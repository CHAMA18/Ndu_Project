import 'package:flutter/material.dart';
import 'package:ndu_project/screens/project_activities_log_screen.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';

/// Standardized header for all Front End Planning pages
/// Displays: back button, title, and user profile with email and role
class FrontEndPlanningHeader extends StatelessWidget {
  const FrontEndPlanningHeader({
    super.key,
    this.title = 'Front End Planning',
    this.onBackPressed,
    this.scaffoldKey,
    this.showActivityLogAction = true,
    this.onOpenActivityLog,
  });

  final String title;
  final VoidCallback? onBackPressed;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool showActivityLogAction;
  final VoidCallback? onOpenActivityLog;

  @override
  Widget build(BuildContext context) {
    return UnifiedPhaseHeader(
      title: title,
      scaffoldKey: scaffoldKey,
      onBackPressed: onBackPressed,
      trailingActions: showActivityLogAction
          ? [
              _buildActivityLogAction(
                context,
                MediaQuery.sizeOf(context).width < 600,
              ),
            ]
          : const <Widget>[],
    );
  }

  Widget _buildActivityLogAction(BuildContext context, bool isMobile) {
    final action =
        onOpenActivityLog ?? () => ProjectActivitiesLogScreen.open(context);

    return Tooltip(
      message: 'Project Activity Log',
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD873)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 18,
                color: Color(0xFFB45309),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 6),
                const Text(
                  'Activity Log',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
