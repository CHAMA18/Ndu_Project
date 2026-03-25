import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/ai_suggesting_textfield.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';

const Color _kPageBackground = Color(0xFFF4F7FF);
const Color _kSurface = Colors.white;
const Color _kBorder = Color(0xFFDDE5F3);
const Color _kPanel = Color(0xFFEAF1FF);
const Color _kPanelSoft = Color(0xFFF7FAFF);
const Color _kPrimary = Color(0xFF0B4DBB);
const Color _kPrimaryDeep = Color(0xFF082A63);
const Color _kTeal = Color(0xFF0B7D68);
const Color _kWarningSoft = Color(0xFFFFF3C9);
const Color _kText = Color(0xFF111827);
const Color _kSubtext = Color(0xFF667085);

class DesignPlanningScreen extends StatelessWidget {
  const DesignPlanningScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DesignPlanningScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 16.0 : 32.0;

    return Scaffold(
      backgroundColor: _kPageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DraggableSidebar(
                  openWidth: AppBreakpoints.sidebarWidth(context),
                  child: const InitiationLikeSidebar(activeItemLabel: 'Design'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlanningPhaseHeader(
                          title: 'Design Planning',
                          showImportButton: false,
                          showContentButton: false,
                          onBack: () => PlanningPhaseNavigation.goToPrevious(
                            context,
                            'design',
                          ),
                          onForward: () => PlanningPhaseNavigation.goToNext(
                            context,
                            'design',
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _DesignMetadataBanner(),
                        const SizedBox(height: 24),
                        const _DesignNotesCard(),
                        const SizedBox(height: 24),
                        _buildSignalBanner(),
                        const SizedBox(height: 24),
                        const _ScopeAndConstraintsSection(),
                        const SizedBox(height: 24),
                        const _MilestonesSection(),
                        const SizedBox(height: 24),
                        const _DesignPlanAutoCard(),
                        const SizedBox(height: 24),
                        const _DeliveryGridSection(),
                        const SizedBox(height: 24),
                        const _GovernanceFooter(),
                        const SizedBox(height: 24),
                        LaunchPhaseNavigation(
                          backLabel:
                              PlanningPhaseNavigation.backLabel('design'),
                          nextLabel:
                              PlanningPhaseNavigation.nextLabel('design'),
                          onBack: () => PlanningPhaseNavigation.goToPrevious(
                            context,
                            'design',
                          ),
                          onNext: () => PlanningPhaseNavigation.goToNext(
                            context,
                            'design',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const KazAiChatBubble(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _kWarningSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF5D56A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Text(
        'Align on design intent, constraints, delivery logic, and approval gates so execution can move fast without rework.',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: _kPrimaryDeep,
          height: 1.45,
        ),
      ),
    );
  }
}

class _DesignMetadataBanner extends StatelessWidget {
  const _DesignMetadataBanner();

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF9FBFF), Color(0xFFEAF1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10082A63),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: const [
              _Pill(
                label: 'Strategy Document',
                background: Color(0xFFE5EEFF),
                foreground: _kPrimary,
              ),
              _Pill(
                label: 'Version 1.0',
                background: Color(0xFFDBF4EC),
                foreground: _kTeal,
              ),
              _Pill(
                label: 'Status: Draft',
                background: Color(0xFFFFF1D7),
                foreground: Color(0xFF9A6700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Plan Title: NduProject Design Planning',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: _kPrimaryDeep,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'This page translates the existing Design checkpoint into an executive-ready planning canvas: scope, assumptions, milestones, resources, deliverables, governance, and editable working notes.',
            style: TextStyle(
              fontSize: 14,
              color: _kSubtext,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final children = const [
                _MetricTile(
                  label: 'Phase Objective',
                  value: 'Turn requirements into a signed-off design direction',
                  icon: Icons.design_services_rounded,
                ),
                _MetricTile(
                  label: 'Primary Output',
                  value: 'Execution-ready design package and review path',
                  icon: Icons.inventory_2_outlined,
                ),
                _MetricTile(
                  label: 'Review Mode',
                  value: 'Cross-functional design, UX, and delivery review',
                  icon: Icons.fact_check_outlined,
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    for (final child in children) ...[
                      child,
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    Expanded(child: children[i]),
                    if (i != children.length - 1) const SizedBox(width: 14),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DesignNotesCard extends StatelessWidget {
  const _DesignNotesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12082A63),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const PlanningAiNotesCard(
        title: 'Design Planning Notes',
        sectionLabel: 'Design Planning',
        noteKey: 'planning_design_notes',
        checkpoint: 'design',
        description:
            'Capture design assumptions, constraints, strategic decisions, dependencies, and early review feedback before execution begins.',
      ),
    );
  }
}

class _ScopeAndConstraintsSection extends StatelessWidget {
  const _ScopeAndConstraintsSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        if (compact) {
          return const Column(
            children: [
              _ScopeCard(),
              SizedBox(height: 20),
              _AssumptionsConstraintsCard(),
            ],
          );
        }

        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ScopeCard()),
            SizedBox(width: 20),
            Expanded(child: _AssumptionsConstraintsCard()),
          ],
        );
      },
    );
  }
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Design Scope & Objectives',
      subtitle:
          'Keep the team aligned on what the design phase must deliver and what remains explicitly outside this checkpoint.',
      icon: Icons.ads_click_rounded,
      accent: _kPrimary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final inScope = _buildList(
            title: 'In Scope',
            titleColor: _kTeal,
            icon: Icons.check_circle,
            items: const [
              'High-fidelity design direction and approval-ready layouts',
              'Visual identity refinement and shared UI patterns',
              'Component behavior definition and documentation',
              'Design review preparation for downstream execution teams',
            ],
          );
          final outOfScope = _buildList(
            title: 'Out of Scope',
            titleColor: Color(0xFFC2410C),
            icon: Icons.cancel_rounded,
            items: const [
              'Backend service implementation',
              'Vendor procurement and contract execution',
              'Production deployment sequencing',
            ],
          );

          if (compact) {
            return Column(
              children: [
                inScope,
                const SizedBox(height: 18),
                outOfScope,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: inScope),
              const SizedBox(width: 18),
              Expanded(child: outOfScope),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList({
    required String title,
    required Color titleColor,
    required IconData icon,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 14),
        for (final item in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 18, color: titleColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _kText,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AssumptionsConstraintsCard extends StatelessWidget {
  const _AssumptionsConstraintsCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Assumptions & Constraints',
      subtitle:
          'Expose the planning conditions that shape design speed, sequencing, and decision quality.',
      icon: Icons.rule_folder_outlined,
      accent: _kPrimary,
      child: Column(
        children: const [
          _AssumptionConstraintRow(
            assumption:
                'Stakeholder feedback and sign-off cycles stay within a 48-hour turnaround.',
            constraint:
                'The phase must stay inside the approved planning and design budget envelope.',
          ),
          Divider(height: 28, color: _kBorder),
          _AssumptionConstraintRow(
            assumption:
                'Current design tooling, assets, and project context remain available to the team.',
            constraint:
                'Design outputs need to be execution-ready before the project shifts into implementation.',
          ),
          Divider(height: 28, color: _kBorder),
          _AssumptionConstraintRow(
            assumption:
                'Cross-functional review participants are available for coordinated governance sessions.',
            constraint:
                'Any unresolved accessibility, scope, or dependency gap must be surfaced before handoff.',
          ),
        ],
      ),
    );
  }
}

class _AssumptionConstraintRow extends StatelessWidget {
  const _AssumptionConstraintRow({
    required this.assumption,
    required this.constraint,
  });

  final String assumption;
  final String constraint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 540;
        final assumptionCard = _MiniInfoBlock(
          label: 'Assumption',
          value: assumption,
          accent: _kTeal,
        );
        final constraintCard = _MiniInfoBlock(
          label: 'Constraint',
          value: constraint,
          accent: const Color(0xFFC2410C),
        );

        if (compact) {
          return Column(
            children: [
              assumptionCard,
              const SizedBox(height: 12),
              constraintCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: assumptionCard),
            const SizedBox(width: 14),
            Expanded(child: constraintCard),
          ],
        );
      },
    );
  }
}

class _MilestonesSection extends StatelessWidget {
  const _MilestonesSection();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Schedule & Milestones',
      subtitle:
          'A high-level design sequence showing how concept, definition, review, and handoff progress through the phase.',
      icon: Icons.timeline_rounded,
      accent: _kPrimary,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _ModeChip(label: 'Monthly', selected: true),
          SizedBox(width: 8),
          _ModeChip(label: 'Quarterly'),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canvasWidth =
              constraints.maxWidth.isFinite && constraints.maxWidth > 0
                  ? (constraints.maxWidth < 760 ? 760.0 : constraints.maxWidth)
                  : 760.0;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: canvasWidth,
              child: Column(
                children: [
                  const _TimelineHeader(),
                  SizedBox(height: 24),
                  _TimelineTrack(
                    canvasWidth: canvasWidth,
                    label: 'Discovery and design framing',
                    startFraction: 0.00,
                    widthFraction: 0.23,
                    progressFraction: 0.78,
                    badge: 'Moodboard / intent approval',
                  ),
                  SizedBox(height: 20),
                  _TimelineTrack(
                    canvasWidth: canvasWidth,
                    label: 'Concept refinement and component definition',
                    startFraction: 0.18,
                    widthFraction: 0.38,
                    progressFraction: 0.44,
                    badge: 'Concept approval milestone',
                    highlightMilestone: true,
                  ),
                  SizedBox(height: 20),
                  _TimelineTrack(
                    canvasWidth: canvasWidth,
                    label: 'Review, governance, and handoff readiness',
                    startFraction: 0.52,
                    widthFraction: 0.34,
                    progressFraction: 0.25,
                    badge: 'Execution handoff gate',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader();

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Phase 01: Concept',
      'Phase 02: Design',
      'Phase 03: Review',
      'Phase 04: Handover',
    ];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _kBorder),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _kSubtext,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TimelineTrack extends StatelessWidget {
  const _TimelineTrack({
    required this.canvasWidth,
    required this.label,
    required this.startFraction,
    required this.widthFraction,
    required this.progressFraction,
    required this.badge,
    this.highlightMilestone = false,
  });

  final double canvasWidth;
  final String label;
  final double startFraction;
  final double widthFraction;
  final double progressFraction;
  final String badge;
  final bool highlightMilestone;

  @override
  Widget build(BuildContext context) {
    final trackLeft = canvasWidth * startFraction;
    final trackWidth = canvasWidth * widthFraction;
    final progressWidth = trackWidth * progressFraction;

    return SizedBox(
      width: canvasWidth,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: trackLeft,
            top: 14,
            child: Container(
              width: trackWidth,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE7FF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: trackLeft,
            top: 14,
            child: Container(
              width: progressWidth,
              height: 10,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPrimary, Color(0xFF5E8EFF)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: trackLeft + progressWidth - 10,
            top: 9,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
          if (highlightMilestone)
            Positioned(
              left: trackLeft + trackWidth + 10,
              top: 6,
              child: const Icon(
                Icons.star_rounded,
                color: _kPrimary,
                size: 24,
              ),
            ),
          Positioned(
            left: 0,
            top: 36,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
          ),
          Positioned(
            left: trackLeft + trackWidth + 40,
            top: 34,
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kPrimaryDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignPlanAutoCard extends StatefulWidget {
  const _DesignPlanAutoCard();

  @override
  State<_DesignPlanAutoCard> createState() => _DesignPlanAutoCardState();
}

class _DesignPlanAutoCardState extends State<_DesignPlanAutoCard> {
  static const String _noteKey = 'planning_design_plan';

  String _currentText = '';
  Timer? _saveDebounce;
  DateTime? _lastSavedAt;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _currentText = value;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () async {
      final trimmed = value.trim();
      final success = await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'design',
        dataUpdater: (data) => data.copyWith(
          planningNotes: {
            ...data.planningNotes,
            _noteKey: trimmed,
          },
        ),
        showSnackbar: false,
      );
      if (mounted && success) {
        setState(() => _lastSavedAt = DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentText.isEmpty) {
      final saved =
          ProjectDataHelper.getData(context).planningNotes[_noteKey] ?? '';
      if (saved.trim().isNotEmpty) {
        _currentText = saved;
      }
    }

    return _DashboardCard(
      title: 'Design Plan Workspace',
      subtitle:
          'Use this working area to define the real design plan: activities, outputs, review moments, dependencies, and handoff logic.',
      icon: Icons.dashboard_customize_outlined,
      accent: _kPrimary,
      trailing: _lastSavedAt == null
          ? null
          : Text(
              'Saved ${TimeOfDay.fromDateTime(_lastSavedAt!).format(context)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kTeal,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 840;
              final left = _MiniShowcaseCard(
                tone: _kPanelSoft,
                borderColor: _kBorder,
                title: 'Recommended Coverage',
                body:
                    'Summarize design intent, decision principles, outputs, governance checkpoints, dependencies, and execution-readiness criteria.',
                icon: Icons.track_changes_rounded,
              );
              final right = _MiniShowcaseCard(
                tone: const Color(0xFFEAF8F3),
                borderColor: const Color(0xFFCCEBDD),
                title: 'Expected Outcome',
                body:
                    'A design package the delivery team can use without ambiguity, rework, or missing sign-off evidence.',
                icon: Icons.verified_outlined,
              );

              if (compact) {
                return Column(
                  children: [
                    left,
                    const SizedBox(height: 12),
                    right,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 12),
                  Expanded(child: right),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          AiSuggestingTextField(
            fieldLabel: 'Design Plan',
            hintText:
                'Outline design objectives, deliverables, review checkpoints, stakeholder alignment, and handoff preparation.',
            sectionLabel: 'Design Planning',
            showLabel: false,
            autoGenerate: true,
            autoGenerateSection: 'Design Plan',
            initialText:
                ProjectDataHelper.getData(context).planningNotes[_noteKey],
            onChanged: _handleChanged,
          ),
        ],
      ),
    );
  }
}

class _DeliveryGridSection extends StatelessWidget {
  const _DeliveryGridSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1080;
        if (compact) {
          return const Column(
            children: [
              _ResourceAllocationCard(),
              SizedBox(height: 20),
              _DeliverablesCard(),
              SizedBox(height: 20),
              _BudgetCard(),
            ],
          );
        }

        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: _ResourceAllocationCard()),
            SizedBox(width: 20),
            Expanded(
              flex: 8,
              child: Column(
                children: [
                  _DeliverablesCard(),
                  SizedBox(height: 20),
                  _BudgetCard(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResourceAllocationCard extends StatelessWidget {
  const _ResourceAllocationCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Resource Allocation',
      subtitle:
          'At a glance: who is involved and what tools anchor the design workflow.',
      icon: Icons.groups_2_outlined,
      accent: _kPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Stakeholders',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _kSubtext,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _AvatarBadge(initials: 'AL', role: 'Architecture Lead'),
              _AvatarBadge(initials: 'UX', role: 'UX Strategist'),
              _AvatarBadge(initials: 'PM', role: 'Project Manager'),
              _AvatarBadge(initials: '+4', role: 'Additional reviewers'),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Required Tools',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _kSubtext,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(
                label: 'Figma Professional',
                background: Color(0xFFEAF1FF),
                foreground: _kPrimaryDeep,
              ),
              _Pill(
                label: 'Jira Enterprise',
                background: Color(0xFFF0F5FF),
                foreground: _kPrimaryDeep,
              ),
              _Pill(
                label: 'Design System Library',
                background: Color(0xFFEAF8F3),
                foreground: _kTeal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliverablesCard extends StatelessWidget {
  const _DeliverablesCard();

  @override
  Widget build(BuildContext context) {
    const rows = [
      _DeliverableRowData(
        category: 'Visual',
        name: 'Master component library',
        format: 'Shared design system',
        status: 'Active',
        statusColor: _kTeal,
        statusBackground: Color(0xFFEAF8F3),
      ),
      _DeliverableRowData(
        category: 'Docs',
        name: 'Accessibility compliance review',
        format: 'WCAG / annotated handoff',
        status: 'Pending',
        statusColor: Color(0xFF8A5A00),
        statusBackground: Color(0xFFFFF3D2),
      ),
      _DeliverableRowData(
        category: 'Prototype',
        name: 'Primary user flow blueprint',
        format: 'Interactive concept flow',
        status: 'Active',
        statusColor: _kTeal,
        statusBackground: Color(0xFFEAF8F3),
      ),
    ];

    return _DashboardCard(
      title: 'Deliverables Breakdown',
      subtitle:
          'The key outputs expected from the design phase, presented in the same executive style as the supplied concept.',
      icon: Icons.table_chart_outlined,
      accent: _kPrimary,
      child: Column(
        children: [
          const _DeliverablesTableHeader(),
          const SizedBox(height: 6),
          for (var i = 0; i < rows.length; i++) ...[
            _DeliverableRow(data: rows[i]),
            if (i != rows.length - 1) const Divider(height: 1, color: _kBorder),
          ],
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPrimary, Color(0xFF2B67D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220B4DBB),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final metrics = const [
            _BudgetMetric(label: 'Estimated', value: '\$45,000'),
            _BudgetMetric(label: 'Actual To Date', value: '\$12,400'),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cost & Budget Estimation',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Track expenditure against the design allocation so scope ambition stays grounded in delivery reality.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFD6E4FF),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              if (compact)
                const Column(
                  children: [
                    _BudgetMetricCard(
                        metric: _BudgetMetric(
                            label: 'Estimated', value: '\$45,000')),
                    SizedBox(height: 12),
                    _BudgetMetricCard(
                        metric: _BudgetMetric(
                            label: 'Actual To Date', value: '\$12,400')),
                  ],
                )
              else
                Row(
                  children: [
                    for (var i = 0; i < metrics.length; i++) ...[
                      Expanded(child: _BudgetMetricCard(metric: metrics[i])),
                      if (i != metrics.length - 1) const SizedBox(width: 14),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GovernanceFooter extends StatelessWidget {
  const _GovernanceFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F082A63),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 880;
          final intro = const _GovernanceIntro();
          final stakeholders = const _GovernanceList(
            title: 'Review Stakeholders',
            items: [
              'Architecture Review Board',
              'Lead Compliance Officer',
              'Senior UX Strategist',
            ],
          );
          final standards = const _GovernanceList(
            title: 'Compliance Standards',
            items: [
              'WCAG 2.1 AA',
              'Design token consistency',
              'Material-aligned interaction patterns',
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                intro,
                const SizedBox(height: 20),
                stakeholders,
                const SizedBox(height: 20),
                standards,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(flex: 2, child: _GovernanceIntro()),
              SizedBox(width: 18),
              Expanded(
                  child: _GovernanceList(
                title: 'Review Stakeholders',
                items: [
                  'Architecture Review Board',
                  'Lead Compliance Officer',
                  'Senior UX Strategist',
                ],
              )),
              SizedBox(width: 18),
              Expanded(
                  child: _GovernanceList(
                title: 'Compliance Standards',
                items: [
                  'WCAG 2.1 AA',
                  'Design token consistency',
                  'Material-aligned interaction patterns',
                ],
              )),
            ],
          );
        },
      ),
    );
  }
}

class _GovernanceIntro extends StatelessWidget {
  const _GovernanceIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Design Governance & Quality Criteria',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: _kPrimaryDeep,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'All design outputs should pass structured review before handoff so the execution team receives approved, compliant, and implementation-ready guidance.',
          style: TextStyle(
            fontSize: 14,
            color: _kSubtext,
            height: 1.55,
          ),
        ),
        SizedBox(height: 16),
        _Pill(
          label: 'Policy-driven review workflow',
          background: Color(0xFFEAF1FF),
          foreground: _kPrimary,
        ),
      ],
    );
  }
}

class _GovernanceList extends StatelessWidget {
  const _GovernanceList({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _kSubtext,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        for (final item in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(Icons.circle, size: 7, color: _kPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F082A63),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: _kPrimaryDeep,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kSubtext,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _kPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _kSubtext,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                    height: 1.4,
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? _kPanel : _kPanelSoft,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: selected ? const Color(0xFFC8D8FF) : _kBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: selected ? _kPrimary : _kSubtext,
        ),
      ),
    );
  }
}

class _MiniInfoBlock extends StatelessWidget {
  const _MiniInfoBlock({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniShowcaseCard extends StatelessWidget {
  const _MiniShowcaseCard({
    required this.tone,
    required this.borderColor,
    required this.title,
    required this.body,
    required this.icon,
  });

  final Color tone;
  final Color borderColor;
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _kPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kPrimaryDeep,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kSubtext,
                    height: 1.5,
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

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.initials,
    required this.role,
  });

  final String initials;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kPanelSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFD9E5FF),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _kPrimaryDeep,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            role,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliverablesTableHeader extends StatelessWidget {
  const _DeliverablesTableHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            'Category',
            style: _tableHeaderStyle,
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            'Deliverable Name',
            style: _tableHeaderStyle,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Format',
            style: _tableHeaderStyle,
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Status',
              style: _tableHeaderStyle,
            ),
          ),
        ),
      ],
    );
  }
}

const TextStyle _tableHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w800,
  color: _kSubtext,
  letterSpacing: 0.8,
);

class _DeliverableRowData {
  const _DeliverableRowData({
    required this.category,
    required this.name,
    required this.format,
    required this.status,
    required this.statusColor,
    required this.statusBackground,
  });

  final String category;
  final String name;
  final String format;
  final String status;
  final Color statusColor;
  final Color statusBackground;
}

class _DeliverableRow extends StatelessWidget {
  const _DeliverableRow({required this.data});

  final _DeliverableRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              data.category,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kText,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              data.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _kText,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              data.format,
              style: const TextStyle(
                fontSize: 13,
                color: _kSubtext,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: data.statusBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  data.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: data.statusColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetMetric {
  const _BudgetMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _BudgetMetricCard extends StatelessWidget {
  const _BudgetMetricCard({required this.metric});

  final _BudgetMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFD6E4FF),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metric.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
