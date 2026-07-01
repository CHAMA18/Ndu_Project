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
///
/// A subtle [ContextBanner] is shown between the [SectionNavigator] and the
/// tab content summarising upstream context (project name, WBS framework and
/// deliverable count, solutions count) so the user can see what data this
/// page is drawing from.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/section_navigator.dart';
import 'package:ndu_project/widgets/context_banner.dart';
import 'package:ndu_project/cost_estimate/providers/cost_estimate_provider.dart';
import 'package:ndu_project/cost_estimate/models/cost_estimate_models.dart';
import 'package:ndu_project/cost_estimate/screens/setup_wizard_screen.dart';
import 'package:ndu_project/cost_estimate/screens/builder_screen.dart';
import 'package:ndu_project/cost_estimate/screens/boe_screen.dart';
import 'package:ndu_project/cost_estimate/screens/ai_assistant_screen.dart';
import 'package:ndu_project/cost_estimate/screens/stakeholders_screen.dart';
import 'package:ndu_project/cost_estimate/screens/accounting_screen.dart';
import 'package:ndu_project/cost_estimate/screens/review_screen.dart';
import 'package:ndu_project/cost_estimate/screens/baseline_screen.dart';
import 'package:ndu_project/cost_estimate/screens/variance_screen.dart';
import 'package:ndu_project/wbs/providers/wbs_provider.dart';
import 'package:ndu_project/wbs/models/wbs_models.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

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
  void initState() {
    super.initState();
    _tabController.addListener(_onTabChanged);
    // Auto-complete setup with defaults so the user goes straight to the
    // Cost Estimate dashboard without seeing the setup wizard. The project
    // name is read from the central ProjectDataHelper (which captures the
    // name from the Initiation Phase's ProjectDataModel) — falling back to
    // 'My Project' when no name has been captured yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<CostEstimateProvider>();
      if (provider.estimate == null || !provider.setupComplete) {
        final projectName =
            ProjectDataHelper.readProjectNameFromContext(context) ??
                'My Project';
        provider.setup(
          projectName: projectName,
          className: EstimateClass.class3,
          deliveryModel: DeliveryModel.waterfall,
        );
      }
    });
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
    return Consumer3<CostEstimateProvider, WBSProvider, ProjectDataProvider>(
      builder: (context, provider, wbsProvider, projectProvider, _) {
        final estimate = provider.estimate;

        // Setup state — show the setup wizard (which itself uses
        // ResponsiveScaffold so the sidebar stays visible).
        if (estimate == null || !provider.setupComplete) {
          return const SetupWizardScreen();
        }

        // ---- Context banner data ----
        final projectData = projectProvider.projectData;
        final projectName = (projectData.projectName).trim().isNotEmpty
            ? projectData.projectName
            : estimate.projectName;
        final solutionsCount = projectData.potentialSolutions.length;
        final wbs = wbsProvider.wbs;
        final wbsCounts = wbs != null ? countNodes(wbs) : null;
        final wbsFrameworkLabel = wbs?.framework.label;
        final wbsDeliverableWord =
            wbs?.framework.level1Label ?? 'deliverables';

        return ResponsiveScaffold(
          activeItemLabel: 'Cost Estimate',
          appBarTitle: 'Cost Estimate',
          breadcrumbPhase: 'Planning Phase',
          breadcrumbTitle: 'Cost Estimate',
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // ── World-class Section Navigator ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SectionNavigator(
                  title: 'Cost Estimate Navigation',
                  subtitle: 'Navigate between cost estimate sections',
                  icon: Icons.attach_money_outlined,
                  tabs: [
                    SectionTab(icon: Icons.build_outlined, label: 'Builder'),
                    SectionTab(icon: Icons.description_outlined, label: 'BOE'),
                    SectionTab(icon: Icons.auto_awesome, label: 'AI'),
                    SectionTab(icon: Icons.people_outline, label: 'Stakeholders'),
                    SectionTab(icon: Icons.account_balance_outlined, label: 'Accounting'),
                    SectionTab(icon: Icons.check_circle_outline, label: 'Review'),
                    SectionTab(icon: Icons.lock_outline, label: 'Baseline'),
                    SectionTab(icon: Icons.trending_up, label: 'Variance'),
                  ],
                  controller: _tabController,
                  onChanged: (index) => setState(() {}),
                ),
              ),
              // ── Context banner (drawn from Initiation + WBS) ──────────
              ContextBanner(
                storageKey: 'cost_estimate_module_context_banner',
                items: [
                  ContextBannerItem(
                    label: 'Project',
                    value: projectName,
                    icon: Icons.flag_outlined,
                  ),
                  if (wbs != null && wbsCounts != null)
                    ContextBannerItem(
                      label: 'WBS',
                      value:
                          '${wbsFrameworkLabel ?? 'WBS'} · ${wbsCounts.level1} $wbsDeliverableWord',
                      icon: Icons.account_tree_outlined,
                    ),
                  ContextBannerItem(
                    label: 'Solutions',
                    value: '$solutionsCount potential',
                    icon: Icons.lightbulb_outline,
                  ),
                ],
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
