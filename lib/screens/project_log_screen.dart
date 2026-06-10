import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ndu_project/models/project_log_model.dart';
import 'package:ndu_project/services/project_log_service.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/voice_text_field.dart';

// ─── Design Tokens ──────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF005BB3);
const _kGoldAccent = Color(0xFFFABD00);
const _kSurface = Colors.white;
const _kBackground = Color(0xFFF7F9FB);
const _kBorder = Color(0xFFE5E7EB);

const _kPriorityHigh = Color(0xFFEF4444);
const _kPriorityMedium = Color(0xFFF59E0B);
const _kPriorityLow = Color(0xFF22C55E);

const _kStatusPending = Color(0xFFF59E0B);
const _kStatusInProgress = Color(0xFF3B82F6);
const _kStatusCompleted = Color(0xFF22C55E);
const _kStatusOverdue = Color(0xFFEF4444);

// ─── Screen ─────────────────────────────────────────────────────────────────

class ProjectLogScreen extends StatefulWidget {
  const ProjectLogScreen({super.key, this.projectId});

  final String? projectId;

  @override
  State<ProjectLogScreen> createState() => _ProjectLogScreenState();
}

class _ProjectLogScreenState extends State<ProjectLogScreen> {
  // ── State ───────────────────────────────────────────────────────────────
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _priorityFilter = 'All';
  String _sortBy = 'Newest';

  static const _statusOptions = ['All', 'Pending', 'In Progress', 'Completed', 'Overdue'];
  static const _priorityOptions = ['All', 'High', 'Medium', 'Low'];
  static const _sortOptions = ['Newest', 'Oldest', 'Due Date', 'Priority'];

  // ── Helpers ─────────────────────────────────────────────────────────────

  bool _isOverdue(ProjectLogEntry e) {
    if (e.status == 'Completed') return false;
    if (e.dueDate == null) return false;
    return e.dueDate!.isBefore(DateTime.now());
  }

