/// Change Management — Extended models for the CM module
///
/// Per the Change Management Process docs (Waterfall: 313 paragraphs,
/// Agile: 338 paragraphs) + supporting document tables (24 WF docs,
/// 30 Agile docs).

import 'package:flutter/material.dart';

// ─── Change Types (10 Waterfall categories, 7 Agile categories) ──────────

enum CMChangeType {
  // Waterfall
  scope,
  schedule,
  cost,
  resource,
  procurement,
  contract,
  risk,
  quality,
  regulatory,
  // Agile
  product,
  requirements,
  technical,
  defect,
  compliance,
  operational,
}

extension CMChangeTypeMeta on CMChangeType {
  String get label => switch (this) {
        CMChangeType.scope => 'Scope Change',
        CMChangeType.schedule => 'Schedule Change',
        CMChangeType.cost => 'Cost Change',
        CMChangeType.resource => 'Resource Change',
        CMChangeType.procurement => 'Procurement Change',
        CMChangeType.contract => 'Contract Change',
        CMChangeType.risk => 'Risk Change',
        CMChangeType.quality => 'Quality Change',
        CMChangeType.regulatory => 'Regulatory Change',
        CMChangeType.product => 'Product Change',
        CMChangeType.requirements => 'Requirements Change',
        CMChangeType.technical => 'Technical Change',
        CMChangeType.defect => 'Defect Change',
        CMChangeType.compliance => 'Compliance Change',
        CMChangeType.operational => 'Operational Change',
      };

  IconData get icon => switch (this) {
        CMChangeType.scope => Icons.account_tree_outlined,
        CMChangeType.schedule => Icons.schedule_outlined,
        CMChangeType.cost => Icons.attach_money,
        CMChangeType.resource => Icons.group_outlined,
        CMChangeType.procurement => Icons.shopping_bag_outlined,
        CMChangeType.contract => Icons.assignment_outlined,
        CMChangeType.risk => Icons.warning_amber_rounded,
        CMChangeType.quality => Icons.verified_outlined,
        CMChangeType.regulatory => Icons.gavel_outlined,
        CMChangeType.product => Icons.inventory_2_outlined,
        CMChangeType.requirements => Icons.list_alt_outlined,
        CMChangeType.technical => Icons.code,
        CMChangeType.defect => Icons.bug_report_outlined,
        CMChangeType.compliance => Icons.security_outlined,
        CMChangeType.operational => Icons.settings_outlined,
      };

  Color get color => switch (this) {
        CMChangeType.scope => const Color(0xFF6366F1),
        CMChangeType.schedule => const Color(0xFF8B5CF6),
        CMChangeType.cost => const Color(0xFFD97706),
        CMChangeType.resource => const Color(0xFF06B6D4),
        CMChangeType.procurement => const Color(0xFF10B981),
        CMChangeType.contract => const Color(0xFF3B82F6),
        CMChangeType.risk => const Color(0xFFEF4444),
        CMChangeType.quality => const Color(0xFF14B8A6),
        CMChangeType.regulatory => const Color(0xFF6B7280),
        CMChangeType.product => const Color(0xFFF59E0B),
        CMChangeType.requirements => const Color(0xFFEC4899),
        CMChangeType.technical => const Color(0xFF6366F1),
        CMChangeType.defect => const Color(0xFFEF4444),
        CMChangeType.compliance => const Color(0xFF6B7280),
        CMChangeType.operational => const Color(0xFF06B6D4),
      };
}

// ─── Change Status ────────────────────────────────────────────────────────

enum CMStatus {
  draft,
  submitted,
  underReview,
  pendingApproval,
  approved,
  rejected,
  returned,
  implemented,
  closed,
  emergency,
}

extension CMStatusMeta on CMStatus {
  String get label => switch (this) {
        CMStatus.draft => 'Draft',
        CMStatus.submitted => 'Submitted',
        CMStatus.underReview => 'Under Review',
        CMStatus.pendingApproval => 'Pending Approval',
        CMStatus.approved => 'Approved',
        CMStatus.rejected => 'Rejected',
        CMStatus.returned => 'Returned for Revision',
        CMStatus.implemented => 'Implemented',
        CMStatus.closed => 'Closed',
        CMStatus.emergency => 'Emergency',
      };

