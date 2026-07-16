import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/feature_model.dart';
import 'package:ndu_project/models/roadmap_sprint.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/epic_feature_service.dart';
import 'package:ndu_project/services/roadmap_service.dart';
import 'package:ndu_project/services/agile_wireframe_service.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_data_table.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/text_formatting_toolbar.dart';

import 'package:ndu_project/widgets/voice_text_field.dart';
import 'package:ndu_project/utils/pdf_export_helper.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
const Color _kBackground = Colors.white;
const Color _kBorder = Color(0xFFE5E7EB);
const Color _kMuted = Color(0xFF6B7280);
const Color _kHeadline = Color(0xFF111827);
const Color _kAccent = Color(0xFFD97706);

class AgileSprintCalendarScreen extends StatefulWidget {
 const AgileSprintCalendarScreen({super.key});

 @override
 State<AgileSprintCalendarScreen> createState() =>
 _AgileSprintCalendarScreenState();
}

class _AgileSprintCalendarScreenState
    extends State<AgileSprintCalendarScreen> {
  List<RoadmapSprint> _sprints = [];
  List<Feature> _features = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  TextEditingController _ceremonyController = TextEditingController();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _saveDebounce;

 final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

 List<RoadmapSprint> get _filteredSprints {
 if (_searchQuery.isEmpty) return _sprints;
 final q = _searchQuery.toLowerCase();
 return _sprints.where((s) =>
 s.name.toLowerCase().contains(q) ||
 s.goal.toLowerCase().contains(q)
 ).toList();
 }

 String? get _projectId {
 try {
 return ProjectDataInherited.maybeOf(context)?.projectData.projectId;
 } catch (e) {
 return null;
 }
 }

 @override
 void initState() {
 super.initState();
 WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
 }

 @override
 void dispose() {
 _saveDebounce?.cancel();
 _ceremonyController.dispose();
 _searchController.dispose();
 super.dispose();
 }

  Future<void> _loadData() async {
    final pid = _projectId;
    if (pid == null) return;
    setState(() => _isLoading = true);
    try {
      final sprints = await RoadmapService.loadSprints(projectId: pid);
      final calendarData =
          await AgileWireframeService.loadSprintCalendar(pid);
      final features = await EpicFeatureService.loadAllFeatures(pid);
      if (!mounted) return;
      _ceremonyController.dispose();
      _ceremonyController = TextEditingController(
          text: calendarData['ceremonies'] as String? ?? '');
      setState(() {
        _sprints = sprints;
        _features = features;
        _isLoading = false;
      });
      // ── Auto-populate ceremony schedule from AI when empty ────────
      if (_ceremonyController.text.trim().isEmpty && !_isGenerating) {
        _generateCeremonies();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateCeremonies() async {
  setState(() => _isGenerating = true);
  try {
  final projectData = ProjectDataHelper.getData(context);
  final contextText = ProjectDataHelper.buildProjectContextScan(
  projectData,
  sectionLabel: 'Sprint Ceremonies',
  );
  final openai = OpenAiServiceSecure();
  final result = await openai.generateCompletion(
  'Based on this project context, suggest a sprint ceremony schedule.\n\n'
  'Context:\n$contextText\n\n'
  'Include: Sprint Planning, Daily Standup, Sprint Review, and Sprint Retrospective '
  'with suggested days and times. Return ONLY the text (no JSON, no markdown headers).',
  maxTokens: 200,
  temperature: 0.5,
  );
  final cleaned = result.trim();
  if (cleaned.isNotEmpty && mounted) {
  _ceremonyController.text = cleaned;
  _saveCeremonies();
  }
  } catch (e) {
  debugPrint('Ceremony generation error: $e');
  }
  if (mounted) setState(() => _isGenerating = false);
  }

  Future<void> _generateCeremonySchedule() async {
  final pid = _projectId;
  if (pid == null || _sprints.isEmpty) return;
  setState(() => _isGenerating = true);
  try {
  final scrumConfig = await AgileWireframeService.loadScrumConfig(pid);

  final sprintPlanningDur = scrumConfig['planning_duration'] as String? ?? '2 hrs';
  final dailyScrumTime = scrumConfig['daily_scrum_time'] as String? ?? '09:00';
  final dailyScrumDur = scrumConfig['daily_scrum_duration'] as String? ?? '15 min';
  final reviewDur = scrumConfig['review_duration'] as String? ?? '1 hr';
  final retroDur = scrumConfig['retro_duration'] as String? ?? '1 hr';
  final refinementDur = scrumConfig['refinement_duration'] as String? ?? '1 hr';

  final buffer = StringBuffer();
  final df = DateFormat('EEE MMM dd');

  for (final sprint in _sprints) {
  final startLabel = sprint.startDate != null ? df.format(sprint.startDate!) : 'TBD';
  final endLabel = sprint.endDate != null ? df.format(sprint.endDate!) : 'TBD';

  buffer.writeln('Sprint ${sprint.order}: ${sprint.name.isNotEmpty ? sprint.name : ''}');
  buffer.writeln('  $startLabel – $endLabel');

  // Sprint Planning — first day
  if (sprint.startDate != null) {
  final dayName = DateFormat('EEEE').format(sprint.startDate!);
  buffer.writeln('  Sprint Planning ($dayName @ $dailyScrumTime, $sprintPlanningDur)');
  }

  // Daily Standup — every day
  if (sprint.startDate != null && sprint.endDate != null) {
  final dayCount = sprint.endDate!.difference(sprint.startDate!).inDays + 1;
  buffer.writeln('  Daily Standup ($dailyScrumTime daily, $dailyScrumDur, $dayCount sessions)');
  }

  // Sprint Review — last day
  if (sprint.endDate != null) {
  final reviewDay = DateFormat('EEEE').format(sprint.endDate!);
  buffer.writeln('  Sprint Review ($reviewDay @ $dailyScrumTime, $reviewDur)');
  }

  // Sprint Retro — last day after review
  if (sprint.endDate != null) {
  final retroDay = DateFormat('EEEE').format(sprint.endDate!);
  buffer.writeln('  Sprint Retrospective ($retroDay after Review, $retroDur)');
  }

  // Backlog Refinement — mid-sprint
  if (sprint.startDate != null) {
  final midPoint = sprint.startDate!.add(
  Duration(days: sprint.endDate != null
  ? (sprint.endDate!.difference(sprint.startDate!).inDays ~/ 2)
  : 7));
  final refineDay = DateFormat('EEEE').format(midPoint);
  buffer.writeln('  Backlog Refinement ($refineDay @ $dailyScrumTime, $refinementDur)');
  }

  buffer.writeln('');
  }

  if (mounted) {
  _ceremonyController.text = buffer.toString().trim();
  _saveCeremonies();
  }
  } catch (e) {
  debugPrint('Ceremony schedule generation error: $e');
  }
  if (mounted) setState(() => _isGenerating = false);
  }

 Future<void> _saveCeremonies() async {
 final pid = _projectId;
 if (pid == null) return;
 await AgileWireframeService.saveSprintCalendar(
 projectId: pid,
 data: {'ceremonies': _ceremonyController.text},
 );
 }

 void _addSprint() {
 showDialog(
 context: context,
 builder: (ctx) => _SprintEditDialog(
 onSave: (sprint) {
 final pid = _projectId;
 if (pid == null) return;
 final updatedList = [..._sprints, sprint];
 RoadmapService.saveSprints(projectId: pid, sprints: updatedList);
 setState(() => _sprints = updatedList);
 },
 ),
 );
 }

 void _editSprint(int index) {
 final sprint = _sprints[index];
 showDialog(
 context: context,
 builder: (ctx) => _SprintEditDialog(
 existing: sprint,
 onSave: (updated) {
 final pid = _projectId;
 if (pid == null) return;
 final updatedList = [..._sprints];
 updatedList[index] = updated;
 RoadmapService.saveSprints(projectId: pid, sprints: updatedList);
 setState(() => _sprints = updatedList);
 },
 ),
 );
 }

  Future<void> _deleteSprint(int index) async {
    final confirmed = await launchConfirmDelete(context, itemName: 'sprint');
    if (!confirmed || !mounted) return;
    final pid = _projectId;
    if (pid == null) return;
    final sprintId = _sprints[index].id;
    final updatedList = [..._sprints];
    updatedList.removeAt(index);
    await RoadmapService.saveSprints(projectId: pid, sprints: updatedList);
    // Unassign features from deleted sprint
    for (final f in _features.where((f) => f.sprintId == sprintId)) {
      await EpicFeatureService.assignFeatureToSprint(
        projectId: pid,
        feature: f,
        sprintId: null,
      );
    }
    setState(() => _sprints = updatedList);
  }

  Future<void> _openAssignFeatures(String sprintId, String sprintName) async {
    final pid = _projectId;
    if (pid == null) return;

    final unassigned =
        _features.where((f) => f.sprintId == null || f.sprintId!.isEmpty).toList();
    final assigned = _features.where((f) => f.sprintId == sprintId).toList();

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => _AssignFeaturesDialog(
        sprintName: sprintName,
        unassigned: unassigned,
        assigned: assigned,
        onAssign: (feature) async {
          await EpicFeatureService.assignFeatureToSprint(
            projectId: pid,
            feature: feature,
            sprintId: sprintId,
          );
          setState(() {});
        },
        onUnassign: (feature) async {
          await EpicFeatureService.assignFeatureToSprint(
            projectId: pid,
            feature: feature,
            sprintId: null,
          );
          setState(() {});
        },
      ),
    );
  }

 @override
 Widget build(BuildContext context) {
 final bool isMobile = AppBreakpoints.isMobile(context);
 final double hp = isMobile ? 20 : 40;

 return Scaffold(
 backgroundColor: _kBackground,
 body: SafeArea(
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 DraggableSidebar(
 openWidth: AppBreakpoints.sidebarWidth(context),
 child: const InitiationLikeSidebar(
 activeItemLabel: 'Agile Delivery Model - Sprint Calendar'),
 ),
 Expanded(
 child: SingleChildScrollView(
 padding: EdgeInsets.symmetric(horizontal: hp, vertical: 32),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 PlanningPhaseHeader(
 title: 'Sprint Cadence & Calendar',
 onBack: () => PlanningPhaseNavigation.goToPrevious(
 context, 'agile_sprint_calendar'),
 onForward: () => PlanningPhaseNavigation.goToNext(
 context, 'agile_sprint_calendar'), onExportPdf: _exportPdf),
 const SizedBox(height: 32),
 Text('Define sprint duration, dates, and ceremony schedule.',
 style: TextStyle(fontSize: 15, color: _kMuted)),
 const SizedBox(height: 24),
 if (_isLoading)
 const Center(child: CircularProgressIndicator())
 else ...[
 VoiceTextField(
 controller: _searchController,
 decoration: InputDecoration(
 hintText: 'Search sprints...',
 prefixIcon: const Icon(Icons.search, size: 20),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(10)),
 isDense: true,
 contentPadding: const EdgeInsets.symmetric(vertical: 10),
 ),
 onChanged: (v) => setState(() => _searchQuery = v),
 ),
 const SizedBox(height: 16),
 if (_filteredSprints.isEmpty)
 _buildEmptyState(
 _searchQuery.isNotEmpty
 ? 'No sprints match "$_searchQuery".'
 : 'No sprints defined. Create your first sprint.')
 else
 ..._filteredSprints.asMap().entries.map((e) =>
 _buildSprintCard(e.key, e.value)),
 const SizedBox(height: 16),
 OutlinedButton.icon(
 onPressed: _addSprint,
 icon: const Icon(Icons.add, size: 18),
 label: const Text('Add Sprint'),
 style: OutlinedButton.styleFrom(
 foregroundColor: _kAccent,
 side: const BorderSide(color: _kAccent),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(8)),
 ),
 ),
 const SizedBox(height: 32),
 const Text('Ceremony Schedule',
 style: TextStyle(
 fontSize: 16,
 fontWeight: FontWeight.w600,
 color: _kHeadline)),
 const SizedBox(height: 8),
 const SizedBox(height: 4),
 VoiceTextField(
 controller: _ceremonyController,
 decoration: InputDecoration(
 hintText:
 'e.g. Sprint Planning (Mon 9-11am), Daily Standup (9:15am), Review (Fri 3-4pm), Retro (Fri 4-5pm)',
 border: const OutlineInputBorder(),
 suffixIcon: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
  IconButton(
  tooltip: 'Generate schedule from sprint dates + config',
  icon: _isGenerating
  ? const SizedBox(
  width: 16,
  height: 16,
  child: CircularProgressIndicator(
  strokeWidth: 2),
  )
  : const Icon(Icons.schedule,
  color: Color(0xFF059669), size: 18),
  onPressed: _isGenerating
  ? null
  : _generateCeremonySchedule,
  padding: const EdgeInsets.all(4),
  constraints: const BoxConstraints(
  minWidth: 32, minHeight: 32),
  ),
  IconButton(
  tooltip: 'KAZ AI',
  icon: _isGenerating
  ? const SizedBox(
  width: 16,
  height: 16,
  child: CircularProgressIndicator(
  strokeWidth: 2),
  )
  : const Icon(Icons.auto_awesome,
  color: Color(0xFFF59E0B), size: 18),
  onPressed: _isGenerating
  ? null
  : _generateCeremonies,
  padding: const EdgeInsets.all(4),
  constraints: const BoxConstraints(
  minWidth: 32, minHeight: 32),
  ),
 if (_ceremonyController.text.isNotEmpty)
 IconButton(
 tooltip: 'Clear all content',
 icon: const Icon(Icons.delete_sweep,
 color: Color(0xFFEF4444), size: 18),
 onPressed: () {
 _ceremonyController.clear();
 _saveCeremonies();
 setState(() {});
 },
 padding: const EdgeInsets.all(4),
 constraints: const BoxConstraints(
 minWidth: 32, minHeight: 32),
 ),
 ],
 ),
 ),
 maxLines: 4,
 onChanged: (_) {
 _saveDebounce?.cancel();
 _saveDebounce = Timer(
 const Duration(milliseconds: 500),
 _saveCeremonies);
 setState(() {});
 },
 ),
 ],
 const SizedBox(height: 24),
 LaunchPhaseNavigation(
 backLabel: PlanningPhaseNavigation.backLabel(
 'agile_sprint_calendar'),
 nextLabel: PlanningPhaseNavigation.nextLabel(
 'agile_sprint_calendar'),
 onBack: () => PlanningPhaseNavigation.goToPrevious(
 context, 'agile_sprint_calendar'),
 onNext: () => PlanningPhaseNavigation.goToNext(
 context, 'agile_sprint_calendar'),
 ),
 const SizedBox(height: 48),
 ],
 ),
 ),
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildSprintCard(int index, RoadmapSprint sprint) {
 final startStr =
 sprint.startDate != null ? _dateFormat.format(sprint.startDate!) : 'TBD';
 final endStr =
 sprint.endDate != null ? _dateFormat.format(sprint.endDate!) : 'TBD';
 final assignedFeatures = _features.where((f) => f.sprintId == sprint.id).toList();

 return Column(
 children: [
 Card(
 margin: const EdgeInsets.only(bottom: 4),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(10),
 side: const BorderSide(color: _kBorder),
 ),
 child: Padding(
 padding: const EdgeInsets.all(14),
 child: Row(
 children: [
 Container(
 width: 36,
 height: 36,
 decoration: BoxDecoration(
 color: _kAccent.withOpacity(0.1),
 borderRadius: BorderRadius.circular(8),
 ),
 child: Center(
 child: Text('${sprint.order}',
 style: const TextStyle(
 fontWeight: FontWeight.w700, color: _kAccent)),
 ),
 ),
 const SizedBox(width: 14),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(sprint.name.isNotEmpty ? sprint.name : 'Sprint ${sprint.order}',
 style: const TextStyle(
 fontWeight: FontWeight.w600, fontSize: 14)),
 const SizedBox(height: 2),
 Text('$startStr – $endStr',
 style: TextStyle(fontSize: 12, color: _kMuted)),
 if (sprint.goal.isNotEmpty)
 Padding(
 padding: const EdgeInsets.only(top: 2),
 child: Text(sprint.goal,
 style: TextStyle(fontSize: 12, color: _kMuted),
 maxLines: 1,
 overflow: TextOverflow.ellipsis),
 ),
 if (assignedFeatures.isNotEmpty)
 Padding(
 padding: const EdgeInsets.only(top: 6),
 child: Text(
 '${assignedFeatures.length} feature${assignedFeatures.length == 1 ? '' : 's'} · '
 '${assignedFeatures.fold<double>(0, (sum, f) => sum + f.storyPointEstimate).toStringAsFixed(0)} pts',
 style: TextStyle(fontSize: 11, color: _kAccent),
 ),
 ),
 ],
 ),
 ),
 PopupMenuButton<String>(
 onSelected: (v) {
 if (v == 'edit') _editSprint(index);
 if (v == 'assign') _openAssignFeatures(sprint.id, sprint.name);
 if (v == 'delete') _deleteSprint(index);
 },
 itemBuilder: (_) => [
 const PopupMenuItem(value: 'edit', child: Text('Edit')),
 const PopupMenuItem(
 value: 'assign',
 child: Text('Assign Features')),
 const PopupMenuItem(
 value: 'delete',
 child: Text('Delete', style: TextStyle(color: Colors.red))),
 ],
 ),
 ],
 ),
 ),
 ),
 if (assignedFeatures.isNotEmpty)
 Container(
 margin: const EdgeInsets.only(left: 50, bottom: 8),
 padding: const EdgeInsets.all(10),
 decoration: BoxDecoration(
 color: Colors.grey.shade50,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: _kBorder),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: assignedFeatures.map((f) {
 return Padding(
 padding: const EdgeInsets.only(bottom: 4),
 child: Row(
 children: [
 Container(
 width: 10,
 height: 10,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: _featureStatusColor(f.status),
 ),
 ),
 const SizedBox(width: 8),
 Expanded(
 child: Text(
 f.title.isNotEmpty ? f.title : '(untitled)',
 style: const TextStyle(fontSize: 12),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 Text(
 '${f.storyPointEstimate.toStringAsFixed(0)} pts',
 style: TextStyle(fontSize: 11, color: _kMuted),
 ),
 ],
 ),
 );
 }).toList(),
 ),
 ),
 ],
 );
 }

 Color _featureStatusColor(String status) {
 switch (status) {
 case 'active': return Colors.blue;
 case 'complete': return Colors.green;
 case 'cancelled': return Colors.red;
 default: return Colors.grey;
 }
 }

 Widget _buildEmptyState(String message) {
 return Container(
 padding: const EdgeInsets.all(32),
 decoration: BoxDecoration(
 border: Border.all(color: _kBorder),
 borderRadius: BorderRadius.circular(12),
 ),
 child: Center(
 child: Text(message, style: TextStyle(color: _kMuted, fontSize: 15)),
 ),
 );
 }

 Future<void> _exportPdf() async {
 final projectData = ProjectDataHelper.getData(context);
 await PdfExportHelper.exportScreenPdf(
 context: context,
 screenTitle: 'Agile Sprint Calendar',
 sections: [
 PdfSection.keyValue('Project Info', [
 {'Project Name': projectData.projectName ?? 'N/A'},
 {'Solution Title': projectData.solutionTitle ?? 'N/A'},
 ]),
 PdfSection.text('Notes', projectData.planningNotes['planning_agile_sprint_calendar_notes'] ?? 'No data recorded.'),
 ],
 );
 }
}

