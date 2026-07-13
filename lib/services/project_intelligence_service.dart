import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

/// Represents a single intelligence insight/action item
class IntelligenceInsight {
  final String id;
  final String title;
  final String description;
  final InsightCategory category;
  final InsightPriority priority;
  final InsightAction action;
  final String? sourceSection;
  final String? targetSection;
  final Map<String, dynamic>? payload;

  const IntelligenceInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.action,
    this.sourceSection,
    this.targetSection,
    this.payload,
  });
}

enum InsightCategory { scope, cost, schedule, crossLink, compliance }
enum InsightPriority { critical, high, medium, low }
enum InsightAction { addNewItem, linkExisting, updateItem, notify, suggest }

/// Core intelligence service that continuously analyzes project data
/// to ensure all work items are tied to Scope, Cost, and Schedule.
class ProjectIntelligenceService {
  ProjectIntelligenceService._();
  static final ProjectIntelligenceService instance = ProjectIntelligenceService._();

  final OpenAiServiceSecure _ai = OpenAiServiceSecure();

  /// Analyze the full project and return all cross-linking insights.
  Future<List<IntelligenceInsight>> analyzeProject(ProjectData data) async {
    final insights = <IntelligenceInsight>[];

    // 1. Scope ↔ Schedule cross-linking
    insights.addAll(_analyzeScopeScheduleGap(data));

    // 2. Scope ↔ Cost cross-linking
    insights.addAll(_analyzeScopeCostGap(data));

    // 3. Cost ↔ Schedule cross-linking
    insights.addAll(_analyzeCostScheduleGap(data));

    // 4. SSHER ↔ Scope/Cost/Schedule
    insights.addAll(_analyzeSsherCrossLinks(data));

    // 5. Activities without scope/cost/schedule ties
    insights.addAll(_analyzeOrphanedActivities(data));

    // 6. WBS items without cost or schedule
    insights.addAll(_analyzeWbsGaps(data));

    // Sort by priority
    insights.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    return insights;
  }

  /// Generate AI-powered suggestions for adding new items to applicable sections.
  Future<List<IntelligenceInsight>> generateAiSuggestions(
    ProjectData data, {
    String? currentSection,
  }) async {
    final contextText = _buildProjectContext(data, currentSection: currentSection);

    if (contextText.trim().isEmpty) return [];

    try {
      final response = await _ai.generateCompletion(
        'You are a project management intelligence assistant analyzing a construction/engineering project. '
        'The project has Scope (WBS), Cost (CBS/estimates), and Schedule (activities/milestones) tracking.\n\n'
        'Based on the current project state below, identify items that are MISSING from specific sections. '
        'Focus on:\n'
        '1. Scope items that need corresponding Cost estimates\n'
        '2. Cost items that need Schedule milestones\n'
        '3. Schedule activities that need Scope definitions\n'
        '4. Any new items that should be added to ensure completeness\n\n'
        'Current project context:\n$contextText\n\n'
        'Respond in JSON format: [{"title":"...","description":"...","category":"scope|cost|schedule","priority":"critical|high|medium|low","action":"addNewItem|linkExisting","targetSection":"..."}]\n'
        'Return an empty array [] if no gaps found. Max 8 suggestions.',
        maxTokens: 1500,
        temperature: 0.4,
      );

      return _parseAiSuggestions(response);
    } catch (e) {
      return [];
    }
  }

  // ─── Scope ↔ Schedule Analysis ───────────────────────────────────────

