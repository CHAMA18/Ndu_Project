import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:ndu_project/screens/detailed_design_screen.dart';
import 'package:ndu_project/screens/scope_tracking_implementation_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/agile_service.dart';

class AgileDevelopmentIterationsScreen extends StatefulWidget {
  const AgileDevelopmentIterationsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const AgileDevelopmentIterationsScreen()),
    );
  }

  @override
  State<AgileDevelopmentIterationsScreen> createState() =>
      _AgileDevelopmentIterationsScreenState();
}

class _AgileDevelopmentIterationsScreenState
    extends State<AgileDevelopmentIterationsScreen> {
  final Set<String> _selectedFilters = {'Single view of iteration health'};
  bool _expandAllStories = false;

  final TextEditingController _overviewGoalController = TextEditingController();
  final TextEditingController _overviewSummaryController =
      TextEditingController();
  final TextEditingController _overviewDependenciesController =
      TextEditingController();
  final TextEditingController _boardSummaryController =
      TextEditingController();

  final TextEditingController _iterationNameController =
      TextEditingController();
  final TextEditingController _iterationWindowController =
      TextEditingController();
  final TextEditingController _iterationFocusController =
      TextEditingController();

  final TextEditingController _throughputCommittedController =
      TextEditingController();
  final TextEditingController _throughputInProgressController =
      TextEditingController();
  final TextEditingController _throughputDoneController =
      TextEditingController();
  final TextEditingController _throughputAtRiskController =
      TextEditingController();

  final TextEditingController _healthPercentController =
      TextEditingController();
  final TextEditingController _healthNotesController = TextEditingController();
  String? _healthLevel;

  final TextEditingController _cadenceController = TextEditingController();
  final TextEditingController _burndownNoteController =
      TextEditingController();
  double _burndownProgress = 0.0;

  final List<_SimpleListItem> _overviewOutcomes = [];
  final List<_SimpleListItem> _rhythmPractices = [];
  final List<_MilestoneItem> _milestones = [];
  final List<_RiskItem> _risks = [];

  final _Debouncer _saveDebounce = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;

  static const List<String> _confidenceLevels = ['Green', 'Amber', 'Red'];
  static const List<String> _milestoneStatuses = [
    'Planned',
    'In progress',
    'At risk',
    'Complete'
  ];
  static const List<String> _riskStatuses = [
    'Open',
    'Watching',
    'Mitigating',
    'Resolved'
  ];

  String? _getProjectId() {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  Map<_BoardStatus, List<AgileStoryModel>> _groupStoriesByStatus(
      List<AgileStoryModel> stories) {
    final grouped = <_BoardStatus, List<AgileStoryModel>>{
      _BoardStatus.planned: [],
      _BoardStatus.inProgress: [],
      _BoardStatus.readyToDemo: [],
    };

    for (final story in stories) {
      switch (story.status.toLowerCase()) {
        case 'planned':
          grouped[_BoardStatus.planned]!.add(story);
          break;
        case 'inprogress':
        case 'in_progress':
          grouped[_BoardStatus.inProgress]!.add(story);
          break;
        case 'readytodemo':
        case 'ready_to_demo':
          grouped[_BoardStatus.readyToDemo]!.add(story);
          break;
      }
    }

    return grouped;
  }

  void _registerListeners() {
    final controllers = [
      _overviewGoalController,
      _overviewSummaryController,
      _overviewDependenciesController,
      _boardSummaryController,
      _iterationNameController,
      _iterationWindowController,
      _iterationFocusController,
      _throughputCommittedController,
      _throughputInProgressController,
      _throughputDoneController,
      _throughputAtRiskController,
      _healthPercentController,
      _healthNotesController,
      _cadenceController,
      _burndownNoteController,
    ];
    for (final controller in controllers) {
      controller.addListener(_scheduleSave);
    }
  }

  void _scheduleSave() {
    if (_suspendSave) return;
    _saveDebounce.run(_saveToFirestore);
  }

  Future<void> _loadFromFirestore() async {
    final projectId = _getProjectId();
    if (projectId == null || projectId.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_sections')
          .doc('agile_development_iterations')
          .get();
      final data = doc.data() ?? {};

      final overview = Map<String, dynamic>.from(data['overview'] ?? {});
      final metrics = Map<String, dynamic>.from(data['metrics'] ?? {});
      final iteration = Map<String, dynamic>.from(metrics['iteration'] ?? {});
      final throughput = Map<String, dynamic>.from(metrics['throughput'] ?? {});
      final health = Map<String, dynamic>.from(metrics['health'] ?? {});
      final board = Map<String, dynamic>.from(data['board'] ?? {});
      final rhythm = Map<String, dynamic>.from(data['rhythm'] ?? {});

      _suspendSave = true;
      _overviewGoalController.text = overview['goal']?.toString() ?? '';
      _overviewSummaryController.text = overview['summary']?.toString() ?? '';
      _overviewDependenciesController.text =
          overview['dependencies']?.toString() ?? '';
      _boardSummaryController.text = board['summary']?.toString() ?? '';
      _iterationNameController.text = iteration['label']?.toString() ?? '';
      _iterationWindowController.text = iteration['window']?.toString() ?? '';
      _iterationFocusController.text = iteration['focus']?.toString() ?? '';
      _throughputCommittedController.text =
          throughput['committed']?.toString() ?? '';
      _throughputInProgressController.text =
          throughput['inProgress']?.toString() ?? '';
      _throughputDoneController.text =
          throughput['done']?.toString() ?? '';
      _throughputAtRiskController.text =
          throughput['atRisk']?.toString() ?? '';
      _healthLevel = _normalizeConfidence(health['level']?.toString());
      _healthPercentController.text =
          _formatNumber(health['percent'], fallback: '');
      _healthNotesController.text = health['notes']?.toString() ?? '';
      _cadenceController.text = rhythm['cadence']?.toString() ?? '';
      _burndownProgress = _parseDouble(rhythm['burndownProgress']) ?? 0.0;
      _burndownNoteController.text = rhythm['burndownNote']?.toString() ?? '';
      _suspendSave = false;

      final outcomes = _SimpleListItem.fromList(overview['outcomes']);
      final practices = _SimpleListItem.fromList(rhythm['practices']);
      final milestones = _MilestoneItem.fromList(data['milestones']);
      final risks = _RiskItem.fromList(data['risks']);

      if (!mounted) return;
      setState(() {
        _overviewOutcomes
          ..clear()
          ..addAll(outcomes);
        _rhythmPractices
          ..clear()
          ..addAll(practices);
        _milestones
          ..clear()
          ..addAll(milestones);
        _risks
          ..clear()
          ..addAll(risks);
      });
    } catch (error) {
      debugPrint('Error loading agile iterations data: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveToFirestore() async {
    final projectId = _getProjectId();
    if (projectId == null || projectId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_sections')
          .doc('agile_development_iterations')
          .set({
        'overview': {
          'goal': _overviewGoalController.text.trim(),
          'summary': _overviewSummaryController.text.trim(),
          'dependencies': _overviewDependenciesController.text.trim(),
          'outcomes': _overviewOutcomes.map((e) => e.toMap()).toList(),
        },
        'metrics': {
          'iteration': {
            'label': _iterationNameController.text.trim(),
            'window': _iterationWindowController.text.trim(),
            'focus': _iterationFocusController.text.trim(),
          },
          'throughput': {
            'committed': _throughputCommittedController.text.trim(),
            'inProgress': _throughputInProgressController.text.trim(),
            'done': _throughputDoneController.text.trim(),
            'atRisk': _throughputAtRiskController.text.trim(),
          },
          'health': {
            'level': _healthLevel,
            'percent': _healthPercentController.text.trim(),
            'notes': _healthNotesController.text.trim(),
          },
        },
        'board': {
          'summary': _boardSummaryController.text.trim(),
        },
        'rhythm': {
          'cadence': _cadenceController.text.trim(),
          'burndownProgress': _burndownProgress,
          'burndownNote': _burndownNoteController.text.trim(),
          'practices': _rhythmPractices.map((e) => e.toMap()).toList(),
        },
        'milestones': _milestones.map((e) => e.toMap()).toList(),
        'risks': _risks.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Error saving agile iterations data: $error');
    }
  }

  String? _normalizeConfidence(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final option in _confidenceLevels) {
      if (option.toLowerCase() == normalized) {
        return option;
      }
    }
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _formatNumber(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    _registerListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
  }

  @override
  void dispose() {
    _overviewGoalController.dispose();
    _overviewSummaryController.dispose();
    _overviewDependenciesController.dispose();
    _boardSummaryController.dispose();
    _iterationNameController.dispose();
    _iterationWindowController.dispose();
    _iterationFocusController.dispose();
    _throughputCommittedController.dispose();
    _throughputInProgressController.dispose();
    _throughputDoneController.dispose();
    _throughputAtRiskController.dispose();
    _healthPercentController.dispose();
    _healthNotesController.dispose();
    _cadenceController.dispose();
    _burndownNoteController.dispose();
    _saveDebounce.dispose();
    super.dispose();
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
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Agile Development Iterations'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        if (_isLoading) const SizedBox(height: 16),
                        _buildPageHeader(context),
                        const SizedBox(height: 20),
                        _buildFilterChips(context),
                        const SizedBox(height: 24),
                        _buildOverviewCard(context),
                        const SizedBox(height: 20),
                        _buildMetricsRow(context, isMobile),
                        const SizedBox(height: 20),
                        _buildBoardAndRhythmRow(context),
                        const SizedBox(height: 20),
                        _buildMilestonesAndRiskRow(context),
                        const SizedBox(height: 24),
                        _buildFooterNavigation(context),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
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
            'AGILE DELIVERY',
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
          'Agile Development Iterations',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'See what is planned, what is moving, and what is at risk in the current and upcoming iterations.',
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
      'Single view of iteration health',
      'Connect work to scope and dates',
      'Highlight only the decisions that matter',
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture the iteration narrative so stand-ups, kick-offs, and reviews stay aligned on outcomes and dependencies.',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Iteration goal',
            controller: _overviewGoalController,
            hintText: 'Define the must-win outcome for this iteration.',
          ),
          const SizedBox(height: 12),
          _buildLabeledField(
            label: 'Overview summary',
            controller: _overviewSummaryController,
            hintText:
                'Summarize scope, confidence, and what could change the plan.',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildEditableListSection(
            title: 'Key outcomes',
            description:
                'List measurable outcomes the team is accountable for this iteration.',
            items: _overviewOutcomes,
            onAdd: _addOverviewOutcome,
            onChanged: _updateOverviewOutcome,
            onDelete: _deleteOverviewOutcome,
            hintText: 'Outcome statement',
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Dependencies to watch',
            controller: _overviewDependenciesController,
            hintText:
                'Capture dependencies, approvals, or external blockers to monitor.',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, bool isMobile) {
    final cards = [
      _buildIterationMetricCard(),
      _buildThroughputMetricCard(isMobile),
      _buildHealthMetricCard(),
    ];
    if (isMobile) {
      return Column(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: card,
                ))
            .toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cards
          .map((card) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: card == cards.last ? 0 : 12),
                  child: card,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildIterationMetricCard() {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricHeader('Current iteration', 'Sprint window'),
          const SizedBox(height: 12),
          _buildLabeledField(
            label: 'Sprint label',
            controller: _iterationNameController,
            hintText: 'Sprint 8 · 10 days',
          ),
          const SizedBox(height: 10),
          _buildLabeledField(
            label: 'Date range',
            controller: _iterationWindowController,
            hintText: 'Mar 4 – Mar 15',
          ),
          const SizedBox(height: 10),
          _buildLabeledField(
            label: 'Focus',
            controller: _iterationFocusController,
            hintText: 'Launch-critical scope only.',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildThroughputMetricCard(bool isMobile) {
    final fields = [
      _buildLabeledField(
        label: 'Committed',
        controller: _throughputCommittedController,
        hintText: '0',
        keyboardType: TextInputType.number,
        dense: true,
      ),
      _buildLabeledField(
        label: 'In progress',
        controller: _throughputInProgressController,
        hintText: '0',
        keyboardType: TextInputType.number,
        dense: true,
      ),
      _buildLabeledField(
        label: 'Done',
        controller: _throughputDoneController,
        hintText: '0',
        keyboardType: TextInputType.number,
        dense: true,
      ),
      _buildLabeledField(
        label: 'At risk',
        controller: _throughputAtRiskController,
        hintText: '0',
        keyboardType: TextInputType.number,
        dense: true,
      ),
    ];

    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricHeader('Stories this iteration', 'Throughput'),
          const SizedBox(height: 12),
          if (isMobile)
            Column(
              children: fields
                  .map((field) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: field,
                      ))
                  .toList(),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: fields
                  .map((field) => SizedBox(
                        width: 140,
                        child: field,
                      ))
                  .toList(),
            ),
          const SizedBox(height: 6),
          Text(
            'Use consistent counting rules to keep sprint commitment metrics trusted.',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetricCard() {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricHeader('Delivery health', 'Confidence'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _healthLevel,
                  decoration: _inputDecoration('Select confidence'),
                  items: _confidenceLevels
                      .map((level) =>
                          DropdownMenuItem(value: level, child: Text(level)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _healthLevel = value);
                    _scheduleSave();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLabeledField(
                  label: 'Percent',
                  controller: _healthPercentController,
                  hintText: '0',
                  keyboardType: TextInputType.number,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLabeledField(
            label: 'Blockers & risks',
            controller: _healthNotesController,
            hintText: 'Call out blockers, risks, and mitigation owners.',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBoardAndRhythmRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildIterationBoardCard(context),
        const SizedBox(height: 12),
        _buildIterationRhythmCard(context),
      ],
    );
  }

  Widget _buildIterationBoardCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Iteration board snapshot',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
              ),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _expandAllStories = !_expandAllStories),
                    icon: Icon(
                        _expandAllStories
                            ? Icons.unfold_less
                            : Icons.unfold_more,
                        size: 16),
                    label:
                        Text(_expandAllStories ? 'Collapse all' : 'Expand all'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  _buildOutlineBadge('Stand-up view'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Highlight the focus of the iteration board snapshot.',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _buildLabeledField(
            label: 'Board focus summary',
            controller: _boardSummaryController,
            hintText:
                'Summarize what is in scope for this board view and why it matters.',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildKanbanBoard(),
        ],
      ),
    );
  }

  Widget _buildKanbanBoard() {
    final projectId = _getProjectId();
    if (projectId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No project selected. Please open a project first.',
              style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }

    return StreamBuilder<List<AgileStoryModel>>(
      stream: AgileService.streamStories(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Error loading stories: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        final stories = snapshot.data ?? [];
        final groupedStories = _groupStoriesByStatus(stories);

        final columns = [
          _BoardStatus.planned,
          _BoardStatus.inProgress,
          _BoardStatus.readyToDemo,
        ];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < columns.length; i++) ...[
              Expanded(
                  child: _buildKanbanColumn(
                      columns[i], groupedStories[columns[i]] ?? [])),
              if (i != columns.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildKanbanColumn(
      _BoardStatus status, List<AgileStoryModel> stories) {
    return DragTarget<_StoryDragData>(
      onWillAcceptWithDetails: (DragTargetDetails<_StoryDragData> details) {
        final dragData = details.data;
        return dragData.from != status;
      },
      onAcceptWithDetails: (DragTargetDetails<_StoryDragData> details) {
        _moveStory(details.data, status);
      },
      builder: (context, candidateData, _) {
        final isActive = candidateData.isNotEmpty;
        final header = _statusLabel(status);
        final count = '${stories.length} stories';
        final badgeColors = _statusBadgeColors(status);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? badgeColors.highlight : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isActive ? badgeColors.border : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: badgeColors.foreground),
                ),
              ),
              const SizedBox(height: 12),
              ...stories.map((story) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildDraggableStory(status, story),
                  )),
              if (stories.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Text(
                    'Drag stories here',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showAddStoryDialog(context, status),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Story'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableStory(_BoardStatus status, AgileStoryModel story) {
    final card =
        _buildStoryCard(story, isExpanded: _expandAllStories, status: status);
    return Draggable<_StoryDragData>(
      data: _StoryDragData(from: status, story: story),
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Opacity(
              opacity: 0.95,
              child: _buildStoryCard(story,
                  isExpanded: true, isDragging: true, status: status)),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.45, child: card),
      child: card,
    );
  }

  Widget _buildStoryCard(AgileStoryModel story,
      {required bool isExpanded,
      bool isDragging = false,
      required _BoardStatus status}) {
    return GestureDetector(
      onTap: () => _showEditStoryDialog(context, story),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isDragging
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFFE5E7EB)),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    story.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert,
                      size: 16, color: Color(0xFF6B7280)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Edit'),
                      onTap: () => Future.delayed(Duration.zero,
                          () => _showEditStoryDialog(context, story)),
                    ),
                    PopupMenuItem(
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                      onTap: () => Future.delayed(Duration.zero,
                          () => _showDeleteStoryDialog(context, story)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Owner: ${story.owner}',
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                Text(
                  story.points,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              story.notes,
              maxLines: isExpanded ? null : 2,
              overflow:
                  isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF9CA3AF), height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStoryDialog(BuildContext context, _BoardStatus status) {
    final projectId = _getProjectId();
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }

    String statusString;
    switch (status) {
      case _BoardStatus.planned:
        statusString = 'planned';
        break;
      case _BoardStatus.inProgress:
        statusString = 'inProgress';
        break;
      case _BoardStatus.readyToDemo:
        statusString = 'readyToDemo';
        break;
    }

    final titleController = TextEditingController();
    final ownerController = TextEditingController();
    final pointsController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Story'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title *')),
              const SizedBox(height: 12),
              TextField(
                  controller: ownerController,
                  decoration: const InputDecoration(labelText: 'Owner *')),
              const SizedBox(height: 12),
              TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(labelText: 'Points *')),
              const SizedBox(height: 12),
              TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes *'),
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  ownerController.text.isEmpty ||
                  pointsController.text.isEmpty ||
                  notesController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please fill in all required fields')),
                );
                return;
              }

              try {
                await AgileService.createStory(
                  projectId: projectId,
                  title: titleController.text,
                  owner: ownerController.text,
                  points: pointsController.text,
                  notes: notesController.text,
                  status: statusString,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Story added successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditStoryDialog(BuildContext context, AgileStoryModel story) {
    final projectId = _getProjectId();
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }

    final titleController = TextEditingController(text: story.title);
    final ownerController = TextEditingController(text: story.owner);
    final pointsController = TextEditingController(text: story.points);
    final notesController = TextEditingController(text: story.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Story'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title *')),
              const SizedBox(height: 12),
              TextField(
                  controller: ownerController,
                  decoration: const InputDecoration(labelText: 'Owner *')),
              const SizedBox(height: 12),
              TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(labelText: 'Points *')),
              const SizedBox(height: 12),
              TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes *'),
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  ownerController.text.isEmpty ||
                  pointsController.text.isEmpty ||
                  notesController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please fill in all required fields')),
                );
                return;
              }

              try {
                await AgileService.updateStory(
                  projectId: projectId,
                  storyId: story.id,
                  title: titleController.text,
                  owner: ownerController.text,
                  points: pointsController.text,
                  notes: notesController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Story updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteStoryDialog(BuildContext context, AgileStoryModel story) {
    final projectId = _getProjectId();
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story'),
        content: Text(
            'Are you sure you want to delete "${story.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await AgileService.deleteStory(
                    projectId: projectId, storyId: story.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Story deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting story: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildIterationRhythmCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Iteration rhythm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Define cadence, burndown trajectory, and repeatable practices that keep the iteration healthy.',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Cadence',
            controller: _cadenceController,
            hintText: '10-day cadence',
          ),
          const SizedBox(height: 16),
          const Text(
            'Burndown trend',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          _buildBurndownBar(),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _burndownProgress.clamp(0.0, 100.0),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${_burndownProgress.round()}%',
                  onChanged: (value) {
                    setState(() => _burndownProgress = value);
                    _scheduleSave();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_burndownProgress.round()}%',
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLabeledField(
            label: 'Burndown note',
            controller: _burndownNoteController,
            hintText:
                'Explain variance from the ideal line and the mitigation plan.',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildEditableListSection(
            title: 'Rhythm practices',
            description:
                'Capture the practices that keep the iteration predictable.',
            items: _rhythmPractices,
            onAdd: _addRhythmPractice,
            onChanged: _updateRhythmPractice,
            onDelete: _deleteRhythmPractice,
            hintText: 'Practice or rule of engagement',
          ),
        ],
      ),
    );
  }

  Widget _buildBurndownBar() {
    final progress = (_burndownProgress / 100).clamp(0.0, 1.0);
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestonesAndRiskRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildUpcomingMilestonesCard(context),
        const SizedBox(height: 12),
        _buildDependencyRiskCard(context),
      ],
    );
  }

  Widget _buildUpcomingMilestonesCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming milestones',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827)),
              ),
              TextButton.icon(
                onPressed: _addMilestone,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add milestone'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1F2937),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: const Color(0xFFFFF3C4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Anchor the team on the few milestones that really matter for this execution phase.',
            style: TextStyle(
                fontSize: 13, color: const Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth =
                  constraints.maxWidth < 720 ? 720.0 : constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTableHeader(
                        const ['Milestone', 'Due date', 'Owner', 'Status', ''],
                        columnWidths: const [3, 2, 2, 2, 1],
                      ),
                      const SizedBox(height: 8),
                      if (_milestones.isEmpty)
                        const _InlineEmptyState(
                          title: 'No milestones yet',
                          message:
                              'Add milestones to track delivery commitments.',
                        )
                      else
                        ..._milestones.map(_buildMilestoneRow),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDependencyRiskCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dependency & risk watch',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827)),
              ),
              Wrap(
                spacing: 8,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Exec focus',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addRisk,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add risk'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1F2937),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      backgroundColor: const Color(0xFFFFF3C4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Only track items that can move dates or compromise launch quality.',
            style: TextStyle(
                fontSize: 13, color: const Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth =
                  constraints.maxWidth < 860 ? 860.0 : constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTableHeader(
                        const [
                          'Risk',
                          'Impact',
                          'Owner',
                          'Mitigation',
                          'Status',
                          ''
                        ],
                        columnWidths: const [3, 2, 2, 3, 2, 1],
                      ),
                      const SizedBox(height: 8),
                      if (_risks.isEmpty)
                        const _InlineEmptyState(
                          title: 'No risks yet',
                          message:
                              'Log risks and dependencies to keep leadership aligned.',
                        )
                      else
                        ..._risks.map(_buildRiskRow),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricHeader(String title, String badgeLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            badgeLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool dense = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: _inputDecoration(hintText, dense: dense),
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
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
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF93C5FD)),
      ),
    );
  }

  Widget _buildEditableListSection({
    required String title,
    required String description,
    required List<_SimpleListItem> items,
    required VoidCallback onAdd,
    required ValueChanged<_SimpleListItem> onChanged,
    required ValueChanged<String> onDelete,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1F2937),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: const Color(0xFFFFF3C4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const _InlineEmptyState(
            title: 'No entries yet',
            message: 'Add the first item to get started.',
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey(item.id),
                      initialValue: item.text,
                      decoration: _inputDecoration(hintText, dense: true),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF111827)),
                      maxLines: 2,
                      onChanged: (value) =>
                          onChanged(item.copyWith(text: value)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFEF4444)),
                    onPressed: () => onDelete(item.id),
                  ),
                ],
              ),
            ),
          ),
      ],
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

  Widget _buildMilestoneRow(_MilestoneItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              key: ValueKey('milestone-title-${item.id}'),
              initialValue: item.title,
              decoration: _inputDecoration('Milestone'),
              maxLines: 2,
              onChanged: (value) =>
                  _updateMilestone(item.copyWith(title: value)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('milestone-date-${item.id}'),
              initialValue: item.dueDate,
              decoration: _inputDecoration('Due date'),
              maxLines: 2,
              onChanged: (value) =>
                  _updateMilestone(item.copyWith(dueDate: value)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('milestone-owner-${item.id}'),
              initialValue: item.owner,
              decoration: _inputDecoration('Owner'),
              maxLines: 2,
              onChanged: (value) =>
                  _updateMilestone(item.copyWith(owner: value)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: item.status,
              decoration: _inputDecoration('Status', dense: true),
              items: _milestoneStatuses
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _updateMilestone(item.copyWith(status: value), notify: true);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => _deleteMilestone(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskRow(_RiskItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              key: ValueKey('risk-title-${item.id}'),
              initialValue: item.risk,
              decoration: _inputDecoration('Risk'),
              maxLines: 2,
              onChanged: (value) =>
                  _updateRisk(item.copyWith(risk: value)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('risk-impact-${item.id}'),
              initialValue: item.impact,
              decoration: _inputDecoration('Impact'),
              maxLines: 2,
              onChanged: (value) =>
                  _updateRisk(item.copyWith(impact: value)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('risk-owner-${item.id}'),
              initialValue: item.owner,
              decoration: _inputDecoration('Owner'),
              maxLines: 2,
              onChanged: (value) =>
                  _updateRisk(item.copyWith(owner: value)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              key: ValueKey('risk-mitigation-${item.id}'),
              initialValue: item.mitigation,
              decoration: _inputDecoration('Mitigation'),
              maxLines: 2,
              onChanged: (value) =>
                  _updateRisk(item.copyWith(mitigation: value)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: item.status,
              decoration: _inputDecoration('Status', dense: true),
              items: _riskStatuses
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _updateRisk(item.copyWith(status: value), notify: true);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => _deleteRisk(item.id),
          ),
        ],
      ),
    );
  }

  void _addOverviewOutcome() {
    setState(() {
      _overviewOutcomes.add(_SimpleListItem(id: _newId(), text: ''));
    });
    _scheduleSave();
  }

  void _updateOverviewOutcome(_SimpleListItem item) {
    final index = _overviewOutcomes.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    _overviewOutcomes[index] = item;
    _scheduleSave();
  }

  void _deleteOverviewOutcome(String id) {
    setState(() => _overviewOutcomes.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addRhythmPractice() {
    setState(() {
      _rhythmPractices.add(_SimpleListItem(id: _newId(), text: ''));
    });
    _scheduleSave();
  }

  void _updateRhythmPractice(_SimpleListItem item) {
    final index = _rhythmPractices.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    _rhythmPractices[index] = item;
    _scheduleSave();
  }

  void _deleteRhythmPractice(String id) {
    setState(() => _rhythmPractices.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addMilestone() {
    setState(() {
      _milestones.add(_MilestoneItem(
        id: _newId(),
        title: '',
        dueDate: '',
        owner: '',
        status: _milestoneStatuses.first,
      ));
    });
    _scheduleSave();
  }

  void _updateMilestone(_MilestoneItem item, {bool notify = false}) {
    final index = _milestones.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    _milestones[index] = item;
    if (notify && mounted) {
      setState(() {});
    }
    _scheduleSave();
  }

  void _deleteMilestone(String id) {
    setState(() => _milestones.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addRisk() {
    setState(() {
      _risks.add(_RiskItem(
        id: _newId(),
        risk: '',
        impact: '',
        owner: '',
        mitigation: '',
        status: _riskStatuses.first,
      ));
    });
    _scheduleSave();
  }

  void _updateRisk(_RiskItem item, {bool notify = false}) {
    final index = _risks.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    _risks[index] = item;
    if (notify && mounted) {
      setState(() {});
    }
    _scheduleSave();
  }

  void _deleteRisk(String id) {
    setState(() => _risks.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Widget _buildOutlineBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildFooterNavigation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to vendor tracking'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            Text(
              'Execution setup · 75% complete',
              style: TextStyle(fontSize: 13, color: const Color(0xFF6B7280)),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.checklist, size: 16),
              label: const Text('Review sprint checklist'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chevron_right, size: 16),
              label: const Text('Next: Scope tracking implementation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC812),
                foregroundColor: Colors.black,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC812),
                foregroundColor: Colors.black,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Ask how to de-risk this iteration'),
                  SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.lightbulb_outline,
                size: 16, color: const Color(0xFFFFC812)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Use this page as the single answer to: what we promised this iteration, where we stand today, and which decisions we need from leadership.',
                style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LaunchPhaseNavigation(
          backLabel: 'Back: Detailed Design',
          nextLabel: 'Next: Scope Tracking Implementation',
          onBack: () => DetailedDesignScreen.open(context),
          onNext: () => ScopeTrackingImplementationScreen.open(context),
        ),
      ],
    );
  }

  Future<void> _moveStory(_StoryDragData dragData, _BoardStatus target) async {
    final projectId = _getProjectId();
    if (projectId == null) return;

    String statusString;
    switch (target) {
      case _BoardStatus.planned:
        statusString = 'planned';
        break;
      case _BoardStatus.inProgress:
        statusString = 'inProgress';
        break;
      case _BoardStatus.readyToDemo:
        statusString = 'readyToDemo';
        break;
    }

    try {
      await AgileService.updateStory(
        projectId: projectId,
        storyId: dragData.story.id,
        status: statusString,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating story: $e')),
        );
      }
    }
  }

  String _statusLabel(_BoardStatus status) {
    switch (status) {
      case _BoardStatus.planned:
        return 'PLANNED';
      case _BoardStatus.inProgress:
        return 'IN PROGRESS';
      case _BoardStatus.readyToDemo:
        return 'READY TO DEMO';
    }
  }

  _StatusBadgeColors _statusBadgeColors(_BoardStatus status) {
    switch (status) {
      case _BoardStatus.planned:
        return const _StatusBadgeColors(
          background: Color(0xFFE0F2FE),
          foreground: Color(0xFF0369A1),
          border: Color(0xFF93C5FD),
          highlight: Color(0xFFF0F9FF),
        );
      case _BoardStatus.inProgress:
        return const _StatusBadgeColors(
          background: Color(0xFFEDE9FE),
          foreground: Color(0xFF6D28D9),
          border: Color(0xFFC4B5FD),
          highlight: Color(0xFFF5F3FF),
        );
      case _BoardStatus.readyToDemo:
        return const _StatusBadgeColors(
          background: Color(0xFFDCFCE7),
          foreground: Color(0xFF15803D),
          border: Color(0xFF86EFAC),
          highlight: Color(0xFFF0FDF4),
        );
    }
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

enum _BoardStatus { planned, inProgress, readyToDemo }

class _StoryDragData {
  final _BoardStatus from;
  final AgileStoryModel story;

  _StoryDragData({required this.from, required this.story});
}

class _StatusBadgeColors {
  const _StatusBadgeColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.highlight,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Color highlight;
}

class _MilestoneItem {
  _MilestoneItem({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.owner,
    required this.status,
  });

  static const List<String> _allowedStatuses = [
    'Planned',
    'In progress',
    'At risk',
    'Complete'
  ];

  final String id;
  final String title;
  final String dueDate;
  final String owner;
  final String status;

  _MilestoneItem copyWith({
    String? title,
    String? dueDate,
    String? owner,
    String? status,
  }) {
    return _MilestoneItem(
      id: id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      owner: owner ?? this.owner,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'dueDate': dueDate,
        'owner': owner,
        'status': status,
      };

  static List<_MilestoneItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      final status = map['status']?.toString() ?? 'Planned';
      return _MilestoneItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        dueDate: map['dueDate']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
        status: _allowedStatuses.contains(status) ? status : 'Planned',
      );
    }).toList();
  }
}

class _RiskItem {
  _RiskItem({
    required this.id,
    required this.risk,
    required this.impact,
    required this.owner,
    required this.mitigation,
    required this.status,
  });

  final String id;
  final String risk;
  final String impact;
  final String owner;
  final String mitigation;
  final String status;

  static const List<String> _allowedStatuses = [
    'Open',
    'Watching',
    'Mitigating',
    'Resolved'
  ];

  _RiskItem copyWith({
    String? risk,
    String? impact,
    String? owner,
    String? mitigation,
    String? status,
  }) {
    return _RiskItem(
      id: id,
      risk: risk ?? this.risk,
      impact: impact ?? this.impact,
      owner: owner ?? this.owner,
      mitigation: mitigation ?? this.mitigation,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'risk': risk,
        'impact': impact,
        'owner': owner,
        'mitigation': mitigation,
        'status': status,
      };

  static List<_RiskItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      final status = map['status']?.toString() ?? 'Open';
      return _RiskItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        risk: map['risk']?.toString() ?? '',
        impact: map['impact']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
        mitigation: map['mitigation']?.toString() ?? '',
        status: _allowedStatuses.contains(status) ? status : 'Open',
      );
    }).toList();
  }
}

class _SimpleListItem {
  _SimpleListItem({required this.id, required this.text});

  final String id;
  final String text;

  _SimpleListItem copyWith({String? text}) {
    return _SimpleListItem(id: id, text: text ?? this.text);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
      };

  static List<_SimpleListItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _SimpleListItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        text: map['text']?.toString() ?? '',
      );
    }).toList();
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
        borderRadius: BorderRadius.circular(10),
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
                    color: Color(0xFF111827),
                  ),
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
