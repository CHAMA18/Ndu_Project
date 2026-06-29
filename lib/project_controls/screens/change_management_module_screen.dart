/// Change Management Screen — World-class UI
///
/// Embedded in the existing sidebar/phase screen pattern via ResponsiveScaffold.
/// 4 tabs: Dashboard, Change Register, Impact & Approval, Audit Trail
///
/// Features:
/// - Executive dashboard with KPI cards, contingency/reserve tracking
/// - Change register with filterable/sortable cards
/// - Impact assessment visualization (14 dimensions)
/// - Approval workflow with step-by-step visualization
/// - Audit trail timeline
/// - Emergency change support
/// - Agile routine refinement vs controlled baseline change
/// - Re-baseline trigger detection

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/project_controls/models/change_management_models.dart';
import 'package:ndu_project/project_controls/providers/change_management_provider.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/theme.dart';

class ChangeManagementModuleScreen extends StatefulWidget {
  const ChangeManagementModuleScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChangeManagementModuleScreen()),
    );
  }

  @override
  State<ChangeManagementModuleScreen> createState() =>
      _ChangeManagementModuleScreenState();
}

class _ChangeManagementModuleScreenState extends State<ChangeManagementModuleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChangeManagementProvider>();
      if (provider.changeRequests.isEmpty) {
        provider.seedDemoData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Theme tokens matching the existing app
  static const _accent = LightModeColors.accent; // #FFC107
  static const _textPrimary = Color(0xFF1A1D1F);
  static const _textSecondary = Color(0xFF6B7280);
  static const _surfaceBorder = Color(0xFFE4E7EC);
  static const _bgColor = Color(0xFFF9FAFB);
  static const _cardBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChangeManagementProvider>(
      builder: (context, provider, _) {
        return ResponsiveScaffold(
          activeItemLabel: 'Change Management',
          appBarTitle: 'Change Management',
          breadcrumbPhase: 'Execution Phase',
          breadcrumbTitle: 'Change Management',
          body: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DashboardTab(provider: provider),
                    _ChangeRegisterTab(provider: provider),
                    _ImpactApprovalTab(provider: provider),
                    _AuditTrailTab(provider: provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _surfaceBorder),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: _textPrimary,
        unselectedLabelColor: _textSecondary,
        labelStyle: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, fontFamily: appFontFamily),
        unselectedLabelStyle: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, fontFamily: appFontFamily),
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'Change Register'),
          Tab(text: 'Impact & Approval'),
          Tab(text: 'Audit Trail'),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// TAB: Dashboard
// ═════════════════════════════════════════════════════════════════════════

class _DashboardTab extends StatelessWidget {
  final ChangeManagementProvider provider;
  const _DashboardTab({required this.provider});

  static const _accent = LightModeColors.accent;
  static const _textPrimary = Color(0xFF1A1D1F);
  static const _textSecondary = Color(0xFF6B7280);
  static const _surfaceBorder = Color(0xFFE4E7EC);
  static const _cardBg = Colors.white;

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
            crossAxisCount: MediaQuery.sizeOf(context).width > 800 ? 5 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _kpiCard('Open CRs', '${provider.openCRs}', Icons.pending_actions, const Color(0xFFF59E0B)),
              _kpiCard('Pending Approval', '${provider.pendingApprovals}', Icons.assignment_late, const Color(0xFF8B5CF6)),
              _kpiCard('Approved', '${provider.approvedCRs}', Icons.check_circle, const Color(0xFF10B981)),
              _kpiCard('Emergency', '${provider.emergencyCRs}', Icons.emergency, const Color(0xFFEF4444)),
              _kpiCard('Re-baselines', '${provider.rebaselineCount}', Icons.history, const Color(0xFF6366F1)),
            ],
          ),
          const SizedBox(height: 24),
          // Contingency & Reserve + Impact Summary
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _contingencyReserveCard()),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _impactSummaryCard()),
            ],
          ),
          const SizedBox(height: 24),
          // Recent CRs + Changes by Category
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _recentCRsCard()),
              const SizedBox(width: 16),
              Expanded(child: _categoryBreakdownCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _surfaceBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
            Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: color, size: 14)),
          ]),
          Text(value, style: TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: appFontFamily)),
        ],
      ),
    );
  }

  Widget _contingencyReserveCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _surfaceBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CONTINGENCY & RESERVE', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 16),
        // Contingency
        _reserveBar('Contingency', provider.usedContingency, provider.totalContingency, const Color(0xFFD97706)),
        const SizedBox(height: 12),
        // Reserve
        _reserveBar('Management Reserve', provider.usedReserve, provider.totalReserve, const Color(0xFF6366F1)),
        const SizedBox(height: 16),
        // Total impact
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Cost Impact (Approved)', style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            Text('\$${provider.totalCostImpact.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Schedule Impact (Approved)', style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${provider.totalScheduleImpact > 0 ? "+" : ""}${provider.totalScheduleImpact.round()} days', style: TextStyle(color: provider.totalScheduleImpact > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
        ),
      ]),
    );
  }

  Widget _reserveBar(String label, double used, double total, Color color) {
    final pct = total > 0 ? used / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        Text('\$${(used / 1000).round()}K / \$${(total / 1000).round()}K', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: const Color(0xFFE4E7EC), valueColor: AlwaysStoppedAnimation(color), minHeight: 8)),
    ]);
  }

  Widget _impactSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _surfaceBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CHANGE IMPACT SUMMARY', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 16),
        ...provider.changeRequests.take(4).map((cr) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(width: 4, height: 32, decoration: BoxDecoration(color: cr.changeType.color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cr.title, style: const TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${cr.crNumber} • ${cr.changeType.label}', style: const TextStyle(color: _textSecondary, fontSize: 10)),
            ])),
            if (cr.impact.totalCostImpact > 0) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text('+\$${(cr.impact.totalCostImpact / 1000).round()}K', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w700))),
            if (cr.impact.totalScheduleImpact != 0) Container(margin: const EdgeInsets.only(left: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (cr.impact.totalScheduleImpact > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text('${cr.impact.totalScheduleImpact > 0 ? "+" : ""}${cr.impact.totalScheduleImpact.round()}d', style: TextStyle(color: cr.impact.totalScheduleImpact > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: cr.status.bgColor, borderRadius: BorderRadius.circular(4)), child: Text(cr.status.label, style: TextStyle(color: cr.status.color, fontSize: 9, fontWeight: FontWeight.w700))),
          ]),
        )),
      ]),
    );
  }

  Widget _recentCRsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _surfaceBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('RECENT CHANGE REQUESTS', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 16),
        ...provider.changeRequests.take(3).map((cr) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Icon(cr.changeType.icon, color: cr.changeType.color, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cr.title, style: const TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${cr.crNumber} • ${cr.submittedBy} • ${cr.dateSubmitted.day}/${cr.dateSubmitted.month}/${cr.dateSubmitted.year}', style: const TextStyle(color: _textSecondary, fontSize: 10)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: cr.status.bgColor, borderRadius: BorderRadius.circular(4)), child: Text(cr.status.label, style: TextStyle(color: cr.status.color, fontSize: 9, fontWeight: FontWeight.w700))),
          ]),
        )),
      ]),
    );
  }

  Widget _categoryBreakdownCard() {
    final byType = <CMChangeType, int>{};
    for (final cr in provider.changeRequests) {
      byType[cr.changeType] = (byType[cr.changeType] ?? 0) + 1;
    }
    final sorted = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _surfaceBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CHANGES BY CATEGORY', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 16),
        ...sorted.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Icon(e.key.icon, color: e.key.color, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(e.key.label, style: const TextStyle(color: _textPrimary, fontSize: 12))),
            Text('${e.value}', style: TextStyle(color: e.key.color, fontSize: 13, fontWeight: FontWeight.w800)),
          ]),
        )),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// TAB: Change Register