  List<IntelligenceInsight> _analyzeScopeScheduleGap(ProjectData data) {
    final insights = <IntelligenceInsight>[];
    final scopeItems = data.wbsTree;
    final scheduleActivities = data.scheduleActivities;

    // Check WBS items without schedule activities
    for (final wbs in scopeItems) {
      final hasSchedule = scheduleActivities.any(
        (a) => a.wbsId == wbs.id || a.name.toLowerCase().contains(wbs.name.toLowerCase().substring(0, (wbs.name.length * 0.5).floor().clamp(1, wbs.name.length))),
      );

      if (!hasSchedule && wbs.name.isNotEmpty) {
        insights.add(IntelligenceInsight(
          id: 'scope_sched_${wbs.id}',
          title: 'Schedule Gap: ${wbs.name}',
          description: 'WBS item "${wbs.name}" has no corresponding schedule activity. Add a schedule entry to track delivery timeline.',
          category: InsightCategory.crossLink,
          priority: InsightPriority.high,
          action: InsightAction.addNewItem,
          sourceSection: 'scope',
          targetSection: 'schedule',
          payload: {'wbsId': wbs.id, 'wbsName': wbs.name},
        ));
      }
    }

    // Check schedule activities without WBS linkage
    for (final activity in scheduleActivities) {
      if (activity.wbsId == null || activity.wbsId!.isEmpty) {
        final hasMatchingWbs = scopeItems.any(
          (w) => w.name.toLowerCase().contains(activity.name.toLowerCase().substring(0, (activity.name.length * 0.4).floor().clamp(1, activity.name.length))),
        );
        if (!hasMatchingWbs) {
          insights.add(IntelligenceInsight(
            id: 'sched_scope_${activity.id}',
            title: 'Scope Link Needed: ${activity.name}',
            description: 'Schedule activity "${activity.name}" is not linked to any WBS scope item. Link it for full traceability.',
            category: InsightCategory.crossLink,
            priority: InsightPriority.medium,
            action: InsightAction.linkExisting,
            sourceSection: 'schedule',
            targetSection: 'scope',
            payload: {'activityId': activity.id, 'activityName': activity.name},
          ));
        }
      }
    }

    return insights;
  }

  // ─── Scope ↔ Cost Analysis ───────────────────────────────────────────

  List<IntelligenceInsight> _analyzeScopeCostGap(ProjectData data) {
    final insights = <IntelligenceInsight>[];
    final scopeItems = data.wbsTree;
    final costItems = data.costEstimateItems;

    for (final wbs in scopeItems) {
      final hasCost = costItems.any(
        (c) => c.wbsId == wbs.id || c.name.toLowerCase().contains(wbs.name.toLowerCase().substring(0, (wbs.name.length * 0.5).floor().clamp(1, wbs.name.length))),
      );

      if (!hasCost && wbs.name.isNotEmpty) {
        insights.add(IntelligenceInsight(
          id: 'scope_cost_${wbs.id}',
          title: 'Cost Estimate Needed: ${wbs.name}',
          description: 'WBS item "${wbs.name}" has no cost estimate. Add a cost entry for budget tracking.',
          category: InsightCategory.crossLink,
          priority: InsightPriority.high,
          action: InsightAction.addNewItem,
          sourceSection: 'scope',
          targetSection: 'cost',
          payload: {'wbsId': wbs.id, 'wbsName': wbs.name},
        ));
      }
    }

    return insights;
  }

  // ─── Cost ↔ Schedule Analysis ────────────────────────────────────────

  List<IntelligenceInsight> _analyzeCostScheduleGap(ProjectData data) {
    final insights = <IntelligenceInsight>[];
    final costItems = data.costEstimateItems;
    final scheduleActivities = data.scheduleActivities;

    for (final cost in costItems) {
      if (cost.dueDate == null || cost.dueDate!.isEmpty) {
        final hasSchedule = scheduleActivities.any(
          (a) => a.name.toLowerCase().contains(cost.name.toLowerCase().substring(0, (cost.name.length * 0.4).floor().clamp(1, cost.name.length))),
        );

        if (!hasSchedule) {
          insights.add(IntelligenceInsight(
            id: 'cost_sched_${cost.name}',
            title: 'Schedule Milestone Needed: ${cost.name}',
            description: 'Cost item "${cost.name}" has no associated schedule milestone. Add one to track payment/cash flow timeline.',
            category: InsightCategory.crossLink,
            priority: InsightPriority.medium,
            action: InsightAction.addNewItem,
            sourceSection: 'cost',
            targetSection: 'schedule',
            payload: {'costName': cost.name},
          ));
        }
      }
    }

    return insights;
  }

  // ─── SSHER ↔ Scope/Cost/Schedule ────────────────────────────────────

