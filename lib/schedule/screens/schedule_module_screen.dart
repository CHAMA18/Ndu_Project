library;

/// Schedule Module Screen — main entry point for the Schedule module.
///
/// Uses [ResponsiveScaffold] with the standard app sidebar
/// (`InitiationLikeSidebar`) so it matches the rest of the app.
///
/// Sub-navigation between Builder / Gantt / List View is a horizontal
/// `TabBar` at the top of the content area (light-mode pills matching the
/// Project Controls screen), replacing the old dark navy left rail.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/section_navigator.dart';
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

class _ScheduleModuleScreenState extends State<ScheduleModuleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        final schedule = provider.schedule;

        // Setup state — show the setup wizard (which itself uses
        // ResponsiveScaffold so the sidebar stays visible).
        if (schedule == null || !provider.setupComplete) {
          return const SetupWizardScreen();
        }

        return ResponsiveScaffold(
          activeItemLabel: 'Schedule',
          appBarTitle: 'Schedule',
          breadcrumbPhase: 'Planning Phase',
          breadcrumbTitle: 'Schedule',
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // ── World-class Section Navigator ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SectionNavigator(
                  title: 'Schedule Navigation',
                  subtitle: 'Navigate between schedule sections',
                  icon: Icons.calendar_month_outlined,
                  tabs: [
                    SectionTab(icon: Icons.build_outlined, label: 'Builder'),
                    SectionTab(icon: Icons.bar_chart, label: 'Gantt'),
                    SectionTab(icon: Icons.list_alt, label: 'List View'),
                  ],
                  controller: _tabController,
                  onChanged: (index) => setState(() {}),
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    BuilderScreen(),
                    GanttScreen(),
                    ListViewScreen(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
