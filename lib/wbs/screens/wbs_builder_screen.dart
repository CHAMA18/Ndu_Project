library;

/// WBS Builder Screen — tree view (Level 0 → 1 → 2) with add/edit/delete/reorder.
///
/// Level-depth enforcement: stops at Level 2.
/// Template seeding from the framework's guidance-doc examples.
///
/// Each node row also surfaces a small blue chip showing how many Cost
/// Estimate lines are linked to that node (read from
/// `node.costLineIds` + any [CostLine] whose `wbsRef` matches the node's
/// code). When a Level 1 node is expanded, a "Linked cost lines" panel
/// appears beneath it listing each linked line's description and amount.
///
/// Rendered inside the parent [ResponsiveScaffold]'s TabBarView, so this widget
/// returns its content directly (no Scaffold) with a white background.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/wbs/models/wbs_models.dart';
import 'package:ndu_project/wbs/models/wbs_templates.dart';
import 'package:ndu_project/wbs/providers/wbs_provider.dart';
import 'package:ndu_project/cost_estimate/models/cost_estimate_models.dart';
import 'package:ndu_project/cost_estimate/providers/cost_estimate_provider.dart';
import 'package:ndu_project/cost_estimate/providers/compute_utils.dart';

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
    return Consumer2<WBSProvider, CostEstimateProvider>(
      builder: (context, provider, costProvider, _) {
        final wbs = provider.wbs!;
        final frameworkMeta = wbs.framework;
        final counts = countNodes(wbs);

        return SingleChildScrollView(
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
                              color: LightModeColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Text(wbs.projectName,
                              style: const TextStyle(
                                  color: Color(0xFF1A1D1F),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        '${frameworkMeta.label} · ${counts.level1} ${frameworkMeta.level1Label} · ${counts.level2} ${frameworkMeta.level2Label}',
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 13),
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
                            foregroundColor: const Color(0xFF1A1D1F),
                            side: const BorderSide(
                                color: Color(0xFFE4E7EC)),
                          ),
                        ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _showAddNodeDialog(
                            context, provider, 1, frameworkMeta.level1Label),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text('Add ${frameworkMeta.level1Label}'),
                        style: FilledButton.styleFrom(
                          backgroundColor: LightModeColors.accent,
                          foregroundColor: LightModeColors.lightOnPrimary,
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
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: Text(
                  'Level convention: Level 0 = Project (root) · Level 1 = ${frameworkMeta.level1Label} · Level 2 = ${frameworkMeta.level2Label}. WBS stops at Level 2.',
                  style: const TextStyle(
                      color: Color(0xFF6B7280), fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
              // Level 0 (root)
              _buildNodeRow(
                context,
                provider,
                costProvider,
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
                        color: Color(0xFFE4E7EC), width: 1),
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
                          costProvider,
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
        );
      },
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WBSProvider provider, frameworkMeta) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.layers, color: Color(0xFF9CA3AF), size: 32),
          const SizedBox(height: 8),
          Text('No ${frameworkMeta.level1Label} nodes yet.',
              style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => _showAddNodeDialog(
                    context, provider, 1, frameworkMeta.level1Label),
                style: FilledButton.styleFrom(
                    backgroundColor: LightModeColors.accent,
                    foregroundColor: LightModeColors.lightOnPrimary),
                child: Text('Add ${frameworkMeta.level1Label}'),
              ),
              if (WBSTemplates.templates[provider.wbs!.framework]!.isNotEmpty)
                OutlinedButton(
                  onPressed: () => _showTemplatesDialog(
                      context, provider, provider.wbs!.framework),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1D1F),
                      side: const BorderSide(color: Color(0xFFE4E7EC))),
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
    CostEstimateProvider costProvider,
    WBSNode node,
    String levelLabel, {
    bool isRoot = false,
  }) {
    final isSelected = _selectedId == node.id;
    final linkedLines = _linkedCostLinesFor(node, costProvider);
    final linkedCount = linkedLines.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? LightModeColors.accent.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? LightModeColors.accent
              : const Color(0xFFE4E7EC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(node.code,
                style: const TextStyle(
                    color: Color(0xFF495057),
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
                              color: Color(0xFF1A1D1F),
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
                          color: const Color(0xFF3B82F6)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('AI',
                            style: TextStyle(
                                color: Color(0xFF3B82F6),
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
                          color: const Color(0xFF16A34A)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('WP',
                            style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                    if (linkedCount > 0) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message:
                            '$linkedCount cost line${linkedCount == 1 ? '' : 's'} linked to this WBS node',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.3),
                                width: 0.6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.attach_money,
                                  size: 9, color: Color(0xFF2563EB)),
                              const SizedBox(width: 2),
                              Text(
                                '$linkedCount cost line${linkedCount == 1 ? '' : 's'}',
                                style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (node.description != null && node.description!.isNotEmpty)
                  Text(node.description!,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if (isRoot)
                  Text(levelLabel.toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF),
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
                      size: 12, color: Color(0xFF6B7280)),
                  onPressed: () => provider.moveNode(node.id, true),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  iconSize: 12,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward,
                      size: 12, color: Color(0xFF6B7280)),
                  onPressed: () => provider.moveNode(node.id, false),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  iconSize: 12,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 12, color: Color(0xFFB91C1C)),
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

  /// Returns all cost lines linked to [node] — either via the node's
  /// `costLineIds` list (the bidirectional link) or via a `wbsRef` on a cost
  /// line that matches the node's code/path. De-duplicates by line ID.
  List<CostLine> _linkedCostLinesFor(
      WBSNode node, CostEstimateProvider costProvider) {
    final estimate = costProvider.estimate;
    if (estimate == null) return const [];
    final allLines = estimate.lines;
    final lineIdSet = <String>{...(node.costLineIds ?? const [])};
    final matches = <CostLine>[];
    final seenIds = <String>{};
    for (final l in allLines) {
      final wbsRef = (l.wbsRef ?? '').trim();
      final matchesByPath = wbsRef.isNotEmpty && wbsRef == node.code;
      final matchesById = lineIdSet.contains(l.id);
      if ((matchesByPath || matchesById) && !seenIds.contains(l.id)) {
        matches.add(l);
        seenIds.add(l.id);
      }
    }
    return matches;
  }

  /// Build the "Linked cost lines" panel shown beneath an expanded Level 1
  /// node (or any node with linked cost lines). Lists each line's description
  /// and amount, and shows the aggregated total.
  Widget _buildLinkedCostLinesPanel(
      WBSNode node, CostEstimateProvider costProvider) {
    final linked = _linkedCostLinesFor(node, costProvider);
    if (linked.isEmpty) return const SizedBox.shrink();
    final total = linked.fold<double>(0, (s, l) => s + l.total);
    final currency = costProvider.estimate?.currency ?? 'USD';
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, size: 12, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              const Text('LINKED COST LINES',
                  style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const Spacer(),
              Text(
                '${linked.length} line${linked.length == 1 ? '' : 's'} · ${formatCurrency(total, currency)}',
                style: const TextStyle(
                    color: Color(0xFF1E40AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...linked.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: const Color(0xFFBFDBFE), width: 0.5),
                      ),
                      child: Text(
                        l.category.label,
                        style: const TextStyle(
                            color: Color(0xFF1E40AF),
                            fontSize: 9,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l.description.isEmpty
                            ? '(no description)'
                            : l.description,
                        style: const TextStyle(
                            color: Color(0xFF1A1D1F), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatCurrency(l.total, currency),
                      style: const TextStyle(
                          color: Color(0xFF1A1D1F),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLevel1Node(
    BuildContext context,
    WBSProvider provider,
    CostEstimateProvider costProvider,
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
                  color: const Color(0xFF6B7280),
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
                child: _buildNodeRow(
                    context, provider, costProvider, l1, frameworkMeta.level1Label),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 14, color: Color(0xFF6B7280)),
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
                left: BorderSide(color: Color(0xFFE4E7EC), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...l1.children.map((l2) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNodeRow(context, provider, costProvider, l2,
                            frameworkMeta.level2Label),
                        _buildLinkedCostLinesPanel(l2, costProvider),
                      ],
                    )),
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
                          foregroundColor: const Color(0xFF6B7280),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 28)),
                    ),
                  ),
                ),
                // Aggregate "Linked cost lines" panel for the L1 node itself
                _buildLinkedCostLinesPanel(l1, costProvider),
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
        backgroundColor: Colors.white,
        title: Text('Add Level $level — $levelLabel',
            style: const TextStyle(color: Color(0xFF1A1D1F))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Color(0xFF6B7280)),
                hintText: 'Use a deliverable noun (not an activity verb)',
              ),
              style: const TextStyle(color: Color(0xFF1A1D1F)),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: Color(0xFF6B7280)),
              ),
              style: const TextStyle(color: Color(0xFF1A1D1F)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B7280))),
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
                backgroundColor: LightModeColors.accent,
                foregroundColor: LightModeColors.lightOnPrimary),
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
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: LightModeColors.accent, size: 18),
            SizedBox(width: 8),
            Text('Framework templates',
                style: TextStyle(color: Color(0xFF1A1D1F), fontSize: 16)),
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
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE4E7EC)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: const TextStyle(
                                    color: Color(0xFF1A1D1F),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            if (t.description != null)
                              Text(t.description!,
                                  style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              children: t.children
                                  .map((c) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(c.name,
                                            style: const TextStyle(
                                                color: Color(0xFF495057),
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
                            backgroundColor: LightModeColors.accent,
                            foregroundColor: LightModeColors.lightOnPrimary,
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
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }
}
