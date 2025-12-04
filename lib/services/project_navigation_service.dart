import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to track and restore the last visited page for each project.
/// This allows users to resume where they left off when reopening a project.
class ProjectNavigationService {
  ProjectNavigationService._();
  static final ProjectNavigationService instance = ProjectNavigationService._();

  static const String _keyPrefix = 'project_last_page_';

  /// Save the last visited route for a project
  Future<void> saveLastPage(String projectId, String routeName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$projectId', routeName);
      if (kDebugMode) {
        debugPrint('ProjectNavigationService: Saved last page for $projectId -> $routeName');
      }
    } catch (e) {
      debugPrint('ProjectNavigationService: Error saving last page: $e');
    }
  }

  /// Get the last visited route for a project
  /// Returns 'initiation' as default if no previous route is saved
  Future<String> getLastPage(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPage = prefs.getString('$_keyPrefix$projectId');
      if (kDebugMode) {
        debugPrint('ProjectNavigationService: Retrieved last page for $projectId -> ${lastPage ?? 'initiation (default)'}');
      }
      return lastPage ?? 'initiation';
    } catch (e) {
      debugPrint('ProjectNavigationService: Error getting last page: $e');
      return 'initiation';
    }
  }

  /// Clear the saved page for a project (useful when deleting a project)
  Future<void> clearLastPage(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$projectId');
      if (kDebugMode) {
        debugPrint('ProjectNavigationService: Cleared last page for $projectId');
      }
    } catch (e) {
      debugPrint('ProjectNavigationService: Error clearing last page: $e');
    }
  }
}
