library;

/// WBS Module Screen — main entry point for the WBS module.
///
/// Uses [ResponsiveScaffold] with the standard app sidebar
/// (`InitiationLikeSidebar`) so it matches the rest of the app.
///
/// Sub-navigation between Builder / AI Generator / Validator / Export & Link
/// is a horizontal `TabBar` at the top of the content area (light-mode pills
/// matching the Project Controls screen), replacing the old dark navy left
/// rail.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/section_navigator.dart';
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

class _WBSModuleScreenState extends State<WBSModuleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WBSProvider>(
      builder: (context, provider, _) {
        final wbs = provider.wbs;

        // Setup state — show framework picker (which itself uses
        // ResponsiveScaffold so the sidebar stays visible).
        if (wbs == null || !provider.setupComplete) {
          return const FrameworkPickerScreen();
        }

        return ResponsiveScaffold(
          activeItemLabel: 'Work Breakdown Structure',
          appBarTitle: 'Work Breakdown Structure',
          breadcrumbPhase: 'Planning Phase',
          breadcrumbTitle: 'WBS',
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // ── World-class Section Navigator ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SectionNavigator(
                  title: 'WBS Navigation',
                  subtitle: 'Navigate between WBS sections',
                  icon: Icons.account_tree_outlined,
                  tabs: [
                    SectionTab(icon: Icons.folder_open, label: 'Builder'),
                    SectionTab(icon: Icons.auto_awesome, label: 'AI Generator'),
                    SectionTab(icon: Icons.check_circle_outline, label: 'Validator'),
                    SectionTab(icon: Icons.trending_up, label: 'Export & Link'),
                  ],
                  controller: _tabController,
                  onChanged: (index) => setState(() {}),
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    WBSBuilderScreen(),
                    WBSAIScreen(),
                    WBSValidatorScreen(),
                    _ExportAndLinkTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Export & Link tab — exports the WBS as JSON or ASCII tree, and shows the
/// link-to-Cost-Estimate affordance.
class _ExportAndLinkTab extends StatelessWidget {
  const _ExportAndLinkTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<WBSProvider>(
      builder: (context, provider, _) {
        final wbs = provider.wbs!;
        final counts = countNodes(wbs);
        final json = const JsonEncoder.withIndent('  ').convert({
          'id': wbs.id,
          'projectName': wbs.projectName,
          'framework': wbs.framework.name,
          'frameworkLabel': wbs.framework.label,
          'level1Label': wbs.framework.level1Label,
          'level2Label': wbs.framework.level2Label,
          'level0': _nodeToJson(wbs.level0),
        });
        final ascii = _toAsciiTree(wbs.level0);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.trending_up,
                      color: LightModeColors.accent, size: 20),
                  const SizedBox(width: 8),
                  const Text('Export & Link',
                      style: TextStyle(
                          color: Color(0xFF1A1D1F),
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Export the WBS as JSON or ASCII tree, or link WBS work packages to Cost Estimate lines.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
              const SizedBox(height: 24),
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: LightModeColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.folder_open,
                          color: LightModeColors.accent, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(wbs.projectName,
                              style: const TextStyle(
                                  color: Color(0xFF1A1D1F),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            '${wbs.framework.label} · ${counts.level1} ${wbs.framework.level1Label} · ${counts.level2} ${wbs.framework.level2Label}',
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: const Color(0xFFE4E7EC)),
                      ),
                      child: Text('${counts.level1 + counts.level2 + 1} nodes',
                          style: const TextStyle(
                              color: Color(0xFF495057),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Export buttons
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _copyToClipboard(context, json, 'JSON'),
                    icon: const Icon(Icons.data_object, size: 16),
                    label: const Text('Copy JSON'),
                    style: FilledButton.styleFrom(
                      backgroundColor: LightModeColors.accent,
                      foregroundColor: LightModeColors.lightOnPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(context, ascii, 'ASCII'),
                    icon: const Icon(Icons.account_tree, size: 16),
                    label: const Text('Copy ASCII tree'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1D1F),
                      side: const BorderSide(color: Color(0xFFE4E7EC)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ASCII preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.preview,
                            size: 14, color: Color(0xFF6B7280)),
                        SizedBox(width: 6),
                        Text('ASCII TREE PREVIEW',
                            style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      ascii,
                      style: const TextStyle(
                        color: Color(0xFF1A1D1F),
                        fontSize: 12,
                        height: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Cost Estimate link section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.link, size: 16, color: LightModeColors.accent),
                        SizedBox(width: 8),
                        Text('Link to Cost Estimate',
                            style: TextStyle(
                                color: Color(0xFF1A1D1F),
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Each Level 2 work package can be linked to one or more Cost Estimate line items. Open the Cost Estimate module from the sidebar to map WBS nodes to cost lines, or use the AI Generator to suggest a baseline breakdown.',
                      style:
                          TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _linkStatChip(
                          'Work packages',
                          '${counts.level2}',
                          Icons.inventory_2_outlined,
                        ),
                        _linkStatChip(
                          'Linked cost lines',
                          '${_countLinkedCostLines(wbs)}',
                          Icons.link,
                        ),
                        _linkStatChip(
                          'AI-generated nodes',
                          '${_countAiNodes(wbs)}',
                          Icons.auto_awesome,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Danger zone — reset
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFECACA).withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Color(0xFFB91C1C), size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Reset WBS — permanently removes the current WBS and returns to setup. This cannot be undone.',
                        style:
                            TextStyle(color: Color(0xFF7F1D1D), fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _confirmReset(context, provider),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB91C1C),
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _linkStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF1A1D1F),
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _copyToClipboard(
      BuildContext context, String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('WBS $label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmReset(BuildContext context, WBSProvider provider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset WBS?'),
        content: const Text(
            'This permanently removes the current WBS and returns to setup. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.resetWBS();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // ---- helpers ----

  Map<String, dynamic> _nodeToJson(WBSNode node) {
    return {
      'id': node.id,
      'level': node.level.name,
      'code': node.code,
      'name': node.name,
      if (node.description != null) 'description': node.description,
      if (node.aiGenerated) 'aiGenerated': true,
      if (node.costLineIds != null && node.costLineIds!.isNotEmpty)
        'costLineIds': node.costLineIds,
      'children': node.children.map(_nodeToJson).toList(),
    };
  }

  String _toAsciiTree(WBSNode root) {
    final buf = StringBuffer();
    buf.writeln('${root.code}  ${root.name}');
    _writeAsciiChildren(buf, root.children, '');
    return buf.toString();
  }

  void _writeAsciiChildren(
      StringBuffer buf, List<WBSNode> children, String prefix) {
    for (var i = 0; i < children.length; i++) {
      final isLast = i == children.length - 1;
      final node = children[i];
      buf.writeln('$prefix${isLast ? '└── ' : '├── '}${node.code}  ${node.name}');
      _writeAsciiChildren(
          buf, node.children, '$prefix${isLast ? '    ' : '│   '}');
    }
  }

  int _countLinkedCostLines(WBS wbs) {
    int count(WBSNode n) {
      final own = n.costLineIds?.length ?? 0;
      return own + n.children.fold(0, (s, c) => s + count(c));
    }
    return count(wbs.level0);
  }

  int _countAiNodes(WBS wbs) {
    int count(WBSNode n) {
      final own = n.aiGenerated ? 1 : 0;
      return own + n.children.fold(0, (s, c) => s + count(c));
    }
    return count(wbs.level0);
  }
}
