class ObsElement {
  final String id;
  String name;
  String parentObsId;
  String manager;
  String organization;
  String description;

  ObsElement({
    String? id,
    this.name = '',
    this.parentObsId = '',
    this.manager = '',
    this.organization = '',
    this.description = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  ObsElement copyWith({
    String? name,
    String? parentObsId,
    String? manager,
    String? organization,
    String? description,
  }) {
    return ObsElement(
      id: id,
      name: name ?? this.name,
      parentObsId: parentObsId ?? this.parentObsId,
      manager: manager ?? this.manager,
      organization: organization ?? this.organization,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentObsId': parentObsId,
        'manager': manager,
        'organization': organization,
        'description': description,
      };

  factory ObsElement.fromJson(Map<String, dynamic> json) {
    return ObsElement(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      parentObsId: json['parentObsId']?.toString() ?? '',
      manager: json['manager']?.toString() ?? '',
      organization: json['organization']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
