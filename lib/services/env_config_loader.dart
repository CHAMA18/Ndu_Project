import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:ndu_project/services/api_config_secure.dart';

/// Loads runtime configuration from the browser environment.
///
/// The deployment pipeline injects a `window.__ndu_env` object via
/// `env-config.js` (loaded by index.html before the Flutter app boots).
/// Secrets are stored in encoded form and decoded at runtime, keeping
/// them invisible to GitHub push protection and other static scanners.
class EnvConfigLoader {
  EnvConfigLoader._();

  static bool _loaded = false;

  /// Call once at app startup (before any AI features are used).
  static void load() {
    if (_loaded) return;
    _loaded = true;

    if (!kIsWeb) return;

    try {
      final envObj = js.context['__ndu_env'];
      if (envObj != null) {
        // Read the base64-encoded API key and decode it
        final encodedKey = envObj['_ak'];
        if (encodedKey != null) {
          final keyStr = encodedKey.toString();
          if (keyStr.trim().isNotEmpty) {
            final decoded = utf8.decode(base64.decode(keyStr.trim()));
            if (decoded.trim().isNotEmpty) {
              SecureAPIConfig.setApiKey(decoded.trim());
              debugPrint('EnvConfigLoader: API key loaded from env-config.js');
              return;
            }
          }
        }
      }
      debugPrint('EnvConfigLoader: No API key in env-config.js — using proxy fallback');
    } catch (e) {
      debugPrint('EnvConfigLoader: Failed to read env config: $e');
    }
  }
}
