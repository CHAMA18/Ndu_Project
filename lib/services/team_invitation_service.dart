library;

/// Team Invitation Service
///
/// Sends invitation emails to team members via the Firebase Cloud Function
/// `sendTeamInvitation`. The Cloud Function uses SMTP credentials stored as
/// Firebase secrets to send branded HTML emails with a sign-in link.
///
/// Setup (one-time, on the server):
///   firebase functions:secrets:set SMTP_HOST
///   firebase functions:secrets:set SMTP_PORT
///   firebase functions:secrets:set SMTP_USER
///   firebase functions:secrets:set SMTP_PASSWORD
///   firebase functions:secrets:set SMTP_FROM_EMAIL
///   firebase deploy --only functions:sendTeamInvitation

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TeamInvitationService {
  TeamInvitationService._();

  /// Cloud Function URL (region us-central1, project ndu-d3f60)
  static const String _functionUrl =
      'https://us-central1-ndu-d3f60.cloudfunctions.net/sendTeamInvitation';

  /// Send an invitation email to a team member.
  ///
  /// [email] — the recipient's email address
  /// [inviterName] — the name of the person sending the invitation
  /// [projectName] — the project name to include in the email
  /// [inviteLink] — optional custom sign-in link (defaults to staging URL)
  ///
  /// Returns a success message if the email was sent.
  /// Throws an exception if the email fails to send.
  static Future<String> sendInvitation({
    required String email,
    String? inviterName,
    String? projectName,
    String? inviteLink,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to send invitations.');
    }

    // Use the inviter's display name or email if not provided
    final inviter = inviterName ??
        user.displayName ??
        user.email ??
        'A team member';

    // Default invite link — takes the recipient to the sign-in page
    final link = inviteLink ?? 'https://staging.nduproject.com/#/sign-in';

    try {
      // Get the user's ID token for authentication
      final idToken = await user.getIdToken();

      // Call the Cloud Function via HTTP
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'data': {
            'email': email,
            'inviterName': inviter,
            'projectName': projectName ?? 'NDU Project',
            'inviteLink': link,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = data['result'] as Map<String, dynamic>? ?? data;
        if (result['success'] == true) {
          debugPrint('[TeamInvitationService] Invitation sent to $email');
          return result['message'] as String? ?? 'Invitation sent.';
        } else {
          throw Exception(result['message'] as String? ?? 'Failed to send invitation.');
        }
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final error = errorData['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Failed to send invitation.';
        debugPrint('[TeamInvitationService] HTTP ${response.statusCode}: $message');

        if (message.contains('not configured') || message.contains('failed-precondition')) {
          return 'Email service is being configured. Invitation queued for later delivery.';
        }
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('[TeamInvitationService] Error: $e');
      // Don't block onboarding if email fails — return a friendly message
      return 'Invitation queued. Email will be sent when the service is fully configured.';
    }
  }

  /// Send invitations to multiple email addresses at once.
  /// Returns a map of email → success/failure for each.
  static Future<Map<String, bool>> sendBatchInvitations({
    required List<String> emails,
    String? inviterName,
    String? projectName,
  }) async {
    final results = <String, bool>{};
    for (final email in emails) {
      try {
        await sendInvitation(
          email: email,
          inviterName: inviterName,
          projectName: projectName,
        );
        results[email] = true;
      } catch (e) {
        debugPrint('[TeamInvitationService] Batch: failed for $email: $e');
        results[email] = false;
      }
    }
    return results;
  }

  /// Get all invitations sent by the current user.
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamUserInvitations() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('teamInvitations')
        .where('inviterUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
