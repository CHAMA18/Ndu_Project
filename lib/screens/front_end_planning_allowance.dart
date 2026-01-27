import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/screens/project_charter_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';

/// Front End Planning – Allowance screen
/// Mirrors the provided layout with shared workspace chrome,
/// large notes area, allowance text panel, and AI hint + Next controls.
class FrontEndPlanningAllowanceScreen extends StatefulWidget {
  const FrontEndPlanningAllowanceScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const FrontEndPlanningAllowanceScreen()),
    );
  }

  @override
  State<FrontEndPlanningAllowanceScreen> createState() =>
      _FrontEndPlanningAllowanceScreenState();
}

class _FrontEndPlanningAllowanceScreenState
    extends State<FrontEndPlanningAllowanceScreen> {
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _allowanceNotes = TextEditingController();
  bool _isSyncReady = false;
  bool _isGenerating = false;
  late final OpenAiServiceSecure _openAi;

  @override
  void initState() {
    super.initState();
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = ProjectDataHelper.getData(context);
      _allowanceNotes.text = data.frontEndPlanning.allowance;
      _allowanceNotes.addListener(_syncAllowanceToProvider);
      _isSyncReady = true;
      _syncAllowanceToProvider();

      // Auto-generate allowance content if empty
      if (_allowanceNotes.text.trim().isEmpty) {
        await _generateAllowanceContent();
      }

      if (mounted) setState(() {});
    });
  }

  Future<void> _regenerateAllAllowance() async {
    await _generateAllowanceContent();
  }

  Future<void> _generateAllowanceContent() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final data = ProjectDataHelper.getData(context);
      final projectContext =
          ProjectDataHelper.buildFepContext(data, sectionLabel: 'Allowance');

      if (projectContext.trim().isNotEmpty) {
        try {
          final generatedText = await _openAi.generateFepSectionText(
            section: 'Allowance',
            context: projectContext,
            maxTokens: 800,
          );

          if (mounted && generatedText.isNotEmpty) {
            setState(() {
              _allowanceNotes.text = generatedText;
              _syncAllowanceToProvider();
            });
            await ProjectDataHelper.getProvider(context)
                .saveToFirebase(checkpoint: 'fep_allowance');
          }
        } catch (e) {
          debugPrint('Error generating allowance content: $e');
          // Use fallback content
          if (mounted) {
            setState(() {
              _allowanceNotes.text = _getFallbackAllowanceContent(data);
              _syncAllowanceToProvider();
            });
          }
        }
      } else {
        // Use fallback if no context available
        if (mounted) {
          setState(() {
            _allowanceNotes.text = _getFallbackAllowanceContent(data);
            _syncAllowanceToProvider();
          });
        }
      }
    } catch (e) {
      debugPrint('Error in allowance generation: $e');
      // Use fallback content
      if (mounted) {
        final data = ProjectDataHelper.getData(context);
        setState(() {
          _allowanceNotes.text = _getFallbackAllowanceContent(data);
          _syncAllowanceToProvider();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }


  String _getFallbackAllowanceContent(ProjectDataModel data) {
    return '''Budget Allowances and Contingencies

Project Budget Allocation:
- Allocate 10-15% of total project budget as contingency reserve for unforeseen expenses
- Set aside 5-10% for scope changes and requirement modifications
- Reserve 3-5% for risk mitigation activities

Cost Categories:
- Labor costs: Include buffer for overtime, training, and knowledge transfer
- Material and equipment: Account for price fluctuations and delivery delays
- Third-party services: Include contingency for vendor cost overruns
- Infrastructure: Reserve funds for additional capacity or upgrades

Contingency Management:
- Establish approval process for accessing contingency funds
- Track contingency usage against project milestones
- Review and adjust contingency allocation based on project progress

Risk-Based Allowances:
- High-risk areas: Allocate additional 10-15% contingency
- Medium-risk areas: Standard 5-10% contingency
- Low-risk areas: Minimal 2-5% contingency

Change Management:
- Budget for approved change requests and scope expansions
- Maintain separate change order budget tracking
- Document all budget adjustments and approvals

Financial Controls:
- Implement regular budget reviews and variance analysis
- Establish spending thresholds and approval limits
- Monitor actual costs against budgeted amounts monthly''';
  }

  @override
  void dispose() {
    if (_isSyncReady) {
      _allowanceNotes.removeListener(_syncAllowanceToProvider);
    }
    _notes.dispose();
    _allowanceNotes.dispose();
    super.dispose();
  }

  void _syncAllowanceToProvider() {
    if (!mounted || !_isSyncReady) return;
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          allowance: _allowanceNotes.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Allowance'),
            ),
            Expanded(
              child: Stack(
                children: [
                  const AdminEditToggle(),
                  Column(
                    children: [
                      const FrontEndPlanningHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _roundedField(
                                  controller: _notes,
                                  hint: 'Input your notes here...',
                                  minLines: 3),
                              const SizedBox(height: 24),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Allowance',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Define budget allowances and contingencies for the project',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PageRegenerateAllButton(
                                    onRegenerateAll: () async {
                                      final confirmed = await showRegenerateAllConfirmation(context);
                                      if (confirmed && mounted) {
                                        await _regenerateAllAllowance();
                                      }
                                    },
                                    isLoading: _isGenerating,
                                    tooltip: 'Regenerate all allowance content',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _AllowancePanel(controller: _allowanceNotes),
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _BottomOverlay(allowanceController: _allowanceNotes),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllowancePanel extends StatelessWidget {
  const _AllowancePanel({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        minLines: 12,
        maxLines: null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '',
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.allowanceController});

  final TextEditingController allowanceController;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            Positioned(
              left: 24,
              bottom: 24,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                    color: Color(0xFFB3D9FF), shape: BoxShape.circle),
                child: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F1FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD7E5FF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                        SizedBox(width: 10),
                        Text('AI',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB))),
                        SizedBox(width: 12),
                        Text(
                          'Define budget allowances and contingency plans.',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await ProjectDataHelper.saveAndNavigate(
                        context: context,
                        checkpoint: 'fep_allowance',
                        nextScreenBuilder: () => const ProjectCharterScreen(),
                        dataUpdater: (data) => data.copyWith(
                          frontEndPlanning: ProjectDataHelper.updateFEPField(
                            current: data.frontEndPlanning,
                            allowance: allowanceController.text.trim(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC812),
                      foregroundColor: const Color(0xFF111827),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 34, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: const Text('Next',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _roundedField(
    {required TextEditingController controller,
    required String hint,
    int minLines = 1}) {
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
