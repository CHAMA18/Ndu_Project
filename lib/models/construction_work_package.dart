/// Typed Construction Work Package (CWP).
/// Complements the generic [WorkPackage] with CWP-specific fields.
class ConstructionWorkPackage {
  final String id;
  final String workPackageId; // FK to WorkPackage.id
  String workArea;
  String swbsCode; // System Work Breakdown Structure code
  String constructionMethod;
  String contractorId;
  String siteSupervisor;
  DateTime? siteMobilizationDate;
  DateTime? constructionStartDate;
  DateTime? constructionEndDate;
  double manHours;
  double progressPercent;
  String status; // 'planned' | 'in_progress' | 'complete' | 'delayed'
  String notes;

  ConstructionWorkPackage({
    String? id,
    required this.workPackageId,
    this.workArea = '',
    this.swbsCode = '',
    this.constructionMethod = '',
    this.contractorId = '',
    this.siteSupervisor = '',
    this.siteMobilizationDate,
    this.constructionStartDate,
    this.constructionEndDate,
    this.manHours = 0,
    this.progressPercent = 0,
    this.status = 'planned',
    this.notes = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'workPackageId': workPackageId,
        'workArea': workArea,
        'swbsCode': swbsCode,
        'constructionMethod': constructionMethod,
        'contractorId': contractorId,
        'siteSupervisor': siteSupervisor,
        'siteMobilizationDate':
            siteMobilizationDate?.toIso8601String(),
        'constructionStartDate':
            constructionStartDate?.toIso8601String(),
        'constructionEndDate': constructionEndDate?.toIso8601String(),
        'manHours': manHours,
        'progressPercent': progressPercent,
        'status': status,
        'notes': notes,
      };

  factory ConstructionWorkPackage.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      if (v is DateTime) return v;
      return null;
    }

    double toDouble(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

    return ConstructionWorkPackage(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      workPackageId: json['workPackageId']?.toString() ?? '',
      workArea: json['workArea']?.toString() ?? '',
      swbsCode: json['swbsCode']?.toString() ?? '',
      constructionMethod: json['constructionMethod']?.toString() ?? '',
      contractorId: json['contractorId']?.toString() ?? '',
      siteSupervisor: json['siteSupervisor']?.toString() ?? '',
      siteMobilizationDate: parseDate(json['siteMobilizationDate']),
      constructionStartDate: parseDate(json['constructionStartDate']),
      constructionEndDate: parseDate(json['constructionEndDate']),
      manHours: toDouble(json['manHours']),
      progressPercent: toDouble(json['progressPercent']),
      status: json['status']?.toString() ?? 'planned',
      notes: json['notes']?.toString() ?? '',
    );
  }
}
