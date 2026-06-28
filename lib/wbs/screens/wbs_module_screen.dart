/// WBS Module Screen — main entry point for the WBS module.
///
/// Left-rail navigation between: Builder, AI Generator, Validator, Export & Link.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/wbs/models/wbs_models.dart';
import 'package:ndu_project/wbs/providers/wbs_provider.dart';
import 'package:ndu_project/wbs/screens/framework_picker_screen.dart';
import 'package:ndu_project/wbs/screens/wbs_builder_screen.dart';
import 'package:ndu_project/wbs/screens/wbs_ai_screen.dart';
import 'package:ndu_project/wbs/screens/wbs_validator_screen.dart';

class WBSModuleScreen extends StatefulWidget {
  const WBSModuleScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WBSModuleScreen()),
    );
  }

  @override
  State<WBSModuleScreen> createState() => _WBSModuleScreenState();
}

class _WBSModuleScreenState extends State<WBSModuleScreen> {
  _WBSSubModule _active = _WBSSubModule.builder;

  @override
  Widget build(BuildContext context) {
    return Consumer<WBSProvider>(
      builder: (context, provider, _) {
        final wbs = provider.wbs;

        if (wbs == null || !provider.setupComplete) {
          return const FrameworkPickerScreen();
        }

        final frameworkMeta = wbs.framework;
        final counts = countNodes(wbs);

        return Scaffold(
          backgroundColor: const Color(0xFF051424),
          body: Row(
            children: [
              // Left rail
              Container(
                width: 220,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1C2D),
                  border: Border(
                    right: BorderSide(color: Color(0xFF46464C), width: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    // Project header
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WBS PROJECT',
                              style: TextStyle(
                                  color: Color(0xFF909096),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text(wbs.projectName,
                              style: const TextStyle(
                                  color: Color(0xFFD4E4FA),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF273647),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(frameworkMeta.shortLabel,
                                    style: const TextStyle(
                                        color: Color(0xFFC7C6CC),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF273647),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                    '${counts.level1} L1 · ${counts.level2} L2',
                                    style: const TextStyle(
                                        color: Color(0xFFC7C6CC),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              '${frameworkMeta.level1Label} → ${frameworkMeta.level2Label}',
                              style: const TextStyle(
                                  color: Color(0xFF909096), fontSize: 11)),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFF46464C), height: 1),
                    // Nav items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: _WBSSubModule.values.map((m) {
                          final isActive = _active == m;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _active = m),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFFF8BD2A)
                                          .withValues(alpha: 0.1)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    Icon(m.icon,
                                        size: 18,
                                        color: isActive
                                            ? const Color(0xFFF8BD2A)
                                            : const Color(0xFFC7C6CC)),
                                    const SizedBox(width: 10),
                                    Text(m.label,
                                        style: TextStyle(
                                          color: isActive
                                              ? const Color(0xFFF8BD2A)
                                              : const Color(0xFFC7C6CC),
                                          fontSize: 13,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: switch (_active) {
                  _WBSSubModule.builder => const WBSBuilderScreen(),
                  _WBSSubModule.ai => const WBSAIScreen(),
                  _WBSSubModule.validator => const WBSValidatorScreen(),
                  _WBSSubModule.export => const _ExportPlaceholder(),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _WBSSubModule {
  builder,
  ai,
  validator,
  export;

  String get label => switch (this) {
        _WBSSubModule.builder => 'Builder',
        _WBSSubModule.ai => 'AI Generator',
        _WBSSubModule.validator => 'Validator',
        _WBSSubModule.export => 'Export & Link',
      };

  IconData get icon => switch (this) {
        _WBSSubModule.builder => Icons.folder_open,
        _WBSSubModule.ai => Icons.auto_awesome,
        _WBSSubModule.validator => Icons.check_circle,
        _WBSSubModule.export => Icons.trending_up,
      };
}

class _ExportPlaceholder extends StatelessWidget {
  const _ExportPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, color: Color(0xFFF8BD2A), size: 48),
          SizedBox(height: 16),
          Text('Export & Link',
              style: TextStyle(
                  color: Color(0xFFD4E4FA),
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Export WBS as JSON or ASCII tree, link to Cost Estimate.',
              style: TextStyle(color: Color(0xFFC7C6CC), fontSize: 14)),
        ],
      ),
    );
  }
}
