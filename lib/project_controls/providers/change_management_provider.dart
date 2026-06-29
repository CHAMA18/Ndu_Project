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

  List<CMChangeRequest> get changeRequests => _changeRequests;
  List<CMAuditEntry> get auditTrail => _auditTrail;
  List<BaselineRevisionRecord> get baselineHistory => _baselineHistory;

  double get totalContingency => _totalContingency;
  double get usedContingency => _usedContingency;
  double get remainingContingency => _totalContingency - _usedContingency;
  double get totalReserve => _totalReserve;
  double get usedReserve => _usedReserve;
  double get remainingReserve => _totalReserve - _usedReserve;

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

  void createChangeRequest({
    required String title,
    required String description,
    required CMChangeType changeType,
    required CMPriority priority,
    required String businessJustification,
    String? rootCause,
    DateTime? requestedCompletion,
    bool isEmergency = false,
    bool isAgileRoutineRefinement = false,
    FullImpactAssessment? impact,
    List<CMApprovalStep>? approvalSteps,
    List<String>? affectedRegisters,
    List<String>? affectedBaselines,
  }) {
    final cr = CMChangeRequest(
      id: 'cm_${DateTime.now().millisecondsSinceEpoch}',
      crNumber: _generateCRNumber(),
      title: title,
      description: description,
      changeType: changeType,
      priority: isEmergency ? CMPriority.emergency : priority,
      status: isEmergency ? CMStatus.emergency : CMStatus.submitted,
      submittedBy: _currentUser,
      dateSubmitted: DateTime.now(),
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
    );

    _changeRequests = [..._changeRequests, cr];
    _addAudit('CR Created', '${cr.crNumber}: ${cr.title}', cr.id);
    notifyListeners();
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

  // ─── Helpers ───────────────────────────────────────────────────────

  void _updateCR(String id, CMChangeRequest updated) {
    _changeRequests = _changeRequests.map((c) => c.id == id ? updated : c).toList();
  }

  void _addAudit(String action, String details, String? crId) {
    _auditTrail = [..._auditTrail, CMAuditEntry(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      user: _currentUser,
      timestamp: DateTime.now(),
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
        impact: const FullImpactAssessment(
          scope: ImpactDimension(name: 'Scope', impact: 'New deliverable: Fire suppression installation', isCritical: true),
          schedule: ImpactDimension(name: 'Schedule', scheduleDays: 14, isCritical: true),
          cost: ImpactDimension(name: 'Cost', costAmount: 350000, isCritical: true),
          resources: ImpactDimension(name: 'Resources', impact: 'Additional fire protection contractor required'),
          procurement: ImpactDimension(name: 'Procurement', impact: 'New PO for suppression equipment'),
          risks: ImpactDimension(name: 'Risks', impact: 'Reduces fire risk but adds schedule risk'),
          quality: ImpactDimension(name: 'Quality', impact: 'Must meet NFPA standards'),
        ),
        approvalSteps: [
          const CMApprovalStep(id: 's1', roleLabel: 'Project Manager', decision: ApprovalDecision.approved, decidedAt: null, assigneeName: 'PM Office'),
          const CMApprovalStep(id: 's2', roleLabel: 'Project Controls'),
          const CMApprovalStep(id: 's3', roleLabel: 'Finance'),
          const CMApprovalStep(id: 's4', roleLabel: 'Sponsor'),
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
        status: CMStatus.approved,
        submittedBy: 'Sarah Chen (Procurement Lead)',
        dateSubmitted: DateTime(2026, 6, 10),
        businessJustification: 'Recover schedule float before critical path impacts',
        impact: const FullImpactAssessment(
          schedule: ImpactDimension(name: 'Schedule', scheduleDays: -5),
          cost: ImpactDimension(name: 'Cost', costAmount: 45000),
          procurement: ImpactDimension(name: 'Procurement', impact: 'Expedited shipping fee'),
        ),
        approvalSteps: [
          const CMApprovalStep(id: 's1', roleLabel: 'Project Manager', decision: ApprovalDecision.approved, assigneeName: 'PM Office'),
          const CMApprovalStep(id: 's2', roleLabel: 'Project Controls', decision: ApprovalDecision.approved, assigneeName: 'PC Team'),
          const CMApprovalStep(id: 's3', roleLabel: 'Finance', decision: ApprovalDecision.approved, assigneeName: 'Finance Dept'),
        ],
        currentStepIndex: 3,
        approvedAt: DateTime(2026, 6, 15),
        affectedRegisters: ['Schedule', 'Cost Estimate', 'Procurement Register'],
        affectedBaselines: ['Schedule Baseline'],
        contingencyUsed: 45000,
        triggersRebaseline: false,
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
          cost: ImpactDimension(name: 'Cost', costAmount: 12000),
          technical: ImpactDimension(name: 'Technical', impact: 'No architecture change, tier upgrade only'),
        ),
        approvalSteps: [
          const CMApprovalStep(id: 's1', roleLabel: 'Product Owner'),
        ],
        currentStepIndex: 0,
        isAgileRoutineRefinement: true,
        affectedRegisters: ['Cost Estimate', 'Budget'],
        affectedBaselines: [],
        triggersRebaseline: false,
      ),
    ];
    _crCounter = 3;
    _usedContingency = 45000;
    _auditTrail = [
      CMAuditEntry(id: 'a1', user: 'John Smith', timestamp: DateTime.now().subtract(const Duration(hours: 48)), action: 'CR Created', details: 'CR-2026-001: Add Fire Suppression System', linkedCRId: 'cm_demo_1'),
    ].map((e) => CMAuditEntry(id: e.id, user: e.user, timestamp: DateTime.now().subtract(const Duration(hours: 48)), action: e.action, details: e.details, linkedCRId: e.linkedCRId)).toList();
    notifyListeners();
  }
}
