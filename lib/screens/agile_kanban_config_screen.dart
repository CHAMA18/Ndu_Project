import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/agile_wireframe_service.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/voice_text_field.dart';
import 'package:ndu_project/utils/pdf_export_helper.dart';

const Color _kBackground = Colors.white;
const Color _kBorder = Color(0xFFE5E7EB);
const Color _kMuted = Color(0xFF6B7280);
const Color _kHeadline = Color(0xFF111827);

const List<String> _defaultColumns = [
  'Backlog',
  'Ready',
  'In Progress',
  'Code Review',
  'Testing',
  'Ready for Release',
  'Done',
];

const List<String> _cosOptions = [
  'Standard',
  'Expedite',
  'Fixed Date',
  'Intangible',
];

class _KanbanColumn {
  String id;
  String name;
  int wipLimit;
  String entryCriteria;
  String exitCriteria;

  _KanbanColumn({
    String? id,
    this.name = '',
    this.wipLimit = 0,
    this.entryCriteria = '',
    this.exitCriteria = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'wipLimit': wipLimit,
        'entryCriteria': entryCriteria,
        'exitCriteria': exitCriteria,
      };

  factory _KanbanColumn.fromJson(Map<String, dynamic> json) {
    return _KanbanColumn(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      wipLimit: (json['wipLimit'] as num?)?.toInt() ?? 0,
      entryCriteria: json['entryCriteria']?.toString() ?? '',
      exitCriteria: json['exitCriteria']?.toString() ?? '',
    );
  }
}

class _ClassOfService {
  String id;
  String name;
  int slaHours;
  String description;

  _ClassOfService({
    String? id,
    this.name = 'Standard',
    this.slaHours = 24,
    this.description = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slaHours': slaHours,
        'description': description,
      };

  factory _ClassOfService.fromJson(Map<String, dynamic> json) {
    return _ClassOfService(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? 'Standard',
      slaHours: (json['slaHours'] as num?)?.toInt() ?? 24,
      description: json['description']?.toString() ?? '',
    );
  }
}

class AgileKanbanConfigScreen extends StatefulWidget {
  const AgileKanbanConfigScreen({super.key});

  @override
  State<AgileKanbanConfigScreen> createState() =>
      _AgileKanbanConfigScreenState();
}

class _AgileKanbanConfigScreenState extends State<AgileKanbanConfigScreen> {
  List<_KanbanColumn> _columns = [];
  List<_ClassOfService> _cosList = [];
  int _nextSprintReviewDays = 7;
  bool _enableSwimlanes = true;
  bool _isLoading = true;
  bool _isSaving = false;
  Timer? _autoSaveDebounce;

