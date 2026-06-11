import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndu_project/models/project_log_model.dart';

class ProjectLogService {
  ProjectLogService._();
  static final ProjectLogService instance = ProjectLogService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Stream all log entries for a given project.
  static Stream<List<ProjectLogEntry>> streamEntries({required String projectId}) {
    return _db
        .collection('project_logs')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProjectLogEntry.fromFirestore(doc))
            .toList());
  }

  /// Stream all log entries for the current user across all their projects.
  static Stream<List<ProjectLogEntry>> streamAllForUser({required String userId}) {
    return _db
        .collection('project_logs')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProjectLogEntry.fromFirestore(doc))
            .toList());
  }

  /// Add a new log entry.
  static Future<String> addEntry(ProjectLogEntry entry) async {
    final docRef = await _db.collection('project_logs').add(entry.toFirestore());
    return docRef.id;
  }

  /// Update an existing log entry.
  static Future<void> updateEntry(String entryId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('project_logs').doc(entryId).update(updates);
  }

  /// Delete a log entry.
  static Future<void> deleteEntry(String entryId) async {
    await _db.collection('project_logs').doc(entryId).delete();
  }

  /// Mark a task as complete.
  static Future<void> markComplete(String entryId) async {
    await updateEntry(entryId, {'status': 'Completed'});
  }
}
