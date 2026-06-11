import 'package:cloud_firestore/cloud_firestore.dart';

/// Configuration for a single subscription tier, including per-seat pricing.
class TierConfig {
  final String key; // e.g. 'project', 'program', 'portfolio'
  final String label; // Display name e.g. 'Project Plan'
  final int monthlyPriceCents; // Price in USD cents per month
  final int annualPriceCents; // Price in USD cents per year
  final int includedSeats; // Seats included in base price
  final int perSeatMonthlyCents; // Extra seat price per month (USD cents)
  final int perSeatAnnualCents; // Extra seat price per year (USD cents)
  final int maxSeats; // Hard cap on total seats
  final bool isActive; // Whether this tier is available for purchase
  final List<String> features; // Feature list for pricing page
  final int sortOrder; // Display order (1 = first)

  const TierConfig({
    required this.key,
    required this.label,
    required this.monthlyPriceCents,
    required this.annualPriceCents,
    this.includedSeats = 1,
    this.perSeatMonthlyCents = 1500,
    this.perSeatAnnualCents = 16500,
    this.maxSeats = 50,
    this.isActive = true,
    this.features = const [],
    this.sortOrder = 0,
  });

  /// Price per month in dollars (e.g. 79.00)
  double get monthlyPriceDollars => monthlyPriceCents / 100;

  /// Price per year in dollars
  double get annualPriceDollars => annualPriceCents / 100;

  /// Per-seat monthly price in dollars
  double get perSeatMonthlyDollars => perSeatMonthlyCents / 100;

  /// Per-seat annual price in dollars
  double get perSeatAnnualDollars => perSeatAnnualCents / 100;

  /// Calculate total price for a given number of seats
  int totalPriceCents({required int seats, required bool isAnnual}) {
    final basePrice = isAnnual ? annualPriceCents : monthlyPriceCents;
    final additionalSeats = (seats - includedSeats).clamp(0, maxSeats - includedSeats);
    final perSeat = isAnnual ? perSeatAnnualCents : perSeatMonthlyCents;
    return basePrice + (additionalSeats * perSeat);
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'monthlyPriceCents': monthlyPriceCents,
        'annualPriceCents': annualPriceCents,
        'includedSeats': includedSeats,
        'perSeatMonthlyCents': perSeatMonthlyCents,
        'perSeatAnnualCents': perSeatAnnualCents,
        'maxSeats': maxSeats,
        'isActive': isActive,
        'features': features,
        'sortOrder': sortOrder,
      };

  factory TierConfig.fromJson(Map<String, dynamic> json) {
    return TierConfig(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      monthlyPriceCents: json['monthlyPriceCents'] ?? 7900,
      annualPriceCents: json['annualPriceCents'] ?? 79000,
      includedSeats: json['includedSeats'] ?? 1,
      perSeatMonthlyCents: json['perSeatMonthlyCents'] ?? 1500,
      perSeatAnnualCents: json['perSeatAnnualCents'] ?? 16500,
      maxSeats: json['maxSeats'] ?? 50,
      isActive: json['isActive'] ?? true,
      features: List<String>.from(json['features'] ?? []),
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  TierConfig copyWith({
    String? key,
    String? label,
    int? monthlyPriceCents,
    int? annualPriceCents,
    int? includedSeats,
    int? perSeatMonthlyCents,
    int? perSeatAnnualCents,
    int? maxSeats,
    bool? isActive,
    List<String>? features,
    int? sortOrder,
  }) {
    return TierConfig(
      key: key ?? this.key,
      label: label ?? this.label,
      monthlyPriceCents: monthlyPriceCents ?? this.monthlyPriceCents,
      annualPriceCents: annualPriceCents ?? this.annualPriceCents,
      includedSeats: includedSeats ?? this.includedSeats,
      perSeatMonthlyCents: perSeatMonthlyCents ?? this.perSeatMonthlyCents,
      perSeatAnnualCents: perSeatAnnualCents ?? this.perSeatAnnualCents,
      maxSeats: maxSeats ?? this.maxSeats,
      isActive: isActive ?? this.isActive,
      features: features ?? this.features,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Full pricing configuration document stored at settings/pricing_config
class PricingConfig {
  final Map<String, TierConfig> tiers;
  final int trialDurationDays;
  final String defaultCurrency;
  final DateTime? updatedAt;

  const PricingConfig({
    required this.tiers,
    this.trialDurationDays = 3,
    this.defaultCurrency = 'USD',
    this.updatedAt,
  });

  /// Sorted list of active tiers for display
  List<TierConfig> get sortedTiers {
    final list = tiers.values.where((t) => t.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  /// Get a specific tier config by key
  TierConfig? tier(String key) => tiers[key];

  /// Default pricing config matching current SubscriptionService values
  static PricingConfig get defaults => const PricingConfig(
        trialDurationDays: 3,
        defaultCurrency: 'USD',
        tiers: {
          'project': TierConfig(
            key: 'project',
            label: 'Project Plan',
            monthlyPriceCents: 7900,
            annualPriceCents: 79000,
            includedSeats: 3,
            perSeatMonthlyCents: 1500,
            perSeatAnnualCents: 16500,
            maxSeats: 10,
            isActive: true,
            features: [
              'Full project delivery',
              'Risk matrix & assessment',
              'Cost analysis & estimation',
              'Stakeholder management',
            ],
            sortOrder: 1,
          ),
          'program': TierConfig(
            key: 'program',
            label: 'Program Plan',
            monthlyPriceCents: 18900,
            annualPriceCents: 189000,
            includedSeats: 8,
            perSeatMonthlyCents: 1500,
            perSeatAnnualCents: 16500,
            maxSeats: 25,
            isActive: true,
            features: [
              'Up to 3 projects',
              'Interface management',
              'Program-level reporting',
              'All Project features',
            ],
            sortOrder: 2,
          ),
          'portfolio': TierConfig(
            key: 'portfolio',
            label: 'Portfolio Plan',
            monthlyPriceCents: 44900,
            annualPriceCents: 449000,
            includedSeats: 15,
            perSeatMonthlyCents: 1500,
            perSeatAnnualCents: 16500,
            maxSeats: 50,
            isActive: true,
            features: [
              'Up to 9 projects',
              'Portfolio reports & dashboards',
              'Executive dashboard',
              'All Program features',
            ],
            sortOrder: 3,
          ),
        },
      );

  Map<String, dynamic> toJson() => {
        'tiers': tiers.map((key, value) => MapEntry(key, value.toJson())),
        'trialDurationDays': trialDurationDays,
        'defaultCurrency': defaultCurrency,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      };

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    final tiersMap = <String, TierConfig>{};
    final tiersJson = json['tiers'] as Map<String, dynamic>? ?? {};
    for (final entry in tiersJson.entries) {
      tiersMap[entry.key] = TierConfig.fromJson(entry.value as Map<String, dynamic>);
    }

    return PricingConfig(
      tiers: tiersMap,
      trialDurationDays: json['trialDurationDays'] ?? 3,
      defaultCurrency: json['defaultCurrency'] ?? 'USD',
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
