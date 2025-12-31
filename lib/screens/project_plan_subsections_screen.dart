import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';

class ProjectPlanLevel1ScheduleScreen extends StatelessWidget {
  const ProjectPlanLevel1ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProjectPlanSectionScreen(
      config: _ProjectPlanSectionConfig(
        title: 'Level 1 - Project Schedule',
        subtitle: 'Map major phases, milestone timing, and governance checkpoints.',
        noteKey: 'planning_project_plan_level1_notes',
        checkpoint: 'project_plan_level1_schedule',
        activeItemLabel: 'Project Plan - Level 1 - Project Schedule',
        metrics: const [
          _MetricData('Milestones', '12', Color(0xFF2563EB)),
          _MetricData('Phases', '5', Color(0xFF10B981)),
          _MetricData('Critical Path', '6', Color(0xFFF59E0B)),
          _MetricData('Variance', '+3 days', Color(0xFFEF4444)),
        ],
        sections: const [
          _SectionData(
            title: 'Major Milestones',
            subtitle: 'High-level checkpoints across delivery.',
            bullets: [
              _BulletData('Project kickoff and charter sign-off', true),
              _BulletData('Design freeze and stakeholder approval', true),
              _BulletData('Build complete and QA sign-off', true),
              _BulletData('Go-live readiness review', true),
            ],
          ),
          _SectionData(
            title: 'Phase Timeline',
            subtitle: 'Planned status by phase.',
            statusRows: [
              _StatusRowData('Planning', 'Complete', Color(0xFF10B981)),
              _StatusRowData('Design', 'In Progress', Color(0xFFF59E0B)),
              _StatusRowData('Build', 'Not Started', Color(0xFF94A3B8)),
            ],
          ),
          _SectionData(
            title: 'Dependency Highlights',
            subtitle: 'External dependencies that impact the schedule.',
            bullets: [
              _BulletData('Vendor contract execution before Build', false),
              _BulletData('Infrastructure provisioning before Integration', false),
              _BulletData('Compliance review before Launch', false),
            ],
          ),
          _SectionData(
            title: 'Governance Cadence',
            subtitle: 'Executive checkpoints for schedule validation.',
            bullets: [
              _BulletData('Weekly schedule steering review', false),
              _BulletData('Monthly sponsor checkpoint', false),
              _BulletData('Critical path risk review', false),
            ],
          ),
        ],
      ),
    );
  }
}

class ProjectPlanDetailedScheduleScreen extends StatelessWidget {
  const ProjectPlanDetailedScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProjectPlanSectionScreen(
      config: _ProjectPlanSectionConfig(
        title: 'Detailed Project Schedule',
        subtitle: 'Track task-level sequencing, owners, and resource loading.',
        noteKey: 'planning_project_plan_detailed_notes',
        checkpoint: 'project_plan_detailed_schedule',
        activeItemLabel: 'Project Plan - Detailed Project Schedule',
        metrics: const [
          _MetricData('Tasks', '248', Color(0xFF2563EB)),
          _MetricData('Workstreams', '8', Color(0xFF10B981)),
          _MetricData('Resource Load', '92%', Color(0xFFF59E0B)),
          _MetricData('Baseline Delta', '-2 days', Color(0xFF8B5CF6)),
        ],
        sections: const [
          _SectionData(
            title: 'Workstream Breakdown',
            subtitle: 'Task volume by workstream.',
            statusRows: [
              _StatusRowData('Product', '42 tasks', Color(0xFF2563EB)),
              _StatusRowData('Engineering', '106 tasks', Color(0xFF10B981)),
              _StatusRowData('Operations', '38 tasks', Color(0xFFF59E0B)),
              _StatusRowData('Data', '24 tasks', Color(0xFF8B5CF6)),
            ],
          ),
          _SectionData(
            title: 'Critical Path Tasks',
            subtitle: 'Tasks with zero float.',
            bullets: [
              _BulletData('Finalize architecture diagrams', true),
              _BulletData('API integration testing', true),
              _BulletData('Security review sign-off', true),
            ],
          ),
          _SectionData(
            title: 'Resource Allocation',
            subtitle: 'High-load areas this sprint.',
            bullets: [
              _BulletData('Frontend squad at 98% capacity', false),
              _BulletData('QA team aligned for regression run', false),
              _BulletData('Infra team reserved for staging rollout', false),
            ],
          ),
          _SectionData(
            title: 'Lookahead (6 weeks)',
            subtitle: 'Near-term schedule commitments.',
            bullets: [
              _BulletData('Complete design QA and handoff', false),
              _BulletData('Finish integration build for core flows', false),
              _BulletData('Start pilot runbook validation', false),
            ],
          ),
        ],
      ),
    );
  }
}

class ProjectPlanCondensedSummaryScreen extends StatelessWidget {
  const ProjectPlanCondensedSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProjectPlanSectionScreen(
      config: _ProjectPlanSectionConfig(
        title: 'Condensed Project Summary',
        subtitle: 'A concise executive view of schedule, cost, and readiness.',
        noteKey: 'planning_project_plan_condensed_notes',
        checkpoint: 'project_plan_condensed_summary',
        activeItemLabel: 'Project Plan - Condensed Project Summary',
        metrics: const [
          _MetricData('Duration', '42 weeks', Color(0xFF2563EB)),
          _MetricData('Budget', '\$1.8M', Color(0xFF10B981)),
          _MetricData('Teams', '6', Color(0xFFF59E0B)),
          _MetricData('Readiness', '78%', Color(0xFF8B5CF6)),
        ],
        sections: const [
          _SectionData(
            title: 'Executive Highlights',
            subtitle: 'One-line narrative of the plan.',
            bullets: [
              _BulletData('Schedule aligns with Q4 go-live target', true),
              _BulletData('Budget coverage secured for core scope', true),
              _BulletData('Critical dependencies tracked weekly', true),
            ],
          ),
          _SectionData(
            title: 'Timeline Snapshot',
            subtitle: 'Phase timing at a glance.',
            statusRows: [
              _StatusRowData('Planning', 'Jan - Mar', Color(0xFF2563EB)),
              _StatusRowData('Design', 'Apr - May', Color(0xFF10B981)),
              _StatusRowData('Build', 'Jun - Sep', Color(0xFFF59E0B)),
              _StatusRowData('Launch', 'Oct', Color(0xFF8B5CF6)),
            ],
          ),
          _SectionData(
            title: 'Risk Watchlist',
            subtitle: 'Top schedule risks to monitor.',
            bullets: [
              _BulletData('Vendor hardware lead time variance', false),
              _BulletData('Integration test environment capacity', false),
              _BulletData('Security review turnaround', false),
            ],
          ),
          _SectionData(
            title: 'Decision Log',
            subtitle: 'Open decisions impacting scope or timing.',
            statusRows: [
              _StatusRowData('Scope freeze date', 'Approved', Color(0xFF10B981)),
              _StatusRowData('Change window', 'Pending', Color(0xFFF59E0B)),
              _StatusRowData('Budget contingency', 'In Review', Color(0xFF2563EB)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectPlanSectionScreen extends StatelessWidget {
  const _ProjectPlanSectionScreen({required this.config});

  final _ProjectPlanSectionConfig config;

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
                              description: 'Capture plan assumptions, deadlines, and key constraints.',
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

class _ProjectPlanSectionConfig {
  const _ProjectPlanSectionConfig({
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
