import 'package:flutter/material.dart';

import 'phase_detail_template.dart';

class StaffTeamScreen extends StatelessWidget {
  const StaffTeamScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StaffTeamScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const PhaseDetailScreen(
      data: _staffTeamData,
      activeSidebarLabel: 'Staff Team',
    );
  }
}

const PhasePageData _staffTeamData = PhasePageData(
  title: 'Staff Team Orchestration',
  subtitle: 'Execution Phase',
  description:
      'Design, mobilize, and elevate the core execution squad with the right blend of full-time, contractor, and partner talent. Deploy an adaptive staffing model that keeps velocity high while protecting institutional knowledge.',
  tagline:
      'Mobilize cross-functional specialists, accelerate onboarding, and safeguard delivery continuity with a people-first execution ecosystem.',
  callToActionLabel: 'Launch Staffing Review',
  accentColor: Color(0xFF4F46E5),
  heroHighlights: [
    'Role coverage across 12 workstreams',
    'Average onboarding time 3.5 days',
    'Capability index sustained at 92%',
  ],
  metrics: [
    PhaseMetric(label: 'Team Filled', value: '26 / 26 roles', trend: '+3 hires this sprint', trendIsPositive: true),
    PhaseMetric(label: 'Onboarding Velocity', value: '3.5 days', trend: '-18% onboarding time', trendIsPositive: true),
    PhaseMetric(label: 'Contractor Utilization', value: '22%', trend: '-5% vs. last month', trendIsPositive: false),
  ],
  focusAreas: [
    PhaseFocusArea(
      title: 'Capability Matrix',
      caption: 'Map squad composition to deliverables to ensure zero risk coverage across critical execution tracks.',
      points: [
        'Align competency tiers to mission-critical features',
        'Highlight succession partners for each leadership role',
        'Pair emerging talent with seasoned delivery leads',
      ],
    ),
    PhaseFocusArea(
      title: 'Adaptive Staffing Pods',
      caption: 'Structure teams around outcomes with a blend of engineering, design, product, and operations anchors.',
      points: [
        'Create pod playbooks with RACI ownership maps',
        'Set clear success metrics per pod and integrate to OKRs',
        'Ensure meeting cadences and rituals reinforce accountability',
      ],
    ),
    PhaseFocusArea(
      title: 'Experience Acceleration',
      caption: 'Deliver concierge onboarding with domain orientation, tooling immersion, and culture anchors within 72 hours.',
      points: [
        'Automate access provisioning and runbook distribution',
        'Schedule welcome immersions with product and operations',
        'Assign launch mentors to maintain psychological safety',
      ],
    ),
  ],
  timeline: [
    PhaseTimelineItem(
      label: 'Squad Blueprint Finalized',
      description: 'Confirm pod composition, squad leads, and escalation partners. Publish coverage dashboard for leadership review.',
      timeframe: 'Week 1',
    ),
    PhaseTimelineItem(
      label: 'Onboarding Wave Deployment',
      description: 'Execute tailored onboarding tracks for each role archetype with tooling certification and domain labs.',
      timeframe: 'Week 2',
    ),
    PhaseTimelineItem(
      label: 'Engagement Rhythm Locked',
      description: 'Institute squad huddles, cross-pod forums, and dependency syncs with transparent documentation.',
      timeframe: 'Week 3',
    ),
    PhaseTimelineItem(
      label: 'Quarterly Talent Calibration',
      description: 'Review performance signals, flight risks, and growth pathways. Align talent investments to roadmap inflection points.',
      timeframe: 'Quarterly',
    ),
  ],
  checklistGroups: [
    PhaseChecklistGroup(
      title: 'Resourcing Readiness',
      items: [
        'Validate compliance and contracting for every hire',
        'Confirm laptop, software, and environment provisioning',
        'Align payroll, billing, and vendor engagement models',
      ],
    ),
    PhaseChecklistGroup(
      title: 'People Operations',
      items: [
        'Publish team directory with biographies and expertise tags',
        'Document working agreements and availability windows',
        'Launch pulse survey to track morale and avoid burnout',
      ],
    ),
    PhaseChecklistGroup(
      title: 'Engagement Excellence',
      items: [
        'Activate recognition rituals and celebration cadence',
        'Host monthly career acceleration clinics for emerging leaders',
        'Refresh staffing plans based on roadmap confidence levels',
      ],
    ),
  ],
  quickWins: [
    'Spin up an automated role coverage dashboard in 30 minutes',
    'Launch welcome kit Microsite with tooling walkthroughs',
    'Embed digital mentorship pairing inside onboarding form',
  ],
  resourceLinks: [
    'Staffing Capacity Calculator',
    'Execution Pod Playbook',
    'Onboarding Experience Checklist',
  ],
);