  List<IntelligenceInsight> _analyzeSsherCrossLinks(ProjectData data) {
    final insights = <IntelligenceInsight>[];
    final ssherEntries = data.ssherData.entries;
    final scheduleActivities = data.scheduleActivities;

    // Check if SSHER high-risk items have schedule mitigation activities
    final highRiskEntries = ssherEntries.where(
      (e) => e.riskLevel.toLowerCase() == 'high',
    );

    for (final entry in highRiskEntries) {
      final hasMitigationSchedule = scheduleActivities.any(
        (a) => a.name.toLowerCase().contains('mitigation') ||
               a.name.toLowerCase().contains(entry.concern.toLowerCase().substring(0, (entry.concern.length * 0.3).floor().clamp(1, entry.concern.length))),
      );

      if (!hasMitigationSchedule) {
        insights.add(IntelligenceInsight(
          id: 'ssher_sched_${entry.id}',
          title: 'Mitigation Activity Needed: ${entry.concern}',
          description: 'High-risk SSHER item "${entry.concern}" needs a schedule activity for mitigation tracking.',
          category: InsightCategory.crossLink,
          priority: InsightPriority.critical,
          action: InsightAction.addNewItem,
          sourceSection: 'ssher',
          targetSection: 'schedule',
          payload: {'entryId': entry.id, 'concern': entry.concern},
        ));
      }
    }

    return insights;
  }

  // ─── Orphaned Activities ─────────────────────────────────────────────

  List<IntelligenceInsight> _analyzeOrphanedActivities(ProjectData data) {
    final insights = <IntelligenceInsight>[];
    final activities = data.scheduleActivities;

    for (final activity in activities) {
      if (activity.wbsId == null || activity.wbsId!.isEmpty) {
        // Check if activity has cost linkage
        final hasCostLink = data.costEstimateItems.any(
          (c) => c.name.toLowerCase().contains(activity.name.toLowerCase().substring(0, (activity.name.length * 0.3).floor().clamp(1, activity.name.length))),
        );

        if (!hasCostLink && activity.name.isNotEmpty) {
          insights.add(IntelligenceInsight(
            id: 'orphan_act_${activity.id}',
            title: 'Unlinked Activity: ${activity.name}',
            description: 'Activity "${activity.name}" is not linked to Scope or Cost. Link it for complete project traceability.',
            category: InsightCategory.crossLink,
            priority: InsightPriority.low,
            action: InsightAction.linkExisting,
            sourceSection: 'schedule',
            targetSection: 'scope',
            payload: {'activityId': activity.id},
          ));
        }
      }
    }

    return insights;
  }

  // ─── WBS Gaps ────────────────────────────────────────────────────────

  List<IntelligenceInsight> _analyzeWbsGaps(ProjectData data) {
    final insights = <IntelligenceInsight>[];
    final wbsItems = data.wbsTree;

    // Check for WBS items without CBS elements
    for (final wbs in wbsItems) {
      final hasCbs = data.cbsElements.any(
        (c) => c.wbsId == wbs.id || c.name.toLowerCase().contains(wbs.name.toLowerCase().substring(0, (wbs.name.length * 0.4).floor().clamp(1, wbs.name.length))),
      );

      if (!hasCbs && wbs.name.isNotEmpty) {
        insights.add(IntelligenceInsight(
          id: 'wbs_cbs_${wbs.id}',
          title: 'CBS Element Needed: ${wbs.name}',
          description: 'WBS item "${wbs.name}" has no corresponding CBS element for cost rollup.',
          category: InsightCategory.cost,
          priority: InsightPriority.medium,
          action: InsightAction.addNewItem,
          sourceSection: 'scope',
          targetSection: 'cost',
          payload: {'wbsId': wbs.id, 'wbsName': wbs.name},
        ));
      }
    }

    return insights;
  }

  // ─── Context Builder ─────────────────────────────────────────────────

  String _buildProjectContext(ProjectData data, {String? currentSection}) {
    final parts = <String>[];

    parts.add('Project: ${data.projectName ?? "Unknown"}');
    parts.add('Solution: ${data.solutionTitle ?? "Unknown"}');

    // Scope summary
    if (data.wbsTree.isNotEmpty) {
      parts.add('\nSCOPE (${data.wbsTree.length} WBS items):');
      for (final wbs in data.wbsTree.take(10)) {
        parts.add('  - ${wbs.name} (ID: ${wbs.id})');
      }
    }

    // Cost summary
    if (data.costEstimateItems.isNotEmpty) {
      parts.add('\nCOST (${data.costEstimateItems.length} items):');
      for (final cost in data.costEstimateItems.take(10)) {
        parts.add('  - ${cost.name}: ${cost.estimatedCost}');
      }
    }

    // Schedule summary
    if (data.scheduleActivities.isNotEmpty) {
      parts.add('\nSCHEDULE (${data.scheduleActivities.length} activities):');
      for (final act in data.scheduleActivities.take(10)) {
        parts.add('  - ${act.name} (WBS: ${act.wbsId ?? "unlinked"})');
      }
    }

    // SSHER summary
    if (data.ssherData.entries.isNotEmpty) {
      parts.add('\nSSHER (${data.ssherData.entries.length} entries):');
      final highRisk = data.ssherData.entries.where((e) => e.riskLevel.toLowerCase() == 'high').length;
      parts.add('  High risk: $highRisk');
    }

    // CBS summary
    if (data.cbsElements.isNotEmpty) {
      parts.add('\nCBS (${data.cbsElements.length} elements)');
    }

    if (currentSection != null) {
      parts.add('\nCurrent section: $currentSection');
    }

    return parts.join('\n');
  }

