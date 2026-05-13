/// Typed Engineering Work Package (EWP).
/// Complements the generic [WorkPackage] with EWP-specific fields.
class EngineeringWorkPackage {
  final String id;
  final String workPackageId; // FK to WorkPackage.id
  String drawingPackageRef;
  String designSpecificationId;
  String designDiscipline;
  String reviewStatus; // 'draft' | 'in_review' | 'approved' | 'issued_for_construction'
  DateTime? designCompletedDate;
  DateTime? issuedForConstructionDate;
  List<String> linkedProcurementPackageIds;
  List<String> linkedConstructionPackageIds;
  String notes;

  EngineeringWorkPackage({
    String? id,
    required this.workPackageId,
    this.drawingPackageRef = '',
    this.designSpecificationId = '',
    this.designDiscipline = '',
    this.reviewStatus = 'draft',
    this.designCompletedDate,
    this.issuedForConstructionDate,
    List<String>? linkedProcurementPackageIds,
    List<String>? linkedConstructionPackageIds,
    this.notes = '',
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        linkedProcurementPackageIds = linkedProcurementPackageIds ?? [],
        linkedConstructionPackageIds = linkedConstructionPackageIds ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'workPackageId': workPackageId,
        'drawingPackageRef': drawingPackageRef,
        'designSpecificationId': designSpecificationId,
        'designDiscipline': designDiscipline,
        'reviewStatus': reviewStatus,
        'designCompletedDate': designCompletedDate?.toIso8601String(),
        'issuedForConstructionDate':
            issuedForConstructionDate?.toIso8601String(),
        'linkedProcurementPackageIds': linkedProcurementPackageIds,
        'linkedConstructionPackageIds': linkedConstructionPackageIds,
        'notes': notes,
      };

  factory EngineeringWorkPackage.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      if (v is DateTime) return v;
      return null;
    }

    return EngineeringWorkPackage(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      workPackageId: json['workPackageId']?.toString() ?? '',
      drawingPackageRef: json['drawingPackageRef']?.toString() ?? '',
      designSpecificationId:
          json['designSpecificationId']?.toString() ?? '',
      designDiscipline: json['designDiscipline']?.toString() ?? '',
      reviewStatus: json['reviewStatus']?.toString() ?? 'draft',
      designCompletedDate: parseDate(json['designCompletedDate']),
      issuedForConstructionDate:
          parseDate(json['issuedForConstructionDate']),
      linkedProcurementPackageIds:
          (json['linkedProcurementPackageIds'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      linkedConstructionPackageIds:
          (json['linkedConstructionPackageIds'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      notes: json['notes']?.toString() ?? '',
    );
  }
}
