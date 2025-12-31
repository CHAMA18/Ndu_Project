import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';

class GapAnalysisScopeReconcillationScreen extends StatefulWidget {
  const GapAnalysisScopeReconcillationScreen({
    super.key,
    this.activeItemLabel = 'Gap Analysis And Scope Reconcillation',
  });

  final String activeItemLabel;

  static void open(BuildContext context, {String activeItemLabel = 'Gap Analysis And Scope Reconcillation'}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GapAnalysisScopeReconcillationScreen(activeItemLabel: activeItemLabel)),
    );
  }

  @override
  State<GapAnalysisScopeReconcillationScreen> createState() => _GapAnalysisScopeReconcillationScreenState();
}

class _GapAnalysisScopeReconcillationScreenState extends State<GapAnalysisScopeReconcillationScreen> {
  final Set<String> _selectedFocusFilters = {'Gap register'};
  final Set<String> _selectedVisibilityFilters = {'Scope baseline', 'Mitigation backlog'};

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
                  child: InitiationLikeSidebar(activeItemLabel: widget.activeItemLabel),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PageHeader(),
                        const SizedBox(height: 20),
                        _InfoStrip(isMobile: isMobile),
                        const SizedBox(height: 24),
                        _FilterToolbar(
                          selectedFocusFilters: _selectedFocusFilters,
                          selectedVisibilityFilters: _selectedVisibilityFilters,
                          onFocusFilterChanged: (label) {
                            setState(() {
                              if (_selectedFocusFilters.contains(label)) {
                                _selectedFocusFilters.remove(label);
                              } else {
                                _selectedFocusFilters.add(label);
                              }
                            });
                          },
                          onVisibilityFilterChanged: (label) {
                            setState(() {
                              if (_selectedVisibilityFilters.contains(label)) {
                                _selectedVisibilityFilters.remove(label);
                              } else {
                                _selectedVisibilityFilters.add(label);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 28),
                        const _SummaryGrid(),
                        const SizedBox(height: 28),
                        const _PrimarySections(),
                        const SizedBox(height: 24),
                        const _SecondarySections(),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Gap Analysis & Scope Reconciliation',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        SizedBox(height: 8),
        Text(
          'Assess active scope gaps, align remediation plans, and ensure stakeholders stay synchronized before handover.',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    const chips = [
      _InfoChipData(label: 'Project', value: 'AI path capacity uplift – Inception'),
      _InfoChipData(label: 'Track', value: 'Product launch alignment'),
      _InfoChipData(label: 'Delivery stage', value: 'Ready-to-build review'),
      _InfoChipData(label: 'Refresh cadence', value: 'Weekly · Next sync Thu, 10:00 AM'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.start,
      children: chips
          .map((chip) => _InfoChip(
                data: chip,
                isCompact: isMobile,
              ))
          .toList(),
    );
  }
}

class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({
    required this.selectedFocusFilters,
    required this.selectedVisibilityFilters,
    required this.onFocusFilterChanged,
    required this.onVisibilityFilterChanged,
  });

  final Set<String> selectedFocusFilters;
  final Set<String> selectedVisibilityFilters;
  final ValueChanged<String> onFocusFilterChanged;
  final ValueChanged<String> onVisibilityFilterChanged;

  @override
  Widget build(BuildContext context) {
    const focusOptions = [
      'Gap register',
      'Scope baseline',
      'Impacts',
      'Stakeholders',
      'Mitigation backlog',
    ];
    const visibilityOptions = [
      'Show riskiest gaps',
      'Show closed gaps',
      'Surface dependencies',
    ];

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Focus',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.video_call_outlined, size: 20),
                label: const Text('Schedule reconciliation meeting'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  backgroundColor: const Color(0xFF4154F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: focusOptions
                .map(
                  (option) => ChoiceChip(
                    label: Text(option),
                    selected: selectedFocusFilters.contains(option),
                    onSelected: (_) => onFocusFilterChanged(option),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    selectedColor: primary.withOpacity(0.12),
                    labelStyle: TextStyle(
                      color: selectedFocusFilters.contains(option) ? primary : const Color(0xFF374151),
                      fontWeight: selectedFocusFilters.contains(option) ? FontWeight.w600 : FontWeight.w500,
                    ),
                    backgroundColor: const Color(0xFFF3F4F6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: visibilityOptions
                .map(
                  (option) => FilterChip(
                    label: Text(option),
                    selected: selectedVisibilityFilters.contains(option),
                    onSelected: (_) => onVisibilityFilterChanged(option),
                    showCheckmark: false,
                    selectedColor: const Color(0xFFEEF2FF),
                    labelStyle: TextStyle(
                      color: selectedVisibilityFilters.contains(option) ? const Color(0xFF3730A3) : const Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  static const _SummaryCardData _healthCard = _SummaryCardData(
    title: 'Overall reconciliation health',
    headline: '82% aligned',
    annotation: 'Remaining gaps: 3 critical · 4 moderate',
    accentColor: Color(0xFF2563EB),
    icon: Icons.insights_outlined,
    bullets: [
      'Material gaps tracked across design, ops, and adoption streams',
      'Integration hand-offs validated for 4 of 5 impacted squads',
    ],
    progress: 0.82,
  );

  static const _SummaryCardData _gapsCard = _SummaryCardData(
    title: 'Gaps',
    headline: '12 active',
    annotation: '5 closed this sprint · 2 newly logged',
    accentColor: Color(0xFF0891B2),
    icon: Icons.warning_amber_outlined,
    bullets: [
      'Critical: Prod-ready data sync · Release deployment',
      'Moderate: Support playbooks · API throttling policy',
    ],
  );

  static const _SummaryCardData _scopeCard = _SummaryCardData(
    title: 'Scope',
    headline: '3 packages in review',
    annotation: 'Procurement lead-time risk easing',
    accentColor: Color(0xFF7C3AED),
    icon: Icons.layers_outlined,
    bullets: [
      'MVP scope freeze by 18 Dec · Consumer onboarding locked',
      'Ops enablement kit staged for final sign-off',
    ],
  );

  static const _SummaryCardData _impactCard = _SummaryCardData(
    title: 'Impacts',
    headline: 'High impact areas',
    annotation: 'Primary: Deployment timeline · Secondary: Support load',
    accentColor: Color(0xFFEA580C),
    icon: Icons.auto_graph_outlined,
    bullets: [
      'Schedule: -4 days variance absorbed with overtime budget',
      'Cost: +3.2% attributed to additional QA automation',
    ],
  );

  static const _SummaryCardData _stakeholderCard = _SummaryCardData(
    title: 'Stakeholder alignment',
    headline: 'Managers synced',
    annotation: 'Last exec review: Mon, 2:00 PM',
    accentColor: Color(0xFF059669),
    icon: Icons.groups_outlined,
    bullets: [
      'Adoption: GTM + Customer success validated mitigation path',
      'Ops: Support + Reliability sign-off scheduled for Friday',
    ],
  );

  static const cards = [_healthCard, _gapsCard, _scopeCard, _impactCard, _stakeholderCard];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        double targetWidth;

        if (maxWidth >= 1100) {
          targetWidth = (maxWidth - 40) / 3;
        } else if (maxWidth >= 760) {
          targetWidth = (maxWidth - 20) / 2;
        } else {
          targetWidth = maxWidth;
        }

        final childWidth = maxWidth < 260 ? maxWidth : targetWidth.clamp(260.0, maxWidth);

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: cards
              .map(
                (card) => _SummaryCard(
                  data: card,
                  width: childWidth,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data, required this.width});

  final _SummaryCardData data;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: data.accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(data.icon, color: data.accentColor, size: 22),
            ),
            const Spacer(),
            if (data.progress != null)
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: data.progress,
                      strokeWidth: 5,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(data.accentColor),
                    ),
                    Center(
                      child: Text(
                        '${(data.progress! * 100).round()}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          data.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 10),
        Text(
          data.headline,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: data.accentColor),
        ),
        const SizedBox(height: 6),
        Text(
          data.annotation,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 14),
        ...data.bullets.map(
          (bullet) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 6, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bullet,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      constraints: BoxConstraints(minWidth: width),
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 14)),
        ],
      ),
      child: cardContent,
    );
  }
}

class _PrimarySections extends StatelessWidget {
  const _PrimarySections();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        double targetWidth;

        if (maxWidth >= 1150) {
          targetWidth = (maxWidth - 40) / 3;
        } else if (maxWidth >= 820) {
          targetWidth = (maxWidth - 20) / 2;
        } else {
          targetWidth = maxWidth;
        }

        final sectionWidth = maxWidth < 320 ? maxWidth : targetWidth.clamp(320.0, maxWidth);

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _GapRegisterCard(width: sectionWidth),
            _GapAnalysisRootCauseCard(width: sectionWidth),
            _ReconciliationPlanningCard(width: sectionWidth),
          ],
        );
      },
    );
  }
}

class _SecondarySections extends StatelessWidget {
  const _SecondarySections();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        double targetWidth;

        if (maxWidth >= 1150) {
          targetWidth = (maxWidth - 40) / 3;
        } else if (maxWidth >= 820) {
          targetWidth = (maxWidth - 20) / 2;
        } else {
          targetWidth = maxWidth;
        }

        final sectionWidth = maxWidth < 320 ? maxWidth : targetWidth.clamp(320.0, maxWidth);

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _ImpactAssessmentCard(width: sectionWidth),
            _ReconciliationWorkflowCard(width: sectionWidth),
            _LessonsLearnedCard(width: sectionWidth),
          ],
        );
      },
    );
  }
}

