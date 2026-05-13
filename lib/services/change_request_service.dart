import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ApprovalStep {
  final int stepNumber;
  final String approverRole;
  final String? approverName;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime? approvedAt;
  final String? comments;

  const ApprovalStep({
    required this.stepNumber,
    required this.approverRole,
    this.approverName,
    this.status = 'pending',
    this.approvedAt,
    this.comments,
  });

  ApprovalStep copyWith({
    String? approverName,
    String? status,
    DateTime? approvedAt,
    String? comments,
  }) {
    return ApprovalStep(
      stepNumber: stepNumber,
      approverRole: approverRole,
      approverName: approverName ?? this.approverName,
      status: status ?? this.status,
      approvedAt: approvedAt ?? this.approvedAt,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'approverRole': approverRole,
        'approverName': approverName,
        'status': status,
        'approvedAt': approvedAt?.toIso8601String(),
        'comments': comments,
      };

  factory ApprovalStep.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return ApprovalStep(
      stepNumber: json['stepNumber'] as int? ?? 0,
      approverRole: json['approverRole']?.toString() ?? '',
      approverName: json['approverName']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      approvedAt: parseDate(json['approvedAt']),
      comments: json['comments']?.toString(),
    );
  }
}

class ChangeRequest {
  final String id;
  final String displayId;
  final String title;
  final String type;
  final String impact;
  final String status;
  final String requester;
  final String? projectId;
  final String? description;
  final String? justification;
  final String? attachmentUrl;
  final String? attachmentName;
  final DateTime requestDate;
  final DateTime createdAt;

  // Structured impact analysis
  final String? scopeChange;
  final int? scheduleDelay;
  final double? costChange;
  final String? riskExposure;
  final String? contractImpact;
  final String? agileImpact;

  // Multi-level approval
  final List<ApprovalStep> approvalSteps;

  ChangeRequest({
    required this.id,
    required this.displayId,
    required this.title,
    required this.type,
    required this.impact,
    required this.status,
    required this.requester,
    required this.requestDate,
    required this.createdAt,
    this.projectId,
    this.description,
    this.justification,
    this.attachmentUrl,
    this.attachmentName,
    this.scopeChange,
    this.scheduleDelay,
    this.costChange,
    this.riskExposure,
    this.contractImpact,
    this.agileImpact,
    List<ApprovalStep>? approvalSteps,
  }) : approvalSteps = approvalSteps ?? [];

  ChangeRequest copyWith({
    String? title,
    String? type,
    String? impact,
    String? status,
    String? description,
    String? justification,
    String? attachmentUrl,
    String? attachmentName,
    String? scopeChange,
    int? scheduleDelay,
    double? costChange,
    String? riskExposure,
    String? contractImpact,
    String? agileImpact,
    List<ApprovalStep>? approvalSteps,
  }) {
    return ChangeRequest(
      id: id,
      displayId: displayId,
      title: title ?? this.title,
      type: type ?? this.type,
      impact: impact ?? this.impact,
      status: status ?? this.status,
      requester: requester,
      requestDate: requestDate,
      createdAt: createdAt,
      projectId: projectId,
      description: description ?? this.description,
      justification: justification ?? this.justification,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      scopeChange: scopeChange ?? this.scopeChange,
      scheduleDelay: scheduleDelay ?? this.scheduleDelay,
      costChange: costChange ?? this.costChange,
      riskExposure: riskExposure ?? this.riskExposure,
      contractImpact: contractImpact ?? this.contractImpact,
      agileImpact: agileImpact ?? this.agileImpact,
      approvalSteps: approvalSteps ?? List.from(this.approvalSteps),
    );
  }

