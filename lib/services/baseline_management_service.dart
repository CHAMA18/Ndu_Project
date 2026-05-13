import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ndu_project/models/baseline_version_model.dart';
import 'package:ndu_project/models/project_data_model.dart';

class BaselineManagementService {
  static CollectionReference<Map<String, dynamic>>? _tryCollection() {
    try {
      return FirebaseFirestore.instance.collection('project_baselines');
    } catch (e, st) {
      debugPrint('BaselineManagementService: Firestore not ready ($e)\n$st');
      return null;
    }
  }

  static CollectionReference<Map<String, dynamic>> _requireCollection() {
    final col = _tryCollection();
    if (col == null) {
      throw StateError('Firestore is not initialized');
    }
    return col;
  }

  /// Create a baseline snapshot from the current project data.
  static Future<String> createBaseline({
    required String projectId,
    required String author,
    required String label,
    String description = '',
    String triggerSource = 'manual',
    String approvedBy = '',
  }) async {
    // For now we store just the BaselineVersion metadata.
    // Full point-in-time data is captured by the project's snapshot in Firestore.
    final existingVersions = await _requireCollection()
        .where('projectId', isEqualTo: projectId)
        .get();
    final versionNumber = existingVersions.size + 1;

    final baseline = BaselineVersion(
      versionNumber: versionNumber,
      label: label,
      description: description,
      author: author,
      approvedBy: approvedBy,
      triggerSource: triggerSource,
    );

    await _requireCollection().doc(projectId).collection('versions').add({
      ...baseline.toJson(),
      'projectId': projectId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return baseline.id;
  }

  /// Retrieve all baselines for a project, ordered by creation date descending.
  static Stream<List<BaselineVersion>> streamBaselines(String projectId) {
    final col = _tryCollection();
    if (col == null) {
      return Stream.value([]);
    }
    return col
        .doc(projectId)
        .collection('versions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return BaselineVersion.fromJson(data);
          })
          .toList();
    });
  }

  /// Compute schedule variance between current and baseline.
  static double computeScheduleVarianceDays({
    required List<ScheduleActivity> currentActivities,
    required List<ScheduleActivity> baselineActivities,
  }) {
    double totalVariance = 0;
    int count = 0;

    for (final current in currentActivities) {
      final baseline = baselineActivities.where((b) => b.id == current.id).firstOrNull;
      if (baseline == null) continue;
      if (current.dueDate.isEmpty || baseline.dueDate.isEmpty) continue;

      final currentDate = DateTime.tryParse(current.dueDate);
      final baselineDate = DateTime.tryParse(baseline.dueDate);
      if (currentDate == null || baselineDate == null) continue;

      totalVariance += currentDate.difference(baselineDate).inDays;
      count++;
    }

    return count > 0 ? totalVariance / count : 0;
  }

  /// Compute cost variance between current and baseline.
  static double computeCostVariance({
    required List<WorkPackage> currentPackages,
    required List<WorkPackage> baselinePackages,
  }) {
    final currentTotal =
        currentPackages.fold<double>(0, (s, wp) => s + wp.budgetedCost);
    final baselineTotal =
        baselinePackages.fold<double>(0, (s, wp) => s + wp.budgetedCost);
    return currentTotal - baselineTotal;
  }

  /// Build a snapshot summary and persist it as a new baseline version.
  static Future<String> captureSnapshot({
    required String projectId,
    required String author,
    required ProjectDataModel projectData,
    String label = '',
    String description = '',
    String triggerSource = 'manual',
    String approvedBy = '',
  }) async {
    final existingVersions = await _requireCollection()
        .doc(projectId)
        .collection('versions')
        .get();
    final versionNumber = existingVersions.size + 1;

    final svDays = computeScheduleVarianceDays(
      currentActivities: projectData.scheduleActivities,
      baselineActivities: projectData.scheduleBaselineActivities,
    );

    final costVar = computeCostVariance(
      currentPackages: projectData.workPackages,
      baselinePackages: [], // Empty baseline list — first baseline has no prior
    );

    final totalWps = projectData.workPackages.length;
    final totalActs = projectData.scheduleActivities.length;
    final completedActs = projectData.scheduleActivities
        .where((a) => a.status == 'complete')
        .length;

    final baseline = BaselineVersion(
      versionNumber: versionNumber,
      label: label.isNotEmpty ? label : 'Baseline v$versionNumber',
      description: description,
      author: author,
      approvedBy: approvedBy,
      triggerSource: triggerSource,
      scheduleVarianceDays: svDays,
      costVariance: costVar,
      budgetAtCompletion:
          projectData.workPackages.fold<double>(0, (s, wp) => s + wp.budgetedCost),
      totalActivities: totalActs,
      completedActivities: completedActs,
      totalWorkPackages: totalWps,
    );

    await _requireCollection().doc(projectId).collection('versions').add({
      ...baseline.toJson(),
      'projectId': projectId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return baseline.id;
  }
}
