import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';

class ProjectPlanLevel1ScheduleScreen extends StatefulWidget {
  const ProjectPlanLevel1ScheduleScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ProjectPlanLevel1ScheduleScreen()),
    );
  }

  @override
  State<ProjectPlanLevel1ScheduleScreen> createState() =>
      _Level1ScheduleScreenState();
}

class _Level1ScheduleScreenState
    extends State<ProjectPlanLevel1ScheduleScreen> {
  List<_L1Phase> _phases = [];
  List<_L1Milestone> _milestones = [];
  DateTime? _projectStart;
  DateTime? _projectEnd;
  DateTime? _baselineDate;
  String _methodology = 'Waterfall';
  bool _hasBaseline = false;
  List<_L1Phase> _baselinePhases = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final data = ProjectDataHelper.getData(context);

    _projectStart = _parseDate(data.frontEndPlanning.milestoneStartDate);
    _projectEnd = _parseDate(data.frontEndPlanning.milestoneEndDate);

    _methodology = data.planningNotes['planning_schedule_methodology']
                ?.trim()
                .isNotEmpty ==
            true
        ? data.planningNotes['planning_schedule_methodology']!
        : 'Waterfall';

    _hasBaseline = data.scheduleBaselineDate.trim().isNotEmpty;
    _baselineDate =
        _hasBaseline ? DateTime.tryParse(data.scheduleBaselineDate) : null;

    _phases = _derivePhases(data);
    _baselinePhases = _hasBaseline
        ? _derivePhasesFromActivities(
            data.scheduleBaselineActivities, data.wbsTree)
        : <_L1Phase>[];

    _milestones = data.keyMilestones
        .where((m) => m.name.trim().isNotEmpty)
        .map((m) => _L1Milestone(
              name: m.name.trim(),
              targetDate: _parseDate(m.dueDate),
              discipline: m.discipline.trim(),
              comments: m.comments.trim(),
            ))
        .toList();

    if (mounted) setState(() {});
  }

  List<_L1Phase> _derivePhases(ProjectDataModel data) {
    if (data.wbsTree.isEmpty) {
      return _buildFallbackPhases(data);
    }
    return _derivePhasesFromActivities(data.scheduleActivities, data.wbsTree);
  }

  List<_L1Phase> _derivePhasesFromActivities(
      List<ScheduleActivity> activities, List<WorkItem> wbsTree) {
    final wbsChildIds = <String, Set<String>>{};
    void collectDescendants(WorkItem node, Set<String> bucket) {
      bucket.add(node.id);
      if (node.title.trim().isNotEmpty) {
        final normalized = node.title.trim().toLowerCase();
        bucket.add(normalized);
      }
      for (final child in node.children) {
        collectDescendants(child, bucket);
      }
    }

    for (final root in wbsTree) {
      final ids = <String>{};
      collectDescendants(root, ids);
      wbsChildIds[root.id] = ids;
    }

    final phases = <_L1Phase>[];
    final usedActivities = <String>{};

    for (final root in wbsTree) {
      final title = root.title.trim().isEmpty
          ? 'Phase ${phases.length + 1}'
          : root.title.trim();
      final childIds = wbsChildIds[root.id] ?? <String>{};

      final matched = activities.where((a) {
        if (usedActivities.contains(a.id)) return false;
        if (childIds.contains(a.wbsId)) return true;
        if (childIds.contains(a.wbsId.toLowerCase())) return true;
        final actTitle = a.title.trim().toLowerCase();
        if (childIds.contains(actTitle)) return true;
        return false;
      }).toList();

      for (final a in matched) {
        usedActivities.add(a.id);
      }

      if (matched.isEmpty) {
        final fallbackStart = _projectStart ?? DateTime.now();
        final fallbackEnd =
            _projectEnd ?? fallbackStart.add(const Duration(days: 90));
        final totalDays = fallbackEnd.difference(fallbackStart).inDays;
        final phaseDuration = wbsTree.length > 1
            ? (totalDays / wbsTree.length).round()
            : totalDays;
        final offset = phases.length * phaseDuration;

        phases.add(_L1Phase(
          name: title,
          startDate: fallbackStart.add(Duration(days: offset)),
          endDate: fallbackStart.add(Duration(days: offset + phaseDuration)),
          progress: 0,
          activityCount: 0,
          status: 'Planned',
        ));
      } else {
        DateTime? minStart;
        DateTime? maxEnd;
        double totalProgress = 0;
        int completedCount = 0;

        for (final a in matched) {
          final start = _parseDate(a.startDate);
          final end = _parseDate(a.dueDate);
          if (start != null && (minStart == null || start.isBefore(minStart))) {
            minStart = start;
          }
          if (end != null && (maxEnd == null || end.isAfter(maxEnd))) {
            maxEnd = end;
          }
          totalProgress += a.progress;
          if (a.status.toLowerCase() == 'completed') completedCount++;
        }

        phases.add(_L1Phase(
          name: title,
          startDate: minStart ?? _projectStart ?? DateTime.now(),
          endDate: maxEnd ?? _projectEnd ?? DateTime.now(),
          progress: matched.isNotEmpty ? totalProgress / matched.length : 0,
          activityCount: matched.length,
          status: completedCount == matched.length && matched.isNotEmpty
              ? 'Complete'
              : matched.any((a) => a.status.toLowerCase() == 'in_progress')
                  ? 'In Progress'
                  : 'Planned',
        ));
      }
    }

    final orphanActivities =
        activities.where((a) => !usedActivities.contains(a.id)).toList();
    if (orphanActivities.isNotEmpty) {
      DateTime? minStart;
      DateTime? maxEnd;
      double totalProgress = 0;
      int completedCount = 0;

      for (final a in orphanActivities) {
        final start = _parseDate(a.startDate);
        final end = _parseDate(a.dueDate);
        if (start != null && (minStart == null || start.isBefore(minStart))) {
          minStart = start;
        }
        if (end != null && (maxEnd == null || end.isAfter(maxEnd))) {
          maxEnd = end;
        }
        totalProgress += a.progress;
        if (a.status.toLowerCase() == 'completed') completedCount++;
      }

      phases.add(_L1Phase(
        name: 'Other Activities',
        startDate: minStart ?? _projectStart ?? DateTime.now(),
        endDate: maxEnd ?? _projectEnd ?? DateTime.now(),
        progress: totalProgress / orphanActivities.length,
        activityCount: orphanActivities.length,
        status: completedCount == orphanActivities.length
            ? 'Complete'
            : orphanActivities
                    .any((a) => a.status.toLowerCase() == 'in_progress')
                ? 'In Progress'
                : 'Planned',
      ));
    }

    return phases;
  }

  List<_L1Phase> _buildFallbackPhases(ProjectDataModel data) {
    final start = _projectStart ?? DateTime.now();
    final end = _projectEnd ?? start.add(const Duration(days: 365));
    final totalDays = end.difference(start).inDays;

    const phaseNames = ['Initiation', 'Planning', 'Execution', 'Launch'];
    const phasePercents = [0.1, 0.3, 0.45, 0.15];

    var offset = 0;
    final phases = <_L1Phase>[];
    for (int i = 0; i < phaseNames.length; i++) {
      final duration = (totalDays * phasePercents[i]).round();
      phases.add(_L1Phase(
        name: phaseNames[i],
        startDate: start.add(Duration(days: offset)),
        endDate: start.add(Duration(days: offset + duration)),
        progress: 0,
        activityCount: 0,
        status: 'Planned',
      ));
      offset += duration;
    }
    return phases;
  }

  int get _totalDurationDays {
    if (_projectStart == null || _projectEnd == null) {
      if (_phases.isEmpty) return 0;
      final minStart = _phases
          .map((p) => p.startDate)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final maxEnd =
          _phases.map((p) => p.endDate).reduce((a, b) => a.isAfter(b) ? a : b);
      return maxEnd.difference(minStart).inDays;
    }
    return _projectEnd!.difference(_projectStart!).inDays;
  }

  String get _scheduleHealth {
    if (_phases.isEmpty) return 'No Data';
    final avgProgress =
        _phases.fold<double>(0, (sum, p) => sum + p.progress) / _phases.length;
    if (avgProgress >= 0.8) return 'On Track';
    if (avgProgress >= 0.5) return 'At Risk';
    return 'Behind';
  }

  Color get _healthColor {
    final health = _scheduleHealth;
    if (health == 'On Track') return const Color(0xFF10B981);
    if (health == 'At Risk') return const Color(0xFFF59E0B);
    if (health == 'Behind') return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 20.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Project Plan - Level 1 - Project Schedule'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopHeader(
                          title: 'Level 1 - Project Schedule',
                          onBack: () => PlanningPhaseNavigation.goToPrevious(
                              context, 'project_plan_level1_schedule'),
                          onForward: () => PlanningPhaseNavigation.goToNext(
                              context, 'project_plan_level1_schedule'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Map major phases, milestone timing, and governance checkpoints.',
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 20),
                        PlanningAiNotesCard(
                          title: 'Notes',
                          sectionLabel: 'Level 1 - Project Schedule',
                          noteKey: 'planning_project_plan_level1_notes',
                          checkpoint: 'project_plan_level1_schedule',
                          description:
                              'Capture plan assumptions, deadlines, and key constraints.',
                        ),
                        const SizedBox(height: 24),
                        _buildMetricsRow(),
                        const SizedBox(height: 24),
                        _buildGanttTimeline(),
                        const SizedBox(height: 24),
                        _buildPhaseSummaryTable(),
                        const SizedBox(height: 24),
                        _buildMilestonesSection(),
                        const SizedBox(height: 24),
                        LaunchPhaseNavigation(
                          backLabel: PlanningPhaseNavigation.backLabel(
                              'project_plan_level1_schedule'),
                          nextLabel: PlanningPhaseNavigation.nextLabel(
                              'project_plan_level1_schedule'),
                          onBack: () => PlanningPhaseNavigation.goToPrevious(
                              context, 'project_plan_level1_schedule'),
                          onNext: () => PlanningPhaseNavigation.goToNext(
                              context, 'project_plan_level1_schedule'),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  const Positioned(
                      right: 24,
                      bottom: 24,
                      child: KazAiChatBubble(positioned: false)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(
          label: 'Total Duration',
          value: _totalDurationDays > 0 ? '$_totalDurationDays days' : '--',
          accent: const Color(0xFF3B82F6),
          icon: Icons.schedule_outlined,
        ),
        _MetricCard(
          label: 'Phases',
          value: '${_phases.length}',
          accent: const Color(0xFF8B5CF6),
          icon: Icons.layers_outlined,
        ),
        _MetricCard(
          label: 'Milestones',
          value: '${_milestones.length}',
          accent: const Color(0xFFF59E0B),
          icon: Icons.flag_outlined,
        ),
        _MetricCard(
          label: 'Schedule Health',
          value: _scheduleHealth,
          accent: _healthColor,
          icon: Icons.assessment_outlined,
        ),
      ],
    );
  }

  Widget _buildGanttTimeline() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Phase Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _methodology,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              if (_hasBaseline && _baselineDate != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Baseline: ${_formatDate(_baselineDate!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (_projectStart != null)
                Text(
                  '${_formatDate(_projectStart!)} → ${_projectEnd != null ? _formatDate(_projectEnd!) : '—'}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _L1GanttChart(
            phases: _phases,
            baselinePhases: _baselinePhases,
            milestones: _milestones,
            projectStart: _projectStart,
            projectEnd: _projectEnd,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseSummaryTable() {
    if (_phases.isEmpty) {
      return const _SectionEmptyState(
        title: 'No phases defined yet',
        message: 'Create WBS items to see phase-level schedule breakdown.',
        icon: Icons.layers_outlined,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined,
                    size: 18, color: Color(0xFF6B7280)),
                const SizedBox(width: 8),
                const Text(
                  'Phase Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildPhaseTable(),
        ],
      ),
    );
  }

  Widget _buildPhaseTable() {
    const border = BorderSide(color: Color(0xFFE5E7EB));
    const headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF374151),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FixedColumnWidth(220),
          2: FixedColumnWidth(130),
          3: FixedColumnWidth(130),
          4: FixedColumnWidth(100),
          5: FixedColumnWidth(110),
          6: FixedColumnWidth(110),
          7: FixedColumnWidth(120),
        },
        border: const TableBorder(
          horizontalInside: border,
          verticalInside: border,
        ),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            children: [
              _headerCell('#', headerStyle),
              _headerCell('Phase', headerStyle),
              _headerCell('Start', headerStyle),
              _headerCell('End', headerStyle),
              _headerCell('Duration', headerStyle),
              _headerCell('Progress', headerStyle),
              _headerCell('Tasks', headerStyle),
              _headerCell('Status', headerStyle),
            ],
          ),
          ...List.generate(_phases.length, (index) {
            final phase = _phases[index];
            final duration = phase.endDate.difference(phase.startDate).inDays;
            final progressPct = (phase.progress * 100).round();
            final statusColor = _statusColor(phase.status);

            return TableRow(
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : const Color(0xFFFAFAFA),
              ),
              children: [
                _dataCell(Center(
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                )),
                _dataCell(Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(phase.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827))),
                )),
                _dataCell(Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(_formatDate(phase.startDate),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF374151))),
                )),
                _dataCell(Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(_formatDate(phase.endDate),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF374151))),
                )),
                _dataCell(Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text('${duration}d',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF374151))),
                )),
                _dataCell(Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: phase.progress.clamp(0, 1),
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progressPct >= 80
                                  ? const Color(0xFF10B981)
                                  : progressPct >= 50
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$progressPct%',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151))),
                    ],
                  ),
                )),
                _dataCell(Center(
                  child: Text('${phase.activityCount}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF374151))),
                )),
                _dataCell(Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      phase.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                )),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.flag_outlined,
                    size: 18, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                const Text(
                  'Key Milestones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_milestones.length} milestones',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _milestones.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No milestones defined. Add milestones in the FEP Milestone screen to see them here.',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic),
                  ),
                )
              : _buildMilestonesTable(),
        ],
      ),
    );
  }

  Widget _buildMilestonesTable() {
    const border = BorderSide(color: Color(0xFFE5E7EB));
    const headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF374151),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FixedColumnWidth(260),
          2: FixedColumnWidth(140),
          3: FixedColumnWidth(160),
          4: FixedColumnWidth(300),
        },
        border: const TableBorder(
          horizontalInside: border,
          verticalInside: border,
        ),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            children: [
              _headerCell('#', headerStyle),
              _headerCell('Milestone', headerStyle),
              _headerCell('Target Date', headerStyle),
              _headerCell('Discipline', headerStyle),
              _headerCell('Notes', headerStyle),
            ],
          ),
          ...List.generate(_milestones.length, (index) {
            final m = _milestones[index];
            return TableRow(
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : const Color(0xFFFAFAFA),
              ),
              children: [
                _dataCell(Center(
                  child: Icon(Icons.flag_outlined,
                      size: 16, color: const Color(0xFFF59E0B)),
                )),
                _dataCell(Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(m.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827))),
                )),
                _dataCell(Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    m.targetDate != null ? _formatDate(m.targetDate!) : '—',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                  ),
                )),
                _dataCell(Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      m.discipline.isEmpty ? 'General' : m.discipline,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                )),
                _dataCell(Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    m.comments.isEmpty ? '—' : m.comments,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280), height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(text, style: style),
    );
  }

  Widget _dataCell(Widget child) {
    return child;
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('complete')) return const Color(0xFF10B981);
    if (s.contains('progress')) return const Color(0xFF3B82F6);
    if (s.contains('risk') || s.contains('behind')) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF6B7280);
  }

  DateTime? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    final parts = value.split(RegExp(r'[\s,]+'));
    if (parts.length >= 3) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final monthIdx =
          months.indexWhere((m) => parts[0].toLowerCase() == m.toLowerCase());
      if (monthIdx != -1) {
        final day = int.tryParse(parts[1]) ?? 1;
        final year = int.tryParse(parts[2]) ?? DateTime.now().year;
        return DateTime(year, monthIdx + 1, day);
      }
    }
    return null;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _L1Phase {
  const _L1Phase({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.activityCount,
    required this.status,
  });

  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double progress;
  final int activityCount;
  final String status;
}

