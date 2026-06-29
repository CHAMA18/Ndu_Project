/// NDU Project Controls — Type system (Dart)
///
/// Implements both Waterfall (WBS-based, strict MoC) and Agile
/// (Epic/backlog-based, flexible change) project controls.
///
/// Per the Project Controls Documentation:
///   "The Project Controls module should serve as the single source of truth
///    for monitoring project scope, schedule, cost, progress, performance,
///    forecasting, and change management throughout the project lifecycle."

import 'package:flutter/material.dart';

// ─── Enums ────────────────────────────────────────────────────────────────

enum DeliveryModel { waterfall, agile, hybrid }

extension DeliveryModelLabel on DeliveryModel {
  String get label => switch (this) {
        DeliveryModel.waterfall => 'Waterfall',
        DeliveryModel.agile => 'Agile',
        DeliveryModel.hybrid => 'Hybrid',
      };
  String get changeProcess => switch (this) {
        DeliveryModel.waterfall => 'Formal MoC required for all scope changes',
        DeliveryModel.agile =>
          'Routine backlog refinement (no formal MoC) + Controlled baseline changes (formal workflow)',
        DeliveryModel.hybrid => 'MoC for waterfall phases, info note for agile phases',
      };
}

enum ChangeStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  implemented,
  archived
}

extension ChangeStatusLabel on ChangeStatus {
  String get label => switch (this) {
        ChangeStatus.draft => 'Draft',
        ChangeStatus.submitted => 'Submitted',
        ChangeStatus.underReview => 'Under Review',
        ChangeStatus.approved => 'Approved',
        ChangeStatus.rejected => 'Rejected',
        ChangeStatus.implemented => 'Implemented',
        ChangeStatus.archived => 'Archived',
      };

  Color get color => switch (this) {
        ChangeStatus.draft => const Color(0xFF6B7280),
        ChangeStatus.submitted => const Color(0xFF3B82F6),
        ChangeStatus.underReview => const Color(0xFFF59E0B),
        ChangeStatus.approved => const Color(0xFF10B981),
        ChangeStatus.rejected => const Color(0xFFEF4444),
        ChangeStatus.implemented => const Color(0xFF8B5CF6),
        ChangeStatus.archived => const Color(0xFF909096),
      };
}

enum ChangeCategory {
  scope,
  schedule,
  cost,
  resource,
  procurement,
  contract,
  risk,
  quality,
  safety,
  stakeholder,
  funding,
  benefits,
  dependencies,
  interfaces
}

extension ChangeCategoryLabel on ChangeCategory {
  String get label => switch (this) {
        ChangeCategory.scope => 'Scope',
        ChangeCategory.schedule => 'Schedule',
        ChangeCategory.cost => 'Cost',
        ChangeCategory.resource => 'Resource',
        ChangeCategory.procurement => 'Procurement',
        ChangeCategory.contract => 'Contract',
        ChangeCategory.risk => 'Risk',
        ChangeCategory.quality => 'Quality',
        ChangeCategory.safety => 'Safety',
        ChangeCategory.stakeholder => 'Stakeholder',
        ChangeCategory.funding => 'Funding',
        ChangeCategory.benefits => 'Benefits',
        ChangeCategory.dependencies => 'Dependencies',
        ChangeCategory.interfaces => 'Interfaces',
      };

  IconData get icon => switch (this) {
        ChangeCategory.scope => Icons.account_tree_outlined,
        ChangeCategory.schedule => Icons.schedule_outlined,
        ChangeCategory.cost => Icons.attach_money,
        ChangeCategory.resource => Icons.group_outlined,
        ChangeCategory.procurement => Icons.shopping_bag_outlined,
        ChangeCategory.contract => Icons.assignment_outlined,
        ChangeCategory.risk => Icons.warning_amber_rounded,
        ChangeCategory.quality => Icons.verified_outlined,
        ChangeCategory.safety => Icons.health_and_safety_outlined,
        ChangeCategory.stakeholder => Icons.people_outline,
        ChangeCategory.funding => Icons.account_balance_outlined,
        ChangeCategory.benefits => Icons.card_giftcard_outlined,
        ChangeCategory.dependencies => Icons.link,
        ChangeCategory.interfaces => Icons.swap_horiz,
      };
}

