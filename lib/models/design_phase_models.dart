// Enums
enum ChecklistStatus { ready, inReview, pending }

// Requirements Implementation Models
class RequirementRow {
  RequirementRow({
    required this.title,
    required this.owner,
    required this.definition,
  });

  String title;
  String owner;
  String definition;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'owner': owner,
      'definition': definition,
    };
  }

  factory RequirementRow.fromMap(Map<String, dynamic> map) {
    return RequirementRow(
      title: map['title']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      definition: map['definition']?.toString() ?? '',
    );
  }
}

class RequirementChecklistItem {
  String title;
  String description;
  ChecklistStatus status;
  String? owner;

  RequirementChecklistItem({
    required this.title,
    required this.description,
    required this.status,
    this.owner,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status.name,
      'owner': owner,
    };
  }

  factory RequirementChecklistItem.fromMap(Map<String, dynamic> map) {
    return RequirementChecklistItem(
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      status: ChecklistStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ChecklistStatus.pending,
      ),
      owner: map['owner']?.toString(),
    );
  }
}

// Technical Alignment Models
class ConstraintRow {
  ConstraintRow({
    required this.constraint,
    required this.guardrail,
    required this.owner,
    required this.status,
  });

  String constraint;
  String guardrail;
  String owner;
  String status;

  Map<String, dynamic> toMap() {
    return {
      'constraint': constraint,
      'guardrail': guardrail,
      'owner': owner,
      'status': status,
    };
  }

  factory ConstraintRow.fromMap(Map<String, dynamic> map) {
    return ConstraintRow(
      constraint: map['constraint']?.toString() ?? '',
      guardrail: map['guardrail']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
    );
  }
}

class RequirementMappingRow {
  RequirementMappingRow({
    required this.requirement,
    required this.approach,
    required this.status,
  });

  String requirement;
  String approach;
  String status;

  Map<String, dynamic> toMap() {
    return {
      'requirement': requirement,
      'approach': approach,
      'status': status,
    };
  }

  factory RequirementMappingRow.fromMap(Map<String, dynamic> map) {
    return RequirementMappingRow(
      requirement: map['requirement']?.toString() ?? '',
      approach: map['approach']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
    );
  }
}

class DependencyDecisionRow {
  DependencyDecisionRow({
    required this.item,
    required this.detail,
    required this.owner,
    required this.status,
  });

  String item;
  String detail;
  String owner;
  String status;

  Map<String, dynamic> toMap() {
    return {
      'item': item,
      'detail': detail,
      'owner': owner,
      'status': status,
    };
  }

  factory DependencyDecisionRow.fromMap(Map<String, dynamic> map) {
    return DependencyDecisionRow(
      item: map['item']?.toString() ?? '',
      detail: map['detail']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
    );
  }
}

// Specialized Design Models
class SecurityPatternRow {
  SecurityPatternRow({
    required this.pattern,
    required this.decision,
    required this.owner,
    required this.status,
  });

  String pattern;
  String decision;
  String owner;
  String status;

  Map<String, dynamic> toMap() => {
        'pattern': pattern,
        'decision': decision,
        'owner': owner,
        'status': status,
      };

  factory SecurityPatternRow.fromMap(Map<String, dynamic> map) {
    return SecurityPatternRow(
      pattern: map['pattern']?.toString() ?? '',
      decision: map['decision']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
    );
  }
}

class PerformancePatternRow {
  PerformancePatternRow({
    required this.hotspot,
    required this.focus,
    required this.sla,
    required this.status,
  });

  String hotspot;
  String focus;
  String sla;
  String status;

  Map<String, dynamic> toMap() => {
        'hotspot': hotspot,
        'focus': focus,
        'sla': sla,
        'status': status,
      };

  factory PerformancePatternRow.fromMap(Map<String, dynamic> map) {
    return PerformancePatternRow(
      hotspot: map['hotspot']?.toString() ?? '',
      focus: map['focus']?.toString() ?? '',
      sla: map['sla']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
    );
  }
}

class IntegrationFlowRow {
  IntegrationFlowRow({
    required this.flow,
    required this.owner,
    required this.system,
    required this.status,
  });

  String flow;
  String owner;
  String system;
  String status;

  Map<String, dynamic> toMap() => {
        'flow': flow,
        'owner': owner,
        'system': system,
        'status': status,
      };

  factory IntegrationFlowRow.fromMap(Map<String, dynamic> map) {
    return IntegrationFlowRow(
      flow: map['flow']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      system: map['system']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
    );
  }
}

