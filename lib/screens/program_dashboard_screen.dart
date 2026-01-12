/// NDU Program Dashboard — Light Mode
///
/// Program workspace overview dashboard rendered with the standard app shell:
///
/// - Light/white theme matching the rest of the app
/// - Standard header (logo + breadcrumb + nav buttons + profile avatar with logout)
/// - No sidebar (full-width dashboard, like Portfolio Dashboard)
/// - Hero bento grid: Budget KPI + Planned vs Actual chart + Radial progress gauge
/// - Project Health Matrix table with sparkline budget trends
/// - Critical Risks + Resource Capacity side-by-side
/// - Escalation Summary + Recent Activity timeline + Visual Context card
/// - Floating Action Button
/// - Custom radial gauge painter with animated sweep
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
<<<<<<< HEAD
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/navigation_context_service.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/app_logo.dart';
=======
import 'package:firebase_auth/firebase_auth.dart';

import '../routing/app_router.dart';
import '../models/program_model.dart';
import '../services/navigation_context_service.dart';
import '../services/program_service.dart';
import '../services/project_service.dart';
import '../services/project_navigation_service.dart';
import '../utils/navigation_route_resolver.dart';
import '../providers/project_data_provider.dart';
import '../screens/initiation_phase_screen.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/kaz_ai_chat_bubble.dart';
>>>>>>> 1ee471ae (Merge codebases)

class ProgramDashboardScreen extends StatefulWidget {
  final String? programId;

  const ProgramDashboardScreen({super.key, this.programId});

  static void open(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProgramDashboardScreen()));
  }

  @override
  State<ProgramDashboardScreen> createState() => _ProgramDashboardScreenState();
}

