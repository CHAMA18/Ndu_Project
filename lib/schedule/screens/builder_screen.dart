library;

/// Builder Screen — decompose WBS into a multi-level schedule.
///
/// Activity tree (Level 0→8) with add/edit/delete/reorder. Below the live
/// activity tree, a sample activity table demonstrates the columnar view that
/// will appear on the Gantt and List View tabs once activities are added.
///
/// A "Drawing from" context banner is rendered below the level-convention
/// card so the user can see that this page consumes the WBS (deliverables +
/// sub-deliverables) and the Cost Estimate (total budget) from earlier in
/// the Planning Phase.
///
/// Rendered inside the parent module's `ResponsiveScaffold` body — no
/// per-screen Scaffold wrapper (parent provides white background).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/schedule/models/schedule_models.dart';
import 'package:ndu_project/schedule/providers/schedule_provider.dart';
import 'package:ndu_project/wbs/providers/wbs_provider.dart';
import 'package:ndu_project/wbs/models/wbs_models.dart';
import 'package:ndu_project/cost_estimate/providers/cost_estimate_provider.dart';
import 'package:ndu_project/cost_estimate/providers/compute_utils.dart';
import 'package:ndu_project/cost_estimate/models/cost_estimate_models.dart';

class BuilderScreen extends StatelessWidget {
  const BuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ScheduleProvider, WBSProvider, CostEstimateProvider>(
      builder: (context, provider, wbsProvider, costProvider, _) {
        final schedule = provider.schedule!;
        final root = schedule.activities[0];
        final wbs = wbsProvider.wbs;
        final wbsCounts = wbs != null ? countNodes(wbs) : null;
        final estimate = costProvider.estimate;
        final currency = estimate?.currency ?? 'USD';
        final costTotal = estimate != null
            ? estimate.lines.fold<double>(
                0,
                (s, l) => s + _effectiveScheduleBuilderLineTotal(l))
            : 0.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.folder_open,
                                color: LightModeColors.accent, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(schedule.projectName,
                                  style: const TextStyle(
                                      color: Color(0xFF1A1D1F),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${schedule.basis.deliveryModel} · ${root.children.length} Level 1 activities · Status: ${schedule.status.label}',
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionChip(
                        icon: Icons.add,
                        label: 'Add Activity',
                        primary: true,
                        enabled: !schedule.isLocked,
                        onTap: () =>
                            _showAddDialog(context, provider, root.id, 1),
                      ),
                      _ActionChip(
                        icon: Icons.upload_outlined,
                        label: 'Import',
                        enabled: !schedule.isLocked,
                        onTap: () => _showImportInfo(context),
                      ),
                      _ActionChip(
                        icon: Icons.download_outlined,
                        label: 'Export',
                        onTap: () => _exportSchedule(context, schedule),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Help / level-convention card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 16, color: LightModeColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Schedule levels: L0=Project · L1=Major Deliverable · L2=Epic/Sub-Deliverable · L3=EWP/Procurement/CWP · L4=Activity/Story · L5–8=Task. Decompose until each activity is executable by one person.',
                        style: TextStyle(
                            color: const Color(0xFF495057),
                            fontSize: 12,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // "Drawing from" context banner — shows the upstream WBS and
              // Cost Estimate data this builder is consuming.
              _DrawingFromBanner(
                wbs: wbs,
                wbsCounts: wbsCounts,
                costTotal: costTotal,
                currency: currency,
                hasEstimate: estimate != null,
              ),
              const SizedBox(height: 24),
              // Live activity tree
              Text('Activity Tree',
                  style: const TextStyle(
                      color: Color(0xFF1A1D1F),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _ActivityNode(
                  activity: root,
                  isRoot: true,
                  provider: provider,
                  isLocked: schedule.isLocked),
              ...root.children.map((child) => _ActivityNode(
                  activity: child,
                  provider: provider,
                  isLocked: schedule.isLocked)),
              const SizedBox(height: 32),
              // Sample activity table (preview of what Gantt/List will show)
              _SampleActivityTable(schedule: schedule),
              const SizedBox(height: 24),
              // Footer note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LightModeColors.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: LightModeColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: LightModeColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The table above shows a sample schedule for reference. Add your own activities via the Add Activity button to populate the Gantt and List View tabs. Each row maps to an EWP, CWP, or activity in your delivery model.',
                        style: TextStyle(
                            color: const Color(0xFF495057),
                            fontSize: 12,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Mirror of [ComputeUtils] effective line total so the schedule builder
  /// can show a variance-aware total without re-implementing the full totals
  /// computation. Kept private — this is the same logic the Cost Estimate
  /// module uses internally.
  double _effectiveScheduleBuilderLineTotal(CostLine l) {
    if (l.varianceType == VarianceType.remove) {
      return -(l.varianceBaselineTotal ?? 0);
    }
    if (l.varianceType == VarianceType.change) {
      return l.varianceDelta ?? 0;
    }
    return l.total;
  }

  void _showAddDialog(BuildContext context, ScheduleProvider provider,
      String parentId, int level) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE4E7EC))),
        title: Text('Add Level $level Activity',
            style: const TextStyle(
                color: Color(0xFF1A1D1F), fontWeight: FontWeight.w600)),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Activity name',
            labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: LightModeColors.accent, width: 1.6),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
          ),
          style: const TextStyle(color: Color(0xFF1A1D1F)),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                provider.addActivity(
                  parentId,
                  ScheduleActivity(
                    id: '',
                    level: 0,
                    code: '',
                    name: nameCtrl.text.trim(),
                    type: level <= 1
                        ? ActivityType.summary
                        : ActivityType.activity,
                    domain: ScheduleDomain.engineering,
                    dependencies: [],
                    aiGenerated: false,
                    children: [],
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: LightModeColors.accent,
              foregroundColor: LightModeColors.lightOnPrimary,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showImportInfo(BuildContext context) {
    final wbsProvider = context.read<WBSProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();

    final wbs = wbsProvider.wbs;
    if (wbs == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE4E7EC))),
          title: const Text('No WBS Available',
              style: TextStyle(
                  color: Color(0xFF1A1D1F), fontWeight: FontWeight.w600)),
          content: const Text(
            'Open the WBS module from the sidebar to create your work breakdown structure first, then return here to import it into the schedule.',
            style: TextStyle(color: Color(0xFF495057), fontSize: 13, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: LightModeColors.lightOnPrimary,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }

    // Build the WBS node list in the format expected by importFromWBS
    final l1Nodes = wbs.level0.children;
    final wbsNodes = l1Nodes.map((l1) {
      return (
        id: l1.id,
        code: l1.code,
        name: l1.name,
        description: l1.description,
        children: l1.children.map((l2) {
          return (
            id: l2.id,
            code: l2.code,
            name: l2.name,
            description: l2.description,
          );
        }).toList(),
      );
    }).toList();

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE4E7EC))),
        title: const Text('Import from WBS',
            style: TextStyle(
                color: Color(0xFF1A1D1F), fontWeight: FontWeight.w600)),
        content: Text(
          'This will import ${l1Nodes.length} Level 1 deliverable(s) and their sub-deliverables from your WBS into the schedule as activities. '
          'Each WBS node becomes a schedule activity with its WBS reference preserved for traceability.',
          style: const TextStyle(color: Color(0xFF495057), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              scheduleProvider.importFromWBS(wbsNodes);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Imported ${l1Nodes.length} deliverable(s) from WBS'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: LightModeColors.accent,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: LightModeColors.accent,
              foregroundColor: LightModeColors.lightOnPrimary,
            ),
            child: const Text('Import Now'),
          ),
        ],
      ),
    );
  }

  void _exportSchedule(BuildContext context, Schedule schedule) async {
    final json = const JsonEncoder.withIndent('  ').convert({
      'id': schedule.id,
      'projectName': schedule.projectName,
      'deliveryModel': schedule.basis.deliveryModel,
      'status': schedule.status.name,
      'isLocked': schedule.isLocked,
      'activities': _activityToJson(schedule.activities[0]),
    });
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Schedule JSON copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: LightModeColors.accent,
      ),
    );
  }

  Map<String, dynamic> _activityToJson(ScheduleActivity node) {
    return {
      'code': node.code,
      'name': node.name,
      'level': node.level,
      'type': node.type.name,
      'domain': node.domain.name,
      if (node.duration != null) 'duration': node.duration,
      if (node.durationUnit != null) 'durationUnit': node.durationUnit,
      if (node.owner != null) 'owner': node.owner,
      if (node.status != null) 'status': node.status,
      'children': node.children.map(_activityToJson).toList(),
    };
  }
}