class SpecializedDesignData {
  String notes;
  List<SecurityPatternRow> securityPatterns;
  List<PerformancePatternRow> performancePatterns;
  List<IntegrationFlowRow> integrationFlows;

  SpecializedDesignData({
    this.notes = '',
    this.securityPatterns = const [],
    this.performancePatterns = const [],
    this.integrationFlows = const [],
  });

  Map<String, dynamic> toMap() => {
        'notes': notes,
        'securityPatterns': securityPatterns.map((e) => e.toMap()).toList(),
        'performancePatterns':
            performancePatterns.map((e) => e.toMap()).toList(),
        'integrationFlows': integrationFlows.map((e) => e.toMap()).toList(),
      };

  factory SpecializedDesignData.fromMap(Map<String, dynamic> map) {
    return SpecializedDesignData(
      notes: map['notes']?.toString() ?? '',
      securityPatterns: (map['securityPatterns'] as List?)
              ?.map(
                  (e) => SecurityPatternRow.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      performancePatterns: (map['performancePatterns'] as List?)
              ?.map((e) =>
                  PerformancePatternRow.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      integrationFlows: (map['integrationFlows'] as List?)
              ?.map(
                  (e) => IntegrationFlowRow.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// --- Enterprise Design Models ---

enum ProjectMethodology { waterfall, agile, hybrid }

enum ExecutionStrategy { inHouse, contracted, hybrid }

enum ProjectIndustry {
  generic,
  software,
  construction,
  manufacturing,
  marketing
}

class DesignReadinessModel {
  final double specificationsScore;
  final double alignmentScore;
  final double architectureScore;
  final double riskScore;
  final double overallScore;
  final List<String> missingItems;

  DesignReadinessModel({
    this.specificationsScore = 0.0,
    this.alignmentScore = 0.0,
    this.architectureScore = 0.0,
    this.riskScore = 0.0,
    this.overallScore = 0.0,
    this.missingItems = const [],
  });

  Map<String, dynamic> toMap() => {
        'specificationsScore': specificationsScore,
        'alignmentScore': alignmentScore,
        'architectureScore': architectureScore,
        'riskScore': riskScore,
        'overallScore': overallScore,
        'missingItems': missingItems,
      };

  factory DesignReadinessModel.fromMap(Map<String, dynamic> map) {
    return DesignReadinessModel(
      specificationsScore: (map['specificationsScore'] ?? 0).toDouble(),
      alignmentScore: (map['alignmentScore'] ?? 0).toDouble(),
      architectureScore: (map['architectureScore'] ?? 0).toDouble(),
      riskScore: (map['riskScore'] ?? 0).toDouble(),
      overallScore: (map['overallScore'] ?? 0).toDouble(),
      missingItems: List<String>.from(map['missingItems'] ?? []),
    );
  }
}

class DesignManagementData {
  // Core Strategy
  ProjectMethodology methodology;
  ExecutionStrategy executionStrategy;
  ProjectIndustry industry;
  List<String> applicableStandards;

  // Readiness
  DesignReadinessModel readiness;

  // Inherited Context (from Planning)
  List<String> inheritedRisks;
  List<String> inheritedConstraints;
  List<String> inheritedScope;

  // Design Specifics
  SpecializedDesignData specializedDesign;

  // Legacy Fields for Backward Compatibility
  List<DesignSpecification> specifications;
  List<DesignDocument> documents;
  List<DesignToolLink> tools;

  // Old progress fields for backward compatibility (mapped to readiness)
  double get specificationsProgress => readiness.specificationsScore;
  double get alignmentProgress => readiness.alignmentScore;

  DesignManagementData({
    this.methodology = ProjectMethodology.waterfall,
    this.executionStrategy = ExecutionStrategy.inHouse,
    this.industry = ProjectIndustry.generic,
    this.applicableStandards = const [],
    DesignReadinessModel? readiness,
    this.inheritedRisks = const [],
    this.inheritedConstraints = const [],
    this.inheritedScope = const [],
    SpecializedDesignData? specializedDesign,
    List<DesignSpecification>? specifications,
    List<DesignDocument>? documents,
    List<DesignToolLink>? tools,
  })  : readiness = readiness ?? DesignReadinessModel(),
        specializedDesign = specializedDesign ?? SpecializedDesignData(),
        specifications = specifications ?? [],
        documents = documents ?? [],
        tools = tools ?? [];

  DesignManagementData copyWith({
    ProjectMethodology? methodology,
    ExecutionStrategy? executionStrategy,
    ProjectIndustry? industry,
    List<String>? applicableStandards,
    DesignReadinessModel? readiness,
    List<String>? inheritedRisks,
    List<String>? inheritedConstraints,
    List<String>? inheritedScope,
    SpecializedDesignData? specializedDesign,
    List<DesignSpecification>? specifications,
    List<DesignDocument>? documents,
    List<DesignToolLink>? tools,
  }) {
    return DesignManagementData(
      methodology: methodology ?? this.methodology,
      executionStrategy: executionStrategy ?? this.executionStrategy,
      industry: industry ?? this.industry,
      applicableStandards: applicableStandards ?? this.applicableStandards,
      readiness: readiness ?? this.readiness,
      inheritedRisks: inheritedRisks ?? this.inheritedRisks,
      inheritedConstraints: inheritedConstraints ?? this.inheritedConstraints,
      inheritedScope: inheritedScope ?? this.inheritedScope,
      specializedDesign: specializedDesign ?? this.specializedDesign,
      specifications: specifications ?? this.specifications,
      documents: documents ?? this.documents,
      tools: tools ?? this.tools,
    );
  }

  Map<String, dynamic> toJson() => {
        'methodology': methodology.name,
        'executionStrategy': executionStrategy.name,
        'industry': industry.name,
        'applicableStandards': applicableStandards,
        'readiness': readiness.toMap(),
        'inheritedRisks': inheritedRisks,
        'inheritedConstraints': inheritedConstraints,
        'inheritedScope': inheritedScope,
        'specializedDesign': specializedDesign.toMap(),
        'specifications': specifications.map((e) => e.toJson()).toList(),
        'documents': documents.map((e) => e.toJson()).toList(),
        'tools': tools.map((e) => e.toJson()).toList(),
      };

  factory DesignManagementData.fromJson(Map<String, dynamic> json) {
    return DesignManagementData(
      methodology: ProjectMethodology.values.firstWhere(
        (e) => e.name == json['methodology'],
        orElse: () => ProjectMethodology.waterfall,
      ),
      executionStrategy: ExecutionStrategy.values.firstWhere(
        (e) => e.name == json['executionStrategy'],
        orElse: () => ExecutionStrategy.inHouse,
      ),
      industry: ProjectIndustry.values.firstWhere(
        (e) => e.name == json['industry'],
        orElse: () => ProjectIndustry.generic,
      ),
      applicableStandards: List<String>.from(json['applicableStandards'] ?? []),
      readiness: json['readiness'] != null
          ? DesignReadinessModel.fromMap(json['readiness'])
          : DesignReadinessModel(),
      inheritedRisks: List<String>.from(json['inheritedRisks'] ?? []),
      inheritedConstraints:
          List<String>.from(json['inheritedConstraints'] ?? []),
      inheritedScope: List<String>.from(json['inheritedScope'] ?? []),
      specializedDesign: json['specializedDesign'] != null
          ? SpecializedDesignData.fromMap(json['specializedDesign'])
          : SpecializedDesignData(),
      specifications: (json['specifications'] as List?)
              ?.map((e) => DesignSpecification.fromJson(e))
              .toList() ??
          [],
      documents: (json['documents'] as List?)
              ?.map((e) => DesignDocument.fromJson(e))
              .toList() ??
          [],
      tools: (json['tools'] as List?)
              ?.map((e) => DesignToolLink.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DesignSpecification {
  String id;
  String description;
  String status; // 'Defined', 'Validated', 'Implemented'

  DesignSpecification({
    String? id,
    this.description = '',
    this.status = 'Defined',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'status': status,
      };

  factory DesignSpecification.fromJson(Map<String, dynamic> json) {
    return DesignSpecification(
      id: json['id']?.toString(),
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Defined',
    );
  }
}

class DesignDocument {
  String id;
  String title;
  String type; // 'Input' or 'Output'
  String? url;
  String? notes;

  DesignDocument({
    String? id,
    this.title = '',
    this.type = 'Output',
    this.url,
    this.notes,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'url': url,
        'notes': notes,
      };

  factory DesignDocument.fromJson(Map<String, dynamic> json) {
    return DesignDocument(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Output',
      url: json['url']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class DesignToolLink {
  String id;
  String name;
  String url;
  bool isInternal;

  DesignToolLink({
    String? id,
    this.name = '',
    this.url = '',
    this.isInternal = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'isInternal': isInternal,
      };

  factory DesignToolLink.fromJson(Map<String, dynamic> json) {
    return DesignToolLink(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      isInternal: json['isInternal'] == true,
    );
  }
}

// Legacy DTO for backward compatibility if needed,
// allows screens to use old DesignPhaseProgress class name temporarily.
typedef DesignPhaseProgress = DesignReadinessModel;
