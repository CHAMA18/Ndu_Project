import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/execution_phase_page.dart';

class TeamMeetingsScreen extends StatelessWidget {
  const TeamMeetingsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TeamMeetingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const ExecutionPhasePage(
      pageKey: 'team_meetings',
      title: 'Meeting Intelligence Hub',
      subtitle: 'Execution Phase',
      sections: [
        ExecutionSectionSpec(
          key: 'cadence',
          title: 'Cadence & ceremonies',
          description: 'Define meeting cadence, owners, and purpose.',
          includeStatus: true,
          titleLabel: 'Meeting / cadence',
        ),
        ExecutionSectionSpec(
          key: 'agendas',
          title: 'Agendas & prep',
          description: 'Capture agenda templates, pre-reads, and facilitation notes.',
          includeStatus: false,
          titleLabel: 'Agenda item',
        ),
        ExecutionSectionSpec(
          key: 'decisions',
          title: 'Decisions & outcomes',
          description: 'Log decisions and follow-ups from meetings.',
          includeStatus: true,
          titleLabel: 'Decision',
        ),
      ],
    );
  }
}
