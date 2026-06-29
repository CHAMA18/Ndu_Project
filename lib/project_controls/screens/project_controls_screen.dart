/// Project Controls Dashboard Screen
///
/// Embeds into the existing phase screen sidebar pattern.
/// Uses ResponsiveScaffold matching the existing UI.
///
/// Shows: executive KPIs, health indicators, EVM metrics (CPI/SPI),
/// work package summary, open change requests, variance alerts.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/project_controls/models/project_controls_models.dart';
import 'package:ndu_project/project_controls/providers/project_controls_provider.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';
import 'package:ndu_project/theme.dart';

class ProjectControlsScreen extends StatefulWidget {
  const ProjectControlsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectControlsScreen()),
    );
  }

  @override
  State<ProjectControlsScreen> createState() => _ProjectControlsScreenState();
}

class _ProjectControlsScreenState extends State<ProjectControlsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Seed demo data if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProjectControlsProvider>();
      if (provider.state.workPackages.isEmpty) {
        provider.seedDemoData(DeliveryModel.waterfall);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectControlsProvider>(
      builder: (context, provider, _) {
        final state = provider.state;
        return ResponsiveScaffold(
          activeItemLabel: 'Project Controls',
          appBarTitle: 'Project Controls',
          breadcrumbPhase: 'Execution Phase',
          breadcrumbTitle: 'Project Controls',
          body: Column(
            children: [
              // Tab bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: LightModeColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: LightModeColors.lightOnPrimary,
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Dashboard'),
                    Tab(text: 'Scope Tracking'),
                    Tab(text: 'Cost Control'),
                    Tab(text: 'Change Mgmt'),
                    Tab(text: 'Forecasting'),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DashboardTab(state: state),
                    _ScopeTrackingTab(state: state),
                    _CostControlTab(state: state),
                    _ChangeMgmtTab(state: state, provider: provider),
                    _ForecastingTab(state: state),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// TAB: Dashboard
// ═════════════════════════════════════════════════════════════════════════

class _DashboardTab extends StatelessWidget {
  final ProjectControlsState state;
  const _DashboardTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Row
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.sizeOf(context).width > 800 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _kpiCard('Total Budget', '\$${(state.totalOriginalBudget / 1000000).toStringAsFixed(1)}M',
                  Icons.account_balance_wallet, const Color(0xFF6366F1)),
              _kpiCard('Actual Cost', '\$${(state.totalActualCost / 1000000).toStringAsFixed(1)}M',
                  Icons.payments, const Color(0xFFD97706)),
              _kpiCard('CPI', state.portfolioCPI.toStringAsFixed(2),
                  Icons.trending_up, _cpiColor(state.portfolioCPI)),
              _kpiCard('SPI', state.portfolioSPI.toStringAsFixed(2),
                  Icons.schedule, _spiColor(state.portfolioSPI)),
            ],
          ),
          const SizedBox(height: 24),
          // Health + EVM Summary
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _healthCard()),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _evmSummaryCard()),
            ],
          ),
          const SizedBox(height: 24),
          // Open Changes + Scope Growth
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _openChangesCard()),
              const SizedBox(width: 16),
              Expanded(child: _scopeGrowthCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600)),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
          ]),
          Text(value, style: TextStyle(color: const Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Color _cpiColor(double cpi) {
    if (cpi >= 1.0) return const Color(0xFF10B981);
    if (cpi >= 0.9) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _spiColor(double spi) {
    if (spi >= 1.0) return const Color(0xFF10B981);
    if (spi >= 0.9) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _healthCard() {
    final score = state.healthScore;
    final color = score >= 80 ? const Color(0xFF10B981) : score >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('OVERALL HEALTH', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 16),
        Row(children: [
          SizedBox(width: 80, height: 80, child: CustomPaint(painter: _HealthGaugePainter(score: score, color: color), child: Center(child: Text('$score', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900))))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(score >= 80 ? 'Healthy' : score >= 60 ? 'At Risk' : 'Critical', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${state.workPackages.length} work packages tracked', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            Text('${state.openChangeRequests} open change requests', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ])),
        ]),
      ]),
    );
  }

  Widget _evmSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('EARNED VALUE SUMMARY', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 16),
        _evmRow('BAC (Budget at Completion)', '\$${(state.totalOriginalBudget / 1000000).toStringAsFixed(2)}M', const Color(0xFF0F172A)),
        _evmRow('EV (Earned Value)', '\$${(state.totalEarnedValue / 1000000).toStringAsFixed(2)}M', const Color(0xFF6366F1)),
        _evmRow('AC (Actual Cost)', '\$${(state.totalActualCost / 1000000).toStringAsFixed(2)}M', const Color(0xFFD97706)),
        _evmRow('PV (Planned Value)', '\$${(state.totalPlannedValue / 1000000).toStringAsFixed(2)}M', const Color(0xFF8B5CF6)),
        _evmRow('EAC (Estimate at Completion)', '\$${(state.portfolioEAC / 1000000).toStringAsFixed(2)}M', _cpiColor(state.portfolioCPI)),
        _evmRow('VAC (Variance at Completion)', '\$${(state.portfolioVAC / 1000000).toStringAsFixed(2)}M', state.portfolioVAC >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
        _evmRow('CV (Cost Variance)', '\$${((state.totalEarnedValue - state.totalActualCost) / 1000000).toStringAsFixed(2)}M', state.totalEarnedValue >= state.totalActualCost ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
        _evmRow('SV (Schedule Variance)', '\$${((state.totalEarnedValue - state.totalPlannedValue) / 1000000).toStringAsFixed(2)}M', state.totalEarnedValue >= state.totalPlannedValue ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
      ]),
    );
  }

  Widget _evmRow(String label, String value, Color color) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
      Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
    ]));
  }

  Widget _openChangesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE4E7EC))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('CHANGE REQUESTS', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text('${state.openChangeRequests} OPEN', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 16),
        ...state.changeRequests.take(3).map((cr) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
          Icon(cr.category.icon, size: 16, color: cr.status.color),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cr.description, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${cr.category.label} • ${cr.status.label}', style: TextStyle(color: cr.status.color, fontSize: 11)),
          ])),
        ]))),
      ]),
    );
  }

  Widget _scopeGrowthCard() {
    // Check for scope growth (work packages with status 'Added' but no approved CR)
    final growthIssues = <String>[];
    for (final wp in state.workPackages) {
      if (wp.status == 'Added') {
        final hasApproval = state.changeRequests.any((cr) =>
            cr.status == ChangeStatus.approved &&
            cr.description.toLowerCase().contains(wp.name.toLowerCase()));
        if (!hasApproval) {
          growthIssues.add('${wp.wbsCode} ${wp.name} — added without approved change request');
        }
      }
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE4E7EC))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('SCOPE GROWTH DETECTION', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 16),
        if (growthIssues.isEmpty)
          const Row(children: [Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18), SizedBox(width: 8), Text('No unauthorized scope growth detected', style: TextStyle(color: Color(0xFF10B981), fontSize: 13))])
        else
          ...growthIssues.map((issue) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.warning_amber, color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(issue, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12))),
          ]))),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// TAB: Scope Tracking