class _ProgramDashboardScreenState extends State<ProgramDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _fadeController;
  late Animation<double> _gaugeAnim;
  late Animation<double> _fadeAnim;

  // ─── Design Tokens (light theme, aligned with the rest of the app) ────────
  static const _bg = Colors.white;
  static const _surface = Color(0xFFF9FAFB);
  static const _surfaceHigh = Color(0xFFF3F4F6);
  static const _surfaceHighest = Color(0xFFE5E7EB);
  static const _onSurface = Color(0xFF1A1D1F);
  static const _onSurfaceVariant = Color(0xFF6B7280);
  static const _outlineVariant = Color(0xFFE4E7EC);
  static const _primary = Color(0xFF1A1D1F);
  static const _primaryContainer = Color(0xFFE5E7EB);
  static const _tertiary = Color(0xFFFFC107);
  static const _tertiaryContainer = Color(0xFFFBBF24);
  static const _secondary = Color(0xFF3B82F6);
  static const _emerald = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);
  static const _crimson = Color(0xFFEF4444);
  static const _onTertiary = Color(0xFF1A1D1F);

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _gaugeAnim =
        CurvedAnimation(parent: _gaugeController, curve: Curves.easeOutCubic);
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _gaugeController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ─── Surface Card (replaces the dark glassmorphism card) ─────────────────
  Widget _surfaceCard({
    required Widget child,
    Color? leftBorder,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: leftBorder != null
              ? BorderSide(color: leftBorder, width: 4)
              : BorderSide.none,
          top: BorderSide(color: _outlineVariant, width: 1),
          right: BorderSide(color: _outlineVariant, width: 1),
          bottom: BorderSide(color: _outlineVariant, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: padding == EdgeInsets.zero
            ? child
            : Padding(padding: padding, child: child),
      ),
    );
  }

  // ─── Logout (used by the profile avatar dropdown) ────────────────────────
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

  void _navigateToPortfolio() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/${AppRoutes.portfolioDashboard}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Record this dashboard so the brand logo knows where to return on tap.
    NavigationContextService.instance
        .setLastClientDashboard(AppRoutes.programDashboard);

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: _tertiary,
        foregroundColor: _onTertiary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 600 ? 20.0 : 40.0;
            return FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildHeroBento(context),
                    const SizedBox(height: 24),
                    _buildMainGrid(context),
                    const SizedBox(height: 72),
                  ],
                ),
              ),
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
            border: Border.all(color: _outlineVariant),
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
              Icon(Icons.view_quilt_outlined,
                  size: 18, color: _onSurfaceVariant),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Program workspace overview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _onSurfaceVariant,
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
                        backgroundColor: _secondary,
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
                      label: 'Create Portfolio',
                      onPressed: _navigateToPortfolio,
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
                  color: _onSurfaceVariant,
                  tooltip: 'Back',
                ),
                const SizedBox(width: 10),
                Expanded(child: crumb),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Program Alpha Dashboard',
              style: TextStyle(
                color: _primary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                fontFamily: appFontFamily,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Infrastructure Modernization & Global Expansion',
              style: TextStyle(
                color: _onSurfaceVariant,
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
          color: _primaryContainer,
          border: Border.all(color: _outlineVariant, width: 1),
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
                        color: _primary,
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
                      color: _primary,
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
                  color: _primary,
                  fontFamily: appFontFamily,
                ),
              ),
              if (user?.email != null && user!.email!.isNotEmpty)
                Text(
                  user.email!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _onSurfaceVariant,
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
        foregroundColor: _primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: _outlineVariant),
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

  // ─── Hero Bento Grid ─────────────────────────────────────────────────────
  Widget _buildHeroBento(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Desktop (>1180): 3-column hero bento
    // Tablet (700-1180): 2-column (KPI + chart side-by-side, gauge below)
    // Mobile (<700): stacked vertically
    if (width > 1180) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: _budgetKpi()),
        const SizedBox(width: 24),
        Expanded(flex: 6, child: _plannedVsActual()),
        const SizedBox(width: 24),
        Expanded(flex: 3, child: _progressGauge()),
      ]);
    }
    if (width >= 700) {
      return Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: _budgetKpi()),
          const SizedBox(width: 24),
          Expanded(flex: 6, child: _plannedVsActual()),
        ]),
        const SizedBox(height: 24),
        _progressGauge(),
      ]);
    }
    return Column(children: [
      _budgetKpi(),
      const SizedBox(height: 24),
      SizedBox(height: 220, child: _plannedVsActual()),
      const SizedBox(height: 24),
      _progressGauge(),
    ]);
  }

  Widget _budgetKpi() {
    return _surfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('TOTAL BUDGET',
                  style: TextStyle(
                      color: _onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      fontFamily: appFontFamily)),
              Icon(Icons.payments, color: _onSurfaceVariant, size: 20),
            ]),
            const SizedBox(height: 16),
            Text('\$42.8M',
                style: TextStyle(
                    color: _primary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    fontFamily: appFontFamily)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.trending_down, color: _emerald, size: 14),
              const SizedBox(width: 4),
              Text('2.4% below forecast',
                  style: TextStyle(
                      color: _emerald,
                      fontSize: 14,
                      fontFamily: appFontFamily)),
            ]),
          ]),
          const SizedBox(height: 32),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: 0.68,
                backgroundColor: _surfaceHighest,
                valueColor: const AlwaysStoppedAnimation(_tertiary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('EXPENDED: \$29.1M',
                  style: TextStyle(
                      color: _onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontFamily: appFontFamily)),
              Text('68%',
                  style: TextStyle(
                      color: _onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: appFontFamily)),
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _plannedVsActual() {
    final planned = [0.40, 0.55, 0.70, 0.85, 0.65, 0.90];
    final actual = [0.38, 0.52, 0.72, 0.88, 0.60, 0.95];
    final labels = ['Q1', 'Q2', 'Q3', 'Q4', 'FY24', 'FY25'];

    return _surfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('PLANNED VS ACTUAL COST',
                style: TextStyle(
                    color: _onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    fontFamily: appFontFamily)),
            Row(children: [
              _legendDot('Planned', _tertiary),
              const SizedBox(width: 12),
              _legendDot('Actual', _secondary),
            ]),
          ]),
          const SizedBox(height: 24),
          // Chart area — fixed height so bars can size as a fraction of it
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxBarHeight = constraints.maxHeight - 4;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(planned.length, (i) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Planned bar
                        Container(
                          width: 12,
                          decoration: BoxDecoration(
                            color: _tertiary.withValues(alpha: 0.55),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2)),
                          ),
                          height: (maxBarHeight * planned[i])
                              .clamp(2.0, maxBarHeight),
                        ),
                        const SizedBox(width: 2),
                        // Actual bar
                        Container(
                          width: 12,
                          decoration: BoxDecoration(
                            color: _secondary,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2)),
                          ),
                          height: (maxBarHeight * actual[i])
                              .clamp(2.0, maxBarHeight),
                        ),
                      ],
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: labels
                .map((l) => Text(l,
                    style: TextStyle(
                        color: _onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: appFontFamily)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              color: _onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: appFontFamily)),
    ]);
  }

  Widget _progressGauge() {
    return _surfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: AnimatedBuilder(
              animation: _gaugeAnim,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RadialGaugePainter(
                    progress: _gaugeAnim.value * 72,
                    fillColor: _tertiary,
                    trackColor: _surfaceHighest,
                  ),
                  child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${(_gaugeAnim.value * 72).round()}%',
                              style: TextStyle(
                                  color: _primary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: appFontFamily)),
                          Text('COMPLETED',
                              style: TextStyle(
                                  color: _onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: appFontFamily)),
                        ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text('GLOBAL PROGRESS',
              style: TextStyle(
                  color: _onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  fontFamily: appFontFamily)),
        ],
      ),
    );
  }

  // ─── Main Grid ───────────────────────────────────────────────────────────
  Widget _buildMainGrid(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Desktop (>1180): 2-column main grid (8:4)
    // Tablet (700-1180): 1-column main grid (left column above, then right column)
    // Mobile (<700): stacked vertically
    if (width > 1180) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 8, child: _leftColumn()),
        const SizedBox(width: 24),
        Expanded(flex: 4, child: _rightColumn()),
      ]);
    }
    return Column(children: [
      _leftColumn(),
      const SizedBox(height: 24),
      _rightColumn(),
    ]);
  }

  // ─── Left Column: Health Matrix + Risks + Capacity ───────────────────────
  Widget _leftColumn() {
    final width = MediaQuery.sizeOf(context).width;
    final sideBySide = width > 1180;
    if (sideBySide) {
      return Column(children: [
        _healthMatrix(),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _criticalRisks()),
          const SizedBox(width: 24),
          Expanded(child: _resourceCapacity()),
        ]),
      ]);
    }
    return Column(children: [
      _healthMatrix(),
      const SizedBox(height: 24),
      _criticalRisks(),
      const SizedBox(height: 24),
      _resourceCapacity(),
    ]);
  }

  Widget _healthMatrix() {
    final projects = [
      (
        'Project Phoenix',
        'Cloud Integration',
        'Healthy',
        _emerald,
        [0.2, 0.4, 0.6, 1.0],
        'On Track',
        '92%',
        null
      ),
      (
        'Data Lake 2.0',
        'Architecture Shift',
        'At Risk',
        _amber,
        [1.0, 0.6, 0.4, 0.2],
        'Delayed (2w)',
        '45%',
        _amber
      ),
      (
        'CyberShield v4',
        'Security Audit',
        'Critical',
        _crimson,
        [0.8, 1.0, 0.5, 0.2],
        'Stalled',
        '12%',
        _crimson
      ),
      (
        'Project Titan',
        'Heavy Infrastructure',
        'Healthy',
        _emerald,
        [0.2, 0.4, 0.6, 1.0],
        'Ahead (1w)',
        '68%',
        null
      ),
      (
        'Edge Connect',
        'IoT Rollout',
        'Healthy',
        _emerald,
        [0.4, 1.0, 0.6, 0.2],
        'On Track',
        '84%',
        null
      ),
    ];

    return _surfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
            decoration: BoxDecoration(
              color: _surfaceHigh,
              border: Border(
                  bottom: BorderSide(
                      color: _outlineVariant.withValues(alpha: 0.6))),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Project Health Matrix',
                      style: TextStyle(
                          color: _primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: appFontFamily)),
                  Icon(Icons.filter_list, color: _onSurfaceVariant, size: 18),
                ]),
          ),
          // Table
          ...List.generate(projects.length, (i) {
            final p = projects[i];
            final altBg = i.isOdd ? _surface : Colors.white;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: altBg,
                border: i < projects.length - 1
                    ? Border(
                        bottom: BorderSide(
                            color: _outlineVariant.withValues(alpha: 0.5)))
                    : null,
              ),
              child: Row(children: [
                // Project name
                Expanded(
                    flex: 3,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.$1,
                              style: TextStyle(
                                  color: _primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: appFontFamily)),
                          Text(p.$2,
                              style: TextStyle(
                                  color: _onSurfaceVariant,
                                  fontSize: 11,
                                  fontFamily: appFontFamily)),
                        ])),
                // Status
                Expanded(
                    flex: 2,
                    child: Row(children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: p.$4,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: p.$4.withValues(alpha: 0.35),
                                    blurRadius: 8)
                              ])),
                      const SizedBox(width: 8),
                      Text(p.$3,
                          style: TextStyle(
                              color: _onSurfaceVariant,
                              fontSize: 13,
                              fontFamily: appFontFamily)),
                    ])),
                // Budget trend sparkline
                Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 24,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: p.$5
                              .map<Widget>((h) => Expanded(
                                  child: Container(
                                      margin: const EdgeInsets.only(right: 1),
                                      decoration: BoxDecoration(
                                          color: p.$4.withValues(
                                              alpha: h == 1.0 ? 1.0 : h * 0.6),
                                          borderRadius:
                                              BorderRadius.circular(1)),
                                      height: 24 * h)))
                              .toList()),
                    )),
                // Schedule
                Expanded(
                    flex: 2,
                    child: Text(p.$6,
                        style: TextStyle(
                            color: p.$8 ?? _onSurface,
                            fontSize: 13,
                            fontFamily: appFontFamily))),
                // Progress
                Expanded(
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(p.$7,
                            style: TextStyle(
                                color: _primary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: appFontFamily)))),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _criticalRisks() {
    final risks = [
      (
        'Resource Burnout - Project Titan',
        'Key developers at 140% capacity for 6+ weeks.',
        _crimson,
        Icons.report,
        true
      ),
      (
        'Hardware Lead-Time Delay',
        'Global supply chain constraints impacting Phase 3.',
        _amber,
        Icons.warning,
        true
      ),
      (
        'Budget Re-allocation Needed',
        'Surplus from Project Phoenix could offset Data Lake.',
        _onSurfaceVariant,
        Icons.info,
        false
      ),
    ];

    return _surfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Critical Risks',
              style: TextStyle(
                  color: _primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: appFontFamily)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: _crimson.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4)),
            child: Text('3 HIGH PRIORITY',
                style: TextStyle(
                    color: _crimson,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: appFontFamily)),
          ),
        ]),
        const SizedBox(height: 24),
        ...risks.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: r.$3.withValues(alpha: r.$5 ? 0.45 : 0.25)),
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(r.$4, color: r.$3, size: 18),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(r.$1,
                          style: TextStyle(
                              color: _primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: appFontFamily)),
                      const SizedBox(height: 4),
                      Text(r.$2,
                          style: TextStyle(
                              color: _onSurfaceVariant,
                              fontSize: 11,
                              fontFamily: appFontFamily)),
                    ])),
              ]),
            )),
      ]),
    );
  }

  Widget _resourceCapacity() {
    final resources = [
      ('Engineering', 98, _crimson),
      ('DevOps / Cloud', 72, _emerald),
      ('Security Analysis', 85, _amber),
      ('UX / Design', 40, _emerald),
    ];

    return _surfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Resource Capacity',
              style: TextStyle(
                  color: _primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: appFontFamily)),
          Text('ACROSS PROJECTS',
              style: TextStyle(
                  color: _onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  fontFamily: appFontFamily)),
        ]),
        const SizedBox(height: 24),
        ...resources.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r.$1,
                              style: TextStyle(
                                  color: _onSurfaceVariant,
                                  fontSize: 11,
                                  fontFamily: appFontFamily)),
                          Text('${r.$2}%',
                              style: TextStyle(
                                  color: r.$3,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: appFontFamily)),
                        ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: r.$2 / 100,
                        backgroundColor: _surfaceHighest,
                        valueColor: AlwaysStoppedAnimation(r.$3),
                        minHeight: 6,
                      ),
                    ),
                  ]),
            )),
      ]),
    );
  }

  // ─── Right Column: Escalations + Activity + Visual Context ───────────────
  Widget _rightColumn() {
    return Column(children: [
      _escalationSummary(),
      const SizedBox(height: 24),
      _recentActivity(),
      const SizedBox(height: 24),
      _visualContext(),
    ]);
  }

  Widget _escalationSummary() {
    return _surfaceCard(
      leftBorder: _amber,
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.priority_high, color: _amber, size: 18),
          const SizedBox(width: 8),
          Text('ESCALATION SUMMARY',
              style: TextStyle(
                  color: _amber,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontFamily: appFontFamily)),
        ]),
        const SizedBox(height: 16),
        // Escalation 1
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _surfaceHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _outlineVariant.withValues(alpha: 0.6)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('OPEN APPROVAL',
                style: TextStyle(
                    color: _onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontFamily: appFontFamily)),
            const SizedBox(height: 4),
            Text(
                'Project Titan requires +\$2.5M additional contingency approval by EOD Friday.',
                style: TextStyle(
                    color: _primary, fontSize: 13, fontFamily: appFontFamily)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {},
              child: Row(children: [
                Text('REVIEW DETAILS',
                    style: TextStyle(
                        color: _tertiaryContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: appFontFamily)),
                Icon(Icons.arrow_forward, color: _tertiaryContainer, size: 12),
              ]),
            ),
          ]),
        ),
        // Escalation 2
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _outlineVariant.withValues(alpha: 0.6)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SCHEDULE REVISION',
                style: TextStyle(
                    color: _onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontFamily: appFontFamily)),
            const SizedBox(height: 4),
            Text(
                'Baseline shift requested for CyberShield v4 due to legislative changes.',
                style: TextStyle(
                    color: _primary, fontSize: 13, fontFamily: appFontFamily)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {},
              child: Row(children: [
                Text('REVIEW DETAILS',
                    style: TextStyle(
                        color: _tertiaryContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: appFontFamily)),
                Icon(Icons.arrow_forward, color: _tertiaryContainer, size: 12),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _recentActivity() {
    final activities = [
      (
        'M. Chen pushed a budget update',
        'Project Phoenix  •  22 mins ago',
        _primary
      ),
      (
        'Milestone Reached: Q3 Cloud Gate',
        'Data Lake 2.0  •  2 hours ago',
        _emerald
      ),
      ('Risk Level Updated to Medium', 'Edge Connect  •  5 hours ago', _amber),
      (
        'S. Rossi added a comment',
        'Resource Allocation  •  Yesterday',
        _primary
      ),
    ];

    return _surfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RECENT ACTIVITY',
            style: TextStyle(
                color: _onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontFamily: appFontFamily)),
        const SizedBox(height: 24),
        // Timeline — each row is a self-contained horizontal layout
        // (dot + connector on the left, text on the right). No Positioned
        // widgets, so no Stack-constraint issues.
        Column(
          children: List.generate(activities.length, (i) {
            final a = activities[i];
            final isLast = i == activities.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline gutter: dot + vertical line below
                  SizedBox(
                    width: 16,
                    child: Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _outlineVariant.withValues(alpha: 0.8)),
                          ),
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: a.$3, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 1,
                              color: _outlineVariant.withValues(alpha: 0.7),
                              margin: const EdgeInsets.only(top: 4),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.$1,
                              style: TextStyle(
                                  color: _primary,
                                  fontSize: 12,
                                  fontFamily: appFontFamily)),
                          const SizedBox(height: 2),
                          Text(a.$2,
                              style: TextStyle(
                                  color: _onSurfaceVariant,
                                  fontSize: 10,
                                  fontFamily: appFontFamily)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _visualContext() {
    return _surfaceCard(
      child: Container(
        height: 192,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.white, _surfaceHigh],
          ),
        ),
        child: Stack(children: [
          // Light gradient overlay
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _surfaceHigh.withValues(alpha: 0.4),
                            Colors.white.withValues(alpha: 0.8)
                          ])))),
          // City silhouette shapes (light gray)
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _cityBuilding(
                        40, 60, _surfaceHighest.withValues(alpha: 0.7)),
                    _cityBuilding(
                        30, 80, _surfaceHighest.withValues(alpha: 0.55)),
                    _cityBuilding(
                        50, 100, _surfaceHighest.withValues(alpha: 0.8)),
                    _cityBuilding(
                        35, 70, _surfaceHighest.withValues(alpha: 0.6)),
                    _cityBuilding(
                        45, 90, _surfaceHighest.withValues(alpha: 0.75)),
                    _cityBuilding(
                        30, 50, _surfaceHighest.withValues(alpha: 0.5)),
                  ])),
          // Glow spots
          Positioned(
              top: 20,
              right: 30,
              child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _tertiaryContainer.withValues(alpha: 0.25),
                      boxShadow: [
                        BoxShadow(
                            color: _tertiaryContainer.withValues(alpha: 0.3),
                            blurRadius: 30)
                      ]))),
          Positioned(
              top: 40,
              left: 40,
              child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _secondary.withValues(alpha: 0.18),
                      boxShadow: [
                        BoxShadow(
                            color: _secondary.withValues(alpha: 0.22),
                            blurRadius: 25)
                      ]))),
          // Label
          Positioned(
              bottom: 16,
              left: 16,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VISUAL CONTEXT',
                        style: TextStyle(
                            color: _tertiaryContainer,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontFamily: appFontFamily)),
                    Text('Site A-01 Progress',
                        style: TextStyle(
                            color: _primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: appFontFamily)),
                  ])),
        ]),
      ),
    );
  }

