import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/screens/front_end_planning_requirements_screen.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';

class FrontEndPlanningWorkspaceScreen extends StatefulWidget {
  const FrontEndPlanningWorkspaceScreen({
    super.key,
    this.initialNotes = '',
    this.initialSummary = '',
  });

  final String initialNotes;
  final String initialSummary;

  static void open(
    BuildContext context, {
    String initialNotes = '',
    String initialSummary = '',
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FrontEndPlanningWorkspaceScreen(
          initialNotes: initialNotes,
          initialSummary: initialSummary,
        ),
      ),
    );
  }

  @override
  State<FrontEndPlanningWorkspaceScreen> createState() => _FrontEndPlanningWorkspaceScreenState();
}

class _FrontEndPlanningWorkspaceScreenState extends State<FrontEndPlanningWorkspaceScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.initialNotes;
    _summaryController.text = widget.initialSummary;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Per request: make the workspace background white
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const AdminEditToggle(),
          SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match the sidebar used on PreferredSolutionAnalysisScreen
                DraggableSidebar(
                  openWidth: AppBreakpoints.sidebarWidth(context),
                  child: const InitiationLikeSidebar(),
                ),
                Expanded(child: _MainPane(notesController: _notesController, summaryController: _summaryController)),
              ],
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }
}

class _MainPane extends StatelessWidget {
  const _MainPane({required this.notesController, required this.summaryController});

  final TextEditingController notesController;
  final TextEditingController summaryController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FrontEndPlanningHeader(),
              const SizedBox(height: 16),
              _roundedField(
                context,
                controller: notesController,
                hint: 'Input your notes here...',
                minLines: 4,
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  EditableContentText(
                    contentKey: 'fep_workspace_summary_title',
                    fallback: 'Summary',
                    category: 'front_end_planning',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                  SizedBox(width: 6),
                  EditableContentText(
                    contentKey: 'fep_workspace_summary_subtitle',
                    fallback: '(Brief explanation here)',
                    category: 'front_end_planning',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _roundedField(
                context,
                controller: summaryController,
                hint: '',
                minLines: 12,
              ),
              const SizedBox(height: 120), // space so bottom button doesn’t overlap scroll content
            ],
          ),
        ),
        Positioned(
          right: 24,
          bottom: 20,
          child: ElevatedButton(
            onPressed: () {
              // Navigate to the Project Requirements page as per new design
              // ignore: deprecated_member_use_from_same_package
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FrontEndPlanningRequirementsScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              elevation: 0,
            ),
            child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _roundedField(BuildContext context, {required TextEditingController controller, required String hint, int minLines = 1}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      padding: const EdgeInsets.all(14),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: null,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
      ),
    );
  }
}