// ═════════════════════════════════════════════════════════════════════════

class _ScopeTrackingTab extends StatelessWidget {
  final ProjectControlsState state;
  const _ScopeTrackingTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Work Package Scope Tracking', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${state.workPackages.length} ${state.deliveryModel == DeliveryModel.agile ? 'Epics' : 'Work Packages'} • Delivery: ${state.deliveryModel.label}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        const SizedBox(height: 20),
        ...state.workPackages.map((wp) => _workPackageCard(wp)),
      ]),
    );
  }

  Widget _workPackageCard(WorkPackageControl wp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE4E7EC))),
      child: Column(children: [
        // Header
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))), child: Row(children: [
          Container(width: 4, height: 24, decoration: BoxDecoration(color: wp.isCriticalPath ? const Color(0xFFEF4444) : const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(wp.name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w700)),
            Text('${wp.wbsCode} • ${wp.discipline ?? "N/A"} • ${wp.status}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ])),
          if (wp.isCriticalPath) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: const Text('CRITICAL PATH', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.w700))),
        ])),
        // Body
        Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          // Progress
          Row(children: [
            const Text('Progress', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${(wp.percentComplete ?? 0).round()}%', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (wp.percentComplete ?? 0) / 100, backgroundColor: const Color(0xFFE4E7EC), valueColor: AlwaysStoppedAnimation(wp.isCriticalPath ? const Color(0xFFEF4444) : const Color(0xFF10B981)), minHeight: 6)),
          const SizedBox(height: 16),
          // Cost + Schedule row
          Row(children: [
            Expanded(child: _infoChip('Original Budget', '\$${(wp.originalBudget / 1000000).toStringAsFixed(2)}M')),
            const SizedBox(width: 8),
            Expanded(child: _infoChip('Actual Cost', '\$${(wp.actualCost / 1000000).toStringAsFixed(2)}M')),
            const SizedBox(width: 8),
            Expanded(child: _infoChip('CPI', wp.cpi.toStringAsFixed(2))),
            const SizedBox(width: 8),
            Expanded(child: _infoChip('SPI', wp.spi.toStringAsFixed(2))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _infoChip('EV', '\$${(wp.earnedValue / 1000000).toStringAsFixed(2)}M')),
            const SizedBox(width: 8),
            Expanded(child: _infoChip('EAC', '\$${(wp.eac / 1000000).toStringAsFixed(2)}M')),
            const SizedBox(width: 8),
            Expanded(child: _infoChip('VAC', '\$${(wp.vac / 1000).toStringAsFixed(0)}K')),
            const SizedBox(width: 8),
            Expanded(child: _infoChip('Float', '${wp.floatDays?.round() ?? 0}d')),
          ]),
        ])),
      ]),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(6)), child: Column(children: [
      Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9, fontWeight: FontWeight.w600)),
      Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w700)),
    ]));
  }
}

