import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';

class StartUpPlanningOperationsScreen extends StatelessWidget {
  const StartUpPlanningOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartUpPlanningSectionScreen(
      config: _StartUpPlanningSectionConfig(
        title: 'Operations Plan & Manual',
        subtitle: 'Define runbooks, ownership, and operating procedures for launch readiness.',
        noteKey: 'planning_startup_operations_notes',
        checkpoint: 'startup_planning_operations',
        activeItemLabel: 'Start-Up Planning - Operations Plan and Manual',
        metrics: const [
          _MetricData('Runbooks', '8', Color(0xFF2563EB)),
          _MetricData('SOPs', '12', Color(0xFF10B981)),
          _MetricData('SLA Coverage', '95%', Color(0xFFF59E0B)),
          _MetricData('Escalation Paths', '4', Color(0xFF8B5CF6)),
        ],
        sections: const [
          _SectionData(
            title: 'Operations Manual',
            subtitle: 'Key procedures required for day-one support.',
            bullets: [
              _BulletData('Incident response flow and severity definitions', true),
              _BulletData('Service ownership matrix by component', true),
              _BulletData('Customer escalation and communication plan', true),
            ],
          ),
          _SectionData(
            title: 'Runbook Coverage',
            subtitle: 'Status of critical operational runbooks.',
            statusRows: [
              _StatusRowData('Deployment rollback', 'Ready', Color(0xFF10B981)),
              _StatusRowData('Database recovery', 'In Review', Color(0xFFF59E0B)),
              _StatusRowData('Third-party outage', 'Draft', Color(0xFF94A3B8)),
            ],
          ),
          _SectionData(
            title: 'Service Ownership',
            subtitle: 'Ownership coverage across operations domains.',
            bullets: [
              _BulletData('Platform monitoring: SRE Team', false),
              _BulletData('API performance: Backend Lead', false),
              _BulletData('Vendor support: Procurement Ops', false),
            ],
          ),
          _SectionData(
            title: 'Support Channels',
            subtitle: 'Primary channels for incident and user support.',
            bullets: [
              _BulletData('On-call rotation: 24/7 escalation', false),
              _BulletData('Launch war room: Daily standups', false),
              _BulletData('Customer support desk: Tiered intake', false),
            ],
          ),
        ],
      ),
    );
  }
}

class StartUpPlanningHypercareScreen extends StatelessWidget {
  const StartUpPlanningHypercareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartUpPlanningSectionScreen(
      config: _StartUpPlanningSectionConfig(
        title: 'Hypercare Plan',
        subtitle: 'Define post-launch monitoring, coverage, and escalation routines.',
        noteKey: 'planning_startup_hypercare_notes',
        checkpoint: 'startup_planning_hypercare',
        activeItemLabel: 'Start-Up Planning - Hypercare Plan',
        metrics: const [
          _MetricData('Hypercare Days', '14', Color(0xFF2563EB)),
          _MetricData('Coverage Shifts', '3', Color(0xFF10B981)),
          _MetricData('Open Sev-1', '0', Color(0xFFF59E0B)),
          _MetricData('Critical Alerts', '18', Color(0xFFEF4444)),
        ],
        sections: const [
          _SectionData(
            title: 'Coverage & War Room',
            subtitle: 'Plan the operational coverage for launch period.',
            bullets: [
              _BulletData('24/7 coverage for first 7 days', true),
              _BulletData('Daily war room sync with owners', true),
              _BulletData('Dedicated triage lead per shift', true),
            ],
          ),
          _SectionData(
            title: 'Issue Triage Process',
            subtitle: 'Escalation and priority management.',
            bullets: [
              _BulletData('Sev-1 response within 30 minutes', false),
              _BulletData('Daily incident review and RCA log', false),
              _BulletData('Product sign-off for severity changes', false),
            ],
          ),
          _SectionData(
            title: 'Monitoring Focus',
            subtitle: 'Systems to monitor closely after launch.',
            bullets: [
              _BulletData('API latency and error rates', false),
              _BulletData('Payment gateway success rate', false),
              _BulletData('User onboarding drop-off', false),
            ],
          ),
          _SectionData(
            title: 'Communications Cadence',
            subtitle: 'Stakeholder updates during hypercare.',
            bullets: [
              _BulletData('Twice-daily stakeholder updates', false),
              _BulletData('Incident broadcast within 15 minutes', false),
              _BulletData('Executive summary every 48 hours', false),
            ],
          ),
        ],
      ),
    );
  }
}