  // Controllers for notes
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _reviewCadenceCtrl = TextEditingController();
  final Map<String, TextEditingController> _nameCtrls = {};
  final Map<String, TextEditingController> _entryCtrls = {};
  final Map<String, TextEditingController> _exitCtrls = {};
  String? _selectedColumnId;

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
    _autoSaveDebounce?.cancel();
    _notesCtrl.dispose();
    _reviewCadenceCtrl.dispose();
    for (final c in _nameCtrls.values) {
      c.dispose();
    }
    for (final c in _entryCtrls.values) {
      c.dispose();
    }
    for (final c in _exitCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final pid = _projectId;
    if (pid == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await AgileWireframeService.loadKanbanConfig(pid);
      if (!mounted) return;
      final rawCols = data['columns'] as List?;
      if (rawCols != null && rawCols.isNotEmpty) {
        _columns = rawCols
            .map((e) => _KanbanColumn.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _columns = _defaultColumns
            .map((name) => _KanbanColumn(
                  name: name,
                  wipLimit: name == 'In Progress' ? 3 : 0,
                ))
            .toList();
      }
      final rawCos = data['classesOfService'] as List?;
      if (rawCols != null && rawCos != null && rawCos.isNotEmpty) {
        _cosList = rawCos
            .map((e) => _ClassOfService.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _cosList = _cosOptions.map((name) {
          final sla = switch (name) {
            'Expedite' => 4,
            'Fixed Date' => 48,
            'Intangible' => 72,
            _ => 24,
          };
          return _ClassOfService(name: name, slaHours: sla);
        }).toList();
      }
      _nextSprintReviewDays =
          (data['nextSprintReviewDays'] as num?)?.toInt() ?? 7;
      _enableSwimlanes = data['enableSwimlanes'] as bool? ?? true;
      _notesCtrl.text = data['notes'] as String? ?? '';
      _reviewCadenceCtrl.text = _nextSprintReviewDays.toString();
      _rebuildCtrls();
      _selectedColumnId = _columns.isNotEmpty ? _columns.first.id : null;
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _rebuildCtrls() {
    for (final c in _nameCtrls.values) {
      c.dispose();
    }
    for (final c in _entryCtrls.values) {
      c.dispose();
    }
    for (final c in _exitCtrls.values) {
      c.dispose();
    }
    _nameCtrls.clear();
    _entryCtrls.clear();
    _exitCtrls.clear();
    for (final col in _columns) {
      _nameCtrls[col.id] = TextEditingController(text: col.name);
      _entryCtrls[col.id] = TextEditingController(text: col.entryCriteria);
      _exitCtrls[col.id] = TextEditingController(text: col.exitCriteria);
    }
  }

  void _scheduleAutoSave() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce =
        Timer(const Duration(milliseconds: 500), () => _performSave());
  }

  Future<void> _performSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final pid = _projectId;
      if (pid == null) return;
      for (final col in _columns) {
        col.entryCriteria = _entryCtrls[col.id]?.text ?? '';
        col.exitCriteria = _exitCtrls[col.id]?.text ?? '';
      }
      await AgileWireframeService.saveKanbanConfig(
        projectId: pid,
        data: {
          'columns': _columns.map((c) => c.toJson()).toList(),
          'classesOfService': _cosList.map((c) => c.toJson()).toList(),
          'nextSprintReviewDays': _nextSprintReviewDays,
          'enableSwimlanes': _enableSwimlanes,
          'notes': _notesCtrl.text,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Saved'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isSaving = false);
  }

  void _addColumn() {
    setState(() {
      final column = _KanbanColumn(name: 'New Stage');
      _columns.add(column);
      _rebuildCtrls();
      _selectedColumnId = column.id;
    });
    _scheduleAutoSave();
  }

  void _removeColumn(int index) {
    if (_columns.length <= 2) return;
    final col = _columns[index];
    _nameCtrls.remove(col.id)?.dispose();
    _entryCtrls.remove(col.id)?.dispose();
    _exitCtrls.remove(col.id)?.dispose();
    setState(() {
      _columns.removeAt(index);
      if (_selectedColumnId == col.id) {
        _selectedColumnId = _columns.isNotEmpty ? _columns.first.id : null;
      }
    });
    _scheduleAutoSave();
  }

  void _moveColumnLeft(int index) {
    if (index <= 0 || index >= _columns.length) return;
    setState(() {
      final col = _columns.removeAt(index);
      _columns.insert(index - 1, col);
    });
    _scheduleAutoSave();
  }

  void _moveColumnRight(int index) {
    if (index < 0 || index >= _columns.length - 1) return;
    setState(() {
      final col = _columns.removeAt(index);
      _columns.insert(index + 1, col);
    });
    _scheduleAutoSave();
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
                  activeItemLabel:
                      'Agile Delivery Model - Kanban Configuration'),
            ),
            Expanded(
              child: Stack(
                children: [
                  MobileSidebarHamburger(
                    sidebar: const InitiationLikeSidebar(
                        activeItemLabel:
                            'Agile Delivery Model - Kanban Configuration'),
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: hp, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlanningPhaseHeader(
                          title: 'Kanban Configuration',
                          onBack: () => PlanningPhaseNavigation.goToPrevious(
                              context, 'agile_kanban_config'),
                          onForward: () => PlanningPhaseNavigation.goToNext(
                              context, 'agile_kanban_config'),
                          onExportPdf: _exportPdf,
                        ),
                        const SizedBox(height: 24),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          _buildColumnsSection(),
                          const SizedBox(height: 24),
                          _buildClassesOfService(),
                          const SizedBox(height: 24),
                          _buildSettingsSection(),
                          const SizedBox(height: 24),
                          _buildNotesSection(),
                        ],
                        const SizedBox(height: 24),
                        LaunchPhaseNavigation(
                          backLabel: PlanningPhaseNavigation.backLabel(
                              'agile_kanban_config'),
                          nextLabel: PlanningPhaseNavigation.nextLabel(
                              'agile_kanban_config'),
                          onBack: () => PlanningPhaseNavigation.goToPrevious(
                              context, 'agile_kanban_config'),
                          onNext: () => PlanningPhaseNavigation.goToNext(
                              context, 'agile_kanban_config'),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: 24,
                    bottom: 24,
                    child: KazAiChatBubble(positioned: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnsSection() {
    final selected = _columns
        .where((c) => c.id == _selectedColumnId)
        .cast<_KanbanColumn?>()
        .firstWhere((c) => c != null,
            orElse: () => _columns.isNotEmpty ? _columns.first : null);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('Board Workflow Setup',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kHeadline)),
              ),
              TextButton.icon(
                onPressed: _applySimpleTemplate,
                icon: const Icon(Icons.view_column_outlined, size: 16),
                label: const Text('Simple Template'),
              ),
              TextButton.icon(
                onPressed: _applySoftwareTemplate,
                icon: const Icon(Icons.developer_board, size: 16),
                label: const Text('Software Template'),
              ),
              TextButton.icon(
                onPressed: _addColumn,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Stage'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure the workflow stages your team will use on the Kanban board. Drag stages left-to-right to set board order, then use Edit to define WIP limits and flow rules.',
            style: TextStyle(fontSize: 13, color: _kMuted),
          ),
          const SizedBox(height: 14),
          if (_columns.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No workflow stages configured yet.',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kHeadline),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose a template or add your first stage to start configuring the board.',
                    style: TextStyle(fontSize: 13, color: _kMuted),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _applySimpleTemplate,
                        icon: const Icon(Icons.view_column_outlined, size: 16),
                        label: const Text('Simple Template'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _applySoftwareTemplate,
                        icon: const Icon(Icons.developer_board, size: 16),
                        label: const Text('Software Template'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addColumn,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Stage'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 240,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_columns.length, (index) {
                    final col = _columns[index];
                    final selectedCard = selected?.id == col.id;
                    return Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => setState(() => _selectedColumnId = col.id),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selectedCard
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selectedCard
                                  ? const Color(0xFFD97706)
                                  : _kBorder,
                              width: selectedCard ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.view_column_outlined,
                                      color: _kMuted, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      col.name.trim().isEmpty
                                          ? 'Untitled Stage'
                                          : col.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _kHeadline),
                                    ),
                                  ),
                                  if (_columns.length > 2)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18, color: Colors.red),
                                      onPressed: () => _removeColumn(index),
                                      tooltip: 'Delete stage',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: _kBorder),
                                    ),
                                    child: Text(
                                      col.wipLimit > 0
                                          ? 'WIP ${col.wipLimit}'
                                          : 'No WIP limit',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _kMuted),
                                    ),
                                  ),
                                  if (index > 0)
                                    IconButton(
                                      onPressed: () => _moveColumnLeft(index),
                                      icon: const Icon(Icons.arrow_back_ios_new,
                                          size: 16),
                                      tooltip: 'Move left',
                                    ),
                                  if (index < _columns.length - 1)
                                    IconButton(
                                      onPressed: () => _moveColumnRight(index),
                                      icon: const Icon(Icons.arrow_forward_ios,
                                          size: 16),
                                      tooltip: 'Move right',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    _stagePolicyPreview(
                                        'Entry', col.entryCriteria),
                                    const SizedBox(height: 8),
                                    _stagePolicyPreview(
                                        'Exit', col.exitCriteria),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: () => _editColumnDialog(col),
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildClassesOfService() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Classes of Service',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kHeadline)),
          const SizedBox(height: 8),
          const Text(
            'Configure service classes with SLA targets for different work item types.',
            style: TextStyle(fontSize: 13, color: _kMuted),
          ),
          const SizedBox(height: 12),
          ..._cosList.asMap().entries.map((e) => _buildCosRow(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildCosRow(int index, _ClassOfService cos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 900;
          final serviceClassField = DropdownButtonFormField<String>(
            value: _cosOptions.contains(cos.name) ? cos.name : _cosOptions[0],
            decoration: const InputDecoration(
              labelText: 'Service Class',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            items: _cosOptions
                .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o, style: const TextStyle(fontSize: 12))))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => cos.name = v);
                _scheduleAutoSave();
              }
            },
          );
          final slaField = TextFormField(
            initialValue: cos.slaHours.toString(),
            decoration: const InputDecoration(
              labelText: 'SLA (hrs)',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 12),
            onChanged: (v) {
              cos.slaHours = int.tryParse(v) ?? 24;
              _scheduleAutoSave();
            },
          );
          final descriptionField = TextFormField(
            initialValue: cos.description,
            decoration: const InputDecoration(
              hintText: 'Description',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            style: const TextStyle(fontSize: 11),
            onChanged: (v) {
              cos.description = v;
              _scheduleAutoSave();
            },
          );
          if (narrow) {
            return Column(
              children: [
                serviceClassField,
                const SizedBox(height: 8),
                slaField,
                const SizedBox(height: 8),
                descriptionField,
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: serviceClassField,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: slaField,
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: descriptionField,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stagePolicyPreview(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
        const SizedBox(height: 4),
        Text(
          value.trim().isEmpty ? 'Not defined yet' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: value.trim().isEmpty ? _kMuted : _kHeadline,
            fontStyle:
                value.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }

  void _editColumnDialog(_KanbanColumn column) {
    final nameCtrl = TextEditingController(text: column.name);
    final entryCtrl = TextEditingController(text: column.entryCriteria);
    final exitCtrl = TextEditingController(text: column.exitCriteria);
    final wipCtrl = TextEditingController(text: column.wipLimit.toString());
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Stage'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Stage name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: wipCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'WIP limit'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: entryCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(labelText: 'Entry criteria'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: exitCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Exit criteria'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                column.name = nameCtrl.text.trim();
                column.wipLimit = int.tryParse(wipCtrl.text.trim()) ?? 0;
                column.entryCriteria = entryCtrl.text.trim();
                column.exitCriteria = exitCtrl.text.trim();
                _nameCtrls[column.id]?.text = column.name;
                _entryCtrls[column.id]?.text = column.entryCriteria;
                _exitCtrls[column.id]?.text = column.exitCriteria;
              });
              Navigator.pop(dialogContext);
              _scheduleAutoSave();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _applySimpleTemplate() {
    setState(() {
      _columns = [
        _KanbanColumn(name: 'To Do'),
        _KanbanColumn(name: 'In Progress', wipLimit: 3),
        _KanbanColumn(name: 'Done'),
      ];
      _rebuildCtrls();
      _selectedColumnId = _columns.first.id;
    });
    _scheduleAutoSave();
  }

  void _applySoftwareTemplate() {
    setState(() {
      _columns = _defaultColumns
          .map((name) => _KanbanColumn(
                name: name,
                wipLimit: name == 'In Progress' ? 3 : 0,
              ))
          .toList();
      _rebuildCtrls();
      _selectedColumnId = _columns.first.id;
    });
    _scheduleAutoSave();
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kHeadline)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              final cadenceField = SizedBox(
                width: narrow ? double.infinity : 120,
                child: VoiceTextField(
                  controller: _reviewCadenceCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12),
                  onChanged: (v) {
                    _nextSprintReviewDays = int.tryParse(v) ?? 7;
                    _scheduleAutoSave();
                  },
                ),
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Enable swimlanes',
                            style: TextStyle(fontSize: 13, color: _kHeadline)),
                        const SizedBox(width: 12),
                        Switch(
                          value: _enableSwimlanes,
                          onChanged: (v) {
                            setState(() => _enableSwimlanes = v);
                            _scheduleAutoSave();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Sprint review cadence (days)',
                        style: TextStyle(fontSize: 13, color: _kHeadline)),
                    const SizedBox(height: 8),
                    cadenceField,
                  ],
                );
              }
              return Row(
                children: [
                  const Text('Enable swimlanes',
                      style: TextStyle(fontSize: 13, color: _kHeadline)),
                  const SizedBox(width: 12),
                  Switch(
                    value: _enableSwimlanes,
                    onChanged: (v) {
                      setState(() => _enableSwimlanes = v);
                      _scheduleAutoSave();
                    },
                  ),
                  const SizedBox(width: 24),
                  const Text('Sprint review cadence (days)',
                      style: TextStyle(fontSize: 13, color: _kHeadline)),
                  const SizedBox(width: 8),
                  cadenceField,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Additional Notes',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kHeadline)),
        const SizedBox(height: 8),
        VoiceTextField(
          controller: _notesCtrl,
          decoration: const InputDecoration(
            hintText: 'Flow policies, pull rules, SLA enforcement notes...',
            border: OutlineInputBorder(),
          ),
          minLines: 3,
          maxLines: 6,
          onChanged: (_) => _scheduleAutoSave(),
        ),
      ],
    );
  }

  Future<void> _exportPdf() async {
    final projectData = ProjectDataHelper.getData(context);
    await PdfExportHelper.exportScreenPdf(
      context: context,
      screenTitle: 'Kanban Configuration',
      sections: [
        PdfSection.keyValue('Project Info', [
          {
            'Project Name': projectData.projectName.isEmpty
                ? 'N/A'
                : projectData.projectName
          },
          {
            'Solution Title': projectData.solutionTitle.isEmpty
                ? 'N/A'
                : projectData.solutionTitle
          },
        ]),
        PdfSection.text(
            'Notes',
            projectData.planningNotes['planning_agile_kanban_config_notes'] ??
                'No data recorded.'),
      ],
    );
  }
}
