import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/services/api_config_secure.dart';

/// Secure API Key Manager
/// This allows you to set your API key at runtime without exposing it in source code
class ApiKeyManager {
  static bool _isInitialized = false;
  static const String _usersCollection = 'users';
  static const String _keyField = 'openaiApiKey';
  
  /// Initialize the API key securely
  /// Call this method once when your app starts
  static void initializeApiKey() {
    if (!_isInitialized) {
      // Always use the permanent hardcoded default key
      // Ignore environment variables to ensure consistency
      print('API key manager: using permanent hardcoded default API key.');
      _isInitialized = true;
    }
  }
  
  /// Set the API key securely
  static void setApiKey(String apiKey) {
    SecureAPIConfig.setApiKey(apiKey);
    _isInitialized = true;
    print('API key updated successfully');
  }
  
  /// Check if API key is properly configured
  static bool get isConfigured => _isInitialized && SecureAPIConfig.hasApiKey;
  
  /// Clear the API key (for logout or security)
  static void clearApiKey() {
    SecureAPIConfig.clearApiKey();
    _isInitialized = false;
  }

  /// Loads a previously saved key for the currently signed-in user (if any).
  /// Does nothing if an environment key is already active or if we have a hardcoded default key.
  static Future<void> ensureLoadedForSignedInUser() async {
    // Skip loading from Firestore since we have a permanent default key
    // The hardcoded default key in SecureAPIConfig always takes precedence
    print('Using permanent default API key - skipping Firestore key load.');
    return;
  }

  /// Persists the provided key under users/{uid}. Creates the document if missing.
  static Future<void> persistForCurrentUser(String apiKey) async {
    setApiKey(apiKey);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final users = FirebaseFirestore.instance.collection(_usersCollection);
      await users.doc(user.uid).set(
        {
          _keyField: apiKey.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('API key persisted to Firestore for user ${user.uid.substring(0, 6)}…');
    } catch (e) {
      print('ApiKeyManager.persistForCurrentUser error: $e');
    }
  }

  /// Removes the stored key for the current user and clears in-memory key.
  static Future<void> removeForCurrentUser() async {
    clearApiKey();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final users = FirebaseFirestore.instance.collection(_usersCollection);
      await users.doc(user.uid).set(
        {
          _keyField: FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('API key removed from Firestore for user ${user.uid.substring(0, 6)}…');
    } catch (e) {
      print('ApiKeyManager.removeForCurrentUser error: $e');
    }
  }
}