class _L1Milestone {
  const _L1Milestone({
    required this.name,
    required this.targetDate,
    required this.discipline,
    required this.comments,
  });

  final String name;
  final DateTime? targetDate;
  final String discipline;
  final String comments;
}

class _L1GanttChart extends StatelessWidget {
  const _L1GanttChart({
    required this.phases,
    required this.baselinePhases,
    required this.milestones,
    required this.projectStart,
    required this.projectEnd,
  });

  final List<_L1Phase> phases;
  final List<_L1Phase> baselinePhases;
  final List<_L1Milestone> milestones;
  final DateTime? projectStart;
  final DateTime? projectEnd;

  static const double _leftColumnWidth = 180;
  static const double _rowHeight = 48;
  static const double _milestoneRowHeight = 32;

  @override
  Widget build(BuildContext context) {
    if (phases.isEmpty && milestones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.timeline_outlined, size: 40, color: Color(0xFF9CA3AF)),
              SizedBox(height: 12),
              Text(
                'No timeline data yet. Add WBS items and milestones to populate.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      );
    }

    DateTime start;
    DateTime end;

    if (projectStart != null && projectEnd != null) {
      start = projectStart!;
      end = projectEnd!;
    } else if (phases.isNotEmpty) {
      start = phases.first.startDate;
      end = phases.last.endDate;
      for (final p in phases) {
        if (p.startDate.isBefore(start)) start = p.startDate;
        if (p.endDate.isAfter(end)) end = p.endDate;
      }
    } else {
      start = DateTime.now();
      end = start.add(const Duration(days: 90));
    }

    for (final m in milestones) {
      if (m.targetDate != null) {
        if (m.targetDate!.isBefore(start)) start = m.targetDate!;
        if (m.targetDate!.isAfter(end)) end = m.targetDate!;
      }
    }

    final buffer = (end.difference(start).inDays * 0.03).round().clamp(3, 14);
    start = start.subtract(Duration(days: buffer));
    end = end.add(Duration(days: buffer));

    final totalDays = end.difference(start).inDays + 1;
    final timelineWidth = (totalDays * 3.0).clamp(600.0, 2400.0);
    final pxPerDay = timelineWidth / totalDays;
    final totalRows = phases.length + (milestones.isNotEmpty ? 1 : 0);
    final chartHeight = totalRows * _rowHeight + 20;
    final totalChartWidth = _leftColumnWidth + timelineWidth + 2;
    final monthSegments = _generateMonthSegments(start, end);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: totalChartWidth,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: _leftColumnWidth,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Phase',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: timelineWidth,
                    height: 18,
                    child: Row(
                      children: monthSegments.map((segment) {
                        final segmentWidth = segment.dayCount * pxPerDay;
                        return SizedBox(
                          width: segmentWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                segment.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: chartHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _L1GridPainter(
                        leftColumnWidth: _leftColumnWidth,
                        rowHeight: _rowHeight,
                        rowCount: totalRows,
                        monthSegments: monthSegments,
                        pxPerDay: pxPerDay,
                      ),
                    ),
                  ),
                  ...List.generate(phases.length, (index) {
                    final phase = phases[index];
                    final top = index * _rowHeight + 4;
                    final startOffset =
                        phase.startDate.difference(start).inDays;
                    final duration =
                        phase.endDate.difference(phase.startDate).inDays + 1;
                    final left = _leftColumnWidth + startOffset * pxPerDay;
                    final width = (duration * pxPerDay).clamp(24.0, 800.0);

                    _L1Phase? baselinePhase;
                    if (baselinePhases.isNotEmpty) {
                      for (final bp in baselinePhases) {
                        if (bp.name == phase.name ||
                            bp.name.toLowerCase() == phase.name.toLowerCase()) {
                          baselinePhase = bp;
                          break;
                        }
                      }
                    }

                    return Positioned(
                      left: 0,
                      right: 0,
                      top: top,
                      height: _rowHeight - 6,
                      child: Row(
                        children: [
                          SizedBox(
                            width: _leftColumnWidth,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                phase.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (baselinePhase != null) ...[
                                  Positioned(
                                    left: baselinePhase.startDate
                                            .difference(start)
                                            .inDays *
                                        pxPerDay,
                                    top: 10,
                                    child: Container(
                                      height: _rowHeight - 26,
                                      width: (baselinePhase.endDate
                                                  .difference(
                                                      baselinePhase.startDate)
                                                  .inDays +
                                              1) *
                                          pxPerDay,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E7EB)
                                            .withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFD1D5DB),
                                          width: 1,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                Positioned(
                                  left: left - _leftColumnWidth,
                                  top: 4,
                                  child: Container(
                                    height: _rowHeight - 16,
                                    width: width,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: _phaseColor(index),
                                            ),
                                          ),
                                          if (phase.progress > 0)
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: FractionallySizedBox(
                                                widthFactor:
                                                    phase.progress.clamp(0, 1),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: _phaseColor(index)
                                                        .withValues(
                                                            alpha: 0.85),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Center(
                                            child: Text(
                                              '${(phase.progress * 100).round()}%',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (milestones.isNotEmpty)
                    ..._buildMilestoneMarkers(start, pxPerDay, phases.length),
                ],
              ),
            ),
            if (_hasBaselinePhases())
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Baseline',
                      style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 20,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Current',
                      style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.diamond,
                        size: 12, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    const Text(
                      'Milestone',
                      style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasBaselinePhases() => baselinePhases.isNotEmpty;

  List<Widget> _buildMilestoneMarkers(
      DateTime start, double pxPerDay, int phaseCount) {
    final topOffset = phaseCount * _rowHeight + 4;

    return [
      Positioned(
        left: 0,
        right: 0,
        top: topOffset,
        height: _milestoneRowHeight,
        child: Row(
          children: [
            SizedBox(
              width: _leftColumnWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Milestones',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: milestones.map((m) {
                  if (m.targetDate == null) return const SizedBox.shrink();
                  final offset =
                      m.targetDate!.difference(start).inDays * pxPerDay;
                  return Positioned(
                    left: offset - 6,
                    top: 6,
                    child: Tooltip(
                      message:
                          '${m.name}${m.targetDate != null ? ' — ${_fmtDate(m.targetDate!)}' : ''}',
                      child: CustomPaint(
                        size: const Size(12, 12),
                        painter: _DiamondPainter(
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Color _phaseColor(int index) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
      Color(0xFFEC4899),
      Color(0xFF6366F1),
    ];
    return colors[index % colors.length];
  }

  String _fmtDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _L1TimelineSegment {
  const _L1TimelineSegment({required this.label, required this.dayCount});
  final String label;
  final int dayCount;
}

List<_L1TimelineSegment> _generateMonthSegments(DateTime start, DateTime end) {
  final segments = <_L1TimelineSegment>[];
  final inclusiveEnd = DateTime(end.year, end.month, end.day);
  DateTime cursor = DateTime(start.year, start.month, 1);

  while (!cursor.isAfter(inclusiveEnd)) {
    final bucketStart = cursor.isBefore(start) ? start : cursor;
    final nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
    final bucketEnd = nextMonth.subtract(const Duration(days: 1));
    final actualEnd =
        bucketEnd.isAfter(inclusiveEnd) ? inclusiveEnd : bucketEnd;
    final dayCount = actualEnd.difference(bucketStart).inDays + 1;

    segments.add(_L1TimelineSegment(
      label: _fmtMonth(cursor),
      dayCount: dayCount,
    ));
    cursor = nextMonth;
  }

  return segments;
}

String _fmtMonth(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${months[date.month - 1]} ${date.year}';
}

class _L1GridPainter extends CustomPainter {
  const _L1GridPainter({
    required this.leftColumnWidth,
    required this.rowHeight,
    required this.rowCount,
    required this.monthSegments,
    required this.pxPerDay,
  });

  final double leftColumnWidth;
  final double rowHeight;
  final int rowCount;
  final List<_L1TimelineSegment> monthSegments;
  final double pxPerDay;

  @override
  void paint(Canvas canvas, Size size) {
    final rowPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 0.5;

    for (int row = 0; row <= rowCount; row++) {
      final y = row * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rowPaint);
    }

    final dividerPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1;

    double x = leftColumnWidth;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), dividerPaint);
    for (final segment in monthSegments) {
      x += segment.dayCount * pxPerDay;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), dividerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _L1GridPainter oldDelegate) => false;
}

class _DiamondPainter extends CustomPainter {
  const _DiamondPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DiamondPainter oldDelegate) =>
      color != oldDelegate.color;
}

class ProjectPlanDetailedScheduleScreen extends StatelessWidget {
  const ProjectPlanDetailedScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProjectPlanSectionScreen(
      config: _ProjectPlanSectionConfig(
        title: 'Detailed Project Schedule',
        subtitle: 'Track task-level sequencing, owners, and resource loading.',
        noteKey: 'planning_project_plan_detailed_notes',
        checkpoint: 'project_plan_detailed_schedule',
        activeItemLabel: 'Project Plan - Detailed Project Schedule',
        metrics: const [],
        sections: const [],
      ),
    );
  }
}

class ProjectPlanCondensedSummaryScreen extends StatelessWidget {
  const ProjectPlanCondensedSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProjectPlanSectionScreen(
      config: _ProjectPlanSectionConfig(
        title: 'Condensed Project Summary',
        subtitle: 'A concise executive view of schedule, cost, and readiness.',
        noteKey: 'planning_project_plan_condensed_notes',
        checkpoint: 'project_plan_condensed_summary',
        activeItemLabel: 'Project Plan - Condensed Project Summary',
        metrics: const [],
        sections: const [],
      ),
    );
  }
}

class _ProjectPlanSectionScreen extends StatelessWidget {
  const _ProjectPlanSectionScreen({required this.config});

  final _ProjectPlanSectionConfig config;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 20.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: InitiationLikeSidebar(
                  activeItemLabel: config.activeItemLabel),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        const gap = 24.0;
                        final twoCol = width >= 980;
                        final halfWidth = twoCol ? (width - gap) / 2 : width;
                        final hasContent = config.metrics.isNotEmpty ||
                            config.sections.isNotEmpty;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(
                              title: config.title,
                              onBack: () =>
                                  PlanningPhaseNavigation.goToPrevious(
                                      context, config.checkpoint),
                              onForward: () => PlanningPhaseNavigation.goToNext(
                                  context, config.checkpoint),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              config.subtitle,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            PlanningAiNotesCard(
                              title: 'Notes',
                              sectionLabel: config.title,
                              noteKey: config.noteKey,
                              checkpoint: config.checkpoint,
                              description:
                                  'Capture plan assumptions, deadlines, and key constraints.',
                            ),
                            const SizedBox(height: 24),
                            if (hasContent) ...[
                              _MetricsRow(metrics: config.metrics),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: config.sections
                                    .map((section) => SizedBox(
                                        width: halfWidth,
                                        child: _SectionCard(data: section)))
                                    .toList(),
                              ),
                            ] else
                              const _SectionEmptyState(
                                title: 'No schedule details yet',
                                message:
                                    'Add schedule insights to populate this view.',
                                icon: Icons.calendar_today_outlined,
                              ),
                            const SizedBox(height: 24),
                            LaunchPhaseNavigation(
                              backLabel: PlanningPhaseNavigation.backLabel(
                                  config.checkpoint),
                              nextLabel: PlanningPhaseNavigation.nextLabel(
                                  config.checkpoint),
                              onBack: () =>
                                  PlanningPhaseNavigation.goToPrevious(
                                      context, config.checkpoint),
                              onNext: () => PlanningPhaseNavigation.goToNext(
                                  context, config.checkpoint),
                            ),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
                    ),
                  ),
                  const Positioned(
                      right: 24,
                      bottom: 24,
                      child: KazAiChatBubble(positioned: false)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectPlanSectionConfig {
  const _ProjectPlanSectionConfig({
    required this.title,
    required this.subtitle,
    required this.noteKey,
    required this.checkpoint,
    required this.activeItemLabel,
    required this.metrics,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final String noteKey;
  final String checkpoint;
  final String activeItemLabel;
  final List<_MetricData> metrics;
  final List<_SectionData> sections;
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.title,
    required this.onBack,
    required this.onForward,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        _CircleIconButton(
            icon: Icons.arrow_forward_ios_rounded, onTap: onForward),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        const Spacer(),
        const _UserChip(),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final email = user?.email ?? '';

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final role = isAdmin ? 'Admin' : 'Member';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151)),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(displayName,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(role,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF6B7280))),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: Color(0xFF9CA3AF)),
            ],
          ),
        );
      },
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: metrics
          .map((metric) => _MetricCard(
              label: metric.label, value: metric.value, accent: metric.color))
          .toList(),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
    this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: accent),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: accent),
          ),
        ],
      ),
    );
  }
}

class _SectionData {
  const _SectionData({
    required this.title,
    required this.subtitle,
  })  : bullets = const [],
        statusRows = const [];

  final String title;
  final String subtitle;
  final List<_BulletData> bullets;
  final List<_StatusRowData> statusRows;
}

class _BulletData {
  const _BulletData(this.text, this.isCheck);

  final String text;
  final bool isCheck;
}

class _StatusRowData {
  const _StatusRowData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.data});

  final _SectionData data;

  @override
  Widget build(BuildContext context) {
    final showBullets = data.bullets.isNotEmpty;
    final showStatus = data.statusRows.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(data.subtitle,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
          const SizedBox(height: 16),
          if (showBullets)
            ...data.bullets.map((bullet) => _BulletRow(data: bullet)),
          if (showStatus)
            ...data.statusRows.map((row) => _StatusRow(data: row)),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.data});

  final _BulletData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            data.isCheck ? Icons.check_circle_outline : Icons.circle,
            size: data.isCheck ? 16 : 8,
            color: data.isCheck
                ? const Color(0xFF10B981)
                : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.text,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF374151), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.data});

  final _StatusRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              data.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              data.value,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: data.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState(
      {required this.title, required this.message, required this.icon});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text(message,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
