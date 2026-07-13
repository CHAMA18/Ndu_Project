library;

/// Gantt Chart Screen — dual-panel (activity list + timeline bars).
///
/// Rendered inside the parent module's `ResponsiveScaffold` body — no
/// per-screen Scaffold wrapper (parent provides white background). Color-coded
/// by domain. Includes a sample activity dataset so the Gantt visualization is
/// always populated for demonstration.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/schedule/models/schedule_models.dart';
import 'package:ndu_project/schedule/providers/schedule_provider.dart';

class GanttScreen extends StatelessWidget {
  const GanttScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        final schedule = provider.schedule!;
        final rows = _sampleRows();
        // Timeline: 16 weeks (Jan 5 → Apr 26, 2026) — covers all bars.
        const weekCount = 16;
        final weekLabels = List<String>.generate(weekCount, (i) {
          // Each week starts on a Monday; week 0 = Jan 5, 2026.
          final start = DateTime(2026, 1, 5).add(Duration(days: i * 7));
          final m = start.month.toString().padLeft(2, '0');
          final d = start.day.toString().padLeft(2, '0');
          return '$m/$d';
        });
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.bar_chart,
                      color: LightModeColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('Gantt Chart — ${schedule.projectName}',
                        style: const TextStyle(
                            color: Color(0xFF1A1D1F),
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Sample timeline view — bars are color-coded by domain and laid out across a 16-week rolling window.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Legend + summary chips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    ...ScheduleDomain.values.map((d) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: Color(d.color),
                                  borderRadius: BorderRadius.circular(2)),
                            ),
                            const SizedBox(width: 4),
                            Text(d.label,
                                style: const TextStyle(
                                    color: Color(0xFF495057), fontSize: 11)),
                          ],
                        )),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color:
                                  LightModeColors.accent.withValues(alpha: 0.3),
                              border: Border.all(
                                  color: LightModeColors.accent, width: 1.5)),
                        ),
                        const SizedBox(width: 4),
                        const Text('Critical path',
                            style: TextStyle(
                                color: Color(0xFF495057), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Gantt panel
              Container(
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline header row
                        _GanttHeaderRow(
                            weekLabels: weekLabels,
                            leftColWidth: 280,
                            cellWidth: 56),
                        const Divider(
                            color: Color(0xFFE4E7EC), height: 1, thickness: 1),
                        // Activity rows
                        ...rows.map((r) => _GanttRow(
                              row: r,
                              weekCount: weekCount,
                              leftColWidth: 280,
                              cellWidth: 56,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Footer summary
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
                    const Icon(Icons.insights,
                        size: 16, color: LightModeColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Critical-path activities (Procurement, Fabrication, Mechanical Install, Cold & Hot Commissioning) form the longest dependency chain. Adding real activities via the Builder tab will replace this sample timeline with your project\'s actual schedule.',
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

  List<_GanttRowData> _sampleRows() {
    // weekStart and weekDuration are expressed in 7-day units; week 0 = Jan 5, 2026.
    return [
      _GanttRowData(
        code: '1',
        name: 'Engineering — Process Design',
        domainColor: ScheduleDomain.engineering.color,
        weekStart: 0,
        weekDuration: 4,
        isCritical: false,
      ),
      _GanttRowData(
        code: '2',
        name: 'Procurement — Long-Lead Vessels',
        domainColor: ScheduleDomain.procurement.color,
        weekStart: 4,
        weekDuration: 9,
        isCritical: true,
      ),
      _GanttRowData(
        code: '3',
        name: 'Execution — Fabrication Phase A',
        domainColor: ScheduleDomain.execution.color,
        weekStart: 9,
        weekDuration: 12,
        isCritical: true,
      ),
      _GanttRowData(
        code: '4',
        name: 'Construction — Site Mobilization',
        domainColor: ScheduleDomain.construction.color,
        weekStart: 12,
        weekDuration: 2,
        isCritical: false,
      ),
      _GanttRowData(
        code: '5',
        name: 'Construction — Mechanical Install',
        domainColor: ScheduleDomain.construction.color,
        weekStart: 14,
        weekDuration: 7,
        isCritical: true,
      ),
      _GanttRowData(
        code: '6',
        name: 'Commissioning — Cold Commissioning',
        domainColor: ScheduleDomain.commissioning.color,
        weekStart: 21,
        weekDuration: 3,
        isCritical: true,
      ),
      _GanttRowData(
        code: '7',
        name: 'Commissioning — Hot Commissioning & Handover',
        domainColor: ScheduleDomain.commissioning.color,
        weekStart: 24,
        weekDuration: 3,
        isCritical: true,
      ),
    ];
  }
}

/// Timeline header row — fixed-width activity column + weekly grid cells.
class _GanttHeaderRow extends StatelessWidget {
  final List<String> weekLabels;
  final double leftColWidth;
  final double cellWidth;

  const _GanttHeaderRow({
    required this.weekLabels,
    required this.leftColWidth,
    required this.cellWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: leftColWidth,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            border: Border(
                right: BorderSide(color: Color(0xFFE4E7EC), width: 1)),
          ),
          child: const Text('Activity',
              style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        ),
        ...weekLabels.map((label) => Container(
              width: cellWidth,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(
                    right: BorderSide(color: Color(0xFFE4E7EC), width: 0.5)),
              ),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 10,
                      fontFamily: appFontFamily)),
            )),
      ],
    );
  }
}

/// Single activity row — fixed-width label column + Gantt bar across the grid.
class _GanttRow extends StatelessWidget {
  final _GanttRowData row;
  final int weekCount;
  final double leftColWidth;
  final double cellWidth;

  const _GanttRow({
    required this.row,
    required this.weekCount,
    required this.leftColWidth,
    required this.cellWidth,
  });

  @override
  Widget build(BuildContext context) {
    final timelineWidth = weekCount * cellWidth;
    return Column(
      children: [
        Row(
          children: [
            // Activity label column
            Container(
              width: leftColWidth,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                    right: BorderSide(color: Color(0xFFE4E7EC), width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: Color(row.domainColor),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(row.code,
                      style: const TextStyle(
                          color: Color(0xFF495057),
                          fontSize: 10,
                          fontFamily: appFontFamily,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(row.name,
                        style: const TextStyle(
                            color: Color(0xFF1A1D1F),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            // Timeline + bar
            Container(
              width: timelineWidth,
              height: 36,
              color: Colors.white,
              child: Stack(
                children: [
                  // Grid vertical lines
                  ...List.generate(weekCount + 1, (i) {
                    return Positioned(
                      left: i * cellWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 0.5,
                        color: const Color(0xFFE4E7EC),
                      ),
                    );
                  }),
                  // Gantt bar
                  Positioned(
                    left: row.weekStart * cellWidth + 2,
                    top: 8,
                    bottom: 8,
                    width: (row.weekDuration * cellWidth) - 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: row.isCritical
                            ? Color(row.domainColor).withValues(alpha: 0.85)
                            : Color(row.domainColor).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: row.isCritical
                              ? LightModeColors.accent
                              : Color(row.domainColor),
                          width: row.isCritical ? 1.5 : 0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${row.weekDuration}w',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(color: Color(0xFFE4E7EC), height: 1, thickness: 0.5),
      ],
    );
  }
}

class _GanttRowData {
  final String code;
  final String name;
  final int domainColor;
  final int weekStart;
  final int weekDuration;
  final bool isCritical;

  const _GanttRowData({
    required this.code,
    required this.name,
    required this.domainColor,
    required this.weekStart,
    required this.weekDuration,
    required this.isCritical,
  });
}
