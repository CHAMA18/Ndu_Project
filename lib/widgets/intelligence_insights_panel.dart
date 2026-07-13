import 'package:flutter/material.dart';
import 'package:ndu_project/services/project_intelligence_service.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/voice_text_field.dart';

/// A sitewide intelligence insights panel that shows cross-linking
/// gaps and AI suggestions for Scope, Cost, and Schedule.
///
/// Place this widget on any screen to get real-time insights.
class IntelligenceInsightsPanel extends StatefulWidget {
  final String currentSection;
  final bool compact;
  final VoidCallback? onInsightApplied;

  const IntelligenceInsightsPanel({
    super.key,
    required this.currentSection,
    this.compact = false,
    this.onInsightApplied,
  });

  @override
  State<IntelligenceInsightsPanel> createState() => _IntelligenceInsightsPanelState();
}

class _IntelligenceInsightsPanelState extends State<IntelligenceInsightsPanel> {
  final ProjectIntelligenceService _intel = ProjectIntelligenceService.instance;
  List<IntelligenceInsight> _insights = [];
  List<IntelligenceInsight> _aiSuggestions = [];
  bool _isLoading = false;
  bool _isAiLoading = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  @override
  void didUpdateWidget(covariant IntelligenceInsightsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSection != widget.currentSection) {
      _loadInsights();
    }
  }

  Future<void> _loadInsights() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final data = ProjectDataHelper.getData(context);
    final insights = await _intel.analyzeProject(data);

    if (!mounted) return;
    setState(() {
      _insights = insights;
      _isLoading = false;
    });
  }

  Future<void> _loadAiSuggestions() async {
    if (!mounted || _isAiLoading) return;
    setState(() => _isAiLoading = true);

    final data = ProjectDataHelper.getData(context);
    final suggestions = await _intel.generateAiSuggestions(
      data,
      currentSection: widget.currentSection,
    );

    if (!mounted) return;
    setState(() {
      _aiSuggestions = suggestions;
      _isAiLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalInsights = _insights.length + _aiSuggestions.length;
    final criticalCount = _insights.where((i) => i.priority == InsightPriority.critical).length;
    final highCount = _insights.where((i) => i.priority == InsightPriority.high).length;

    if (widget.compact) {
      return _buildCompactView(totalInsights, criticalCount, highCount);
    }
    return _buildFullView(totalInsights, criticalCount, highCount);
  }

  Widget _buildCompactView(int total, int critical, int high) {
    if (total == 0 && !_isLoading) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: critical > 0
              ? const Color(0xFFFEF2F2)
              : high > 0
                  ? const Color(0xFFFFFBEB)
                  : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: critical > 0
                ? const Color(0xFFFECACA)
                : high > 0
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFFBBF7D0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: critical > 0
                        ? const Color(0xFFDC2626)
                        : high > 0
                            ? const Color(0xFFD97706)
                            : const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isLoading
                          ? 'Analyzing project data...'
                          : '$total insight${total != 1 ? 's' : ''} for Scope · Cost · Schedule',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: critical > 0
                            ? const Color(0xFF991B1B)
                            : high > 0
                                ? const Color(0xFF92400E)
                                : const Color(0xFF166534),
                      ),
                    ),
                  ),
                  if (!_isLoading) ...[
                    if (critical > 0)
                      _buildBadge('$critical', const Color(0xFFDC2626)),
                    if (high > 0) ...[
                      const SizedBox(width: 4),
                      _buildBadge('$high', const Color(0xFFD97706)),
                    ],
                    const SizedBox(width: 8),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ],
                  if (_isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1, thickness: 1),
              _buildInsightsList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullView(int total, int critical, int high) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.psychology, size: 20, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project Intelligence',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        _isLoading
                            ? 'Analyzing Scope · Cost · Schedule...'
                            : '$total cross-linking insight${total != 1 ? 's' : ''} found',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isLoading) ...[
                  _buildSummaryChips(critical, high),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _loadInsights,
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'Refresh insights',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // AI Suggestions button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAiLoading ? null : _loadAiSuggestions,
                    icon: _isAiLoading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, size: 16),
                    label: Text(_isAiLoading ? 'AI Analyzing...' : 'AI Suggestions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      side: const BorderSide(color: Color(0xFFDDD6FE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Insights list
          if (!_isLoading || _insights.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInsightsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryChips(int critical, int high) {
    return Row(
      children: [
        if (critical > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$critical Critical',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
            ),
          ),
        if (critical > 0 && high > 0) const SizedBox(width: 4),
        if (high > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$high High',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
            ),
          ),
      ],
    );
  }

  Widget _buildBadge(String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInsightsList() {
    final allInsights = [..._insights, ..._aiSuggestions];

    if (allInsights.isEmpty && !_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'All project items are properly cross-linked to Scope, Cost, and Schedule.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        itemCount: allInsights.length,
        itemBuilder: (context, index) => _buildInsightCard(allInsights[index]),
      ),
    );
  }

  Widget _buildInsightCard(IntelligenceInsight insight) {
    final Color priorityColor;
    final Color priorityBg;
    final IconData categoryIcon;
    final String categoryLabel;

    switch (insight.priority) {
      case InsightPriority.critical:
        priorityColor = const Color(0xFFDC2626);
        priorityBg = const Color(0xFFFEF2F2);
        break;
      case InsightPriority.high:
        priorityColor = const Color(0xFFD97706);
        priorityBg = const Color(0xFFFFFBEB);
        break;
      case InsightPriority.medium:
        priorityColor = const Color(0xFF2563EB);
        priorityBg = const Color(0xFFEFF6FF);
        break;
      case InsightPriority.low:
        priorityColor = const Color(0xFF6B7280);
        priorityBg = const Color(0xFFF3F4F6);
        break;
    }

    switch (insight.category) {
      case InsightCategory.scope:
        categoryIcon = Icons.account_tree;
        categoryLabel = 'Scope';
        break;
      case InsightCategory.cost:
        categoryIcon = Icons.attach_money;
        categoryLabel = 'Cost';
        break;
      case InsightCategory.schedule:
        categoryIcon = Icons.calendar_today;
        categoryLabel = 'Schedule';
        break;
      case InsightCategory.crossLink:
        categoryIcon = Icons.link;
        categoryLabel = 'Cross-Link';
        break;
      case InsightCategory.compliance:
        categoryIcon = Icons.verified;
        categoryLabel = 'Compliance';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(categoryIcon, size: 14, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  insight.priority.name.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: priorityColor),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  categoryLabel,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ),
              if (insight.sourceSection != null && insight.targetSection != null) ...[
                const SizedBox(width: 6),
                Text(
                  '${insight.sourceSection} → ${insight.targetSection}',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            insight.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            insight.description,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (insight.action == InsightAction.addNewItem)
                _buildActionButton(
                  label: 'Add to ${insight.targetSection ?? "..."}',
                  icon: Icons.add,
                  color: const Color(0xFF2563EB),
                  onTap: () => _applyInsight(insight),
                ),
              if (insight.action == InsightAction.linkExisting)
                _buildActionButton(
                  label: 'Link Items',
                  icon: Icons.link,
                  color: const Color(0xFF7C3AED),
                  onTap: () => _applyInsight(insight),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyInsight(IntelligenceInsight insight) {
    // Show a snackbar with the action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action: ${insight.title}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
    widget.onInsightApplied?.call();
  }
}

/// Compact badge that can be placed in any screen header
/// to show the count of cross-linking insights.
class IntelligenceBadge extends StatefulWidget {
  final String currentSection;

  const IntelligenceBadge({super.key, required this.currentSection});

  @override
  State<IntelligenceBadge> createState() => _IntelligenceBadgeState();
}

class _IntelligenceBadgeState extends State<IntelligenceBadge> {
  final ProjectIntelligenceService _intel = ProjectIntelligenceService.instance;
  int _count = 0;
  int _criticalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  @override
  void didUpdateWidget(covariant IntelligenceBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSection != widget.currentSection) {
      _loadCount();
    }
  }

  Future<void> _loadCount() async {
    if (!mounted) return;
    final data = ProjectDataHelper.getData(context);
    final insights = await _intel.analyzeProject(data);
    if (!mounted) return;
    setState(() {
      _count = insights.length;
      _criticalCount = insights.where((i) => i.priority == InsightPriority.critical).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IntelligenceInsightsPanel(
                currentSection: widget.currentSection,
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _criticalCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _criticalCount > 0 ? const Color(0xFFFECACA) : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology,
              size: 14,
              color: _criticalCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
            ),
            const SizedBox(width: 4),
            Text(
              '$_count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _criticalCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