// ═════════════════════════════════════════════════════════════════════════

class _ChangeRegisterTab extends StatelessWidget {
  final ChangeManagementProvider provider;
  const _ChangeRegisterTab({required this.provider});

  static const _textPrimary = Color(0xFF1A1D1F);
  static const _textSecondary = Color(0xFF6B7280);
  static const _surfaceBorder = Color(0xFFE4E7EC);
  static const _cardBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Change Register', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            ElevatedButton.icon(
              onPressed: () => _showNewCRDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Change Request'),
              style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: _textPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ]),
          const SizedBox(height: 4),
          Text('${provider.changeRequests.length} change requests • ${provider.openCRs} open • ${provider.approvedCRs} approved', style: const TextStyle(color: _textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          ...provider.changeRequests.map((cr) => _changeRequestCard(cr, context)),
        ],
      ),
    );
  }

  Widget _changeRequestCard(CMChangeRequest cr, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cr.status.color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cr.status.bgColor,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          ),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: cr.changeType.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(cr.changeType.icon, color: cr.changeType.color, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cr.title, style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('${cr.crNumber} • ${cr.changeType.label} • ${cr.priority.label} Priority', style: const TextStyle(color: _textSecondary, fontSize: 11)),
            ])),
            if (cr.isEmergency) Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(4)), child: const Text('EMERGENCY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
            if (cr.isAgileRoutineRefinement) Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)), child: const Text('AGILE REFINEMENT', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 9, fontWeight: FontWeight.w700))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: cr.status.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(cr.status.label, style: TextStyle(color: cr.status.color, fontSize: 10, fontWeight: FontWeight.w700))),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Description
            Text(cr.description, style: const TextStyle(color: _textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            // Justification
            Text('Justification: ${cr.businessJustification}', style: const TextStyle(color: _textSecondary, fontSize: 12)),
            if (cr.rootCause != null) ...[const SizedBox(height: 4), Text('Root Cause: ${cr.rootCause}', style: const TextStyle(color: _textSecondary, fontSize: 12))],
            const SizedBox(height: 12),
            // Impact chips
            if (cr.impact.impactedCount > 0) ...[
              const Text('IMPACT ANALYSIS', style: TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: _buildImpactChips(cr)),
            ],
            const SizedBox(height: 12),
            // Approval workflow
            if (cr.approvalSteps.isNotEmpty) ...[
              const Text('APPROVAL WORKFLOW', style: TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 8),
              Row(children: cr.approvalSteps.map((step) {
                final idx = cr.approvalSteps.indexOf(step);
                final isCurrent = idx == cr.currentStepIndex;
                return Expanded(child: Row(children: [
                  if (idx > 0) Container(width: 8, height: 2, color: step.decision == ApprovalDecision.approved ? const Color(0xFF10B981) : const Color(0xFFE4E7EC)),
                  Container(width: 28, height: 28, decoration: BoxDecoration(color: step.decision == ApprovalDecision.approved ? const Color(0xFF10B981) : (isCurrent ? const Color(0xFFF59E0B) : const Color(0xFFE4E7EC)), shape: BoxShape.circle, border: Border.all(color: step.decision == ApprovalDecision.approved ? const Color(0xFF10B981) : (isCurrent ? const Color(0xFFF59E0B) : const Color(0xFFE4E7EC)), width: 2)), child: step.decision == ApprovalDecision.approved ? const Icon(Icons.check, color: Colors.white, size: 14) : (isCurrent ? const Icon(Icons.hourglass_top, color: Colors.white, size: 12) : null)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(step.roleLabel, style: TextStyle(color: step.decision == ApprovalDecision.approved ? const Color(0xFF10B981) : (isCurrent ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF)), fontSize: 10, fontWeight: step.decision == ApprovalDecision.approved || isCurrent ? FontWeight.w600 : FontWeight.normal), overflow: TextOverflow.ellipsis)),
                ]));
              }).toList()),
            ],
            // Action buttons
            if (cr.status == CMStatus.underReview || cr.status == CMStatus.pendingApproval) ...[
              const SizedBox(height: 12),
              Row(children: [
                ElevatedButton(onPressed: () => provider.approveStep(cr.id), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: Text('Approve as ${cr.currentStepIndex < cr.approvalSteps.length ? cr.approvalSteps[cr.currentStepIndex].roleLabel : "N/A"}')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () => provider.rejectCR(cr.id, reason: 'Rejected from UI'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text('Reject')),
              ]),
            ],
            if (cr.status == CMStatus.approved) ...[
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => provider.implementCR(cr.id, notes: 'Implemented from UI'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text('Implement Change')),
            ],
            // Re-baseline warning
            if (cr.triggersRebaseline) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2))), child: Row(children: [
                const Icon(Icons.warning_amber, color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('This change triggers a re-baseline. Affected: ${cr.affectedBaselines.join(", ")}', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11))),
              ])),
            ],
          ]),
        ),
      ]),
    );
  }

  List<Widget> _buildImpactChips(CMChangeRequest cr) {
    final chips = <Widget>[];
    for (final d in cr.impact.all) {
      if (!d.hasImpact) continue;
      final color = d.isCritical ? const Color(0xFFEF4444) : const Color(0xFF6366F1);
      final labelParts = <String>[];
      if (d.scheduleDays != null && d.scheduleDays != 0) labelParts.add('${d.scheduleDays! > 0 ? "+" : ""}${d.scheduleDays!.round()}d');
      if (d.costAmount != null && d.costAmount != 0) labelParts.add('\$${(d.costAmount! / 1000).round()}K');
      if (d.impact != null) labelParts.add(d.impact!.length > 30 ? '${d.impact!.substring(0, 30)}...' : d.impact!);
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.name, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
          Text(labelParts.join(' • '), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ));
    }
    return chips;
  }

  void _showNewCRDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final justCtrl = TextEditingController();
    var type = CMChangeType.scope;
    var priority = CMPriority.medium;
    var isEmergency = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('New Change Request',
              style: TextStyle(color: Color(0xFF1A1D1F), fontSize: 18, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title'), style: const TextStyle(color: Color(0xFF1A1D1F))),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description'), style: const TextStyle(color: Color(0xFF1A1D1F))),
                const SizedBox(height: 12),
                TextField(controller: justCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Business Justification'), style: const TextStyle(color: Color(0xFF1A1D1F))),
                const SizedBox(height: 12),
                DropdownButtonFormField<CMChangeType>(value: type, decoration: const InputDecoration(labelText: 'Change Type'), items: CMChangeType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(), onChanged: (v) => setState(() => type = v!)),
                const SizedBox(height: 8),
                DropdownButtonFormField<CMPriority>(value: priority, decoration: const InputDecoration(labelText: 'Priority'), items: CMPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(), onChanged: (v) => setState(() => priority = v!)),
                const SizedBox(height: 8),
                CheckboxListTile(value: isEmergency, onChanged: (v) => setState(() => isEmergency = v ?? false), title: const Text('Emergency Change', style: TextStyle(fontSize: 13)), dense: true, activeColor: LightModeColors.accent, contentPadding: EdgeInsets.zero),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  context.read<ChangeManagementProvider>().createChangeRequest(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    changeType: type,
                    priority: priority,
                    businessJustification: justCtrl.text.trim(),
                    isEmergency: isEmergency,
                  );
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: const Color(0xFF1A1D1F)),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// TAB: Impact & Approval
// ═════════════════════════════════════════════════════════════════════════

