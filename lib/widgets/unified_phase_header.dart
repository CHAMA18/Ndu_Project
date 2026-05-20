import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndu_project/screens/project_activities_log_screen.dart';
import 'package:ndu_project/screens/settings_screen.dart';
import 'package:ndu_project/services/auth_nav.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/widgets/responsive.dart';

class UnifiedPhaseHeader extends StatelessWidget {
  const UnifiedPhaseHeader({
    super.key,
    required this.title,
    this.scaffoldKey,
    this.onBackPressed,
    this.onForwardPressed,
    this.trailingActions = const <Widget>[],
    this.showActivityLogAction = true,
    this.onOpenActivityLog,
    this.backgroundColor = Colors.white,
    this.showDrawerButton = true,
  });

  final String title;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final VoidCallback? onBackPressed;
  final VoidCallback? onForwardPressed;
  final List<Widget> trailingActions;
  final bool showActivityLogAction;
  final VoidCallback? onOpenActivityLog;
  final Color backgroundColor;
  final bool showDrawerButton;

  void _openDrawer(BuildContext context) {
    HapticFeedback.selectionClick();
    if (scaffoldKey?.currentState != null) {
      scaffoldKey!.currentState!.openDrawer();
    } else {
      Scaffold.of(context).openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final headerHeight = isMobile ? 56.0 : 72.0;

    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      child: Row(
        children: [
          if (isMobile) ...[
            if (showDrawerButton)
              IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF374151)),
                tooltip: 'Open menu',
                padding: const EdgeInsets.all(8),
                constraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () => _openDrawer(context),
              ),
            _CircleNavButton(
              icon: Icons.arrow_back_ios_new_rounded,
              iconSize: 14,
              onTap: onBackPressed ?? () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 8),
            _CircleNavButton(
              icon: Icons.arrow_forward_ios_rounded,
              iconSize: 14,
              onTap: onForwardPressed,
              enabled: onForwardPressed != null,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              tooltip: 'Back',
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            ),
            if (onForwardPressed != null)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                tooltip: 'Forward',
                onPressed: onForwardPressed,
              ),
          ],
          const Spacer(),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D3748),
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            if (showActivityLogAction)
              _ActivityLogAction(
                compact: false,
                onTap: onOpenActivityLog ??
                    () => ProjectActivitiesLogScreen.open(context),
              ),
            if (showActivityLogAction) const SizedBox(width: 12),
            ...trailingActions,
            if (trailingActions.isNotEmpty) const SizedBox(width: 12),
          ],
          const UnifiedProfileMenu(compact: true),
        ],
      ),
    );
  }
}

class _CircleNavButton extends StatelessWidget {
  const _CircleNavButton({
    required this.icon,
    required this.iconSize,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final double iconSize;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: iconSize,
          color: enabled ? const Color(0xFF374151) : const Color(0xFFCBD5E0),
        ),
      ),
    );
  }
}

class UnifiedScaffoldAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const UnifiedScaffoldAppBar({
    super.key,
    this.backgroundColor,
    this.title,
    this.onMenuTap,
    this.showActivityLogAction = true,
    this.onOpenActivityLog,
  });

  final Color? backgroundColor;
  final String? title;
  final VoidCallback? onMenuTap;
  final bool showActivityLogAction;
  final VoidCallback? onOpenActivityLog;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    final isMobile = AppBreakpoints.isMobile(context);

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF374151)),
          tooltip: 'Open menu',
          onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: title == null
          ? null
          : Text(
              title!,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
      centerTitle: true,
      actions: [
        if (showActivityLogAction)
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 8 : 10),
            child: _ActivityLogAction(
              compact: isMobile,
              onTap: onOpenActivityLog ??
                  () => ProjectActivitiesLogScreen.open(context),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(right: isMobile ? 8 : 12),
          child: const UnifiedProfileMenu(compact: true),
        ),
      ],
    );
  }
}

class UnifiedProfileMenu extends StatelessWidget {
  const UnifiedProfileMenu({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    final displayName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'Unknown User');
    final email = user?.email?.trim() ?? '';
    final avatarInitial = displayName.trim().isNotEmpty
        ? displayName.trim().characters.first.toUpperCase()
        : 'U';
    final photoUrl = user?.photoURL;
    Stream<bool> adminStatusStream;
    try {
      adminStatusStream = UserService.watchAdminStatus();
    } catch (_) {
      adminStatusStream = Stream<bool>.value(UserService.isAdminEmail(email));
    }

    final avatar = photoUrl != null && photoUrl.isNotEmpty
        ? CircleAvatar(
            radius: compact ? 16 : 20,
            backgroundImage: NetworkImage(photoUrl),
            backgroundColor: Colors.blue,
          )
        : Container(
            width: compact ? 32 : 40,
            height: compact ? 32 : 40,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              avatarInitial,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 13 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          );

    final label = Material(
      color: Colors.transparent,
      child: compact
          ? avatar
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatar,
                const SizedBox(width: 10),
                StreamBuilder<bool>(
                  stream: adminStatusStream,
                  builder: (context, snapshot) {
                    final isAdmin =
                        snapshot.data ?? UserService.isAdminEmail(email);
                    final role = isAdmin ? 'Admin' : 'Member';
                    // Avoid showing email twice when displayName is already
                    // the email address (no proper display name set).
                    final emailIsDuplicate =
                        email.isNotEmpty && displayName == email;
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          if (!emailIsDuplicate)
                            Text(
                              email.isEmpty ? 'No email' : email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          Text(
                            role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );

    return PopupMenuButton<String>(
      tooltip: 'Profile actions',
      onSelected: (value) {
        if (value == 'settings') {
          SettingsScreen.open(context);
        } else if (value == 'logout') {
          AuthNav.signOutAndExit(context);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'settings',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_outlined),
            title: Text('Logout'),
          ),
        ),
      ],
      child: label,
    );
  }
}

class _ActivityLogAction extends StatelessWidget {
  const _ActivityLogAction({
    required this.compact,
    required this.onTap,
  });

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Project Activity Log',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD873)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 18,
                color: Color(0xFFB45309),
              ),
              if (!compact) ...[
                const SizedBox(width: 6),
                const Text(
                  'Activity Log',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
