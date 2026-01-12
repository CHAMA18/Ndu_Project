import 'package:flutter/material.dart';

import 'package:ndu_project/screens/detailed_design_screen.dart';
import 'package:ndu_project/screens/scope_tracking_implementation_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/execution_phase_service.dart';
import 'package:ndu_project/models/agile_task.dart';
import 'package:ndu_project/utils/form_validation_engine.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/rich_text_editing_controller.dart';
import 'package:ndu_project/widgets/agile_iteration_table_widget.dart';
import 'package:ndu_project/utils/auto_bullet_text_controller.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';
import 'package:ndu_project/widgets/text_formatting_toolbar.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/execution_phase_ai_seed.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';

import 'package:ndu_project/widgets/voice_text_field.dart';
import 'package:ndu_project/utils/pdf_export_helper.dart';
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
<<<<<<< HEAD
  final Set<String> _selectedFilters = {'All'};
  List<AgileTask> _tasks = [];
  List<String> _availableRoles = [];
  bool _isLoading = false;
  bool _isRegeneratingAll = false;
  bool _autoGenerationTriggered = false;
  bool _isAutoGenerating = false;

  String? get _projectId {
=======
  final Set<String> _selectedFilters = {'Single view of iteration health'};
  final TextEditingController _notesController = TextEditingController();
  bool _expandAllStories = false;

  String? _getProjectId() {
>>>>>>> 1ee471ae (Merge codebases)
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }
<<<<<<< HEAD
=======

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
>>>>>>> 1ee471ae (Merge codebases)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
      _loadAvailableRoles();
    });
  }

  Future<void> _loadTasks() async {
    final projectId = _projectId;
    if (projectId == null) return;

    setState(() => _isLoading = true);
    try {
      final tasks =
          await ExecutionPhaseService.loadAgileTasks(projectId: projectId);
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
      await _autoGenerateIfNeeded();
    } catch (e) {
      debugPrint('Error loading agile tasks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAvailableRoles() async {
    final projectId = _projectId;
    if (projectId == null) return;

    try {
      final staffRows =
          await ExecutionPhaseService.loadStaffingRows(projectId: projectId);
      if (mounted) {
        setState(() {
          _availableRoles = staffRows
              .map((row) => row.role)
              .where((role) => role.isNotEmpty)
              .toSet()
              .toList();
        });
      }
      await _autoGenerateIfNeeded();
    } catch (e) {
      debugPrint('Error loading staff roles: $e');
    }
  }

  Future<void> _autoGenerateIfNeeded() async {
    if (!mounted || _autoGenerationTriggered || _isAutoGenerating) return;
    if (_tasks.isNotEmpty) return;
    if (_projectId == null) return;

    _autoGenerationTriggered = true;
    _isAutoGenerating = true;
    try {
      final generated = await ExecutionPhaseAiSeed.generateEntries(
        context: context,
        section: 'Agile Development Iterations',
        sections: const {
          'agileTasks': 'Agile user stories and tasks for execution',
        },
        itemsPerSection: 4,
      );
      final entries = generated['agileTasks'] ?? const [];
      if (entries.isEmpty) return;

      final roleFallback =
          _availableRoles.isNotEmpty ? _availableRoles.first : '';
      final newTasks = entries
          .map(
            (entry) => AgileTask(
              userStory: entry.title,
              assignedRole: roleFallback,
              storyPoints: 3,
              priority: 'Medium',
              status: 'To-Do',
              taskDescription: entry.details,
              acceptanceCriteria: entry.details.isNotEmpty
                  ? '. ${entry.details}'
                  : '',
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() => _tasks = newTasks);
      final projectId = _projectId;
      if (projectId != null) {
        await ExecutionPhaseService.saveAgileTasks(
          projectId: projectId,
          tasks: newTasks,
        );
      }
    } catch (e) {
      debugPrint('Error auto-generating agile tasks: $e');
    } finally {
      _isAutoGenerating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 18 : 32;

    return Scaffold(
      backgroundColor: Colors.white,
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
                        PlanningPhaseHeader(
            title: 'Agile Development Iterations',
            showImportButton: false,
            showContentButton: false,
            showNavigationButtons: false, onExportPdf: _exportPdf),
          const SizedBox(height: 16),
          _buildPageHeader(context),
                        const SizedBox(height: 20),
                        _buildFilterChips(context),
                        const SizedBox(height: 24),
                        _buildIterationTable(),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                  MobileSidebarHamburger(
                      sidebar: const InitiationLikeSidebar(
                        activeItemLabel: 'Agile Development Iterations',
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
    final isMobile = AppBreakpoints.isMobile(context);
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
<<<<<<< HEAD
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agile Development Iterations',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Manage sprint cycles, track velocity, and synchronize development tasks with design components.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (!isMobile) _buildHeaderActions(),
          ],
        ),
        if (isMobile) ...[
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
        Tooltip(
          message: 'Regenerate all task descriptions',
          child: PageRegenerateAllButton(
            isLoading: _isRegeneratingAll,
            onRegenerateAll: _regenerateAllTaskDescriptions,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _showAddTaskDialog(context),
          icon: const Icon(Icons.add, size: 18, color: Color(0xFF64748B)),
          label: const Text('Add Task',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.description_outlined,
              size: 18, color: Color(0xFF64748B)),
          label: const Text('Export',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
=======
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
>>>>>>> 1ee471ae (Merge codebases)
        ),
      ],
    );
  }

  Future<void> _regenerateAllTaskDescriptions() async {
    if (_isRegeneratingAll || _tasks.isEmpty) return;
    final projectId = _projectId;
    final provider = ProjectDataInherited.maybeOf(context);
    if (projectId == null || provider == null) return;

    final confirmed = await showRegenerateAllConfirmation(context);
    if (!confirmed) return;

    setState(() => _isRegeneratingAll = true);
    try {
      final designComponents = await ExecutionPhaseService.loadDesignComponents(
        projectId: projectId,
      );
      final componentNames =
          designComponents.map((c) => c.componentName).toList();
      final contextText = ProjectDataHelper.buildExecutivePlanContext(
        provider.projectData,
        sectionLabel: 'Agile Development Iterations',
      );
      final ai = OpenAiServiceSecure();
      final updated = <AgileTask>[];
      for (final task in _tasks) {
        try {
          final breakdown = await ai.breakDownUserStory(
            context: contextText,
            userStory: task.userStory,
            designComponents: componentNames,
          );
          updated.add(task.copyWith(taskDescription: breakdown));
        } catch (e) {
          updated.add(task);
        }
      }
      if (!mounted) return;
      setState(() => _tasks = updated);
      await ExecutionPhaseService.saveAgileTasks(
        projectId: projectId,
        tasks: updated,
      );
    } finally {
      if (mounted) setState(() => _isRegeneratingAll = false);
    }
  }

  Widget _buildFilterChips(BuildContext context) {
    final List<String> filters = [
      'All',
      'To-Do',
      'In-Progress',
      'Testing',
      'Done'
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((label) {
        final isSelected = _selectedFilters.contains(label);
        return GestureDetector(
          onTap: () => setState(() {
            _selectedFilters.clear();
            _selectedFilters.add(label);
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

<<<<<<< HEAD
  Widget _buildStatsRow(bool isNarrow) {
    // Calculate metrics from tasks
    final totalTasks = _tasks.length;
    final completedTasks = _tasks.where((t) => t.status == 'Done').length;
    final iterationProgress =
        totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;
    final sprintVelocity =
        _tasks.fold<int>(0, (sum, task) => sum + task.storyPoints);
    final activeBlockers = _tasks
        .where((t) => t.status == 'To-Do' && t.priority == 'Critical')
        .length;

    final stats = [
      _StatCardData('Iteration Progress', '$iterationProgress%',
          '$completedTasks/$totalTasks tasks', const Color(0xFF0EA5E9)),
      _StatCardData('Sprint Velocity', '$sprintVelocity', 'Total story points',
          const Color(0xFF6366F1)),
      _StatCardData('Active Blockers', '$activeBlockers',
          'Critical tasks pending', const Color(0xFFEF4444)),
    ];

    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => _buildStatCard(stat)).toList(),
=======
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
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Text(
            'Use this page during stand-ups, iteration kick-offs, and demos to ground the team on what must land this cycle, how confident you are, and which dependencies could slow you down.',
            style: TextStyle(
                fontSize: 14, color: const Color(0xFF6B7280), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, bool isMobile) {
    final metrics = [
      _MetricData(
        badgeLabel: 'Sprint window',
        title: 'Sprint 8 · 10 days',
        subtitle:
            'Mar 4 – Mar 15 · Focus on core launch-critical stories only.',
        header: 'Current iteration',
      ),
      _MetricData(
        badgeLabel: 'Throughput',
        title: '21 committed',
        subtitle: '16 in progress · 3 done · 2 flagged as at risk.',
        header: 'Stories this iteration',
      ),
      _MetricData(
        badgeLabel: 'Confidence',
        title: 'Amber · 78%',
        subtitle:
            'Blocked on environment stability and one external integration dependency.',
        header: 'Delivery health',
        titleColor: const Color(0xFFD97706),
      ),
    ];

    if (isMobile) {
      return Column(
        children: metrics
            .map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMetricCard(m),
                ))
            .toList(),
>>>>>>> 1ee471ae (Merge codebases)
      );
    }

    return Row(
<<<<<<< HEAD
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
=======
      crossAxisAlignment: CrossAxisAlignment.start,
      children: metrics
          .map((m) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: m == metrics.last ? 0 : 12),
                  child: _buildMetricCard(m),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMetricCard(_MetricData data) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.header,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  data.badgeLabel,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: data.titleColor ?? const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardAndRhythmRow(BuildContext context, bool isMobile) {
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
            'A compressed view of the board focusing only on launch-critical work. Use this to steer conversations away from noise.',
            style: TextStyle(
                fontSize: 13, color: const Color(0xFF6B7280), height: 1.4),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Iteration rhythm',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827)),
              ),
              _buildOutlineBadge('10-day cadence'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Keep a lightweight but disciplined rhythm so that every iteration produces visible, reviewable progress.',
            style: TextStyle(
                fontSize: 13, color: const Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Burndown trend',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          _buildBurndownBar(),
          const SizedBox(height: 8),
          Text(
            'Slightly behind ideal line · 4 pts to pull into next sprint if risk remains.',
            style: TextStyle(fontSize: 12, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildRhythmBullet(
              'Align scope for the next sprint while there are still 3–4 days left in the current one.'),
          _buildRhythmBullet(
              'Reserve capacity every iteration for technical debt and stabilization work.'),
          _buildRhythmBullet(
              'Capture 3–5 key learnings in each retrospective and link them to concrete actions.'),
        ],
      ),
    );
  }

  Widget _buildBurndownBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.72,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildRhythmBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF6B7280),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF374151), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesAndRiskRow(BuildContext context, bool isMobile) {
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
    final milestones = [
      _MilestoneItem(title: 'Beta launch feature-complete', date: 'Mar 29'),
      _MilestoneItem(title: 'Security & compliance sign-off', date: 'Apr 05'),
      _MilestoneItem(title: 'Production readiness review', date: 'Apr 18'),
    ];

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
              _buildOutlineBadge('Next 30 days'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Anchor the team on the few milestones that really matter for this execution phase.',
            style: TextStyle(
                fontSize: 13, color: const Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          ...milestones.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827)),
                    ),
                    Text(
                      m.date,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDependencyRiskCard(BuildContext context) {
    final risks = [
      'Payments sandbox instability could delay end-to-end checkout testing by 3–5 days.',
      'Environment capacity upgrades must land before load-testing window opens.',
      'Design bandwidth is tight; agree on what can move to a later iteration.',
    ];

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
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Only track items that can move dates or compromise launch quality.',
            style: TextStyle(
                fontSize: 13, color: const Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          ...risks.map((r) => _buildRhythmBullet(r)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip('+ Log new iteration risk'),
              _buildActionChip('Link to vendor tracking'),
              _buildActionChip('Export iteration summary'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildOutlineBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
>>>>>>> 1ee471ae (Merge codebases)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
<<<<<<< HEAD
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: data.color),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildIterationTable() {
    final filteredTasks = _selectedFilters.contains('All')
        ? _tasks
        : _tasks.where((t) => _selectedFilters.contains(t.status)).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agile Iteration Table',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track user stories, assign roles, and manage sprint velocity.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          AgileIterationTableWidget(
            tasks: filteredTasks,
            availableRoles: _availableRoles,
            onUpdated: (task) {
              setState(() {
                final index = _tasks.indexWhere((t) => t.id == task.id);
                if (index != -1) {
                  _tasks[index] = task;
                } else {
                  _tasks.add(task);
                }
              });
            },
            onDeleted: (task) {
              setState(() {
                _tasks.removeWhere((t) => t.id == task.id);
              });
            },
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final userStoryController = TextEditingController();
    final taskDescriptionController = RichTextEditingController();
    final acceptanceCriteriaController = RichAutoBulletTextController();
    final iterationNotesController = RichTextEditingController();
    final userStoryFieldKey = GlobalKey();
    final assignedRoleFieldKey = GlobalKey();
    String selectedRole = '';
    int selectedStoryPoints = 1;
    String selectedPriority = 'Medium';
    String selectedStatus = 'To-Do';
    Map<String, String> validationErrors = const {};

    OutlineInputBorder fieldBorder(bool hasError) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VoiceTextField(
                    key: userStoryFieldKey,
                    controller: userStoryController,
                    onChanged: (_) {
                      if (!validationErrors.containsKey('user_story')) return;
                      setDialogState(() {
                        validationErrors =
                            Map<String, String>.from(validationErrors)
                              ..remove('user_story');
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'User Story/Task *',
                      errorText: validationErrors['user_story'],
                      border:
                          fieldBorder(validationErrors['user_story'] != null),
                      enabledBorder:
                          fieldBorder(validationErrors['user_story'] != null),
                      focusedBorder:
                          fieldBorder(validationErrors['user_story'] != null),
                      errorBorder: fieldBorder(true),
                      focusedErrorBorder: fieldBorder(true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: assignedRoleFieldKey,
                    value: _availableRoles.isEmpty
                        ? null
                        : (_availableRoles.contains(selectedRole)
                            ? selectedRole
                            : null),
                    decoration: InputDecoration(
                      labelText: 'Assigned Role *',
                      errorText: validationErrors['assigned_role'],
                      border: fieldBorder(
                          validationErrors['assigned_role'] != null),
                      enabledBorder: fieldBorder(
                          validationErrors['assigned_role'] != null),
                      focusedBorder: fieldBorder(
                          validationErrors['assigned_role'] != null),
                      errorBorder: fieldBorder(true),
                      focusedErrorBorder: fieldBorder(true),
                    ),
                    items: _availableRoles.map((role) {
                      return DropdownMenuItem<String>(
                          value: role, child: Text(role));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRole = value ?? '';
                        if (selectedRole.isNotEmpty) {
                          validationErrors =
                              Map<String, String>.from(validationErrors)
                                ..remove('assigned_role');
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedStoryPoints,
                    decoration:
                        const InputDecoration(labelText: 'Story Points *'),
                    items: const [1, 2, 3, 5, 8].map((points) {
                      return DropdownMenuItem<int>(
                          value: points, child: Text('$points'));
                    }).toList(),
                    onChanged: (value) => selectedStoryPoints = value ?? 1,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority *'),
                    items: const ['Critical', 'High', 'Medium', 'Low'].map((p) {
                      return DropdownMenuItem<String>(value: p, child: Text(p));
                    }).toList(),
                    onChanged: (value) => selectedPriority = value ?? 'Medium',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status *'),
                    items: const ['To-Do', 'In-Progress', 'Testing', 'Done']
                        .map((s) {
                      return DropdownMenuItem<String>(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (value) => selectedStatus = value ?? 'To-Do',
                  ),
                  const SizedBox(height: 12),
                  TextFormattingToolbar(controller: taskDescriptionController),
                  const SizedBox(height: 6),
                  VoiceTextField(
                    controller: taskDescriptionController,
                    decoration:
                        const InputDecoration(labelText: 'Task Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormattingToolbar(
                      controller: acceptanceCriteriaController),
                  const SizedBox(height: 6),
                  VoiceTextField(
                    controller: acceptanceCriteriaController,
                    decoration: const InputDecoration(
                        labelText: 'Acceptance Criteria (use "." bullets)'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormattingToolbar(controller: iterationNotesController),
                  const SizedBox(height: 6),
                  VoiceTextField(
                    controller: iterationNotesController,
                    decoration: const InputDecoration(
                        labelText: 'Iteration Notes (manual input only)'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final validation = FormValidationEngine.validateForm([
                    ValidationFieldRule(
                      id: 'user_story',
                      label: 'User Story/Task',
                      section: 'Task Details',
                      type: ValidationFieldType.text,
                      value: userStoryController.text,
                      fieldKey: userStoryFieldKey,
                    ),
                    ValidationFieldRule(
                      id: 'assigned_role',
                      label: 'Assigned Role',
                      section: 'Task Details',
                      type: ValidationFieldType.dropdown,
                      value: selectedRole,
                      fieldKey: assignedRoleFieldKey,
                    ),
                  ]);

                  if (!validation.isValid) {
                    setDialogState(() {
                      validationErrors = validation.errorByFieldId;
                    });
                    FormValidationEngine.showValidationSnackBar(
                      this.context,
                      validation,
                      intro:
                          'Please complete the required task fields before adding this task.',
                      backgroundColor: const Color(0xFFF59E0B),
                    );
                    return;
                  }

                  final newTask = AgileTask(
                    userStory: userStoryController.text,
                    assignedRole: selectedRole,
                    storyPoints: selectedStoryPoints,
                    priority: selectedPriority,
                    status: selectedStatus,
                    taskDescription: taskDescriptionController.text,
                    acceptanceCriteria: acceptanceCriteriaController.text,
                    iterationNotes: iterationNotesController.text,
                  );

                  setState(() {
                    _tasks.add(newTask);
                  });

                  final projectId = _projectId;
                  if (projectId != null) {
                    try {
                      await ExecutionPhaseService.saveAgileTasks(
                        projectId: projectId,
                        tasks: _tasks,
                      );
                    } catch (e) {
                      debugPrint('Error saving task: $e');
                    }
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
=======
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151)),
>>>>>>> 1ee471ae (Merge codebases)
      ),
    );
  }

  Widget _buildFooterNavigation(BuildContext context) {
<<<<<<< HEAD
    return LaunchPhaseNavigation(
      backLabel: 'Back: Detailed Design',
      nextLabel: 'Next: Scope Tracking Implementation',
      onBack: () => DetailedDesignScreen.open(context),
      onNext: () => ScopeTrackingImplementationScreen.open(context),
    );
  }

  Future<void> _exportPdf() async {
    final projectData = ProjectDataHelper.getData(context);
    await PdfExportHelper.exportScreenPdf(
      context: context,
      screenTitle: 'Agile Development Iterations',
      sections: [
        PdfSection.keyValue('Project Info', [
          {'Project Name': projectData.projectName ?? 'N/A'},
          {'Solution Title': projectData.solutionTitle ?? 'N/A'},
        ]),
        PdfSection.text('Notes', projectData.planningNotes['planning_agile_development_iterations_notes'] ?? 'No data recorded.'),
      ],
    );
  }
=======
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
>>>>>>> 1ee471ae (Merge codebases)
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.subtitle, this.color);

  final String label;
  final String value;
  final String subtitle;
  final Color color;
}