// ═════════════════════════════════════════════════════════════════════════
// TAB: Cost Control
// ═════════════════════════════════════════════════════════════════════════

class _CostControlTab extends StatelessWidget {
  final ProjectControlsState state;
  const _CostControlTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Cost Control & EVM', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Total Budget: \$${(state.totalOriginalBudget / 1000000).toStringAsFixed(2)}M • Spent: \$${(state.totalActualCost / 1000000).toStringAsFixed(2)}M • Remaining: \$${((state.totalCurrentBudget - state.totalActualCost) / 1000000).toStringAsFixed(2)}M', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        const SizedBox(height: 20),
        // Cost breakdown per WP
        ...state.workPackages.map((wp) => _costCard(wp)),
      ]),
    );
  }

  Widget _costCard(WorkPackageControl wp) {
    final pct = wp.currentBudget > 0 ? wp.actualCost / wp.currentBudget : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE4E7EC))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${wp.wbsCode} ${wp.name}', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600)),
          Text('CPI: ${wp.cpi.toStringAsFixed(2)}', style: TextStyle(color: wp.cpi >= 1.0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: const Color(0xFFE4E7EC), valueColor: AlwaysStoppedAnimation(pct > 1.0 ? const Color(0xFFEF4444) : const Color(0xFFD97706)), minHeight: 8)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Budget: \$${(wp.currentBudget / 1000000).toStringAsFixed(2)}M', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          Text('Actual: \$${(wp.actualCost / 1000000).toStringAsFixed(2)}M', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          Text('EAC: \$${(wp.eac / 1000000).toStringAsFixed(2)}M', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w700)),
          Text('VAC: \$${(wp.vac / 1000).toStringAsFixed(0)}K', style: TextStyle(color: wp.vac >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// TAB: Change Management
// ═════════════════════════════════════════════════════════════════════════

class _ChangeMgmtTab extends StatelessWidget {
  final ProjectControlsState state;
  final ProjectControlsProvider provider;
  const _ChangeMgmtTab({required this.state, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Change Management', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Delivery Model: ${state.deliveryModel.label} • ${state.deliveryModel.changeProcess}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        const SizedBox(height: 20),
        // Change requests
        ...state.changeRequests.map((cr) => _changeRequestCard(cr, context)),
      ]),
    );
  }

  Widget _changeRequestCard(ChangeRequest cr, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cr.status.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cr.status.color.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(children: [
              Icon(cr.category.icon, color: cr.status.color, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cr.description, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700)),
                Text('${cr.id} • ${cr.category.label} • Priority: ${cr.priority}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: cr.status.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(cr.status.label, style: TextStyle(color: cr.status.color, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildChangeBody(cr)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChangeBody(ChangeRequest cr) {
    final children = <Widget>[];
    // Justification
    children.add(Text('Justification: ${cr.justification}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)));
    if (cr.rootCause != null) {
      children.add(const SizedBox(height: 4));
      children.add(Text('Root Cause: ${cr.rootCause}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)));
    }
    children.add(const SizedBox(height: 12));
    // Impact analysis
    children.add(const Text('IMPACT ANALYSIS', style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)));
    children.add(const SizedBox(height: 8));
    children.add(Wrap(spacing: 8, runSpacing: 8, children: _buildImpactChips(cr)));
    children.add(const SizedBox(height: 12));
    // Affected baselines
    if (cr.affectedBaselines.isNotEmpty) {
      children.add(const Text('AFFECTED BASELINES', style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)));
      children.add(const SizedBox(height: 4));
      children.add(Wrap(spacing: 6, children: cr.affectedBaselines.map((b) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE4E7EC))),
        child: Text(b, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
      )).toList()));
    }
    children.add(const SizedBox(height: 12));
    // Approval workflow
    if (cr.approval != null) {
      children.add(const Text('APPROVAL WORKFLOW', style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)));
      children.add(const SizedBox(height: 8));
      for (final entry in cr.approval!.steps.asMap().entries) {
        final step = entry.value;
        final isCurrent = entry.key == cr.approval!.currentStepIndex;
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: step.approved ? const Color(0xFF10B981) : (isCurrent ? const Color(0xFFF59E0B) : const Color(0xFFE4E7EC)),
                shape: BoxShape.circle,
              ),
              child: step.approved
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : (isCurrent ? const Icon(Icons.hourglass_top, color: Colors.white, size: 12) : null),
            ),
            const SizedBox(width: 8),
            Text(step.role.label, style: TextStyle(
              color: step.approved ? const Color(0xFF10B981) : (isCurrent ? const Color(0xFFF59E0B) : const Color(0xFF6B7280)),
              fontSize: 12,
              fontWeight: step.approved || isCurrent ? FontWeight.w600 : FontWeight.normal,
            )),
            if (step.approved && step.approvedAt != null)
              Text('  ✓ ${step.approvedAt!.day}/${step.approvedAt!.month}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 10)),
          ]),
        ));
      }
    }
    // Action button
    if (cr.status == ChangeStatus.underReview && cr.approval != null && cr.approval!.currentStep != null) {
      children.add(const SizedBox(height: 12));
      children.add(SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => provider.approveChangeStep(cr.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Approve as ${cr.approval!.currentStep!.role.label}'),
        ),
      ));
    }
    return children;
  }

  List<Widget> _buildImpactChips(ChangeRequest cr) {
    final chips = <Widget>[];
    if (cr.impact.scheduleImpactDays != null && cr.impact.scheduleImpactDays! > 0) {
      chips.add(_impactChip('Schedule', '+${cr.impact.scheduleImpactDays!.round()} days', const Color(0xFFEF4444)));
    }
    if (cr.impact.costImpactAmount != null && cr.impact.costImpactAmount! > 0) {
      chips.add(_impactChip('Cost', '+\$${(cr.impact.costImpactAmount! / 1000).round()}K', const Color(0xFFD97706)));
    }
    if (cr.impact.scopeImpact != null) {
      chips.add(_impactChip('Scope', cr.impact.scopeImpact!, const Color(0xFF6366F1)));
    }
    if (cr.impact.resourceImpact != null) {
      chips.add(_impactChip('Resource', cr.impact.resourceImpact!, const Color(0xFF8B5CF6)));
    }
    if (cr.impact.procurementImpact != null) {
      chips.add(_impactChip('Procurement', cr.impact.procurementImpact!, const Color(0xFF10B981)));
    }
    if (cr.impact.riskImpact != null) {
      chips.add(_impactChip('Risk', cr.impact.riskImpact!, const Color(0xFFEF4444)));
    }
    return chips;
  }

  Widget _impactChip(String label, String value, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.2))), child: Column(children: [
      Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
      Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]));
  }
}

