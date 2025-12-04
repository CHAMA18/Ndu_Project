import 'package:flutter/material.dart';
import '../widgets/kaz_ai_chat_bubble.dart';
import '../routing/app_router.dart';
import '../services/navigation_context_service.dart';

class PortfolioDashboardScreen extends StatelessWidget {
  const PortfolioDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    NavigationContextService.instance.setLastClientDashboard(AppRoutes.portfolioDashboard);
    return const Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      body: Stack(
        children: [
          SafeArea(
            child: _PortfolioRollUpContent(),
          ),
          KazAiChatBubble(),
        ],
      ),
    );
  }
}

class _PortfolioRollUpContent extends StatelessWidget {
  const _PortfolioRollUpContent();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1000;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderSection(),
              const SizedBox(height: 24),
              if (isNarrow) ...[
                const _ProgramsProjectsCard(),
                const SizedBox(height: 24),
                const _GovernanceReportingCard(),
                const SizedBox(height: 24),
                const _IndependentProjectsCard(),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: const [
                          _ProgramsProjectsCard(),
                          SizedBox(height: 16),
                          _IndependentProjectsCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Expanded(flex: 4, child: _GovernanceReportingCard()),
                  ],
                ),
              const SizedBox(height: 24),
              const _CostScheduleRiskSection(),
              const SizedBox(height: 24),
              const _RollUpUpdateSection(),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE4A0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Text('Roll-up preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade800)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Confirm portfolio roll-up', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1A1D21))),
              const SizedBox(height: 8),
              Text(
                'Review which programs, projects, governance rules, and risks will be rolled up into this portfolio view before publishing it for executives and steering committees.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280), height: 1.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoChip(label: '3 programs', icon: Icons.layers_outlined),
                  _InfoChip(label: '7 projects included', icon: Icons.folder_outlined),
                  _InfoChip(label: 'Total portfolio value: \$18.2M', icon: Icons.attach_money),
                  _InfoChip(label: 'Risk posture: Medium', icon: Icons.shield_outlined),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to portfolio dashboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            Text('Adjust selection of programs, projects, or independent work', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF9CA3AF))),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ProgramsProjectsCard extends StatelessWidget {
  const _ProgramsProjectsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Programs & projects in this roll-up', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Verify which programs and projects will contribute cost, schedule, and risk into the rolled-up portfolio.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                  child: const Text('3 programs · 7 projects', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2563EB))),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('Program', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)))),
                Expanded(flex: 2, child: Text('Projects in scope', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)))),
                Expanded(flex: 1, child: Text('Value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)))),
                Expanded(flex: 1, child: Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)))),
              ],
            ),
          ),
          const _ProgramRow(title: 'Airport capacity uplift', description: 'Improve passenger throughput and on-time performance across terminals.', projects: '3 of 3 projects', value: '\$7.4M', priority: 'Rank 1 · Primary', priorityColor: Color(0xFF10B981)),
          const _ProgramRow(title: 'Control system modernization', description: 'Consolidate legacy control rooms, automation, and monitoring platforms.', projects: '2 of 3 projects', value: '\$6.1M', priority: 'Rank 2 · Growth', priorityColor: Color(0xFF3B82F6)),
          const _ProgramRow(title: 'People & readiness', description: 'Training, change, and readiness initiatives for frontline teams.', projects: '3 of 3 projects', value: '\$4.7M', priority: 'Rank 3 · Enablement', priorityColor: Color(0xFF8B5CF6)),
        ],
      ),
    );
  }
}

class _ProgramRow extends StatelessWidget {
  const _ProgramRow({required this.title, required this.description, required this.projects, required this.value, required this.priority, required this.priorityColor});
  final String title, description, projects, value, priority;
  final Color priorityColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)), child: Text(projects, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF92400E))))),
          Expanded(flex: 1, child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
          Expanded(flex: 1, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(priority, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: priorityColor)))),
        ],
      ),
    );
  }
}

