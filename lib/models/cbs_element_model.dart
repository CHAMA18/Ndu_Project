class CbsElement {
  final String id;
  String code;
  String name;
  String parentCbsId;
  String costCategory;
  String costType;
  String description;

  CbsElement({
    String? id,
    this.code = '',
    this.name = '',
    this.parentCbsId = '',
    this.costCategory = '',
    this.costType = '',
    this.description = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  CbsElement copyWith({
    String? code,
    String? name,
    String? parentCbsId,
    String? costCategory,
    String? costType,
    String? description,
  }) {
    return CbsElement(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      parentCbsId: parentCbsId ?? this.parentCbsId,
      costCategory: costCategory ?? this.costCategory,
      costType: costType ?? this.costType,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'parentCbsId': parentCbsId,
        'costCategory': costCategory,
        'costType': costType,
        'description': description,
      };

  factory CbsElement.fromJson(Map<String, dynamic> json) {
    return CbsElement(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      parentCbsId: json['parentCbsId']?.toString() ?? '',
      costCategory: json['costCategory']?.toString() ?? '',
      costType: json['costType']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