class _ImpactApprovalTab extends StatelessWidget {
  final ChangeManagementProvider provider;
  const _ImpactApprovalTab({required this.provider});

  static const _textPrimary = Color(0xFF1A1D1F);
  static const _textSecondary = Color(0xFF6B7280);
  static const _surfaceBorder = Color(0xFFE4E7EC);
  static const _cardBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    final pendingCRs = provider.changeRequests.where((cr) =>
        cr.status == CMStatus.underReview ||
        cr.status == CMStatus.pendingApproval ||
        cr.status == CMStatus.approved).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Impact Assessment & Approval Workflow', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('$pendingCRs.length} change requests with impact assessments', style: const TextStyle(color: _textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        ...pendingCRs.map((cr) => _impactApprovalCard(cr)),
      ]),
    );
  }

  Widget _impactApprovalCard(CMChangeRequest cr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _surfaceBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cr.changeType.color.withValues(alpha: 0.05), borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))), child: Row(children: [
          Icon(cr.changeType.icon, color: cr.changeType.color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cr.title, style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            Text('${cr.crNumber} - ${cr.changeType.label}', style: const TextStyle(color: _textSecondary, fontSize: 11)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: cr.status.bgColor, borderRadius: BorderRadius.circular(6)), child: Text(cr.status.label, style: TextStyle(color: cr.status.color, fontSize: 10, fontWeight: FontWeight.w700))),
        ])),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('IMPACT ASSESSMENT', style: TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 12),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.5, children: cr.impact.all.map((d) {
            final hasImpact = d.hasImpact;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: hasImpact ? (d.isCritical ? const Color(0xFFEF4444).withValues(alpha: 0.06) : const Color(0xFF6366F1).withValues(alpha: 0.04)) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(6), border: Border.all(color: hasImpact ? (d.isCritical ? const Color(0xFFEF4444).withValues(alpha: 0.2) : const Color(0xFF6366F1).withValues(alpha: 0.15)) : _surfaceBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(d.name, style: TextStyle(color: hasImpact ? (d.isCritical ? const Color(0xFFEF4444) : const Color(0xFF6366F1)) : _textSecondary, fontSize: 9, fontWeight: FontWeight.w600)),
                if (hasImpact) ...[
                  if (d.scheduleDays != null && d.scheduleDays != 0) Text('${d.scheduleDays! > 0 ? "+" : ""}${d.scheduleDays!.round()} days', style: TextStyle(color: d.isCritical ? const Color(0xFFEF4444) : const Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w700)),
                  if (d.costAmount != null && d.costAmount != 0) Text('\$${(d.costAmount! / 1000).round()}K', style: TextStyle(color: d.isCritical ? const Color(0xFFEF4444) : const Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w700)),
                  if (d.impact != null) Text(d.impact!, style: const TextStyle(color: _textSecondary, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                ] else Text('No impact', style: TextStyle(color: _textSecondary.withValues(alpha: 0.5), fontSize: 9)),
              ]),
            );
          }).toList()),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _totalChip('Schedule', '${cr.impact.totalScheduleImpact > 0 ? "+" : ""}${cr.impact.totalScheduleImpact.round()}d', cr.impact.totalScheduleImpact > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
            _totalChip('Cost', '\$${(cr.impact.totalCostImpact / 1000).round()}K', cr.impact.totalCostImpact > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
            _totalChip('Dimensions', '${cr.impact.impactedCount}/${cr.impact.all.length}', const Color(0xFF6366F1)),
          ])),
        ])),
      ]),
    );
  }

  Widget _totalChip(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(color: _textSecondary, fontSize: 9, fontWeight: FontWeight.w600)),
      Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════
