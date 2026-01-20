import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/execution_phase_service.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class ExecutionSectionSpec {
  const ExecutionSectionSpec({
    required this.key,
    required this.title,
    required this.description,
    this.includeStatus = true,
    this.titleLabel = 'Title',
  });

  final String key;
  final String title;
  final String description;
  final bool includeStatus;
  final String titleLabel;
}

/// Reusable Execution Phase page builder: blank by default, with pop-up add + Firebase submit.
class ExecutionPhasePage extends StatefulWidget {
  const ExecutionPhasePage({
    super.key,
    required this.pageKey,
    required this.title,
    required this.subtitle,
    required this.sections,
    this.introText,
    this.navigation,
  });

  final String pageKey;
  final String title;
  final String subtitle;
  final String? introText;
  final List<ExecutionSectionSpec> sections;
  final PhaseNavigationSpec? navigation;

  @override
  State<ExecutionPhasePage> createState() => _ExecutionPhasePageState();
}

class _ExecutionPhasePageState extends State<ExecutionPhasePage> {
  final Map<String, List<LaunchEntry>> _sectionData = {};
  bool _submitting = false;
  bool _loading = true;
  String? _submitError;

  /// Get project ID from ProjectDataInherited
  String? get _projectId {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    for (final section in widget.sections) {
      _sectionData[section.key] = <LaunchEntry>[];
    }
    _loadData();
  }

  /// Load existing data from Firebase
  Future<void> _loadData() async {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final data = await ExecutionPhaseService.loadPageData(
        projectId: projectId,
        pageKey: widget.pageKey,
      );
      if (mounted && data != null && data.isNotEmpty) {
        setState(() {
          _sectionData.clear();
          _sectionData.addAll(data);
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error loading execution phase data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: widget.title,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            for (final section in widget.sections) ...[
              LaunchEditableSection(
                title: section.title,
                description: section.description,
                entries: _sectionData[section.key]!,
                onAdd: () => _addEntry(_sectionData[section.key]!, section),
                onRemove: (i) => _removeEntry(section.key, i),
                onEdit: (i, entry) => _editEntry(_sectionData[section.key]!, section, i, entry),
              ),
              const SizedBox(height: 16),
            ],
            _buildSubmitRow(),
            if (widget.navigation != null) ...[
              const SizedBox(height: 24),
              LaunchPhaseNavigation(
                backLabel: widget.navigation!.backLabel,
                nextLabel: widget.navigation!.nextLabel,
                onBack: widget.navigation!.onBack,
                onNext: widget.navigation!.onNext,
              ),
            ],
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 6),
        Text(
          _loading 
            ? '${widget.subtitle} · Loading...'
            : '${widget.subtitle} · Use the add buttons to populate and submit to Firebase.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
        ),
        if (widget.introText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.introText!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4B5563),
                  height: 1.5,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitRow() {
    return Row(
      children: [
        FilledButton.icon(
          onPressed: _submitting ? null : _submitToFirebase,
          icon: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.cloud_upload_outlined),
          label: const Text('Submit to Firebase'),
        ),
        if (_submitError != null) ...[
          const SizedBox(width: 12),
          Text(_submitError!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  Future<void> _addEntry(List<LaunchEntry> target, ExecutionSectionSpec section) async {
    final entry = await showLaunchEntryDialog(
      context,
      titleLabel: section.titleLabel,
      detailsLabel: 'Details',
      includeStatus: section.includeStatus,
    );
    if (entry != null && mounted) {
      setState(() => target.add(entry));
      _autoSave();
    }
  }

  Future<void> _editEntry(List<LaunchEntry> target, ExecutionSectionSpec section, int index, LaunchEntry currentEntry) async {
    final entry = await showLaunchEntryDialog(
      context,
      titleLabel: section.titleLabel,
      detailsLabel: 'Details',
      includeStatus: section.includeStatus,
      initialEntry: currentEntry,
    );
    if (entry != null && mounted) {
      setState(() => target[index] = entry);
      _autoSave();
    }
  }

  void _removeEntry(String sectionKey, int index) {
    setState(() => _sectionData[sectionKey]!.removeAt(index));
    _autoSave();
  }

  Timer? _autoSaveDebounce;
  void _autoSave() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _submitToFirebase(showSnackbar: false);
      }
    });
  }

  @override
  void dispose() {
    _autoSaveDebounce?.cancel();
    super.dispose();
  }

  Future<void> _submitToFirebase({bool showSnackbar = true}) async {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) {
      setState(() => _submitError = 'No project selected');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await ExecutionPhaseService.savePageData(
        projectId: projectId,
        pageKey: widget.pageKey,
        sections: _sectionData,
        userId: FirebaseAuth.instance.currentUser?.uid,
      );
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Firebase'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _submitError = 'Failed to submit: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class PhaseNavigationSpec {
  const PhaseNavigationSpec({
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });

  final String backLabel;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;
}