  Color get color => switch (this) {
        CMStatus.draft => const Color(0xFF6B7280),
        CMStatus.submitted => const Color(0xFF3B82F6),
        CMStatus.underReview => const Color(0xFFF59E0B),
        CMStatus.pendingApproval => const Color(0xFF8B5CF6),
        CMStatus.approved => const Color(0xFF10B981),
        CMStatus.rejected => const Color(0xFFEF4444),
        CMStatus.returned => const Color(0xFFEC4899),
        CMStatus.implemented => const Color(0xFF06B6D4),
        CMStatus.closed => const Color(0xFF6B7280),
        CMStatus.emergency => const Color(0xFFDC2626),
      };

  Color get bgColor => color.withValues(alpha: 0.08);
}

// ─── Priority ─────────────────────────────────────────────────────────────

enum CMPriority { low, medium, high, critical, emergency }

extension CMPriorityMeta on CMPriority {
  String get label => switch (this) {
        CMPriority.low => 'Low',
        CMPriority.medium => 'Medium',
        CMPriority.high => 'High',
        CMPriority.critical => 'Critical',
        CMPriority.emergency => 'Emergency',
      };

  Color get color => switch (this) {
        CMPriority.low => const Color(0xFF10B981),
        CMPriority.medium => const Color(0xFF3B82F6),
        CMPriority.high => const Color(0xFFF59E0B),
        CMPriority.critical => const Color(0xFFEF4444),
        CMPriority.emergency => const Color(0xFFDC2626),
      };
}

// ─── Approval Decision ───────────────────────────────────────────────────

enum ApprovalDecision {
  pending,
  approved,
  rejected,
  requestInfo,
  returnRevision,
  delegated,
  escalated,
}

extension ApprovalDecisionMeta on ApprovalDecision {
  String get label => switch (this) {
        ApprovalDecision.pending => 'Pending',
        ApprovalDecision.approved => 'Approved',
        ApprovalDecision.rejected => 'Rejected',
        ApprovalDecision.requestInfo => 'Request Info',
        ApprovalDecision.returnRevision => 'Return for Revision',
        ApprovalDecision.delegated => 'Delegated',
        ApprovalDecision.escalated => 'Escalated',
      };

  IconData get icon => switch (this) {
        ApprovalDecision.pending => Icons.hourglass_top,
        ApprovalDecision.approved => Icons.check_circle,
        ApprovalDecision.rejected => Icons.cancel,
        ApprovalDecision.requestInfo => Icons.help_outline,
        ApprovalDecision.returnRevision => Icons.undo,
        ApprovalDecision.delegated => Icons.forward,
        ApprovalDecision.escalated => Icons.arrow_upward,
      };

  Color get color => switch (this) {
        ApprovalDecision.pending => const Color(0xFFF59E0B),
        ApprovalDecision.approved => const Color(0xFF10B981),
        ApprovalDecision.rejected => const Color(0xFFEF4444),
        ApprovalDecision.requestInfo => const Color(0xFF3B82F6),
        ApprovalDecision.returnRevision => const Color(0xFFEC4899),
        ApprovalDecision.delegated => const Color(0xFF8B5CF6),
        ApprovalDecision.escalated => const Color(0xFFDC2626),
      };
}

// ─── Impact Assessment (14 dimensions) ────────────────────────────────────

class ImpactDimension {
  final String name;
  final String? impact;
  final double? scheduleDays;
  final double? costAmount;
  final bool isCritical;

  const ImpactDimension({
    required this.name,
    this.impact,
    this.scheduleDays,
    this.costAmount,
    this.isCritical = false,
  });

  bool get hasImpact =>
      (impact?.isNotEmpty ?? false) ||
      (scheduleDays ?? 0) != 0 ||
      (costAmount ?? 0) != 0;
}

