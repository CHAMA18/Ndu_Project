/// Gantt Chart Screen — dual-panel (WBS tree + timeline bars).
/// Color-coded by domain. Matches Alick's design.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/schedule/models/schedule_models.dart';
import 'package:ndu_project/schedule/providers/schedule_provider.dart';

class GanttScreen extends StatelessWidget {
  const GanttScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        final schedule = provider.schedule!;
        final root = schedule.activities[0];
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.bar_chart, color: Color(0xFFF8BD2A), size: 20),
                const SizedBox(width: 8),
                Text('Gantt Chart — ${schedule.projectName}', style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ),
            // Domain legend
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(spacing: 12, children: ScheduleDomain.values.map((d) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(d.color), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 4), Text(d.label, style: const TextStyle(color: Color(0xFFC7C6CC), fontSize: 11))])).toList()),
            ),
            const Divider(color: Color(0xFF46464C), height: 1),
            // Dual-panel
            Expanded(
              child: Row(
                children: [
                  // Left: Activity tree
                  Container(width: 280, decoration: const BoxDecoration(color: Color(0xFF0D1C2D), border: Border(right: BorderSide(color: Color(0xFF46464C), width: 0.5))), child: ListView(children: [_GanttTreeRow(activity: root, isRoot: true, depth: 0)])),
                  // Right: Timeline
                  const Expanded(child: Center(child: Text('Timeline grid with Gantt bars', style: TextStyle(color: Color(0xFF909096), fontSize: 14)))),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GanttTreeRow extends StatelessWidget {
  final ScheduleActivity activity;
  final bool isRoot;
  final int depth;

  const _GanttTreeRow({required this.activity, this.isRoot = false, required this.depth});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(left: depth * 16.0 + 8, top: 6, bottom: 6),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: Color(activity.domain.color), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(activity.code, style: const TextStyle(color: Color(0xFF909096), fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Expanded(child: Text(activity.name, style: TextStyle(color: isRoot ? const Color(0xFFD4E4FA) : const Color(0xFFC7C6CC), fontSize: isRoot ? 13 : 12, fontWeight: isRoot ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis)),
          ]),
        ),
        ...activity.children.map((child) => _GanttTreeRow(activity: child, depth: depth + 1)),
      ],
    );
  }
}
