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
  void lockBaseline(BaselineType type, {String? reason}) {
    final baseline = BaselineSnapshot(
      version: _state.baselineHistory.length + 1,
      lockedAt: DateTime.now(),
      lockedBy: _currentUser,
      type: type,
      workPackages: List.from(_state.workPackages),
      totalBudget: _state.totalOriginalBudget,
      reason: reason ?? 'Manual baseline lock',
    );
    _state = _state.copyWith(
      isBaselined: true,
      baselineHistory: [..._state.baselineHistory, baseline],
    );
    _addAudit('baseline.${type.name}', '', 'v${baseline.version}',
        '${type.label} locked at version ${baseline.version}${reason != null ? ' — $reason' : ''}');
    notifyListeners();
    _saveToStorage();
  }

  /// Convenience wrapper that explicitly creates a snapshot with a reason.
  void createBaselineSnapshot(BaselineType type, String reason) {
    lockBaseline(type, reason: reason);
  }

  /// Restore the work-package set + total budget from a prior baseline
  /// version.  Logs a rollback audit entry.  Does not delete subsequent
  /// baseline history entries (they remain as an audit record).
  void rollbackToBaseline(int version) {
    final baseline = _state.baselineHistory
        .cast<BaselineSnapshot?>()
        .firstWhere((b) => b?.version == version, orElse: () => null);
    if (baseline == null) return;
    final previousWpCount = _state.workPackages.length;
    _state = _state.copyWith(
      workPackages: List.from(baseline.workPackages),
      isBaselined: true,
    );
    _addAudit('baseline.rollback', 'v$version', 'current',
        'Rolled back to baseline v$version — restored ${baseline.workPackages.length} work packages (was $previousWpCount), budget \$${baseline.totalBudget}');
    notifyListeners();
    _saveToStorage();
  }

  // ─── Schedule Control ───────────────────────────────────────────────
  void addScheduleVariance(ScheduleVariance sv) {
    _state = _state.copyWith(
      scheduleVariances: [..._state.scheduleVariances, sv],
    );
    _addAudit('scheduleVariance.${sv.workPackageId}', '—', 'created',
        'Schedule variance record added for ${sv.workPackageId}');
    notifyListeners();
    _saveToStorage();
  }

  void updateScheduleVariance(String workPackageId, ScheduleVariance updated) {
    final existing = _state.scheduleVariances
        .any((sv) => sv.workPackageId == workPackageId);
    _state = _state.copyWith(
      scheduleVariances: existing
          ? _state.scheduleVariances
              .map((sv) =>
                  sv.workPackageId == workPackageId ? updated : sv)
              .toList()
          : [..._state.scheduleVariances, updated],
    );
    _addAudit('scheduleVariance.$workPackageId', 'updated',
        updated.compressionStrategy.label,
        'Schedule variance updated — strategy: ${updated.compressionStrategy.label}, reason: "${updated.delayReason}"');
    notifyListeners();
    _saveToStorage();
  }

  void setCompressionStrategy(
      String workPackageId, CompressionStrategy strategy) {
    final idx =
        _state.scheduleVariances.indexWhere((sv) => sv.workPackageId == workPackageId);
    if (idx == -1) return;
    final old = _state.scheduleVariances[idx];
    final updated = old.copyWith(compressionStrategy: strategy);
    final newList = List<ScheduleVariance>.from(_state.scheduleVariances);
    newList[idx] = updated;
    _state = _state.copyWith(scheduleVariances: newList);
    _addAudit('scheduleVariance.$workPackageId.compression',
        old.compressionStrategy.label,
        strategy.label,
        'Compression strategy set to ${strategy.label} for $workPackageId');
    notifyListeners();
    _saveToStorage();
  }

  void setDelayReason(String workPackageId, String reason) {
    final idx =
        _state.scheduleVariances.indexWhere((sv) => sv.workPackageId == workPackageId);
    if (idx == -1) return;
    final updated =
        _state.scheduleVariances[idx].copyWith(delayReason: reason);
    final newList = List<ScheduleVariance>.from(_state.scheduleVariances);
    newList[idx] = updated;
    _state = _state.copyWith(scheduleVariances: newList);
    _addAudit('scheduleVariance.$workPackageId.delayReason', '',
        reason.isEmpty ? '(cleared)' : reason,
        'Delay reason recorded for $workPackageId');
    notifyListeners();
    _saveToStorage();
  }

  // ─── Risk & Issues ──────────────────────────────────────────────────
  void addRiskItem(RiskItem item) {
    _state = _state.copyWith(risksAndIssues: [..._state.risksAndIssues, item]);
    _addAudit(item.isIssue ? 'issue.${item.id}' : 'risk.${item.id}', '—',
        item.status.label,
        '${item.isIssue ? "Issue" : "Risk"} ${item.id} added: ${item.description}');
    notifyListeners();
    _saveToStorage();
  }

  void updateRiskItem(String id, RiskItem updated) {
    _state = _state.copyWith(
      risksAndIssues: _state.risksAndIssues
          .map((r) => r.id == id ? updated : r)
          .toList(),
    );
    _addAudit('risk.$id', '', updated.status.label,
        'Risk/issue $id updated — status: ${updated.status.label}, owner: ${updated.owner}');
    notifyListeners();
    _saveToStorage();
  }

  void closeRiskItem(String id) {
    final existing =
        _state.risksAndIssues.firstWhere((r) => r.id == id);
    updateRiskItem(id, existing.copyWith(status: RiskStatus.closed));
  }

  // ─── Resource Control ───────────────────────────────────────────────
  void addResourceAllocation(ResourceAllocation ra) {
    _state = _state.copyWith(
      resourceAllocations: [..._state.resourceAllocations, ra],
    );
    _addAudit('resource.${ra.resourceName}', '—', 'added',
        'Resource ${ra.resourceName} (${ra.discipline.label}) added');
    notifyListeners();
    _saveToStorage();
  }

  void updateResourceAllocation(
      String resourceName, ResourceAllocation updated) {
    final existing =
        _state.resourceAllocations.any((r) => r.resourceName == resourceName);
    _state = _state.copyWith(
      resourceAllocations: existing
          ? _state.resourceAllocations
              .map((r) => r.resourceName == resourceName ? updated : r)
              .toList()
          : [..._state.resourceAllocations, updated],
    );
    _addAudit('resource.$resourceName', 'updated',
        '${updated.weeklyHours.length}w',
        'Resource allocation updated for $resourceName');
    notifyListeners();
    _saveToStorage();
  }

  // ─── Reporting ──────────────────────────────────────────────────────
  void generateReport(ReportType type, DateTime start, DateTime end,
      {String? summaryOverride}) {
    final summary = summaryOverride ?? _buildDefaultReportSummary(type, start, end);
    final report = ReportRecord(
      id: 'rpt_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      generatedAt: DateTime.now(),
      dateRangeStart: start,
      dateRangeEnd: end,
      generatedBy: _currentUser,
      summaryText: summary,
    );
    _state = _state.copyWith(reports: [..._state.reports, report]);
    _addAudit('report.${type.name}', '—', report.id,
        '${type.label} generated (${start.day}/${start.month}–${end.day}/${end.month})');
    notifyListeners();
    _saveToStorage();
  }

  String _buildDefaultReportSummary(
      ReportType type, DateTime start, DateTime end) {
    final rangeLabel =
        '${start.day}/${start.month}/${start.year} – ${end.day}/${end.month}/${end.year}';
    switch (type) {
      case ReportType.costVariance:
        final cv = _state.totalEarnedValue - _state.totalActualCost;
        return 'Cost Variance Report ($rangeLabel)\n'
            'BAC: \$${(_state.totalOriginalBudget / 1000000).toStringAsFixed(2)}M • '
            'AC: \$${(_state.totalActualCost / 1000000).toStringAsFixed(2)}M • '
            'EV: \$${(_state.totalEarnedValue / 1000000).toStringAsFixed(2)}M\n'
            'CV: \$${(cv / 1000000).toStringAsFixed(2)}M • CPI: ${_state.portfolioCPI.toStringAsFixed(2)} • '
            'EAC: \$${(_state.portfolioEAC / 1000000).toStringAsFixed(2)}M';
      case ReportType.scheduleVariance:
        final sv = _state.totalEarnedValue - _state.totalPlannedValue;
        return 'Schedule Variance Report ($rangeLabel)\n'
            'PV: \$${(_state.totalPlannedValue / 1000000).toStringAsFixed(2)}M • '
            'EV: \$${(_state.totalEarnedValue / 1000000).toStringAsFixed(2)}M\n'
            'SV: \$${(sv / 1000000).toStringAsFixed(2)}M • SPI: ${_state.portfolioSPI.toStringAsFixed(2)}\n'
            'Critical-path WPs: ${_state.criticalPathCount} • Delayed WPs: ${_state.delayedWorkPackagesCount}';
      case ReportType.evmForecast:
        return 'EVM Forecast Report ($rangeLabel)\n'
            'EAC: \$${(_state.portfolioEAC / 1000000).toStringAsFixed(2)}M • '
            'ETC: \$${((_state.portfolioEAC - _state.totalActualCost) / 1000000).toStringAsFixed(2)}M\n'
            'VAC: \$${(_state.portfolioVAC / 1000000).toStringAsFixed(2)}M • '
            'Avg progress: ${_state.avgPercentComplete.round()}%';
      case ReportType.riskBurnDown:
        final open = _state.openRisks.length;
        final critical = _state.criticalRisksCount;
        return 'Risk Burn-down Report ($rangeLabel)\n'
            'Open risks: $open • Critical risks: $critical • Open issues: ${_state.openIssues.length}\n'
            'Realized risks: ${_state.risksAndIssues.where((r) => r.status == RiskStatus.realized).length} • '
            'Closed: ${_state.risksAndIssues.where((r) => r.status == RiskStatus.closed).length}';
      case ReportType.auditTrail:
        return 'Audit Trail Report ($rangeLabel)\n'
            'Total audit entries: ${_state.auditTrail.length} • '
            'Generated by $_currentUser\n'
            'Earliest: ${_state.auditTrail.isEmpty ? "—" : _state.auditTrail.first.timestamp} • '
            'Latest: ${_state.auditTrail.isEmpty ? "—" : _state.auditTrail.last.timestamp}';
      case ReportType.performanceSummary:
        return 'Performance Summary Report ($rangeLabel)\n'
            'Health score: ${_state.healthScore}/100 • CPI: ${_state.portfolioCPI.toStringAsFixed(2)} • '
            'SPI: ${_state.portfolioSPI.toStringAsFixed(2)}\n'
            'Work packages: ${_state.workPackages.length} • Open changes: ${_state.openChangeRequests}';
    }
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

    // ─── Baseline history (two prior snapshots for diff/compare) ─────────
    final baselineV1 = BaselineSnapshot(
      version: 1,
      lockedAt: DateTime(2026, 1, 5),
      lockedBy: 'jane.doe@ndu.project',
      type: BaselineType.scope,
      workPackages: wps.take(2).toList(),
      totalBudget: wps.take(2).fold(0.0, (s, w) => s + w.originalBudget),
      reason: 'Initial project baseline at kickoff',
    );
    final baselineV2 = BaselineSnapshot(
      version: 2,
      lockedAt: DateTime(2026, 3, 1),
      lockedBy: 'jane.doe@ndu.project',
      type: BaselineType.scope,
      workPackages: List.from(wps),
      totalBudget: wps.fold(0.0, (s, w) => s + w.originalBudget),
      reason: 'Added Structural Steel work package after design review',
    );

    // ─── Schedule variances (one per work package) ──────────────────────
    final scheduleVariances = [
      ScheduleVariance(
        workPackageId: 'wp_001',
        plannedStart: DateTime(2026, 1, 15),
        actualStart: DateTime(2026, 1, 18),
        plannedFinish: DateTime(2026, 3, 30),
        floatDays: 5,
        delayReason: 'Late mobilisation due to equipment transport delays',
        compressionStrategy: CompressionStrategy.none,
      ),
      ScheduleVariance(
        workPackageId: 'wp_002',
        plannedStart: DateTime(2026, 4, 1),
        plannedFinish: DateTime(2026, 6, 15),
        floatDays: 0,
        delayReason: '',
        compressionStrategy: CompressionStrategy.fastTrack,
      ),
      ScheduleVariance(
        workPackageId: 'wp_003',
        plannedStart: DateTime(2026, 3, 1),
        actualStart: DateTime(2026, 3, 5),
        plannedFinish: DateTime(2026, 5, 30),
        floatDays: 12,
        delayReason: 'Shop drawing revisions required after vendor feedback',
        compressionStrategy: CompressionStrategy.crash,
      ),
    ];

    // ─── Risks & Issues ─────────────────────────────────────────────────
    final risksAndIssues = [
      const RiskItem(
        id: 'rsk_001',
        description: 'Long-lead steel delivery may slip beyond Q3',
        probability: 4,
        impact: 5,
        owner: 'Procurement Lead',
        mitigation: 'Dual-source RFQs issued; expedite fee budget set',
        status: RiskStatus.open,
      ),
      const RiskItem(
        id: 'rsk_002',
        description: 'Concrete pour weather risk during monsoon window',
        probability: 3,
        impact: 4,
        owner: 'Construction Manager',
        mitigation: 'Tented pour area + 7-day weather lookahead review',
        status: RiskStatus.mitigated,
      ),
      const RiskItem(
        id: 'rsk_003',
        description: 'Permit approval timeline may exceed 8 weeks',
        probability: 2,
        impact: 3,
        owner: 'Project Manager',
        mitigation: 'Pre-application meeting scheduled; third-party expediter on standby',
        status: RiskStatus.open,
      ),
      const RiskItem(
        id: 'iss_001',
        description: 'Survey crew encountered undocumented underground utility',
        probability: 5,
        impact: 4,
        owner: 'Site Engineer',
        mitigation: 'Utility re-route in progress; coordination with city utilities office',
        status: RiskStatus.realized,
        isIssue: true,
      ),
      const RiskItem(
        id: 'iss_002',
        description: 'QA inspector shortage delaying inspection sign-offs',
        probability: 4,
        impact: 3,
        owner: 'QA Lead',
        mitigation: 'Subcontracted third-party inspector onboarded',
        status: RiskStatus.open,
        isIssue: true,
      ),
    ];

    // ─── Resource allocations (12 weeks) ────────────────────────────────
    List<double> buildWeekly(double base, List<double> adj) {
      final out = <double>[];
      for (var i = 0; i < 12; i++) {
        out.add(base + (i < adj.length ? adj[i] : 0));
      }
      return out;
    }

    final resourceAllocations = [
      ResourceAllocation(
        resourceName: 'A. Khan (PM)',
        discipline: ResourceDiscipline.pm,
        weeklyHours: buildWeekly(40, [0, 0, 5, 5, 5, 10, 10, 10, 5, 0, 0, 0]),
        capacityHoursPerWeek: 40,
      ),
      ResourceAllocation(
        resourceName: 'M. Garcia (Eng)',
        discipline: ResourceDiscipline.engineering,
        weeklyHours: buildWeekly(35, [10, 10, 10, 5, 0, 0, 0, 0, 5, 10, 5, 0]),
        capacityHoursPerWeek: 40,
      ),
      ResourceAllocation(
        resourceName: 'L. Chen (Design)',
        discipline: ResourceDiscipline.design,
        weeklyHours: buildWeekly(30, [15, 15, 10, 5, 0, 0, 0, 5, 10, 5, 0, 0]),
        capacityHoursPerWeek: 40,
      ),
      ResourceAllocation(
        resourceName: 'R. Patel (QA)',
        discipline: ResourceDiscipline.qa,
        weeklyHours: buildWeekly(20, [0, 0, 5, 10, 15, 20, 20, 15, 10, 5, 0, 0]),
        capacityHoursPerWeek: 40,
      ),
      ResourceAllocation(
        resourceName: 'Site Crew (Constr.)',
        discipline: ResourceDiscipline.construction,
        weeklyHours: buildWeekly(120,
            [40, 80, 120, 160, 200, 200, 200, 160, 120, 80, 40, 0]),
        capacityHoursPerWeek: 200,
      ),
    ];

    // ─── Reports (history) ──────────────────────────────────────────────
    final reports = [
      ReportRecord(
        id: 'rpt_seed_001',
        type: ReportType.costVariance,
        generatedAt: DateTime(2026, 6, 1),
        dateRangeStart: DateTime(2026, 1, 1),
        dateRangeEnd: DateTime(2026, 5, 31),
        generatedBy: 'jane.doe@ndu.project',
        summaryText:
            'Cost Variance Report (Jan–May 2026)\nCPI: 0.97 • CV: -\$0.21M • EAC: \$16.4M',
      ),
      ReportRecord(
        id: 'rpt_seed_002',
        type: ReportType.evmForecast,
        generatedAt: DateTime(2026, 6, 8),
        dateRangeStart: DateTime(2026, 1, 1),
        dateRangeEnd: DateTime(2026, 6, 7),
        generatedBy: 'you@ndu.project',
        summaryText:
            'EVM Forecast Report (Jan–Jun 2026)\nEAC: \$16.55M • VAC: -\$0.35M • Avg progress: 38%',
      ),
      ReportRecord(
        id: 'rpt_seed_003',
        type: ReportType.riskBurnDown,
        generatedAt: DateTime(2026, 6, 15),
        dateRangeStart: DateTime(2026, 1, 1),
        dateRangeEnd: DateTime(2026, 6, 14),
        generatedBy: 'jane.doe@ndu.project',
        summaryText:
            'Risk Burn-down Report (Jan–Jun 2026)\nOpen risks: 2 • Critical: 1 • Realized issues: 1',
      ),
    ];

    // ─── Audit trail (initial entries) ──────────────────────────────────
    final auditTrail = [
      AuditEntry(
        id: 'audit_seed_001',
        user: 'jane.doe@ndu.project',
        timestamp: DateTime(2026, 1, 5, 9, 30),
        field: 'baseline.scope',
        previousValue: '—',
        newValue: 'v1',
        reason: 'Initial project baseline at kickoff',
      ),
      AuditEntry(
        id: 'audit_seed_002',
        user: 'jane.doe@ndu.project',
        timestamp: DateTime(2026, 3, 1, 14, 12),
        field: 'baseline.scope',
        previousValue: 'v1',
        newValue: 'v2',
        reason: 'Added Structural Steel work package after design review',
      ),
      AuditEntry(
        id: 'audit_seed_003',
        user: 'john.smith@ndu.project',
        timestamp: DateTime(2026, 6, 18, 10, 5),
        field: 'changeRequest',
        previousValue: '—',
        newValue: 'cr_001',
        reason: 'Change request submitted: Add fire suppression system',
      ),
    ];

    _state = _state.copyWith(
      deliveryModel: model,
      isBaselined: true,
      isExecutionActive: true,
      workPackages: wps,
      changeRequests: [demoCR],
      baselineHistory: [baselineV1, baselineV2],
      scheduleVariances: scheduleVariances,
      risksAndIssues: risksAndIssues,
      resourceAllocations: resourceAllocations,
      reports: reports,
      auditTrail: auditTrail,
    );
    notifyListeners();
    _saveToStorage();
  }
}
