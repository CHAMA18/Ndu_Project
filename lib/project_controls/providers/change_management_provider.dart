/// Change Management — ChangeNotifier state management
///
/// Handles both Waterfall (strict MoC) and Agile (routine refinement
/// + controlled baseline changes) change workflows.

import 'package:flutter/foundation.dart';
import 'package:ndu_project/project_controls/models/change_management_models.dart';

const String _currentUser = 'you@ndu.project';

class ChangeManagementProvider extends ChangeNotifier {
  List<CMChangeRequest> _changeRequests = [];
  List<CMAuditEntry> _auditTrail = [];
  List<BaselineRevisionRecord> _baselineHistory = [];
  int _crCounter = 0;

  // Contingency / Reserve tracking
  double _totalContingency = 500000; // $500K default
  double _usedContingency = 0;
  double _totalReserve = 1000000; // $1M default
  double _usedReserve = 0;

  // Project BAC (Budget at Completion) — updated by applyToBaseline / rollbackBaseline
  double _currentBAC = 12500000; // $12.5M default project BAC
  String _currentScopeHash = 'sha256:a1b2c3d4e5f6';
  DateTime _currentBaselineFinish = DateTime(2027, 6, 30);

  List<CMChangeRequest> get changeRequests => _changeRequests;
  List<CMAuditEntry> get auditTrail => _auditTrail;
  List<BaselineRevisionRecord> get baselineHistory => _baselineHistory;

  double get totalContingency => _totalContingency;
  double get usedContingency => _usedContingency;
  double get remainingContingency => _totalContingency - _usedContingency;
  double get totalReserve => _totalReserve;
  double get usedReserve => _usedReserve;
  double get remainingReserve => _totalReserve - _usedReserve;

  double get currentBAC => _currentBAC;
  String get currentScopeHash => _currentScopeHash;
  DateTime get currentBaselineFinish => _currentBaselineFinish;

  // ─── Dashboard metrics ─────────────────────────────────────────────
  int get openCRs => _changeRequests.where((cr) =>
      cr.status == CMStatus.submitted ||
      cr.status == CMStatus.underReview ||
      cr.status == CMStatus.pendingApproval).length;

  int get pendingApprovals => _changeRequests.where((cr) =>
      cr.status == CMStatus.underReview ||
      cr.status == CMStatus.pendingApproval).length;

  int get approvedCRs => _changeRequests.where((cr) =>
      cr.status == CMStatus.approved ||
      cr.status == CMStatus.implemented).length;

  int get rejectedCRs => _changeRequests.where((cr) =>
      cr.status == CMStatus.rejected).length;

  int get emergencyCRs => _changeRequests.where((cr) =>
      cr.isEmergency).length;

  int get implementedCRs => _changeRequests.where((cr) =>
      cr.status == CMStatus.implemented ||
      cr.status == CMStatus.closed).length;

  int get rebaselineCount => _baselineHistory.length;

  /// Re-baseline count this quarter (last 90 days).
  int get rebaselineCountThisQuarter {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    return _baselineHistory.where((r) => r.revisionDate.isAfter(cutoff)).length;
  }

  /// Average approval cycle time (days from submission to approval) for
  /// approved CRs that have an approvedAt timestamp. Returns 0 when none.
  double get avgApprovalCycleDays {
    final approved = _changeRequests.where((cr) =>
        cr.approvedAt != null);
    if (approved.isEmpty) return 0;
    final totalDays = approved.fold<double>(0, (sum, cr) =>
        sum + cr.approvedAt!.difference(cr.dateSubmitted).inDays.toDouble());
    return totalDays / approved.length;
  }

