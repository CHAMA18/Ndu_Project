class BaselineVersion {
  final String id;
  final int versionNumber;
  final String label;
  final String description;
  final String author;
  final String approvedBy;
  final DateTime createdAt;

  // Point-in-time snapshot summaries
  final double scheduleVarianceDays;
  final double costVariance;
  final double budgetAtCompletion;
  final int totalActivities;
  final int completedActivities;
  final int totalWorkPackages;
  final String triggerSource; // 'manual' | 'change_request' | 'periodic'

  BaselineVersion({
    String? id,
    required this.versionNumber,
    required this.label,
    this.description = '',
    required this.author,
    this.approvedBy = '',
    DateTime? createdAt,
    this.scheduleVarianceDays = 0,
    this.costVariance = 0,
    this.budgetAtCompletion = 0,
    this.totalActivities = 0,
    this.completedActivities = 0,
    this.totalWorkPackages = 0,
    this.triggerSource = 'manual',
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  BaselineVersion copyWith({
    String? label,
    String? description,
    String? approvedBy,
    int? versionNumber,
    double? scheduleVarianceDays,
    double? costVariance,
    double? budgetAtCompletion,
    int? totalActivities,
    int? completedActivities,
    int? totalWorkPackages,
    String? triggerSource,
  }) {
    return BaselineVersion(
      id: id,
      versionNumber: versionNumber ?? this.versionNumber,
      label: label ?? this.label,
      description: description ?? this.description,
      author: author,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt,
      scheduleVarianceDays:
          scheduleVarianceDays ?? this.scheduleVarianceDays,
      costVariance: costVariance ?? this.costVariance,
      budgetAtCompletion: budgetAtCompletion ?? this.budgetAtCompletion,
      totalActivities: totalActivities ?? this.totalActivities,
      completedActivities: completedActivities ?? this.completedActivities,
      totalWorkPackages: totalWorkPackages ?? this.totalWorkPackages,
      triggerSource: triggerSource ?? this.triggerSource,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'versionNumber': versionNumber,
        'label': label,
        'description': description,
        'author': author,
        'approvedBy': approvedBy,
        'createdAt': createdAt.toIso8601String(),
        'scheduleVarianceDays': scheduleVarianceDays,
        'costVariance': costVariance,
        'budgetAtCompletion': budgetAtCompletion,
        'totalActivities': totalActivities,
        'completedActivities': completedActivities,
        'totalWorkPackages': totalWorkPackages,
        'triggerSource': triggerSource,
      };

  factory BaselineVersion.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      if (v is DateTime) return v;
      return null;
    }

    double toDouble(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
    int toInt(dynamic v) =>
        (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

    return BaselineVersion(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      versionNumber: toInt(json['versionNumber']),
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      approvedBy: json['approvedBy']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      scheduleVarianceDays: toDouble(json['scheduleVarianceDays']),
      costVariance: toDouble(json['costVariance']),
      budgetAtCompletion: toDouble(json['budgetAtCompletion']),
      totalActivities: toInt(json['totalActivities']),
      completedActivities: toInt(json['completedActivities']),
      totalWorkPackages: toInt(json['totalWorkPackages']),
      triggerSource: json['triggerSource']?.toString() ?? 'manual',
    );
  }
}
