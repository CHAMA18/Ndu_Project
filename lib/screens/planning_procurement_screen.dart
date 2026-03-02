import 'package:flutter/material.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';

class PlanningProcurementScreen extends StatelessWidget {
  const PlanningProcurementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlanningProcurementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const FrontEndPlanningProcurementScreen(
      mode: ProcurementScreenMode.planning,
      activeItemLabel: 'Planning Procurement',
    );
  }
}
