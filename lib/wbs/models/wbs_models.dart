/// NDU Project — WBS type system (Dart equivalent)
///
/// Level convention (per user spec):
///   Level 0 = main project (the root)
///   Level 1 = major breakdown (Epic in Agile / Major Category in Waterfall)
///   Level 2 = sub-component (Feature in Agile / Sub-Deliverable in Waterfall)
///
/// The WBS stops at Level 2.

enum WBSFramework {
  agile,
  waterfallDeliverable,
  waterfallDiscipline,
  waterfallFunctional,
  waterfallGeographic,
  waterfallPhase;

  String get label => switch (this) {
        WBSFramework.agile => 'Agile WBS',
        WBSFramework.waterfallDeliverable =>
          'Waterfall — Deliverable-Based',
        WBSFramework.waterfallDiscipline =>
          'Waterfall — Discipline-Based',
        WBSFramework.waterfallFunctional =>
          'Waterfall — Functional Area',
        WBSFramework.waterfallGeographic =>
          'Waterfall — Geographic Location',
        WBSFramework.waterfallPhase =>
          'Waterfall — Phase-Based (Least Preferred)',
      };

  String get shortLabel => switch (this) {
        WBSFramework.agile => 'Agile',
        WBSFramework.waterfallDeliverable => 'Deliverable',
        WBSFramework.waterfallDiscipline => 'Discipline',
        WBSFramework.waterfallFunctional => 'Functional',
        WBSFramework.waterfallGeographic => 'Geographic',
        WBSFramework.waterfallPhase => 'Phase',
      };

  String get deliveryModel => switch (this) {
        WBSFramework.agile => 'AGILE',
        _ => 'WATERFALL',
      };

  String get level1Label => switch (this) {
        WBSFramework.agile => 'Epic',
        WBSFramework.waterfallDeliverable => 'Deliverable',
        WBSFramework.waterfallDiscipline => 'Discipline',
        WBSFramework.waterfallFunctional => 'Functional Area',
        WBSFramework.waterfallGeographic => 'Region',
        WBSFramework.waterfallPhase => 'Phase',
      };

  String get level2Label => switch (this) {
        WBSFramework.agile => 'Feature',
        WBSFramework.waterfallDeliverable => 'Sub-Deliverable',
        WBSFramework.waterfallDiscipline => 'Component',
        WBSFramework.waterfallFunctional => 'Sub-Area',
        WBSFramework.waterfallGeographic => 'Site',
        WBSFramework.waterfallPhase => 'Phase Activity',
      };

  int get rating => switch (this) {
        WBSFramework.agile => 5,
        WBSFramework.waterfallDeliverable => 5,
        WBSFramework.waterfallDiscipline => 5,
        WBSFramework.waterfallFunctional => 4,
        WBSFramework.waterfallGeographic => 4,
        WBSFramework.waterfallPhase => 2,
      };

  String get bestFor => switch (this) {
        WBSFramework.agile =>
          'Software, digital products, iterative delivery',
        WBSFramework.waterfallDeliverable =>
          'All industries (preferred standard approach)',
        WBSFramework.waterfallDiscipline =>
          'Engineering, Construction, EPC, Industrial facilities',
        WBSFramework.waterfallFunctional =>
          'Organizations with strong departments, resource planning, cost reporting',
        WBSFramework.waterfallGeographic =>
          'Multi-site deployments, infrastructure programs, retail expansions, telecom rollouts',
        WBSFramework.waterfallPhase =>
          'High-level reporting, small projects, educational purposes only',
      };

  String get description => switch (this) {
        WBSFramework.agile =>
          'Product → Epic → Feature. Focuses on deliverables (not activities). Maps naturally to the product backlog.',
        WBSFramework.waterfallDeliverable =>
          'Project → Deliverable → Sub-Deliverable. Focuses on what must be produced, not how. Preferred standard approach.',
        WBSFramework.waterfallDiscipline =>
          'Project → Discipline (Civil, Structural, Mechanical, etc.) → Component. Best for technical systems.',
        WBSFramework.waterfallFunctional =>
          'Project → Functional Area (Engineering, Procurement, Construction, etc.) → Sub-Area. Focuses on who performs the work.',
        WBSFramework.waterfallGeographic =>
          'Project → Region → Site. Focuses on where the work occurs. Best for multi-site programs.',
        WBSFramework.waterfallPhase =>
          'Project → Phase (Initiation, Planning, Design, Execution, Testing, Closeout) → Phase Activity. Least preferred — mixes deliverables and activities.',
      };

  String get icon => switch (this) {
        WBSFramework.agile => 'speed',
        WBSFramework.waterfallDeliverable => 'inventory_2',
        WBSFramework.waterfallDiscipline => 'engineering',
        WBSFramework.waterfallFunctional => 'groups',
        WBSFramework.waterfallGeographic => 'public',
        WBSFramework.waterfallPhase => 'timeline',
      };
}

enum WBSLevel { level0, level1, level2 }

extension WBSLevelMeta on WBSLevel {
  int get value => switch (this) {
        WBSLevel.level0 => 0,
        WBSLevel.level1 => 1,
        WBSLevel.level2 => 2,
      };
}

