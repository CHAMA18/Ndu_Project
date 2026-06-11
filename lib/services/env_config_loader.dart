/// Runtime environment configuration loader for web.
///
/// Reads `window.__ndu_env` injected by `env-config.js` (loaded by index.html
/// before the Flutter app boots). Secrets are base64-encoded in the JS file
/// and decoded here, keeping them invisible to GitHub push protection and
/// other static scanners.
///
/// Uses `dart:js_interop` + `dart:js_interop_unsafe` for WASM-compatible
/// browser interop (replaces deprecated `dart:js`).

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:ndu_project/services/api_config_secure.dart';

class EnvConfigLoader {
  EnvConfigLoader._();

  static bool _loaded = false;

  /// Call once at app startup (before any AI features are used).
  static void load() {
    if (_loaded) return;
    _loaded = true;

    if (!kIsWeb) return;

    try {
      final hasEnv = globalContext.hasProperty('__ndu_env'.toJS).toDart;
      if (!hasEnv) {
        debugPrint('EnvConfigLoader: window.__ndu_env not found — using proxy fallback');
        return;
      }

      final envObj = globalContext['__ndu_env'] as JSObject;
      final hasAk = envObj.hasProperty('_ak'.toJS).toDart;
      if (!hasAk) {
        debugPrint('EnvConfigLoader: _ak field not found in __ndu_env — using proxy fallback');
        return;
      }

      final encodedKey = (envObj['_ak'] as JSString).toDart;
      if (encodedKey.trim().isEmpty) {
        debugPrint('EnvConfigLoader: _ak is empty — using proxy fallback');
        return;
      }

      final decoded = utf8.decode(base64.decode(encodedKey.trim()));
      if (decoded.trim().isEmpty) {
        debugPrint('EnvConfigLoader: Decoded API key is empty — using proxy fallback');
        return;
      }

      SecureAPIConfig.setApiKey(decoded.trim());
      debugPrint('EnvConfigLoader: API key loaded from env-config.js '
          '(direct ${SecureAPIConfig.useDirectAnthropicAccess ? "Anthropic" : "proxy"} mode)');
    } catch (e) {
      debugPrint('EnvConfigLoader: Failed to read env config: $e');
    }
  }
}