  /// Returns the last 7 days of CR creation counts (oldest → newest) for
  /// the dashboard sparkline.
  List<int> crVolumeLast7Days() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = List<int>.filled(7, 0);
    for (final cr in _changeRequests) {
      final d = DateTime(cr.dateSubmitted.year, cr.dateSubmitted.month, cr.dateSubmitted.day);
      final diff = today.difference(d).inDays;
      if (diff >= 0 && diff < 7) counts[6 - diff] += 1;
    }
    return counts;
  }

  double get totalCostImpact => _changeRequests
      .where((cr) => cr.status == CMStatus.approved || cr.status == CMStatus.implemented)
      .fold(0, (sum, cr) => sum + cr.impact.totalCostImpact);

  double get totalScheduleImpact => _changeRequests
      .where((cr) => cr.status == CMStatus.approved || cr.status == CMStatus.implemented)
      .fold(0, (sum, cr) => sum + cr.impact.totalScheduleImpact);

  // ─── CR Lifecycle ──────────────────────────────────────────────────

  String _generateCRNumber() {
    _crCounter++;
    final year = DateTime.now().year;
    return 'CR-$year-${_crCounter.toString().padLeft(3, '0')}';
  }

  /// Creates a new CR with the full creation-form payload.
  /// Returns the new CR's id so the caller can navigate to it.
  String createChangeRequest({
    required String title,
    required String description,
    required CMChangeType changeType,
    required CMPriority priority,
    required String businessJustification,
    String? rootCause,
    String? submittedBy,
    DateTime? dateSubmitted,
    DateTime? requestedCompletion,
    bool isEmergency = false,
    bool isAgileRoutineRefinement = false,
    FullImpactAssessment? impact,
    List<CMApprovalStep>? approvalSteps,
    List<String>? affectedRegisters,
    List<String>? affectedBaselines,
    String? alternativesConsidered,
    List<String>? affectedWorkPackages,
    int deliverablesAdded = 0,
    int deliverablesModified = 0,
    int deliverablesRemoved = 0,
    double? initialCostEstimate,
    int? scheduleDaysImpact,
    double? contingencyDrawdownRequested,
    double? reserveDrawdownRequested,
  }) {
    final crId = 'cm_${DateTime.now().millisecondsSinceEpoch}';
    final cr = CMChangeRequest(
      id: crId,
      crNumber: _generateCRNumber(),
      title: title,
      description: description,
      changeType: changeType,
      priority: isEmergency ? CMPriority.emergency : priority,
      status: isEmergency ? CMStatus.emergency : CMStatus.submitted,
      submittedBy: submittedBy ?? _currentUser,
      dateSubmitted: dateSubmitted ?? DateTime.now(),
      requestedCompletion: requestedCompletion,
      businessJustification: businessJustification,
      rootCause: rootCause,
      impact: impact ?? const FullImpactAssessment(),
      approvalSteps: approvalSteps ?? _defaultApprovalSteps(isEmergency),
      currentStepIndex: 0,
      isEmergency: isEmergency,
      isAgileRoutineRefinement: isAgileRoutineRefinement,
      affectedRegisters: affectedRegisters ?? [],
      affectedBaselines: affectedBaselines ?? [],
      triggersRebaseline: false,
      alternativesConsidered: alternativesConsidered,
      affectedWorkPackages: affectedWorkPackages ?? const [],
      deliverablesAdded: deliverablesAdded,
      deliverablesModified: deliverablesModified,
      deliverablesRemoved: deliverablesRemoved,
      initialCostEstimate: initialCostEstimate,
      scheduleDaysImpact: scheduleDaysImpact,
      contingencyDrawdownRequested: contingencyDrawdownRequested,
      reserveDrawdownRequested: reserveDrawdownRequested,
    );

    _changeRequests = [..._changeRequests, cr];
    _addAudit('CR Created', '${cr.crNumber}: ${cr.title}', cr.id);
    notifyListeners();
    return crId;
  }

  List<CMApprovalStep> _defaultApprovalSteps(bool isEmergency) {
    if (isEmergency) {
      return [
        const CMApprovalStep(id: 'em_1', roleLabel: 'Project Manager'),
        const CMApprovalStep(id: 'em_2', roleLabel: 'Sponsor'),
      ];
    }
    return [
      const CMApprovalStep(id: 'step_1', roleLabel: 'Project Manager'),
      const CMApprovalStep(id: 'step_2', roleLabel: 'Project Controls'),
      const CMApprovalStep(id: 'step_3', roleLabel: 'Finance'),
      const CMApprovalStep(id: 'step_4', roleLabel: 'Sponsor'),
    ];
  }

  void approveStep(String crId, {String? comments}) {
    final cr = _changeRequests.firstWhere((c) => c.id == crId);
    final steps = cr.approvalSteps;
    final idx = cr.currentStepIndex;
    if (idx >= steps.length) return;

    final updatedSteps = steps.asMap().map((i, s) => MapEntry(
        i,
        i == idx
            ? s.copyWith(
                decision: ApprovalDecision.approved,
                decidedAt: DateTime.now(),
                comments: comments,
                assigneeName: _currentUser,
              )
            : s)).values.toList();

    final newIdx = idx + 1;
    final allApproved = updatedSteps.every((s) => s.decision == ApprovalDecision.approved);

    _updateCR(crId, cr.copyWith(
      approvalSteps: updatedSteps,
      currentStepIndex: newIdx,
      status: allApproved ? CMStatus.approved : CMStatus.pendingApproval,
      approvedAt: allApproved ? DateTime.now() : cr.approvedAt,
      triggersRebaseline: allApproved && cr.impact.requiresRebaseline,
    ));

    // Apply contingency/reserve usage on approval
    if (allApproved) {
      final costImpact = cr.impact.totalCostImpact;
      if (costImpact > 0) {
        // Small changes eat into contingency first, then reserve
        if (costImpact <= remainingContingency) {
          _usedContingency += costImpact;
          _addAudit('Contingency Used', '\$${costImpact.toStringAsFixed(0)} from contingency', crId);
        } else {
          final fromContingency = remainingContingency;
          final fromReserve = costImpact - fromContingency;
          _usedContingency += fromContingency;
          _usedReserve += fromReserve;
          _addAudit('Reserve Used', '\$${fromContingency.toStringAsFixed(0)} contingency + \$${fromReserve.toStringAsFixed(0)} reserve', crId);
        }
      }
      _addAudit('CR Approved', '${cr.crNumber} fully approved', crId);
    }
    notifyListeners();
  }

  void rejectCR(String crId, {String? reason}) {
    _updateCR(crId, _changeRequests.firstWhere((c) => c.id == crId).copyWith(
      status: CMStatus.rejected,
    ));
    _addAudit('CR Rejected', reason ?? 'No reason provided', crId);
    notifyListeners();
  }

  void returnForRevision(String crId, {String? comments}) {
    _updateCR(crId, _changeRequests.firstWhere((c) => c.id == crId).copyWith(
      status: CMStatus.returned,
    ));
    _addAudit('CR Returned', comments ?? 'Returned for revision', crId);
    notifyListeners();
  }

  void implementCR(String crId, {String? notes}) {
    final cr = _changeRequests.firstWhere((c) => c.id == crId);

    // Check if re-baseline is needed
    if (cr.triggersRebaseline) {
      _createBaselineRevision(cr);
    }

    _updateCR(crId, cr.copyWith(
      status: CMStatus.implemented,
      implementedAt: DateTime.now(),
      implementationNotes: notes,
    ));
    _addAudit('CR Implemented', '${cr.crNumber} implemented', crId);
    notifyListeners();
  }

  void closeCR(String crId, {String? closureNotes}) {
    final cr = _changeRequests.firstWhere((c) => c.id == crId);
    _updateCR(crId, cr.copyWith(
      status: CMStatus.closed,
      closedAt: DateTime.now(),
      closureNotes: closureNotes,
    ));
    _addAudit('CR Closed', '${cr.crNumber} closed', crId);
    notifyListeners();
  }

  void _createBaselineRevision(CMChangeRequest cr) {
    final revision = BaselineRevisionRecord(
      version: _baselineHistory.length + 1,
      revisionDate: DateTime.now(),
      revisedBy: _currentUser,
      linkedCRId: cr.id,
      reason: '${cr.crNumber}: ${cr.title}',
      updatedBaselines: cr.affectedBaselines,
    );
    _baselineHistory = [..._baselineHistory, revision];
    _addAudit('Baseline Revised', 'v${revision.version} — ${cr.crNumber}', cr.id);
  }

  // ─── Impact Assessment Detail ──────────────────────────────────────

  /// Updates a single dimension on the CR's impact assessment and writes
  /// an audit entry. [dimensionIndex] is the position in
  /// `FullImpactAssessment.all` (0..14).
  void updateImpactDimension(
    String crId,
    int dimensionIndex, {
    int? impactLevel,
    String? narrative,
    String? owner,
    DateTime? dueDate,
  }) {
    final cr = _changeRequests.firstWhere((c) => c.id == crId);
    final dims = cr.impact.all;
    if (dimensionIndex < 0 || dimensionIndex >= dims.length) return;
    final existing = dims[dimensionIndex];
    final updated = existing.copyWith(
      impactLevel: impactLevel ?? existing.impactLevel,
      narrative: narrative ?? existing.narrative,
      owner: owner ?? existing.owner,
      dueDate: dueDate ?? existing.dueDate,
    );
    final newAssessment = cr.impact.updateDimension(dimensionIndex, updated);
    _updateCR(crId, cr.copyWith(impact: newAssessment));
    _addAudit(
      'Impact Dimension Updated',
      '${cr.crNumber} • ${existing.name} → level ${updated.impactLevel}',
      crId,
    );
    notifyListeners();
  }

  /// Bulk-replaces the CR's impact assessment (used by the Impact Detail
  /// tab's Save button which posts the whole grid in one transaction).
  void saveImpactAssessment(String crId, FullImpactAssessment assessment) {
    final cr = _changeRequests.firstWhere((c) => c.id == crId);
    _updateCR(crId, cr.copyWith(impact: assessment));
    _addAudit(
      'Impact Assessment Saved',
      '${cr.crNumber} • composite ${assessment.compositeImpactScore.toStringAsFixed(2)}',
      crId,
    );
    notifyListeners();
  }

  // ─── Approval Workflow Builder ─────────────────────────────────────

  /// Adds a new approval step to the end of the CR's workflow.
  void addApprovalStep(
    String crId, {
    required ApprovalRole role,
    required String decisionMakerName,
    DateTime? dueDate,
  }) {
    final cr = _changeRequests.firstWhere((c) => c.id == crId);
    final stepId = 'step_${cr.approvalSteps.length + 1}_${DateTime.now().millisecondsSinceEpoch}';
    final newStep = CMApprovalStep(
      id: stepId,
      roleLabel: role.label,
      role: role,
      assigneeName: decisionMakerName,
      dueDate: dueDate,
    );
    _updateCR(crId, cr.copyWith(approvalSteps: [...cr.approvalSteps, newStep]));
    _addAudit(
      'Approval Step Added',
      '${cr.crNumber} • ${role.label} → $decisionMakerName',
      crId,
    );
    notifyListeners();
  }

  /// Records a decision on a specific approval step. Handles approve / reject
  /// / defer / delegate / escalate uniformly. Advances currentStepIndex when
  /// the step is at the current pending position.
  void recordApprovalDecision(
    String crId,
    String stepId, {
    required ApprovalDecision decision,
    String? comments,
    String? escalationTarget,
    String? escalationReason,
    String? delegatedFrom,
  }) {
    final cr = _changeRequests.firstWhere((c) => c.id == crId);
    final stepIndex = cr.approvalSteps.indexWhere((s) => s.id == stepId);
    if (stepIndex == -1) return;

    final updatedSteps = cr.approvalSteps.asMap().map((i, s) {
      if (i != stepIndex) return MapEntry(i, s);
      return MapEntry(
        i,
        s.copyWith(
          decision: decision,
          decidedAt: DateTime.now(),
          comments: comments,
          assigneeName: s.assigneeName ?? _currentUser,
          escalationTarget: escalationTarget,
          escalationReason: escalationReason,
          delegatedFrom: delegatedFrom,
        ),
      );
    }).values.toList();

    // Advance current step pointer if the decided step was the active one.
    final newCurrentIdx = stepIndex == cr.currentStepIndex
        ? (cr.currentStepIndex + 1).clamp(0, updatedSteps.length)
        : cr.currentStepIndex;

    // If any step is rejected, mark whole CR returned for revision.
    final anyRejected = updatedSteps.any((s) => s.decision == ApprovalDecision.rejected);
    final newStatus = anyRejected ? CMStatus.returned : cr.status;

    _updateCR(crId, cr.copyWith(
      approvalSteps: updatedSteps,
      currentStepIndex: newCurrentIdx,
      status: newStatus,
    ));
    _addAudit(
      'Approval Decision',
      '${cr.crNumber} • ${updatedSteps[stepIndex].roleLabel} → ${decision.label}',
      crId,
    );
    notifyListeners();
  }

  /// Finalizes the workflow: when every step has a terminal decision, the CR
  /// is closed as either approved (→ triggers re-baseline if scope change
  /// exceeds threshold) or rejected (→ audit entry only).
  void finalizeApproval(String crId) {
    final cr = _changeRequests.firstWhere((c) => c.id == crId);
    if (cr.approvalSteps.isEmpty) return;
    final allTerminal = cr.approvalSteps.every((s) => s.isTerminal);
    if (!allTerminal) return;

    final allApproved = cr.approvalSteps.every((s) =>
        s.decision == ApprovalDecision.approved);
    if (allApproved) {
      final willRebaseline = cr.impact.requiresRebaseline;
      _updateCR(crId, cr.copyWith(
        status: CMStatus.approved,
        approvedAt: DateTime.now(),
        triggersRebaseline: willRebaseline,
      ));
      _addAudit(
        'Workflow Finalized',
        '${cr.crNumber} • APPROVED${willRebaseline ? " (re-baseline triggered)" : ""}',
        crId,
      );
      if (willRebaseline) {
        _addAudit(
          'Re-baseline Triggered',
          '${cr.crNumber} • awaiting apply-to-baseline',
          crId,
        );
      }
    } else {
      _updateCR(crId, cr.copyWith(
        status: CMStatus.rejected,
      ));
      _addAudit(
        'Workflow Finalized',
        '${cr.crNumber} • REJECTED',
        crId,
      );
    }
    notifyListeners();
  }

  // ─── Implementation & Baseline ─────────────────────────────────────

  /// Adds an implementation task tied to an affected work package.
  void addImplementationTask(
    String crId, {
    required String workPackageId,
    required String workPackageName,
    String? assignee,
    DateTime? dueDate,
  }) {
    final cr = _changeRequests.firstWhere((c) => c.id == crId);
    final task = ImplementationTask(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      workPackageId: workPackageId,
      workPackageName: workPackageName,
      assignee: assignee,
      dueDate: dueDate,
    );
    _updateCR(crId, cr.copyWith(
      implementationTasks: [...cr.implementationTasks, task],
      affectedWorkPackages: [...cr.affectedWorkPackages, workPackageId],
    ));
    _addAudit(
      'Implementation Task Added',
      '${cr.crNumber} • $workPackageName',
      crId,
    );
    notifyListeners();
  }

  /// Updates an implementation task's status / assignee / due date.
  void updateImplementationTask(
    String crId,
    String taskId, {
    ImplementationStatus? status,
    String? assignee,
    DateTime? dueDate,
  }) {
    final cr = _changeRequests.firstWhere((c) => c.id == crId);
    final updatedTasks = cr.implementationTasks.map((t) {
      if (t.id != taskId) return t;
      return t.copyWith(
        status: status ?? t.status,
        assignee: assignee ?? t.assignee,
        dueDate: dueDate ?? t.dueDate,
        completedAt: status == ImplementationStatus.done ? DateTime.now() : t.completedAt,
      );
    }).toList();
    _updateCR(crId, cr.copyWith(implementationTasks: updatedTasks));

    // Auto-advance CR to "implemented" when every task is done.
    final allDone = updatedTasks.isNotEmpty &&
        updatedTasks.every((t) => t.status == ImplementationStatus.done);
    if (allDone && cr.status == CMStatus.approved) {
      _updateCR(crId, _changeRequests.firstWhere((c) => c.id == crId).copyWith(
        status: CMStatus.implemented,
        implementedAt: DateTime.now(),
      ));
    }

    _addAudit(
      'Implementation Task Updated',
      '${cr.crNumber} • task $taskId → ${status?.label ?? "assignee/due"}',
      crId,
    );
    notifyListeners();
  }

  /// Creates a new [BaselineRevisionRecord], updates the project BAC by the
  /// CR's cost impact, and writes a re-baseline audit entry. Returns the
  /// new revision version number.
  int applyToBaseline(String crId) {
    final cr = _changeRequests.firstWhere((c) => c.id == crId);
    final previousBAC = _currentBAC;
    final costImpact = cr.impact.totalCostImpact;
    final revisedBAC = previousBAC + costImpact;
    final previousHash = _currentScopeHash;
    final revisedHash = 'sha256:${cr.id}_${cr.impact.compositeImpactScore.toStringAsFixed(2)}_${DateTime.now().millisecondsSinceEpoch}';
    final previousFinish = _currentBaselineFinish;
    final scheduleDelta = cr.impact.totalScheduleImpact.round();
    final revisedFinish = previousFinish.add(Duration(days: scheduleDelta));

    final revision = BaselineRevisionRecord(
      version: _baselineHistory.length + 1,
      revisionDate: DateTime.now(),
      revisedBy: _currentUser,
      linkedCRId: cr.id,
      reason: '${cr.crNumber}: ${cr.title}',
      updatedBaselines: cr.affectedBaselines,
      previousBudget: previousBAC,
      revisedBudget: revisedBAC,
      previousFinish: previousFinish,
      revisedFinish: revisedFinish,
      previousScopeHash: previousHash,
      revisedScopeHash: revisedHash,
      approver: _currentUser,
    );
    _baselineHistory = [..._baselineHistory, revision];
    _currentBAC = revisedBAC;
    _currentScopeHash = revisedHash;
    _currentBaselineFinish = revisedFinish;

    _addAudit(
      'Baseline Applied',
      'v${revision.version} • BAC \$${previousBAC.toStringAsFixed(0)} → \$${revisedBAC.toStringAsFixed(0)} • ${cr.crNumber}',
      crId,
    );
    notifyListeners();
    return revision.version;
  }

  /// Rolls back the most recent baseline revision (restores prior BAC,
  /// scope hash and finish date). Requires confirmation from the UI.
  bool rollbackBaseline() {
    if (_baselineHistory.isEmpty) return false;
    final last = _baselineHistory.last;
    _currentBAC = last.previousBudget ?? _currentBAC;
    _currentScopeHash = last.previousScopeHash ?? _currentScopeHash;
    _currentBaselineFinish = last.previousFinish ?? _currentBaselineFinish;
    _baselineHistory = _baselineHistory.sublist(0, _baselineHistory.length - 1);
    _addAudit(
      'Baseline Rollback',
      'v${last.version} reverted • BAC restored to \$${_currentBAC.toStringAsFixed(0)}',
      last.linkedCRId,
    );
    notifyListeners();
    return true;
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  void _updateCR(String id, CMChangeRequest updated) {
    _changeRequests = _changeRequests.map((c) => c.id == id ? updated : c).toList();
  }

  int _auditCounter = 0;
  void _addAudit(String action, String details, String? crId, {DateTime? timestamp}) {
    _auditCounter++;
    _auditTrail = [..._auditTrail, CMAuditEntry(
      id: 'audit_${timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}_$_auditCounter',
      user: _currentUser,
      timestamp: timestamp ?? DateTime.now(),
      action: action,
      details: details,
      linkedCRId: crId,
    )];
  }

  // ─── Seed demo data ────────────────────────────────────────────────

  void seedDemoData() {
    _changeRequests = [
      CMChangeRequest(
        id: 'cm_demo_1',
        crNumber: 'CR-2026-001',
        title: 'Add Fire Suppression System',
        description: 'Local fire code update requires automated suppression in Site Prep area',
        changeType: CMChangeType.scope,
        priority: CMPriority.high,
        status: CMStatus.underReview,
        submittedBy: 'John Smith (Site Manager)',
        dateSubmitted: DateTime(2026, 6, 18),
        businessJustification: 'Regulatory compliance — new fire code effective Q3 2026',
        rootCause: 'Regulatory change',
        alternativesConsidered: 'Option A: Manual fire watch (rejected — labour cost). Option B: Portable extinguishers only (rejected — insufficient coverage).',
        affectedWorkPackages: const ['WP-1.2 Site Prep', 'WP-3.4 Mechanical Rough-In'],
        deliverablesAdded: 1,
        deliverablesModified: 2,
        deliverablesRemoved: 0,
        initialCostEstimate: 350000,
        scheduleDaysImpact: 14,
        contingencyDrawdownRequested: 350000,
        impact: const FullImpactAssessment(
          scope: ImpactDimension(name: 'Scope', impact: 'New deliverable: Fire suppression installation', isCritical: true, impactLevel: 5, narrative: 'Adds new scope item: complete NFPA-13 sprinkler system in Site Prep and adjacent mechanical rooms.', owner: 'Engineering Lead', dueDate: null),
          schedule: ImpactDimension(name: 'Schedule', scheduleDays: 14, isCritical: true, impactLevel: 4, narrative: 'Adds 14 working days to critical path — procurement lead time 21d, installation 7d.', owner: 'Project Controls'),
          cost: ImpactDimension(name: 'Cost', costAmount: 350000, isCritical: true, impactLevel: 5, narrative: 'Capital cost \$350K — equipment \$210K, installation \$120K, commissioning \$20K.', owner: 'Finance'),
          resources: ImpactDimension(name: 'Resources', impact: 'Additional fire protection contractor required', impactLevel: 3, narrative: 'Requires licensed fire-protection subcontractor for 4 weeks.', owner: 'Procurement Lead'),
          procurement: ImpactDimension(name: 'Procurement', impact: 'New PO for suppression equipment', impactLevel: 4, narrative: 'New PO — long-lead item 21 days ARO.', owner: 'Procurement Lead'),
          contracts: ImpactDimension(name: 'Contracts', impactLevel: 2, narrative: 'Subcontract amendment required.', owner: 'Contracts'),
          risks: ImpactDimension(name: 'Risks', impact: 'Reduces fire risk but adds schedule risk', impactLevel: 3, narrative: 'Net risk reduction post-implementation; temporary schedule risk during installation.', owner: 'Risk Manager'),
          quality: ImpactDimension(name: 'Quality', impact: 'Must meet NFPA standards', impactLevel: 3, narrative: 'Acceptance testing per NFPA-13 §28.', owner: 'Quality Manager'),
          safety: ImpactDimension(name: 'Safety', impactLevel: 4, narrative: 'Positive safety impact — reduces fire risk exposure.', owner: 'Safety Officer'),
          stakeholders: ImpactDimension(name: 'Stakeholders', impactLevel: 2, narrative: 'Local AHJ notified; insurance carrier informed.', owner: 'Project Manager'),
          funding: ImpactDimension(name: 'Funding', impactLevel: 3, narrative: 'Funded from contingency reserve.', owner: 'Finance'),
          benefits: ImpactDimension(name: 'Benefits', impactLevel: 3, narrative: 'Regulatory compliance + reduced insurance premium long-term.', owner: 'Sponsor'),
          dependencies: ImpactDimension(name: 'Dependencies', impactLevel: 2, narrative: 'Depends on WP-1.2 completion; blocks WP-3.4 start.', owner: 'Project Controls'),
          interfaces: ImpactDimension(name: 'Interfaces', impactLevel: 2, narrative: 'Integration with building management system.', owner: 'Engineering Lead'),
          technical: ImpactDimension(name: 'Technical', impactLevel: 3, narrative: 'Standard NFPA-13 design — no R&D required.', owner: 'Engineering Lead'),
        ),
        approvalSteps: [
          const CMApprovalStep(id: 's1', roleLabel: 'Project Manager', role: ApprovalRole.projectManager, decision: ApprovalDecision.approved, decidedAt: null, assigneeName: 'PM Office'),
          const CMApprovalStep(id: 's2', roleLabel: 'Project Controls', role: ApprovalRole.projectControls),
          const CMApprovalStep(id: 's3', roleLabel: 'Finance', role: ApprovalRole.finance, dueDate: null),
          const CMApprovalStep(id: 's4', roleLabel: 'Sponsor', role: ApprovalRole.sponsor),
        ],
        currentStepIndex: 1,
        affectedRegisters: ['WBS', 'Schedule', 'Cost Estimate', 'Procurement Register', 'Risk Register'],
        affectedBaselines: ['Scope Baseline', 'Cost Baseline', 'Schedule Baseline'],
        triggersRebaseline: true,
      ),
      CMChangeRequest(
        id: 'cm_demo_2',
        crNumber: 'CR-2026-002',
        title: 'Accelerate Steel Delivery',
        description: 'Expedite structural steel delivery to recover 5 days of schedule float',
        changeType: CMChangeType.procurement,
        priority: CMPriority.medium,
        status: CMStatus.implemented,
        submittedBy: 'Sarah Chen (Procurement Lead)',
        dateSubmitted: DateTime(2026, 6, 10),
        businessJustification: 'Recover schedule float before critical path impacts',
        alternativesConsidered: 'Option A: Air freight (selected — \$45K). Option B: Wait for next vessel (rejected — 21d delay).',
        affectedWorkPackages: const ['WP-2.1 Structural Steel'],
        deliverablesAdded: 0,
        deliverablesModified: 1,
        deliverablesRemoved: 0,
        initialCostEstimate: 45000,
        scheduleDaysImpact: -5,
        contingencyDrawdownRequested: 45000,
        impact: const FullImpactAssessment(
          schedule: ImpactDimension(name: 'Schedule', scheduleDays: -5, impactLevel: 3, narrative: 'Recovers 5 days of schedule float.', owner: 'Project Controls'),
          cost: ImpactDimension(name: 'Cost', costAmount: 45000, impactLevel: 2, narrative: 'Air-freight premium \$45K — funded from contingency.', owner: 'Finance'),
          procurement: ImpactDimension(name: 'Procurement', impact: 'Expedited shipping fee', impactLevel: 3, narrative: 'PO amended with expedite fee.', owner: 'Procurement Lead'),
        ),
        approvalSteps: [
          const CMApprovalStep(id: 's1', roleLabel: 'Project Manager', role: ApprovalRole.projectManager, decision: ApprovalDecision.approved, assigneeName: 'PM Office'),
          const CMApprovalStep(id: 's2', roleLabel: 'Project Controls', role: ApprovalRole.projectControls, decision: ApprovalDecision.approved, assigneeName: 'PC Team'),
          const CMApprovalStep(id: 's3', roleLabel: 'Finance', role: ApprovalRole.finance, decision: ApprovalDecision.approved, assigneeName: 'Finance Dept'),
        ],
        currentStepIndex: 3,
        approvedAt: DateTime(2026, 6, 15),
        implementedAt: DateTime(2026, 6, 20),
        affectedRegisters: ['Schedule', 'Cost Estimate', 'Procurement Register'],
        affectedBaselines: ['Schedule Baseline'],
        contingencyUsed: 45000,
        triggersRebaseline: false,
        implementationTasks: const [
          ImplementationTask(id: 'task_1', workPackageId: 'WP-2.1', workPackageName: 'Structural Steel Erection', status: ImplementationStatus.done, assignee: 'Sarah Chen', dueDate: null, completedAt: null, notes: 'Steel delivered 2 days ahead of revised ETA.'),
          ImplementationTask(id: 'task_2', workPackageId: 'WP-2.1', workPackageName: 'Erection Crew Mobilization', status: ImplementationStatus.done, assignee: 'Carlos Mendez', completedAt: null),
          ImplementationTask(id: 'task_3', workPackageId: 'WP-2.1', workPackageName: 'Schedule Update in P6', status: ImplementationStatus.inProgress, assignee: 'Priya Singh'),
        ],
      ),
      CMChangeRequest(
        id: 'cm_demo_3',
        crNumber: 'CR-2026-003',
        title: 'Cloud Infrastructure Upgrade',
        description: 'Upgrade cloud tier for production environment to handle increased load',
        changeType: CMChangeType.technical,
        priority: CMPriority.low,
        status: CMStatus.submitted,
        submittedBy: 'Mike Ross (DevOps)',
        dateSubmitted: DateTime(2026, 6, 25),
        businessJustification: 'Performance requirements exceed current tier capacity',
        impact: const FullImpactAssessment(
          cost: ImpactDimension(name: 'Cost', costAmount: 12000, impactLevel: 1, narrative: 'OpEx increase \$12K/year.'),
          technical: ImpactDimension(name: 'Technical', impact: 'No architecture change, tier upgrade only', impactLevel: 2, narrative: 'Configuration change only — no code changes.'),
        ),
        approvalSteps: [
          const CMApprovalStep(id: 's1', roleLabel: 'Product Owner', role: ApprovalRole.changeBoard),
        ],
        currentStepIndex: 0,
        isAgileRoutineRefinement: true,
        affectedRegisters: ['Cost Estimate', 'Budget'],
        affectedBaselines: [],
        triggersRebaseline: false,
      ),
      CMChangeRequest(
        id: 'cm_demo_4',
        crNumber: 'CR-2026-004',
        title: 'HVAC Re-Design for Cleanroom Annex',
        description: 'Stakeholder requested cleanroom annex (Class 10K) requires HVAC re-design with HEPA filtration and positive pressure differential.',
        changeType: CMChangeType.scope,
        priority: CMPriority.critical,
        status: CMStatus.pendingApproval,
        submittedBy: 'Aisha Patel (Program Manager)',
        dateSubmitted: DateTime(2026, 6, 28),
        businessJustification: 'New customer contract requires ISO 14644 Class 7 cleanroom — current design cannot meet particle count threshold.',
        alternativesConsidered: 'Option A: Retrofit existing HVAC (selected — \$620K, 28d). Option B: Build standalone cleanroom module (rejected — \$1.2M, 70d). Option C: Outsource to vendor (rejected — no IP control).',
        affectedWorkPackages: const ['WP-4.2 HVAC', 'WP-4.3 Controls', 'WP-5.1 Commissioning'],
        deliverablesAdded: 3,
        deliverablesModified: 2,
        deliverablesRemoved: 0,
        initialCostEstimate: 620000,
        scheduleDaysImpact: 28,
        contingencyDrawdownRequested: 500000,
        reserveDrawdownRequested: 120000,
        impact: const FullImpactAssessment(
          scope: ImpactDimension(name: 'Scope', impact: 'New cleanroom annex + HVAC re-design', isCritical: true, impactLevel: 5, narrative: 'Adds 3 new deliverables: HEPA filtration, positive-pressure controls, particle monitoring.', owner: 'Engineering Lead'),
          schedule: ImpactDimension(name: 'Schedule', scheduleDays: 28, isCritical: true, impactLevel: 5, narrative: 'Adds 28 days to critical path.', owner: 'Project Controls'),
          cost: ImpactDimension(name: 'Cost', costAmount: 620000, isCritical: true, impactLevel: 5, narrative: 'Capital \$620K — exceeds contingency, draws \$120K from reserve.', owner: 'Finance'),
          resources: ImpactDimension(name: 'Resources', impact: 'HVAC engineer + cleanroom consultant', impactLevel: 4, narrative: 'Requires specialist cleanroom consultant 6 weeks.', owner: 'Procurement Lead'),
          procurement: ImpactDimension(name: 'Procurement', impactLevel: 4, narrative: 'HEPA units long-lead 35d ARO.', owner: 'Procurement Lead'),
          contracts: ImpactDimension(name: 'Contracts', impactLevel: 3, narrative: 'HVAC subcontract change order required.', owner: 'Contracts'),
          risks: ImpactDimension(name: 'Risks', impactLevel: 4, narrative: 'Acceptance test risk — particle count threshold strict.', owner: 'Risk Manager'),
          quality: ImpactDimension(name: 'Quality', impactLevel: 4, narrative: 'ISO 14644 Class 7 acceptance criteria.', owner: 'Quality Manager'),
          safety: ImpactDimension(name: 'Safety', impactLevel: 2, narrative: 'No new safety hazards.', owner: 'Safety Officer'),
          stakeholders: ImpactDimension(name: 'Stakeholders', impactLevel: 3, narrative: 'Customer notified — approves additional cost.', owner: 'Project Manager'),
          funding: ImpactDimension(name: 'Funding', impactLevel: 4, narrative: 'Contingency + management reserve drawdown.', owner: 'Finance'),
          benefits: ImpactDimension(name: 'Benefits', impactLevel: 4, narrative: 'Unlocks \$4M customer contract.', owner: 'Sponsor'),
          dependencies: ImpactDimension(name: 'Dependencies', impactLevel: 3, narrative: 'Blocks commissioning of WP-5.1.', owner: 'Project Controls'),
          interfaces: ImpactDimension(name: 'Interfaces', impactLevel: 3, narrative: 'BMS integration for pressure monitoring.', owner: 'Engineering Lead'),
          technical: ImpactDimension(name: 'Technical', impactLevel: 3, narrative: 'Standard cleanroom design — well-understood.', owner: 'Engineering Lead'),
        ),
        approvalSteps: [
          const CMApprovalStep(id: 's1', roleLabel: 'Project Manager', role: ApprovalRole.projectManager, decision: ApprovalDecision.approved, assigneeName: 'Aisha Patel', decidedAt: null, comments: 'Approved — customer-funded.'),
          const CMApprovalStep(id: 's2', roleLabel: 'Project Controls', role: ApprovalRole.projectControls, decision: ApprovalDecision.approved, assigneeName: 'James Wong', comments: 'Schedule impact acceptable.'),
          const CMApprovalStep(id: 's3', roleLabel: 'Finance', role: ApprovalRole.finance, decision: ApprovalDecision.escalated, assigneeName: 'Finance Dept', escalationTarget: 'Sponsor', escalationReason: 'Exceeds contingency — requires management reserve drawdown.'),
          const CMApprovalStep(id: 's4', roleLabel: 'Sponsor', role: ApprovalRole.sponsor),
        ],
        currentStepIndex: 3,
        affectedRegisters: ['WBS', 'Schedule', 'Cost Estimate', 'Procurement Register', 'Risk Register', 'Quality Plan'],
        affectedBaselines: ['Scope Baseline', 'Cost Baseline', 'Schedule Baseline', 'Quality Baseline'],
        triggersRebaseline: true,
        implementationTasks: const [
          ImplementationTask(id: 'task_1', workPackageId: 'WP-4.2', workPackageName: 'HVAC Re-Design Drawings', status: ImplementationStatus.todo, assignee: 'Engineering Lead'),
          ImplementationTask(id: 'task_2', workPackageId: 'WP-4.3', workPackageName: 'Controls Programming Update', status: ImplementationStatus.todo, assignee: 'Controls Engineer'),
          ImplementationTask(id: 'task_3', workPackageId: 'WP-5.1', workPackageName: 'Cleanroom Commissioning & Particle Test', status: ImplementationStatus.todo, assignee: 'Quality Manager'),
        ],
      ),
    ];
    _crCounter = 4;
    _usedContingency = 45000;
    _currentBAC = 12545000; // original 12.5M + 45K steel delivery
    _currentScopeHash = 'sha256:v2_after_steel_2026_06_20';
    _currentBaselineFinish = DateTime(2027, 6, 25);

    // Seed baseline history with one prior revision (from CR-2026-002).
    _baselineHistory = [
      BaselineRevisionRecord(
        version: 1,
        revisionDate: DateTime(2026, 6, 20),
        revisedBy: 'Sarah Chen',
        linkedCRId: 'cm_demo_2',
        reason: 'CR-2026-002: Accelerate Steel Delivery',
        updatedBaselines: const ['Schedule Baseline'],
        previousBudget: 12500000,
        revisedBudget: 12545000,
        previousFinish: DateTime(2027, 6, 30),
        revisedFinish: DateTime(2027, 6, 25),
        previousScopeHash: 'sha256:a1b2c3d4e5f6',
        revisedScopeHash: 'sha256:v2_after_steel_2026_06_20',
        approver: 'Sponsor',
      ),
    ];

    // Seed audit trail with several historical entries spanning multiple actors.
    _auditTrail = [
      CMAuditEntry(id: 'a1', user: 'John Smith', timestamp: DateTime.now().subtract(const Duration(hours: 240)), action: 'CR Created', details: 'CR-2026-001: Add Fire Suppression System', linkedCRId: 'cm_demo_1'),
      CMAuditEntry(id: 'a2', user: 'Sarah Chen', timestamp: DateTime.now().subtract(const Duration(hours: 480)), action: 'CR Created', details: 'CR-2026-002: Accelerate Steel Delivery', linkedCRId: 'cm_demo_2'),
      CMAuditEntry(id: 'a3', user: 'Sarah Chen', timestamp: DateTime.now().subtract(const Duration(hours: 360)), action: 'Approval Decision', details: 'CR-2026-002 • Project Manager → Approved', linkedCRId: 'cm_demo_2'),
      CMAuditEntry(id: 'a4', user: 'you@ndu.project', timestamp: DateTime.now().subtract(const Duration(hours: 350)), action: 'Workflow Finalized', details: 'CR-2026-002 • APPROVED', linkedCRId: 'cm_demo_2'),
      CMAuditEntry(id: 'a5', user: 'you@ndu.project', timestamp: DateTime.now().subtract(const Duration(hours: 320)), action: 'Baseline Applied', details: 'v1 • BAC \$12,500,000 → \$12,545,000 • CR-2026-002', linkedCRId: 'cm_demo_2'),
      CMAuditEntry(id: 'a6', user: 'you@ndu.project', timestamp: DateTime.now().subtract(const Duration(hours: 300)), action: 'CR Implemented', details: 'CR-2026-002 implemented', linkedCRId: 'cm_demo_2'),
      CMAuditEntry(id: 'a7', user: 'Mike Ross', timestamp: DateTime.now().subtract(const Duration(hours: 72)), action: 'CR Created', details: 'CR-2026-003: Cloud Infrastructure Upgrade', linkedCRId: 'cm_demo_3'),
      CMAuditEntry(id: 'a8', user: 'Aisha Patel', timestamp: DateTime.now().subtract(const Duration(hours: 24)), action: 'CR Created', details: 'CR-2026-004: HVAC Re-Design for Cleanroom Annex', linkedCRId: 'cm_demo_4'),
      CMAuditEntry(id: 'a9', user: 'Aisha Patel', timestamp: DateTime.now().subtract(const Duration(hours: 20)), action: 'Approval Decision', details: 'CR-2026-004 • Project Manager → Approved', linkedCRId: 'cm_demo_4'),
      CMAuditEntry(id: 'a10', user: 'James Wong', timestamp: DateTime.now().subtract(const Duration(hours: 18)), action: 'Approval Decision', details: 'CR-2026-004 • Project Controls → Approved', linkedCRId: 'cm_demo_4'),
      CMAuditEntry(id: 'a11', user: 'Finance Dept', timestamp: DateTime.now().subtract(const Duration(hours: 12)), action: 'Approval Decision', details: 'CR-2026-004 • Finance → Escalated (exceeds contingency)', linkedCRId: 'cm_demo_4'),
    ];
    notifyListeners();
  }
}
