/// List View Screen — flat sortable/filterable table of all activities.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/schedule/models/schedule_models.dart';
import 'package:ndu_project/schedule/providers/schedule_provider.dart';

class ListViewScreen extends StatelessWidget {
  const ListViewScreen({super.key});

  List<ScheduleActivity> _flatten(ScheduleActivity node) {
    final result = <ScheduleActivity>[node];
    for (final c in node.children) result.addAll(_flatten(c));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        final schedule = provider.schedule!;
        final root = schedule.activities[0];
        final allActivities = _flatten(root).where((a) => a.level > 0).toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.list, color: Color(0xFFF8BD2A), size: 20), const SizedBox(width: 8), Text('List View — ${schedule.projectName}', style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 20, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 4),
            Text('${allActivities.length} activities', style: const TextStyle(color: Color(0xFF909096), fontSize: 13)),
            const SizedBox(height: 16),
            allActivities.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(48), child: Text('No activities yet.', style: TextStyle(color: Color(0xFF909096), fontSize: 14))))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFF0D1C2D)),
                      dataRowColor: WidgetStateProperty.all(Colors.transparent),
                      columns: const [
                        DataColumn(label: Text('Code', style: TextStyle(color: Color(0xFF909096), fontSize: 12))),
                        DataColumn(label: Text('Name', style: TextStyle(color: Color(0xFF909096), fontSize: 12))),
                        DataColumn(label: Text('Lvl', style: TextStyle(color: Color(0xFF909096), fontSize: 12))),
                        DataColumn(label: Text('Domain', style: TextStyle(color: Color(0xFF909096), fontSize: 12))),
                        DataColumn(label: Text('Duration', style: TextStyle(color: Color(0xFF909096), fontSize: 12))),
                        DataColumn(label: Text('Owner', style: TextStyle(color: Color(0xFF909096), fontSize: 12))),
                        DataColumn(label: Text('Status', style: TextStyle(color: Color(0xFF909096), fontSize: 12))),
                      ],
                      rows: allActivities.map((a) => DataRow(cells: [
                        DataCell(Text(a.code, style: const TextStyle(color: Color(0xFF909096), fontSize: 11, fontFamily: 'monospace'))),
                        DataCell(Text(a.name, style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 13))),
                        DataCell(Text('${a.level}', style: const TextStyle(color: Color(0xFFC7C6CC)))),
                        DataCell(Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: Color(a.domain.color), shape: BoxShape.circle)), const SizedBox(width: 4), Text(a.domain.label, style: const TextStyle(color: Color(0xFFC7C6CC), fontSize: 11))])),
                        DataCell(Text(formatDuration(a.duration, a.durationUnit), style: const TextStyle(color: Color(0xFFC7C6CC), fontSize: 12))),
                        DataCell(Text(a.owner ?? '—', style: const TextStyle(color: Color(0xFFC7C6CC), fontSize: 12))),
                        DataCell(Text(a.status ?? '—', style: const TextStyle(color: Color(0xFFC7C6CC), fontSize: 12))),
                      ])).toList(),
                    ),
                  ),
          ]),
        );
      },
    );
  }
}
