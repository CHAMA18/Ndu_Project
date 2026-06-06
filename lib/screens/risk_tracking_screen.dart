import 'package:flutter/material.dart';
import 'package:ndu_project/screens/launch_checklist_screen.dart';
import 'package:ndu_project/screens/scope_completion_screen.dart';
import 'package:ndu_project/utils/execution_phase_ai_seed.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/inline_editable_text.dart';

import 'package:ndu_project/widgets/voice_text_field.dart';
import 'package:ndu_project/utils/pdf_export_helper.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
class RiskTrackingScreen extends StatefulWidget {
  const RiskTrackingScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RiskTrackingScreen()),
    );
  }

  @override
  State<RiskTrackingScreen> createState() => _RiskTrackingScreenState();
}

class _RiskTrackingScreenState extends State<RiskTrackingScreen> {
  final List<_RiskItem> _risks = [];

  List<_RiskSignal> _signals = [
    _RiskSignal(
      id: 'SIG-001',
      title: 'Critical path dependencies',
      category: 'Leading',
      severity: 'Critical',
      confidence: 'High',
      description: '2 risks require executive unblock on the critical path. '
          'Delay in resolution could cascade across dependent workstreams.',
      linkedRisk: 'R-001',
      trend: 'Increasing',
      detectedDate: '2026-05-06',
    ),
    _RiskSignal(
      id: 'SIG-002',
      title: 'Security posture drift',
      category: 'Lagging',
      severity: 'High',
      confidence: 'Medium',
      description: '1 high risk pending penetration retest. '
          'Security baseline has deviated from approved architecture.',
      linkedRisk: 'R-003',
      trend: 'Stable',
      detectedDate: '2026-05-04',
    ),
    _RiskSignal(
      id: 'SIG-003',
      title: 'Budget volatility',
      category: 'Leading',
      severity: 'Medium',
      confidence: 'High',
      description: 'Forecast variance at 6%. Cost trajectory trending above '
          'approved baseline with potential for further deviation.',
      linkedRisk: 'R-005',
      trend: 'Increasing',
      detectedDate: '2026-05-07',
    ),
    _RiskSignal(
      id: 'SIG-004',
      title: 'Resource utilization imbalance',
      category: 'Leading',
      severity: 'Medium',
      confidence: 'Medium',
      description: 'Team capacity at 94% with 2 key roles unfilled. '
          'Sprint velocity has declined 12% over last 3 sprints.',
      linkedRisk: 'R-007',
      trend: 'Increasing',
      detectedDate: '2026-05-05',
    ),
  ];

  final List<_EscalationReadiness> _escalations = [
    _EscalationReadiness(
      id: 'ESC-001',
      event: 'Executive sync — critical path unblock',
      level: 'L3-Executive',
      triggerCondition: '2+ critical risks unresolved > 48 hrs',
      responsibleParty: 'A. Mwanza',
      escalationTarget: 'CTO / Steering Committee',
      status: 'Ready',
      readiness: 0.85,
      responseWindow: '4 hrs',
      decisionRequired: 'Approve expedited vendor failover deployment',
      lastReview: '2026-05-07',
    ),
    _EscalationReadiness(
      id: 'ESC-002',
      event: 'Risk board update — regulatory submission',
      level: 'L2-Management',
      triggerCondition: 'Compliance SLA breach or regulatory deadline < 5 days',
      responsibleParty: 'B. Tembo',
      escalationTarget: 'VP Legal / Risk Board',
      status: 'Pending',
      readiness: 0.60,
      responseWindow: '8 hrs',
      decisionRequired: 'Authorize parallel regulatory submission track',
      lastReview: '2026-05-06',
    ),
    _EscalationReadiness(
      id: 'ESC-003',
      event: 'Ops stakeholder review — security posture',
      level: 'L2-Management',
      triggerCondition: 'Penetration retest overdue or critical vulnerability detected',
      responsibleParty: 'D. Phiri',
      escalationTarget: 'CISO / Ops Review Board',
      status: 'In progress',
      readiness: 0.45,
      responseWindow: '24 hrs',
      decisionRequired: 'Approve emergency patch cycle & retest schedule',
      lastReview: '2026-05-05',
    ),
    _EscalationReadiness(
      id: 'ESC-004',
      event: 'Budget variance escalation — forecast drift',
      level: 'L3-Executive',
      triggerCondition: 'Forecast variance > 8% or contingency depleted',
      responsibleParty: 'E. Zulu',
      escalationTarget: 'CFO / Executive Sponsor',
      status: 'Deferred',
      readiness: 0.30,
      responseWindow: '12 hrs',
      decisionRequired: 'Release contingency reserve & revise budget baseline',
      lastReview: '2026-05-04',
    ),
  ];

  List<_MitigationPlan> _plans = [
    _MitigationPlan(
      id: 'MIT-001',
      riskId: 'R-001',
      strategy: 'Vendor API stability — failover circuit breaker implementation',
      owner: 'A. Mwanza',
      category: 'Integrations',
      status: 'On track',
      coverage: 0.78,
      targetDate: '2026-05-30',
      effectiveness: 'High',
      residualRisk: 'Low',
    ),
    _MitigationPlan(
      id: 'MIT-002',
      riskId: 'R-002',
      strategy: 'Regulatory review delay — parallel submission track with legal',
      owner: 'B. Tembo',
      category: 'Compliance',
      status: 'At risk',
      coverage: 0.42,
      targetDate: '2026-06-15',
      effectiveness: 'Medium',
      residualRisk: 'High',
    ),
    _MitigationPlan(
      id: 'MIT-003',
      riskId: 'R-003',
      strategy: 'Data quality regression — automated validation pipeline deployment',
      owner: 'C. Banda',
      category: 'Data team',
      status: 'On track',
      coverage: 0.64,
      targetDate: '2026-05-25',
      effectiveness: 'High',
      residualRisk: 'Medium',
    ),
    _MitigationPlan(
      id: 'MIT-004',
      riskId: 'R-004',
      strategy: 'Security posture drift — scheduled penetration retest & patch cycle',
      owner: 'D. Phiri',
      category: 'Cybersecurity',
      status: 'In progress',
      coverage: 0.55,
      targetDate: '2026-06-01',
      effectiveness: 'Medium',
      residualRisk: 'Medium',
    ),
    _MitigationPlan(
      id: 'MIT-005',
      riskId: 'R-005',
      strategy: 'Budget volatility — revised forecast with contingency allocation',
      owner: 'E. Zulu',
      category: 'Finance',
      status: 'Not started',
      coverage: 0.0,
      targetDate: '2026-06-10',
      effectiveness: 'Low',
      residualRisk: 'High',
    ),
  ];

