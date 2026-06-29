/// NDU Program Dashboard — "Program Alpha | Obsidian Executive"
///
/// World-class, top 1% quality program dashboard faithfully replicating
/// the attached HTML design with Flutter-native rendering:
///
/// - Dark obsidian theme (#051424) with gold tertiary accents (#f9be2b)
/// - Glass-card glassmorphism with backdrop blur
/// - Hero bento grid: Budget KPI + Planned vs Actual chart + Radial progress gauge
/// - Project Health Matrix table with sparkline budget trends
/// - Critical Risks + Resource Capacity side-by-side
/// - Escalation Summary + Recent Activity timeline + Visual Context card
/// - Floating Action Button
/// - Custom radial gauge painter with animated sweep

import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ndu_project/theme.dart';

class ProgramDashboardScreen extends StatefulWidget {
  final String? programId;

  const ProgramDashboardScreen({super.key, this.programId});

  static void open(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProgramDashboardScreen()));
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

  // ─── Design Tokens (from HTML tailwind config) ───────────────────────────
  static const _bg = Color(0xFF051424);
  static const _surface = Color(0xFF122131);
  static const _surfaceHigh = Color(0xFF1C2B3C);
  static const _surfaceHighest = Color(0xFF273647);
  static const _surfaceLow = Color(0xFF0D1C2D);
  static const _onSurface = Color(0xFFD4E4FA);
  static const _onSurfaceVariant = Color(0xFFC7C6CC);
  static const _outline = Color(0xFF909096);
  static const _outlineVariant = Color(0xFF46464C);
  static const _primary = Color(0xFFDFE2F3);
  static const _primaryContainer = Color(0xFFC3C6D7);
  static const _tertiary = Color(0xFFFFDFA3);
  static const _tertiaryContainer = Color(0xFFF9BE2B);
  static const _secondary = Color(0xFFBBC3FF);
  static const _emerald = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);
  static const _crimson = Color(0xFFEF4444);
  static const _onTertiary = Color(0xFF402D00);

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _gaugeAnim = CurvedAnimation(
        parent: _gaugeController, curve: Curves.easeOutCubic);
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

  // ─── Glass Card ──────────────────────────────────────────────────────────
  Widget _glassCard({
    required Widget child,
    Color? leftBorder,
    bool enableHover = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: leftBorder != null
              ? BorderSide(color: leftBorder, width: 4)
              : BorderSide.none,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: _tertiaryContainer,
        foregroundColor: _onTertiary,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      body: Stack(
        children: [
          // Atmospheric background
          Positioned(
            top: -200,
            right: -200,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _tertiaryContainer.withValues(alpha: 0.04),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(64, 24, 64, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildHeroBento(context),
                    const SizedBox(height: 24),
                    _buildMainGrid(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Program Alpha Dashboard',
                style: TextStyle(
                    color: _primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    fontFamily: appFontFamily)),
            const SizedBox(height: 4),
            Text('Infrastructure Modernization & Global Expansion',
                style: TextStyle(
                    color: _onSurfaceVariant,
                    fontSize: 16,
                    fontFamily: appFontFamily)),
          ],
        ),
        Row(
          children: [
            // Health score
            _glassCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: _amber,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _amber, blurRadius: 8)])),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('OVERALL HEALTH',
                        style: TextStyle(
                            color: _onSurfaceVariant,
                            fontSize: 10,
                            fontFamily: appFontFamily)),
                    Text('72/100',
                        style: TextStyle(
                            color: _primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: appFontFamily)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(width: 16),
            // Executive report button
            Container(
              decoration: BoxDecoration(
                color: _primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Row(children: [
                      Icon(Icons.ios_share, color: _bg.withValues(alpha: 0.8), size: 16),
                      const SizedBox(width: 8),
                      Text('EXECUTIVE REPORT',
                          style: TextStyle(
                              color: _bg.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              fontFamily: appFontFamily)),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Hero Bento Grid ─────────────────────────────────────────────────────
  Widget _buildHeroBento(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 900;
    if (isDesktop) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: _budgetKpi()),
        const SizedBox(width: 24),
        Expanded(flex: 6, child: _plannedVsActual()),
        const SizedBox(width: 24),
        Expanded(flex: 3, child: _progressGauge()),
      ]);
    }
    return Column(children: [
      _budgetKpi(),
      const SizedBox(height: 24),
      SizedBox(height: 200, child: _plannedVsActual()),
      const SizedBox(height: 24),
      _progressGauge(),
    ]);
  }

  Widget _budgetKpi() {
    return _glassCard(
      child: Padding(
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
                    style: TextStyle(color: _emerald, fontSize: 14, fontFamily: appFontFamily)),
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
      ),
    );
  }

  Widget _plannedVsActual() {
    final planned = [0.40, 0.55, 0.70, 0.85, 0.65, 0.90];
    final actual = [0.38, 0.52, 0.72, 0.88, 0.60, 0.95];
    final labels = ['Q1', 'Q2', 'Q3', 'Q4', 'FY24'];

    return _glassCard(
      child: Padding(
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
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Planned bar
                      Container(
                        width: 12,
                        decoration: BoxDecoration(
                          color: _tertiary.withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                        height: double.maxFinite * planned[i] * 0.001,
                      ),
                      const SizedBox(width: 2),
                      // Actual bar
                      Container(
                        width: 12,
                        decoration: BoxDecoration(
                          color: _secondary,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                        height: double.maxFinite * actual[i] * 0.001,
                      ),
                    ],
                  );
                }),
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
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              color: _onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
    ]);
  }

  Widget _progressGauge() {
    return _glassCard(
      child: Padding(
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
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
      ),
    );
  }

  // ─── Main Grid ───────────────────────────────────────────────────────────
  Widget _buildMainGrid(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 900;
    if (isDesktop) {
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

  Widget _healthMatrix() {
    final projects = [
      ('Project Phoenix', 'Cloud Integration', 'Healthy', _emerald, [0.2, 0.4, 0.6, 1.0], 'On Track', '92%', null),
      ('Data Lake 2.0', 'Architecture Shift', 'At Risk', _amber, [1.0, 0.6, 0.4, 0.2], 'Delayed (2w)', '45%', _amber),
      ('CyberShield v4', 'Security Audit', 'Critical', _crimson, [0.8, 1.0, 0.5, 0.2], 'Stalled', '12%', _crimson),
      ('Project Titan', 'Heavy Infrastructure', 'Healthy', _emerald, [0.2, 0.4, 0.6, 1.0], 'Ahead (1w)', '68%', null),
      ('Edge Connect', 'IoT Rollout', 'Healthy', _emerald, [0.4, 1.0, 0.6, 0.2], 'On Track', '84%', null),
    ];

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
            decoration: BoxDecoration(
              color: _surfaceHigh.withValues(alpha: 0.5),
              border: Border(bottom: BorderSide(color: _outlineVariant.withValues(alpha: 0.3))),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: i < projects.length - 1
                    ? Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))
                    : null,
              ),
              child: Row(children: [
                // Project name
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.$1, style: TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
                  Text(p.$2, style: TextStyle(color: _onSurfaceVariant, fontSize: 11, fontFamily: appFontFamily)),
                ])),
                // Status
                Expanded(flex: 2, child: Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: p.$4, shape: BoxShape.circle, boxShadow: [BoxShadow(color: p.$4, blurRadius: 8)])),
                  const SizedBox(width: 8),
                  Text(p.$3, style: TextStyle(color: _onSurfaceVariant, fontSize: 13, fontFamily: appFontFamily)),
                ])),
                // Budget trend sparkline
                Expanded(flex: 2, child: SizedBox(
                  height: 24,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: p.$5.map<Widget>((h) => Expanded(child: Container(margin: const EdgeInsets.only(right: 1), decoration: BoxDecoration(color: p.$4.withValues(alpha: h == 1.0 ? 1.0 : h * 0.6), borderRadius: BorderRadius.circular(1)), height: 24 * h))).toList()),
                )),
                // Schedule
                Expanded(flex: 2, child: Text(p.$6, style: TextStyle(color: p.$8 ?? _onSurface, fontSize: 13, fontFamily: appFontFamily))),
                // Progress
                Expanded(child: Align(alignment: Alignment.centerRight, child: Text(p.$7, style: TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: appFontFamily)))),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _criticalRisks() {
    final risks = [
      ('Resource Burnout - Project Titan', 'Key developers at 140% capacity for 6+ weeks.', _crimson, Icons.report, true),
      ('Hardware Lead-Time Delay', 'Global supply chain constraints impacting Phase 3.', _amber, Icons.warning, true),
      ('Budget Re-allocation Needed', 'Surplus from Project Phoenix could offset Data Lake.', _outlineVariant, Icons.info, false),
    ];

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Critical Risks',
                style: TextStyle(color: _primary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _crimson.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
              child: Text('3 HIGH PRIORITY',
                  style: TextStyle(color: _crimson, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
            ),
          ]),
          const SizedBox(height: 24),
          ...risks.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: r.$3.withValues(alpha: r.$5 ? 0.3 : 0.15)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(r.$4, color: r.$3, size: 18),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.$1, style: TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
                const SizedBox(height: 4),
                Text(r.$2, style: TextStyle(color: _onSurfaceVariant, fontSize: 11, fontFamily: appFontFamily)),
              ])),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _resourceCapacity() {
    final resources = [
      ('Engineering', 98, _crimson),
      ('DevOps / Cloud', 72, _emerald),
      ('Security Analysis', 85, _amber),
      ('UX / Design', 40, _emerald),
    ];

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Resource Capacity',
                style: TextStyle(color: _primary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
            Text('ACROSS PROJECTS',
                style: TextStyle(color: _onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1, fontFamily: appFontFamily)),
          ]),
          const SizedBox(height: 24),
          ...resources.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(r.$1, style: TextStyle(color: _onSurfaceVariant, fontSize: 11, fontFamily: appFontFamily)),
                Text('${r.$2}%', style: TextStyle(color: r.$3, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
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
      ),
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
    return _glassCard(
      leftBorder: _amber,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.priority_high, color: _amber, size: 18),
            const SizedBox(width: 8),
            Text('ESCALATION SUMMARY',
                style: TextStyle(color: _amber, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: appFontFamily)),
          ]),
          const SizedBox(height: 16),
          // Escalation 1
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _surfaceHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('OPEN APPROVAL',
                  style: TextStyle(color: _onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: appFontFamily)),
              const SizedBox(height: 4),
              Text('Project Titan requires +\$2.5M additional contingency approval by EOD Friday.',
                  style: TextStyle(color: _primary, fontSize: 13, fontFamily: appFontFamily)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {},
                child: Row(children: [
                  Text('REVIEW DETAILS',
                      style: TextStyle(color: _tertiary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
                  Icon(Icons.arrow_forward, color: _tertiary, size: 12),
                ]),
              ),
            ]),
          ),
          // Escalation 2
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SCHEDULE REVISION',
                  style: TextStyle(color: _onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: appFontFamily)),
              const SizedBox(height: 4),
              Text('Baseline shift requested for CyberShield v4 due to legislative changes.',
                  style: TextStyle(color: _primary, fontSize: 13, fontFamily: appFontFamily)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {},
                child: Row(children: [
                  Text('REVIEW DETAILS',
                      style: TextStyle(color: _tertiary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
                  Icon(Icons.arrow_forward, color: _tertiary, size: 12),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _recentActivity() {
    final activities = [
      ('M. Chen pushed a budget update', 'Project Phoenix  •  22 mins ago', _primary),
      ('Milestone Reached: Q3 Cloud Gate', 'Data Lake 2.0  •  2 hours ago', _emerald),
      ('Risk Level Updated to Medium', 'Edge Connect  •  5 hours ago', _amber),
      ('S. Rossi added a comment', 'Resource Allocation  •  Yesterday', _primary),
    ];

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('RECENT ACTIVITY',
              style: TextStyle(color: _onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: appFontFamily)),
          const SizedBox(height: 24),
          // Timeline
          Stack(children: [
            // Vertical line
            Positioned(
              left: 7,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: _outlineVariant.withValues(alpha: 0.3)),
            ),
            ...activities.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 24),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Positioned(
                  left: 0,
                  top: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Center(child: Container(width: 6, height: 6, decoration: BoxDecoration(color: a.$3, shape: BoxShape.circle))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.$1, style: TextStyle(color: _primary, fontSize: 12, fontFamily: appFontFamily)),
                  Text(a.$2, style: TextStyle(color: _onSurfaceVariant, fontSize: 10, fontFamily: appFontFamily)),
                ])),
              ]),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _visualContext() {
    return _glassCard(
      child: Container(
        height: 192,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [_bg, _surfaceHigh.withValues(alpha: 0.3)],
          ),
        ),
        child: Stack(children: [
          // Cinematic city construction graphic (simplified with gradient)
          Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_surfaceHigh.withValues(alpha: 0.2), _bg.withValues(alpha: 0.8)])))),
          // City silhouette shapes
          Positioned(bottom: 0, left: 0, right: 0, child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _cityBuilding(40, 60, _surfaceHighest.withValues(alpha: 0.4)),
            _cityBuilding(30, 80, _surfaceHighest.withValues(alpha: 0.3)),
            _cityBuilding(50, 100, _surfaceHighest.withValues(alpha: 0.5)),
            _cityBuilding(35, 70, _surfaceHighest.withValues(alpha: 0.35)),
            _cityBuilding(45, 90, _surfaceHighest.withValues(alpha: 0.45)),
            _cityBuilding(30, 50, _surfaceHighest.withValues(alpha: 0.3)),
          ])),
          // Glow spots
          Positioned(top: 20, right: 30, child: Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: _tertiaryContainer.withValues(alpha: 0.15), boxShadow: [BoxShadow(color: _tertiaryContainer.withValues(alpha: 0.2), blurRadius: 30)]))),
          Positioned(top: 40, left: 40, child: Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: _secondary.withValues(alpha: 0.1), boxShadow: [BoxShadow(color: _secondary.withValues(alpha: 0.15), blurRadius: 25)]))),
          // Label
          Positioned(bottom: 16, left: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('VISUAL CONTEXT',
                style: TextStyle(color: _tertiary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: appFontFamily)),
            Text('Site A-01 Progress',
                style: TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
          ])),
        ]),
      ),
    );
  }

  Widget _cityBuilding(double w, double h, Color c) {
    return Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2))));
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

    // Inner radial gradient effect
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [fillColor.withValues(alpha: 0.05), Colors.transparent],
        radius: 0.85,
      ).createShader(Rect.fromCircle(center: center, radius: radius - strokeWidth));

    canvas.drawCircle(center, radius - strokeWidth, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
