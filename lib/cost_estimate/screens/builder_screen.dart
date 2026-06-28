/// Builder Screen — the main cost estimate builder with 4 sub-tabs.
///
/// Tabs: Direct Costs, Indirect Costs, SSHER & Quality, Additional Elements.
/// Shows cost lines grouped by category with add/edit/delete + live totals sidebar.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/cost_estimate/models/cost_estimate_models.dart';
import 'package:ndu_project/cost_estimate/providers/cost_estimate_provider.dart';
import 'package:ndu_project/cost_estimate/providers/compute_utils.dart';
import 'package:ndu_project/cost_estimate/widgets/totals_panel.dart';
import 'package:ndu_project/cost_estimate/widgets/add_line_dialog.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _editingLineId;

  static const _subTabs = [
    ('Direct Costs', [
      CostCategory.labor,
      CostCategory.materials,
      CostCategory.software,
      CostCategory.procurement,
      CostCategory.travelTraining,
      CostCategory.construction,
    ]),
    ('Indirect Costs', [
      CostCategory.projectTeam,
      CostCategory.overheads,
      CostCategory.ga,
      CostCategory.facilities,
      CostCategory.insuranceCompliance,
    ]),
    ('SSHER & Quality', [
      CostCategory.ssher,
      CostCategory.quality,
    ]),
    ('Additional Elements', [
      CostCategory.riskAllowance,
      CostCategory.contingency,
      CostCategory.mgmtReserve,
      CostCategory.escalation,
      CostCategory.taxes,
      CostCategory.financing,
      CostCategory.startup,
      CostCategory.warranty,
      CostCategory.decommissioning,
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CostEstimateProvider>(
      builder: (context, provider, _) {
        final estimate = provider.estimate!;
        final isBaselined = estimate.status == EstimateStatus.baselined ||
            estimate.status == EstimateStatus.rebaselined;
        final canEdit = provider.currentRole == RBACRole.editor ||
            provider.currentRole == RBACRole.approver ||
            provider.currentRole == RBACRole.admin;
        final canEditNow = canEdit && !isBaselined;

        return Scaffold(
          backgroundColor: const Color(0xFF051424),
          body: Column(
            children: [
              // Sub-tab bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1C2D),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF46464C)),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: const Color(0xFFF8BD2A),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  labelColor: const Color(0xFF402D00),
                  unselectedLabelColor: const Color(0xFFC7C6CC),
                  labelStyle:
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: _subTabs.map((t) => Tab(text: t.$1)).toList(),
                ),
              ),
              // Baselined warning
              if (isBaselined)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8BD2A).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFF8BD2A).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Color(0xFFF8BD2A), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimate is baselined (v${estimate.baseline?.version}). Edits create variance entries. Re-baselines remaining: ${estimate.baseline?.rebaselineRemaining}',
                          style: const TextStyle(
                              color: Color(0xFFC7C6CC), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              // Main content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _subTabs
                      .map((t) => _buildTabContent(
                          context, provider, estimate, t.$2, canEditNow))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    CostEstimateProvider provider,
    CostEstimate estimate,
    List<CostCategory> categories,
    bool canEditNow,
  ) {
    final lines = estimate.lines
        .where((l) => categories.contains(l.category))
        .toList();
    final tabTotal = lines.fold(0.0, (a, l) => a + l.total);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lines column
        Expanded(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _subTabs[_tabController.index].$1,
                          style: const TextStyle(
                            color: Color(0xFFD4E4FA),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${lines.length} lines · ${formatCurrency(tabTotal, estimate.currency)}',
                          style: const TextStyle(
                              color: Color(0xFF909096), fontSize: 12),
                        ),
                      ],
                    ),
                    if (canEditNow)
                      FilledButton.icon(
                        onPressed: () => _showAddLineDialog(context, provider,
                            categories.isNotEmpty ? categories.first : CostCategory.labor),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add line'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF8BD2A),
                          foregroundColor: const Color(0xFF402D00),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Lines list
              Expanded(
                child: lines.isEmpty
                    ? _buildEmptyState(context, canEditNow, () =>
                        _showAddLineDialog(context, provider,
                            categories.isNotEmpty ? categories.first : CostCategory.labor))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: lines.length,
                        itemBuilder: (ctx, i) =>
                            _buildLineRow(context, provider, lines[i], canEditNow),
                      ),
              ),
            ],
          ),
        ),
        // Totals sidebar
        const SizedBox(
          width: 300,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: TotalsPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildLineRow(BuildContext context, CostEstimateProvider provider,
      CostLine line, bool canEdit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF122131).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF46464C).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1C2B3C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long, color: Color(0xFFF8BD2A), size: 18),
          ),
          const SizedBox(width: 12),
          // Description + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        line.description,
                        style: const TextStyle(
                          color: Color(0xFFD4E4FA),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (line.aiGenerated) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF168FFC).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            color: Color(0xFFBBC3FF),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (!line.inSchedule) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8BD2A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Not in schedule',
                          style: TextStyle(
                            color: Color(0xFFF8BD2A),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${line.category.label} · ${line.basisSource.label}',
                  style: const TextStyle(
                      color: Color(0xFF909096), fontSize: 11),
                ),
              ],
            ),
          ),
          // Total
          Text(
            formatCurrency(line.total, 'USD'),
            style: const TextStyle(
              color: Color(0xFFD4E4FA),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Actions
          if (canEdit) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 14, color: Color(0xFF909096)),
              onPressed: () => _showAddLineDialog(context, provider, line.category, line),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 14, color: Color(0xFF909096)),
              onPressed: () => provider.removeLine(line.id),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, bool canAdd, VoidCallback onAdd) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, color: Color(0xFF909096), size: 48),
          const SizedBox(height: 16),
          const Text(
            'No cost lines yet',
            style: TextStyle(
                color: Color(0xFFD4E4FA),
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add your first cost line. The totals sidebar updates live.',
            style: TextStyle(color: Color(0xFF909096), fontSize: 13),
          ),
          if (canAdd) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add first line'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF8BD2A),
                foregroundColor: const Color(0xFF402D00),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddLineDialog(
    BuildContext context,
    CostEstimateProvider provider,
    CostCategory defaultCategory, [
    CostLine? editing,
  ]) {
    showDialog(
      context: context,
      builder: (ctx) => AddLineDialog(
        defaultCategory: defaultCategory,
        editingLine: editing,
      ),
    );
  }
}
