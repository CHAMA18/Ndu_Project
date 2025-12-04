import 'package:flutter/material.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/screens/sign_in_screen.dart';

/// Centralized auth navigation helper
class AuthNav {
  /// Signs out the current user and clears the navigation stack,
  /// then sends the user to the SignInScreen.
  static Future<void> signOutAndExit(BuildContext context) async {
    try {
      await FirebaseAuthService.signOut();
    } catch (e) {
      // Best-effort: still attempt to navigate, but surface the error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    }

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    }
  }
}
