import 'package:flutter/foundation.dart';

/// Runtime AI configuration that avoids hardcoding secrets in source.
/// ApiKeyManager sets and clears the key at runtime; callers read via [apiKey].
class SecureAPIConfig {
  SecureAPIConfig._();

  static String? _apiKey;

  // Cloud Function proxy endpoint (keeps the API key server-side).
  // Used as fallback for OpenAI models when no client-side key is provided.
  static const String baseUrl =
      'https://us-central1-ndu-d3f60.cloudfunctions.net/openaiProxy';

  // Default model used across AI requests.
  // Using Claude Sonnet 4 — Anthropic's fastest and most capable model.
  // Claude Sonnet provides excellent quality at dramatically faster speeds
  // compared to OpenAI o3 reasoning model (2-4s vs 15-30s per request).
  // Direct browser access eliminates proxy latency for near-instant responses.
  static const String model = 'claude-sonnet-4-20250514';

  /// Anthropic API endpoint for direct browser access.
  /// Claude models call this directly, bypassing the Firebase proxy
  /// for minimum latency. The anthropic-dangerous-direct-browser-access
  /// header enables CORS for browser-based requests.
  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1/messages';

  /// Whether the current model is an OpenAI reasoning model (o1, o3, o4, etc.)
  static bool get isReasoningModel =>
      model.startsWith('o1') || model.startsWith('o3') || model.startsWith('o4');

  /// Whether the current model is an Anthropic Claude model.
  static bool get isClaudeModel => model.toLowerCase().startsWith('claude');

  /// Returns the API endpoint URI for the current model.
  /// Claude models use the direct Anthropic endpoint for fastest response.
  /// OpenAI models use the Firebase Cloud Function proxy.
  static Uri get apiEndpoint {
    if (isClaudeModel) {
      return Uri.parse(anthropicBaseUrl);
    }
    return Uri.parse(baseUrl);
  }

  /// Returns the API key header name for the current model.
  /// Claude uses `x-api-key`, OpenAI uses `Authorization: Bearer`.
  static Map<String, String> get authHeaders {
    if (isClaudeModel) {
      return {
        'x-api-key': _apiKey ?? '',
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
      };
    }
    return {
      'Authorization': 'Bearer ${_apiKey ?? ''}',
    };
  }

  /// Returns model parameters for API requests.
  static Map<String, dynamic> modelParams({int? maxTokens, double? temperature}) {
    final params = <String, dynamic>{
      'model': model,
    };
    if (maxTokens != null) {
      params['max_tokens'] = maxTokens;
    }
    // Claude supports temperature natively; reasoning models don't.
    if (temperature != null && !isReasoningModel) params['temperature'] = temperature;
    return params;
  }

  // Default OpenAI Agent Builder workflow used by the Firebase OpenAI proxy.
  static const String workflowId =
      'wf_69f1f5acc7ec819082fb76bbbf79b64d088ea0e514080150';

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