<<<<<<< HEAD
  Widget _cityBuilding(double w, double h, Color c) {
    return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
            color: c,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2), topRight: Radius.circular(2))));
=======
  Future<void> _handleProjectTap(BuildContext context, String projectId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 3),
                SizedBox(height: 16),
                Text(
                  'Loading project...',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final provider = ProjectDataInherited.of(context);
      debugPrint('📥 Calling loadFromFirebase for project: $projectId');
      
      final success = await provider.loadFromFirebase(projectId);

      debugPrint('📤 Load result: $success, error: ${provider.lastError}');

      if (!context.mounted) return;

      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        // Get checkpoint from Firestore (primary source) or fallback to SharedPreferences
        final projectRecord = await ProjectService.getProjectById(projectId);
        final checkpointRoute = projectRecord?.checkpointRoute.isNotEmpty == true
            ? projectRecord!.checkpointRoute
            : await ProjectNavigationService.instance.getLastPage(projectId);
        debugPrint('✅ Project loaded successfully, navigating to checkpoint: $checkpointRoute');
        
        // Resolve checkpoint to screen widget
        final screen = NavigationRouteResolver.resolveCheckpointToScreen(
          checkpointRoute.isEmpty ? 'initiation' : checkpointRoute,
          context,
        );
        
        // Navigate to the resolved screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen ?? const InitiationPhaseScreen()),
        );
      } else {
        debugPrint('❌ Failed to load project: ${provider.lastError}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load project: ${provider.lastError ?? "Unknown error"}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading project: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading project: $e')),
        );
      }
    }
>>>>>>> 1ee471ae (Merge codebases)
  }
}

// ─── Radial Gauge Painter ──────────────────────────────────────────────────
class _RadialGaugePainter extends CustomPainter {
  final double progress; // 0-100
  final Color fillColor;
  final Color trackColor;

  _RadialGaugePainter({
    required this.progress,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 10.0;

    // Track (full circle)
    canvas.drawCircle(
      center,
      radius - strokeWidth / 2,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    final sweepAngle = (progress / 100) * 2 * 3.14159265;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -3.14159265 / 2, // start from top
      sweepAngle,
      false,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Inner radial gradient effect (very subtle on light theme)
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [fillColor.withValues(alpha: 0.06), Colors.transparent],
        radius: 0.85,
      ).createShader(
          Rect.fromCircle(center: center, radius: radius - strokeWidth));

    canvas.drawCircle(center, radius - strokeWidth, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
