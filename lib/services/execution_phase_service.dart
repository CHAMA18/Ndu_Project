import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';

class ExecutionPhaseService {
  static final _firestore = FirebaseFirestore.instance;

  /// Save execution phase page data to project subcollection
  static Future<void> savePageData({
    required String projectId,
    required String pageKey,
    required Map<String, List<LaunchEntry>> sections,
    String? userId,
  }) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_entries')
          .doc(pageKey)
          .set({
        'page': pageKey,
        'sections': sections.map(
          (key, value) => MapEntry(
            key,
            value
                .map((e) => {
                      'title': e.title,
                      'details': e.details,
                      'status': e.status,
                    })
                .toList(),
          ),
        ),
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Use merge to allow updates
    } catch (e) {
      debugPrint('ExecutionPhaseService save error: $e');
      rethrow;
    }
  }

  /// Load execution phase page data from project subcollection
  static Future<Map<String, List<LaunchEntry>>?> loadPageData({
    required String projectId,
    required String pageKey,
  }) async {
    try {
      final doc = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_entries')
          .doc(pageKey)
          .get();

      if (!doc.exists) return null;

      final data = doc.data() ?? {};
      final sections = <String, List<LaunchEntry>>{};

      final sectionsData = data['sections'];
      if (sectionsData is Map) {
        sectionsData.forEach((key, value) {
          if (value is List) {
            sections[key.toString()] = value
                .map((e) {
                  if (e is Map) {
                    return LaunchEntry(
                      title: e['title']?.toString() ?? '',
                      details: e['details']?.toString() ?? '',
                      status: e['status']?.toString() ?? '',
                    );
                  }
                  return LaunchEntry(title: '', details: '', status: '');
                })
                .toList();
          }
        });
      }

      return sections.isEmpty ? null : sections;
    } catch (e) {
      debugPrint('ExecutionPhaseService load error: $e');
      return null;
    }
  }
}