// ═════════════════════════════════════════════════════════════════════════
// TAB: Forecasting
// ═════════════════════════════════════════════════════════════════════════

class _ForecastingTab extends StatelessWidget {
  final ProjectControlsState state;
  const _ForecastingTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Forecasting & Analytics', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Automated forecasts based on current performance trends', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        const SizedBox(height: 20),
        // Forecast cards
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.2, children: [
          _forecastCard('EAC (Estimate at Completion)', '\$${(state.portfolioEAC / 1000000).toStringAsFixed(2)}M', 'Based on CPI ${state.portfolioCPI.toStringAsFixed(2)}', state.portfolioEAC <= state.totalOriginalBudget ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
          _forecastCard('ETC (Estimate to Complete)', '\$${((state.portfolioEAC - state.totalActualCost) / 1000000).toStringAsFixed(2)}M', 'Remaining work value', const Color(0xFF6366F1)),
          _forecastCard('VAC (Variance at Completion)', '\$${(state.portfolioVAC / 1000000).toStringAsFixed(2)}M', state.portfolioVAC >= 0 ? 'Under budget' : 'Over budget', state.portfolioVAC >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
          _forecastCard('Avg Progress', '${state.avgPercentComplete.round()}%', '${state.workPackages.length} work packages', const Color(0xFF8B5CF6)),
        ]),
        const SizedBox(height: 24),
        // Trend analysis
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE4E7EC))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PERFORMANCE TRENDS', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 16),
          ...state.workPackages.map((wp) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${wp.wbsCode} ${wp.name}', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
              Row(children: [
                Text('CPI ${wp.cpi.toStringAsFixed(2)}', style: TextStyle(color: wp.cpi >= 1.0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text('SPI ${wp.spi.toStringAsFixed(2)}', style: TextStyle(color: wp.spi >= 1.0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(flex: wp.percentComplete?.round() ?? 0, child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(2)))),
              Expanded(flex: 100 - (wp.percentComplete?.round() ?? 0), child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFE4E7EC), borderRadius: BorderRadius.circular(2)))),
            ]),
          ]))),
        ])),
      ]),
    );
  }

  Widget _forecastCard(String label, String value, String subtitle, Color color) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600)),
      Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
      Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
    ]));
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Health Gauge Painter
// ═════════════════════════════════════════════════════════════════════════

class _HealthGaugePainter extends CustomPainter {
  final int score;
  final Color color;
  _HealthGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const sw = 8.0;
    // Track
    canvas.drawCircle(center, radius - sw / 2, Paint()..color = const Color(0xFFE4E7EC)..style = PaintingStyle.stroke..strokeWidth = sw);
    // Fill
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - sw / 2), -3.14159 / 2, (score / 100) * 2 * 3.14159, false, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _HealthGaugePainter old) => old.score != score;
}
