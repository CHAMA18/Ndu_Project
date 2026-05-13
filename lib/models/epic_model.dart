class Epic {
  final String id;
  String title;
  String description;
  String theme;
  String status; // 'backlog' | 'active' | 'complete' | 'cancelled'
  String businessValue;
  int? startSprint;
  int? endSprint;
  String owner;
  double totalStoryPoints;
  double completedStoryPoints;

  Epic({
    String? id,
    this.title = '',
    this.description = '',
    this.theme = '',
    this.status = 'backlog',
    this.businessValue = '',
    this.startSprint,
    this.endSprint,
    this.owner = '',
    this.totalStoryPoints = 0,
    this.completedStoryPoints = 0,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Epic copyWith({
    String? title,
    String? description,
    String? theme,
    String? status,
    String? businessValue,
    int? startSprint,
    int? endSprint,
    String? owner,
    double? totalStoryPoints,
    double? completedStoryPoints,
  }) {
    return Epic(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      theme: theme ?? this.theme,
      status: status ?? this.status,
      businessValue: businessValue ?? this.businessValue,
      startSprint: startSprint ?? this.startSprint,
      endSprint: endSprint ?? this.endSprint,
      owner: owner ?? this.owner,
      totalStoryPoints: totalStoryPoints ?? this.totalStoryPoints,
      completedStoryPoints: completedStoryPoints ?? this.completedStoryPoints,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'theme': theme,
        'status': status,
        'businessValue': businessValue,
        'startSprint': startSprint,
        'endSprint': endSprint,
        'owner': owner,
        'totalStoryPoints': totalStoryPoints,
        'completedStoryPoints': completedStoryPoints,
      };

  factory Epic.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
    int? toNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return Epic(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      theme: json['theme']?.toString() ?? '',
      status: json['status']?.toString() ?? 'backlog',
      businessValue: json['businessValue']?.toString() ?? '',
      startSprint: toNullableInt(json['startSprint']),
      endSprint: toNullableInt(json['endSprint']),
      owner: json['owner']?.toString() ?? '',
      totalStoryPoints: toDouble(json['totalStoryPoints']),
      completedStoryPoints: toDouble(json['completedStoryPoints']),
    );
  }
}
