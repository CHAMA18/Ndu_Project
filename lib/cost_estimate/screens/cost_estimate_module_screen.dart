library;

/// Cost Estimate Module Screen — main entry point for the Cost Estimate module.
///
/// Uses [ResponsiveScaffold] with the standard app sidebar
/// (`InitiationLikeSidebar`) so it matches the rest of the app.
///
/// Sub-navigation between Builder / BOE / AI / Stakeholders / Accounting /
/// Review / Baseline / Variance is a horizontal `TabBar` at the top of the
/// content area (light-mode pills matching the Project Controls screen),
/// replacing the old dark navy left rail.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/cost_estimate/providers/cost_estimate_provider.dart';
import 'package:ndu_project/cost_estimate/screens/setup_wizard_screen.dart';
import 'package:ndu_project/cost_estimate/screens/builder_screen.dart';
import 'package:ndu_project/cost_estimate/screens/boe_screen.dart';
import 'package:ndu_project/cost_estimate/screens/ai_assistant_screen.dart';
import 'package:ndu_project/cost_estimate/screens/stakeholders_screen.dart';
import 'package:ndu_project/cost_estimate/screens/accounting_screen.dart';
import 'package:ndu_project/cost_estimate/screens/review_screen.dart';
import 'package:ndu_project/cost_estimate/screens/baseline_screen.dart';
import 'package:ndu_project/cost_estimate/screens/variance_screen.dart';

class CostEstimateModuleScreen extends StatefulWidget {
  const CostEstimateModuleScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CostEstimateModuleScreen()),
    );
  }

  @override
  State<CostEstimateModuleScreen> createState() =>
      _CostEstimateModuleScreenState();
}

class _CostEstimateModuleScreenState extends State<CostEstimateModuleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 8,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CostEstimateProvider>(
      builder: (context, provider, _) {
        final estimate = provider.estimate;

        // Setup state — show the setup wizard (which itself uses
        // ResponsiveScaffold so the sidebar stays visible).
        if (estimate == null || !provider.setupComplete) {
          return const SetupWizardScreen();
        }

        return ResponsiveScaffold(
          activeItemLabel: 'Cost Estimate',
          appBarTitle: 'Cost Estimate',
          breadcrumbPhase: 'Planning Phase',
          breadcrumbTitle: 'Cost Estimate',
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Horizontal sub-tab bar (replaces the dark left rail)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: LightModeColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: LightModeColors.lightOnPrimary,
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  tabs: const [
                    Tab(text: 'Builder'),
                    Tab(text: 'BOE'),
                    Tab(text: 'AI'),
                    Tab(text: 'Stakeholders'),
                    Tab(text: 'Accounting'),
                    Tab(text: 'Review'),
                    Tab(text: 'Baseline'),
                    Tab(text: 'Variance'),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    BuilderScreen(),
                    BOEScreen(),
                    AIAssistantScreen(),
                    StakeholdersScreen(),
                    AccountingScreen(),
                    ReviewScreen(),
                    BaselineScreen(),
                    VarianceScreen(),
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
