import 'package:flutter/material.dart';

import 'phase_detail_template.dart';

class ProgressTrackingScreen extends StatelessWidget {
  const ProgressTrackingScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProgressTrackingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const PhaseDetailScreen(
      data: _progressTrackingData,
      activeSidebarLabel: 'Progress Tracking',
    );
  }
}

const PhasePageData _progressTrackingData = PhasePageData(
  title: 'Progress Tracking Command Center',
  subtitle: 'Execution Phase',
  description:
      'Instrument delivery momentum with real-time visibility into milestones, dependencies, and health signals. Combine operational telemetry and human insight to keep the roadmap on track.',
  tagline:
      'Power every decision with live progress intelligence, predictive alerts, and automated storytelling for stakeholders.',
  callToActionLabel: 'Open Performance Dashboard',
  accentColor: Color(0xFF22C55E),
  heroHighlights: [
    '87% milestones delivered on or ahead of plan',
    '12 / 12 OKRs fully instrumented',
    'Risk triggers auto-escalated within 15 minutes',
  ],
  metrics: [
    PhaseMetric(label: 'Sprint Velocity', value: '34 pts', trend: '+12% vs. avg', trendIsPositive: true),
    PhaseMetric(label: 'Milestone Completion', value: '87%', trend: '+9% month-over-month', trendIsPositive: true),
    PhaseMetric(label: 'Open Risk Alerts', value: '2 active', trend: '-3 this month', trendIsPositive: true),
  ],
  focusAreas: [
    PhaseFocusArea(
      title: 'Unified Dashboards',
      caption: 'Blend roadmap, delivery, and operational telemetry into curated command views tailored for each stakeholder tier.',
      points: [
        'Connect Jira / Azure DevOps with financial and CX systems',
        'Design executive, squad, and partner dashboards with focus metrics',
        'Align dashboards to OKR pillars and key results',
      ],
    ),
    PhaseFocusArea(
      title: 'Predictive Analytics',
      caption: 'Surface red flags early with machine learning signals across throughput, quality, and sentiment.',
      points: [
        'Monitor burn-up, cycle time, and WIP limits for drift',
        'Enrich dashboards with engineering quality and release KPIs',
        'Trigger automated alerts when thresholds or trends break',
      ],
    ),
    PhaseFocusArea(
      title: 'Performance Rituals',
      caption: 'Use storytelling, demos, and data-driven reviews to celebrate wins and course correct with speed.',
      points: [
        'Run weekly demo theatre for stakeholders',
        'Publish progress narratives with context and next bets',
        'Document learning loops and integrate into retrospectives',
      ],
    ),
  ],
  timeline: [
    PhaseTimelineItem(
      label: 'Telemetry Intake & Mapping',
      description: 'Audit data sources, KPIs, and owners. Establish single source of truth with governance guardrails.',
      timeframe: 'Week 0',
    ),
    PhaseTimelineItem(
      label: 'Dashboard Fabrication',
      description: 'Develop curated dashboards and storytelling templates for squads, executives, and partners.',
      timeframe: 'Week 1',
    ),
    PhaseTimelineItem(
      label: 'Predictive Signal Activation',
      description: 'Enable anomaly detection on velocity, quality, and risk triggers with automated workflows.',
      timeframe: 'Week 2',
    ),
    PhaseTimelineItem(
      label: 'Insights to Action Loop',
      description: 'Review metrics weekly, craft decision memos, and feed insights into backlog prioritization.',
      timeframe: 'Weekly',
    ),
  ],
  checklistGroups: [
    PhaseChecklistGroup(
      title: 'Data Foundations',
      items: [
        'Confirm data contracts and refresh cadence for each source',
        'Validate metric definitions and owner accountability',
        'Enable self-serve filters for squads and leadership',
      ],
    ),
    PhaseChecklistGroup(
      title: 'Status Governance',
      items: [
        'Publish weekly status narratives with blockers and asks',
        'Highlight leading indicators not just lag metrics',
        'Map progress signals to risk mitigation plans',
      ],
    ),
    PhaseChecklistGroup(
      title: 'Continuous Improvement',
      items: [
        'Document insights from retrospectives and demos',
        'Track experiments and hypothesis outcomes in dashboard',
        'Celebrate momentum with team-wide recognition moments',
      ],
    ),
  ],
  quickWins: [
    'Automate progress digest to executive Slack channel',
    'Launch live milestone tracker with color-coded confidence',
    'Integrate AI summaries into stakeholder newsletters',
  ],
  resourceLinks: [
    'Progress Intelligence Toolkit',
    'Executive Dashboard Template',
    'Predictive Alerts Cookbook',
  ],
);