class _GapRegisterCard extends StatelessWidget {
  const _GapRegisterCard({required this.width});

  final double width;

  static const entries = [
    _GapEntry(
      id: 'GAP-017',
      title: 'Prod-ready data sync misaligned with AI pilot scope',
      stage: 'Critical',
      owner: 'Alex Rivera',
      nextStep: 'Finalize ops readiness checklist',
    ),
    _GapEntry(
      id: 'GAP-011',
      title: 'Support knowledge base misses new workflow',
      stage: 'Moderate',
      owner: 'Priya Nair',
      nextStep: 'Review enablement drafts (due Wed)',
    ),
    _GapEntry(
      id: 'GAP-004',
      title: 'API throttling policy conflicts with projected volume',
      stage: 'Moderate',
      owner: 'Morgan Lee',
      nextStep: 'Update rollout guardrails',
    ),
    _GapEntry(
      id: 'GAP-002',
      title: 'Deployment playbook lacks rollback automation',
      stage: 'Critical',
      owner: 'Jamie Chen',
      nextStep: 'Schedule dry-run with release manager',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      width: width,
      title: 'Gap register & catalog',
      subtitle: 'Tracking priority, owner, and mitigation status for each scope gap.',
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Log new gap'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _Pill(label: 'Critical · 3', color: Color(0xFFDC2626)),
              _Pill(label: 'Moderate · 5', color: Color(0xFFF97316)),
              _Pill(label: 'Low · 4', color: Color(0xFF059669)),
              _Pill(label: 'Resolved · 18', color: Color(0xFF2563EB)),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: const [
                      _TableHeaderCell(flex: 2, label: 'Gap'),
                      _TableHeaderCell(label: 'Priority'),
                      _TableHeaderCell(label: 'Owner'),
                      _TableHeaderCell(flex: 2, label: 'Next step'),
                    ],
                  ),
                ),
                ...entries.map(
                  (entry) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.9)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: _GapTitleCell(entry: entry)),
                        _PriorityBadge(label: entry.stage),
                        Expanded(
                          child: Text(
                            entry.owner,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.nextStep,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GapAnalysisRootCauseCard extends StatelessWidget {
  const _GapAnalysisRootCauseCard({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      width: width,
      title: 'Gap analysis & root cause',
      subtitle: 'Identify the underlying sources of each scope discrepancy.',
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.playlist_add_check_circle_outlined),
        label: const Text('Share updated findings'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _InsightBlock(
            label: 'Root cause themes',
            points: [
              'Handoffs between solution engineering and product readiness lack coverage on data retention scenarios.',
              'Operational load forecast underestimated AI inference traffic across two customer segments.',
              'Customer success enablement packs were built off outdated pilot assumptions.',
            ],
          ),
          SizedBox(height: 18),
          _InsightBlock(
            label: 'Mitigation confidence',
            points: [
              '80% confidence on deployment gap closure once automation scripts finish QA (ETA Tue).',
              'Stakeholder sign-off pending around support playbooks; expect approval during Thursday sync.',
              'Adoption risk tracked as medium – features flagged for staged rollout with guardrails.',
            ],
          ),
        ],
      ),
    );
  }
}