  bool _autoGenerationTriggered = false;
  bool _isAutoGenerating = false;

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoGenerateIfNeeded());
  }

  Future<void> _autoGenerateIfNeeded() async {
    if (!mounted || _autoGenerationTriggered || _isAutoGenerating) return;
    if (_risks.isNotEmpty) return;

    _autoGenerationTriggered = true;
    _isAutoGenerating = true;
    try {
      final generated = await ExecutionPhaseAiSeed.generateEntries(
        context: context,
        section: 'Risk Tracking',
        sections: const {
          'risks': 'Active execution risks to monitor',
          'signals': 'Risk signals and alerts',
          'mitigationPlans': 'Mitigation plans and ownership',
        },
        itemsPerSection: 3,
      );

      final risks = generated['risks'] ?? const <LaunchEntry>[];
      final signals = generated['signals'] ?? const <LaunchEntry>[];
      final plans = generated['mitigationPlans'] ?? const <LaunchEntry>[];

      if (!mounted) return;
      setState(() {
        if (risks.isNotEmpty) {
          _risks
            ..clear()
            ..addAll(risks.map(
              (entry) => _RiskItem(
                _newId(),
                entry.title,
                'Risk Owner',
                'Medium',
                'Medium',
                entry.status?.isNotEmpty == true ? entry.status! : 'Open',
                'TBD',
              ),
            ));
        }
        if (signals.isNotEmpty) {
          _signals = signals.map(
            (entry) => _RiskSignal(
              id: 'SIG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              title: entry.title,
              category: 'Leading',
              severity: 'Medium',
              confidence: 'Medium',
              description: entry.details,
              linkedRisk: '—',
              trend: 'Stable',
              detectedDate: DateTime.now().toIso8601String().substring(0, 10),
            ),
          ).toList();
        }
        if (plans.isNotEmpty) {
          _plans = plans.asMap().entries.map(
            (entry) => _MitigationPlan(
              id: 'MIT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              riskId: '—',
              strategy: entry.value.title,
              owner: 'Risk Lead',
              category: 'General',
              status: entry.value.status?.isNotEmpty == true
                  ? entry.value.status!
                  : 'On track',
              coverage: 0.6,
              targetDate: '2026-06-01',
              effectiveness: 'Medium',
              residualRisk: 'Medium',
            ),
          ).toList();
        }
      });
    } catch (e) {
      debugPrint('Error auto-generating risk tracking data: $e');
    } finally {
      _isAutoGenerating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Risk Tracking',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(positioned: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlanningPhaseHeader(
            title: 'Risk Tracking',
            showImportButton: false,
            showContentButton: false,
            showNavigationButtons: false, onExportPdf: _exportPdf),
          const SizedBox(height: 16),
                        _buildHeader(isNarrow),
            const SizedBox(height: 20),
            _buildStatsRow(isNarrow),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRiskRegister(),
                const SizedBox(height: 20),
                _buildMitigationPanel(),
                const SizedBox(height: 20),
                _buildSignalsPanel(),
                const SizedBox(height: 20),
                _buildEscalationPanel(),
              ],
            ),
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Start-up / Launch Checklist',
              nextLabel: 'Next: Scope Completion',
              onBack: () => LaunchChecklistScreen.open(context),
              onNext: () => ScopeCompletionScreen.open(context),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'EXECUTION SAFETY',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Risk Tracking',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Monitor active risks, mitigation coverage, and escalation readiness across execution.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (!isNarrow) _buildHeaderActions(),
          ],
        ),
        if (isNarrow) ...[
          const SizedBox(height: 12),
          _buildHeaderActions(),
        ],
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _actionButton(Icons.add, 'Add risk', onPressed: _openAddRiskDialog),
        _actionButton(Icons.download_outlined, 'Import risk log',
            onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Risk log import is queued. You can add risks manually now using Add risk.')),
          );
        }),
        _actionButton(Icons.description_outlined, 'Export report',
            onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Risk report export is queued while report templates are finalized.')),
          );
        }),
        _primaryButton('Run weekly review'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      label: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _primaryButton(String label) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Weekly review started.')),
        );
      },
      icon: const Icon(Icons.play_arrow, size: 18),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow(bool isNarrow) {
    final stats = [
      _StatCardData(
        'Active risks',
        '$_activeRiskCount',
        '$_criticalRiskCount critical',
        const Color(0xFFEF4444),
      ),
      _StatCardData(
        'Mitigation coverage',
        '${(_mitigationCoverageRate * 100).round()}%',
        _risks.isEmpty
            ? 'Add risks to start tracking'
            : '$_mitigatedRiskCount of $_activeRiskCount mitigated',
        const Color(0xFF10B981),
      ),
      _StatCardData(
        'Escalations',
        '$_escalationCount',
        _escalationCount > 0 ? 'Exec sync scheduled' : 'None',
        const Color(0xFFF97316),
      ),
      _StatCardData(
        'Exposure score',
        _risks.isEmpty ? '—' : '$_exposureScore/100',
        _risks.isEmpty ? 'Add risks to compute' : _exposureStatus,
        const Color(0xFF6366F1),
      ),
    ];

    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => _buildStatCard(stat)).toList(),
      );
    }

    return Row(
      children: stats
          .map((stat) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildStatCard(stat),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: data.color)),
          const SizedBox(height: 6),
          Text(data.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(data.supporting,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: data.color)),
        ],
      ),
    );
  }

  // ─── Computed Properties ──────────────────────────────────────────────────

  int get _activeRiskCount => _risks.length;

  int get _criticalRiskCount =>
      _risks.where((risk) => risk.impact == 'High').length;

  int get _mitigatedRiskCount =>
      _risks.where((risk) => _isMitigatingStatus(risk.status)).length;

  double get _mitigationCoverageRate =>
      _risks.isEmpty ? 0 : _mitigatedRiskCount / _activeRiskCount;

  int get _escalationCount =>
      _risks.where((risk) => risk.status == 'Escalated').length;

  double get _averageProbability => _risks.isEmpty
      ? 0
      : _risks
              .map((risk) => _safeProbability(risk.probability))
              .reduce((a, b) => a + b) /
          _activeRiskCount;

  int get _exposureScore => _risks.isEmpty
      ? 0
      : ((1 - _averageProbability).clamp(0.0, 1.0) * 100).round();

  String get _exposureStatus => _exposureScore >= 70
      ? 'Stable'
      : _exposureScore >= 40
          ? 'Caution'
          : 'At risk';

  double _safeProbability(String value) {
    return (double.tryParse(value) ?? 0).clamp(0.0, 1.0);
  }

  bool _isMitigatingStatus(String status) {
    return status == 'Mitigating' ||
        status == 'Monitoring' ||
        status == 'Accepted';
  }

  // ─── Risk Register ────────────────────────────────────────────────────────

  Widget _buildRiskRegister() {
    return _PanelShell(
      title: 'Risk register',
      subtitle: 'Live view of probability, impact, and mitigation status',
      trailing: _actionButton(Icons.filter_list, 'Filter'),
      child: _risks.isEmpty
          ? _buildEmptyRiskState()
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      headingRowHeight: 32,
                      dataRowHeight: 36,
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(
                            label: Text('ID',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Risk',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Owner',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Probability',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Impact',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Next review',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                      ],
                      rows: _risks.map((risk) {
                        return DataRow(cells: [
                          DataCell(Text(risk.id,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF0EA5E9)))),
                          DataCell(InlineEditableText(
                            value: risk.title,
                            onChanged: (v) { setState(() { risk.title = v; }); },
                            style: const TextStyle(fontSize: 13),
                            enableVoice: false,
                          )),
                          DataCell(InlineEditableText(
                            value: risk.owner,
                            onChanged: (v) { setState(() { risk.owner = v; }); },
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            enableVoice: false,
                          )),
                          DataCell(_editableChipCell(
                            chip: _chip('${risk.probability} p'),
                            options: const ['0.1 p', '0.2 p', '0.3 p', '0.4 p', '0.5 p', '0.6 p', '0.7 p', '0.8 p', '0.9 p', '1.0 p'],
                            currentValue: '${risk.probability} p',
                            onChanged: (v) { setState(() { risk.probability = v.replaceAll(' p', ''); }); },
                          )),
                          DataCell(_editableChipCell(
                            chip: _impactChip(risk.impact),
                            options: const ['Low', 'Medium', 'High'],
                            currentValue: risk.impact,
                            onChanged: (v) { setState(() { risk.impact = v; }); },
                          )),
                          DataCell(_editableChipCell(
                            chip: _statusChip(risk.status),
                            options: const ['Mitigating', 'Monitoring', 'Escalated', 'Accepted'],
                            currentValue: risk.status,
                            onChanged: (v) { setState(() { risk.status = v; }); },
                          )),
                          DataCell(InlineEditableText(
                            value: risk.nextReview,
                            onChanged: (v) { setState(() { risk.nextReview = v; }); },
                            style: const TextStyle(fontSize: 12),
                            hint: 'YYYY-MM-DD',
                            enableVoice: false,
                          )),
                          DataCell(_buildRowActions(
                            onEdit: () => _openEditRiskDialog(risk),
                            onDelete: () => _deleteRisk(risk),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyRiskState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No risks logged yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a risk to start tracking probability, impact, and mitigation status for your execution plan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _actionButton(Icons.add, 'Add risk', onPressed: _openAddRiskDialog),
        ],
      ),
    );
  }

  Widget _buildRowActions({required VoidCallback onEdit, required VoidCallback onDelete}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconButton(Icons.edit_outlined, 'Edit', onEdit),
        const SizedBox(width: 4),
        _iconButton(Icons.delete_outline, 'Delete', onDelete, isDestructive: true),
      ],
    );
  }

  Widget _iconButton(IconData icon, String tooltip, VoidCallback onTap, {bool isDestructive = false}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon,
              size: 16,
              color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF64748B)),
        ),
      ),
    );
  }

  // ─── Mitigation Coverage Table ────────────────────────────────────────────

  Widget _buildMitigationPanel() {
    return _PanelShell(
      title: 'Mitigation coverage',
      subtitle: 'Execution readiness by risk program — aligned to ISO 31000 & PMI Risk Practice',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionButton(Icons.add, 'Add plan', onPressed: _openAddMitigationDialog),
        ],
      ),
      child: _plans.isEmpty
          ? _buildEmptyMitigationState()
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      headingRowHeight: 32,
                      dataRowHeight: 36,
                      columnSpacing: 14,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(
                            label: Text('ID',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Risk Ref',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Mitigation Strategy',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Owner',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Category',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Coverage',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Target',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Effectiveness',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Residual',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                      ],
                      rows: _plans.map((plan) {
                        return DataRow(cells: [
                          DataCell(Text(plan.id,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF0EA5E9), fontWeight: FontWeight.w600))),
                          DataCell(InlineEditableText(
                            value: plan.riskId,
                            onChanged: (v) { setState(() { plan.riskId = v; }); },
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1)),
                            enableVoice: false,
                          )),
                          DataCell(SizedBox(
                            width: 220,
                            child: InlineEditableText(
                              value: plan.strategy,
                              onChanged: (v) { setState(() { plan.strategy = v; }); },
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              enableVoice: false,
                            ),
                          )),
                          DataCell(InlineEditableText(
                            value: plan.owner,
                            onChanged: (v) { setState(() { plan.owner = v; }); },
                            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                            enableVoice: false,
                          )),
                          DataCell(_editableChipCell(
                            chip: _categoryChip(plan.category),
                            options: const ['Integrations', 'Compliance', 'Data team', 'Cybersecurity', 'Finance', 'General'],
                            currentValue: plan.category,
                            onChanged: (v) { setState(() { plan.category = v; }); },
                          )),
                          DataCell(_editableChipCell(
                            chip: _mitigationStatusChip(plan.status),
                            options: const ['Not started', 'In progress', 'On track', 'At risk', 'Completed'],
                            currentValue: plan.status,
                            onChanged: (v) { setState(() { plan.status = v; }); },
                          )),
                          DataCell(_buildCoverageCell(plan)),
                          DataCell(InlineEditableText(
                            value: plan.targetDate,
                            onChanged: (v) { setState(() { plan.targetDate = v; }); },
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            hint: 'YYYY-MM-DD',
                            enableVoice: false,
                          )),
                          DataCell(_editableChipCell(
                            chip: _effectivenessChip(plan.effectiveness),
                            options: const ['High', 'Medium', 'Low'],
                            currentValue: plan.effectiveness,
                            onChanged: (v) { setState(() { plan.effectiveness = v; }); },
                          )),
                          DataCell(_editableChipCell(
                            chip: _residualRiskChip(plan.residualRisk),
                            options: const ['Low', 'Medium', 'High'],
                            currentValue: plan.residualRisk,
                            onChanged: (v) { setState(() { plan.residualRisk = v; }); },
                          )),
                          DataCell(_buildRowActions(
                            onEdit: () => _openEditMitigationDialog(plan),
                            onDelete: () => _deleteMitigationPlan(plan),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyMitigationState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 40, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          const Text(
            'No mitigation plans defined.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add a mitigation plan to track execution readiness and residual risk.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _actionButton(Icons.add, 'Add plan', onPressed: _openAddMitigationDialog),
        ],
      ),
    );
  }

  Widget _buildCoverageCell(_MitigationPlan plan) {
    final pct = (plan.coverage * 100).round();
    final color = _coverageColor(pct);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: plan.coverage,
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text('$pct%',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Color _coverageColor(int pct) {
    if (pct >= 75) return const Color(0xFF10B981);
    if (pct >= 50) return const Color(0xFF0EA5E9);
    if (pct >= 25) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _categoryChip(String category) {
    final icon = category == 'Integrations'
        ? Icons.cable
        : category == 'Compliance'
            ? Icons.gavel
            : category == 'Data team'
                ? Icons.storage
                : category == 'Cybersecurity'
                    ? Icons.security
                    : category == 'Finance'
                        ? Icons.attach_money
                        : Icons.category;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF475569)),
          const SizedBox(width: 3),
          Text(category,
              style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _mitigationStatusChip(String status) {
    final (color, icon) = switch (status) {
      'On track' => (const Color(0xFF10B981), Icons.check_circle_outline),
      'At risk' => (const Color(0xFFEF4444), Icons.warning_amber),
      'In progress' => (const Color(0xFF0EA5E9), Icons.sync),
      'Completed' => (const Color(0xFF6366F1), Icons.task_alt),
      'Not started' => (const Color(0xFF94A3B8), Icons.radio_button_unchecked),
      _ => (const Color(0xFF64748B), Icons.help_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(status,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _effectivenessChip(String effectiveness) {
    final color = effectiveness == 'High'
        ? const Color(0xFF10B981)
        : effectiveness == 'Medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(effectiveness,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _residualRiskChip(String residual) {
    final color = residual == 'Low'
        ? const Color(0xFF10B981)
        : residual == 'Medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(residual,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ─── Risk Signals Table ──────────────────────────────────────────────────

  Widget _buildSignalsPanel() {
    return _PanelShell(
      title: 'Risk signals',
      subtitle: 'Early warnings, leading/lagging indicators, and momentum shifts — COSO ERM aligned',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionButton(Icons.add, 'Add signal', onPressed: _openAddSignalDialog),
        ],
      ),
      child: _signals.isEmpty
          ? _buildEmptySignalsState()
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      headingRowHeight: 32,
                      dataRowHeight: 36,
                      columnSpacing: 14,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(
                            label: Text('Signal ID',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Signal',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Category',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Severity',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Confidence',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Description',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Linked Risk',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Trend',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Detected',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                      ],
                      rows: _signals.map((signal) {
                        return DataRow(cells: [
                          DataCell(Text(signal.id,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF0EA5E9), fontWeight: FontWeight.w600))),
                          DataCell(SizedBox(
                            width: 160,
                            child: InlineEditableText(
                              value: signal.title,
                              onChanged: (v) { setState(() { signal.title = v; }); },
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                              maxLines: 2,
                              enableVoice: false,
                            ),
                          )),
                          DataCell(_editableChipCell(
                            chip: _signalCategoryChip(signal.category),
                            options: const ['Leading', 'Lagging'],
                            currentValue: signal.category,
                            onChanged: (v) { setState(() { signal.category = v; }); },
                          )),
                          DataCell(_editableChipCell(
                            chip: _severityChip(signal.severity),
                            options: const ['Critical', 'High', 'Medium', 'Low'],
                            currentValue: signal.severity,
                            onChanged: (v) { setState(() { signal.severity = v; }); },
                          )),
                          DataCell(_editableChipCell(
                            chip: _confidenceChip(signal.confidence),
                            options: const ['High', 'Medium', 'Low'],
                            currentValue: signal.confidence,
                            onChanged: (v) { setState(() { signal.confidence = v; }); },
                          )),
                          DataCell(SizedBox(
                            width: 240,
                            child: InlineEditableText(
                              value: signal.description,
                              onChanged: (v) { setState(() { signal.description = v; }); },
                              style: const TextStyle(fontSize: 11, color: Color(0xFF374151)),
                              maxLines: 2,
                              enableVoice: false,
                            ),
                          )),
                          DataCell(InlineEditableText(
                            value: signal.linkedRisk,
                            onChanged: (v) { setState(() { signal.linkedRisk = v; }); },
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                            enableVoice: false,
                          )),
                          DataCell(_editableChipCell(
                            chip: _trendChip(signal.trend),
                            options: const ['Increasing', 'Stable', 'Decreasing'],
                            currentValue: signal.trend,
                            onChanged: (v) { setState(() { signal.trend = v; }); },
                          )),
                          DataCell(InlineEditableText(
                            value: signal.detectedDate,
                            onChanged: (v) { setState(() { signal.detectedDate = v; }); },
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            hint: 'YYYY-MM-DD',
                            enableVoice: false,
                          )),
                          DataCell(_buildRowActions(
                            onEdit: () => _openEditSignalDialog(signal),
                            onDelete: () => _deleteSignal(signal),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptySignalsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar, size: 40, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          const Text(
            'No risk signals detected.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add a risk signal to track leading and lagging indicators.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _actionButton(Icons.add, 'Add signal', onPressed: _openAddSignalDialog),
        ],
      ),
    );
  }

  Widget _signalCategoryChip(String category) {
    final isLeading = category == 'Leading';
    final color = isLeading ? const Color(0xFF0EA5E9) : const Color(0xFF8B5CF6);
    final icon = isLeading ? Icons.trending_up : Icons.history;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(category,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _severityChip(String severity) {
    final (color, icon) = switch (severity) {
      'Critical' => (const Color(0xFFDC2626), Icons.error),
      'High' => (const Color(0xFFEF4444), Icons.warning),
      'Medium' => (const Color(0xFFF59E0B), Icons.info),
      'Low' => (const Color(0xFF10B981), Icons.check_circle),
      _ => (const Color(0xFF64748B), Icons.help_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(severity,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _confidenceChip(String confidence) {
    final color = confidence == 'High'
        ? const Color(0xFF10B981)
        : confidence == 'Medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(confidence,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _trendChip(String trend) {
    final (color, icon) = switch (trend) {
      'Increasing' => (const Color(0xFFEF4444), Icons.arrow_upward),
      'Decreasing' => (const Color(0xFF10B981), Icons.arrow_downward),
      'Stable' => (const Color(0xFF0EA5E9), Icons.horizontal_rule),
      _ => (const Color(0xFF64748B), Icons.remove),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(trend,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ─── Escalation Readiness Table ──────────────────────────────────────────

  Widget _buildEscalationPanel() {
    return _PanelShell(
      title: 'Escalation readiness',
      subtitle: 'Escalation paths, decision authority, and sponsor alignment — ISO 31000 & ITIL aligned',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionButton(Icons.add, 'Add escalation', onPressed: _openAddEscalationDialog),
        ],
      ),
      child: _escalations.isEmpty
          ? _buildEmptyEscalationState()
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      headingRowHeight: 32,
                      dataRowHeight: 36,
                      columnSpacing: 14,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(
                            label: Text('ID',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Escalation Event',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Level',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Trigger Condition',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Responsible',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Escalation Target',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Readiness',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Response',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Decision Required',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Last Review',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700))),
                      ],
                      rows: _escalations.map((esc) {
                        return DataRow(cells: [
                          DataCell(Text(esc.id,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF0EA5E9), fontWeight: FontWeight.w600))),
                          DataCell(SizedBox(
                            width: 200,
                            child: InlineEditableText(
                              value: esc.event,
                              onChanged: (v) { setState(() { esc.event = v; }); },
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                              maxLines: 2,
                              enableVoice: false,
                            ),
                          )),
                          DataCell(_editableChipCell(
                            chip: _escalationLevelChip(esc.level),
                            options: const ['L1-Operational', 'L2-Management', 'L3-Executive', 'L4-Board/C-Suite'],
                            currentValue: esc.level,
                            onChanged: (v) { setState(() { esc.level = v; }); },
                          )),
                          DataCell(SizedBox(
                            width: 180,
                            child: InlineEditableText(
                              value: esc.triggerCondition,
                              onChanged: (v) { setState(() { esc.triggerCondition = v; }); },
                              style: const TextStyle(fontSize: 11, color: Color(0xFF374151)),
                              maxLines: 2,
                              enableVoice: false,
                            ),
                          )),
                          DataCell(InlineEditableText(
                            value: esc.responsibleParty,
                            onChanged: (v) { setState(() { esc.responsibleParty = v; }); },
                            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                            enableVoice: false,
                          )),
                          DataCell(InlineEditableText(
                            value: esc.escalationTarget,
                            onChanged: (v) { setState(() { esc.escalationTarget = v; }); },
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                            enableVoice: false,
                          )),
                          DataCell(_editableChipCell(
                            chip: _escalationStatusChip(esc.status),
                            options: const ['Ready', 'Pending', 'In progress', 'Escalated', 'Deferred'],
                            currentValue: esc.status,
                            onChanged: (v) { setState(() { esc.status = v; }); },
                          )),
                          DataCell(_buildEscalationReadinessCell(esc)),
                          DataCell(_editableChipCell(
                            chip: _responseWindowChip(esc.responseWindow),
                            options: const ['4 hrs', '8 hrs', '12 hrs', '24 hrs', '48 hrs'],
                            currentValue: esc.responseWindow,
                            onChanged: (v) { setState(() { esc.responseWindow = v; }); },
                          )),
                          DataCell(SizedBox(
                            width: 200,
                            child: InlineEditableText(
                              value: esc.decisionRequired,
                              onChanged: (v) { setState(() { esc.decisionRequired = v; }); },
                              style: const TextStyle(fontSize: 11, color: Color(0xFF374151)),
                              maxLines: 2,
                              enableVoice: false,
                            ),
                          )),
                          DataCell(InlineEditableText(
                            value: esc.lastReview,
                            onChanged: (v) { setState(() { esc.lastReview = v; }); },
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            hint: 'YYYY-MM-DD',
                            enableVoice: false,
                          )),
                          DataCell(_buildRowActions(
                            onEdit: () => _openEditEscalationDialog(esc),
                            onDelete: () => _deleteEscalation(esc),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyEscalationState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.vertical_align_top, size: 40, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          const Text(
            'No escalation paths defined.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add an escalation path to track decision authority and sponsor readiness.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _actionButton(Icons.add, 'Add escalation', onPressed: _openAddEscalationDialog),
        ],
      ),
    );
  }

  Widget _buildEscalationReadinessCell(_EscalationReadiness esc) {
    final pct = (esc.readiness * 100).round();
    final color = _readinessColor(pct);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: esc.readiness,
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text('$pct%',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Color _readinessColor(int pct) {
    if (pct >= 80) return const Color(0xFF10B981);
    if (pct >= 60) return const Color(0xFF0EA5E9);
    if (pct >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _escalationLevelChip(String level) {
    final (color, icon) = switch (level) {
      'L1-Operational' => (const Color(0xFF10B981), Icons.support_agent),
      'L2-Management' => (const Color(0xFF0EA5E9), Icons.manage_accounts),
      'L3-Executive' => (const Color(0xFFF59E0B), Icons.business_center),
      'L4-Board/C-Suite' => (const Color(0xFFEF4444), Icons.account_balance),
      _ => (const Color(0xFF64748B), Icons.help_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(level,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _escalationStatusChip(String status) {
    final (color, icon) = switch (status) {
      'Ready' => (const Color(0xFF10B981), Icons.check_circle_outline),
      'Pending' => (const Color(0xFFF59E0B), Icons.schedule),
      'In progress' => (const Color(0xFF0EA5E9), Icons.sync),
      'Escalated' => (const Color(0xFFEF4444), Icons.notifications_active),
      'Deferred' => (const Color(0xFF94A3B8), Icons.pause_circle_outline),
      _ => (const Color(0xFF64748B), Icons.help_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(status,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _responseWindowChip(String window) {
    final hrs = int.tryParse(window.replaceAll(RegExp(r'[^0-9]'), '')) ?? 24;
    final color = hrs <= 4
        ? const Color(0xFFEF4444)
        : hrs <= 12
            ? const Color(0xFFF59E0B)
            : const Color(0xFF0EA5E9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 11, color: color),
          const SizedBox(width: 3),
          Text(window,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ─── CRUD: Escalation Readiness ────────────────────────────────────────────

  void _openAddEscalationDialog() {
    final idController = TextEditingController();
    final eventController = TextEditingController();
    final triggerController = TextEditingController();
    final responsibleController = TextEditingController();
    final targetController = TextEditingController();
    final windowController = TextEditingController();
    final decisionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedLevel = 'L2-Management';
    var selectedStatus = 'Pending';
    var readinessValue = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add escalation path'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 480,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VoiceTextFormField(
                          controller: idController,
                          decoration: const InputDecoration(
                              labelText: 'Escalation ID', hintText: 'e.g., ESC-005'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter an ID' : null,
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: eventController,
                          decoration: const InputDecoration(
                              labelText: 'Escalation event', hintText: 'e.g., Executive sync — critical unblock'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedLevel,
                          items: ['L1-Operational', 'L2-Management', 'L3-Executive', 'L4-Board/C-Suite']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedLevel = v); },
                          decoration: const InputDecoration(labelText: 'Escalation level'),
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: triggerController,
                          decoration: const InputDecoration(
                              labelText: 'Trigger condition', hintText: 'e.g., SLA breach or threshold exceeded'),
                          maxLines: 2,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: responsibleController,
                          decoration: const InputDecoration(labelText: 'Responsible party'),
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: targetController,
                          decoration: const InputDecoration(
                              labelText: 'Escalation target', hintText: 'e.g., CTO / Steering Committee'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          items: ['Ready', 'Pending', 'In progress', 'Escalated', 'Deferred']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedStatus = v); },
                          decoration: const InputDecoration(labelText: 'Status'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Readiness: ', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child: Slider(
                                value: readinessValue,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                label: '${(readinessValue * 100).round()}%',
                                onChanged: (v) => setDialogState(() => readinessValue = v),
                              ),
                            ),
                            Text('${(readinessValue * 100).round()}%',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        VoiceTextFormField(
                          controller: windowController,
                          decoration: const InputDecoration(
                              labelText: 'Response window', hintText: 'e.g., 4 hrs, 24 hrs'),
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: decisionController,
                          decoration: const InputDecoration(
                              labelText: 'Decision required', hintText: 'What decision is needed?'),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() {
                        _escalations.add(_EscalationReadiness(
                          id: idController.text.trim(),
                          event: eventController.text.trim(),
                          level: selectedLevel,
                          triggerCondition: triggerController.text.trim(),
                          responsibleParty: responsibleController.text.trim().isEmpty ? 'TBD' : responsibleController.text.trim(),
                          escalationTarget: targetController.text.trim().isEmpty ? 'TBD' : targetController.text.trim(),
                          status: selectedStatus,
                          readiness: readinessValue,
                          responseWindow: windowController.text.trim().isEmpty ? '24 hrs' : windowController.text.trim(),
                          decisionRequired: decisionController.text.trim().isEmpty ? 'TBD' : decisionController.text.trim(),
                          lastReview: DateTime.now().toIso8601String().substring(0, 10),
                        ));
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add escalation'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      idController.dispose();
      eventController.dispose();
      triggerController.dispose();
      responsibleController.dispose();
      targetController.dispose();
      windowController.dispose();
      decisionController.dispose();
    });
  }

  void _openEditEscalationDialog(_EscalationReadiness esc) {
    final eventController = TextEditingController(text: esc.event);
    final triggerController = TextEditingController(text: esc.triggerCondition);
    final responsibleController = TextEditingController(text: esc.responsibleParty);
    final targetController = TextEditingController(text: esc.escalationTarget);
    final windowController = TextEditingController(text: esc.responseWindow);
    final decisionController = TextEditingController(text: esc.decisionRequired);
    final formKey = GlobalKey<FormState>();
    var selectedLevel = esc.level;
    var selectedStatus = esc.status;
    var readinessValue = esc.readiness;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${esc.id}'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 480,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VoiceTextFormField(
                          controller: eventController,
                          decoration: const InputDecoration(labelText: 'Escalation event'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedLevel,
                          items: ['L1-Operational', 'L2-Management', 'L3-Executive', 'L4-Board/C-Suite']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedLevel = v); },
                          decoration: const InputDecoration(labelText: 'Escalation level'),
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: triggerController,
                          decoration: const InputDecoration(labelText: 'Trigger condition'),
                          maxLines: 2,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: responsibleController,
                          decoration: const InputDecoration(labelText: 'Responsible party'),
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: targetController,
                          decoration: const InputDecoration(labelText: 'Escalation target'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          items: ['Ready', 'Pending', 'In progress', 'Escalated', 'Deferred']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedStatus = v); },
                          decoration: const InputDecoration(labelText: 'Status'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Readiness: ', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child: Slider(
                                value: readinessValue,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                label: '${(readinessValue * 100).round()}%',
                                onChanged: (v) => setDialogState(() => readinessValue = v),
                              ),
                            ),
                            Text('${(readinessValue * 100).round()}%',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        VoiceTextFormField(
                          controller: windowController,
                          decoration: const InputDecoration(labelText: 'Response window'),
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: decisionController,
                          decoration: const InputDecoration(labelText: 'Decision required'),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() {
                        final idx = _escalations.indexWhere((e) => e.id == esc.id);
                        if (idx != -1) {
                          _escalations[idx] = _EscalationReadiness(
                            id: esc.id,
                            event: eventController.text.trim(),
                            level: selectedLevel,
                            triggerCondition: triggerController.text.trim(),
                            responsibleParty: responsibleController.text.trim(),
                            escalationTarget: targetController.text.trim(),
                            status: selectedStatus,
                            readiness: readinessValue,
                            responseWindow: windowController.text.trim(),
                            decisionRequired: decisionController.text.trim(),
                            lastReview: DateTime.now().toIso8601String().substring(0, 10),
                          );
                        }
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      eventController.dispose();
      triggerController.dispose();
      responsibleController.dispose();
      targetController.dispose();
      windowController.dispose();
      decisionController.dispose();
    });
  }

  void _deleteEscalation(_EscalationReadiness esc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete escalation path?'),
        content: Text('Are you sure you want to delete ${esc.id}: "${esc.event}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              setState(() => _escalations.removeWhere((e) => e.id == esc.id));
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─── Generic Chip Helpers ─────────────────────────────────────────────────

  /// Wraps a chip widget in an InkWell that shows a dropdown dialog on tap.
  Widget _editableChipCell({
    required Widget chip,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onChanged,
  }) {
    return InkWell(
      onTap: () {
        var selected = currentValue;
        showDialog(
          context: context,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setDialogState) {
                return AlertDialog(
                  title: const Text('Select value'),
                  content: DropdownButton<String>(
                    value: options.contains(selected) ? selected : null,
                    isExpanded: true,
                    items: options
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selected = v);
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onChanged(selected);
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Update'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: chip,
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569))),
    );
  }

  Widget _statusChip(String label) {
    final color = label == 'Escalated'
        ? const Color(0xFFEF4444)
        : label == 'Mitigating'
            ? const Color(0xFF0EA5E9)
            : label == 'Monitoring'
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _impactChip(String label) {
    final color = label == 'High'
        ? const Color(0xFFEF4444)
        : label == 'Medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ─── CRUD: Risk Register ─────────────────────────────────────────────────

  void _openAddRiskDialog() {
    final idController = TextEditingController();
    final titleController = TextEditingController();
    final ownerController = TextEditingController();
    final probabilityController = TextEditingController();
    final nextReviewController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedImpact = 'High';
    var selectedStatus = 'Mitigating';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add risk'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VoiceTextFormField(
                        controller: idController,
                        decoration: const InputDecoration(
                            labelText: 'Risk ID', hintText: 'e.g., R-050'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter an ID'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      VoiceTextFormField(
                        controller: titleController,
                        decoration:
                            const InputDecoration(labelText: 'Risk title'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Describe the risk'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      VoiceTextFormField(
                        controller: ownerController,
                        decoration: const InputDecoration(labelText: 'Owner'),
                      ),
                      const SizedBox(height: 12),
                      VoiceTextFormField(
                        controller: probabilityController,
                        decoration: const InputDecoration(
                            labelText: 'Probability (e.g., 0.42)'),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedImpact,
                        items: const ['Low', 'Medium', 'High']
                            .map((impact) => DropdownMenuItem(
                                value: impact, child: Text(impact)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedImpact = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Impact'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        items: const [
                          'Mitigating',
                          'Monitoring',
                          'Escalated',
                          'Accepted'
                        ]
                            .map((status) => DropdownMenuItem(
                                value: status, child: Text(status)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedStatus = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Status'),
                      ),
                      const SizedBox(height: 12),
                      VoiceTextFormField(
                        controller: nextReviewController,
                        decoration: const InputDecoration(
                            labelText: 'Next review (date or note)'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() {
                        _risks.add(
                          _RiskItem(
                            idController.text.trim(),
                            titleController.text.trim(),
                            ownerController.text.trim().isEmpty
                                ? 'TBD'
                                : ownerController.text.trim(),
                            probabilityController.text.trim().isEmpty
                                ? '0.5'
                                : probabilityController.text.trim(),
                            selectedImpact,
                            selectedStatus,
                            nextReviewController.text.trim().isEmpty
                                ? 'TBD'
                                : nextReviewController.text.trim(),
                          ),
                        );
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add risk'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      idController.dispose();
      titleController.dispose();
      ownerController.dispose();
      probabilityController.dispose();
      nextReviewController.dispose();
    });
  }

  void _openEditRiskDialog(_RiskItem risk) {
    final titleController = TextEditingController(text: risk.title);
    final ownerController = TextEditingController(text: risk.owner);
    final probabilityController = TextEditingController(text: risk.probability);
    final nextReviewController = TextEditingController(text: risk.nextReview);
    final formKey = GlobalKey<FormState>();
    var selectedImpact = risk.impact;
    var selectedStatus = risk.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit risk ${risk.id}'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VoiceTextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Risk title'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      VoiceTextFormField(
                        controller: ownerController,
                        decoration: const InputDecoration(labelText: 'Owner'),
                      ),
                      const SizedBox(height: 12),
                      VoiceTextFormField(
                        controller: probabilityController,
                        decoration: const InputDecoration(labelText: 'Probability'),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedImpact,
                        items: ['Low', 'Medium', 'High']
                            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                            .toList(),
                        onChanged: (v) { if (v != null) setDialogState(() => selectedImpact = v); },
                        decoration: const InputDecoration(labelText: 'Impact'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        items: ['Mitigating', 'Monitoring', 'Escalated', 'Accepted']
                            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                            .toList(),
                        onChanged: (v) { if (v != null) setDialogState(() => selectedStatus = v); },
                        decoration: const InputDecoration(labelText: 'Status'),
                      ),
                      const SizedBox(height: 12),
                      VoiceTextFormField(
                        controller: nextReviewController,
                        decoration: const InputDecoration(labelText: 'Next review'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() {
                        final idx = _risks.indexWhere((r) => r.id == risk.id);
                        if (idx != -1) {
                          _risks[idx] = _RiskItem(
                            risk.id,
                            titleController.text.trim(),
                            ownerController.text.trim(),
                            probabilityController.text.trim(),
                            selectedImpact,
                            selectedStatus,
                            nextReviewController.text.trim(),
                          );
                        }
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      titleController.dispose();
      ownerController.dispose();
      probabilityController.dispose();
      nextReviewController.dispose();
    });
  }

  void _deleteRisk(_RiskItem risk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete risk?'),
        content: Text('Are you sure you want to delete risk ${risk.id}: "${risk.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              setState(() => _risks.removeWhere((r) => r.id == risk.id));
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─── CRUD: Mitigation Plans ───────────────────────────────────────────────

  void _openAddMitigationDialog() {
    final idController = TextEditingController();
    final riskIdController = TextEditingController();
    final strategyController = TextEditingController();
    final ownerController = TextEditingController();
    final targetDateController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedCategory = 'General';
    var selectedStatus = 'Not started';
    var selectedEffectiveness = 'Medium';
    var selectedResidual = 'Medium';
    var coverageValue = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add mitigation plan'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 480,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VoiceTextFormField(
                          controller: idController,
                          decoration: const InputDecoration(
                              labelText: 'Plan ID', hintText: 'e.g., MIT-006'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter an ID' : null,
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: riskIdController,
                          decoration: const InputDecoration(
                              labelText: 'Linked Risk ID', hintText: 'e.g., R-001'),
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: strategyController,
                          decoration: const InputDecoration(
                              labelText: 'Mitigation strategy', hintText: 'Describe the mitigation approach'),
                          maxLines: 2,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: ownerController,
                          decoration: const InputDecoration(labelText: 'Responsible owner'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          items: ['Integrations', 'Compliance', 'Data team', 'Cybersecurity', 'Finance', 'General']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedCategory = v); },
                          decoration: const InputDecoration(labelText: 'Category'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          items: ['Not started', 'In progress', 'On track', 'At risk', 'Completed']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedStatus = v); },
                          decoration: const InputDecoration(labelText: 'Status'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Coverage: ', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child: Slider(
                                value: coverageValue,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                label: '${(coverageValue * 100).round()}%',
                                onChanged: (v) => setDialogState(() => coverageValue = v),
                              ),
                            ),
                            Text('${(coverageValue * 100).round()}%',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        VoiceTextFormField(
                          controller: targetDateController,
                          decoration: const InputDecoration(
                              labelText: 'Target date', hintText: 'e.g., 2026-06-15'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedEffectiveness,
                          items: ['High', 'Medium', 'Low']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedEffectiveness = v); },
                          decoration: const InputDecoration(labelText: 'Effectiveness'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedResidual,
                          items: ['Low', 'Medium', 'High']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedResidual = v); },
                          decoration: const InputDecoration(labelText: 'Residual risk'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() {
                        _plans.add(_MitigationPlan(
                          id: idController.text.trim(),
                          riskId: riskIdController.text.trim().isEmpty ? '—' : riskIdController.text.trim(),
                          strategy: strategyController.text.trim(),
                          owner: ownerController.text.trim().isEmpty ? 'TBD' : ownerController.text.trim(),
                          category: selectedCategory,
                          status: selectedStatus,
                          coverage: coverageValue,
                          targetDate: targetDateController.text.trim().isEmpty ? 'TBD' : targetDateController.text.trim(),
                          effectiveness: selectedEffectiveness,
                          residualRisk: selectedResidual,
                        ));
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add plan'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      idController.dispose();
      riskIdController.dispose();
      strategyController.dispose();
      ownerController.dispose();
      targetDateController.dispose();
    });
  }

  void _openEditMitigationDialog(_MitigationPlan plan) {
    final strategyController = TextEditingController(text: plan.strategy);
    final ownerController = TextEditingController(text: plan.owner);
    final targetDateController = TextEditingController(text: plan.targetDate);
    final formKey = GlobalKey<FormState>();
    var selectedCategory = plan.category;
    var selectedStatus = plan.status;
    var selectedEffectiveness = plan.effectiveness;
    var selectedResidual = plan.residualRisk;
    var coverageValue = plan.coverage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${plan.id}'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 480,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VoiceTextFormField(
                          controller: strategyController,
                          decoration: const InputDecoration(labelText: 'Mitigation strategy'),
                          maxLines: 2,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: ownerController,
                          decoration: const InputDecoration(labelText: 'Responsible owner'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          items: ['Integrations', 'Compliance', 'Data team', 'Cybersecurity', 'Finance', 'General']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedCategory = v); },
                          decoration: const InputDecoration(labelText: 'Category'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          items: ['Not started', 'In progress', 'On track', 'At risk', 'Completed']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedStatus = v); },
                          decoration: const InputDecoration(labelText: 'Status'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Coverage: ', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child: Slider(
                                value: coverageValue,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                label: '${(coverageValue * 100).round()}%',
                                onChanged: (v) => setDialogState(() => coverageValue = v),
                              ),
                            ),
                            Text('${(coverageValue * 100).round()}%',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        VoiceTextFormField(
                          controller: targetDateController,
                          decoration: const InputDecoration(labelText: 'Target date'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedEffectiveness,
                          items: ['High', 'Medium', 'Low']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedEffectiveness = v); },
                          decoration: const InputDecoration(labelText: 'Effectiveness'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedResidual,
                          items: ['Low', 'Medium', 'High']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedResidual = v); },
                          decoration: const InputDecoration(labelText: 'Residual risk'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() {
                        final idx = _plans.indexWhere((p) => p.id == plan.id);
                        if (idx != -1) {
                          _plans[idx] = _MitigationPlan(
                            id: plan.id,
                            riskId: plan.riskId,
                            strategy: strategyController.text.trim(),
                            owner: ownerController.text.trim(),
                            category: selectedCategory,
                            status: selectedStatus,
                            coverage: coverageValue,
                            targetDate: targetDateController.text.trim(),
                            effectiveness: selectedEffectiveness,
                            residualRisk: selectedResidual,
                          );
                        }
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      strategyController.dispose();
      ownerController.dispose();
      targetDateController.dispose();
    });
  }

  void _deleteMitigationPlan(_MitigationPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete mitigation plan?'),
        content: Text('Are you sure you want to delete ${plan.id}: "${plan.strategy.substring(0, plan.strategy.length > 50 ? 50 : plan.strategy.length)}..."?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              setState(() => _plans.removeWhere((p) => p.id == plan.id));
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─── CRUD: Risk Signals ──────────────────────────────────────────────────

  void _openAddSignalDialog() {
    final idController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final linkedRiskController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedCategory = 'Leading';
    var selectedSeverity = 'Medium';
    var selectedConfidence = 'Medium';
    var selectedTrend = 'Stable';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add risk signal'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 480,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VoiceTextFormField(
                          controller: idController,
                          decoration: const InputDecoration(
                              labelText: 'Signal ID', hintText: 'e.g., SIG-005'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter an ID' : null,
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Signal name'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          items: ['Leading', 'Lagging']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedCategory = v); },
                          decoration: const InputDecoration(labelText: 'Indicator type'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedSeverity,
                          items: ['Critical', 'High', 'Medium', 'Low']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedSeverity = v); },
                          decoration: const InputDecoration(labelText: 'Severity'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedConfidence,
                          items: ['High', 'Medium', 'Low']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedConfidence = v); },
                          decoration: const InputDecoration(labelText: 'Confidence level'),
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: linkedRiskController,
                          decoration: const InputDecoration(
                              labelText: 'Linked Risk ID', hintText: 'e.g., R-001'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTrend,
                          items: ['Increasing', 'Stable', 'Decreasing']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedTrend = v); },
                          decoration: const InputDecoration(labelText: 'Trend direction'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() {
                        _signals.add(_RiskSignal(
                          id: idController.text.trim(),
                          title: titleController.text.trim(),
                          category: selectedCategory,
                          severity: selectedSeverity,
                          confidence: selectedConfidence,
                          description: descriptionController.text.trim(),
                          linkedRisk: linkedRiskController.text.trim().isEmpty ? '—' : linkedRiskController.text.trim(),
                          trend: selectedTrend,
                          detectedDate: DateTime.now().toIso8601String().substring(0, 10),
                        ));
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add signal'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      idController.dispose();
      titleController.dispose();
      descriptionController.dispose();
      linkedRiskController.dispose();
    });
  }

  void _openEditSignalDialog(_RiskSignal signal) {
    final titleController = TextEditingController(text: signal.title);
    final descriptionController = TextEditingController(text: signal.description);
    final linkedRiskController = TextEditingController(text: signal.linkedRisk);
    final formKey = GlobalKey<FormState>();
    var selectedCategory = signal.category;
    var selectedSeverity = signal.severity;
    var selectedConfidence = signal.confidence;
    var selectedTrend = signal.trend;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${signal.id}'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 480,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VoiceTextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Signal name'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          items: ['Leading', 'Lagging']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedCategory = v); },
                          decoration: const InputDecoration(labelText: 'Indicator type'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedSeverity,
                          items: ['Critical', 'High', 'Medium', 'Low']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedSeverity = v); },
                          decoration: const InputDecoration(labelText: 'Severity'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedConfidence,
                          items: ['High', 'Medium', 'Low']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedConfidence = v); },
                          decoration: const InputDecoration(labelText: 'Confidence level'),
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        VoiceTextFormField(
                          controller: linkedRiskController,
                          decoration: const InputDecoration(labelText: 'Linked Risk ID'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTrend,
                          items: ['Increasing', 'Stable', 'Decreasing']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => selectedTrend = v); },
                          decoration: const InputDecoration(labelText: 'Trend direction'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() {
                        final idx = _signals.indexWhere((s) => s.id == signal.id);
                        if (idx != -1) {
                          _signals[idx] = _RiskSignal(
                            id: signal.id,
                            title: titleController.text.trim(),
                            category: selectedCategory,
                            severity: selectedSeverity,
                            confidence: selectedConfidence,
                            description: descriptionController.text.trim(),
                            linkedRisk: linkedRiskController.text.trim().isEmpty ? '—' : linkedRiskController.text.trim(),
                            trend: selectedTrend,
                            detectedDate: signal.detectedDate,
                          );
                        }
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      titleController.dispose();
      descriptionController.dispose();
      linkedRiskController.dispose();
    });
  }

  void _deleteSignal(_RiskSignal signal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete risk signal?'),
        content: Text('Are you sure you want to delete ${signal.id}: "${signal.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              setState(() => _signals.removeWhere((s) => s.id == signal.id));
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    final projectData = ProjectDataHelper.getData(context);
    await PdfExportHelper.exportScreenPdf(
      context: context,
      screenTitle: 'Risk Tracking',
      sections: [
        PdfSection.keyValue('Project Info', [
          {'Project Name': projectData.projectName ?? 'N/A'},
          {'Solution Title': projectData.solutionTitle ?? 'N/A'},
        ]),
        PdfSection.text('Notes', projectData.planningNotes['planning_risk_tracking_notes'] ?? 'No data recorded.'),
      ],
    );
  }
}

// ─── Private Helper Widgets ─────────────────────────────────────────────────

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EscalationReadiness {
  _EscalationReadiness({
    required this.id,
    required this.event,
    required this.level,
    required this.triggerCondition,
    required this.responsibleParty,
    required this.escalationTarget,
    required this.status,
    required this.readiness,
    required this.responseWindow,
    required this.decisionRequired,
    required this.lastReview,
  });

  final String id;
  String event;
  String level; // L1-Operational | L2-Management | L3-Executive | L4-Board/C-Suite
  String triggerCondition;
  String responsibleParty;
  String escalationTarget;
  String status; // Ready | Pending | In progress | Escalated | Deferred
  double readiness;
  String responseWindow;
  String decisionRequired;
  String lastReview;
}

// ─── Data Models ────────────────────────────────────────────────────────────

class _RiskItem {
  _RiskItem(this.id, this.title, this.owner, this.probability,
      this.impact, this.status, this.nextReview);

  final String id;
  String title;
  String owner;
  String probability;
  String impact;
  String status;
  String nextReview;
}

class _RiskSignal {
  _RiskSignal({
    required this.id,
    required this.title,
    required this.category,
    required this.severity,
    required this.confidence,
    required this.description,
    required this.linkedRisk,
    required this.trend,
    required this.detectedDate,
  });

  final String id;
  String title;
  String category; // Leading | Lagging
  String severity; // Critical | High | Medium | Low
  String confidence; // High | Medium | Low
  String description;
  String linkedRisk;
  String trend; // Increasing | Stable | Decreasing
  String detectedDate;
}

class _MitigationPlan {
  _MitigationPlan({
    required this.id,
    required this.riskId,
    required this.strategy,
    required this.owner,
    required this.category,
    required this.status,
    required this.coverage,
    required this.targetDate,
    required this.effectiveness,
    required this.residualRisk,
  });

  final String id;
  String riskId;
  String strategy;
  String owner;
  String category;
  String status; // Not started | In progress | On track | At risk | Completed
  double coverage;
  String targetDate;
  String effectiveness; // High | Medium | Low
  String residualRisk; // Low | Medium | High
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