  static ChangeRequest fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime parseDate(dynamic value, {required String fieldName}) {
      try {
        if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
        if (value is Timestamp) return value.toDate();
        if (value is DateTime) return value;
        if (value is String) {
          final parsed = DateTime.tryParse(value);
          if (parsed != null) return parsed;
        }
        if (value is int) {
          if (value > 100000000000) {
            return DateTime.fromMillisecondsSinceEpoch(value);
          }
          return DateTime.fromMillisecondsSinceEpoch(value * 1000);
        }
        if (value is Map) {
          final seconds = value['seconds'] ?? value['_seconds'];
          final nanos = value['nanoseconds'] ?? value['_nanoseconds'] ?? 0;
          final intSec = seconds is int
              ? seconds
              : (seconds is double
                  ? seconds.toInt()
                  : (seconds is num ? seconds.toInt() : 0));
          final intNanos = nanos is int
              ? nanos
              : (nanos is double
                  ? nanos.toInt()
                  : (nanos is num ? nanos.toInt() : 0));
          if (intSec != 0 || intNanos != 0) {
            return DateTime.fromMillisecondsSinceEpoch(
                intSec * 1000 + (intNanos ~/ 1000000));
          }
        }
      } catch (e, st) {
        debugPrint('ChangeRequest parse error for field "$fieldName": $e\n$st');
      }
      debugPrint(
          'ChangeRequest warning: Unrecognized date value for "$fieldName" -> $value (type: ${value.runtimeType}), defaulting to now');
      return DateTime.now();
    }

    final requestDate =
        parseDate(data['requestDate'], fieldName: 'requestDate');
    final createdAt = parseDate(data['createdAt'], fieldName: 'createdAt');

