import 'package:flutter/material.dart';

import 'phase_detail_template.dart';

class TeamMeetingsScreen extends StatelessWidget {
  const TeamMeetingsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TeamMeetingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const PhaseDetailScreen(
      data: _teamMeetingsData,
      activeSidebarLabel: 'Team Meetings',
    );
  }
}

const PhasePageData _teamMeetingsData = PhasePageData(
  title: 'Meeting Intelligence Hub',
  subtitle: 'Execution Phase',
  description:
      'Orchestrate strategic and tactical meetings that unlock alignment, accelerate decisions, and keep progress transparent. Design every interaction with purpose, prep, and measurable outcomes.',
  tagline:
      'Transform recurring meetings into high-energy moments that fuel clarity, unblock teams, and capture insight at the speed of execution.',
  callToActionLabel: 'Schedule Cadence Review',
  accentColor: Color(0xFF0EA5E9),
  heroHighlights: [
    '96% on-time start for critical ceremonies',
    'Avg. 11 decisions unlocked per week',
    'Feedback score 4.7 / 5 from participants',
  ],
  metrics: [
    PhaseMetric(label: 'Decision Throughput', value: '11 / week', trend: '+28% vs. last month', trendIsPositive: true),
    PhaseMetric(label: 'Meeting Equity Score', value: '4.7 / 5', trend: '+0.4 QoQ satisfaction', trendIsPositive: true),
    PhaseMetric(label: 'Time Saved', value: '6 hrs / week', trend: '+3 async updates', trendIsPositive: true),
  ],
  focusAreas: [
    PhaseFocusArea(
      title: 'Cadence Blueprint',
      caption: 'Align ceremonies to delivery rhythm with explicit agendas, pre-reads, and success metrics.',
      points: [
        'Define anchor meetings: stand-ups, squad syncs, executive reviews',
        'Automate pre-read dispatch and expectation nudges',
        'Keep a visible cadence map for all stakeholders',
      ],
    ),
    PhaseFocusArea(
      title: 'Meeting Playbooks',
      caption: 'Equip facilitators with tools to lead inclusive conversations and capture outcomes in real-time.',
      points: [
        'Establish facilitation roles, note-takers, and observers',
        'Leverage live polling to surface risks and dependencies',
        'Track action items with owners before closing the room',
      ],
    ),
    PhaseFocusArea(
      title: 'Outcomes & Follow-up',
      caption: 'Convert outputs into next steps, decisions, and artifacts within 30 minutes of every session.',
      points: [
        'Publish frictionless recaps to shared channels instantly',
        'Link outcomes to Jira, Asana, or Azure DevOps automations',
        'Trigger nudges for overdue actions with AI summarization',
      ],
    ),
  ],
  timeline: [
    PhaseTimelineItem(
      label: 'Ceremony Audit & Redesign',
      description: 'Analyze current cadence, attendee load, and overlapping agendas. Redesign for purpose-fit interactions.',
      timeframe: 'Week 0',
    ),
    PhaseTimelineItem(
      label: 'Playbook Rollout',
      description: 'Deploy facilitator toolkits, async briefing templates, and moment-of-truth prompts.',
      timeframe: 'Week 1',
    ),
    PhaseTimelineItem(
      label: 'Signal-Driven Iteration',
      description: 'Collect sentiment, attendance, and action completion data to fine-tune cadence and formats.',
      timeframe: 'Week 3',
    ),
    PhaseTimelineItem(
      label: 'Quarterly Retrospective',
      description: 'Evolve meeting portfolio with executive sponsors and embed updated rituals into OKR cycles.',
      timeframe: 'Quarterly',
    ),
  ],
  checklistGroups: [
    PhaseChecklistGroup(
      title: 'Before the Meeting',
      items: [
        'Distribute agenda, context, and artifacts 24 hours prior',
        'Confirm the decision, update, or ideation goal for session',
        'Assign facilitator, timekeeper, and live note owner',
      ],
    ),
    PhaseChecklistGroup(
      title: 'During the Meeting',
      items: [
        'Start with progress snapshot and blockers dashboard',
        'Run inclusion cues ensuring every voice is heard',
        'Record decisions, assumptions, and owners in real time',
      ],
    ),
    PhaseChecklistGroup(
      title: 'After the Meeting',
      items: [
        'Send recap with key takeaways and action register',
        'Update roadmap or backlog items triggered by outcomes',
        'Gather micro-feedback to evolve structure and pacing',
      ],
    ),
  ],
  quickWins: [
    'Add 10-minute async check-ins to compress status updates',
    'Use AI co-pilot to surface agenda insights and risks',
    'Set meeting-free innovation blocks every Wednesday',
  ],
  resourceLinks: [
    'Execution Ceremony Playbook',
    'AI Meeting Recap Templates',
    'Leadership Decision Log Board',
  ],
);