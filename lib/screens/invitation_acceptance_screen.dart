import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndu_project/models/user_role.dart';
import 'package:ndu_project/routing/app_router.dart';

// ── Design tokens (matching NDU dark theme) ──────────────────────────────
const _kBg = Color(0xFF0F172A);
const _kCard = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kAccent = Color(0xFFFFC107);
const _kBlue = Color(0xFF3B82F6);
const _kTextPrimary = Colors.white;
const _kTextSecondary = Color(0xFF94A3B8);
const _kSuccess = Color(0xFF10B981);
const _kError = Color(0xFFEF4444);
const _kWarning = Color(0xFFF59E0B);

/// The states the invitation acceptance screen can be in.
enum _InviteState {
  loading,
  loaded,
  notFound,
  expired,
  alreadyAccepted,
  notAuthenticated,
  accepting,
  accepted,
  error,
}

/// Data model for a collaboration invite fetched from Firestore.
class _InviteData {
  final String invitedByEmail;
  final String projectName;
  final String siteRole;
  final String scope;
  final String? personalMessage;
  final DateTime? expiresAt;
  final String status;

  const _InviteData({
    required this.invitedByEmail,
    required this.projectName,
    required this.siteRole,
    required this.scope,
    this.personalMessage,
    this.expiresAt,
    required this.status,
  });
}

/// Screen that handles the invitation acceptance flow when a user clicks an
/// invite link like `https://ndu-d3f60.web.app/invite?token=xxx`.
///
/// Required parameter: [token] — the invite token from the URL.
/// Optional parameter: [status] — pre-resolved status hint from the URL.
class InvitationAcceptanceScreen extends StatefulWidget {
  const InvitationAcceptanceScreen({
    super.key,
    required this.token,
    this.status,
  });

  final String token;
  final String? status;

  @override
  State<InvitationAcceptanceScreen> createState() =>
      _InvitationAcceptanceScreenState();
}

