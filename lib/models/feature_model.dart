class Feature {
  final String id;
  String title;
  String description;
  String epicId;
  String status; // 'backlog' | 'active' | 'complete' | 'cancelled'
  String priority; // 'critical' | 'high' | 'medium' | 'low'
  double storyPointEstimate;

  Feature({
    String? id,
    this.title = '',
    this.description = '',
    this.epicId = '',
    this.status = 'backlog',
    this.priority = 'medium',
    this.storyPointEstimate = 0,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Feature copyWith({
    String? title,
    String? description,
    String? epicId,
    String? status,
    String? priority,
    double? storyPointEstimate,
  }) {
    return Feature(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      epicId: epicId ?? this.epicId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      storyPointEstimate: storyPointEstimate ?? this.storyPointEstimate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'epicId': epicId,
        'status': status,
        'priority': priority,
        'storyPointEstimate': storyPointEstimate,
      };

  factory Feature.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

    return Feature(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      epicId: json['epicId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'backlog',
      priority: json['priority']?.toString() ?? 'medium',
      storyPointEstimate: toDouble(json['storyPointEstimate']),
    );
  }
}