  String _effectiveStatus(ProjectLogEntry e) {
    if (_isOverdue(e)) return 'Overdue';
    return e.status;
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return _kPriorityHigh;
      case 'Medium':
        return _kPriorityMedium;
      case 'Low':
        return _kPriorityLow;
      default:
        return _kPriorityMedium;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return _kStatusPending;
      case 'In Progress':
        return _kStatusInProgress;
      case 'Completed':
        return _kStatusCompleted;
      case 'Overdue':
        return _kStatusOverdue;
      default:
        return _kStatusPending;
    }
  }

  List<ProjectLogEntry> _applyFilters(List<ProjectLogEntry> entries) {
    var result = entries.toList();

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((e) =>
              (e.taskDescription?.toLowerCase().contains(q) ?? false) ||
              (e.assignedTo?.toLowerCase().contains(q) ?? false) ||
              (e.category?.toLowerCase().contains(q) ?? false) ||
              (e.notes?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    // Status filter
    if (_statusFilter != 'All') {
      result = result.where((e) => _effectiveStatus(e) == _statusFilter).toList();
    }

    // Priority filter
    if (_priorityFilter != 'All') {
      result = result.where((e) => e.priority == _priorityFilter).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'Newest':
        result.sort((a, b) =>
            (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
      case 'Oldest':
        result.sort((a, b) =>
            (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
        break;
      case 'Due Date':
        result.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'Priority':
        const order = {'High': 0, 'Medium': 1, 'Low': 2};
        result.sort((a, b) =>
            (order[a.priority] ?? 1).compareTo(order[b.priority] ?? 1));
        break;
    }

    return result;
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────

  Future<void> _showAddTaskDialog({ProjectLogEntry? existing}) async {
    final isEditing = existing != null;
    final descController = TextEditingController(text: existing?.taskDescription ?? '');
    final assignController = TextEditingController(text: existing?.assignedTo ?? '');
    final categoryController = TextEditingController(text: existing?.category ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');

    String priority = existing?.priority ?? 'Medium';
    String status = existing?.status ?? 'Pending';
    DateTime? dueDate = existing?.dueDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _kSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note_rounded : Icons.add_task_rounded,
                  color: _kGoldAccent, size: 26),
              const SizedBox(width: 10),
              Text(isEditing ? 'Edit Task' : 'Add Task',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(ctx).size.width > 600 ? 520 : null,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Task Description
                  VoiceTextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Task Description *',
                      hintText: 'Describe the task...',
                      prefixIcon: Icon(Icons.description_outlined, size: 20),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    enableImport: false,
                  ),
                  const SizedBox(height: 16),

                  // Assigned To
                  VoiceTextField(
                    controller: assignController,
                    decoration: const InputDecoration(
                      labelText: 'Assigned To',
                      hintText: 'Person or team responsible',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    textCapitalization: TextCapitalization.words,
                    enableImport: false,
                  ),
                  const SizedBox(height: 16),

                  // Due Date
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: _kPrimary,
                              onPrimary: Colors.white,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setDialogState(() => dueDate = picked);
                    },
                    child: AbsorbPointer(
                      child: VoiceTextField(
                        controller: TextEditingController(
                          text: dueDate != null ? DateFormat.yMMMd().format(dueDate!) : '',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Due Date',
                          hintText: 'Select a date',
                          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                          suffixIcon: dueDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setDialogState(() => dueDate = null),
                                )
                              : null,
                        ),
                        enableVoice: false,
                        enableImport: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Priority & Status row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: priority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            prefixIcon: Icon(Icons.flag_outlined, size: 20),
                          ),
                          items: ['High', 'Medium', 'Low']
                              .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _priorityColor(v),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(v),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setDialogState(() => priority = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.track_changes_outlined, size: 20),
                          ),
                          items: ['Pending', 'In Progress', 'Completed']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) => setDialogState(() => status = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category
                  VoiceTextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      hintText: 'e.g. Planning, Design, Execution',
                      prefixIcon: Icon(Icons.category_outlined, size: 20),
                    ),
                    textCapitalization: TextCapitalization.words,
                    enableImport: false,
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  VoiceTextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Additional details...',
                      prefixIcon: Icon(Icons.notes_outlined, size: 20),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    enableImport: false,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () async {
                final desc = descController.text.trim();
                if (desc.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task description is required.')),
                  );
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;
                final entry = ProjectLogEntry(
                  id: existing?.id,
                  projectId: widget.projectId,
                  taskDescription: desc,
                  assignedTo: assignController.text.trim().isEmpty
                      ? null
                      : assignController.text.trim(),
                  dueDate: dueDate,
                  priority: priority,
                  status: status,
                  category: categoryController.text.trim().isEmpty
                      ? null
                      : categoryController.text.trim(),
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                  createdBy: user?.uid,
                );

                try {
                  if (isEditing) {
                    final entryId = existing.id ?? '';
                    await ProjectLogService.updateEntry(
                      entryId,
                      entry.toFirestore(),
                    );
                  } else {
                    await ProjectLogService.addEntry(entry);
                  }
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: _kGoldAccent,
                foregroundColor: const Color(0xFF1C1C1C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEditing ? 'Update' : 'Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ProjectLogEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _kPriorityHigh, size: 26),
            SizedBox(width: 10),
            Text('Delete Task?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${entry.taskDescription ?? 'this task'}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: _kPriorityHigh,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && entry.id != null) {
      await ProjectLogService.deleteEntry(entry.id!);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final user = FirebaseAuth.instance.currentUser;
    final stream = widget.projectId != null
        ? ProjectLogService.streamEntries(projectId: widget.projectId!)
        : ProjectLogService.streamAllForUser(userId: user?.uid ?? '');

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: _buildAppBar(),
      body: StreamBuilder<List<ProjectLogEntry>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kPrimary));
          }

          final allEntries = snapshot.data ?? [];
          final filtered = _applyFilters(allEntries);

          return RefreshIndicator(
            color: _kPrimary,
            onRefresh: () async => setState(() {}),
            child: CustomScrollView(
              slivers: [
                // ── Summary Bar ──
                SliverToBoxAdapter(child: _buildSummaryBar(allEntries, isMobile)),

                // ── Search & Filters ──
                SliverToBoxAdapter(child: _buildSearchAndFilters(isMobile)),

                // ── Table or Empty State ──
                if (filtered.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState(isMobile))
                else if (isMobile)
                  _buildMobileList(filtered)
                else
                  _buildDesktopTable(filtered),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(),
        backgroundColor: _kGoldAccent,
        foregroundColor: const Color(0xFF1C1C1C),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kGoldAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_outlined, color: _kGoldAccent, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Project Log',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kBorder),
      ),
    );
  }

  // ── Summary Bar ─────────────────────────────────────────────────────────

  Widget _buildSummaryBar(List<ProjectLogEntry> entries, bool isMobile) {
    final total = entries.length;
    final pending = entries.where((e) => _effectiveStatus(e) == 'Pending').length;
    final completed = entries.where((e) => e.status == 'Completed').length;
    final overdue = entries.where((e) => _isOverdue(e)).length;

    final cards = [
      _SummaryCard(label: 'Total Tasks', value: total, color: _kPrimary, icon: Icons.list_alt_rounded),
      _SummaryCard(label: 'Pending', value: pending, color: _kStatusPending, icon: Icons.schedule_rounded),
      _SummaryCard(label: 'Completed', value: completed, color: _kStatusCompleted, icon: Icons.check_circle_outline_rounded),
      _SummaryCard(label: 'Overdue', value: overdue, color: _kStatusOverdue, icon: Icons.warning_amber_rounded),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppBreakpoints.pagePadding(context),
        vertical: 16,
      ),
      child: isMobile
          ? Column(
              children: [
                Row(children: [Expanded(child: cards[0]), const SizedBox(width: 10), Expanded(child: cards[1])]),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: cards[2]), const SizedBox(width: 10), Expanded(child: cards[3])]),
              ],
            )
          : Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: c))).toList()),
    );
  }

  // ── Search & Filters ────────────────────────────────────────────────────

  Widget _buildSearchAndFilters(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppBreakpoints.pagePadding(context)),
      child: Column(
        children: [
          // Search
          VoiceTextField(
            decoration: const InputDecoration(
              hintText: 'Search tasks, assignments, categories...',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            enableVoice: false,
            enableImport: false,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),
          // Filters
          if (isMobile)
            Column(
              children: [
                _buildFilterRow(),
              ],
            )
          else
            _buildFilterRow(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: [
        _filterChip('Status: $_statusFilter', _statusFilter != 'All', () {
          _showFilterPicker('Filter by Status', _statusOptions, _statusFilter, (v) {
            setState(() => _statusFilter = v);
          });
        }),
        _filterChip('Priority: $_priorityFilter', _priorityFilter != 'All', () {
          _showFilterPicker('Filter by Priority', _priorityOptions, _priorityFilter, (v) {
            setState(() => _priorityFilter = v);
          });
        }),
        _filterChip('Sort: $_sortBy', false, () {
          _showFilterPicker('Sort By', _sortOptions, _sortBy, (v) {
            setState(() => _sortBy = v);
          });
        }),
        if (_statusFilter != 'All' || _priorityFilter != 'All')
          ActionChip(
            label: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
            avatar: const Icon(Icons.clear_all_rounded, size: 16),
            onPressed: () => setState(() {
              _statusFilter = 'All';
              _priorityFilter = 'All';
            }),
          ),
      ],
    );
  }

  Widget _filterChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _kPrimary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _kPrimary.withOpacity(0.4) : _kBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? _kPrimary : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive ? _kPrimary : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterPicker(String title, List<String> options, String current, ValueChanged<String> onSelected) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        children: options
            .map((opt) => SimpleDialogOption(
                  onPressed: () {
                    onSelected(opt);
                    Navigator.pop(ctx);
                  },
                  child: Row(
                    children: [
                      if (opt == current)
                        const Icon(Icons.check_rounded, color: _kPrimary, size: 18),
                      if (opt == current) const SizedBox(width: 8),
                      Text(
                        opt,
                        style: TextStyle(
                          fontWeight: opt == current ? FontWeight.w700 : FontWeight.w400,
                          color: opt == current ? _kPrimary : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Desktop Table ───────────────────────────────────────────────────────

  Widget _buildDesktopTable(List<ProjectLogEntry> entries) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppBreakpoints.pagePadding(context)),
      sliver: SliverToBoxAdapter(
        child: Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - AppBreakpoints.pagePadding(context) * 2 - 20),
                child: DataTable(
                  columnSpacing: 16,
                  horizontalMargin: 16,
                  columns: const [
                    DataColumn(label: _TableHeader('Task')),
                    DataColumn(label: _TableHeader('Assigned To')),
                    DataColumn(label: _TableHeader('Due Date')),
                    DataColumn(label: _TableHeader('Priority')),
                    DataColumn(label: _TableHeader('Status')),
                    DataColumn(label: _TableHeader('Category')),
                    DataColumn(label: _TableHeader('Notes')),
                    DataColumn(label: _TableHeader('Actions')),
                  ],
                  rows: entries.map((e) => _buildDataRow(e)).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(ProjectLogEntry e) {
    final effStatus = _effectiveStatus(e);
    return DataRow(
      cells: [
        // Task
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              e.taskDescription ?? '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: e.status == 'Completed' ? TextDecoration.lineThrough : null,
                color: e.status == 'Completed' ? Colors.grey : const Color(0xFF1E293B),
              ),
            ),
          ),
        ),
        // Assigned To
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _kPrimary.withOpacity(0.08),
                child: Text(
                  (e.assignedTo ?? '?').isNotEmpty ? (e.assignedTo!).substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  e.assignedTo ?? 'Unassigned',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        // Due Date
        DataCell(_buildDueDateCell(e)),
        // Priority
        DataCell(_Badge(label: e.priority, color: _priorityColor(e.priority))),
        // Status
        DataCell(_Badge(label: effStatus, color: _statusColor(effStatus))),
        // Category
        DataCell(
          Text(e.category ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        ),
        // Notes
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Tooltip(
              message: e.notes ?? '',
              child: Text(
                e.notes ?? '—',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
          ),
        ),
        // Actions
        DataCell(_buildActionButtons(e)),
      ],
    );
  }

  Widget _buildDueDateCell(ProjectLogEntry e) {
    if (e.dueDate == null) return const Text('—', style: TextStyle(fontSize: 13, color: Color(0xFF64748B)));

    final isOver = _isOverdue(e);
    final isSoon = !isOver && e.dueDate!.difference(DateTime.now()).inDays <= 3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOver ? Icons.warning_amber_rounded : isSoon ? Icons.schedule_rounded : Icons.event_outlined,
          size: 14,
          color: isOver ? _kStatusOverdue : isSoon ? _kStatusPending : const Color(0xFF64748B),
        ),
        const SizedBox(width: 4),
        Text(
          DateFormat.yMMMd().format(e.dueDate!),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isOver ? FontWeight.w700 : FontWeight.w500,
            color: isOver ? _kStatusOverdue : isSoon ? _kStatusPending : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ProjectLogEntry e) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionIcon(Icons.edit_outlined, 'Edit', _kPrimary, () => _showAddTaskDialog(existing: e)),
        const SizedBox(width: 4),
        if (e.status != 'Completed')
          _actionIcon(Icons.check_circle_outline_rounded, 'Complete', _kStatusCompleted, () async {
            await ProjectLogService.markComplete(e.id!);
          }),
        if (e.status != 'Completed') const SizedBox(width: 4),
        _actionIcon(Icons.delete_outline_rounded, 'Delete', _kPriorityHigh, () => _confirmDelete(e)),
      ],
    );
  }

  Widget _actionIcon(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  // ── Mobile List ─────────────────────────────────────────────────────────

  Widget _buildMobileList(List<ProjectLogEntry> entries) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppBreakpoints.pagePadding(context)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildMobileCard(entries[index]),
          childCount: entries.length,
        ),
      ),
    );
  }

  Widget _buildMobileCard(ProjectLogEntry e) {
    final effStatus = _effectiveStatus(e);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Task + badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      e.taskDescription ?? '—',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: e.status == 'Completed' ? TextDecoration.lineThrough : null,
                        color: e.status == 'Completed' ? Colors.grey : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Badge(label: e.priority, color: _priorityColor(e.priority)),
                  const SizedBox(width: 4),
                  _Badge(label: effStatus, color: _statusColor(effStatus)),
                ],
              ),
              const SizedBox(height: 10),
              // Row 2: Assigned & due
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(e.assignedTo ?? 'Unassigned',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  const Spacer(),
                  if (e.dueDate != null) ...[
                    Icon(Icons.event_outlined, size: 14,
                        color: _isOverdue(e) ? _kStatusOverdue : Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMMMd().format(e.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isOverdue(e) ? FontWeight.w700 : FontWeight.w500,
                        color: _isOverdue(e) ? _kStatusOverdue : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
              if (e.category != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.category_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(e.category!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
              if (e.notes != null && e.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(e.notes!, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
              ],
              const Divider(height: 20),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _textAction('Edit', Icons.edit_outlined, _kPrimary, () => _showAddTaskDialog(existing: e)),
                  if (e.status != 'Completed') ...[
                    const SizedBox(width: 12),
                    _textAction('Complete', Icons.check_circle_outline_rounded, _kStatusCompleted, () async {
                      await ProjectLogService.markComplete(e.id!);
                    }),
                  ],
                  const SizedBox(width: 12),
                  _textAction('Delete', Icons.delete_outline_rounded, _kPriorityHigh, () => _confirmDelete(e)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kGoldAccent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 56,
                color: _kGoldAccent.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No tasks yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first task to start tracking\nassignments, deadlines, and progress.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddTaskDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: _kGoldAccent,
                foregroundColor: const Color(0xFF1C1C1C),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1.1)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 0.6,
      ),
    );
  }
}
