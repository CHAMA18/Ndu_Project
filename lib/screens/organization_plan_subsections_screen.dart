import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';

class OrganizationRolesResponsibilitiesScreen extends StatelessWidget {
  const OrganizationRolesResponsibilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlanningSubsectionScreen(
      config: _PlanningSubsectionConfig(
        title: 'Roles & Responsibilities',
        subtitle: 'Clarify ownership across workstreams and decision points.',
        noteKey: 'planning_organization_roles_responsibilities',
        checkpoint: 'organization_roles_responsibilities',
        activeItemLabel: 'Organization Plan - Roles & Responsibilities',
        metrics: const [
          _MetricData('Roles', '18', Color(0xFF2563EB)),
          _MetricData('Owners', '12', Color(0xFF10B981)),
          _MetricData('RACI Items', '24', Color(0xFFF59E0B)),
          _MetricData('Open Gaps', '3', Color(0xFFEF4444)),
        ],
        sections: const [
          _SectionData(
            title: 'RACI Highlights',
            subtitle: 'Top role assignments for key deliverables.',
            bullets: [
              _BulletData('Project sponsor accountable for scope changes', true),
              _BulletData('Product owner approves backlog priority', true),
              _BulletData('Engineering lead owns release sign-off', true),
            ],
          ),
          _SectionData(
            title: 'Decision Owners',
            subtitle: 'Primary decision-makers by domain.',
            statusRows: [
              _StatusRowData('Architecture', 'CTO', Color(0xFF2563EB)),
              _StatusRowData('Security', 'CISO', Color(0xFF10B981)),
              _StatusRowData('Budget', 'PMO', Color(0xFFF59E0B)),
            ],
          ),
          _SectionData(
            title: 'Coverage Gaps',
            subtitle: 'Roles still missing owners.',
            bullets: [
              _BulletData('Data governance lead', false),
              _BulletData('Vendor escalation manager', false),
              _BulletData('Change control coordinator', false),
            ],
          ),
          _SectionData(
            title: 'Escalation Path',
            subtitle: 'Routing for unresolved decisions.',
            bullets: [
              _BulletData('Workstream lead to PM', false),
              _BulletData('PM to steering committee', false),
              _BulletData('Steering committee to sponsor', false),
            ],
          ),
        ],
      ),
    );
  }
}

class OrganizationStaffingPlanScreen extends StatelessWidget {
  const OrganizationStaffingPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlanningSubsectionScreen(
      config: _PlanningSubsectionConfig(
        title: 'Staffing Plan',
        subtitle: 'Plan resource needs, staffing timeline, and onboarding cadence.',
        noteKey: 'planning_organization_staffing_plan',
        checkpoint: 'organization_staffing_plan',
        activeItemLabel: 'Organization Plan - Staffing Plan',
        metrics: const [
          _MetricData('FTEs', '26', Color(0xFF2563EB)),
          _MetricData('Contractors', '8', Color(0xFF10B981)),
          _MetricData('Ramp', '6 weeks', Color(0xFFF59E0B)),
          _MetricData('Open Reqs', '5', Color(0xFFEF4444)),
        ],
        sections: const [
          _SectionData(
            title: 'Hiring Timeline',
            subtitle: 'Key onboarding windows by role.',
            bullets: [
              _BulletData('Backend hires onboard by Sprint 4', true),
              _BulletData('QA expansion scheduled Sprint 6', true),
              _BulletData('Ops handoff hires by Sprint 8', false),
            ],
          ),
          _SectionData(
            title: 'Capacity Allocation',
            subtitle: 'Planned staffing by workstream.',
            statusRows: [
              _StatusRowData('Product', '6 FTE', Color(0xFF2563EB)),
              _StatusRowData('Engineering', '12 FTE', Color(0xFF10B981)),
              _StatusRowData('QA', '4 FTE', Color(0xFFF59E0B)),
              _StatusRowData('Ops', '4 FTE', Color(0xFF8B5CF6)),
            ],
          ),
          _SectionData(
            title: 'Onboarding Plan',
            subtitle: 'Enablement tasks for new staff.',
            bullets: [
              _BulletData('Environment access and tooling setup', false),
              _BulletData('Product and domain walkthroughs', false),
              _BulletData('Process and cadence alignment', false),
            ],
          ),
          _SectionData(
            title: 'Staffing Risks',
            subtitle: 'Risks that impact resource readiness.',
            bullets: [
              _BulletData('Competitive hiring market for data roles', false),
              _BulletData('Contractor availability post-launch', false),
              _BulletData('Training bandwidth for new hires', false),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanningSubsectionScreen extends StatelessWidget {
  const _PlanningSubsectionScreen({required this.config});

  final _PlanningSubsectionConfig config;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 20.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: InitiationLikeSidebar(activeItemLabel: config.activeItemLabel),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        const gap = 24.0;
                        final twoCol = width >= 980;
                        final halfWidth = twoCol ? (width - gap) / 2 : width;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(title: config.title, onBack: () => Navigator.maybePop(context)),
                            const SizedBox(height: 12),
                            Text(
                              config.subtitle,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            PlanningAiNotesCard(
                              title: 'AI Notes',
                              sectionLabel: config.title,
                              noteKey: config.noteKey,
                              checkpoint: config.checkpoint,
                              description: 'Capture ownership, staffing needs, and role coverage.',
                            ),
                            const SizedBox(height: 24),
                            _MetricsRow(metrics: config.metrics),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: config.sections
                                  .map((section) => SizedBox(width: halfWidth, child: _SectionCard(data: section)))
                                  .toList(),
                            ),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
                    ),
                  ),
                  const Positioned(right: 24, bottom: 24, child: KazAiChatBubble()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanningSubsectionConfig {
  const _PlanningSubsectionConfig({
    required this.title,
    required this.subtitle,
    required this.noteKey,
    required this.checkpoint,
    required this.activeItemLabel,
    required this.metrics,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final String noteKey;
  final String checkpoint;
  final String activeItemLabel;
  final List<_MetricData> metrics;
  final List<_SectionData> sections;
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        const _CircleIconButton(icon: Icons.arrow_forward_ios_rounded),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const Spacer(),
        const _UserChip(),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'User';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE5E7EB),
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Text('Product manager', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: metrics
          .map((metric) => _MetricCard(label: metric.label, value: metric.value, accent: metric.color))
          .toList(),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent),
          ),
        ],
      ),
    );
  }
}

class _SectionData {
  const _SectionData({
    required this.title,
    required this.subtitle,
    this.bullets = const [],
    this.statusRows = const [],
  });

  final String title;
  final String subtitle;
  final List<_BulletData> bullets;
  final List<_StatusRowData> statusRows;
}

class _BulletData {
  const _BulletData(this.text, this.isCheck);

  final String text;
  final bool isCheck;
}

class _StatusRowData {
  const _StatusRowData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.data});

  final _SectionData data;

  @override
  Widget build(BuildContext context) {
    final showBullets = data.bullets.isNotEmpty;
    final showStatus = data.statusRows.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(data.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
          const SizedBox(height: 16),
          if (showBullets)
            ...data.bullets.map((bullet) => _BulletRow(data: bullet)),
          if (showStatus)
            ...data.statusRows.map((row) => _StatusRow(data: row)),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.data});

  final _BulletData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            data.isCheck ? Icons.check_circle_outline : Icons.circle,
            size: data.isCheck ? 16 : 8,
            color: data.isCheck ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.data});

  final _StatusRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              data.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              data.value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: data.color),
            ),
          ),
        ],
      ),
    );
  }
}
