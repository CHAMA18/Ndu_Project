/// WBS — ChangeNotifier-based state management (Dart equivalent)
///
/// Mirrors the Zustand store in the Next.js module.
/// Persists to SharedPreferences as JSON.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ndu_project/wbs/models/wbs_models.dart';
import 'package:ndu_project/wbs/models/wbs_templates.dart';

const String _storageKey = 'ndu_wbs_v1';

class WBSProvider extends ChangeNotifier {
  WBS? _wbs;
  bool _setupComplete = false;

  WBS? get wbs => _wbs;
  bool get setupComplete => _setupComplete;

  WBSProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final state = data['state'] as Map<String, dynamic>? ?? {};
        _setupComplete = state['setupComplete'] as bool? ?? false;
        if (state['wbs'] != null) {
          _wbs = _wbsFromJson(state['wbs'] as Map<String, dynamic>);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading WBS: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'state': {
          'wbs': _wbs != null ? _wbsToJson(_wbs!) : null,
          'setupComplete': _setupComplete,
        },
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving WBS: $e');
    }
  }

  WBS _wbsFromJson(Map<String, dynamic> json) {
    return WBS(
      id: json['id'] as String,
      projectId: json['projectId'] as String? ?? 'default',
      projectName: json['projectName'] as String,
      framework: WBSFramework.values
          .byName(json['framework'] as String? ?? 'waterfallDeliverable'),
      level0: _nodeFromJson(json['level0'] as Map<String, dynamic>),
      aiSuggestions: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  WBSNode _nodeFromJson(Map<String, dynamic> json) {
    return WBSNode(
      id: json['id'] as String,
      level: WBSLevel.values.byName(json['level'] as String? ?? 'level0'),
      code: json['code'] as String? ?? '0',
      name: json['name'] as String,
      description: json['description'] as String?,
      aiGenerated: json['aiGenerated'] as bool? ?? false,
      children: (json['children'] as List<dynamic>? ?? [])
          .map((c) => _nodeFromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> _wbsToJson(WBS wbs) => {
        'id': wbs.id,
        'projectId': wbs.projectId,
        'projectName': wbs.projectName,
        'framework': wbs.framework.name,
        'level0': _nodeToJson(wbs.level0),
      };

  Map<String, dynamic> _nodeToJson(WBSNode node) => {
        'id': node.id,
        'level': node.level.name,
        'code': node.code,
        'name': node.name,
        'description': node.description,
        'aiGenerated': node.aiGenerated,
        'children': node.children.map(_nodeToJson).toList(),
      };

  // ---- Setup ----

  void setup({
    required String projectName,
    required WBSFramework framework,
  }) {
    _wbs = createEmptyWBS(
      projectId: 'default',
      projectName: projectName,
      framework: framework,
    );
    _setupComplete = true;
    notifyListeners();
    _saveToStorage();
  }

  void resetWBS() {
    _wbs = null;
    _setupComplete = false;
    notifyListeners();
    _saveToStorage();
  }

  // ---- Node operations ----

  String addLevel1Node(String name, [String? description]) {
    if (_wbs == null) return '';
    final id = newWBSId('node');
    final newNode = WBSNode(
      id: id,
      level: WBSLevel.level1,
      code: '${_wbs!.level0.children.length + 1}',
      name: name,
      description: description,
      aiGenerated: false,
      isWorkPackage: _wbs!.framework != WBSFramework.agile,
      children: [],
    );
    final updatedLevel0 = recalcCodes(_wbs!.level0.copyWith(
      children: [..._wbs!.level0.children, newNode],
    ));
    _wbs = _wbs!.copyWith(
      level0: updatedLevel0,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    _saveToStorage();
    return id;
  }

  String addLevel2Node(String parentId, String name, [String? description]) {
    if (_wbs == null) return '';
    final id = newWBSId('node');
    final newNode = WBSNode(
      id: id,
      level: WBSLevel.level2,
      code: '',
      name: name,
      description: description,
      aiGenerated: false,
      isWorkPackage: _wbs!.framework != WBSFramework.agile,
      estimationMethod: _wbs!.framework == WBSFramework.agile
          ? EstimationMethod.storyPoints
          : null,
      children: [],
    );
    final updatedLevel0 = recalcCodes(_findAndUpdateNode(
        _wbs!.level0, parentId, (n) => n.copyWith(children: [...n.children, newNode])));
    _wbs = _wbs!.copyWith(
      level0: updatedLevel0,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    _saveToStorage();
    return id;
  }

  void addNodeFromTemplate(TemplateNode template) {
    final l1Id = addLevel1Node(template.name, template.description);
    for (final child in template.children) {
      addLevel2Node(l1Id, child.name, child.description);
    }
  }

  void updateNode(String id, WBSNode patch) {
    if (_wbs == null) return;
    final updatedLevel0 = recalcCodes(
        _findAndUpdateNode(_wbs!.level0, id, (n) => _mergeNode(n, patch)));
    _wbs = _wbs!.copyWith(
      level0: updatedLevel0,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    _saveToStorage();
  }

  WBSNode _mergeNode(WBSNode original, WBSNode patch) {
    return original.copyWith(
      name: patch.name,
      description: patch.description,
      estimationMethod: patch.estimationMethod,
      isWorkPackage: patch.isWorkPackage,
      aiGenerated: patch.aiGenerated,
      aiSource: patch.aiSource,
      aiConfidence: patch.aiConfidence,
      aiReference: patch.aiReference,
    );
  }

  void removeNode(String id) {
    if (_wbs == null) return;
    if (_wbs!.level0.id == id) return; // Can't remove Level 0
    final updatedLevel0 = recalcCodes(_findAndRemoveNode(_wbs!.level0, id));
    _wbs = _wbs!.copyWith(
      level0: updatedLevel0,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    _saveToStorage();
  }

  void moveNode(String id, bool directionUp) {
    if (_wbs == null) return;
    final updatedLevel0 = recalcCodes(_swapNode(_wbs!.level0, id, directionUp));
    _wbs = _wbs!.copyWith(
      level0: updatedLevel0,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    _saveToStorage();
  }

  void linkCostLine(String nodeId, String costLineId) {
    if (_wbs == null) return;
    final updatedLevel0 = _findAndUpdateNode(_wbs!.level0, nodeId, (n) {
      final ids = [...(n.costLineIds ?? []), costLineId];
      return n.copyWith(costLineIds: ids);
    });
    _wbs = _wbs!.copyWith(
      level0: updatedLevel0,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    _saveToStorage();
  }

  void unlinkCostLine(String nodeId, String costLineId) {
    if (_wbs == null) return;
    final updatedLevel0 = _findAndUpdateNode(_wbs!.level0, nodeId, (n) {
      final ids = (n.costLineIds ?? []).where((id) => id != costLineId).toList();
      return n.copyWith(costLineIds: ids);
    });
    _wbs = _wbs!.copyWith(
      level0: updatedLevel0,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    _saveToStorage();
  }

  // ---- Tree helpers ----

  WBSNode _findAndUpdateNode(
      WBSNode root, String id, WBSNode Function(WBSNode) updater) {
    if (root.id == id) return updater(root);
    return root.copyWith(
      children: root.children
          .map((c) => _findAndUpdateNode(c, id, updater))
          .toList(),
    );
  }

  WBSNode _findAndRemoveNode(WBSNode root, String id) {
    return root.copyWith(
      children: root.children
          .where((c) => c.id != id)
          .map((c) => _findAndRemoveNode(c, id))
          .toList(),
    );
  }

  WBSNode _swapNode(WBSNode root, String id, bool directionUp) {
    List<WBSNode> swap(List<WBSNode> arr) {
      final idx = arr.indexWhere((n) => n.id == id);
      if (idx >= 0) {
        if (directionUp && idx > 0) {
          final newArr = List<WBSNode>.from(arr);
          final temp = newArr[idx - 1];
          newArr[idx - 1] = newArr[idx];
          newArr[idx] = temp;
          return newArr;
        }
        if (!directionUp && idx < arr.length - 1) {
          final newArr = List<WBSNode>.from(arr);
          final temp = newArr[idx];
          newArr[idx] = newArr[idx + 1];
          newArr[idx + 1] = temp;
          return newArr;
        }
        return arr;
      }
      return arr.map((n) => n.copyWith(children: swap(n.children))).toList();
    }

    // Check if the id is in the root's children
    final idx = root.children.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      return root.copyWith(children: swap(root.children));
    }
    // Otherwise recurse
    return root.copyWith(
      children: root.children
          .map((c) => _swapNode(c, id, directionUp))
          .toList(),
    );
  }

  WBSNode? findNode(String id) {
    WBSNode? find(WBSNode node) {
      if (node.id == id) return node;
      for (final c in node.children) {
        final found = find(c);
        if (found != null) return found;
      }
      return null;
    }
    return _wbs == null ? null : find(_wbs!.level0);
  }
}
