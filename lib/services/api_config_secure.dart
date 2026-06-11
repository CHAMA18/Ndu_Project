import 'package:flutter/foundation.dart';

/// Runtime Anthropic Claude configuration that avoids hardcoding secrets in source.
/// ApiKeyManager sets and clears the key at runtime; callers read via [apiKey].
class SecureAPIConfig {
  SecureAPIConfig._();

  static String? _apiKey;

  // Cloud Function proxy endpoint (keeps the API key server-side).
  static const String baseUrl =
      'https://us-central1-ndu-d3f60.cloudfunctions.net/claudeProxy';

  // Default model used across Anthropic Claude requests.
  // Using claude-sonnet-4-20250514 — high-performance model with excellent
  // reasoning capabilities and fast response times.
  static const String model = 'claude-sonnet-4-20250514';

  /// Anthropic API version header value.
  static const String anthropicVersion = '2023-06-01';

  static String? get apiKey => _apiKey;
  static bool get hasApiKey => _apiKey?.trim().isNotEmpty == true;

  static void setApiKey(String apiKey) {
    _apiKey = apiKey.trim().isEmpty ? null : apiKey.trim();
    debugPrint('SecureAPIConfig: runtime API key set.');
  }

  static void clearApiKey() {
    _apiKey = null;
    debugPrint('SecureAPIConfig: runtime API key cleared.');
  }
}