class _SprintEditDialog extends StatefulWidget {
 final RoadmapSprint? existing;
 final ValueChanged<RoadmapSprint> onSave;

 const _SprintEditDialog({this.existing, required this.onSave});

 @override
 State<_SprintEditDialog> createState() => _SprintEditDialogState();
}

class _SprintEditDialogState extends State<_SprintEditDialog> {
 late TextEditingController _nameCtrl;
 late TextEditingController _goalCtrl;
 late TextEditingController _orderCtrl;
 DateTime? _startDate;
 DateTime? _endDate;

 @override
 void initState() {
 super.initState();
 final e = widget.existing;
 _nameCtrl = TextEditingController(text: e?.name ?? '');
 _goalCtrl = TextEditingController(text: e?.goal ?? '');
 _orderCtrl =
 TextEditingController(text: (e?.order ?? _nextOrder()).toString());
 _startDate = e?.startDate;
 _endDate = e?.endDate;
 }

 int _nextOrder() {
 return (widget.existing?.order ?? 0) + 1;
 }

 @override
 void dispose() {
 _nameCtrl.dispose();
 _goalCtrl.dispose();
 _orderCtrl.dispose();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 final DateFormat df = DateFormat('MMM dd, yyyy');
 return AlertDialog(
 title: Text(widget.existing != null ? 'Edit Sprint' : 'Add Sprint'),
 content: SingleChildScrollView(
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 VoiceTextField(
 controller: _nameCtrl,
 decoration: const InputDecoration(
 labelText: 'Sprint Name', border: OutlineInputBorder()),
 ),
 const SizedBox(height: 12),
 VoiceTextField(
 controller: _orderCtrl,
 decoration: const InputDecoration(
 labelText: 'Sprint #', border: OutlineInputBorder()),
 keyboardType: TextInputType.number,
 ),
 const SizedBox(height: 12),
 InkWell(
 onTap: () async {
 final picked = await showDatePicker(
 context: context,
 initialDate: _startDate ?? DateTime.now(),
 firstDate: DateTime.now().subtract(const Duration(days: 30)),
 lastDate: DateTime.now().add(const Duration(days: 365)),
 );
 if (picked != null) setState(() => _startDate = picked);
 },
 child: InputDecorator(
 decoration: const InputDecoration(
 labelText: 'Start Date', border: OutlineInputBorder()),
 child: Text(_startDate != null
 ? df.format(_startDate!)
 : 'Select date'),
 ),
 ),
 const SizedBox(height: 12),
 InkWell(
 onTap: () async {
 final picked = await showDatePicker(
 context: context,
 initialDate: _endDate ?? DateTime.now(),
 firstDate: DateTime.now().subtract(const Duration(days: 30)),
 lastDate: DateTime.now().add(const Duration(days: 365)),
 );
 if (picked != null) setState(() => _endDate = picked);
 },
 child: InputDecorator(
 decoration: const InputDecoration(
 labelText: 'End Date', border: OutlineInputBorder()),
 child: Text(
 _endDate != null ? df.format(_endDate!) : 'Select date'),
 ),
 ),
 const SizedBox(height: 12),
 VoiceTextField(
 controller: _goalCtrl,
 decoration: const InputDecoration(
 labelText: 'Sprint Goal', border: OutlineInputBorder()),
 maxLines: 2,
 ),
 ],
 ),
 ),
 actions: [
 TextButton(
 onPressed: () => Navigator.pop(context),
 child: const Text('Cancel'),
 ),
 ElevatedButton(
 onPressed: () {
 final sprint = RoadmapSprint(
 id: widget.existing?.id,
 name: _nameCtrl.text,
 order: int.tryParse(_orderCtrl.text) ?? 0,
 startDate: _startDate,
 endDate: _endDate,
 goal: _goalCtrl.text,
 );
 widget.onSave(sprint);
 Navigator.pop(context);
 },
 child: const Text('Save'),
 ),
 ],
 );
 }
}