class FullImpactAssessment {
  final ImpactDimension scope;
  final ImpactDimension schedule;
  final ImpactDimension cost;
  final ImpactDimension resources;
  final ImpactDimension procurement;
  final ImpactDimension contracts;
  final ImpactDimension risks;
  final ImpactDimension quality;
  final ImpactDimension safety;
  final ImpactDimension stakeholders;
  final ImpactDimension funding;
  final ImpactDimension benefits;
  final ImpactDimension dependencies;
  final ImpactDimension interfaces;
  final ImpactDimension technical;

  const FullImpactAssessment({
    this.scope = const ImpactDimension(name: 'Scope'),
    this.schedule = const ImpactDimension(name: 'Schedule'),
    this.cost = const ImpactDimension(name: 'Cost'),
    this.resources = const ImpactDimension(name: 'Resources'),
    this.procurement = const ImpactDimension(name: 'Procurement'),
    this.contracts = const ImpactDimension(name: 'Contracts'),
    this.risks = const ImpactDimension(name: 'Risks'),
    this.quality = const ImpactDimension(name: 'Quality'),
    this.safety = const ImpactDimension(name: 'Safety'),
    this.stakeholders = const ImpactDimension(name: 'Stakeholders'),
    this.funding = const ImpactDimension(name: 'Funding'),
    this.benefits = const ImpactDimension(name: 'Benefits'),
    this.dependencies = const ImpactDimension(name: 'Dependencies'),
    this.interfaces = const ImpactDimension(name: 'Interfaces'),
    this.technical = const ImpactDimension(name: 'Technical'),
  });

  List<ImpactDimension> get all => [
        scope, schedule, cost, resources, procurement, contracts,
        risks, quality, safety, stakeholders, funding, benefits,
        dependencies, interfaces,
      ];

  double get totalScheduleImpact =>
      all.fold(0, (sum, d) => sum + (d.scheduleDays ?? 0));

  double get totalCostImpact =>
      all.fold(0, (sum, d) => sum + (d.costAmount ?? 0));

  int get impactedCount => all.where((d) => d.hasImpact).length;

  bool get requiresRebaseline =>
      totalCostImpact > 0 || totalScheduleImpact > 0;
}

// ─── Approval Step (configurable) ─────────────────────────────────────────

class CMApprovalStep {
  final String id;
  final String roleLabel;
  final String? assigneeName;
  final ApprovalDecision decision;
  final DateTime? decidedAt;
  final String? comments;
  final bool isParallel;

  const CMApprovalStep({
    required this.id,
    required this.roleLabel,
    this.assigneeName,
    this.decision = ApprovalDecision.pending,
    this.decidedAt,
    this.comments,
    this.isParallel = false,
  });

  CMApprovalStep copyWith({
    ApprovalDecision? decision,
    DateTime? decidedAt,
    String? comments,
    String? assigneeName,
  }) {
    return CMApprovalStep(
      id: id,
      roleLabel: roleLabel,
      assigneeName: assigneeName ?? this.assigneeName,
      decision: decision ?? this.decision,
      decidedAt: decidedAt ?? this.decidedAt,
      comments: comments ?? this.comments,
      isParallel: isParallel,
    );
  }
}

// ─── Full Change Request ─────────────────────────────────────────────────

class CMChangeRequest {
  final String id;
  final String crNumber;
  final String title;
  final String description;
  final CMChangeType changeType;
  final CMPriority priority;
  final CMStatus status;
  final String submittedBy;
  final DateTime dateSubmitted;
  final DateTime? requestedCompletion;
  final String businessJustification;
  final String? rootCause;
  final FullImpactAssessment impact;
  final List<CMApprovalStep> approvalSteps;
  final int currentStepIndex;
  final bool isEmergency;
  final bool isAgileRoutineRefinement;
  final List<String> affectedRegisters;
  final List<String> affectedBaselines;
  final double? contingencyUsed;
  final double? reserveUsed;
  final bool triggersRebaseline;
  final DateTime? approvedAt;
  final DateTime? implementedAt;
  final DateTime? closedAt;
  final String? implementationNotes;
  final String? closureNotes;

