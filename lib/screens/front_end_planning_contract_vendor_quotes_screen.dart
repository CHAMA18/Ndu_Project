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
import 'package:ndu_project/models/procurement/procurement_models.dart';
import 'package:ndu_project/services/procurement_service.dart';
import 'package:ndu_project/widgets/procurement_tables.dart'; // Updated import
import 'package:ndu_project/widgets/procurement_dialogs.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'dart:convert';

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
  // removed _contractsController
  
  late Stream<List<ProcurementItemModel>> _itemsStream;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    ApiKeyManager.initializeApiKey();
    // Initialize stream - assumes valid project ID available or fetched
    // For now, hardcoded project-1 as seen in other files, or derived from context if possible.
    // Ideally we get projectId from ProjectDataHelper or similar.
    _itemsStream = ProcurementService.streamItems('project-1');
    
    // safe refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) setState(() {});
    });
  }

  Future<void> _openAddItemDialog() async {
    final categoryOptions = const [
      'Materials',
      'Equipment',
      'Services',
      'IT Equipment',
      'Construction Services',
      'Furniture',
      'Security',
      'Logistics',
      'Consulting',
      'Labor'
    ];

    final result = await showDialog<ProcurementItemModel>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return AddItemDialog(
          contextChips: _buildDialogContextChips(),
          categoryOptions: categoryOptions,
        );
      },
    );

    if (result != null) {
      try {
        // We pass the project ID from the result or context. 
        // Result has a temp ID. Service creates real ID.
        // We need to ensure result.projectId is set.
        // The dialog might set it to 'project-1' by default (based on my reading of _AddItemDialog).
        await ProcurementService.createItem(result);
        // Stream will update automatically.
      } catch (e) {
        debugPrint('Error creating item: $e');
      }
    }
  }

  List<Widget> _buildDialogContextChips() {
    final data = ProjectDataHelper.getData(context);
    final chips = <Widget>[
      const ContextChip(label: 'Phase', value: 'Front End Planning'),
    ];
    final projectName = data.projectName.trim();
    if (projectName.isNotEmpty) {
      chips.insert(0, ContextChip(label: 'Project', value: projectName));
    }
    return chips;
  }

  Future<void> _regenerateAllContracts() async {
    setState(() => _generating = true);
    try {
      final data = ProjectDataHelper.getData(context);
      final projectDescription = data.solutionDescription.isNotEmpty
          ? data.solutionDescription
          : data.businessCase;
      final contextText =
          'Project: ${data.projectName}. Description: $projectDescription. '
          'Objective: ${data.projectObjective}. Solution: ${data.solutionDescription}.';

      final prompt = 'Generate a breakdown of potential contractors and procurement vendors needed for this project. '
          'Return a JSON object with a single key "items", which is an array of objects. '
          'Each object must have: "name" (string), "description" (string), "category" (string, choose from: Services, Construction Services, Security, Logistics, Materials, Equipment, IT Equipment, Furniture, Consulting), '
          '"budget" (number, estimated cost), "potential_vendors" (string, comma separated names). '
          'Context: $contextText';

      final response = await OpenAiServiceSecure().generateCompletion(prompt);
      final cleanJson = TextSanitizer.cleanJson(response);
      Map<String, dynamic> parsed = {};
      try {
        parsed = jsonDecode(cleanJson);
      } catch (e) {
        debugPrint('JSON decode error, attempting fallback cleanup: $e');
        // Simple fallback: invalid JSON
        throw Exception('AI returned invalid data format.');
      }
      
      if (parsed.containsKey('items') && parsed['items'] is List) {
        final List<dynamic> items = parsed['items'];
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final newItem = ProcurementItemModel(
              id: '', // Service will assign ID
              projectId: 'project-1',
              name: item['name'] ?? 'New Item',
              description: item['description'] ?? '',
              category: item['category'] ?? 'Equipment',
              budget: (item['budget'] as num?)?.toDouble() ?? 0.0,
              notes: item['potential_vendors'] ?? '', // Storing vendors in notes
              status: ProcurementItemStatus.planning,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await ProcurementService.createItem(newItem);
          }
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contractors and Vendors auto-populated successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error regenerating contracts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating items: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      activeItemLabel: 'Contract & Vendor Quotes',
      backgroundColor: Colors.white,
      floatingActionButton: const KazAiChatBubble(),
      body: Stack(
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
                                  fallback: 'Manage your contractors and vendors below.',
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
                            tooltip: 'Auto-populate Contractors and Vendors',
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _openAddItemDialog,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      StreamBuilder<List<ProcurementItemModel>>(
                        stream: _itemsStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('Error loading items: ${snapshot.error}',
                                  style: const TextStyle(color: Color(0xFFDC2626))),
                            );
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final items = snapshot.data ?? [];
                          // Replaced simple table with split tables
                          return ProcurementTables(items: items);
                        },
                      ),
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
              dataUpdater: (data) => data,
            );
          }),
        ],
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
