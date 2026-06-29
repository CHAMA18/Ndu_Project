/// Project Controls — ChangeNotifier state management
///
/// Serves as the single source of truth for project controls.
/// Persists to SharedPreferences.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ndu_project/project_controls/models/project_controls_models.dart';

const String _storageKey = 'ndu_project_controls_v1';
const String _currentUser = 'you@ndu.project';

class ProjectControlsProvider extends ChangeNotifier {
  ProjectControlsState _state = ProjectControlsState(
    deliveryModel: DeliveryModel.waterfall,
    isBaselined: false,
    isExecutionActive: false,
    workPackages: [],
    changeRequests: [],
    baselineHistory: [],
    auditTrail: [],
  );

  ProjectControlsState get state => _state;

  ProjectControlsProvider() {
    _loadFromStorage();
  }

  // ─── Persistence ─────────────────────────────────────────────────────
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        // Simplified deserialization
        _state = _state.copyWith(
          deliveryModel: DeliveryModel.values
              .byName(data['deliveryModel'] as String? ?? 'waterfall'),
          isBaselined: data['isBaselined'] as bool? ?? false,
          isExecutionActive: data['isExecutionActive'] as bool? ?? false,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading PC state: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode({
        'deliveryModel': _state.deliveryModel.name,
        'isBaselined': _state.isBaselined,
        'isExecutionActive': _state.isExecutionActive,
      }));
    } catch (e) {
      debugPrint('Error saving PC state: $e');
    }
  }

  // ─── Setup ───────────────────────────────────────────────────────────
  void setDeliveryModel(DeliveryModel model) {
    _state = _state.copyWith(deliveryModel: model);
    notifyListeners();
    _saveToStorage();
  }

  void activateExecution() {
    _state = _state.copyWith(isExecutionActive: true);
    notifyListeners();
    _saveToStorage();
  }

  // ─── Work Packages ──────────────────────────────────────────────────
  void addWorkPackage(WorkPackageControl wp) {
    _state = _state.copyWith(workPackages: [..._state.workPackages, wp]);
    _addAudit('workPackages', '—', wp.name, 'Work package added');
    notifyListeners();
    _saveToStorage();
  }

  void updateWorkPackage(String id, WorkPackageControl updated) {
    final oldWp = _state.workPackages.firstWhere((w) => w.id == id);
    _state = _state.copyWith(
      workPackages: _state.workPackages
          .map((w) => w.id == id ? updated : w)
          .toList(),
    );
    if (oldWp.actualCost != updated.actualCost) {
      _addAudit('actualCost.$id', '${oldWp.actualCost}',
          '${updated.actualCost}', 'Actual cost updated');
    }
    if (oldWp.percentComplete != updated.percentComplete) {
      _addAudit('percentComplete.$id', '${oldWp.percentComplete}',
          '${updated.percentComplete}', 'Progress updated');
    }
    notifyListeners();
    _saveToStorage();
  }

  // ─── Change Management ──────────────────────────────────────────────

  /// Submit a new change request.
  /// For Waterfall: ALL scope changes require formal MoC.
  /// For Agile: routine backlog refinement is tracked in audit only;
  /// controlled baseline changes (new Epics, budget increases, etc.) require formal workflow.
  void submitChangeRequest(ChangeRequest cr) {
    _state = _state.copyWith(changeRequests: [..._state.changeRequests, cr]);
    _addAudit('changeRequest', '—', cr.id,
        'Change request submitted: ${cr.description}');
    notifyListeners();
    _saveToStorage();
  }

  void updateChangeStatus(String id, ChangeStatus status) {
    _state = _state.copyWith(
      changeRequests: _state.changeRequests
          .map((cr) => cr.id == id
              ? cr.copyWith(
                  status: status,
                  approvedAt: status == ChangeStatus.approved
                      ? DateTime.now()
                      : cr.approvedAt,
                  implementedAt: status == ChangeStatus.implemented
                      ? DateTime.now()
                      : cr.implementedAt,
                )
              : cr)
          .toList(),
    );
    _addAudit('changeStatus.$id', '', status.label,
        'Change request status updated to ${status.label}');
    notifyListeners();
    _saveToStorage();
  }

  void approveChangeStep(String changeId) {
    final cr = _state.changeRequests.firstWhere((c) => c.id == changeId);
    if (cr.approval == null) return;
    final steps = cr.approval!.steps;
    final currentIdx = cr.approval!.currentStepIndex;
    if (currentIdx >= steps.length) return;

    final updatedSteps = steps.asMap().map((i, s) => MapEntry(
        i,
        i == currentIdx
            ? ApprovalStep(
                id: s.id,
                role: s.role,
                assigneeName: s.assigneeName,
                approved: true,
                approvedAt: DateTime.now(),
                comments: s.comments,
              )
            : s)).values.toList();

    final newIdx = currentIdx + 1;
    final allApproved = updatedSteps.every((s) => s.approved);

    final updatedWorkflow = ApprovalWorkflow(
      steps: updatedSteps,
      currentStepIndex: newIdx,
    );

    _state = _state.copyWith(
      changeRequests: _state.changeRequests
          .map((c) => c.id == changeId
              ? c.copyWith(
                  approval: updatedWorkflow,
                  status: allApproved
                      ? ChangeStatus.approved
                      : ChangeStatus.underReview,
                  approvedAt: allApproved ? DateTime.now() : c.approvedAt,
                )
              : c)
          .toList(),
    );
    _addAudit('changeApproval.$changeId', 'step $currentIdx',
        allApproved ? 'ALL APPROVED' : 'step $newIdx',
        'Change approval step ${currentIdx + 1} approved');
    notifyListeners();
    _saveToStorage();
  }

  void rejectChangeRequest(String id, String reason) {
    _state = _state.copyWith(
      changeRequests: _state.changeRequests
          .map((cr) => cr.id == id
              ? cr.copyWith(status: ChangeStatus.rejected)
              : cr)
          .toList(),
    );
    _addAudit('changeRejection.$id', '', 'REJECTED',
        'Change request rejected: $reason');
    notifyListeners();
    _saveToStorage();
  }

  // ─── Baseline Management ────────────────────────────────────────────
  void lockBaseline(BaselineType type) {
    final baseline = BaselineSnapshot(
      version: _state.baselineHistory.length + 1,
      lockedAt: DateTime.now(),
      lockedBy: _currentUser,
      type: type,
      workPackages: List.from(_state.workPackages),
      totalBudget: _state.totalOriginalBudget,
    );
    _state = _state.copyWith(
      isBaselined: true,
      baselineHistory: [..._state.baselineHistory, baseline],
    );
    _addAudit('baseline.${type.name}', '', 'v${baseline.version}',
        '${type.label} locked at version ${baseline.version}');
    notifyListeners();
    _saveToStorage();
  }

  // ─── Audit Trail ────────────────────────────────────────────────────
  void _addAudit(String field, String prev, String next, String reason) {
    final entry = AuditEntry(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      user: _currentUser,
      timestamp: DateTime.now(),
      field: field,
      previousValue: prev,
      newValue: next,
      reason: reason,
    );
    _state = _state.copyWith(auditTrail: [..._state.auditTrail, entry]);
  }

  // ─── Scope Growth Detection ────────────────────────────────────────

  /// Detect unauthorized scope changes (activities added without approved change request)
  List<String> detectScopeGrowth() {
    final issues = <String>[];
    // Check for work packages with no corresponding approved change request
    for (final wp in _state.workPackages) {
      final hasApproval = _state.changeRequests.any((cr) =>
          cr.status == ChangeStatus.approved &&
          cr.description.toLowerCase().contains(wp.name.toLowerCase()));
      if (!hasApproval && wp.status == 'Added') {
        issues.add('${wp.wbsCode} ${wp.name} — added without approved change request');
      }
    }
    return issues;
  }

  // ─── Seed demo data ────────────────────────────────────────────────
  void seedDemoData(DeliveryModel model) {
    final wps = [
      WorkPackageControl(
        id: 'wp_001',
        wbsCode: '1.1',
        name: model == DeliveryModel.agile
            ? 'User Authentication Epic'
            : 'Site Preparation',
        scopeDescription: model == DeliveryModel.agile
            ? 'Complete authentication system with MFA'
            : 'Clear, grade, and prepare site for construction',
        deliverables: ['Completed site survey', 'Grading plan'],
        acceptanceCriteria: ['Site passes geotech inspection'],
        priority: 'High',
        status: 'In Progress',
        plannedStart: DateTime(2026, 1, 15),
        plannedFinish: DateTime(2026, 3, 30),
        actualStart: DateTime(2026, 1, 18),
        percentComplete: 68,
        isCriticalPath: true,
        remainingDuration: 42,
        floatDays: 5,
        originalBudget: 4200000,
        currentBudget: 4200000,
        committedCost: 3100000,
        actualCost: 2950000,
        earnedValue: 2856000,
        plannedValue: 3100000,
        storyPoints: model == DeliveryModel.agile ? 55 : null,
        storyPointsCompleted: model == DeliveryModel.agile ? 38 : null,
        velocity: model == DeliveryModel.agile ? 22 : null,
        progressMethod: model == DeliveryModel.agile
            ? ProgressMethod.storyPointsCompleted
            : ProgressMethod.physicalPercent,
      ),
      WorkPackageControl(
        id: 'wp_002',
        wbsCode: '1.2',
        name: model == DeliveryModel.agile
            ? 'Customer Management Epic'
            : 'Foundation Works',
        scopeDescription: model == DeliveryModel.agile
            ? 'Customer CRUD, search, and history'
            : 'Concrete foundations and piers',
        deliverables: ['Foundation drawings', 'Concrete pour records'],
        acceptanceCriteria: ['Strength test passes'],
        priority: 'High',
        status: 'Not Started',
        plannedStart: DateTime(2026, 4, 1),
        plannedFinish: DateTime(2026, 6, 15),
        percentComplete: 0,
        isCriticalPath: true,
        remainingDuration: 75,
        floatDays: 0,
        originalBudget: 6800000,
        currentBudget: 6800000,
        committedCost: 0,
        actualCost: 0,
        earnedValue: 0,
        plannedValue: 0,
        storyPoints: model == DeliveryModel.agile ? 89 : null,
        storyPointsCompleted: model == DeliveryModel.agile ? 0 : null,
        velocity: model == DeliveryModel.agile ? 22 : null,
        progressMethod: model == DeliveryModel.agile
            ? ProgressMethod.storyPointsCompleted
            : ProgressMethod.physicalPercent,
      ),
      WorkPackageControl(
        id: 'wp_003',
        wbsCode: '1.3',
        name: model == DeliveryModel.agile
            ? 'Reporting Epic'
            : 'Structural Steel',
        scopeDescription: model == DeliveryModel.agile
            ? 'Dashboards and reporting suite'
            : 'Steel erection for building structure',
        deliverables: ['Steel shop drawings', 'Erection sequence'],
        acceptanceCriteria: ['Inspection passed'],
        priority: 'Medium',
        status: 'In Progress',
        plannedStart: DateTime(2026, 3, 1),
        plannedFinish: DateTime(2026, 5, 30),
        actualStart: DateTime(2026, 3, 5),
        percentComplete: 45,
        isCriticalPath: false,
        remainingDuration: 56,
        floatDays: 12,
        originalBudget: 5200000,
        currentBudget: 5400000,
        committedCost: 4200000,
        actualCost: 2400000,
        earnedValue: 2430000,
        plannedValue: 2800000,
        storyPoints: model == DeliveryModel.agile ? 42 : null,
        storyPointsCompleted: model == DeliveryModel.agile ? 19 : null,
        velocity: model == DeliveryModel.agile ? 22 : null,
        progressMethod: model == DeliveryModel.agile
            ? ProgressMethod.storyPointsCompleted
            : ProgressMethod.physicalPercent,
      ),
    ];

    final demoCR = ChangeRequest(
      id: 'cr_001',
      description: 'Add fire suppression system to Site Preparation scope',
      requestor: 'John Smith (Site Manager)',
      justification: 'Local fire code update requires automated suppression',
      rootCause: 'Regulatory change',
      category: ChangeCategory.scope,
      priority: 'High',
      status: ChangeStatus.underReview,
      impact: const ImpactAnalysis(
        scheduleImpactDays: 14,
        costImpactAmount: 350000,
        scopeImpact: 'New deliverable: Fire suppression installation',
        resourceImpact: 'Additional fire protection contractor required',
        procurementImpact: 'New PO for suppression equipment',
        riskImpact: 'Reduces fire risk but adds schedule risk',
        qualityImpact: 'Must meet NFPA standards',
      ),
      approval: ApprovalWorkflow(steps: [
        ApprovalStep(id: 'step_1', role: ApprovalRole.projectManager, approved: true, approvedAt: DateTime(2026, 6, 20)),
        ApprovalStep(id: 'step_2', role: ApprovalRole.projectControls, approved: false),
        ApprovalStep(id: 'step_3', role: ApprovalRole.finance, approved: false),
        ApprovalStep(id: 'step_4', role: ApprovalRole.sponsor, approved: false),
      ], currentStepIndex: 1),
      dateSubmitted: DateTime(2026, 6, 18),
      affectedBaselines: ['Scope Baseline', 'Cost Baseline', 'Schedule Baseline'],
    );

    _state = _state.copyWith(
      deliveryModel: model,
      isBaselined: true,
      isExecutionActive: true,
      workPackages: wps,
      changeRequests: [demoCR],
    );
    notifyListeners();
    _saveToStorage();
  }
}
