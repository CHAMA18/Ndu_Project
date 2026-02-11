import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/architecture_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/services/sidebar_navigation_service.dart';
import 'package:ndu_project/utils/navigation_route_resolver.dart';
import 'package:ndu_project/utils/phase_transition_helper.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/text_sanitizer.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class DesignPhaseScreen extends StatefulWidget {
  const DesignPhaseScreen({super.key, this.activeItemLabel = 'Design Management'});

  final String activeItemLabel;

  static void open(
    BuildContext context, {
    String activeItemLabel = 'Design Management',
    String destinationCheckpoint = 'design_management',
  }) {
    PhaseTransitionHelper.pushPhaseAware(
      context: context,
      builder: (_) => DesignPhaseScreen(activeItemLabel: activeItemLabel),
      destinationCheckpoint: destinationCheckpoint,
    );
  }

  @override
  State<DesignPhaseScreen> createState() => _DesignPhaseScreenState();
}

class _DesignPhaseScreenState extends State<DesignPhaseScreen> {
  static const _saveDebounceDuration = Duration(milliseconds: 600);

  final TextEditingController _designPlanController = TextEditingController();

  String? _projectId;
  bool _isSaving = false;
  bool _isGeneratingAi = false;
  bool _isHydrating = false;
  DateTime? _lastSavedAt;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _designPlanController.addListener(_onDesignPlanChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final pid = provider?.projectData.projectId;
      if (pid == null || pid.isEmpty) return;

      if (mounted) {
        setState(() => _projectId = pid);
      }

      await _loadPersisted(pid);

      // Save this page as the last visited page for the project.
      await ProjectNavigationService.instance.saveLastPage(pid, 'design');
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _designPlanController.removeListener(_onDesignPlanChanged);
    _designPlanController.dispose();
    super.dispose();
  }

  void _onDesignPlanChanged() {
    if (_isHydrating) return;
    _scheduleAutoSave();
  }

  Future<void> _loadPersisted(String projectId) async {
    try {
      final data = await ArchitectureService.load(projectId);
      if (data == null) return;

      final existingText = data['designPlan']?.toString() ?? '';
      if (existingText.trim().isEmpty) return;

      _isHydrating = true;
      _designPlanController.text = TextSanitizer.sanitizeAiText(existingText);
      _designPlanController.selection = TextSelection.fromPosition(
        TextPosition(offset: _designPlanController.text.length),
      );
    } catch (e, st) {
      debugPrint('Failed to load design plan: $e\n$st');
    } finally {
      _isHydrating = false;
    }
  }

