import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single task entry in the Project Log.
class ProjectLogEntry {
  const ProjectLogEntry({
    this.id,
    this.projectId,
    this.taskDescription,
    this.assignedTo,
    this.dueDate,
    this.priority = 'Medium',
    this.status = 'Pending',
    this.category,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? projectId;
  final String? taskDescription;
  final String? assignedTo;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final String? category;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProjectLogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProjectLogEntry(
      id: doc.id,
      projectId: data['projectId'] as String?,
      taskDescription: data['taskDescription'] as String?,
      assignedTo: data['assignedTo'] as String?,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      priority: data['priority'] as String? ?? 'Medium',
      status: data['status'] as String? ?? 'Pending',
      category: data['category'] as String?,
      notes: data['notes'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (projectId != null) 'projectId': projectId,
      if (taskDescription != null) 'taskDescription': taskDescription,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      'priority': priority,
      'status': status,
      if (category != null) 'category': category,
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ProjectLogEntry copyWith({
    String? id,
    String? projectId,
    String? taskDescription,
    String? assignedTo,
    DateTime? dueDate,
    String? priority,
    String? status,
    String? category,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectLogEntry(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      taskDescription: taskDescription ?? this.taskDescription,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