  // ─── AI Response Parser ──────────────────────────────────────────────

  List<IntelligenceInsight> _parseAiSuggestions(String response) {
    final insights = <IntelligenceInsight>[];
    try {
      // Simple JSON parsing without dart:convert for now
      // The AI returns an array of objects
      final cleaned = response.trim();
      if (cleaned == '[]' || cleaned.isEmpty) return [];

      // Extract JSON array from response
      final startIdx = cleaned.indexOf('[');
      final endIdx = cleaned.lastIndexOf(']');
      if (startIdx == -1 || endIdx == -1) return [];

      final jsonStr = cleaned.substring(startIdx, endIdx + 1);

      // Simple regex-based parsing for robustness
      final titleMatches = RegExp(r'"title"\s*:\s*"([^"]+)"').allMatches(jsonStr);
      final descMatches = RegExp(r'"description"\s*:\s*"([^"]+)"').allMatches(jsonStr);
      final catMatches = RegExp(r'"category"\s*:\s*"([^"]+)"').allMatches(jsonStr);
      final priMatches = RegExp(r'"priority"\s*:\s*"([^"]+)"').allMatches(jsonStr);
      final actMatches = RegExp(r'"action"\s*:\s*"([^"]+)"').allMatches(jsonStr);
      final targetMatches = RegExp(r'"targetSection"\s*:\s*"([^"]+)"').allMatches(jsonStr);

      final titles = titleMatches.map((m) => m.group(1)!).toList();
      final descs = descMatches.map((m) => m.group(1)!).toList();
      final cats = catMatches.map((m) => m.group(1)!).toList();
      final pris = priMatches.map((m) => m.group(1)!).toList();
      final acts = actMatches.map((m) => m.group(1)!).toList();
      final targets = targetMatches.map((m) => m.group(1)!).toList();

      for (int i = 0; i < titles.length; i++) {
        insights.add(IntelligenceInsight(
          id: 'ai_suggestion_$i',
          title: titles[i],
          description: i < descs.length ? descs[i] : '',
          category: _parseCategory(i < cats.length ? cats[i] : 'scope'),
          priority: _parsePriority(i < pris.length ? pris[i] : 'medium'),
          action: _parseAction(i < acts.length ? acts[i] : 'suggest'),
          targetSection: i < targets.length ? targets[i] : null,
          sourceSection: 'ai',
        ));
      }
    } catch (_) {
      // If parsing fails, return empty
    }
    return insights;
  }

  InsightCategory _parseCategory(String s) {
    switch (s.toLowerCase()) {
      case 'scope': return InsightCategory.scope;
      case 'cost': return InsightCategory.cost;
      case 'schedule': return InsightCategory.schedule;
      case 'compliance': return InsightCategory.compliance;
      default: return InsightCategory.crossLink;
    }
  }

  InsightPriority _parsePriority(String s) {
    switch (s.toLowerCase()) {
      case 'critical': return InsightPriority.critical;
      case 'high': return InsightPriority.high;
      case 'medium': return InsightPriority.medium;
      case 'low': return InsightPriority.low;
      default: return InsightPriority.medium;
    }
  }

  InsightAction _parseAction(String s) {
    switch (s.toLowerCase()) {
      case 'addnewitem': return InsightAction.addNewItem;
      case 'linkexisting': return InsightAction.linkExisting;
      case 'updateitem': return InsightAction.updateItem;
      case 'notify': return InsightAction.notify;
      default: return InsightAction.suggest;
    }
  }
}