class _IndependentProjectsCard extends StatelessWidget {
  const _IndependentProjectsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Independent projects in roll-up', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)), child: const Text('Related vs. unrelated', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)))),
            ],
          ),
          const SizedBox(height: 8),
          Text('Decide which independent projects should be reflected in this portfolio\'s value and reporting.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
          const SizedBox(height: 16),
          _IndependentProjectRow(title: 'Terminal wayfinding refresh', subtitle: 'Linked to this portfolio. Not assigned to any program.', phase: 'Front-end planning', phaseChips: const ['In-sync', 'Award', 'Vendor Q', 'Authority']),
          const SizedBox(height: 12),
          _IndependentProjectRow(title: 'Regional hub pilot', subtitle: 'Unrelated exploratory project. Outside portfolio targets.', phase: 'Concept stage', phaseChips: const ['Excluded', 'Unrelated']),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(child: Text('Use the related/unrelated flag to control which independent work influences portfolio value and dashboards.', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndependentProjectRow extends StatelessWidget {
  const _IndependentProjectRow({required this.title, required this.subtitle, required this.phase, required this.phaseChips});
  final String title, subtitle, phase;
  final List<String> phaseChips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFDDD6FE), borderRadius: BorderRadius.circular(4)), child: Text(phase, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF7C3AED)))),
        ],
      ),
    );
  }
}