  void _scheduleAutoSave() {
    if (_projectId == null || _projectId!.isEmpty) return;

    _saveDebounce?.cancel();
    if (mounted) {
      setState(() => _isSaving = true);
    }

    _saveDebounce = Timer(_saveDebounceDuration, () async {
      try {
        await ArchitectureService.save(_projectId!, {
          'designPlan': _designPlanController.text,
        });

        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _lastSavedAt = DateTime.now();
        });
      } catch (e, st) {
        debugPrint('Failed to autosave design plan: $e\n$st');
        if (!mounted) return;
        setState(() => _isSaving = false);
      }
    });
  }

  Future<String> _buildDesignAiContext() async {
    final projectData = ProjectDataHelper.getData(context);
    final baseContext = ProjectDataHelper.buildFepContext(
      projectData,
      sectionLabel: 'Design Plan',
    );

    final buffer = StringBuffer();
    if (baseContext.trim().isNotEmpty) {
      buffer.writeln(baseContext.trim());
      buffer.writeln();
    }

    final draftText = _designPlanController.text.trim();
    if (draftText.isNotEmpty) {
      buffer.writeln('Current Design Plan Draft:');
      buffer.writeln(draftText);
      buffer.writeln();
    }

    if (_projectId != null && _projectId!.isNotEmpty) {
      final persisted = await ArchitectureService.load(_projectId!);
      final persistedDraft = TextSanitizer.sanitizeAiText(
        persisted?['designPlan']?.toString() ?? '',
      ).trim();
      if (persistedDraft.isNotEmpty && persistedDraft != draftText) {
        buffer.writeln('Saved Design Plan Draft:');
        buffer.writeln(persistedDraft);
        buffer.writeln();
      }
    }

    return buffer.toString().trim();
  }

  String _resolveCurrentCheckpoint() {
    final checkpoint =
        ProjectDataInherited.maybeOf(context)?.projectData.currentCheckpoint;
    final normalized = checkpoint?.trim() ?? '';
    if (normalized.isNotEmpty) {
      return normalized;
    }

    if (widget.activeItemLabel == 'Design') {
      return 'design';
    }
    if (widget.activeItemLabel == 'Design Management') {
      return 'design_management';
    }
    return 'design';
  }

  SidebarItem? _resolveNextSidebarItem() {
    final currentCheckpoint = _resolveCurrentCheckpoint();
    return SidebarNavigationService.instance.getNextItem(currentCheckpoint);
  }

  Future<void> _navigateToNextSidebarScreen() async {
    final nextItem = _resolveNextSidebarItem();
    if (nextItem == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No next sidebar page is available.')),
      );
      return;
    }

    final nextScreen = NavigationRouteResolver.resolveCheckpointToScreen(
      nextItem.checkpoint,
      context,
    );
    if (nextScreen == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open ${nextItem.label}.'),
        ),
      );
      return;
    }

    final provider = ProjectDataInherited.maybeOf(context);
    final currentCheckpoint = provider?.projectData.currentCheckpoint;

    if (!mounted) return;
    PhaseTransitionHelper.pushPhaseAware(
      context: context,
      builder: (_) => nextScreen,
      destinationCheckpoint: nextItem.checkpoint,
      sourceCheckpoint: currentCheckpoint,
    );

    final projectId = provider?.projectData.projectId;
    if (provider != null && projectId != null && projectId.isNotEmpty) {
      provider.updateField(
        (data) => data.copyWith(currentCheckpoint: nextItem.checkpoint),
      );
      Future<void>(
        () => ProjectNavigationService.instance
            .saveLastPageLocal(projectId, nextItem.checkpoint),
      );
      Future<void>(() async {
        try {
          await provider.saveToFirebase(checkpoint: nextItem.checkpoint);
        } catch (e, st) {
          debugPrint('Failed to save checkpoint ${nextItem.checkpoint}: $e\n$st');
        }
      });
    }
  }

  Future<void> _generateWithAi() async {
    if (_isGeneratingAi) return;

    setState(() => _isGeneratingAi = true);

    try {
      final contextText = await _buildDesignAiContext();

      if (contextText.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project context is empty. Add project details or a draft first.'),
          ),
        );
        return;
      }

      final generated = await OpenAiServiceSecure().generateFepSectionText(
        section: 'Design Plan',
        context: contextText,
        maxTokens: 1000,
        temperature: 0.45,
      );

      if (!mounted) return;

      final sanitized = TextSanitizer.sanitizeAiText(generated);
      if (sanitized.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI returned empty content.')),
        );
        return;
      }

      _designPlanController.text = sanitized;
      _designPlanController.selection = TextSelection.fromPosition(
        TextPosition(offset: _designPlanController.text.length),
      );
      _scheduleAutoSave();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Design plan generated. You can edit it freely.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI generation failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = isMobile ? 16.0 : 24.0;
    final nextSidebarItem = _resolveNextSidebarItem();
    final nextButtonLabel = nextSidebarItem?.label ?? 'Next';

    return ResponsiveScaffold(
      activeItemLabel: widget.activeItemLabel,
      body: Column(
        children: [
          PlanningPhaseHeader(
            title: 'Design',
            showImportButton: false,
            showContentButton: false,
            onForward: _navigateToNextSidebarScreen,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PlanningAiNotesCard(
                    title: 'Notes',
                    sectionLabel: 'Design',
                    noteKey: 'planning_design_notes',
                    checkpoint: 'design',
                    description:
                        'Summarize design goals, artifacts, and key decisions.',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Design Plan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Draft your planning-phase design plan below. Use AI to generate a starting point, then refine it as needed.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  _buildDesignPlanEditor(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          LaunchPhaseNavigation(
            backLabel: 'Back: Design overview',
            nextLabel: nextButtonLabel,
            onBack: () => Navigator.of(context).maybePop(),
            onNext: _navigateToNextSidebarScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildDesignPlanEditor() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isGeneratingAi ? null : _generateWithAi,
                  icon: _isGeneratingAi
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isGeneratingAi ? 'Generating...' : 'Generate with AI'),
                ),
                const Spacer(),
                Text(
                  _isSaving
                      ? 'Saving...'
                      : _lastSavedAt != null
                          ? 'Saved ${TimeOfDay.fromDateTime(_lastSavedAt!).format(context)}'
                          : 'No changes yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isSaving ? Colors.orange[700] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _designPlanController,
              minLines: 16,
              maxLines: null,
              decoration: const InputDecoration(
                hintText:
                    'Type your design plan here. AI-generated content remains fully editable.',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(14),
              ),
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