enum BaselineType {
  scope,
  schedule,
  cost,
  resource,
  procurement,
  contract
}

extension BaselineTypeLabel on BaselineType {
  String get label => switch (this) {
        BaselineType.scope => 'Scope Baseline',
        BaselineType.schedule => 'Schedule Baseline',
        BaselineType.cost => 'Cost Baseline',
        BaselineType.resource => 'Resource Baseline',
        BaselineType.procurement => 'Procurement Baseline',
        BaselineType.contract => 'Contract Baseline',
      };
}

enum ApprovalRole {
  projectManager,
  functionalManager,
  projectControls,
  finance,
  procurement,
  sponsor,
  steeringCommittee,
  executive,
  productOwner,
  engineeringManager,
  scrumMaster
}

extension ApprovalRoleLabel on ApprovalRole {
  String get label => switch (this) {
        ApprovalRole.projectManager => 'Project Manager',
        ApprovalRole.functionalManager => 'Functional Manager',
        ApprovalRole.projectControls => 'Project Controls',
        ApprovalRole.finance => 'Finance',
        ApprovalRole.procurement => 'Procurement',
        ApprovalRole.sponsor => 'Sponsor',
        ApprovalRole.steeringCommittee => 'Steering Committee',
        ApprovalRole.executive => 'Executive',
        ApprovalRole.productOwner => 'Product Owner',
        ApprovalRole.engineeringManager => 'Engineering Manager',
        ApprovalRole.scrumMaster => 'Scrum Master',
      };
}

enum ProgressMethod {
  physicalPercent,
  deliverableComplete,
  quantityInstalled,
  milestoneComplete,
  storyCompletion,
  earnedValue,
  rulesOfCredit,
  weightedMilestones,
  storyPointsCompleted,
  featuresDelivered,
  epicCompletion,
  sprintCompletion,
  releaseCompletion,
  businessValueDelivered
}

// ─── Work Package Control (Waterfall) / Epic Control (Agile) ──────────────

class WorkPackageControl {
  final String id;
  final String wbsCode;
  final String name;
  final String scopeDescription;
  final List<String> deliverables;
  final List<String> acceptanceCriteria;
  final String? responsibleOrg;
  final String? responsibleIndividual;
  final String? discipline;
  final String? location;
  final String? phase;
  final String priority;
  final String status;

  // Schedule
  final DateTime? plannedStart;
  final DateTime? plannedFinish;
  final DateTime? actualStart;
  final DateTime? actualFinish;
  final double? percentComplete;
  final bool isCriticalPath;
  final double? remainingDuration;
  final double? floatDays;

  // Cost
  final double originalBudget;
  final double currentBudget;
  final double committedCost;
  final double actualCost;
  final double earnedValue;
  final double plannedValue;

  // Agile-specific
  final double? storyPoints;
  final double? storyPointsCompleted;
  final double? velocity;
  final String? sprint;
  final String? release;

  // Progress method
  final ProgressMethod progressMethod;

  const WorkPackageControl({
    required this.id,
    required this.wbsCode,
    required this.name,
    required this.scopeDescription,
    required this.deliverables,
    required this.acceptanceCriteria,
    this.responsibleOrg,
    this.responsibleIndividual,
    this.discipline,
    this.location,
    this.phase,
    required this.priority,
    required this.status,
    this.plannedStart,
    this.plannedFinish,
    this.actualStart,
    this.actualFinish,
    this.percentComplete,
    this.isCriticalPath = false,
    this.remainingDuration,
    this.floatDays,
    required this.originalBudget,
    required this.currentBudget,
    required this.committedCost,
    required this.actualCost,
    required this.earnedValue,
    required this.plannedValue,
    this.storyPoints,
    this.storyPointsCompleted,
    this.velocity,
    this.sprint,
    this.release,
    required this.progressMethod,
  });

  // ─── Computed EVM metrics ──────────────────────────────────────────────
  double get remainingCost => currentBudget - actualCost;
  double get cpi => actualCost > 0 ? earnedValue / actualCost : 1.0;
  double get spi => plannedValue > 0 ? earnedValue / plannedValue : 1.0;
  double get bac => originalBudget;
  double get eac => cpi > 0 ? actualCost + (bac - earnedValue) / cpi : bac;
  double get etc => eac - actualCost;
  double get vac => bac - eac;
  double get costVariance => earnedValue - actualCost;
  double get scheduleVariance => earnedValue - plannedValue;

