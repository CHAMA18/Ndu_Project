/// NDU Portfolio — PMO Executive Dashboard (Ultra-Modern Edition)
///
/// World-class design with deep glassmorphism, gold gradient accents,
/// animated entrance, gradient charts, and premium micro-interactions.
/// Standard header with logo, breadcrumb, nav buttons, and profile avatar.
library;

import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/navigation_context_service.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/app_logo.dart';


class SafeSection extends StatelessWidget {
  SafeSection({super.key, required this.title, required this.builder});
  final String title;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    Widget child;
    try {
      child = builder(context);
    } catch (error, stack) {
      debugPrint('[PortfolioDashboard] Section "$title" failed: $error');
      debugPrint(stack.toString());
      return _SectionErrorCard(
        title: '$title unavailable',
        message: 'This section encountered an error while rendering. Other parts are unaffected.',
        details: error.toString(),
      );
    }
    return child;
  }
}

class _SectionErrorCard extends StatelessWidget {
  const _SectionErrorCard({required this.title, required this.message, required this.details});
  final String title;
  final String message;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDA29B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFFEE4E2), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline, color: Color(0xFFD92D20), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFB42318))),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 12.5, color: Color(0xFF667085), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class PortfolioDashboardScreen extends StatefulWidget {
  final String? portfolioId;

  const PortfolioDashboardScreen({super.key, this.portfolioId});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PortfolioDashboardScreen()),
    );
  }

  @override
  State<PortfolioDashboardScreen> createState() => _PortfolioDashboardScreenState();
}

