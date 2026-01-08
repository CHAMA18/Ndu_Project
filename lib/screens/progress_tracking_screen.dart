import 'package:flutter/material.dart';
import 'package:ndu_project/screens/contracts_tracking_screen.dart';
import 'package:ndu_project/screens/team_meetings_screen.dart';
import 'package:ndu_project/widgets/execution_phase_page.dart';

class ProgressTrackingScreen extends StatelessWidget {
  const ProgressTrackingScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProgressTrackingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExecutionPhasePage(
      pageKey: 'progress_tracking',
      title: 'Progress Tracking Command Center',
      subtitle: 'Execution Phase',
      sections: [
        ExecutionSectionSpec(
          key: 'deliverableUpdates',
          title: 'Deliverable status updates',
          description: 'Add deliverable updates, owners, and status.',
          includeStatus: true,
          titleLabel: 'Deliverable',
        ),
        ExecutionSectionSpec(
          key: 'recurring',
          title: 'Recurring deliverables',
          description: 'Track recurring work (sprints, releases, cadences).',
          includeStatus: true,
          titleLabel: 'Recurring item',
        ),
        ExecutionSectionSpec(
          key: 'reports',
          title: 'Status reports & asks',
          description: 'Log stakeholder updates, risks, and asks.',
          includeStatus: true,
          titleLabel: 'Report / ask',
        ),
      ],
      navigation: PhaseNavigationSpec(
        backLabel: 'Back: Team Meetings',
        nextLabel: 'Next: Contracts Tracking',
        onBack: () => TeamMeetingsScreen.open(context),
        onNext: () => ContractsTrackingScreen.open(context),
      ),
    );
  }
}