class _ReconciliationPlanningCard extends StatelessWidget {
  const _ReconciliationPlanningCard({required this.width});

  final double width;

  static const plans = [
    _PlanEntry(title: 'Finalize design to ops handoff', due: 'Due Wed · Release train', owner: 'Ops integration squad', status: 'On track'),
    _PlanEntry(title: 'Validate deployment automation guardrails', due: 'Due Thu · QA automation', owner: 'Quality guild', status: 'At risk'),
    _PlanEntry(title: 'Roll out customer success knowledge base updates', due: 'Due Fri · Adoption pod', owner: 'GTM + CS enablement', status: 'In review'),
    _PlanEntry(title: 'Confirm post-launch monitoring coverage', due: 'Due Sat · Reliability team', owner: 'SRE task force', status: 'Not started'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      width: width,
      title: 'Reconciliation planning',
      subtitle: 'Sequenced closure plan with owners, timelines, and status.',
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.task_alt_outlined),
        label: const Text('Export action plan'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: plans
            .map(
              (plan) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                          ),
                        ),
                        _StatusBadge(label: plan.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.due,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4C1D95)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.owner,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ImpactAssessmentCard extends StatelessWidget {
  const _ImpactAssessmentCard({required this.width});

  final double width;

  static const impacts = [
    _ImpactRow(area: 'Schedule', rating: 'Medium', trend: 'Improving', detail: 'Variance trimmed from 6 to 4 days with paired testing.'),
    _ImpactRow(area: 'Cost', rating: 'Low', trend: 'Stable', detail: 'Budget buffer of 4.1% remains after QA automation spend.'),
    _ImpactRow(area: 'Quality', rating: 'Medium', trend: 'Needs attention', detail: 'Automation scripts pending validation before go-live.'),
    _ImpactRow(area: 'Adoption', rating: 'High', trend: 'Improving', detail: 'New knowledge base ready for pilot customers next week.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      width: width,
      title: 'Impact assessment results',
      subtitle: 'Evaluate schedule, cost, quality, and adoption exposure for unresolved gaps.',
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.analytics_outlined),
        label: const Text('View scenario matrix'),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    Expanded(child: _TableHeaderCell(label: 'Impact area')),
                    _TableHeaderCell(label: 'Rating'),
                    _TableHeaderCell(label: 'Trend'),
                  ],
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                ...impacts.map(
                  (impact) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                impact.area,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                impact.detail,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 120, child: _StatusBadge(label: impact.rating)),
                        SizedBox(width: 120, child: _TrendPill(label: impact.trend)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReconciliationWorkflowCard extends StatelessWidget {
  const _ReconciliationWorkflowCard({required this.width});

  final double width;

  static const steps = [
    _WorkflowStep(label: 'Discovery', status: 'Complete', description: 'All gap interviews and system scans logged.'),
    _WorkflowStep(label: 'Alignment workshop', status: 'Complete', description: 'Findings confirmed with design, ops, adoption leads.'),
    _WorkflowStep(label: 'Mitigation backlog', status: 'In progress', description: '13 of 18 actions scheduled with delivery squads.'),
    _WorkflowStep(label: 'Validation & sign-off', status: 'Upcoming', description: 'Stakeholder verification targeted for Friday review.'),
    _WorkflowStep(label: 'Post-launch monitoring', status: 'Planned', description: 'Success metrics dashboard in drafting with analytics.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      width: width,
      title: 'Reconciliation workflow & backlog',
      subtitle: 'Track the lifecycle of gap discovery through launch readiness.',
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.view_kanban_outlined),
        label: const Text('Open workflow board'),
      ),
      child: Column(
        children: steps
            .map(
              (step) => Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.label,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            step.description,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(label: step.status),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _LessonsLearnedCard extends StatelessWidget {
  const _LessonsLearnedCard({required this.width});

  final double width;

  static const lessons = [
    'Embed ops readiness checkpoints in discovery playback to avoid scope drift.',
    'Codify AI model retraining needs within scope assumptions for downstream teams.',
    'Pre-schedule support enablement refresh once feature flag thresholds are set.',
    'Retain a rolling dependency map between squads to surface cross-team blockers earlier.',
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      width: width,
      title: 'Lessons learned & prevention',
      subtitle: 'Document leading indicators and preventative practices for future launches.',
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.history_edu_outlined),
        label: const Text('Log follow-up insight'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lessons
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.check_circle, size: 18, color: Color(0xFF22C55E)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final double width;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: trailing!,
              ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    );

    return Container(
      width: width,
      constraints: BoxConstraints(minWidth: width),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 12)),
        ],
      ),
      child: content,
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.data, required this.isCompact});

  final _InfoChipData data;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: TextStyle(fontSize: isCompact ? 13 : 14, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }
}

class _GapTitleCell extends StatelessWidget {
  const _GapTitleCell({required this.entry});

  final _GapEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.id,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 4),
        Text(
          entry.title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
        ),
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.label});

  final String label;

  Color _badgeColor() {
    switch (label.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFECACA);
      case 'moderate':
        return const Color(0xFFFDE68A);
      case 'low':
        return const Color(0xFFCFFAFE);
      default:
        return const Color(0xFFE0E7FF);
    }
  }

  Color _textColor() {
    switch (label.toLowerCase()) {
      case 'critical':
        return const Color(0xFFB91C1C);
      case 'moderate':
        return const Color(0xFFB45309);
      case 'low':
        return const Color(0xFF0F766E);
      default:
        return const Color(0xFF3730A3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: _badgeColor(), borderRadius: BorderRadius.circular(30)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textColor()),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  Color _statusColor() {
    switch (label.toLowerCase()) {
      case 'on track':
        return const Color(0xFF16A34A);
      case 'at risk':
        return const Color(0xFFF97316);
      case 'in review':
        return const Color(0xFF2563EB);
      case 'not started':
        return const Color(0xFF4B5563);
      case 'complete':
        return const Color(0xFF0F766E);
      case 'upcoming':
        return const Color(0xFF6366F1);
      case 'planned':
        return const Color(0xFF5B21B6);
      default:
        return const Color(0xFF111827);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(30)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.label});

  final String label;

  Color _trendColor() {
    switch (label.toLowerCase()) {
      case 'improving':
        return const Color(0xFF16A34A);
      case 'stable':
        return const Color(0xFF2563EB);
      case 'needs attention':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF4B5563);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _trendColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label.toLowerCase() == 'needs attention' ? Icons.warning_amber_outlined : Icons.trending_up,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _InsightBlock extends StatelessWidget {
  const _InsightBlock({required this.label, required this.points});

  final String label;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell({required this.label, this.flex = 1});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.3),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _InfoChipData {
  const _InfoChipData({required this.label, required this.value});

  final String label;
  final String value;
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.headline,
    required this.annotation,
    required this.accentColor,
    required this.icon,
    required this.bullets,
    this.progress,
  });

  final String title;
  final String headline;
  final String annotation;
  final Color accentColor;
  final IconData icon;
  final List<String> bullets;
  final double? progress;
}

class _GapEntry {
  const _GapEntry({
    required this.id,
    required this.title,
    required this.stage,
    required this.owner,
    required this.nextStep,
  });

  final String id;
  final String title;
  final String stage;
  final String owner;
  final String nextStep;
}

class _PlanEntry {
  const _PlanEntry({required this.title, required this.due, required this.owner, required this.status});

  final String title;
  final String due;
  final String owner;
  final String status;
}

class _ImpactRow {
  const _ImpactRow({required this.area, required this.rating, required this.trend, required this.detail});

  final String area;
  final String rating;
  final String trend;
  final String detail;
}

class _WorkflowStep {
  const _WorkflowStep({required this.label, required this.status, required this.description});

  final String label;
  final String status;
  final String description;
}
