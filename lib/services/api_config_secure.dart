import 'package:flutter/foundation.dart';

// Compile-time Anthropic API key injected via --dart-define=ANTHROPIC_API_KEY=...
const String _envAnthropicApiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

/// Runtime AI API configuration that avoids hardcoding secrets in source.
/// ApiKeyManager sets and clears the key at runtime; callers read via [apiKey].
class SecureAPIConfig {
  SecureAPIConfig._();

  static String? _apiKey;

  // Cloud Function proxy endpoint (keeps the API key server-side).
  static const String baseUrl =
      'https://us-central1-ndu-d3f60.cloudfunctions.net/openaiProxy';

  // ── Claude / Anthropic Model ──────────────────────────────────────────
  // Using claude-sonnet-4-20250514 — Anthropic's high-performance model.
  // The Firebase proxy auto-detects claude-* models and routes to the
  // Anthropic Messages API with full request/response translation.
  static const String model = 'claude-sonnet-4-20250514';

  /// Whether the current model is an OpenAI reasoning model (o1, o3, o4, etc.)
  /// Claude models are NOT OpenAI reasoning models, so temperature and
  /// max_tokens work normally.
  static bool get isReasoningModel =>
      model.startsWith('o1') || model.startsWith('o3') || model.startsWith('o4');

  /// Whether the current model is a Claude / Anthropic model.
  static bool get isClaudeModel => model.toLowerCase().startsWith('claude-');

  /// Returns model parameters for API requests.
  /// For Claude models, uses `max_tokens` (not `max_completion_tokens`).
  /// For OpenAI reasoning models, uses `max_completion_tokens`.
  static Map<String, dynamic> modelParams({int? maxTokens, double? temperature}) {
    final params = <String, dynamic>{
      'model': model,
    };
    if (maxTokens != null) {
      // Claude uses max_tokens; OpenAI reasoning models use max_completion_tokens
      if (isClaudeModel || !isReasoningModel) {
        params['max_tokens'] = maxTokens;
      } else {
        params['max_completion_tokens'] = maxTokens;
      }
    }
    // Claude supports temperature normally (unlike OpenAI reasoning models)
    if (temperature != null) params['temperature'] = temperature;
    return params;
  }

  // Default OpenAI Agent Builder workflow used by the Firebase OpenAI proxy.
  // Not applicable for Claude models — the proxy handles routing.
  static const String workflowId =
      'wf_69f1f5acc7ec819082fb76bbbf79b64d088ea0e514080150';

  static String? get apiKey => _apiKey;
  static bool get hasApiKey => _apiKey?.trim().isNotEmpty == true;

  /// Whether a compile-time Anthropic API key was provided via --dart-define.
  static bool get hasEnvAnthropicKey => _envAnthropicApiKey.trim().isNotEmpty;

  /// Returns the compile-time Anthropic API key (if set via --dart-define).
  static String? get envAnthropicApiKey =>
      _envAnthropicApiKey.trim().isEmpty ? null : _envAnthropicApiKey.trim();

  static void setApiKey(String apiKey) {
    _apiKey = apiKey.trim().isEmpty ? null : apiKey.trim();
    debugPrint('SecureAPIConfig: runtime API key set.');
  }

  static void clearApiKey() {
    _apiKey = null;
    debugPrint('SecureAPIConfig: runtime API key cleared.');
  }

  /// Initialize the API key from compile-time env var if available.
  /// Called during app startup.
  static void initFromEnv() {
    if (hasEnvAnthropicKey && !hasApiKey) {
      _apiKey = envAnthropicApiKey;
      debugPrint('SecureAPIConfig: Anthropic API key loaded from --dart-define.');
    }
  }
}