// TAB: Audit Trail
// ═════════════════════════════════════════════════════════════════════════

class _AuditTrailTab extends StatelessWidget {
  final ChangeManagementProvider provider;
  const _AuditTrailTab({required this.provider});

  static const _textPrimary = Color(0xFF1A1D1F);
  static const _textSecondary = Color(0xFF6B7280);
  static const _surfaceBorder = Color(0xFFE4E7EC);
  static const _cardBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Audit Trail', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${provider.auditTrail.length} audit entries - Immutable record', style: const TextStyle(color: _textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        if (provider.baselineHistory.isNotEmpty) ...[
          const Text('BASELINE REVISION HISTORY', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 12),
          ...provider.baselineHistory.map((rev) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2))),
            child: Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: const Center(child: Text('v', style: TextStyle(color: Color(0xFF6366F1), fontSize: 14, fontWeight: FontWeight.w800)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Baseline v${rev.version} - ${rev.reason}', style: const TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                Text('By ${rev.revisedBy} - ${rev.revisionDate.day}/${rev.revisionDate.month}/${rev.revisionDate.year}', style: const TextStyle(color: _textSecondary, fontSize: 10)),
              ])),
            ]),
          )),
          const SizedBox(height: 24),
        ],
        const Text('ACTIVITY LOG', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...provider.auditTrail.reversed.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _surfaceBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.action, style: const TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                if (entry.details != null) Text(entry.details!, style: const TextStyle(color: _textSecondary, fontSize: 11)),
                Text('${entry.user} - ${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year}', style: const TextStyle(color: _textSecondary, fontSize: 10)),
              ]),
            )),
          ]),
        )),
      ]),
    );
  }
}