  const CMChangeRequest({
    required this.id,
    required this.crNumber,
    required this.title,
    required this.description,
    required this.changeType,
    required this.priority,
    required this.status,
    required this.submittedBy,
    required this.dateSubmitted,
    this.requestedCompletion,
    required this.businessJustification,
    this.rootCause,
    required this.impact,
    required this.approvalSteps,
    this.currentStepIndex = 0,
    this.isEmergency = false,
    this.isAgileRoutineRefinement = false,
    required this.affectedRegisters,
    required this.affectedBaselines,
    this.contingencyUsed,
    this.reserveUsed,
    this.triggersRebaseline = false,
    this.approvedAt,
    this.implementedAt,
    this.closedAt,
    this.implementationNotes,
    this.closureNotes,
  });

  CMChangeRequest copyWith({
    String? id,
    String? crNumber,
    String? title,
    String? description,
    CMChangeType? changeType,
    CMPriority? priority,
    CMStatus? status,
    String? submittedBy,
    DateTime? dateSubmitted,
    DateTime? requestedCompletion,
    String? businessJustification,
    String? rootCause,
    FullImpactAssessment? impact,
    List<CMApprovalStep>? approvalSteps,
    int? currentStepIndex,
    bool? isEmergency,
    bool? isAgileRoutineRefinement,
    List<String>? affectedRegisters,
    List<String>? affectedBaselines,
    double? contingencyUsed,
    double? reserveUsed,
    bool? triggersRebaseline,
    DateTime? approvedAt,
    DateTime? implementedAt,
    DateTime? closedAt,
    String? implementationNotes,
    String? closureNotes,
  }) {
    return CMChangeRequest(
      id: id ?? this.id,
      crNumber: crNumber ?? this.crNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      changeType: changeType ?? this.changeType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      submittedBy: submittedBy ?? this.submittedBy,
      dateSubmitted: dateSubmitted ?? this.dateSubmitted,
      requestedCompletion: requestedCompletion ?? this.requestedCompletion,
      businessJustification: businessJustification ?? this.businessJustification,
      rootCause: rootCause ?? this.rootCause,
      impact: impact ?? this.impact,
      approvalSteps: approvalSteps ?? this.approvalSteps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isEmergency: isEmergency ?? this.isEmergency,
      isAgileRoutineRefinement: isAgileRoutineRefinement ?? this.isAgileRoutineRefinement,
      affectedRegisters: affectedRegisters ?? this.affectedRegisters,
      affectedBaselines: affectedBaselines ?? this.affectedBaselines,
      contingencyUsed: contingencyUsed ?? this.contingencyUsed,
      reserveUsed: reserveUsed ?? this.reserveUsed,
      triggersRebaseline: triggersRebaseline ?? this.triggersRebaseline,
      approvedAt: approvedAt ?? this.approvedAt,
      implementedAt: implementedAt ?? this.implementedAt,
      closedAt: closedAt ?? this.closedAt,
      implementationNotes: implementationNotes ?? this.implementationNotes,
      closureNotes: closureNotes ?? this.closureNotes,
    );
  }
}

// ─── Audit Entry ──────────────────────────────────────────────────────────

class CMAuditEntry {
  final String id;
  final String user;
  final DateTime timestamp;
  final String action;
  final String? details;
  final String? linkedCRId;
  final String? baselineVersion;

  const CMAuditEntry({
    required this.id,
    required this.user,
    required this.timestamp,
    required this.action,
    this.details,
    this.linkedCRId,
    this.baselineVersion,
  });
}

// ─── Baseline Revision Record ─────────────────────────────────────────────

class BaselineRevisionRecord {
  final int version;
  final DateTime revisionDate;
  final String revisedBy;
  final String linkedCRId;
  final String reason;
  final List<String> updatedBaselines;
  final double? previousBudget;
  final double? revisedBudget;
  final DateTime? previousFinish;
  final DateTime? revisedFinish;

  const BaselineRevisionRecord({
    required this.version,
    required this.revisionDate,
    required this.revisedBy,
    required this.linkedCRId,
    required this.reason,
    required this.updatedBaselines,
    this.previousBudget,
    this.revisedBudget,
    this.previousFinish,
    this.revisedFinish,
  });
}
