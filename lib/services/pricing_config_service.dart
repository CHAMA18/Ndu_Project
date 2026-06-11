import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:ndu_project/models/pricing_config_model.dart';

/// Service for managing dynamic pricing configuration stored in Firestore
/// at settings/pricing_config. Falls back to hardcoded defaults if unavailable.
class PricingConfigService {
  static final _firestore = FirebaseFirestore.instance;
  static const _configDocPath = 'settings/pricing_config';

  /// In-memory cache so we don't hit Firestore on every call
  static PricingConfig? _cache;

  /// Stream subscription for real-time updates
  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  /// Stream controller for broadcasting config changes
  static final _controller = StreamController<PricingConfig>.broadcast();

  /// Current config (cached, or defaults if not yet loaded)
  static PricingConfig get current => _cache ?? PricingConfig.defaults;

  /// Real-time stream of config changes
  static Stream<PricingConfig> get onConfigChanged => _controller.stream;

  /// Whether the config has been loaded from Firestore at least once
  static bool get isLoaded => _cache != null;

  // ---------------------------------------------------------------------------
  // READ OPERATIONS
  // ---------------------------------------------------------------------------

  /// Load pricing config from Firestore. Returns defaults if unavailable.
  static Future<PricingConfig> loadConfig() async {
    try {
      final doc = await _firestore.doc(_configDocPath).get();
      if (doc.exists && doc.data() != null) {
        _cache = PricingConfig.fromJson(doc.data()!);
        _controller.add(_cache!);
        return _cache!;
      }
    } catch (e) {
      debugPrint('PricingConfigService: Failed to load from Firestore, using defaults: $e');
    }
    _cache = PricingConfig.defaults;
    _controller.add(_cache!);
    return _cache!;
  }

  /// Watch pricing config in real-time. Automatically starts listening on first call.
  static Stream<PricingConfig> watchConfig() {
    if (_subscription == null) {
      _subscription = _firestore.doc(_configDocPath).snapshots().listen(
        (doc) {
          if (doc.exists && doc.data() != null) {
            _cache = PricingConfig.fromJson(doc.data()!);
          } else {
            _cache = PricingConfig.defaults;
          }
          _controller.add(_cache!);
        },
        onError: (error) {
          debugPrint('PricingConfigService: Stream error: $error');
          // Keep using cached or default values
          if (_cache == null) {
            _cache = PricingConfig.defaults;
            _controller.add(_cache!);
          }
        },
      );
    }
    return _controller.stream;
  }

  /// Stop listening to real-time updates
  static void stopWatching() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ---------------------------------------------------------------------------
  // WRITE OPERATIONS (admin only)
  // ---------------------------------------------------------------------------

  /// Save the full pricing config to Firestore
  static Future<void> saveConfig(PricingConfig config) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = config.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['updatedBy'] = user.uid;

    await _firestore.doc(_configDocPath).set(data, SetOptions(merge: true));
    _cache = config;
    _controller.add(_cache!);
  }

  /// Save a single tier's config
  static Future<void> saveTierConfig(TierConfig tier) async {
    final config = current;
    final updatedTiers = Map<String, TierConfig>.from(config.tiers);
    updatedTiers[tier.key] = tier;

    final updatedConfig = PricingConfig(
      tiers: updatedTiers,
      trialDurationDays: config.trialDurationDays,
      defaultCurrency: config.defaultCurrency,
    );
    await saveConfig(updatedConfig);
  }

  /// Add a new tier
  static Future<void> addTier(TierConfig tier) async {
    final config = current;
    if (config.tiers.containsKey(tier.key)) {
      throw Exception('Tier "${tier.key}" already exists');
    }
    final updatedTiers = Map<String, TierConfig>.from(config.tiers);
    updatedTiers[tier.key] = tier;

    final updatedConfig = PricingConfig(
      tiers: updatedTiers,
      trialDurationDays: config.trialDurationDays,
      defaultCurrency: config.defaultCurrency,
    );
    await saveConfig(updatedConfig);
  }

  /// Remove a tier by key
  static Future<void> removeTier(String tierKey) async {
    final config = current;
    final updatedTiers = Map<String, TierConfig>.from(config.tiers);
    updatedTiers.remove(tierKey);

    final updatedConfig = PricingConfig(
      tiers: updatedTiers,
      trialDurationDays: config.trialDurationDays,
      defaultCurrency: config.defaultCurrency,
    );
    await saveConfig(updatedConfig);
  }

  /// Update trial duration days
  static Future<void> updateTrialDuration(int days) async {
    final config = current;
    final updatedConfig = PricingConfig(
      tiers: config.tiers,
      trialDurationDays: days,
      defaultCurrency: config.defaultCurrency,
    );
    await saveConfig(updatedConfig);
  }

  /// Update default currency
  static Future<void> updateCurrency(String currency) async {
    final config = current;
    final updatedConfig = PricingConfig(
      tiers: config.tiers,
      trialDurationDays: config.trialDurationDays,
      defaultCurrency: currency,
    );
    await saveConfig(updatedConfig);
  }

  // ---------------------------------------------------------------------------
  // CONVENIENCE GETTERS
  // ---------------------------------------------------------------------------

  /// Get tier config for a given SubscriptionTier enum value
  static TierConfig tierConfigForKey(String tierKey) {
    return current.tiers[tierKey] ??
        TierConfig(
          key: tierKey,
          label: tierKey,
          monthlyPriceCents: 7900,
          annualPriceCents: 79000,
        );
  }

  /// Get price for a tier (in cents), accounting for seats
  static int getPriceCents({
    required String tierKey,
    required bool isAnnual,
    int seats = 1,
  }) {
    final tier = tierConfigForKey(tierKey);
    return tier.totalPriceCents(seats: seats, isAnnual: isAnnual);
  }

  /// Get formatted price string (e.g. "$79")
  static String getFormattedPrice({
    required String tierKey,
    required bool isAnnual,
    int seats = 1,
  }) {
    final cents = getPriceCents(tierKey: tierKey, isAnnual: isAnnual, seats: seats);
    final dollars = cents / 100;
    return '\$${dollars.toStringAsFixed(dollars.truncateToDouble() == dollars ? 0 : 2)}';
  }

  /// Get per-seat monthly price formatted (e.g. "$15")
  static String getPerSeatPriceFormatted(String tierKey) {
    final tier = tierConfigForKey(tierKey);
    final dollars = tier.perSeatMonthlyDollars;
    return '\$${dollars.toStringAsFixed(dollars.truncateToDouble() == dollars ? 0 : 2)}';
  }

  /// Seed the Firestore document with default values if it doesn't exist
  static Future<void> seedDefaultsIfNeeded() async {
    try {
      final doc = await _firestore.doc(_configDocPath).get();
      if (!doc.exists) {
        debugPrint('PricingConfigService: Seeding default pricing config to Firestore');
        await saveConfig(PricingConfig.defaults);
      }
    } catch (e) {
      debugPrint('PricingConfigService: Failed to seed defaults: $e');
    }
  }

  /// Dispose resources
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller.close();
  }
}