class StartUpPlanningDevOpsScreen extends StatelessWidget {
  const StartUpPlanningDevOpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartUpPlanningSectionScreen(
      config: _StartUpPlanningSectionConfig(
        title: 'DevOps',
        subtitle: 'Assess pipeline readiness, environments, and automation coverage.',
        noteKey: 'planning_startup_devops_notes',
        checkpoint: 'startup_planning_devops',
        activeItemLabel: 'Start-Up Planning - DevOps',
        metrics: const [
          _MetricData('Pipelines', '6', Color(0xFF2563EB)),
          _MetricData('Environments', '4', Color(0xFF10B981)),
          _MetricData('Release Cadence', 'Weekly', Color(0xFFF59E0B)),
          _MetricData('Automation', '78%', Color(0xFF8B5CF6)),
        ],
        sections: const [
          _SectionData(
            title: 'CI/CD Status',
            subtitle: 'Pipeline checks for release readiness.',
            statusRows: [
              _StatusRowData('Build & unit tests', 'Passing', Color(0xFF10B981)),
              _StatusRowData('Security scans', 'Scheduled', Color(0xFFF59E0B)),
              _StatusRowData('Release gates', 'Configured', Color(0xFF2563EB)),
            ],
          ),
          _SectionData(
            title: 'Environment Readiness',
            subtitle: 'Stability across environments.',
            bullets: [
              _BulletData('Prod & staging parity verified', true),
              _BulletData('Disaster recovery drills scheduled', true),
              _BulletData('Performance baselines captured', true),
            ],
          ),
          _SectionData(
            title: 'Deployment Checklist',
            subtitle: 'Steps required for release readiness.',
            bullets: [
              _BulletData('Release notes approved', false),
              _BulletData('Rollback procedures documented', false),
              _BulletData('Feature flags configured', false),
            ],
          ),
          _SectionData(
            title: 'Observability',
            subtitle: 'Monitoring & alerting coverage.',
            bullets: [
              _BulletData('Synthetic tests active', false),
              _BulletData('Alert thresholds tuned', false),
              _BulletData('Dashboards shared with stakeholders', false),
            ],
          ),
        ],
      ),
    );
  }
}

class StartUpPlanningCloseOutPlanScreen extends StatelessWidget {
  const StartUpPlanningCloseOutPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartUpPlanningSectionScreen(
      config: _StartUpPlanningSectionConfig(
        title: 'Close Out Plan',
        subtitle: 'Outline post-launch closure activities and acceptance criteria.',
        noteKey: 'planning_startup_closeout_notes',
        checkpoint: 'startup_planning_closeout',
        activeItemLabel: 'Start-Up Planning - Close Out Plan',
        metrics: const [
          _MetricData('Close-out Tasks', '18', Color(0xFF2563EB)),
          _MetricData('Approvals', '6', Color(0xFF10B981)),
          _MetricData('Archive Items', '12', Color(0xFFF59E0B)),
          _MetricData('Lessons Logged', '4', Color(0xFF8B5CF6)),
        ],
        sections: const [
          _SectionData(
            title: 'Close Out Checklist',
            subtitle: 'Key activities after launch stabilization.',
            bullets: [
              _BulletData('Finalize documentation and runbooks', true),
              _BulletData('Obtain final stakeholder sign-off', true),
              _BulletData('Confirm support handoff completion', true),
            ],
          ),
          _SectionData(
            title: 'Approval Tracker',
            subtitle: 'Approval status by stakeholder group.',
            statusRows: [
              _StatusRowData('Executive sponsor', 'Pending', Color(0xFFF59E0B)),
              _StatusRowData('Product owner', 'Approved', Color(0xFF10B981)),
              _StatusRowData('Security', 'In Review', Color(0xFF2563EB)),
            ],
          ),
          _SectionData(
            title: 'Archive & Access',
            subtitle: 'Artifacts and access to archive.',
            bullets: [
              _BulletData('Project documentation stored in archive', false),
              _BulletData('Repository access updated for maintenance', false),
              _BulletData('Vendor contracts stored and tagged', false),
            ],
          ),
          _SectionData(
            title: 'Post-Launch Review',
            subtitle: 'Capture learnings and improvement actions.',
            bullets: [
              _BulletData('Retro session scheduled', false),
              _BulletData('Metrics report finalized', false),
              _BulletData('Improvement backlog created', false),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartUpPlanningSectionScreen extends StatelessWidget {
  const _StartUpPlanningSectionScreen({required this.config});

  final _StartUpPlanningSectionConfig config;

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
                        final gap = 24.0;
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
                              description: 'Capture critical decisions, dependencies, and readiness updates.',
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

class _StartUpPlanningSectionConfig {
  const _StartUpPlanningSectionConfig({
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