  WorkPackageControl copyWith({
    String? id,
    String? wbsCode,
    String? name,
    String? scopeDescription,
    List<String>? deliverables,
    List<String>? acceptanceCriteria,
    String? responsibleOrg,
    String? responsibleIndividual,
    String? discipline,
    String? location,
    String? phase,
    String? priority,
    String? status,
    DateTime? plannedStart,
    DateTime? plannedFinish,
    DateTime? actualStart,
    DateTime? actualFinish,
    double? percentComplete,
    bool? isCriticalPath,
    double? remainingDuration,
    double? floatDays,
    double? originalBudget,
    double? currentBudget,
    double? committedCost,
    double? actualCost,
    double? earnedValue,
    double? plannedValue,
    double? storyPoints,
    double? storyPointsCompleted,
    double? velocity,
    String? sprint,
    String? release,
    ProgressMethod? progressMethod,
  }) {
    return WorkPackageControl(
      id: id ?? this.id,
      wbsCode: wbsCode ?? this.wbsCode,
      name: name ?? this.name,
      scopeDescription: scopeDescription ?? this.scopeDescription,
      deliverables: deliverables ?? this.deliverables,
      acceptanceCriteria: acceptanceCriteria ?? this.acceptanceCriteria,
      responsibleOrg: responsibleOrg ?? this.responsibleOrg,
      responsibleIndividual: responsibleIndividual ?? this.responsibleIndividual,
      discipline: discipline ?? this.discipline,
      location: location ?? this.location,
      phase: phase ?? this.phase,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      plannedStart: plannedStart ?? this.plannedStart,
      plannedFinish: plannedFinish ?? this.plannedFinish,
      actualStart: actualStart ?? this.actualStart,
      actualFinish: actualFinish ?? this.actualFinish,
      percentComplete: percentComplete ?? this.percentComplete,
      isCriticalPath: isCriticalPath ?? this.isCriticalPath,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      floatDays: floatDays ?? this.floatDays,
      originalBudget: originalBudget ?? this.originalBudget,
      currentBudget: currentBudget ?? this.currentBudget,
      committedCost: committedCost ?? this.committedCost,
      actualCost: actualCost ?? this.actualCost,
      earnedValue: earnedValue ?? this.earnedValue,
      plannedValue: plannedValue ?? this.plannedValue,
      storyPoints: storyPoints ?? this.storyPoints,
      storyPointsCompleted: storyPointsCompleted ?? this.storyPointsCompleted,
      velocity: velocity ?? this.velocity,
      sprint: sprint ?? this.sprint,
      release: release ?? this.release,
      progressMethod: progressMethod ?? this.progressMethod,
    );
  }
}

// ─── Impact Analysis (14 dimensions per guidance) ─────────────────────────

class ImpactAnalysis {
  final double? scheduleImpactDays;
  final double? costImpactAmount;
  final String? scopeImpact;
  final String? resourceImpact;
  final String? procurementImpact;
  final String? contractImpact;
  final String? riskImpact;
  final String? qualityImpact;
  final String? safetyImpact;
  final String? stakeholderImpact;
  final String? fundingImpact;
  final String? benefitsImpact;
  final String? dependenciesImpact;
  final String? interfacesImpact;

  const ImpactAnalysis({
    this.scheduleImpactDays,
    this.costImpactAmount,
    this.scopeImpact,
    this.resourceImpact,
    this.procurementImpact,
    this.contractImpact,
    this.riskImpact,
    this.qualityImpact,
    this.safetyImpact,
    this.stakeholderImpact,
    this.fundingImpact,
    this.benefitsImpact,
    this.dependenciesImpact,
    this.interfacesImpact,
  });