/// Compact action chip used in the Builder header.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled;
    if (primary && !disabled) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: LightModeColors.accent,
          foregroundColor: LightModeColors.lightOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: disabled ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: disabled ? const Color(0xFF9CA3AF) : const Color(0xFF1A1D1F),
        backgroundColor: Colors.white,
        side: BorderSide(
            color: disabled
                ? const Color(0xFFE4E7EC)
                : const Color(0xFFE4E7EC)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// A single activity node in the live tree.
class _ActivityNode extends StatelessWidget {
  final ScheduleActivity activity;
  final bool isRoot;
  final ScheduleProvider provider;
  final bool isLocked;

  const _ActivityNode({
    required this.activity,
    this.isRoot = false,
    required this.provider,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6, left: isRoot ? 0 : 24),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: Color(activity.domain.color), width: 3),
          top: const BorderSide(color: Color(0xFFE4E7EC), width: 1),
          right: const BorderSide(color: Color(0xFFE4E7EC), width: 1),
          bottom: const BorderSide(color: Color(0xFFE4E7EC), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Text(activity.code,
                style: const TextStyle(
                    color: Color(0xFF495057),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: Color(activity.domain.color), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(activity.name,
                style: const TextStyle(
                    color: Color(0xFF1A1D1F),
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          if (formatDuration(activity.duration, activity.durationUnit) != '—')
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                  formatDuration(activity.duration, activity.durationUnit),
                  style: const TextStyle(
                      color: Color(0xFF6B7280), fontSize: 11)),
            ),
          if (!isRoot && !isLocked) ...[
            IconButton(
              icon: const Icon(Icons.add, size: 14, color: Color(0xFF6B7280)),
              onPressed: () {},
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 14, color: Color(0xFFB91C1C)),
              onPressed: () => provider.removeActivity(activity.id),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sample activity table — demonstrates the full columnar view (ID, Name,
/// Duration, Start, Finish, Predecessors, Resources) that the Gantt and List
/// View tabs render against live data.
class _SampleActivityTable extends StatelessWidget {
  final Schedule schedule;
  const _SampleActivityTable({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final rows = _sampleRows(schedule.projectName, schedule.basis.deliveryModel);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.table_chart,
                    size: 16, color: LightModeColors.accent),
                const SizedBox(width: 8),
                const Text('Sample Activity Schedule',
                    style: TextStyle(
                        color: Color(0xFF1A1D1F),
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE4E7EC)),
                  ),
                  child: Text('${rows.length} activities',
                      style: const TextStyle(
                          color: Color(0xFF495057),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE4E7EC), height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFF9FAFB)),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
              columnSpacing: 24,
              horizontalMargin: 16,
              columns: const [
                DataColumn(
                    label: Text('ID',
                        style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
                DataColumn(
                    label: Text('Name',
                        style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
                DataColumn(
                    label: Text('Duration',
                        style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
                DataColumn(
                    label: Text('Start',
                        style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
                DataColumn(
                    label: Text('Finish',
                        style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
                DataColumn(
                    label: Text('Predecessors',
                        style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
                DataColumn(
                    label: Text('Resources',
                        style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
              ],
              rows: rows
                  .map((r) => DataRow(cells: [
                        DataCell(Text(r.id,
                            style: const TextStyle(
                                color: Color(0xFF495057),
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold))),
                        DataCell(Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: Color(r.domainColor),
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(r.name,
                                style: const TextStyle(
                                    color: Color(0xFF1A1D1F),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ],
                        )),
                        DataCell(Text(r.duration,
                            style: const TextStyle(
                                color: Color(0xFF495057), fontSize: 12))),
                        DataCell(Text(r.start,
                            style: const TextStyle(
                                color: Color(0xFF495057), fontSize: 12))),
                        DataCell(Text(r.finish,
                            style: const TextStyle(
                                color: Color(0xFF495057), fontSize: 12))),
                        DataCell(Text(r.predecessors,
                            style: const TextStyle(
                                color: Color(0xFF495057),
                                fontSize: 11,
                                fontFamily: 'monospace'))),
                        DataCell(Text(r.resources,
                            style: const TextStyle(
                                color: Color(0xFF495057), fontSize: 12))),
                      ]))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<_SampleRow> _sampleRows(String projectName, String deliveryModel) {
    return [
      _SampleRow('1', 'Engineering — Process Design', '20 d', '01/06/26',
          '01/30/26', '—', 'Process Eng (2)', ScheduleDomain.engineering.color),
      _SampleRow('2', 'Procurement — Long-Lead Vessels', '45 d', '02/02/26',
          '03/20/26', '1FS', 'Buyer, Expediter', ScheduleDomain.procurement.color),
      _SampleRow('3', 'Execution — Fabrication Phase A', '60 d', '03/23/26',
          '05/22/26', '2FS', 'Fab Shop (6)', ScheduleDomain.execution.color),
      _SampleRow('4', 'Construction — Site Mobilization', '10 d', '05/25/26',
          '06/05/26', '3FS-5d', 'Site Sup (3)', ScheduleDomain.construction.color),
      _SampleRow('5', 'Construction — Mechanical Install', '35 d', '06/08/26',
          '07/17/26', '4FS', 'Mech Crew (8)', ScheduleDomain.construction.color),
      _SampleRow('6', 'Commissioning — Cold Commissioning', '15 d', '07/20/26',
          '08/07/26', '5FS', 'Commissioning Eng (2)', ScheduleDomain.commissioning.color),
      _SampleRow('7', 'Commissioning — Hot Commissioning & Handover', '12 d',
          '08/10/26', '08/22/26', '6FS', 'Commissioning Eng (2)', ScheduleDomain.commissioning.color),
    ];
  }
}

class _SampleRow {
  final String id;
  final String name;
  final String duration;
  final String start;
  final String finish;
  final String predecessors;
  final String resources;
  final int domainColor;
  const _SampleRow(this.id, this.name, this.duration, this.start, this.finish,
      this.predecessors, this.resources, this.domainColor);
}

/// "Drawing from" context banner shown at the top of the Schedule Builder.
///
/// Surfaces a one-line summary of the upstream Planning Phase data this page
/// is consuming — the WBS (with deliverable + sub-deliverable counts) and
/// the Cost Estimate total. Uses a soft accent-tinted surface so it sits
/// naturally between the level-convention card and the activity tree.
class _DrawingFromBanner extends StatelessWidget {
  final WBS? wbs;
  final ({int level0, int level1, int level2})? wbsCounts;
  final double costTotal;
  final String currency;
  final bool hasEstimate;

  const _DrawingFromBanner({
    required this.wbs,
    required this.wbsCounts,
    required this.costTotal,
    required this.currency,
    required this.hasEstimate,
  });

  @override
  Widget build(BuildContext context) {
    final hasWbs = wbs != null && wbsCounts != null;
    final l1Label = wbs?.framework.level1Label ?? 'deliverables';
    final l2Label = wbs?.framework.level2Label ?? 'sub-deliverables';
    final l1Count = wbsCounts?.level1 ?? 0;
    final l2Count = wbsCounts?.level2 ?? 0;

    final parts = <String>[];
    if (hasWbs) {
      parts.add(
          'WBS ($l1Count $l1Label, $l2Count $l2Label)');
    }
    if (hasEstimate) {
      parts.add('Cost Estimate (${formatCurrency(costTotal, currency)})');
    }
    if (parts.isEmpty) {
      // Nothing to draw from yet — show a gentle hint instead.
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LightModeColors.accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: LightModeColors.accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 16, color: LightModeColors.accent.withValues(alpha: 0.9)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No WBS or Cost Estimate data found yet. Set up the WBS and Cost Estimate modules first to enrich the schedule context.',
                style: TextStyle(
                    color: const Color(0xFF495057),
                    fontSize: 12,
                    height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LightModeColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: LightModeColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.input,
              size: 16, color: LightModeColors.accent.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Color(0xFF495057),
                    fontSize: 12,
                    height: 1.5,
                    fontFamily: appFontFamily),
                children: [
                  const TextSpan(
                    text: 'Drawing from: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: parts.join(' and ')),
                  const TextSpan(
                    text:
                        ' — activities you add here should map to WBS nodes and consume the cost budget above.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
