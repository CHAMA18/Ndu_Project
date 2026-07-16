import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/initiation_phase_screen.dart';
import 'package:ndu_project/screens/project_activities_log_screen.dart';
import 'package:ndu_project/services/dashboard_metrics_service.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/navigation_context_service.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/services/project_service.dart';
import 'package:ndu_project/utils/navigation_route_resolver.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:ndu_project/widgets/compact_action_button.dart';
import 'package:ndu_project/widgets/dashboard_metrics_cards.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';

class ProjectWorkspaceDashboardScreen extends StatefulWidget {
  const ProjectWorkspaceDashboardScreen({
    super.key,
    required this.isBasicPlan,
  });

  final bool isBasicPlan;

  @override
  State<ProjectWorkspaceDashboardScreen> createState() =>
      _ProjectWorkspaceDashboardScreenState();
}

class _ProjectWorkspaceDashboardScreenState
    extends State<ProjectWorkspaceDashboardScreen>
    {

  DashboardMetrics? _metrics;
  bool _loading = true;
  String? _error;

  static const _bg = Color(0xFFFFFFFF);
  static const _surface = Color(0xFFF8FAFC);
  static const _surfaceHigh = Color(0xFFF1F5F9);
  static const _outline = Color(0xFFE2E8F0);
  static const _onSurface = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _gold = Color(0xFFD97706);
  static const _blue = Color(0xFF2563EB);
  static const _emerald = Color(0xFF059669);
  static const _crimson = Color(0xFFDC2626);
  static const _teal = Color(0xFF0F766E);

  bool get _isBasic => widget.isBasicPlan;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final metrics = await DashboardMetricsService.load();
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load workspace dashboard data.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      await FirebaseAuthService.signOut();
      if (mounted) context.go('/');
    }
  }

  Future<void> _openProject(ProjectRecord project) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final provider = ProjectDataInherited.read(context);
      final success = await provider
          .loadFromFirebase(project.id)
          .timeout(const Duration(seconds: 35));
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.lastError ?? 'Unable to open project'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final checkpoint = project.checkpointRoute.isNotEmpty
          ? project.checkpointRoute
          : await ProjectNavigationService.instance.getLastPage(project.id);
      if (!mounted) return;
      final screen = NavigationRouteResolver.resolveCheckpointToScreen(
        checkpoint.isEmpty ? 'initiation' : checkpoint,
        context,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => screen ?? const InitiationPhaseScreen(),
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project load timed out. Please retry.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening project: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    NavigationContextService.instance.setLastClientDashboard(
      '/dashboard',
    );

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<List<ProjectRecord>>(
          stream: FirebaseAuth.instance.currentUser == null
              ? Stream.value(const <ProjectRecord>[])
              : ProjectService.streamProjects(
                  ownerId: FirebaseAuth.instance.currentUser!.uid,
                  filterByOwner: true,
                  limit: 200,
                ),
          builder: (context, snapshot) {
            final allProjects = snapshot.data ?? const <ProjectRecord>[];
            final projects = allProjects
                .where((project) =>
                    _isBasic ? project.isBasicPlanProject : !project.isBasicPlanProject)
                .toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

            final statusesById = {
              for (final status in _metrics?.projectStatuses ?? const <ProjectStatusRollup>[])
                status.projectId: status,
            };
            final rollups = projects
                .map((project) => statusesById[project.id])
                .whereType<ProjectStatusRollup>()
                .toList();
            final assigned = (_metrics?.assignedToMe ?? const <AssignedActivity>[])
                .where((activity) =>
                    projects.any((project) => project.id == activity.projectId))
                .toList();
            final pastDue = (_metrics?.pastDue ?? const <AssignedActivity>[])
                .where((activity) =>
                    projects.any((project) => project.id == activity.projectId))
                .toList();

            final onTrack = rollups
                .where((rollup) => rollup.overallStatus == 'on_track')
                .length;
            final atRisk = rollups
                .where((rollup) => rollup.overallStatus == 'at_risk')
                .length;
            final offTrack = rollups
                .where((rollup) => rollup.overallStatus == 'off_track')
                .length;
            final avgProgress = projects.isEmpty
                ? 0.0
                : projects.fold<double>(0, (total, project) {
                      return total + project.progressSnapshot.completion;
                    }) /
                    projects.length;
            final totalBudget = projects.fold<double>(
              0,
              (total, project) => total + project.investmentMillions,
            );
            final totalMilestones = projects.fold<int>(
              0,
              (total, project) =>
                  total + project.progressSnapshot.totalMilestones,
            );
            final achievedMilestones = projects.fold<int>(
              0,
              (total, project) =>
                  total + project.progressSnapshot.achievedMilestones,
            );
            final phaseDistribution = <String, int>{};
            for (final project in projects) {
              final phase = project.progressSnapshot.currentPhase;
              phaseDistribution[phase] = (phaseDistribution[phase] ?? 0) + 1;
            }

            return RefreshIndicator(
              onRefresh: _loadMetrics,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 24),
                  _buildHero(
                    projectCount: projects.length,
                    avgProgress: avgProgress,
                    totalBudget: totalBudget,
                    assignedCount: assigned.length,
                  ),
                  const SizedBox(height: 24),
                  if (_loading) ...[
                    const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 20),
                    _sectionCard(
                      title: 'Loading dashboard',
                      subtitle: 'Fetching workspace health, delivery status, and activity rollups.',
                      child: _emptyState('Loading dashboard data...'),
                    ),
                  ] else ...[
                    if (_error != null) ...[
                      _buildBanner(_error!, _crimson),
                      const SizedBox(height: 20),
                    ],
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 1180;
                        final kpis = [
                          _kpiCard(
                            'Workspaces',
                            '${projects.length}',
                            _isBasic ? 'Basic plan projects' : 'Standard projects',
                            _isBasic ? _teal : _blue,
                            Icons.workspaces_outline,
                          ),
                          _kpiCard(
                            'On Track',
                            '$onTrack',
                            '$atRisk at risk, $offTrack off track',
                            _emerald,
                            Icons.health_and_safety_outlined,
                          ),
                          _kpiCard(
                            'Milestones',
                            '$achievedMilestones/$totalMilestones',
                            'Achieved across all workspaces',
                            _gold,
                            Icons.flag_outlined,
                          ),
                          _kpiCard(
                            'Assigned To Me',
                            '${assigned.length}',
                            '${pastDue.length} currently overdue',
                            _crimson,
                            Icons.assignment_ind_outlined,
                          ),
                        ];
                        if (stacked) {
                          return Column(
                            children: [
                              for (int i = 0; i < kpis.length; i++) ...[
                                kpis[i],
                                if (i != kpis.length - 1)
                                  const SizedBox(height: 14),
                              ],
                            ],
                          );
                        }
                        return Row(
                          children: [
                            for (int i = 0; i < kpis.length; i++) ...[
                              Expanded(child: kpis[i]),
                              if (i != kpis.length - 1)
                                const SizedBox(width: 14),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 1100;
                        final left = _sectionCard(
                          title: 'Workspace Health',
                          subtitle: 'Live status rollups across schedule, cost, scope, quality, and risk.',
                          child: rollups.isEmpty
                              ? _emptyState('No project status rollups available yet.')
                              : Column(
                                  children: [
                                    for (int i = 0; i < rollups.take(6).length; i++) ...[
                                      ProjectMetricsCard(
                                        rollup: rollups[i],
                                        level: _isBasic ? 'Regular Project' : 'Project',
                                        onTap: () {
                                          final project = projects.firstWhere(
                                            (item) => item.id == rollups[i].projectId,
                                          );
                                          _openProject(project);
                                        },
                                      ),
                                      if (i != rollups.take(6).length - 1)
                                        const SizedBox(height: 12),
                                    ],
                                  ],
                                ),
                        );
                        final right = _sectionCard(
                          title: 'Phase Distribution',
                          subtitle: 'How these workspaces are currently spread across delivery phases.',
                          child: phaseDistribution.isEmpty
                              ? _emptyState('No phase data available yet.')
                              : Column(
                                  children: phaseDistribution.entries.map((entry) {
                                    final pct = projects.isEmpty
                                        ? 0.0
                                        : entry.value / projects.length;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  entry.key,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: _onSurface,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${entry.value}',
                                                style: const TextStyle(
                                                  color: _muted,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(99),
                                            child: LinearProgressIndicator(
                                              minHeight: 10,
                                              value: pct,
                                              backgroundColor: _surfaceHigh,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                _isBasic ? _teal : _blue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        );
                        if (stacked) {
                          return Column(
                            children: [
                              left,
                              const SizedBox(height: 20),
                              right,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: left),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: right),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 1100;
                        final activitiesCard = AssignedActivitiesCard(
                          activities: assigned,
                          title: _isBasic
                              ? 'Assigned within regular projects'
                              : 'Assigned within projects',
                          maxRows: 6,
                        );
                        final dueCard = PastDueActivitiesCard(
                          activities: pastDue,
                          maxRows: 6,
                        );
                        if (stacked) {
                          return Column(
                            children: [
                              activitiesCard,
                              const SizedBox(height: 20),
                              dueCard,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: activitiesCard),
                            const SizedBox(width: 20),
                            Expanded(child: dueCard),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _sectionCard(
                      title: _isBasic
                          ? 'Regular Project Workspaces'
                          : 'Project Workspaces',
                      subtitle: 'Most recent workspaces with quick access back into execution.',
                      child: projects.isEmpty
                          ? _emptyState('No workspaces available yet.')
                          : Column(
                              children: [
                                for (int i = 0; i < projects.take(8).length; i++) ...[
                                  _workspaceRow(projects[i]),
                                  if (i != projects.take(8).length - 1)
                                    const Divider(height: 24, color: _outline),
                                ],
                              ],
                            ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: const KazAiChatBubble(),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const AppLogo(height: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isBasic ? 'Regular Project Dashboard' : 'Project Dashboard',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _onSurface,
                ),
              ),
              Text(
                _isBasic
                    ? 'Basic plan workspaces with portfolio-style rollups.'
                    : 'Active project workspaces with program-style delivery visibility.',
                style: const TextStyle(fontSize: 13, color: _muted),
              ),
            ],
          ),
        ),
        CompactActionButton(
          label: 'Activity Log',
          subtitle: 'Open the unified activity tracker',
          icon: Icons.fact_check_outlined,
          accent: _gold,
          onTap: () => ProjectActivitiesLogScreen.open(context),
        ),
        const SizedBox(width: 10),
        CompactActionButton(
          label: 'Log Out',
          subtitle: 'Sign out of this workspace',
          icon: Icons.logout_rounded,
          accent: _crimson,
          onTap: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildHero({
    required int projectCount,
    required double avgProgress,
    required double totalBudget,
    required int assignedCount,
  }) {
    final gradient = _isBasic
        ? const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFF5EEAD4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6), Color(0xFF93C5FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 900;
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _isBasic ? 'REGULAR PROJECTS' : 'PROJECTS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isBasic
                    ? 'Track initiation-first workspaces with executive-level clarity.'
                    : 'Monitor live project delivery with the same dashboard language as programs and portfolios.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use this view to review progress, health, assigned work, and milestone movement across the selected workspace tier.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          );
          final stats = Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _heroMetric('Workspaces', '$projectCount'),
              _heroMetric('Avg Progress', '${(avgProgress * 100).round()}%'),
              _heroMetric('Budget', _formatMoney(totalBudget)),
              _heroMetric('Assigned', '$assignedCount'),
            ],
          );
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                summary,
                const SizedBox(height: 20),
                stats,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: summary),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: Align(alignment: Alignment.topRight, child: stats)),
            ],
          );
        },
      ),
    );
  }

  Widget _heroMetric(String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
    String label,
    String value,
    String subtitle,
    Color accent,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12.5, color: _muted, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: _muted, height: 1.5),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _workspaceRow(ProjectRecord project) {
    final statusColor = switch (project.progressSnapshot.health) {
      ProjectProgressHealth.completed => _emerald,
      ProjectProgressHealth.onTrack => _blue,
      ProjectProgressHealth.behind => _crimson,
      ProjectProgressHealth.inProgress => _gold,
    };
    return InkWell(
      onTap: () => _openProject(project),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.progressSnapshot.currentPhase} · ${project.progressSnapshot.completionPercent}% complete',
                    style: const TextStyle(fontSize: 12.5, color: _muted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  project.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  project.milestone.isEmpty ? 'No milestone set' : project.milestone,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(String message, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: TextStyle(color: accent, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 34, color: Colors.grey.shade500),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13.5),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double millions) {
    if (millions <= 0) return '\$0';
    if (millions >= 1000) return '\$${(millions / 1000).toStringAsFixed(1)}B';
    if (millions >= 1) return '\$${millions.toStringAsFixed(1)}M';
    return '\$${(millions * 1000).toStringAsFixed(0)}K';
  }
}