  bool get hasImpact =>
      (scheduleImpactDays ?? 0) != 0 ||
      (costImpactAmount ?? 0) != 0 ||
      (scopeImpact?.isNotEmpty ?? false) ||
      (resourceImpact?.isNotEmpty ?? false) ||
      (procurementImpact?.isNotEmpty ?? false) ||
      (contractImpact?.isNotEmpty ?? false) ||
      (riskImpact?.isNotEmpty ?? false) ||
      (qualityImpact?.isNotEmpty ?? false) ||
      (safetyImpact?.isNotEmpty ?? false) ||
      (stakeholderImpact?.isNotEmpty ?? false) ||
      (fundingImpact?.isNotEmpty ?? false) ||
      (benefitsImpact?.isNotEmpty ?? false) ||
      (dependenciesImpact?.isNotEmpty ?? false) ||
      (interfacesImpact?.isNotEmpty ?? false);
}

// ─── Approval Workflow ────────────────────────────────────────────────────

class ApprovalStep {
  final String id;
  final ApprovalRole role;
  final String? assigneeName;
  final bool approved;
  final DateTime? approvedAt;
  final String? comments;

  const ApprovalStep({
    required this.id,
    required this.role,
    this.assigneeName,
    required this.approved,
    this.approvedAt,
    this.comments,
  });
}

class ApprovalWorkflow {
  final List<ApprovalStep> steps;
  final int currentStepIndex;

  const ApprovalWorkflow({
    required this.steps,
    this.currentStepIndex = 0,
  });

  ApprovalStep? get currentStep =>
      currentStepIndex < steps.length ? steps[currentStepIndex] : null;
  bool get allApproved => steps.every((s) => s.approved);
}

// ─── Change Request ───────────────────────────────────────────────────────

class ChangeRequest {
  final String id;
  final String description;
  final String requestor;
  final String justification;
  final String? rootCause;
  final ChangeCategory category;
  final String priority;
  final ChangeStatus status;
  final ImpactAnalysis impact;
  final ApprovalWorkflow? approval;
  final DateTime dateSubmitted;
  final DateTime? approvedAt;
  final DateTime? implementedAt;
  final bool isAgileRoutineRefinement;
  final List<String> affectedBaselines;

  const ChangeRequest({
    required this.id,
    required this.description,
    required this.requestor,
    required this.justification,
    this.rootCause,
    required this.category,
    required this.priority,
    required this.status,
    required this.impact,
    this.approval,
    required this.dateSubmitted,
    this.approvedAt,
    this.implementedAt,
    this.isAgileRoutineRefinement = false,
    required this.affectedBaselines,
  });

  ChangeRequest copyWith({
    String? id,
    String? description,
    String? requestor,
    String? justification,
    String? rootCause,
    ChangeCategory? category,
    String? priority,
    ChangeStatus? status,
    ImpactAnalysis? impact,
    ApprovalWorkflow? approval,
    DateTime? dateSubmitted,
    DateTime? approvedAt,
    DateTime? implementedAt,
    bool? isAgileRoutineRefinement,
    List<String>? affectedBaselines,
  }) {
    return ChangeRequest(
      id: id ?? this.id,
      description: description ?? this.description,
      requestor: requestor ?? this.requestor,
      justification: justification ?? this.justification,
      rootCause: rootCause ?? this.rootCause,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      impact: impact ?? this.impact,
      approval: approval ?? this.approval,
      dateSubmitted: dateSubmitted ?? this.dateSubmitted,
      approvedAt: approvedAt ?? this.approvedAt,
      implementedAt: implementedAt ?? this.implementedAt,
      isAgileRoutineRefinement:
          isAgileRoutineRefinement ?? this.isAgileRoutineRefinement,
      affectedBaselines: affectedBaselines ?? this.affectedBaselines,
    );
  }
}

// ─── Baseline ─────────────────────────────────────────────────────────────

class BaselineSnapshot {
  final int version;
  final DateTime lockedAt;
  final String lockedBy;
  final BaselineType type;
  final List<WorkPackageControl> workPackages;
  final double totalBudget;
  final DateTime? baselineStartDate;
  final DateTime? baselineFinishDate;

  const BaselineSnapshot({
    required this.version,
    required this.lockedAt,
    required this.lockedBy,
    required this.type,
    required this.workPackages,
    required this.totalBudget,
    this.baselineStartDate,
    this.baselineFinishDate,
  });
}