class _PortfolioDashboardScreenState extends State<PortfolioDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Light theme — plain white background with dark text
  static const _bg = Color(0xFFFFFFFF);
  static const _surface = Color(0xFFF8FAFC);
  static const _surfaceHigh = Color(0xFFF1F5F9);
  static const _surfaceHighest = Color(0xFFE2E8F0);
  static const _onSurface = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _outline = Color(0xFFE2E8F0);
  static const _gold = Color(0xFFD97706);
  static const _blue = Color(0xFF6366F1);
  static const _blueDeep = Color(0xFF4F46E5);
  static const _emerald = Color(0xFF059669);
  static const _amber = Color(0xFFD97706);
  static const _crimson = Color(0xFFDC2626);
  static const _crimsonBright = Color(0xFFEF4444);

  LinearGradient get _goldGrad => const LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() { _fadeController.dispose(); super.dispose(); }

  Widget _glassCard({required Widget child, Color? glow, double blur = 0}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: glow != null ? [BoxShadow(color: glow.withValues(alpha: 0.08), blurRadius: blur)] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _outline, width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Record this dashboard so the brand logo knows where to return on tap.
    NavigationContextService.instance
        .setLastClientDashboard(AppRoutes.portfolioDashboard);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth < 600 ? 20.0 : 40.0;
            return Stack(
              children: [
                // Subtle atmospheric glows (very faint on white)
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _blue.withValues(alpha: 0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -150,
                  left: -80,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _gold.withValues(alpha: 0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Main content — wrapped in SafeSection to prevent blank page
                SafeSection(
                  title: 'Portfolio Dashboard content',
                  builder: (_) => FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildKpis(context),
                        const SizedBox(height: 28),
                        _buildBento(context),
                        const SizedBox(height: 72),
                      ],
                    ),
                  ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Standard Header ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = FirebaseAuthService.displayNameOrEmail();
    final initials = _userInitials(displayName);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 960;

        final crumb = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _outline),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.view_quilt_outlined, size: 18, color: _muted),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Portfolio workspace overview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                    fontFamily: appFontFamily,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: compact ? 16 : 20),
                    child: Align(
                      alignment:
                          compact ? Alignment.center : Alignment.centerLeft,
                      child: AppLogo(
                        height: compact ? 72 : 88,
                        semanticLabel: 'NDU Project Platform',
                      ),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: _navigateToProjectDashboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0x1A000000),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 22),
                          const SizedBox(width: 10),
                          Text('Create Project',
                              style: TextStyle(fontFamily: appFontFamily)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                    _secondaryCta(
                      label: 'Create Program',
                      onPressed: _navigateToProgram,
                    ),
                    _profileAvatar(user, displayName, initials),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/${AppRoutes.dashboard}');
                    }
                  },
                  color: _muted,
                  tooltip: 'Back',
                ),
                const SizedBox(width: 10),
                Expanded(child: crumb),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Executive Portfolio Dashboard',
              style: TextStyle(
                color: _onSurface,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                fontFamily: appFontFamily,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Strategic overview across all programs, projects, and investments',
              style: TextStyle(
                color: _muted,
                fontSize: 15,
                fontFamily: appFontFamily,
              ),
            ),
          ],
        );
      },
    );
  }

  String _userInitials(String displayName) {
    if (displayName.isEmpty) return 'U';
    final parts =
        displayName.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return displayName.substring(0, 1).toUpperCase();
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Widget _profileAvatar(User? user, String displayName, String initials) {
    final photoUrl = user?.photoURL;
    return PopupMenuButton<String>(
      tooltip: displayName,
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 4,
      icon: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _surfaceHigh,
          border: Border.all(color: _outline, width: 1),
        ),
        child: ClipOval(
          child: photoUrl != null && photoUrl.isNotEmpty
              ? Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: _onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: appFontFamily,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: appFontFamily,
                    ),
                  ),
                ),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                  fontFamily: appFontFamily,
                ),
              ),
              if (user?.email != null && user!.email!.isNotEmpty)
                Text(
                  user.email!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontFamily: appFontFamily,
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: _crimson),
              const SizedBox(width: 10),
              Text('Log Out',
                  style: TextStyle(color: _crimson, fontFamily: appFontFamily)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          _handleLogout();
        }
      },
    );
  }

  Widget _secondaryCta({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _onSurface,
        backgroundColor: Colors.white,
        side: BorderSide(color: _outline),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontFamily: appFontFamily)),
          const SizedBox(width: 8),
          Icon(icon ?? Icons.keyboard_arrow_right, size: 20),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      try {
        await FirebaseAuthService.signOut();
        if (mounted) {
          context.go('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToProjectDashboard() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/${AppRoutes.dashboard}');
      }
    });
  }

  void _navigateToProgram() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/${AppRoutes.programDashboard}');
      }
    });
  }

  Widget _buildKpis(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 1000;
    final isTablet = screenWidth > 600;
    final sp = 16.0;
    final kpis = [
      ('Total Projects', '156', Icons.inventory_2_rounded, _blue, '+12% vs LY', _emerald, Icons.trending_up_rounded, null, null),
      ('On Track', '32%', Icons.check_circle_rounded, _emerald, '50 Projects', _muted, null, _emerald, null),
      ('At Risk', '41%', Icons.warning_amber_rounded, _amber, '64 Projects', _muted, null, _amber, null),
      ('Off Track', '27%', Icons.error_outline_rounded, _crimson, '42 Projects', _muted, null, _crimson, null),
      ('Total Budget', '\$1.2B', Icons.account_balance_wallet_rounded, _blue, 'FY24/25 Allocation', _muted, null, null, null),
      ('Budget Spent', '\$780M', Icons.payments_rounded, _gold, '65% utilized', _muted, null, null, 0.65),
    ];

    // Desktop: all 6 cards in one row using Expanded (never wraps)
    if (isDesktop) {
      return Row(
        children: kpis.asMap().entries.map((entry) {
          final i = entry.key;
          final k = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < kpis.length - 1 ? sp : 0),
              child: _kpi(k),
            ),
          );
        }).toList(),
      );
    }

    // Tablet/mobile: use Wrap with 3 or 2 per row
    final count = isTablet ? 3 : 2;
    final w = (screenWidth - 64 - sp * (count - 1)) / count;
    return Wrap(spacing: sp, runSpacing: sp, children: kpis.map((k) => SizedBox(width: w, child: _kpi(k))).toList());
  }

  Widget _kpi(dynamic k) {
    return _glassCard(glow: k.$4 as Color?, blur: 20, child: Stack(children: [
      if (k.$4 != null) Positioned(top: 0, left: 0, right: 0, child: Container(height: 3, decoration: BoxDecoration(gradient: LinearGradient(colors: [(k.$4 as Color), (k.$4 as Color).withValues(alpha: 0)])))),
      if (k.$8 != null) Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 3, decoration: BoxDecoration(color: k.$8 as Color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))))),
      Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k.$1 as String, style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3, fontFamily: appFontFamily)),
          Container(width: 32, height: 32, decoration: BoxDecoration(color: (k.$4 as Color).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(k.$3 as IconData, color: k.$4 as Color, size: 16)),
        ]),
        const SizedBox(height: 14),
        ShaderMask(shaderCallback: (b) => ((k.$4 == _gold) ? _goldGrad : LinearGradient(colors: [_onSurface, _onSurface])).createShader(b), child: Text(k.$2 as String, style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1, fontFamily: appFontFamily))),
        const SizedBox(height: 6),
        if (k.$9 != null) ...[ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: k.$9 as double, backgroundColor: _surfaceHighest, valueColor: AlwaysStoppedAnimation(_gold), minHeight: 4)), const SizedBox(height: 4)],
        Row(children: [
          if (k.$7 != null) Icon(k.$7 as IconData, color: k.$6 as Color, size: 12),
          if (k.$7 != null) const SizedBox(width: 3),
          Text(k.$5 as String, style: TextStyle(color: k.$6 as Color, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: appFontFamily)),
        ]),
      ])),
    ]));
  }

  Widget _buildBento(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w > 1000;
    return Column(children: [
      if (isDesktop) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 8, child: _portfolioTable()), const SizedBox(width: 20), Expanded(flex: 4, child: _buChart())])
      else ...[_portfolioTable(), const SizedBox(height: 20), _buChart()],
      const SizedBox(height: 20),
      if (isDesktop) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 4, child: _budgetTrend()), const SizedBox(width: 20), Expanded(flex: 4, child: _risksDonut()), const SizedBox(width: 20), Expanded(flex: 4, child: _portfolioAllocation())])
      else ...[_budgetTrend(), const SizedBox(height: 20), _risksDonut(), const SizedBox(height: 20), _portfolioAllocation()],
      const SizedBox(height: 20),
      if (isDesktop) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: _upcoming()), const SizedBox(width: 20), Expanded(flex: 6, child: _overdue())])
      else ...[_upcoming(), const SizedBox(height: 20), _overdue()],
      const SizedBox(height: 20),
      if (isDesktop) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 4, child: _portfolioPerformance()), const SizedBox(width: 20), Expanded(flex: 4, child: _strategicAlignment()), const SizedBox(width: 20), Expanded(flex: 4, child: _resourceUtilization())])
      else ...[_portfolioPerformance(), const SizedBox(height: 20), _strategicAlignment(), const SizedBox(height: 20), _resourceUtilization()],
    ]);
  }

  Widget _portfolioTable() {
    final ps = [
      ('Project Alpha', 'On Track', _emerald, [_emerald, _emerald, _emerald], '12', '5', '30 Jun 2024', null),
      ('Project Beta', 'At Risk', _amber, [_amber, _emerald, _emerald], '28', '9', '15 Aug 2024', null),
      ('Project Gamma', 'On Track', _emerald, [_emerald, _amber, _emerald], '15', '7', '10 Jul 2024', null),
      ('Project Delta', 'Off Track', _crimson, [_crimson, _crimson, _amber], '42', '18', 'Delayed', _crimson),
      ('Project Epsilon', 'On Track', _emerald, [_emerald, _emerald, _emerald], '4', '2', '31 May 2024', null),
    ];
    return _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Portfolio Health Overview', style: TextStyle(color: _onSurface, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, fontFamily: appFontFamily)),
        Row(children: [_pillBtn('View All'), const SizedBox(width: 8), _pillBtn('Filter')]),
      ])),
      Divider(height: 1, color: _outline.withValues(alpha: 0.2)),
      ...List.generate(ps.length, (i) {
        final p = ps[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: i.isOdd ? _surface.withValues(alpha: 0.3) : Colors.transparent, border: i < ps.length - 1 ? Border(bottom: BorderSide(color: _outline.withValues(alpha: 0.1))) : null),
          child: Row(children: [
            Expanded(flex: 3, child: Row(children: [Container(width: 4, height: 28, decoration: BoxDecoration(color: p.$3, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Text(p.$1, style: TextStyle(color: _onSurface, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: appFontFamily))])),
            Expanded(flex: 2, child: Row(children: [_dot(p.$3), const SizedBox(width: 8), Text(p.$2, style: TextStyle(color: _muted, fontSize: 13, fontFamily: appFontFamily))])),
            Expanded(flex: 2, child: Row(children: p.$4.map<Widget>((c) => Padding(padding: const EdgeInsets.only(right: 6), child: _dot(c, size: 7))).toList())),
            Expanded(child: Center(child: _badge(p.$5, high: int.parse(p.$5) > 30))),
            Expanded(child: Center(child: _badge(p.$6))),
            Expanded(flex: 2, child: Text(p.$7, style: TextStyle(color: p.$8 ?? _muted, fontSize: 13, fontWeight: p.$8 != null ? FontWeight.w700 : FontWeight.w400, fontFamily: appFontFamily))),
          ]),
        );
      }),
    ]));
  }

  Widget _dot(Color c, {double size = 8}) => Container(width: size, height: size, decoration: BoxDecoration(color: c, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]));
  Widget _badge(String count, {bool high = false}) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: high ? _crimson.withValues(alpha: 0.12) : _surfaceHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: high ? _crimson.withValues(alpha: 0.3) : _outline.withValues(alpha: 0.3))), child: Text(count, style: TextStyle(color: high ? _crimsonBright : _onSurface, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: appFontFamily)));
  Widget _pillBtn(String label) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: _surfaceHighest.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16), border: Border.all(color: _outline.withValues(alpha: 0.3))), child: Text(label, style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: appFontFamily)));

  Widget _buChart() {
    final us = [('IT Infrastructure', 28, 0.80, _blue), ('HR Transformation', 24, 0.70, _gold), ('Customer Experience', 24, 0.70, const Color(0xFF9CA3AF)), ('Strategic Sales', 18, 0.55, _surfaceHighest)];
    return _glassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PROJECTS BY BUSINESS UNIT', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontFamily: appFontFamily)),
      const SizedBox(height: 20),
      ...us.map((u) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(u.$1, style: TextStyle(color: _onSurface, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: appFontFamily)), Text('${u.$2}', style: TextStyle(color: u.$4 == _surfaceHighest ? _muted : u.$4, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: appFontFamily))]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Stack(children: [Container(height: 22, decoration: BoxDecoration(color: _surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8))), FractionallySizedBox(widthFactor: u.$3, child: Container(height: 22, decoration: BoxDecoration(gradient: LinearGradient(colors: [u.$4, u.$4.withValues(alpha: 0.6)]), borderRadius: BorderRadius.circular(8), boxShadow: u.$4 != _surfaceHighest ? [BoxShadow(color: u.$4.withValues(alpha: 0.3), blurRadius: 8)] : null)))])),
      ]))),
    ])));
  }

  Widget _budgetTrend() {
    final ms = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final hs = [0.40, 0.45, 0.55, 0.65, 0.85, 0.50];
    return _glassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BUDGET UTILIZATION TREND', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontFamily: appFontFamily)),
      const SizedBox(height: 24),
      SizedBox(height: 160, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(6, (i) {
        final hl = i == 4;
        return Container(width: 24, decoration: BoxDecoration(gradient: hl ? LinearGradient(colors: [_blue, _blueDeep], begin: Alignment.bottomCenter, end: Alignment.topCenter) : LinearGradient(colors: [_blue.withValues(alpha: 0.15), _blue.withValues(alpha: 0.05)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(6)), boxShadow: hl ? [BoxShadow(color: _blue.withValues(alpha: 0.3), blurRadius: 12)] : null), height: 160 * hs[i]);
      }))),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ms.map((m) => Text(m, style: TextStyle(color: _muted.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600, fontFamily: appFontFamily))).toList()),
    ])));
  }

  Widget _risksDonut() {
    return _glassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('RISKS BY CATEGORY', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontFamily: appFontFamily)),
      const SizedBox(height: 20),
      Row(children: [
        SizedBox(width: 110, height: 110, child: CustomPaint(painter: _DonutPainter(segments: [(_crimson, 0.25), (_amber, 0.30), (_emerald, 0.45)], trackColor: _surfaceHighest.withValues(alpha: 0.4)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('248', style: TextStyle(color: _onSurface, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: appFontFamily)), Text('TOTAL', style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.w600, fontFamily: appFontFamily))])))),
        const SizedBox(width: 24),
        Expanded(child: Column(children: [_rLeg('Strategic', '25%', _crimson), const SizedBox(height: 10), _rLeg('Technical', '30%', _amber), const SizedBox(height: 10), _rLeg('Resource', '45%', _emerald)])),
      ]),
    ])));
  }

  Widget _rLeg(String l, String p, Color c) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 4)])), const SizedBox(width: 8), Text(l, style: TextStyle(color: _onSurface, fontSize: 11, fontFamily: appFontFamily))]), Text(p, style: TextStyle(color: _onSurface, fontSize: 12, fontWeight: FontWeight.w800, fontFamily: appFontFamily))]);

  // ─── Portfolio Allocation by Phase ────────────────────────────────────────
  Widget _portfolioAllocation() {
    final phases = [
      ('Initiation', 12, 0.08, _blue),
      ('Planning', 28, 0.18, _blueDeep),
      ('Execution', 68, 0.44, _gold),
      ('Monitoring', 32, 0.20, _emerald),
      ('Closeout', 16, 0.10, _muted),
    ];
    return _glassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PORTFOLIO ALLOCATION BY PHASE', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontFamily: appFontFamily)),
      const SizedBox(height: 20),
      // Stacked bar
      ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(height: 28, child: Row(children: phases.map((p) => Expanded(flex: (p.$2 * 10).round(), child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [p.$4, p.$4.withValues(alpha: 0.7)]))))).toList()))),
      const SizedBox(height: 16),
      ...phases.map((p) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: p.$4, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 8), Text(p.$1, style: TextStyle(color: _onSurface, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: appFontFamily))]),
        Text('${p.$2} (${(p.$3 * 100).round()}%)', style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: appFontFamily)),
      ]))),
    ])));
  }

  // ─── Portfolio Performance Scorecard ──────────────────────────────────────
  Widget _portfolioPerformance() {
    final metrics = [
      ('SPI', '0.94', _amber, 'Schedule Perf. Index'),
      ('CPI', '0.87', _crimson, 'Cost Perf. Index'),
      ('ROI', '12.3%', _emerald, 'Return on Investment'),
      ('NPS', '68', _emerald, 'Net Promoter Score'),
    ];
    return _glassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PORTFOLIO PERFORMANCE', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontFamily: appFontFamily)),
      const SizedBox(height: 20),
      ...metrics.map((m) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: m.$3.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(m.$1, style: TextStyle(color: m.$3, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: appFontFamily)))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.$1, style: TextStyle(color: _onSurface, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: appFontFamily)),
            Text(m.$4, style: TextStyle(color: _muted, fontSize: 10, fontFamily: appFontFamily)),
          ]),
        ]),
        Text(m.$2, style: TextStyle(color: m.$3, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: appFontFamily)),
      ]))),
    ])));
  }

  // ─── Strategic Alignment ──────────────────────────────────────────────────
  Widget _strategicAlignment() {
    final goals = [
      ('Digital Transformation', 42, _blue),
      ('Operational Excellence', 38, _emerald),
      ('Customer Experience', 34, _gold),
      ('Risk Mitigation', 22, _crimson),
      ('Revenue Growth', 20, _blueDeep),
    ];
    return _glassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('STRATEGIC GOAL ALIGNMENT', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontFamily: appFontFamily)),
      const SizedBox(height: 20),
      ...goals.map((g) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(g.$1, style: TextStyle(color: _onSurface, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: appFontFamily)),
          Text('${g.$2}', style: TextStyle(color: g.$3, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: appFontFamily)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: g.$2 / 50, backgroundColor: _surfaceHighest, valueColor: AlwaysStoppedAnimation(g.$3), minHeight: 6)),
      ]))),
    ])));
  }

  // ─── Resource Utilization ─────────────────────────────────────────────────
  Widget _resourceUtilization() {
    final resources = [
      ('Engineering', 78, _blue, '42 FTE allocated'),
      ('Project Mgmt', 92, _amber, '18 PMs assigned'),
      ('Procurement', 65, _emerald, '9 specialists'),
      ('Quality', 54, _gold, '7 inspectors'),
      ('Construction', 88, _crimson, '156 crew'),
    ];
    return _glassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('RESOURCE UTILIZATION', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontFamily: appFontFamily)),
      const SizedBox(height: 20),
      ...resources.map((r) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Text(r.$1, style: TextStyle(color: _onSurface, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: appFontFamily)), const SizedBox(width: 8), Text(r.$4, style: TextStyle(color: _muted, fontSize: 10, fontFamily: appFontFamily))]),
          Text('${r.$2}%', style: TextStyle(color: r.$2 > 85 ? _crimson : (r.$2 > 75 ? _amber : r.$3), fontSize: 14, fontWeight: FontWeight.w800, fontFamily: appFontFamily)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: r.$2 / 100, backgroundColor: _surfaceHighest, valueColor: AlwaysStoppedAnimation(r.$2 > 85 ? _crimson : (r.$2 > 75 ? _amber : r.$3)), minHeight: 6)),
      ]))),
    ])));
  }

  Widget _upcoming() {
    final ms = [('Requirement Sign-off', 'Project Beta', '22 May 2024', null), ('Database Migration', 'Project Gamma', '28 May 2024', null), ('Security Audit Completion', 'Project Alpha', '01 Jun 2024', _emerald)];
    return _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('UPCOMING MILESTONES (30 DAYS)', style: TextStyle(color: _onSurface, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, fontFamily: appFontFamily)), Container(width: 28, height: 28, decoration: BoxDecoration(color: _gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.event, color: _gold, size: 14))])),
      Divider(height: 1, color: _outline.withValues(alpha: 0.15)),
      ...ms.map((m) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(m.$1, style: TextStyle(color: _gold.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: appFontFamily))), Text(m.$2, style: TextStyle(color: _muted, fontSize: 12, fontFamily: appFontFamily)), const SizedBox(width: 12), Text(m.$3, style: TextStyle(color: m.$4 ?? _muted, fontSize: 12, fontWeight: m.$4 != null ? FontWeight.w700 : FontWeight.w400, fontFamily: appFontFamily))]))),
    ]));
  }

  Widget _overdue() {
    final os = [('UAT Start Phase', 'Project Delta', '12 Days', true), ('Vendor Final Payment', 'Project Zeta', '5 Days', false), ('Training Modules Delivery', 'Project Eta', '3 Days', false)];
    return _glassCard(glow: _crimson, blur: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), decoration: BoxDecoration(color: _crimson.withValues(alpha: 0.06), border: Border(bottom: BorderSide(color: _crimson.withValues(alpha: 0.15)))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('OVERDUE MILESTONES', style: TextStyle(color: _crimsonBright, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, fontFamily: appFontFamily)), Container(width: 28, height: 28, decoration: BoxDecoration(color: _crimson.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.dangerous, color: _crimsonBright, size: 14))])),
      ...os.map((m) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(m.$1, style: TextStyle(color: _onSurface, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: appFontFamily))), Text(m.$2, style: TextStyle(color: _muted, fontSize: 12, fontFamily: appFontFamily)), const SizedBox(width: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(gradient: m.$4 ? LinearGradient(colors: [_crimson, _crimsonBright]) : null, color: m.$4 ? null : _crimson.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), boxShadow: m.$4 ? [BoxShadow(color: _crimson.withValues(alpha: 0.3), blurRadius: 8)] : null), child: Text(m.$3, style: TextStyle(color: m.$4 ? Colors.white : _crimsonBright, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: appFontFamily)))]))),
    ]));
  }
}

class _DonutPainter extends CustomPainter {
  final List<(Color, double)> segments;
  final Color trackColor;
  _DonutPainter({required this.segments, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const sw = 10.0;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - sw / 2, paint..color = trackColor);
    double start = -90 * 3.14159 / 180;
    const gap = 0.04;
    for (final (color, frac) in segments) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - sw / 2), start, frac * 2 * 3.14159 - gap, false, paint..color = color);
      start += frac * 2 * 3.14159;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
