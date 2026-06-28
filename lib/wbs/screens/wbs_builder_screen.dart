/// WBS Builder Screen — tree view (Level 0 → 1 → 2) with add/edit/delete/reorder.
///
/// Level-depth enforcement: stops at Level 2.
/// Template seeding from the framework's guidance-doc examples.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/wbs/models/wbs_models.dart';
import 'package:ndu_project/wbs/models/wbs_templates.dart';
import 'package:ndu_project/wbs/providers/wbs_provider.dart';

class WBSBuilderScreen extends StatefulWidget {
  const WBSBuilderScreen({super.key});

  @override
  State<WBSBuilderScreen> createState() => _WBSBuilderScreenState();
}

class _WBSBuilderScreenState extends State<WBSBuilderScreen> {
  String? _selectedId;
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<WBSProvider>(
      builder: (context, provider, _) {
        final wbs = provider.wbs!;
        final frameworkMeta = wbs.framework;
        final counts = countNodes(wbs);

        return Scaffold(
          backgroundColor: const Color(0xFF051424),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.folder_open,
                                color: Color(0xFFF8BD2A), size: 20),
                            const SizedBox(width: 8),
                            Text(wbs.projectName,
                                style: const TextStyle(
                                    color: Color(0xFFD4E4FA),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(
                          '${frameworkMeta.label} · ${counts.level1} ${frameworkMeta.level1Label} · ${counts.level2} ${frameworkMeta.level2Label}',
                          style: const TextStyle(
                              color: Color(0xFF909096), fontSize: 13),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (WBSTemplates.templates[wbs.framework]!.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => _showTemplatesDialog(
                                context, provider, wbs.framework),
                            icon: const Icon(Icons.auto_awesome, size: 14),
                            label: const Text('Templates'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF8BD2A),
                              side: const BorderSide(
                                  color: Color(0xFF46464C)),
                            ),
                          ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () => _showAddNodeDialog(
                              context, provider, 1, frameworkMeta.level1Label),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text('Add ${frameworkMeta.level1Label}'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF8BD2A),
                            foregroundColor: const Color(0xFF402D00),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Level convention reminder
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2B3C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Level convention: Level 0 = Project (root) · Level 1 = ${frameworkMeta.level1Label} · Level 2 = ${frameworkMeta.level2Label}. WBS stops at Level 2.',
                    style: const TextStyle(
                        color: Color(0xFFC7C6CC), fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
                // Level 0 (root)
                _buildNodeRow(
                  context,
                  provider,
                  wbs.level0,
                  'Project',
                  isRoot: true,
                ),
                // Level 1 nodes
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(left: 24),
                  padding: const EdgeInsets.only(left: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                          color: Color(0xFF46464C), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (wbs.level0.children.isEmpty)
                        _buildEmptyState(context, provider, frameworkMeta)
                      else
                        ...wbs.level0.children.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final l1 = entry.value;
                          final isExpanded = _expanded.contains(l1.id);
                          return _buildLevel1Node(
                            context,
                            provider,
                            l1,
                            frameworkMeta,
                            idx,
                            wbs.level0.children.length,
                            isExpanded,
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WBSProvider provider, frameworkMeta) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(
            color: const Color(0xFF46464C).withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.layers, color: Color(0xFF909096), size: 32),
          const SizedBox(height: 8),
          Text('No ${frameworkMeta.level1Label} nodes yet.',
              style: const TextStyle(
                  color: Color(0xFF909096), fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => _showAddNodeDialog(
                    context, provider, 1, frameworkMeta.level1Label),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF8BD2A),
                    foregroundColor: const Color(0xFF402D00)),
                child: Text('Add ${frameworkMeta.level1Label}'),
              ),
              if (WBSTemplates.templates[provider.wbs!.framework]!.isNotEmpty)
                OutlinedButton(
                  onPressed: () => _showTemplatesDialog(
                      context, provider, provider.wbs!.framework),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC7C6CC)),
                  child: const Text('Use template'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNodeRow(
    BuildContext context,
    WBSProvider provider,
    WBSNode node,
    String levelLabel, {
    bool isRoot = false,
  }) {
    final isSelected = _selectedId == node.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFF8BD2A).withValues(alpha: 0.08)
            : const Color(0xFF1C2B3C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFF8BD2A)
              : const Color(0xFF46464C).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF273647),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(node.code,
                style: const TextStyle(
                    color: Color(0xFFC7C6CC),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(node.name,
                          style: const TextStyle(
                              color: Color(0xFFD4E4FA),
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (node.aiGenerated) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF168FFC)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('AI',
                            style: TextStyle(
                                color: Color(0xFFBBC3FF),
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                    if (node.isWorkPackage == true && node.level == WBSLevel.level2) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('WP',
                            style: TextStyle(
                                color: Color(0xFF4ADE80),
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                if (node.description != null && node.description!.isNotEmpty)
                  Text(node.description!,
                      style: const TextStyle(
                          color: Color(0xFF909096), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if (isRoot)
                  Text(levelLabel.toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF909096),
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Actions
          if (!isRoot)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward,
                      size: 12, color: Color(0xFF909096)),
                  onPressed: () => provider.moveNode(node.id, true),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  iconSize: 12,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward,
                      size: 12, color: Color(0xFF909096)),
                  onPressed: () => provider.moveNode(node.id, false),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  iconSize: 12,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 12, color: Color(0xFF909096)),
                  onPressed: () => provider.removeNode(node.id),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  iconSize: 12,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLevel1Node(
    BuildContext context,
    WBSProvider provider,
    WBSNode l1,
    frameworkMeta,
    int idx,
    int total,
    bool isExpanded,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // L1 node row with expand toggle
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                  color: const Color(0xFF909096),
                ),
                onPressed: () {
                  setState(() {
                    if (isExpanded) {
                      _expanded.remove(l1.id);
                    } else {
                      _expanded.add(l1.id);
                    }
                  });
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              Expanded(
                child: _buildNodeRow(context, provider, l1, frameworkMeta.level1Label),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 14, color: Color(0xFF909096)),
                onPressed: () => _showAddNodeDialog(
                    context, provider, 2, frameworkMeta.level2Label,
                    parentId: l1.id),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                tooltip: 'Add ${frameworkMeta.level2Label}',
              ),
            ],
          ),
        ),
        // L2 children
        if (isExpanded) ...[
          Container(
            margin: const EdgeInsets.only(left: 24),
            padding: const EdgeInsets.only(left: 16),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF46464C), width: 1),
              ),
            ),
            child: Column(
              children: [
                ...l1.children.map((l2) =>
                    _buildNodeRow(context, provider, l2, frameworkMeta.level2Label)),
                // Add L2 button
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _showAddNodeDialog(
                          context, provider, 2, frameworkMeta.level2Label,
                          parentId: l1.id),
                      icon: const Icon(Icons.add, size: 12),
                      label: Text('Add ${frameworkMeta.level2Label}'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF909096),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 28)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showAddNodeDialog(
    BuildContext context,
    WBSProvider provider,
    int level,
    String levelLabel, {
    String? parentId,
  }) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1C2D),
        title: Text('Add Level $level — $levelLabel',
            style: const TextStyle(color: Color(0xFFD4E4FA))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Color(0xFF909096)),
                hintText: 'Use a deliverable noun (not an activity verb)',
              ),
              style: const TextStyle(color: Color(0xFFD4E4FA)),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: Color(0xFF909096)),
              ),
              style: const TextStyle(color: Color(0xFFD4E4FA)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF909096))),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              if (level == 1) {
                provider.addLevel1Node(name, descCtrl.text.trim());
              } else if (parentId != null) {
                provider.addLevel2Node(parentId, name, descCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF8BD2A),
                foregroundColor: const Color(0xFF402D00)),
            child: Text('Add $levelLabel'),
          ),
        ],
      ),
    );
  }

  void _showTemplatesDialog(
      BuildContext context, WBSProvider provider, WBSFramework framework) {
    final templates = WBSTemplates.templates[framework]!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1C2D),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFF8BD2A), size: 18),
            SizedBox(width: 8),
            Text('Framework templates',
                style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: templates.map((t) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2B3C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: const TextStyle(
                                    color: Color(0xFFD4E4FA),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            if (t.description != null)
                              Text(t.description!,
                                  style: const TextStyle(
                                      color: Color(0xFF909096),
                                      fontSize: 12)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              children: t.children
                                  .map((c) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF273647),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(c.name,
                                            style: const TextStyle(
                                                color: Color(0xFFC7C6CC),
                                                fontSize: 10)),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          provider.addNodeFromTemplate(t);
                          Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF8BD2A),
                            foregroundColor: const Color(0xFF402D00),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6)),
                        child: const Text('Add',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(color: Color(0xFF909096))),
          ),
        ],
      ),
    );
  }
}
