import 'package:flutter/material.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/text_sanitizer.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';

/// Front End Planning – Contract and Vendor Quotes screen.
/// Mirrors the provided mock with the shared workspace chrome,
/// short notes field, large contract/vendor entry area, and
/// the bottom info + AI hint + next control row.
class FrontEndPlanningContractVendorQuotesScreen extends StatefulWidget {
  const FrontEndPlanningContractVendorQuotesScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const FrontEndPlanningContractVendorQuotesScreen()),
    );
  }

  @override
  State<FrontEndPlanningContractVendorQuotesScreen> createState() =>
      _FrontEndPlanningContractVendorQuotesScreenState();
}

class _FrontEndPlanningContractVendorQuotesScreenState
    extends State<FrontEndPlanningContractVendorQuotesScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _contractsController = TextEditingController();
  bool _isSyncReady = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ProjectDataHelper.getData(context);
      _contractsController.text = data.frontEndPlanning.contractVendorQuotes;
      _contractsController.addListener(_syncContractsToProvider);
      _isSyncReady = true;
      _syncContractsToProvider();
      if (_contractsController.text.trim().isEmpty) {
        _generateAiSuggestion();
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _regenerateAllContracts() async {
    await _generateAiSuggestion();
  }

  Future<void> _generateAiSuggestion() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final data = ProjectDataHelper.getData(context);
      final provider = ProjectDataHelper.getProvider(context);
      final ctx = ProjectDataHelper.buildFepContext(data,
          sectionLabel: 'Contract & Vendor Quotes');
      
      // Track field history before regenerating
      if (_contractsController.text.trim().isNotEmpty) {
        provider.addFieldToHistory(
          'fep_contract_vendor_quotes_content',
          _contractsController.text,
          isAiGenerated: true,
        );
      }
      
      final ai = OpenAiServiceSecure();
      final suggestion = await ai.generateFepSectionText(
          section: 'Contract & Vendor Quotes',
          context: ctx,
          maxTokens: 900,
          temperature: 0.55);
      if (!mounted) return;
      final cleaned = TextSanitizer.sanitizeAiText(suggestion).trim();
      if (cleaned.isNotEmpty) {
        // Track new AI-generated content
        provider.addFieldToHistory(
          'fep_contract_vendor_quotes_content',
          cleaned,
          isAiGenerated: true,
        );
        
        setState(() {
          _contractsController.text = cleaned;
          _syncContractsToProvider();
        });
        await ProjectDataHelper.getProvider(context)
            .saveToFirebase(checkpoint: 'fep_contracts');
      }
    } catch (e) {
      debugPrint('AI contracts suggestion failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Regenerate failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  void dispose() {
    if (_isSyncReady) {
      _contractsController.removeListener(_syncContractsToProvider);
    }
    _notesController.dispose();
    _contractsController.dispose();
    super.dispose();
  }

  void _syncContractsToProvider() {
    if (!mounted || !_isSyncReady) return;
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          contractVendorQuotes: _contractsController.text.trim(),
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
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Contract & Vendor Quotes'),
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
                                  controller: _notesController,
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
                                        EditableContentText(
                                          contentKey: 'fep_contract_vendor_quotes_title',
                                          fallback: 'Contract and Vendor Quotes',
                                          category: 'front_end_planning',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        EditableContentText(
                                          contentKey: 'fep_contract_vendor_quotes_subtitle',
                                          fallback: '(Brief explanation here)',
                                          category: 'front_end_planning',
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
                                        await _regenerateAllContracts();
                                      }
                                    },
                                    isLoading: _generating,
                                    tooltip: 'Regenerate all contract and vendor quotes content',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _ContractsPanel(controller: _contractsController),
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _BottomOverlay(onNext: () async {
                    await ProjectDataHelper.saveAndNavigate(
                      context: context,
                      checkpoint: 'fep_contracts',
                      nextScreenBuilder: () =>
                          const FrontEndPlanningProcurementScreen(),
                      dataUpdater: (data) => data.copyWith(
                        frontEndPlanning: ProjectDataHelper.updateFEPField(
                          current: data.frontEndPlanning,
                          contractVendorQuotes:
                              _contractsController.text.trim(),
                        ),
                      ),
                    );
                  }),
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

class _ContractsPanel extends StatelessWidget {
  const _ContractsPanel({required this.controller});

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
  const _BottomOverlay({required this.onNext});

  final VoidCallback onNext;

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
                          'Focus on major risks associated with each potential solution.',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF6C437),
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
