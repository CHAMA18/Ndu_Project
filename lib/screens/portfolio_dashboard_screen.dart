/// NDU Portfolio — PMO Executive Dashboard
///
/// Faithfully replicates the attached HTML/Tailwind design in Flutter.
/// Dark navy (#051424) + gold (#f8bd2a) theme, glass-card effect,
/// bento-grid layout with KPIs, portfolio table, charts, and milestone lists.

import 'package:flutter/material.dart';
import 'package:ndu_project/theme.dart';

class PortfolioDashboardScreen extends StatelessWidget {
  final String? portfolioId;

  const PortfolioDashboardScreen({super.key, this.portfolioId});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PortfolioDashboardScreen()),
    );
  }

  // ─── Color constants (from the HTML design) ──────────────────────────────
  static const Color _surface = Color(0xFF051424);
  static const Color _onSurface = Color(0xFFD4E4FA);
  static const Color _onSurfaceVariant = Color(0xFFC7C6CC);
  static const Color _outline = Color(0xFF909096);
  static const Color _outlineVariant = Color(0xFF46464C);
  static const Color _surfaceContainer = Color(0xFF122131);
  static const Color _surfaceContainerHigh = Color(0xFF1C2B3C);
  static const Color _surfaceContainerHighest = Color(0xFF273647);
  static const Color _surfaceContainerLow = Color(0xFF0D1C2D);
  static const Color _primary = Color(0xFFC3C6D7);
  static const Color _primaryContainer = Color(0xFF0A0E1A);
  static const Color _tertiary = Color(0xFFF8BD2A);
  static const Color _secondary = Color(0xFFBBC3FF);
  static const Color _error = Color(0xFFFFB4AB);
  static const Color _errorContainer = Color(0xFF93000A);
  static const Color _emerald = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _crimson = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        slivers: [
          // ─── Top Navigation Bar ────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _surface.withValues(alpha: 0.85),
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 64,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: _surface.withValues(alpha: 0.8),
                border: const Border(
                    bottom: BorderSide(color: _outlineVariant, width: 0.5)),
              ),
              child: _buildTopNav(),
            ),
          ),
          // ─── Main Content ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // KPI Top Row
                _buildKpiRow(),
                const SizedBox(height: 24),
                // Bento Grid
                _buildBentoGrid(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top Navigation Bar ──────────────────────────────────────────────────
  Widget _buildTopNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: title + nav links
            Row(
              children: [
                Text(
                  'Executive Dashboard',
                  style: TextStyle(
                    color: _onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    fontFamily: appFontFamily,
                  ),
                ),
                const SizedBox(width: 32),
                // Nav links (hidden on small screens)
                _navLink('Global View', isActive: true),
                const SizedBox(width: 24),
                _navLink('B.U. Filter'),
                const SizedBox(width: 24),
                _navLink('Strategic Goals'),
              ],
            ),
            // Right: search + actions
            Row(
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, color: _onSurfaceVariant, size: 16),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 150,
                        child: TextField(
                          style: TextStyle(color: _onSurface, fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Search portfolio...',
                            hintStyle:
                                TextStyle(color: _onSurfaceVariant.withValues(alpha: 0.5), fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: _outlineVariant),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.notifications, color: _onSurfaceVariant, size: 20),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.history, color: _onSurfaceVariant, size: 20),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryContainer,
                    foregroundColor: const Color(0xFF777B8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 0,
                  ),
                  child: Text('Export Data',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: appFontFamily)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navLink(String label, {bool isActive = false}) {
    return Text(
      label,
      style: TextStyle(
        color: isActive ? _primary : _onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        fontFamily: appFontFamily,
        decoration: isActive ? TextDecoration.underline : TextDecoration.none,
        decorationColor: _primary,
        decorationThickness: 2,
      ),
    );
  }

  // ─── KPI Top Row ─────────────────────────────────────────────────────────
  Widget _buildKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1000
            ? 6
            : constraints.maxWidth > 600
                ? 3
                : 1;
        final spacing = 24.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
                width: itemWidth,
                child: _kpiCard('Total Projects', '156', Icons.inventory_2, _primary,
                    subtitle: '+12% vs LY', subtitleColor: _emerald, subtitleIcon: Icons.trending_up)),
            SizedBox(
                width: itemWidth,
                child: _kpiCard('On Track', '32%', Icons.check_circle, _emerald,
                    subtitle: '50 Projects', borderLeft: _emerald)),
            SizedBox(
                width: itemWidth,
                child: _kpiCard('At Risk', '41%', Icons.warning, _amber,
                    subtitle: '64 Projects', borderLeft: _amber)),
            SizedBox(
                width: itemWidth,
                child: _kpiCard('Off Track', '27%', Icons.error, _error,
                    subtitle: '42 Projects', borderLeft: _crimson)),
            SizedBox(
                width: itemWidth,
                child: _kpiCard('Total Budget', '\$1.2B', Icons.account_balance_wallet, _secondary,
                    subtitle: 'FY24/25 Allocation', bgColor: _primaryContainer.withValues(alpha: 0.4))),
            SizedBox(
                width: itemWidth,
                child: _kpiCardWithProgress('Budget Spent', '\$780M', Icons.payments, _tertiary, 0.65)),
          ],
        );
      },
    );
  }

  Widget _kpiCard(
    String label,
    String value,
    IconData icon,
    Color iconColor, {
    String? subtitle,
    Color? subtitleColor,
    Color? borderLeft,
    Color? bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor ?? _surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _outlineVariant.withValues(alpha: 0.4)),
        borderLeft: borderLeft != null ? BorderSide(color: borderLeft, width: 4) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(color: _onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: appFontFamily)),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  color: _onSurface, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: appFontFamily)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (subtitleColor == _emerald)
                  Icon(Icons.trending_up, color: _emerald, size: 14),
                if (subtitleColor == _emerald) const SizedBox(width: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: subtitleColor ?? _onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: appFontFamily)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _kpiCardWithProgress(
      String label, String value, IconData icon, Color iconColor, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(color: _onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: appFontFamily)),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  color: _onSurface, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: appFontFamily)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _surfaceContainerHighest,
              color: _tertiary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bento Grid ──────────────────────────────────────────────────────────
  Widget _buildBentoGrid(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 1000;

    return Column(
      children: [
        // Row 1: Portfolio Health Table (8 cols) + Projects by BU (4 cols)
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 8, child: _buildPortfolioHealthTable()),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: _buildBusinessUnitChart()),
            ],
          )
        else ...[
          _buildPortfolioHealthTable(),
          const SizedBox(height: 24),
          _buildBusinessUnitChart(),
        ],
        const SizedBox(height: 24),
        // Row 2: Budget Trend (4 cols) + Risks Donut (4 cols) + (spacer 4 cols on desktop)
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: _buildBudgetTrendChart()),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: _buildRisksDonut()),
              const SizedBox(width: 24),
              const Expanded(flex: 4, child: SizedBox()),
            ],
          )
        else ...[
          _buildBudgetTrendChart(),
          const SizedBox(height: 24),
          _buildRisksDonut(),
        ],
        const SizedBox(height: 24),
        // Row 3: Upcoming Milestones (6 cols) + Overdue Milestones (6 cols)
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _buildUpcomingMilestones()),
              const SizedBox(width: 24),
              Expanded(flex: 6, child: _buildOverdueMilestones()),
            ],
          )
        else ...[
          _buildUpcomingMilestones(),
          const SizedBox(height: 24),
          _buildOverdueMilestones(),
        ],
      ],
    );
  }

  // ─── Glass Card wrapper ──────────────────────────────────────────────────
  Widget _glassCard({required Widget child, Color? borderColor}) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? _outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  // ─── Portfolio Health Overview Table ─────────────────────────────────────
  Widget _buildPortfolioHealthTable() {
    final projects = [
      ('Project Alpha', 'On Track', _emerald, [_emerald, _emerald, _emerald], '12', '5', '30 Jun 2024', null),
      ('Project Beta', 'At Risk', _amber, [_amber, _emerald, _emerald], '28', '9', '15 Aug 2024', null),
      ('Project Gamma', 'On Track', _emerald, [_emerald, _amber, _emerald], '15', '7', '10 Jul 2024', null),
      ('Project Delta', 'Off Track', _crimson, [_crimson, _crimson, _amber], '42', '18', 'Delayed', _error),
      ('Project Epsilon', 'On Track', _emerald, [_emerald, _emerald, _emerald], '4', '2', '31 May 2024', null),
    ];

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surfaceContainerLow.withValues(alpha: 0.5),
              border: Border(bottom: BorderSide(color: _outlineVariant.withValues(alpha: 0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Portfolio Health Overview',
                    style: TextStyle(color: _onSurface, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: appFontFamily)),
                Row(children: [
                  _tableButton('View All'),
                  const SizedBox(width: 8),
                  _tableButton('Filter'),
                ]),
              ],
            ),
          ),
          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(_surfaceContainerLow.withValues(alpha: 0.3)),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
              columnSpacing: 32,
              horizontalMargin: 24,
              columns: [
                DataColumn(label: _headerText('Project Name')),
                DataColumn(label: _headerText('Status')),
                DataColumn(label: _headerText('Sch / Bud / Scp')),
                DataColumn(label: _headerText('Risks'), numeric: true),
                DataColumn(label: _headerText('Issues'), numeric: true),
                DataColumn(label: _headerText('Forecast Finish')),
              ],
              rows: projects.map((p) {
                final isDelayed = p.$7 == 'Delayed';
                return DataRow(
                  color: WidgetStateProperty.all(Colors.transparent),
                  cells: [
                    DataCell(Text(p.$1, style: TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: appFontFamily))),
                    DataCell(Row(children: [
                      _statusDot(p.$3),
                      const SizedBox(width: 8),
                      Text(p.$2, style: TextStyle(color: _onSurfaceVariant, fontSize: 14, fontFamily: appFontFamily)),
                    ])),
                    DataCell(Row(children: p.$4.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: _statusDot(c))).toList())),
                    DataCell(_riskBadge(p.$5, isHigh: int.parse(p.$5) > 30)),
                    DataCell(_riskBadge(p.$6, isHigh: false)),
                    DataCell(Text(p.$7, style: TextStyle(color: isDelayed ? _error : _onSurfaceVariant, fontSize: 14, fontWeight: isDelayed ? FontWeight.bold : FontWeight.normal, fontFamily: appFontFamily))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(text.toUpperCase(),
        style: TextStyle(color: _onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, fontFamily: appFontFamily));
  }

  Widget _tableButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _outlineVariant),
      ),
      child: Text(label, style: TextStyle(color: _onSurfaceVariant, fontSize: 13, fontFamily: appFontFamily)),
    );
  }

  Widget _statusDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
      ),
    );
  }

  Widget _riskBadge(String count, {bool isHigh = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isHigh ? _errorContainer.withValues(alpha: 0.3) : _surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isHigh ? _error.withValues(alpha: 0.3) : _outlineVariant),
      ),
      child: Text(count,
          style: TextStyle(color: isHigh ? _error : _onSurface, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
    );
  }

  // ─── Projects by Business Unit ───────────────────────────────────────────
  Widget _buildBusinessUnitChart() {
    final units = [
      ('IT Infrastructure', 28, 0.80, _secondary),
      ('HR Transformation', 24, 0.70, _tertiary),
      ('Customer Experience', 24, 0.70, _primary),
      ('Strategic Sales', 18, 0.55, _outlineVariant),
    ];

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PROJECTS BY BUSINESS UNIT',
                style: TextStyle(color: _onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: appFontFamily)),
            const SizedBox(height: 24),
            ...units.map((u) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(u.$1, style: TextStyle(color: _onSurface, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
                          Text('${u.$2}', style: TextStyle(color: _onSurface, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: u.$3,
                          backgroundColor: _surfaceContainer,
                          color: u.$4,
                          minHeight: 24,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ─── Budget Utilization Trend ────────────────────────────────────────────
  Widget _buildBudgetTrendChart() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final heights = [0.40, 0.45, 0.55, 0.65, 0.85, 0.50];
    final highlightIndex = 4; // May is highlighted

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BUDGET UTILIZATION TREND',
                style: TextStyle(color: _onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: appFontFamily)),
            const SizedBox(height: 24),
            // Bar chart
            SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (i) {
                  final isHighlight = i == highlightIndex;
                  return Container(
                    width: 28,
                    decoration: BoxDecoration(
                      color: isHighlight ? _secondary : _primary.withValues(alpha: 0.2),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      boxShadow: isHighlight
                          ? [BoxShadow(color: _secondary.withValues(alpha: 0.3), blurRadius: 15)]
                          : null,
                    ),
                    height: 180 * heights[i],
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: months
                  .map((m) => Text(m,
                      style: TextStyle(color: _onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: appFontFamily)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Risks by Category (Donut) ───────────────────────────────────────────
  Widget _buildRisksDonut() {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RISKS BY CATEGORY',
                style: TextStyle(color: _onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: appFontFamily)),
            const SizedBox(height: 24),
            Row(
              children: [
                // Donut chart
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      segments: [
                        (_crimson, 0.25),    // Strategic 25%
                        (_amber, 0.30),       // Technical 30%
                        (_emerald, 0.45),     // Resource 45%
                      ],
                      trackColor: _surfaceContainerHigh,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('248', style: TextStyle(color: _onSurface, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: appFontFamily)),
                          Text('TOTAL', style: TextStyle(color: _onSurfaceVariant.withValues(alpha: 0.6), fontSize: 8, letterSpacing: 2, fontFamily: appFontFamily)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Legend
                Expanded(
                  child: Column(
                    children: [
                      _riskLegend('Strategic', '25%', _crimson),
                      const SizedBox(height: 8),
                      _riskLegend('Technical', '30%', _amber),
                      const SizedBox(height: 8),
                      _riskLegend('Resource', '45%', _emerald),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _riskLegend(String label, String pct, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: _onSurface, fontSize: 11, fontFamily: appFontFamily)),
        ]),
        Text(pct, style: TextStyle(color: _onSurface, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: appFontFamily)),
      ],
    );
  }

  // ─── Upcoming Milestones ─────────────────────────────────────────────────
  Widget _buildUpcomingMilestones() {
    final milestones = [
      ('Requirement Sign-off', 'Project Beta', '22 May 2024', null),
      ('Database Migration', 'Project Gamma', '28 May 2024', null),
      ('Security Audit Completion', 'Project Alpha', '01 Jun 2024', _emerald),
    ];

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceContainerLow.withValues(alpha: 0.5),
              border: Border(bottom: BorderSide(color: _outlineVariant.withValues(alpha: 0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('UPCOMING MILESTONES (30 DAYS)',
                    style: TextStyle(color: _onSurface, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: appFontFamily)),
                Icon(Icons.event, color: _primary.withValues(alpha: 0.7), size: 18),
              ],
            ),
          ),
          ...milestones.map((m) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m.$1, style: TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: appFontFamily)),
                    Text(m.$2, style: TextStyle(color: _onSurfaceVariant, fontSize: 14, fontFamily: appFontFamily)),
                    Text(m.$3, style: TextStyle(color: m.$4 ?? _onSurfaceVariant, fontSize: 14, fontWeight: m.$4 != null ? FontWeight.bold : FontWeight.normal, fontFamily: appFontFamily)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─── Overdue Milestones ──────────────────────────────────────────────────
  Widget _buildOverdueMilestones() {
    final overdue = [
      ('UAT Start Phase', 'Project Delta', '12 Days', true),
      ('Vendor Final Payment', 'Project Zeta', '5 Days', false),
      ('Training Modules Delivery', 'Project Eta', '3 Days', false),
    ];

    return _glassCard(
      borderColor: _errorContainer.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _errorContainer.withValues(alpha: 0.1),
              border: Border(bottom: BorderSide(color: _outlineVariant.withValues(alpha: 0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('OVERDUE MILESTONES',
                    style: TextStyle(color: _error, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: appFontFamily)),
                Icon(Icons.dangerous, color: _error, size: 18),
              ],
            ),
          ),
          ...overdue.map((m) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m.$1, style: TextStyle(color: _onSurface, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: appFontFamily)),
                    Text(m.$2, style: TextStyle(color: _onSurfaceVariant, fontSize: 14, fontFamily: appFontFamily)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: m.$4 ? _error : _error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(m.$3,
                          style: TextStyle(color: m.$4 ? const Color(0xFF690005) : _error, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: appFontFamily)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Donut Chart Painter ───────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<(Color, double)> segments;
  final Color trackColor;

  _DonutPainter({required this.segments, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    // Track
    canvas.drawCircle(
      center,
      radius - strokeWidth / 2,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Segments
    double startAngle = -90 * 3.14159 / 180; // start from top
    for (final (color, fraction) in segments) {
      final sweepAngle = fraction * 2 * 3.14159;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