    List<ApprovalStep> parseApprovalSteps(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((m) => ApprovalStep.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return ChangeRequest(
      id: doc.id,
      displayId: data['displayId'] as String? ??
          'CR-${doc.id.substring(0, 6).toUpperCase()}',
      title: data['title'] as String? ?? '',
      type: data['type'] as String? ?? '',
      impact: data['impact'] as String? ?? '',
      status: data['status'] as String? ?? 'Pending',
      requester: data['requester'] as String? ?? '',
      projectId: data['projectId'] as String?,
      description: data['description'] as String?,
      justification: data['justification'] as String?,
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentName: data['attachmentName'] as String?,
      requestDate: requestDate,
      createdAt: createdAt,
      scopeChange: data['scopeChange']?.toString(),
      scheduleDelay: data['scheduleDelay'] is int
          ? data['scheduleDelay'] as int
          : (data['scheduleDelay'] is num
              ? (data['scheduleDelay'] as num).toInt()
              : null),
      costChange: data['costChange'] is num
          ? (data['costChange'] as num).toDouble()
          : null,
      riskExposure: data['riskExposure']?.toString(),
      contractImpact: data['contractImpact']?.toString(),
      agileImpact: data['agileImpact']?.toString(),
      approvalSteps: parseApprovalSteps(data['approvalSteps']),
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'displayId': displayId,
      'title': title,
      'type': type,
      'impact': impact,
      'status': status,
      'requester': requester,
      'projectId': projectId,
      'description': description,
      'justification': justification,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'requestDate': Timestamp.fromDate(requestDate),
      'createdAt': FieldValue.serverTimestamp(),
      'scopeChange': scopeChange,
      'scheduleDelay': scheduleDelay,
      'costChange': costChange,
      'riskExposure': riskExposure,
      'contractImpact': contractImpact,
      'agileImpact': agileImpact,
      'approvalSteps':
          approvalSteps.map((s) => s.toJson()).toList(),
    };
  }
}

class ChangeRequestService {
  static CollectionReference<Map<String, dynamic>>? _tryCollection() {
    try {
      return FirebaseFirestore.instance.collection('change_requests');
    } catch (e, st) {
      debugPrint('ChangeRequestService: Firestore not ready ($e)\n$st');
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

  static Future<String> _generateDisplayId(String? projectId) async {
    Query query = _requireCollection();
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    final snapshot = await query.count().get();
    final next = (snapshot.count ?? 0) + 1;
    String pad(int n) => n.toString().padLeft(3, '0');
    return 'CR-${pad(next)}';
  }

  static Future<String> createChangeRequest({
    required String title,
    required String type,
    required String impact,
    required String status,
    required String requester,
    required DateTime requestDate,
    String? projectId,
    String? description,
    String? justification,
    String? attachmentUrl,
    String? attachmentName,
    String? scopeChange,
    int? scheduleDelay,
    double? costChange,
    String? riskExposure,
    String? contractImpact,
    String? agileImpact,
    List<ApprovalStep>? approvalSteps,
  }) async {
    final displayId = await _generateDisplayId(projectId);
    final data = {
      'displayId': displayId,
      'title': title,
      'type': type,
      'impact': impact,
      'status': status,
      'requester': requester,
      'projectId': projectId,
      'description': description,
      'justification': justification,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'requestDate': Timestamp.fromDate(requestDate),
      'createdAt': FieldValue.serverTimestamp(),
      'scopeChange': scopeChange,
      'scheduleDelay': scheduleDelay,
      'costChange': costChange,
      'riskExposure': riskExposure,
      'contractImpact': contractImpact,
      'agileImpact': agileImpact,
      'approvalSteps':
          (approvalSteps ?? []).map((s) => s.toJson()).toList(),
    };
    final ref = await _requireCollection().add(data);
    return ref.id;
  }

  static Stream<List<ChangeRequest>> streamChangeRequests(
      {String? projectId}) {
    final col = _tryCollection();
    if (col == null) {
      return Stream<List<ChangeRequest>>.value(const []);
    }
    try {
      Query<Map<String, dynamic>> query = col;
      if (projectId != null && projectId.isNotEmpty) {
        query = query.where('projectId', isEqualTo: projectId);
      }

      return query.snapshots().map((s) {
        final list =
            s.docs.map((d) => ChangeRequest.fromDoc(d)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } catch (e, st) {
      debugPrint('ChangeRequestService: stream failure ($e)\n$st');
      return Stream<List<ChangeRequest>>.value(const []);
    }
  }

  static Future<void> updateChangeRequest(ChangeRequest request) async {
    try {
      await _requireCollection().doc(request.id).update({
        'title': request.title,
        'type': request.type,
        'impact': request.impact,
        'status': request.status,
        'requester': request.requester,
        'description': request.description,
        'justification': request.justification,
        'attachmentUrl': request.attachmentUrl,
        'attachmentName': request.attachmentName,
        'requestDate': Timestamp.fromDate(request.requestDate),
        'scopeChange': request.scopeChange,
        'scheduleDelay': request.scheduleDelay,
        'costChange': request.costChange,
        'riskExposure': request.riskExposure,
        'contractImpact': request.contractImpact,
        'agileImpact': request.agileImpact,
        'approvalSteps':
            request.approvalSteps.map((s) => s.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Failed to update change request (${request.id}): $e');
      rethrow;
    }
  }

  static Future<void> deleteChangeRequest(String id) async {
    try {
      await _requireCollection().doc(id).delete();
    } catch (e) {
      debugPrint('Failed to delete change request ($id): $e');
    }
  }

  /// Approve a specific approval step and auto-update the overall CR status.
  static Future<void> approveStep({
    required ChangeRequest request,
    required int stepNumber,
    required String approverName,
    String? comments,
  }) async {
    final updatedSteps = request.approvalSteps.map((step) {
      if (step.stepNumber == stepNumber) {
        return step.copyWith(
          approverName: approverName,
          status: 'approved',
          approvedAt: DateTime.now(),
          comments: comments,
        );
      }
      return step;
    }).toList();

    final allApproved = updatedSteps.every((s) => s.status == 'approved');
    final anyRejected = updatedSteps.any((s) => s.status == 'rejected');
    final newStatus = allApproved
        ? 'Approved'
        : anyRejected
            ? 'Rejected'
            : 'Pending';

    final updated = request.copyWith(
      status: newStatus,
      approvalSteps: updatedSteps,
    );
    await updateChangeRequest(updated);
  }

  /// Reject a specific approval step.
  static Future<void> rejectStep({
    required ChangeRequest request,
    required int stepNumber,
    required String approverName,
    String? comments,
  }) async {
    final updatedSteps = request.approvalSteps.map((step) {
      if (step.stepNumber == stepNumber) {
        return step.copyWith(
          approverName: approverName,
          status: 'rejected',
          approvedAt: DateTime.now(),
          comments: comments,
        );
      }
      return step;
    }).toList();

    final updated = request.copyWith(
      status: 'Rejected',
      approvalSteps: updatedSteps,
    );
    await updateChangeRequest(updated);
  }
}