class _GovernanceReportingCard extends StatelessWidget {
  const _GovernanceReportingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Governance & reporting', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), backgroundColor: const Color(0xFFF3F4F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  child: const Text('Portfolio-wide settings', style: TextStyle(fontSize: 12, color: Color(0xFF374151))),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Confirm which approvals, risk registers, and reports will play in-sync across the portfolio.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
          ),
          const SizedBox(height: 16),
          const _GovernanceItem(title: 'Gate approvals', description: 'Use the same approval path for all included projects and stages.', trailing: 'Applies to entire portfolio', isEnabled: true),
          const _GovernanceItem(title: 'Shared risk register', description: 'Surface portfolio-level risks across all work in this roll-up.', trailing: 'Applies to entire portfolio', isEnabled: true),
          const _GovernanceItem(title: 'Common change control', description: 'Route change requests through a single portfolio change board.', trailing: 'Program-specific', isEnabled: false),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Reporting cadence', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF))),
          ),
          const _GovernanceItem(title: 'Executive portfolio summary', description: 'Costs, schedule, risk, and key decisions rolled up.', trailing: 'Weekly', isEnabled: true),
          const _GovernanceItem(title: 'Benefits realization tracker', description: 'Tracks realized vs. planned benefits across all programs.', trailing: 'Monthly', isEnabled: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GovernanceItem extends StatelessWidget {
  const _GovernanceItem({required this.title, required this.description, required this.trailing, required this.isEnabled});
  final String title, description, trailing;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isEnabled ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: isEnabled ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
            child: Text(trailing, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }
}

class _CostScheduleRiskSection extends StatelessWidget {
  const _CostScheduleRiskSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cost, schedule & risk snapshot', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Preview how this roll-up will appear to executives in the live portfolio view, with cost, schedule, and risk broken down by program.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;
              if (isNarrow) {
                return Column(
                  children: const [
                    _PortfolioValueCard(),
                    SizedBox(height: 16),
                    _AggregateScheduleCard(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(child: _PortfolioValueCard()),
                  SizedBox(width: 24),
                  Expanded(child: _AggregateScheduleCard()),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const _RiskPostureSection(),
          const SizedBox(height: 24),
          const _ProjectCostComparison(),
        ],
      ),
    );
  }
}

class _PortfolioValueCard extends StatelessWidget {
  const _PortfolioValueCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total portfolio value', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          const Text('\$18.2M', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 4),
          const Text('3 programs · 7 projects · 1 related standalone', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          Row(
            children: [
              _ValueBreakdown(label: 'Capex', value: '\$10.8M', color: const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _ValueBreakdown(label: 'Opex', value: '\$4.9M', color: const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _ValueBreakdown(label: 'Contingency', value: '15%', color: const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueBreakdown extends StatelessWidget {
  const _ValueBreakdown({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      ],
    );
  }
}

class _AggregateScheduleCard extends StatelessWidget {
  const _AggregateScheduleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aggregate schedule', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          const Text('32 months', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 4),
          const Text('Span by program', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          _ScheduleBar(label: 'Airport capacity uplift', months: '2 - 18 months', progress: 0.9, color: const Color(0xFF10B981)),
          const SizedBox(height: 8),
          _ScheduleBar(label: 'Control system modernization', months: '3 - 14 months', progress: 0.7, color: const Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          _ScheduleBar(label: 'People & readiness', months: '1 - 18 months', progress: 0.85, color: const Color(0xFF3B82F6)),
          const SizedBox(height: 12),
          const Text('Earliest start: Month 1     Critical path: Capacity uplift → Control modernization', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class _ScheduleBar extends StatelessWidget {
  const _ScheduleBar({required this.label, required this.months, required this.progress, required this.color});
  final String label, months;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis)),
            Text(months, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          ),
        ),
      ],
    );
  }
}

class _RiskPostureSection extends StatelessWidget {
  const _RiskPostureSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Risk posture', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const SizedBox(height: 8),
              const Text('Medium', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
              const SizedBox(height: 4),
              const Text('5 high risks · 14 medium · 8 low', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RiskTag(label: 'Scope creep', severity: 'High', color: const Color(0xFFEF4444)),
                  _RiskTag(label: 'Cybersecurity', severity: 'Medium', color: const Color(0xFFF59E0B)),
                  _RiskTag(label: 'Vendor performance', severity: 'Medium', color: const Color(0xFFF59E0B)),
                  _RiskTag(label: 'Change adoption', severity: 'Low', color: const Color(0xFF10B981)),
                  _RiskTag(label: 'Training coverage', severity: 'Low', color: const Color(0xFF10B981)),
                  _RiskTag(label: 'Retention', severity: 'Low', color: const Color(0xFF10B981)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Control system modernization', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Passenger experience', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Row(children: [_RiskLevel(level: '3 high', color: const Color(0xFFEF4444)), const SizedBox(width: 8), _RiskLevel(level: '4 medium', color: const Color(0xFFF59E0B))]),
            const SizedBox(height: 16),
            const Text('Scheduling availability', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Row(children: [_RiskLevel(level: '2 high', color: const Color(0xFFEF4444)), const SizedBox(width: 8), _RiskLevel(level: '5 medium', color: const Color(0xFFF59E0B))]),
            const SizedBox(height: 16),
            const Text('Staff experience', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Row(children: [_RiskLevel(level: '0 high', color: const Color(0xFF9CA3AF)), const SizedBox(width: 8), _RiskLevel(level: '5 medium', color: const Color(0xFFF59E0B))]),
          ],
        ),
      ],
    );
  }
}

class _RiskTag extends StatelessWidget {
  const _RiskTag({required this.label, required this.severity, required this.color});
  final String label, severity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

class _RiskLevel extends StatelessWidget {
  const _RiskLevel({required this.level, required this.color});
  final String level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(level, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

class _ProjectCostComparison extends StatelessWidget {
  const _ProjectCostComparison();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Project cost comparison', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: const [
              _CostBar(label: 'Gate\nexpansion', value: '\$3.5M', height: 120, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              _CostBar(label: 'Runway\nresurfacing', value: '\$3.2M', height: 110, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              _CostBar(label: 'Check-in\nkiosks', value: '\$1.9M', height: 70, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              _CostBar(label: 'Control room\nupgrade', value: '\$2.9M', height: 100, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              _CostBar(label: 'Automation\nupgr', value: '\$2.1M', height: 75, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              _CostBar(label: 'Monitoring\nplatform', value: '\$1.1M', height: 45, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              _CostBar(label: 'Change\nmanagement', value: '\$1.4M', height: 55, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              _CostBar(label: 'Workforce\nprogram', value: '\$1.7M', height: 60, color: Color(0xFFF59E0B)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CostBar extends StatelessWidget {
  const _CostBar({required this.label, required this.value, required this.height, required this.color});
  final String label, value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 4),
        Container(width: 50, height: height, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 8),
        SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)), textAlign: TextAlign.center)),
      ],
    );
  }
}

class _RollUpUpdateSection extends StatelessWidget {
  const _RollUpUpdateSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This roll-up will update', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 8),
                const Text('Executive dashboards & governance reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    const Text('Effective date', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("Today's date at next reporting cycle", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    const Text('Included scope', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('3 programs · 5 related + 1 standalone project', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                const SizedBox(height: 12),
                Text('Once published, this roll-up becomes the live portfolio view used in steering committees, executive dashboards, and downstream project scorecards.', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFE5E7EB)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Cancel roll-up'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Publish roll-up'),
                    SizedBox(width: 8),
                    Icon(Icons.check_circle_outline, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
