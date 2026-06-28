/// Framework Picker Screen — 2-step setup for a new WBS.
///
/// Step 1: Project name (Level 0 node)
/// Step 2: Framework selection (Agile + 5 Waterfall variations with ratings)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/wbs/models/wbs_models.dart';
import 'package:ndu_project/wbs/providers/wbs_provider.dart';

class FrameworkPickerScreen extends StatefulWidget {
  const FrameworkPickerScreen({super.key});

  @override
  State<FrameworkPickerScreen> createState() => _FrameworkPickerScreenState();
}

class _FrameworkPickerScreenState extends State<FrameworkPickerScreen> {
  int _step = 0;
  String _projectName = '';
  WBSFramework? _framework;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF051424),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open,
                      color: Color(0xFFF8BD2A), size: 28),
                  const SizedBox(width: 8),
                  const Text('NDU ',
                      style: TextStyle(
                          color: Color(0xFFD4E4FA),
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const Text('PROJECT',
                      style: TextStyle(
                          color: Color(0xFFF8BD2A),
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('WBS Setup',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF909096),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3)),
              const SizedBox(height: 32),
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _step ? 24 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= _step
                          ? const Color(0xFFF8BD2A)
                          : const Color(0xFF46464C),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              // Step content
              Expanded(child: _buildStepContent()),
              // Footer nav
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Back',
                          style: TextStyle(color: Color(0xFFC7C6CC))),
                    )
                  else
                    const SizedBox(width: 80),
                  FilledButton(
                    onPressed: _canProceed() ? _handleNext : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF8BD2A),
                      foregroundColor: const Color(0xFF402D00),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(_step == 1 ? 'Create WBS' : 'Continue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_step) {
      case 0:
        return _projectName.trim().isNotEmpty;
      case 1:
        return _framework != null;
    }
    return false;
  }

  void _handleNext() {
    if (_step < 1) {
      setState(() => _step++);
    } else {
      context.read<WBSProvider>().setup(
            projectName: _projectName.trim(),
            framework: _framework!,
          );
    }
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildProjectNameStep();
      case 1:
        return _buildFrameworkStep();
    }
    return const SizedBox();
  }

  Widget _buildProjectNameStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Name your project',
            style: TextStyle(
                color: Color(0xFFD4E4FA),
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
            'This becomes the Level 0 root node of your WBS. It represents the overall project or product being delivered.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFC7C6CC), fontSize: 14)),
        const SizedBox(height: 32),
        TextField(
          onChanged: (v) => setState(() => _projectName = v),
          decoration: InputDecoration(
            labelText: 'Project name (Level 0)',
            labelStyle:
                const TextStyle(color: Color(0xFF909096), fontSize: 11),
            hintText: 'e.g. NDU Manufacturing Facility',
            hintStyle: const TextStyle(color: Color(0xFF46464C)),
            filled: true,
            fillColor: const Color(0xFF0D1C2D),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF46464C))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFF8BD2A))),
          ),
          style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 14),
          autofocus: true,
        ),
      ],
    );
  }

  Widget _buildFrameworkStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Pick a WBS framework',
            style: TextStyle(
                color: Color(0xFFD4E4FA),
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
            'The framework determines how your project is decomposed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFC7C6CC), fontSize: 14)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            children: WBSFramework.values.map((f) {
              final selected = _framework == f;
              final isPhase = f == WBSFramework.waterfallPhase;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _framework = f),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF8BD2A).withValues(alpha: 0.08)
                            : const Color(0xFF1C2B3C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFF8BD2A)
                              : const Color(0xFF46464C),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            switch (f) {
                              WBSFramework.agile => Icons.speed,
                              WBSFramework.waterfallDeliverable =>
                                Icons.inventory_2,
                              WBSFramework.waterfallDiscipline =>
                                Icons.engineering,
                              WBSFramework.waterfallFunctional =>
                                Icons.group,
                              WBSFramework.waterfallGeographic =>
                                Icons.public,
                              WBSFramework.waterfallPhase => Icons.timeline,
                            },
                            color: selected
                                ? const Color(0xFFF8BD2A)
                                : const Color(0xFFC7C6CC),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(f.label,
                                          style: const TextStyle(
                                              color: Color(0xFFD4E4FA),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '★' * f.rating +
                                          '★' * (5 - f.rating),
                                      style: const TextStyle(
                                          color: Color(0xFFF8BD2A),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(f.description,
                                    style: const TextStyle(
                                        color: Color(0xFFC7C6CC),
                                        fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('Best for: ${f.bestFor}',
                                    style: const TextStyle(
                                        color: Color(0xFF909096),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500)),
                                if (isPhase) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFB923C)
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                          color: const Color(0xFFFB923C)
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.warning_amber,
                                            size: 12,
                                            color: Color(0xFFFB923C)),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Least preferred — consider Deliverable-Based.',
                                            style: TextStyle(
                                                color: Color(0xFFFB923C),
                                                fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle,
                                color: Color(0xFFF8BD2A), size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
