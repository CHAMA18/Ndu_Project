import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';

class ExecutionPhaseService {
  static final _firestore = FirebaseFirestore.instance;
  static const _collection = 'execution_phase_entries';

  static Future<void> savePageData({
    required String pageKey,
    required Map<String, List<LaunchEntry>> sections,
    String? userId,
  }) async {
    try {
      await _firestore.collection(_collection).add({
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
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ExecutionPhaseService save error: $e');
      rethrow;
    }
  }
}
