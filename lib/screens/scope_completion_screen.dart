import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/screens/gap_analysis_scope_reconcillation_screen.dart';
import 'package:ndu_project/screens/risk_tracking_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';

class ScopeCompletionScreen extends StatefulWidget {
  const ScopeCompletionScreen({super.key});

  static void open(BuildContext context) {
    context.push('/${AppRoutes.scopeCompletion}');
  }

  @override
  State<ScopeCompletionScreen> createState() => _ScopeCompletionScreenState();
}

class _ScopeCompletionScreenState extends State<ScopeCompletionScreen> {
  final Set<String> _selectedFilters = {'Clear view of delivered scope'};

  final TextEditingController _overviewController = TextEditingController();
  final TextEditingController _statusSummaryController =
      TextEditingController();
  final TextEditingController _sponsorSummaryController =
      TextEditingController();
  final TextEditingController _changeSummaryController =
      TextEditingController();

  final TextEditingController _deliveredPercentController =
      TextEditingController();
  final TextEditingController _deliveredStatusController =
      TextEditingController();
  final TextEditingController _deferredCountController =
      TextEditingController();
  final TextEditingController _deferredStatusController =
      TextEditingController();
  final TextEditingController _criticalGapCountController =
      TextEditingController();
  final TextEditingController _criticalGapStatusController =
      TextEditingController();

  final TextEditingController _approvedChangesController =
      TextEditingController();
  final TextEditingController _unapprovedChangesController =
      TextEditingController();
  final TextEditingController _openRequestsController =
      TextEditingController();

  final List<_WorkPackageItem> _workPackages = [];
  final List<_CheckpointItem> _acceptanceCheckpoints = [];
  final List<_AcceptanceTagItem> _acceptanceTags = [];
  final List<_ScopeChangeItem> _scopeChanges = [];

  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;

  static const List<String> _workStatuses = [
    'Delivered',
    'Partially delivered',
    'Deferred',
    'Not started'
  ];
  static const List<String> _impactLevels = [
    'Critical',
    'High',
    'Medium',
    'Low'
  ];
  static const List<String> _checkpointStatuses = [
    'Pending',
    'Aligned',
    'Blocked'
  ];

  @override
  void initState() {
    super.initState();
    _registerListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
  }

  @override
  void dispose() {
    _overviewController.dispose();
    _statusSummaryController.dispose();
    _sponsorSummaryController.dispose();
    _changeSummaryController.dispose();
    _deliveredPercentController.dispose();
    _deliveredStatusController.dispose();
    _deferredCountController.dispose();
    _deferredStatusController.dispose();
    _criticalGapCountController.dispose();
    _criticalGapStatusController.dispose();
    _approvedChangesController.dispose();
    _unapprovedChangesController.dispose();
    _openRequestsController.dispose();
    _saveDebouncer.dispose();
    super.dispose();
  }

  String? _projectId() => ProjectDataHelper.getData(context).projectId;

  void _registerListeners() {
    final controllers = [
      _overviewController,
      _statusSummaryController,
      _sponsorSummaryController,
      _changeSummaryController,
      _deliveredPercentController,
      _deliveredStatusController,
      _deferredCountController,
      _deferredStatusController,
      _criticalGapCountController,
      _criticalGapStatusController,
      _approvedChangesController,
      _unapprovedChangesController,
      _openRequestsController,
    ];
    for (final controller in controllers) {
      controller.addListener(_scheduleSave);
    }
  }

  void _scheduleSave() {
    if (_suspendSave) return;
    _saveDebouncer.run(_saveToFirestore);
  }

  Future<void> _loadFromFirestore() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_sections')
          .doc('scope_completion')
          .get();
      final data = doc.data() ?? {};
      final metrics = Map<String, dynamic>.from(data['metrics'] ?? {});

