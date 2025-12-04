import 'package:flutter/material.dart';
import 'package:ndu_project/models/app_content_model.dart';
import 'package:ndu_project/services/app_content_service.dart';

/// Provider to manage editable app content across the application
class AppContentProvider extends ChangeNotifier {
  final Map<String, String> _contentCache = {};
  bool _isLoading = false;
  String? _error;
  bool _isEditMode = false;
  Offset _editButtonPosition = const Offset(16, 170);
  bool _showEditButton = true; // false = button visible, true = button hidden (default: hidden)
  bool _isWatching = false; // Prevent multiple stream subscriptions

  Map<String, String> get contentCache => Map.unmodifiable(_contentCache);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEditMode => _isEditMode;
  Offset get editButtonPosition => _editButtonPosition;
  bool get showEditButton => _showEditButton;

  /// Toggle edit mode (admin only)
  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  /// Set edit mode explicitly
  void setEditMode(bool enabled) {
    if (_isEditMode != enabled) {
      _isEditMode = enabled;
      notifyListeners();
    }
  }

  /// Update edit button position (only notifies when drag ends)
  void updateEditButtonPosition(Offset position) {
    _editButtonPosition = position;
    notifyListeners();
  }

  /// Toggle edit button visibility
  void toggleEditButtonVisibility() {
    _showEditButton = !_showEditButton;
    notifyListeners();
  }

  /// Set edit button visibility explicitly
  void setEditButtonVisibility(bool visible) {
    if (_showEditButton != visible) {
      _showEditButton = visible;
      notifyListeners();
    }
  }

  /// Get content value by key with optional fallback
  String getContent(String key, {String fallback = ''}) => _contentCache[key] ?? fallback;

  /// Load all content from Firestore
  Future<void> loadContent() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final content = await AppContentService.getAllContent();
      _contentCache.clear();
      for (final item in content) {
        _contentCache[item.key] = item.value;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Watch content for real-time updates
  void watchContent() {
    if (_isWatching) return; // Prevent multiple subscriptions
    _isWatching = true;
    
    AppContentService.watchContent().listen(
      (content) {
        bool hasChanges = false;
        final newCache = <String, String>{};
        
        for (final item in content) {
          newCache[item.key] = item.value;
          if (_contentCache[item.key] != item.value) {
            hasChanges = true;
          }
        }
        
        // Only notify if content actually changed
        if (hasChanges || _contentCache.length != newCache.length) {
          _contentCache.clear();
          _contentCache.addAll(newCache);
          notifyListeners();
        }
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  /// Update a specific content value
  Future<bool> updateContent(String id, AppContent content) async {
    try {
      final success = await AppContentService.updateContent(id, content);
      if (success) {
        _contentCache[content.key] = content.value;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Add new content
  Future<String?> addContent(AppContent content) async {
    try {
      final id = await AppContentService.addContent(content);
      if (id != null) {
        _contentCache[content.key] = content.value;
        notifyListeners();
      }
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Delete content
  Future<bool> deleteContent(String id, String key) async {
    try {
      final success = await AppContentService.deleteContent(id);
      if (success) {
        _contentCache.remove(key);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
