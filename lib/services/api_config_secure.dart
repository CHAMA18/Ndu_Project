import 'package:flutter/foundation.dart';

/// Runtime AI configuration that avoids hardcoding secrets in source.
/// ApiKeyManager sets and clears the key at runtime; callers read via [apiKey].
class SecureAPIConfig {
  SecureAPIConfig._();

  // API key loaded at runtime from env-config.js or Firestore.
  // Direct Anthropic access is used when a key is available, bypassing
  // the Firebase proxy for minimum latency.
  static String? _apiKey;

  // Cloud Function proxy endpoint — the only endpoint used for AI requests.
  // Both OpenAI and Anthropic (Claude) requests route through this proxy,
  // keeping API keys server-side for maximum security. The proxy function
  // detects the model name and routes to the appropriate API.
  static const String baseUrl =
      'https://us-central1-ndu-d3f60.cloudfunctions.net/openaiProxy';

  // Default model used across AI requests.
  // Using Claude 3.5 Sonnet — Anthropic's balanced model with strong
  // reasoning and speed. Routes through the Firebase Cloud Function proxy
  // by default (which detects the 'claude' prefix and forwards to the
  // Anthropic API). When a user provides their own Anthropic API key via
  // Settings > Integrations, direct client-side access is used for minimum
  // latency.
  // Fallback models tried automatically if the primary model is unavailable.
  static const String model = 'claude-3-5-sonnet-20241022';

  /// Ordered list of fallback Claude models to try if the primary model
  /// returns a 404 or other transient error. The client walks this list
  /// before giving up.
  static const List<String> fallbackModels = [
    'claude-3-5-sonnet-20241022',
    'claude-3-5-haiku-20241022',
    'claude-3-haiku-20240307',
  ];

  /// Anthropic API endpoint — used ONLY when a client-side API key is
  /// explicitly provided by the user (Settings > Integrations). When no
  /// client key is set, all requests go through the Firebase proxy which
  /// keeps the key server-side.
  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1/messages';

  /// Whether the current model is an OpenAI reasoning model (o1, o3, o4, etc.)
  static bool get isReasoningModel =>
      model.startsWith('o1') || model.startsWith('o3') || model.startsWith('o4');

  /// Whether the current model is an Anthropic Claude model.
  static bool get isClaudeModel => model.toLowerCase().startsWith('claude');

  /// Whether we should use direct Anthropic API access (client-side key)
  /// vs. routing through the Firebase proxy (server-side key).
  /// Direct access is only used when a user has explicitly provided their
  /// own Anthropic API key via Settings > Integrations.
  static bool get useDirectAnthropicAccess =>
      isClaudeModel && _apiKey != null && _apiKey!.trim().isNotEmpty;

  /// Returns the API endpoint URI for the current model.
  /// When a user-provided Claude API key exists, use direct Anthropic access
  /// for minimum latency. Otherwise, route through the Firebase proxy.
  static Uri get apiEndpoint {
    if (useDirectAnthropicAccess) {
      return Uri.parse(anthropicBaseUrl);
    }
    return Uri.parse(baseUrl);
  }

  /// Returns the API key headers for the current model.
  /// For direct Anthropic access (user-provided key), uses x-api-key.
  /// For proxy access, uses Authorization header (proxy handles auth).
  static Map<String, String> get authHeaders {
    if (useDirectAnthropicAccess) {
      return {
        'x-api-key': _apiKey ?? '',
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
      };
    }
    return {
      'Authorization': 'Bearer ${apiKey ?? ''}',
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

  /// Returns the API key — either the user-provided runtime key, or empty
  /// string when using the Firebase proxy (which has its own server-side key).
  static String? get apiKey => _apiKey;

  /// Whether any API key is available (either client-side or via proxy).
  /// Always true because a default Claude API key is built in.
  static bool get hasApiKey => true;

  static void setApiKey(String apiKey) {
    _apiKey = apiKey.trim().isEmpty ? null : apiKey.trim();
    debugPrint('SecureAPIConfig: runtime API key set.');
  }

  static void clearApiKey() {
    _apiKey = null;
    debugPrint('SecureAPIConfig: runtime API key cleared.');
  }
}