class _AssignFeaturesDialog extends StatefulWidget {
 final String sprintName;
 final List<Feature> unassigned;
 final List<Feature> assigned;
 final ValueChanged<Feature> onAssign;
 final ValueChanged<Feature> onUnassign;

 const _AssignFeaturesDialog({
 required this.sprintName,
 required this.unassigned,
 required this.assigned,
 required this.onAssign,
 required this.onUnassign,
 });

 @override
 State<_AssignFeaturesDialog> createState() => _AssignFeaturesDialogState();
}

class _AssignFeaturesDialogState extends State<_AssignFeaturesDialog> {
 @override
 Widget build(BuildContext context) {
 return AlertDialog(
 title: Text('Features for ${widget.sprintName}'),
 content: SizedBox(
 width: double.maxFinite,
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 if (widget.assigned.isNotEmpty) ...[
 Text('Assigned to this sprint',
 style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kHeadline)),
 const SizedBox(height: 8),
 ...widget.assigned.map((f) => _buildFeatureTile(f, true)),
 const Divider(height: 24),
 ],
 if (widget.unassigned.isNotEmpty) ...[
 Text('Unassigned features',
 style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kHeadline)),
 const SizedBox(height: 8),
 ...widget.unassigned.map((f) => _buildFeatureTile(f, false)),
 ],
 if (widget.unassigned.isEmpty && widget.assigned.isEmpty)
 const Padding(
 padding: EdgeInsets.only(top: 16),
 child: Text('No features found. Create features in Epics & Features first.'),
 ),
 ],
 ),
 ),
 actions: [
 TextButton(
 onPressed: () => Navigator.pop(context),
 child: const Text('Close'),
 ),
 ],
 );
 }

 Widget _buildFeatureTile(Feature feature, bool isAssigned) {
 return Padding(
 padding: const EdgeInsets.only(bottom: 6),
 child: Row(
 children: [
 Icon(
 isAssigned ? Icons.check_circle : Icons.radio_button_unchecked,
 size: 18,
 color: isAssigned ? Colors.green : _kMuted,
 ),
 const SizedBox(width: 8),
 Expanded(
 child: Text(
 feature.title.isNotEmpty ? feature.title : '(untitled)',
 style: const TextStyle(fontSize: 13),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 Text(
 '${feature.storyPointEstimate.toStringAsFixed(0)} pts',
 style: TextStyle(fontSize: 11, color: _kMuted),
 ),
 const SizedBox(width: 8),
 SizedBox(
 height: 28,
 child: TextButton(
 onPressed: () {
 if (isAssigned) {
 widget.onUnassign(feature);
 } else {
 widget.onAssign(feature);
 }
 setState(() {});
 },
 style: TextButton.styleFrom(
 padding: const EdgeInsets.symmetric(horizontal: 8),
 ),
 child: Text(
 isAssigned ? 'Remove' : 'Assign',
 style: TextStyle(
 fontSize: 11,
 color: isAssigned ? Colors.red : const Color(0xFF059669),
 ),
 ),
 ),
 ),
 ],
 ),
 );
 }
}