      _suspendSave = true;
      _overviewController.text = data['overview']?.toString() ?? '';
      _statusSummaryController.text =
          data['statusSummary']?.toString() ?? '';
      _sponsorSummaryController.text =
          data['sponsorSummary']?.toString() ?? '';
      _changeSummaryController.text =
          data['changeSummary']?.toString() ?? '';
      _deliveredPercentController.text =
          metrics['deliveredPercent']?.toString() ?? '';
      _deliveredStatusController.text =
          metrics['deliveredStatus']?.toString() ?? '';
      _deferredCountController.text =
          metrics['deferredCount']?.toString() ?? '';
      _deferredStatusController.text =
          metrics['deferredStatus']?.toString() ?? '';
      _criticalGapCountController.text =
          metrics['criticalGapCount']?.toString() ?? '';
      _criticalGapStatusController.text =
          metrics['criticalGapStatus']?.toString() ?? '';
      _approvedChangesController.text =
          metrics['approvedChanges']?.toString() ?? '';
      _unapprovedChangesController.text =
          metrics['unapprovedChanges']?.toString() ?? '';
      _openRequestsController.text =
          metrics['openRequests']?.toString() ?? '';
      _suspendSave = false;

      final packages = _WorkPackageItem.fromList(data['workPackages']);
      final checkpoints =
          _CheckpointItem.fromList(data['acceptanceCheckpoints']);
      final tags = _AcceptanceTagItem.fromList(data['acceptanceTags']);
      final changes = _ScopeChangeItem.fromList(data['scopeChanges']);