// ─── Audit Entry ──────────────────────────────────────────────────────────

class AuditEntry {
  final String id;
  final String user;
  final DateTime timestamp;
  final String field;
  final String previousValue;
  final String newValue;
  final String? reason;
  final String? changeRequestId;

  const AuditEntry({
    required this.id,
    required this.user,
    required this.timestamp,
    required this.field,
    required this.previousValue,
    required this.newValue,
    this.reason,
    this.changeRequestId,
  });
}

// ─── Project Controls State ───────────────────────────────────────────────

class ProjectControlsState {
  final DeliveryModel deliveryModel;
  final bool isBaselined;
  final bool isExecutionActive;
  final List<WorkPackageControl> workPackages;
  final List<ChangeRequest> changeRequests;
  final List<BaselineSnapshot> baselineHistory;
  final List<AuditEntry> auditTrail;

  const ProjectControlsState({
    required this.deliveryModel,
    required this.isBaselined,
    required this.isExecutionActive,
    required this.workPackages,
    required this.changeRequests,
    required this.baselineHistory,
    required this.auditTrail,
  });

  ProjectControlsState copyWith({
    DeliveryModel? deliveryModel,
    bool? isBaselined,
    bool? isExecutionActive,
    List<WorkPackageControl>? workPackages,
    List<ChangeRequest>? changeRequests,
    List<BaselineSnapshot>? baselineHistory,
    List<AuditEntry>? auditTrail,
  }) {
    return ProjectControlsState(
      deliveryModel: deliveryModel ?? this.deliveryModel,
      isBaselined: isBaselined ?? this.isBaselined,
      isExecutionActive: isExecutionActive ?? this.isExecutionActive,
      workPackages: workPackages ?? this.workPackages,
      changeRequests: changeRequests ?? this.changeRequests,
      baselineHistory: baselineHistory ?? this.baselineHistory,
      auditTrail: auditTrail ?? this.auditTrail,
    );
  }

  // ─── Computed portfolio metrics ───────────────────────────────────────
  double get totalOriginalBudget =>
      workPackages.fold(0, (sum, wp) => sum + wp.originalBudget);
  double get totalCurrentBudget =>
      workPackages.fold(0, (sum, wp) => sum + wp.currentBudget);
  double get totalActualCost =>
      workPackages.fold(0, (sum, wp) => sum + wp.actualCost);
  double get totalEarnedValue =>
      workPackages.fold(0, (sum, wp) => sum + wp.earnedValue);
  double get totalPlannedValue =>
      workPackages.fold(0, (sum, wp) => sum + wp.plannedValue);
  double get totalCommitted =>
      workPackages.fold(0, (sum, wp) => sum + wp.committedCost);

  double get portfolioCPI =>
      totalActualCost > 0 ? totalEarnedValue / totalActualCost : 1.0;
  double get portfolioSPI =>
      totalPlannedValue > 0 ? totalEarnedValue / totalPlannedValue : 1.0;
  double get portfolioEAC =>
      portfolioCPI > 0
          ? totalActualCost + (totalOriginalBudget - totalEarnedValue) / portfolioCPI
          : totalOriginalBudget;
  double get portfolioVAC => totalOriginalBudget - portfolioEAC;

  double get avgPercentComplete {
    if (workPackages.isEmpty) return 0;
    return workPackages.fold(0.0, (sum, wp) => sum + (wp.percentComplete ?? 0)) /
        workPackages.length;
  }

  int get openChangeRequests =>
      changeRequests.where((cr) => cr.status == ChangeStatus.submitted ||
          cr.status == ChangeStatus.underReview).length;
  int get approvedChanges =>
      changeRequests.where((cr) => cr.status == ChangeStatus.approved ||
          cr.status == ChangeStatus.implemented).length;

  // Health score (0-100)
  int get healthScore {
    var score = 100;
    if (portfolioCPI < 0.9) score -= 15;
    if (portfolioCPI < 0.8) score -= 15;
    if (portfolioSPI < 0.9) score -= 15;
    if (portfolioSPI < 0.8) score -= 15;
    if (openChangeRequests > 5) score -= 10;
    if (openChangeRequests > 10) score -= 10;
    return score.clamp(0, 100);
  }
}
