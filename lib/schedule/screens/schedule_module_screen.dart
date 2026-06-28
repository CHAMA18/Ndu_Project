/// Schedule Module Screen — main entry point for the Schedule module.
///
/// Left-rail navigation between 9 sub-modules:
///   Basis · Builder · Gantt · List · Dependencies · SME Review · Import/Export · Estimate Basis · Cost Linkage

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/schedule/models/schedule_models.dart';
import 'package:ndu_project/schedule/providers/schedule_provider.dart';
import 'package:ndu_project/schedule/screens/setup_wizard_screen.dart';
import 'package:ndu_project/schedule/screens/builder_screen.dart';
import 'package:ndu_project/schedule/screens/gantt_screen.dart';
import 'package:ndu_project/schedule/screens/list_view_screen.dart';

class ScheduleModuleScreen extends StatefulWidget {
  const ScheduleModuleScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScheduleModuleScreen()),
    );
  }

  @override
  State<ScheduleModuleScreen> createState() => _ScheduleModuleScreenState();
}

class _ScheduleModuleScreenState extends State<ScheduleModuleScreen> {
  _SubModule _active = _SubModule.builder;

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        final schedule = provider.schedule;

        if (schedule == null || !provider.setupComplete) {
          return const SetupWizardScreen();
        }

        return Scaffold(
          backgroundColor: const Color(0xFF051424),
          body: Row(
            children: [
              _buildLeftRail(context, provider, schedule),
              Expanded(child: _buildMainContent(context, provider, schedule)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeftRail(BuildContext context, ScheduleProvider provider, Schedule schedule) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1C2D),
        border: Border(right: BorderSide(color: Color(0xFF46464C), width: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SCHEDULE', style: TextStyle(color: Color(0xFF909096), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(schedule.projectName, style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Wrap(spacing: 4, runSpacing: 4, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF273647), borderRadius: BorderRadius.circular(10)), child: Text(schedule.basis.deliveryModel, style: const TextStyle(color: Color(0xFFC7C6CC), fontSize: 10, fontWeight: FontWeight.w600))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF273647), borderRadius: BorderRadius.circular(10)), child: Text(schedule.status.label, style: const TextStyle(color: Color(0xFFC7C6CC), fontSize: 10, fontWeight: FontWeight.w600))),
                ]),
              ],
            ),
          ),
          const Divider(color: Color(0xFF46464C), height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _SubModule.values.map((m) {
                final isActive = _active == m;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _active = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: isActive ? const Color(0xFFF8BD2A).withValues(alpha: 0.1) : Colors.transparent),
                      child: Row(children: [
                        Icon(m.icon, size: 18, color: isActive ? const Color(0xFFF8BD2A) : const Color(0xFFC7C6CC)),
                        const SizedBox(width: 10),
                        Text(m.label, style: TextStyle(color: isActive ? const Color(0xFFF8BD2A) : const Color(0xFFC7C6CC), fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ScheduleProvider provider, Schedule schedule) {
    return switch (_active) {
      _SubModule.builder => const BuilderScreen(),
      _SubModule.gantt => const GanttScreen(),
      _SubModule.list => const ListViewScreen(),
      _ => _ComingSoon(label: _active.label),
    };
  }
}

enum _SubModule {
  basis, builder, gantt, list, dependencies, review, importExport, estimateBasis, linkage;

  String get label => switch (this) {
        _SubModule.basis => 'Schedule Basis',
        _SubModule.builder => 'Builder',
        _SubModule.gantt => 'Gantt Chart',
        _SubModule.list => 'List View',
        _SubModule.dependencies => 'Dependencies',
        _SubModule.review => 'SME Review',
        _SubModule.importExport => 'Import / Export',
        _SubModule.estimateBasis => 'Estimate Basis',
        _SubModule.linkage => 'Cost Linkage',
      };

  IconData get icon => switch (this) {
        _SubModule.basis => Icons.calendar_today,
        _SubModule.builder => Icons.folder_open,
        _SubModule.gantt => Icons.bar_chart,
        _SubModule.list => Icons.list,
        _SubModule.dependencies => Icons.account_tree,
        _SubModule.review => Icons.checklist,
        _SubModule.importExport => Icons.swap_horiz,
        _SubModule.estimateBasis => Icons.description,
        _SubModule.linkage => Icons.trending_up,
      };
}

class _ComingSoon extends StatelessWidget {
  final String label;
  const _ComingSoon({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, color: Color(0xFFF8BD2A), size: 48),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Coming soon', style: TextStyle(color: Color(0xFF909096), fontSize: 14)),
        ],
      ),
    );
  }
}