      if (!mounted) return;
      setState(() {
        _workPackages
          ..clear()
          ..addAll(packages);
        _acceptanceCheckpoints
          ..clear()
          ..addAll(checkpoints);
        _acceptanceTags
          ..clear()
          ..addAll(tags);
        _scopeChanges
          ..clear()
          ..addAll(changes);
      });
    } catch (error) {
      debugPrint('Scope Completion load error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveToFirestore() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_sections')
          .doc('scope_completion')
          .set({
        'overview': _overviewController.text.trim(),
        'statusSummary': _statusSummaryController.text.trim(),
        'sponsorSummary': _sponsorSummaryController.text.trim(),
        'changeSummary': _changeSummaryController.text.trim(),
        'metrics': {
          'deliveredPercent': _deliveredPercentController.text.trim(),
          'deliveredStatus': _deliveredStatusController.text.trim(),
          'deferredCount': _deferredCountController.text.trim(),
          'deferredStatus': _deferredStatusController.text.trim(),
          'criticalGapCount': _criticalGapCountController.text.trim(),
          'criticalGapStatus': _criticalGapStatusController.text.trim(),
          'approvedChanges': _approvedChangesController.text.trim(),
          'unapprovedChanges': _unapprovedChangesController.text.trim(),
          'openRequests': _openRequestsController.text.trim(),
        },
        'workPackages': _workPackages.map((e) => e.toMap()).toList(),
        'acceptanceCheckpoints':
            _acceptanceCheckpoints.map((e) => e.toMap()).toList(),
        'acceptanceTags': _acceptanceTags.map((e) => e.toMap()).toList(),
        'scopeChanges': _scopeChanges.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Scope Completion save error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 18 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Scope Completion'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                        if (_isLoading) const SizedBox(height: 16),
                        _buildPageHeader(context),
                        const SizedBox(height: 20),
                        _buildFilterChips(context),
                        const SizedBox(height: 24),
                        _buildOverviewCard(context),
                        const SizedBox(height: 20),
                        _buildMainContentRow(context, isMobile),
                        const SizedBox(height: 24),
                        _buildFooterNavigation(context),
                        const SizedBox(height: 12),
                        _buildTipRow(context),
                        const SizedBox(height: 24),
                        LaunchPhaseNavigation(
                          backLabel: 'Back: Risk Tracking',
                          nextLabel: 'Next: Gap Analysis & Scope Reconciliation',
                          onBack: () => RiskTrackingScreen.open(context),
                          onNext: () => GapAnalysisScopeReconcillationScreen.open(context),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                  const _AiHelperButton(),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'SCOPE WRAP-UP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Scope Completion',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Confirm what was delivered, what changed, and that sponsors agree the project scope is formally complete.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
            height: 1.5,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final List<String> filters = [
      'Clear view of delivered scope',
      'Changes captured and approved',
      'Ready for handover',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((label) {
        final isSelected = _selectedFilters.contains(label);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              _selectedFilters.remove(label);
            } else {
              _selectedFilters.add(label);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          _buildLabeledField(
            label: 'Scope completion overview',
            controller: _overviewController,
            hintText:
                'Summarize how delivery matched the agreed scope and what is out-of-scope.',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentRow(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildScopeCompletionStatusCard(context),
          const SizedBox(height: 16),
          _buildSponsorAcceptanceCard(context),
          const SizedBox(height: 16),
          _buildScopeChangeSummaryCard(context),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildScopeCompletionStatusCard(context),
        const SizedBox(height: 16),
        _buildSponsorAcceptanceCard(context),
        const SizedBox(height: 16),
        _buildScopeChangeSummaryCard(context),
      ],
    );
  }

  Widget _buildScopeCompletionStatusCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scope completion status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Execution summary',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLabeledField(
            label: 'Completion narrative',
            controller: _statusSummaryController,
            hintText:
                'Explain delivery confidence, known deferrals, and remaining gaps.',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildMetricsRow(context),
          const SizedBox(height: 20),
          const Text(
            'Key work packages',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          _buildTableHeader(
            const ['Work package', 'Owner', 'Milestone', 'Status', 'Impact', ''],
            columnWidths: const [3, 2, 2, 2, 2, 1],
          ),
          const SizedBox(height: 10),
          if (_workPackages.isEmpty)
            const _InlineEmptyState(
              title: 'No work packages yet',
              message: 'Add work packages to summarize delivered scope.',
            )
          else
            ..._workPackages.map(_buildWorkPackageRow),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addWorkPackage,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add work package'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: const Color(0xFFFFF3C4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricBox(
            label: 'Original scope delivered',
            valueController: _deliveredPercentController,
            statusController: _deliveredStatusController,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricBox(
            label: 'Items deferred',
            valueController: _deferredCountController,
            statusController: _deferredStatusController,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricBox(
            label: 'Critical gaps',
            valueController: _criticalGapCountController,
            statusController: _criticalGapStatusController,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox({
    required String label,
    required TextEditingController valueController,
    required TextEditingController statusController,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: valueController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            decoration: const InputDecoration(
              hintText: '0',
              border: InputBorder.none,
              isDense: true,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: statusController,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
            decoration: const InputDecoration(
              hintText: 'Status note',
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkPackageRow(_WorkPackageItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              key: ValueKey('package-title-${item.id}'),
              initialValue: item.title,
              decoration: _inputDecoration('Work package'),
              maxLines: 2,
              onChanged: (value) =>
                  _updateWorkPackage(item.copyWith(title: value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('package-owner-${item.id}'),
              initialValue: item.owner,
              decoration: _inputDecoration('Owner'),
              onChanged: (value) =>
                  _updateWorkPackage(item.copyWith(owner: value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('package-milestone-${item.id}'),
              initialValue: item.milestone,
              decoration: _inputDecoration('Milestone'),
              onChanged: (value) =>
                  _updateWorkPackage(item.copyWith(milestone: value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: item.status,
              decoration: _inputDecoration('Status', dense: true),
              items: _workStatuses
                  .map((status) =>
                      DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _updateWorkPackage(item.copyWith(status: value), notify: true);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: item.impact,
              decoration: _inputDecoration('Impact', dense: true),
              items: _impactLevels
                  .map((impact) =>
                      DropdownMenuItem(value: impact, child: Text(impact)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _updateWorkPackage(item.copyWith(impact: value), notify: true);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => _deleteWorkPackage(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorAcceptanceCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sponsor acceptance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Sign-off readiness',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLabeledField(
            label: 'Acceptance summary',
            controller: _sponsorSummaryController,
            hintText:
                'Capture sponsor alignment, remaining gaps, and ownership confirmation.',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Acceptance checkpoints',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          _buildTableHeader(
            const ['Checkpoint', 'Owner', 'Status', ''],
            columnWidths: const [4, 2, 2, 1],
          ),
          const SizedBox(height: 8),
          if (_acceptanceCheckpoints.isEmpty)
            const _InlineEmptyState(
              title: 'No checkpoints yet',
              message: 'List the acceptance checkpoints for sponsor sign-off.',
            )
          else
            ..._acceptanceCheckpoints.map(_buildCheckpointRow),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _addCheckpoint,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add checkpoint'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: const Color(0xFFFFF3C4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Acceptance signals',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          if (_acceptanceTags.isEmpty)
            const _InlineEmptyState(
              title: 'No acceptance signals yet',
              message: 'Add sponsor and operations acceptance signals.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _acceptanceTags
                  .map((tag) => _buildAcceptanceTag(tag))
                  .toList(),
            ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _addAcceptanceTag,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add acceptance signal'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: const Color(0xFFFFF3C4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointRow(_CheckpointItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextFormField(
              key: ValueKey('checkpoint-title-${item.id}'),
              initialValue: item.title,
              decoration: _inputDecoration('Checkpoint'),
              maxLines: 2,
              onChanged: (value) =>
                  _updateCheckpoint(item.copyWith(title: value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('checkpoint-owner-${item.id}'),
              initialValue: item.owner,
              decoration: _inputDecoration('Owner'),
              onChanged: (value) =>
                  _updateCheckpoint(item.copyWith(owner: value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: item.status,
              decoration: _inputDecoration('Status', dense: true),
              items: _checkpointStatuses
                  .map((status) =>
                      DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _updateCheckpoint(item.copyWith(status: value), notify: true);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => _deleteCheckpoint(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptanceTag(_AcceptanceTagItem tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            child: TextFormField(
              key: ValueKey('acceptance-tag-${tag.id}'),
              initialValue: tag.label,
              decoration: const InputDecoration(
                hintText: 'Signal',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151)),
              onChanged: (value) =>
                  _updateAcceptanceTag(tag.copyWith(label: value)),
            ),
          ),
          const SizedBox(width: 6),
          DropdownButton<String>(
            value: tag.status,
            underline: const SizedBox(),
            onChanged: (value) {
              if (value == null) return;
              _updateAcceptanceTag(tag.copyWith(status: value), notify: true);
            },
            items: _checkpointStatuses
                .map((status) =>
                    DropdownMenuItem(value: status, child: Text(status)))
                .toList(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF)),
            onPressed: () => _deleteAcceptanceTag(tag.id),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeChangeSummaryCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scope change summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Change log',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLabeledField(
            label: 'Change summary',
            controller: _changeSummaryController,
            hintText:
                'Summarize the scope, budget, or timeline changes that mattered.',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          const Text(
            'Most impactful changes:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          if (_scopeChanges.isEmpty)
            const _InlineEmptyState(
              title: 'No scope changes yet',
              message: 'Add the most impactful scope changes.',
            )
          else
            ..._scopeChanges.map(_buildScopeChangeRow),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _addScopeChange,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add scope change'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: const Color(0xFFFFF3C4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMetricChip(
                label: 'Total approved changes',
                controller: _approvedChangesController,
              ),
              _buildMetricChip(
                label: 'Unapproved changes',
                controller: _unapprovedChangesController,
              ),
              _buildMetricChip(
                label: 'Open change requests',
                controller: _openRequestsController,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScopeChangeRow(_ScopeChangeItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey('scope-change-${item.id}'),
              initialValue: item.detail,
              decoration: _inputDecoration('Scope change'),
              maxLines: 2,
              onChanged: (value) =>
                  _updateScopeChange(item.copyWith(detail: value)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => _deleteScopeChange(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: _inputDecoration(hintText),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hintText, {bool dense = false}) {
    return InputDecoration(
      hintText: hintText,
      isDense: dense,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: dense ? 8 : 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF93C5FD)),
      ),
    );
  }

  Widget _buildTableHeader(List<String> labels,
      {List<int>? columnWidths}) {
    final widths =
        columnWidths ?? List<int>.filled(labels.length, 1, growable: false);
    return Row(
      children: List.generate(labels.length, (index) {
        return Expanded(
          flex: widths[index],
          child: Text(
            labels[index],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        );
      }),
    );
  }

  void _addWorkPackage() {
    setState(() {
      _workPackages.add(_WorkPackageItem(
        id: _newId(),
        title: '',
        owner: '',
        milestone: '',
        status: _workStatuses.first,
        impact: _impactLevels.first,
      ));
    });
    _scheduleSave();
  }

  void _updateWorkPackage(_WorkPackageItem item, {bool notify = false}) {
    final index = _workPackages.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    _workPackages[index] = item;
    if (notify && mounted) {
      setState(() {});
    }
    _scheduleSave();
  }

  void _deleteWorkPackage(String id) {
    setState(() => _workPackages.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addCheckpoint() {
    setState(() {
      _acceptanceCheckpoints.add(_CheckpointItem(
        id: _newId(),
        title: '',
        owner: '',
        status: _checkpointStatuses.first,
      ));
    });
    _scheduleSave();
  }

  void _updateCheckpoint(_CheckpointItem item, {bool notify = false}) {
    final index =
        _acceptanceCheckpoints.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    _acceptanceCheckpoints[index] = item;
    if (notify && mounted) {
      setState(() {});
    }
    _scheduleSave();
  }

  void _deleteCheckpoint(String id) {
    setState(
        () => _acceptanceCheckpoints.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addAcceptanceTag() {
    setState(() {
      _acceptanceTags.add(_AcceptanceTagItem(
        id: _newId(),
        label: '',
        status: _checkpointStatuses.first,
      ));
    });
    _scheduleSave();
  }

  void _updateAcceptanceTag(_AcceptanceTagItem item, {bool notify = false}) {
    final index = _acceptanceTags.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    _acceptanceTags[index] = item;
    if (notify && mounted) {
      setState(() {});
    }
    _scheduleSave();
  }

  void _deleteAcceptanceTag(String id) {
    setState(() => _acceptanceTags.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addScopeChange() {
    setState(() {
      _scopeChanges.add(_ScopeChangeItem(id: _newId(), detail: ''));
    });
    _scheduleSave();
  }

  void _updateScopeChange(_ScopeChangeItem item) {
    final index = _scopeChanges.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    _scopeChanges[index] = item;
    _scheduleSave();
  }

  void _deleteScopeChange(String id) {
    setState(() => _scopeChanges.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Widget _buildFooterNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF374151)),
            label: const Text(
              'Back to risk tracking',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Execution wrap-up · Scope view',
            style: TextStyle(fontSize: 13, color: const Color(0xFF9CA3AF)),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('Download scope report'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Finalize execution scope'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFC812),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.lightbulb_outline, size: 18, color: const Color(0xFFFFC812)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'If someone reads only this page, can they quickly see what was delivered, what moved, and that the right people have agreed?',
            style: TextStyle(fontSize: 13, color: const Color(0xFF9CA3AF), fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  final Widget child;

  const _ContentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

class _AiHelperButton extends StatelessWidget {
  const _AiHelperButton();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90,
      right: 100,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Help me summarize scope',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF374151)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827)),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkPackageItem {
  _WorkPackageItem({
    required this.id,
    required this.title,
    required this.owner,
    required this.milestone,
    required this.status,
    required this.impact,
  });

  final String id;
  final String title;
  final String owner;
  final String milestone;
  final String status;
  final String impact;

  _WorkPackageItem copyWith({
    String? title,
    String? owner,
    String? milestone,
    String? status,
    String? impact,
  }) {
    return _WorkPackageItem(
      id: id,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      milestone: milestone ?? this.milestone,
      status: status ?? this.status,
      impact: impact ?? this.impact,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'owner': owner,
        'milestone': milestone,
        'status': status,
        'impact': impact,
      };

  static List<_WorkPackageItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _WorkPackageItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
        milestone: map['milestone']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Delivered',
        impact: map['impact']?.toString() ?? 'Medium',
      );
    }).toList();
  }
}

class _CheckpointItem {
  _CheckpointItem({
    required this.id,
    required this.title,
    required this.owner,
    required this.status,
  });

  final String id;
  final String title;
  final String owner;
  final String status;

  _CheckpointItem copyWith({String? title, String? owner, String? status}) {
    return _CheckpointItem(
      id: id,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'owner': owner,
        'status': status,
      };

  static List<_CheckpointItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _CheckpointItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Pending',
      );
    }).toList();
  }
}

class _AcceptanceTagItem {
  _AcceptanceTagItem({
    required this.id,
    required this.label,
    required this.status,
  });

  final String id;
  final String label;
  final String status;

  _AcceptanceTagItem copyWith({String? label, String? status}) {
    return _AcceptanceTagItem(
      id: id,
      label: label ?? this.label,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'status': status,
      };

  static List<_AcceptanceTagItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _AcceptanceTagItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Pending',
      );
    }).toList();
  }
}

class _ScopeChangeItem {
  _ScopeChangeItem({required this.id, required this.detail});

  final String id;
  final String detail;

  _ScopeChangeItem copyWith({String? detail}) {
    return _ScopeChangeItem(id: id, detail: detail ?? this.detail);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'detail': detail,
      };

  static List<_ScopeChangeItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ScopeChangeItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        detail: map['detail']?.toString() ?? '',
      );
    }).toList();
  }
}

class _Debouncer {
  _Debouncer({Duration? delay}) : delay = delay ?? const Duration(milliseconds: 600);

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
