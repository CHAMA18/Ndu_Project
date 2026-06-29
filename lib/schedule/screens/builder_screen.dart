/// Builder Screen — decompose WBS into a multi-level schedule.
/// Activity tree (Level 0→8) with add/edit/delete/reorder.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/schedule/models/schedule_models.dart';
import 'package:ndu_project/schedule/providers/schedule_provider.dart';

class BuilderScreen extends StatelessWidget {
  const BuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        final schedule = provider.schedule!;
        final root = schedule.activities[0];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.folder_open, color: Color(0xFFF8BD2A), size: 20), const SizedBox(width: 8), Text(schedule.projectName, style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 20, fontWeight: FontWeight.bold))]),
                  Text('${schedule.basis.deliveryModel} · ${root.children.length} Level 1 activities', style: const TextStyle(color: Color(0xFF909096), fontSize: 13)),
                ]),
                FilledButton.icon(
                  onPressed: schedule.isLocked ? null : () => _showAddDialog(context, provider, root.id, 1),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Activity'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF8BD2A), foregroundColor: const Color(0xFF402D00)),
                ),
              ]),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF1C2B3C), borderRadius: BorderRadius.circular(8)), child: const Text('Schedule levels: L0=Project · L1=Major Deliverable · L2=Epic/Sub-Deliverable · L3=EWP/Procurement/CWP · L4=Activity/Story · L5–8=Task. Decompose until each activity is executable by one person.', style: TextStyle(color: Color(0xFFC7C6CC), fontSize: 12))),
              const SizedBox(height: 24),
              _ActivityNode(activity: root, isRoot: true, provider: provider, isLocked: schedule.isLocked),
              ...root.children.map((child) => _ActivityNode(activity: child, provider: provider, isLocked: schedule.isLocked)),
            ],
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, ScheduleProvider provider, String parentId, int level) {
    final nameCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF0D1C2D),
      title: Text('Add Level $level Activity', style: const TextStyle(color: Color(0xFFD4E4FA))),
      content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Color(0xFF909096))), style: const TextStyle(color: Color(0xFFD4E4FA)), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF909096)))),
        FilledButton(onPressed: () { if (nameCtrl.text.trim().isNotEmpty) { provider.addActivity(parentId, ScheduleActivity(id: '', level: 0, code: '', name: nameCtrl.text.trim(), type: level <= 1 ? ActivityType.summary : ActivityType.activity, domain: ScheduleDomain.engineering, dependencies: [], aiGenerated: false, children: [])); Navigator.pop(ctx); } }, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF8BD2A), foregroundColor: const Color(0xFF402D00)), child: const Text('Add')),
      ],
    ));
  }
}

class _ActivityNode extends StatelessWidget {
  final ScheduleActivity activity;
  final bool isRoot;
  final ScheduleProvider provider;
  final bool isLocked;

  const _ActivityNode({required this.activity, this.isRoot = false, required this.provider, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6, left: isRoot ? 0 : 24),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF1C2B3C), borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: Color(activity.domain.color), width: 3))),
      child: Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF273647), borderRadius: BorderRadius.circular(4)), child: Text(activity.code, style: const TextStyle(color: Color(0xFFC7C6CC), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(activity.domain.color), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(activity.name, style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        if (formatDuration(activity.duration, activity.durationUnit) != '—') Padding(padding: const EdgeInsets.only(left: 8), child: Text(formatDuration(activity.duration, activity.durationUnit), style: const TextStyle(color: Color(0xFF909096), fontSize: 11))),
        if (!isRoot && !isLocked) ...[
          IconButton(icon: const Icon(Icons.add, size: 14, color: Color(0xFF909096)), onPressed: () {}, constraints: const BoxConstraints(), padding: const EdgeInsets.all(4)),
          IconButton(icon: const Icon(Icons.delete_outline, size: 14, color: Color(0xFF909096)), onPressed: () => provider.removeActivity(activity.id), constraints: const BoxConstraints(), padding: const EdgeInsets.all(4)),
        ],
      ]),
    );
  }
}