enum EstimationMethod {
  tShirt,
  storyPoints,
  hours,
  days;

  String get label => switch (this) {
        EstimationMethod.tShirt => 'T-shirt Size',
        EstimationMethod.storyPoints => 'Story Points',
        EstimationMethod.hours => 'Hours',
        EstimationMethod.days => 'Days',
      };

  String get desc => switch (this) {
        EstimationMethod.tShirt =>
          'XS / S / M / L / XL — quick epic-level sizing',
        EstimationMethod.storyPoints =>
          'Fibonacci-scale relative estimation',
        EstimationMethod.hours => 'Detailed hour estimates (task-level)',
        EstimationMethod.days => 'Day-level estimates (task-level)',
      };
}

enum AISource {
  global,
  regional,
  local,
  siteSpecific,
  kazAI;

  String get label => switch (this) {
        AISource.global => 'Global Projects',
        AISource.regional => 'Regional Projects',
        AISource.local => 'Local Projects',
        AISource.siteSpecific => 'Site-Specific',
        AISource.kazAI => 'KAZ AI',
      };
}

enum AIConfidence { low, med, high }

/// A WBS node (Level 0, 1, or 2).
class WBSNode {
  final String id;
  final WBSLevel level;
  final String code;
  final String name;
  final String? description;
  final EstimationMethod? estimationMethod;
  final bool? isWorkPackage;
  final bool aiGenerated;
  final AISource? aiSource;
  final AIConfidence? aiConfidence;
  final String? aiReference;
  final List<String>? costLineIds;
  final List<WBSNode> children;

  const WBSNode({
    required this.id,
    required this.level,
    required this.code,
    required this.name,
    this.description,
    this.estimationMethod,
    this.isWorkPackage,
    required this.aiGenerated,
    this.aiSource,
    this.aiConfidence,
    this.aiReference,
    this.costLineIds,
    required this.children,
  });

  WBSNode copyWith({
    String? id,
    WBSLevel? level,
    String? code,
    String? name,
    String? description,
    EstimationMethod? estimationMethod,
    bool? isWorkPackage,
    bool? aiGenerated,
    AISource? aiSource,
    AIConfidence? aiConfidence,
    String? aiReference,
    List<String>? costLineIds,
    List<WBSNode>? children,
  }) {
    return WBSNode(
      id: id ?? this.id,
      level: level ?? this.level,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      estimationMethod: estimationMethod ?? this.estimationMethod,
      isWorkPackage: isWorkPackage ?? this.isWorkPackage,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      aiSource: aiSource ?? this.aiSource,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      aiReference: aiReference ?? this.aiReference,
      costLineIds: costLineIds ?? this.costLineIds,
      children: children ?? this.children,
    );
  }
}

/// The full WBS.
class WBS {
  final String id;
  final String projectId;
  final String projectName;
  final WBSFramework framework;
  final WBSNode level0;
  final List<dynamic> aiSuggestions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WBS({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.framework,
    required this.level0,
    required this.aiSuggestions,
    required this.createdAt,
    required this.updatedAt,
  });

  WBS copyWith({
    String? id,
    String? projectId,
    String? projectName,
    WBSFramework? framework,
    WBSNode? level0,
    List<dynamic>? aiSuggestions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WBS(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      framework: framework ?? this.framework,
      level0: level0 ?? this.level0,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Count nodes at each level.
({int level0, int level1, int level2}) countNodes(WBS wbs) {
  int level1 = 0;
  int level2 = 0;
  for (final l1 in wbs.level0.children) {
    level1++;
    level2 += l1.children.length;
  }
  return (level0: 1, level1: level1, level2: level2);
}

/// Generate a unique ID.
String newWBSId([String prefix = 'wbs']) {
  return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
}

/// Recompute node codes based on tree position.
WBSNode recalcCodes(WBSNode node) {
  if (node.level == WBSLevel.level0) {
    return node.copyWith(
      code: '0',
      children: node.children.asMap().entries.map((e) {
        return _recalcCodesRecursive(e.value, '${e.key + 1}');
      }).toList(),
    );
  }
  return node;
}

WBSNode _recalcCodesRecursive(WBSNode node, String parentCode) {
  final level = parentCode.split('.').length == 1
      ? WBSLevel.level1
      : WBSLevel.level2;
  return node.copyWith(
    code: parentCode,
    level: level,
    children: node.children.asMap().entries.map((e) {
      return _recalcCodesRecursive(e.value, '$parentCode.${e.key + 1}');
    }).toList(),
  );
}

/// Create an empty WBS.
WBS createEmptyWBS({
  required String projectId,
  required String projectName,
  required WBSFramework framework,
}) {
  final now = DateTime.now();
  return WBS(
    id: newWBSId('wbs'),
    projectId: projectId,
    projectName: projectName,
    framework: framework,
    level0: WBSNode(
      id: newWBSId('node'),
      level: WBSLevel.level0,
      code: '0',
      name: projectName,
      description: 'Project root (Level 0)',
      aiGenerated: false,
      children: [],
    ),
    aiSuggestions: [],
    createdAt: now,
    updatedAt: now,
  );
}