class _InvitationAcceptanceScreenState
    extends State<InvitationAcceptanceScreen> {
  _InviteState _state = _InviteState.loading;
  _InviteData? _inviteData;
  String? _errorMessage;
  String? _acceptedProjectName;

  @override
  void initState() {
    super.initState();
    _fetchInvitation();
  }

  // ── Firestore fetch ───────────────────────────────────────────────────
  Future<void> _fetchInvitation() async {
    if (widget.token.isEmpty) {
      setState(() {
        _state = _InviteState.notFound;
        _errorMessage = 'No invitation token provided.';
      });
      return;
    }

    setState(() => _state = _InviteState.loading);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('collaboration_invites')
          .where('inviteToken', isEqualTo: widget.token)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _state = _InviteState.notFound;
          _errorMessage = 'This invitation could not be found. It may have been revoked or the link is incorrect.';
        });
        return;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      final expiresAtRaw = data['expiresAt'];
      DateTime? expiresAt;
      if (expiresAtRaw is Timestamp) {
        expiresAt = expiresAtRaw.toDate();
      } else if (expiresAtRaw is String) {
        expiresAt = DateTime.tryParse(expiresAtRaw);
      }

      final inviteStatus = (data['status'] as String?) ?? 'pending';

      // Check if already accepted
      if (inviteStatus.toLowerCase() == 'accepted') {
        setState(() {
          _state = _InviteState.alreadyAccepted;
          _inviteData = _InviteData(
            invitedByEmail: data['invitedByEmail'] as String? ?? 'Unknown',
            projectName: data['projectName'] as String? ?? 'Unknown Project',
            siteRole: data['siteRole'] as String? ?? 'guest',
            scope: data['scope'] as String? ?? 'Project',
            personalMessage: data['personalMessage'] as String?,
            expiresAt: expiresAt,
            status: inviteStatus,
          );
        });
        return;
      }

      // Check if expired
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        setState(() {
          _state = _InviteState.expired;
          _inviteData = _InviteData(
            invitedByEmail: data['invitedByEmail'] as String? ?? 'Unknown',
            projectName: data['projectName'] as String? ?? 'Unknown Project',
            siteRole: data['siteRole'] as String? ?? 'guest',
            scope: data['scope'] as String? ?? 'Project',
            personalMessage: data['personalMessage'] as String?,
            expiresAt: expiresAt,
            status: inviteStatus,
          );
        });
        return;
      }

      setState(() {
        _state = _InviteState.loaded;
        _inviteData = _InviteData(
          invitedByEmail: data['invitedByEmail'] as String? ?? 'Unknown',
          projectName: data['projectName'] as String? ?? 'Unknown Project',
          siteRole: data['siteRole'] as String? ?? 'guest',
          scope: data['scope'] as String? ?? 'Project',
          personalMessage: data['personalMessage'] as String?,
          expiresAt: expiresAt,
          status: inviteStatus,
        );
      });
    } catch (e) {
      setState(() {
        _state = _InviteState.error;
        _errorMessage = 'Failed to load invitation details. Please try again.\n$e';
      });
    }
  }

  // ── Accept invitation via Cloud Function ──────────────────────────────
  Future<void> _acceptInvitation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _state = _InviteState.notAuthenticated);
      return;
    }

    setState(() => _state = _InviteState.accepting);

    try {
      final uri = Uri.parse(
        'https://us-central1-ndu-d3f60.cloudfunctions.net/acceptInvitation',
      );

      final request = await HttpClient().postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        'token': widget.token,
        'uid': user.uid,
      }));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _state = _InviteState.accepted;
          _acceptedProjectName = _inviteData?.projectName ?? 'the project';
        });
      } else {
        final errorData = jsonDecode(responseBody) as Map<String, dynamic>;
        final message = errorData['error'] as String? ??
            errorData['message'] as String? ??
            'Unknown error occurred.';
        setState(() {
          _state = _InviteState.error;
          _errorMessage = 'Failed to accept invitation: $message';
        });
      }
    } catch (e) {
      setState(() {
        _state = _InviteState.error;
        _errorMessage = 'Network error. Please check your connection and try again.\n$e';
      });
    }
  }

  void _navigateToSignIn() {
    context.go('/${AppRoutes.signIn}');
  }

  void _navigateToDashboard() {
    context.go('/${AppRoutes.dashboard}');
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: _buildContentForState(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentForState() {
    switch (_state) {
      case _InviteState.loading:
        return _buildLoadingState();
      case _InviteState.loaded:
        return _buildLoadedState();
      case _InviteState.notFound:
        return _buildErrorState(
          icon: Icons.link_off_rounded,
          iconColor: _kError,
          title: 'Invitation Not Found',
          message: _errorMessage ?? 'This invitation could not be found.',
        );
      case _InviteState.expired:
        return _buildExpiredState();
      case _InviteState.alreadyAccepted:
        return _buildAlreadyAcceptedState();
      case _InviteState.notAuthenticated:
        return _buildNotAuthenticatedState();
      case _InviteState.accepting:
        return _buildAcceptingState();
      case _InviteState.accepted:
        return _buildAcceptedState();
      case _InviteState.error:
        return _buildErrorState(
          icon: Icons.error_outline_rounded,
          iconColor: _kError,
          title: 'Something Went Wrong',
          message: _errorMessage ?? 'An unexpected error occurred.',
          showRetry: true,
        );
    }
  }

  // ── Loading ───────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return _CardContainer(
      children: [
        const SizedBox(height: 32),
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
            backgroundColor: _kBorder.withOpacity(0.3),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Loading Invitation\u2026',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please wait while we verify your invitation details.',
          style: TextStyle(fontSize: 14, color: _kTextSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Loaded — show details + actions ───────────────────────────────────
  Widget _buildLoadedState() {
    final data = _inviteData!;
    final siteRole = SiteRole.fromString(data.siteRole);

    return _CardContainer(
      children: [
        // Header icon + title
        _buildHeaderIcon(
          Icons.mail_outline_rounded,
          _kAccent,
        ),
        const SizedBox(height: 20),
        const Text(
          'You\'re Invited!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _kTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'You have been invited to collaborate on a project.',
          style: TextStyle(
            fontSize: 15,
            color: _kTextSecondary.withOpacity(0.9),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Divider
        _buildDivider(),
        const SizedBox(height: 20),

        // Details
        _buildDetailRow(Icons.person_outline_rounded, 'Invited By', data.invitedByEmail),
        const SizedBox(height: 16),
        _buildDetailRow(Icons.folder_outlined, 'Project', data.projectName),
        const SizedBox(height: 16),
        _buildDetailRow(
          Icons.admin_panel_settings_outlined,
          'Role',
          siteRole.displayName,
          trailing: _RoleChip(role: siteRole),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(Icons.public_outlined, 'Scope', data.scope),
        if (data.expiresAt != null) ...[
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.schedule_outlined,
            'Expires',
            _formatDate(data.expiresAt!),
            valueColor: _isExpiringSoon(data.expiresAt!) ? _kWarning : null,
          ),
        ],

        // Personal message (if any)
        if (data.personalMessage != null &&
            data.personalMessage!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kAccent.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 16, color: _kAccent.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text(
                      'Personal Message',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kAccent.withOpacity(0.9),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"${data.personalMessage}"',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: _kTextSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),

        // Action buttons
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _acceptInvitation,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Accept Invitation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => context.go('/${AppRoutes.landing}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kTextSecondary,
              side: const BorderSide(color: _kBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Decline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Expired ───────────────────────────────────────────────────────────
  Widget _buildExpiredState() {
    final data = _inviteData;
    return _CardContainer(
      children: [
        _buildHeaderIcon(Icons.event_busy_rounded, _kWarning),
        const SizedBox(height: 20),
        const Text(
          'Invitation Expired',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _kTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          data != null
              ? 'The invitation to join "${data.projectName}" has expired on ${_formatDate(data.expiresAt!)}.'
              : 'This invitation has expired and is no longer valid.',
          style: const TextStyle(fontSize: 15, color: _kTextSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => context.go('/${AppRoutes.landing}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kTextSecondary,
              side: const BorderSide(color: _kBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Go to Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Already Accepted ──────────────────────────────────────────────────
  Widget _buildAlreadyAcceptedState() {
    final data = _inviteData;
    return _CardContainer(
      children: [
        _buildHeaderIcon(Icons.check_circle_outline_rounded, _kSuccess),
        const SizedBox(height: 20),
        const Text(
          'Already Accepted',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _kTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          data != null
              ? 'You have already accepted the invitation to join "${data.projectName}".'
              : 'This invitation has already been accepted.',
          style: const TextStyle(fontSize: 15, color: _kTextSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _navigateToDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Go to Dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Not Authenticated ─────────────────────────────────────────────────
  Widget _buildNotAuthenticatedState() {
    return _CardContainer(
      children: [
        _buildHeaderIcon(Icons.lock_outline_rounded, _kBlue),
        const SizedBox(height: 20),
        const Text(
          'Sign In Required',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _kTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Please sign in or create an account to accept this invitation.',
          style: TextStyle(fontSize: 15, color: _kTextSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _navigateToSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () =>
                context.go('/${AppRoutes.createAccount}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kBlue,
              side: const BorderSide(color: _kBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Create Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Accepting (loading spinner) ───────────────────────────────────────
  Widget _buildAcceptingState() {
    return _CardContainer(
      children: [
        const SizedBox(height: 32),
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
            backgroundColor: _kBorder.withOpacity(0.3),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Accepting Invitation\u2026',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Please wait while we process your acceptance.',
          style: TextStyle(fontSize: 14, color: _kTextSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Accepted (celebration) ────────────────────────────────────────────
  Widget _buildAcceptedState() {
    return _CardContainer(
      children: [
        const SizedBox(height: 16),
        // Celebration icon with glow
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _kSuccess.withOpacity(0.25),
                _kSuccess.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: _kSuccess.withOpacity(0.4), width: 2),
          ),
          child: const Icon(
            Icons.celebration_rounded,
            size: 44,
            color: _kSuccess,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _kTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome to $_acceptedProjectName!',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kAccent,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'You have successfully joined the project. You can now access all the features and collaborate with your team.',
          style: TextStyle(
            fontSize: 15,
            color: _kTextSecondary.withOpacity(0.9),
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Success confetti-like dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCelebrationDot(const Color(0xFFFFC107)),
            const SizedBox(width: 10),
            _buildCelebrationDot(const Color(0xFF3B82F6)),
            const SizedBox(width: 10),
            _buildCelebrationDot(const Color(0xFF10B981)),
            const SizedBox(width: 10),
            _buildCelebrationDot(const Color(0xFF8B5CF6)),
            const SizedBox(width: 10),
            _buildCelebrationDot(const Color(0xFFEF4444)),
          ],
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _navigateToDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Go to Dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────
  Widget _buildErrorState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    bool showRetry = false,
  }) {
    return _CardContainer(
      children: [
        _buildHeaderIcon(icon, iconColor),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _kTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(fontSize: 15, color: _kTextSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        if (showRetry) ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _fetchInvitation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => context.go('/${AppRoutes.landing}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kTextSecondary,
              side: const BorderSide(color: _kBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Go to Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Shared UI helpers ─────────────────────────────────────────────────

  Widget _buildHeaderIcon(IconData icon, Color color) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Icon(icon, size: 36, color: color),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kBorder.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _kTextSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary.withOpacity(0.8),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? _kTextPrimary,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: _kBorder.withOpacity(0.5),
    );
  }

  Widget _buildCelebrationDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays <= 0) {
      return 'Expired';
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else if (diff.inDays <= 7) {
      return '${diff.inDays} days from now';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  bool _isExpiringSoon(DateTime date) {
    final diff = date.difference(DateTime.now());
    return diff.inDays <= 3 && diff.inDays > 0;
  }
}

// ── Role chip widget ────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final SiteRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: role.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: role.color.withOpacity(0.35)),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: role.color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Reusable card container ────────────────────────────────────────────
class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
