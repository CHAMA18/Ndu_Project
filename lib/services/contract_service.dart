import 'package:cloud_firestore/cloud_firestore.dart';

String _normalizeStatusForStorage(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) return 'draft';
  switch (normalized) {
    case 'draft':
    case 'under_review':
    case 'approved':
    case 'executed':
    case 'expired':
    case 'terminated':
      return normalized;
  }
  if (normalized.contains('not started')) return 'draft';
  if (normalized.contains('pending')) return 'under_review';
  if (normalized.contains('review')) return 'under_review';
  if (normalized.contains('in progress')) return 'approved';
  if (normalized.contains('progress')) return 'approved';
  if (normalized.contains('complete')) return 'executed';
  if (normalized.contains('completed')) return 'executed';
  return 'draft';
}

String _normalizeStatusForDisplay(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) return 'Not Started';
  switch (normalized) {
    case 'draft':
      return 'Not Started';
    case 'under_review':
      return 'Pending Review';
    case 'approved':
      return 'In Progress';
    case 'executed':
      return 'Completed';
    case 'expired':
    case 'terminated':
      return 'Completed';
  }
  if (normalized.contains('not started')) return 'Not Started';
  if (normalized.contains('pending')) return 'Pending Review';
  if (normalized.contains('review')) return 'Pending Review';
  if (normalized.contains('in progress')) return 'In Progress';
  if (normalized.contains('progress')) return 'In Progress';
  if (normalized.contains('complete')) return 'Completed';
  if (normalized.contains('completed')) return 'Completed';
  return status.trim();
}

class ContractModel {
  final String id;
  final String projectId;
  final String name; // Contract Name
  final String description;
  final String contractType;
  final String paymentType;
  final String status;
  final double estimatedValue;
  final DateTime? startDate;
  final DateTime? endDate;
  final String scope;
  final String discipline;
  final String contractorName;
  final String owner;
  final String notes; // optional
  final String createdById;
  final String createdByEmail;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContractModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.contractType,
    required this.paymentType,
    required this.status,
    required this.estimatedValue,
    this.startDate,
    this.endDate,
    required this.scope,
    required this.discipline,
    this.contractorName = '',
    this.owner = '',
    required this.notes,
    required this.createdById,
    required this.createdByEmail,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final normalizedStatus = _normalizeStatusForStorage(status);
    final statusLabel = _normalizeStatusForDisplay(status);
    return {
      'projectId': projectId,
      'name': name,
      'title': name,
      'description': description,
      'contractType': contractType,
      'paymentType': paymentType,
      'status': normalizedStatus,
      'statusLabel': statusLabel,
      'estimatedValue': estimatedValue,
      'estimatedCost': estimatedValue,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'scope': scope,
      'discipline': discipline,
      'contractorName': contractorName,
      'owner': owner,
      'notes': notes,
      'createdById': createdById,
      'createdByEmail': createdByEmail,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static ContractModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? parseTs(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    final rawStatus = (data['statusLabel'] ?? data['status'] ?? '').toString();
    final displayStatus = _normalizeStatusForDisplay(rawStatus);

    return ContractModel(
      id: doc.id,
      projectId: (data['projectId'] ?? '').toString(),
      name: (data['name'] ?? data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      contractType: (data['contractType'] ?? '').toString(),
      paymentType: (data['paymentType'] ?? '').toString(),
      status: displayStatus,
      estimatedValue:
          parseDouble(data['estimatedValue'] ?? data['estimatedCost']),
      startDate: parseTs(data['startDate']),
      endDate: parseTs(data['endDate']),
      scope: (data['scope'] ?? '').toString(),
      discipline: (data['discipline'] ?? '').toString(),
      contractorName: (data['contractorName'] ?? '').toString(),
      owner: (data['owner'] ?? '').toString(),
      notes: (data['notes'] ?? '').toString(),
      createdById: (data['createdById'] ?? '').toString(),
      createdByEmail: (data['createdByEmail'] ?? '').toString(),
      createdByName: (data['createdByName'] ?? '').toString(),
      createdAt:
          parseTs(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          parseTs(data['updatedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ContractService {
  static CollectionReference<Map<String, dynamic>> _contractsCol(
          String projectId) =>
      FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('contracts');

  static Future<String> createContract({
    required String projectId,
    required String name,
    required String description,
    required String contractType,
    required String paymentType,
    required String status,
    required double estimatedValue,
    DateTime? startDate,
    DateTime? endDate,
    required String scope,
    required String discipline,
    String notes = '',
    required String createdById,
    required String createdByEmail,
    required String createdByName,
  }) async {
    final payload = ContractModel(
      id: '',
      projectId: projectId,
      name: name,
      description: description,
      contractType: contractType,
      paymentType: paymentType,
      status: status,
      estimatedValue: estimatedValue,
      startDate: startDate,
      endDate: endDate,
      scope: scope,
      discipline: discipline,
      contractorName: '',
      owner: '',
      notes: notes,
      createdById: createdById,
      createdByEmail: createdByEmail,
      createdByName: createdByName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).toMap();

    final ref = await _contractsCol(projectId).add(payload);
    return ref.id;
  }

  static Stream<List<ContractModel>> streamContracts(String projectId,
      {int limit = 50}) {
    return _contractsCol(projectId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ContractModel.fromDoc).toList());
  }

  /// Update an existing contract
  static Future<void> updateContract({
    required String projectId,
    required String contractId,
    String? name,
    String? description,
    String? contractType,
    String? paymentType,
    String? status,
    double? estimatedValue,
    DateTime? startDate,
    DateTime? endDate,
    String? scope,
    String? discipline,
    String? notes,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      updateData['name'] = name;
      updateData['title'] = name;
    }
    if (description != null) updateData['description'] = description;
    if (contractType != null) updateData['contractType'] = contractType;
    if (paymentType != null) updateData['paymentType'] = paymentType;
    if (status != null) {
      updateData['status'] = _normalizeStatusForStorage(status);
      updateData['statusLabel'] = _normalizeStatusForDisplay(status);
    }
    if (estimatedValue != null) {
      updateData['estimatedValue'] = estimatedValue;
      updateData['estimatedCost'] = estimatedValue;
    }
    if (startDate != null) {
      updateData['startDate'] = Timestamp.fromDate(startDate);
    }
    if (endDate != null) {
      updateData['endDate'] = Timestamp.fromDate(endDate);
    }
    if (scope != null) updateData['scope'] = scope;
    if (discipline != null) updateData['discipline'] = discipline;
    if (notes != null) updateData['notes'] = notes;

    await _contractsCol(projectId).doc(contractId).update(updateData);
  }

  /// Delete a contract
  static Future<void> deleteContract({
    required String projectId,
    required String contractId,
  }) async {
    await _contractsCol(projectId).doc(contractId).delete();
  }

  /// Get a single contract
  static Future<ContractModel?> getContract({
    required String projectId,
    required String contractId,
  }) async {
    final doc = await _contractsCol(projectId).doc(contractId).get();
    if (!doc.exists) return null;
    return ContractModel.fromDoc(doc);
  }
}
