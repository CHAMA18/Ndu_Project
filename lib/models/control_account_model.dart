class ControlAccount {
  final String id;
  String wbsId;
  String obsId;
  String title;
  String description;
  String responsiblePerson;
  String status; // 'authorized' | 'active' | 'closed'

  double budgetAtCompletion;
  Map<String, double> plannedValueByPeriod; // periodKey '2026-05' -> PV

  double earnedValue;
  double actualCost;
  double cpi;
  double spi;
  double eac;
  double etc;
  double vac;

  DateTime? lastRecalculated;
  DateTime createdAt;
  DateTime? updatedAt;

  ControlAccount({
    String? id,
    this.wbsId = '',
    this.obsId = '',
    this.title = '',
    this.description = '',
    this.responsiblePerson = '',
    this.status = 'authorized',
    this.budgetAtCompletion = 0,
    Map<String, double>? plannedValueByPeriod,
    this.earnedValue = 0,
    this.actualCost = 0,
    this.cpi = 1.0,
    this.spi = 1.0,
    this.eac = 0,
    this.etc = 0,
    this.vac = 0,
    this.lastRecalculated,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        plannedValueByPeriod = plannedValueByPeriod ?? {},
        createdAt = createdAt ?? DateTime.now();

  ControlAccount copyWith({
    String? wbsId,
    String? obsId,
    String? title,
    String? description,
    String? responsiblePerson,
    String? status,
    double? budgetAtCompletion,
    Map<String, double>? plannedValueByPeriod,
    double? earnedValue,
    double? actualCost,
    double? cpi,
    double? spi,
    double? eac,
    double? etc,
    double? vac,
    DateTime? lastRecalculated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ControlAccount(
      id: id,
      wbsId: wbsId ?? this.wbsId,
      obsId: obsId ?? this.obsId,
      title: title ?? this.title,
      description: description ?? this.description,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      status: status ?? this.status,
      budgetAtCompletion: budgetAtCompletion ?? this.budgetAtCompletion,
      plannedValueByPeriod:
          plannedValueByPeriod ?? Map<String, double>.from(this.plannedValueByPeriod),
      earnedValue: earnedValue ?? this.earnedValue,
      actualCost: actualCost ?? this.actualCost,
      cpi: cpi ?? this.cpi,
      spi: spi ?? this.spi,
      eac: eac ?? this.eac,
      etc: etc ?? this.etc,
      vac: vac ?? this.vac,
      lastRecalculated: lastRecalculated ?? this.lastRecalculated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wbsId': wbsId,
        'obsId': obsId,
        'title': title,
        'description': description,
        'responsiblePerson': responsiblePerson,
        'status': status,
        'budgetAtCompletion': budgetAtCompletion,
        'plannedValueByPeriod': plannedValueByPeriod
            .map((k, v) => MapEntry(k, v)),
        'earnedValue': earnedValue,
        'actualCost': actualCost,
        'cpi': cpi,
        'spi': spi,
        'eac': eac,
        'etc': etc,
        'vac': vac,
        'lastRecalculated': lastRecalculated?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory ControlAccount.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateField(String key) {
      final val = json[key];
      if (val == null) return null;
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val);
      }
      if (val is DateTime) return val;
      return null;
    }

    Map<String, double> parsePeriodMap(dynamic raw) {
      final map = <String, double>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          map[k.toString()] = (v is num) ? v.toDouble() : 0.0;
        });
      }
      return map;
    }

    double toDouble(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

    return ControlAccount(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      wbsId: json['wbsId']?.toString() ?? '',
      obsId: json['obsId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      responsiblePerson: json['responsiblePerson']?.toString() ?? '',
      status: json['status']?.toString() ?? 'authorized',
      budgetAtCompletion: toDouble(json['budgetAtCompletion']),
      plannedValueByPeriod: parsePeriodMap(json['plannedValueByPeriod']),
      earnedValue: toDouble(json['earnedValue']),
      actualCost: toDouble(json['actualCost']),
      cpi: toDouble(json['cpi']),
      spi: toDouble(json['spi']),
      eac: toDouble(json['eac']),
      etc: toDouble(json['etc']),
      vac: toDouble(json['vac']),
      lastRecalculated: parseDateField('lastRecalculated'),
      createdAt: parseDateField('createdAt') ?? DateTime.now(),
      updatedAt: parseDateField('updatedAt'),
    );
  }
}
