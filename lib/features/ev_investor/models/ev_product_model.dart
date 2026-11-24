class EvProductSpecs {
  final String brandModel;
  final String vehicleAge;
  final String range;
  final String battery;
  final String chargingTime;

  const EvProductSpecs({
    required this.brandModel,
    required this.vehicleAge,
    required this.range,
    required this.battery,
    required this.chargingTime,
  });

  factory EvProductSpecs.fromJson(Map<String, dynamic> json) {
    return EvProductSpecs(
      brandModel: json['brandModel']?.toString().trim() ?? '',
      vehicleAge: json['vehicleAge']?.toString().trim() ?? 'Brand New',
      range: json['range']?.toString().trim() ?? '',
      battery: json['battery']?.toString().trim() ?? '',
      chargingTime: json['chargingTime']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brandModel': brandModel,
      'vehicleAge': vehicleAge,
      'range': range,
      'battery': battery,
      'chargingTime': chargingTime,
    };
  }

  EvProductSpecs copyWith({
    String? brandModel,
    String? vehicleAge,
    String? range,
    String? battery,
    String? chargingTime,
  }) {
    return EvProductSpecs(
      brandModel: brandModel ?? this.brandModel,
      vehicleAge: vehicleAge ?? this.vehicleAge,
      range: range ?? this.range,
      battery: battery ?? this.battery,
      chargingTime: chargingTime ?? this.chargingTime,
    );
  }
}

class EvProductModel {
  final String id;
  final String mongoId;
  final String type;
  final String category;
  final String brand;
  final String modelName;
  final int modelYear;
  final String summary;
  final int unitPrice;
  final double monthlyReturnRate;
  final int? explicitMonthlyReturnAmount;
  final String? explicitExpectedReturn;
  final String coverImage;
  final List<String> gallery;
  final List<String> infoTags;
  final List<String> highlights;
  final EvProductSpecs specs;
  final bool isActive;

  const EvProductModel({
    required this.id,
    this.mongoId = '',
    required this.type,
    required this.category,
    required this.brand,
    required this.modelName,
    required this.modelYear,
    required this.summary,
    required this.unitPrice,
    required this.monthlyReturnRate,
    this.explicitMonthlyReturnAmount,
    this.explicitExpectedReturn,
    required this.coverImage,
    this.gallery = const [],
    this.infoTags = const [],
    this.highlights = const [],
    required this.specs,
    this.isActive = true,
  });

  String get name => modelName.isNotEmpty
      ? modelName
      : (specs.brandModel.isNotEmpty ? specs.brandModel : '$brand EV');

  int get monthlyReturnAmount {
    if (explicitMonthlyReturnAmount != null) {
      return explicitMonthlyReturnAmount!;
    }
    return (unitPrice * (monthlyReturnRate / 100)).round();
  }

  String get expectedReturnLabel {
    if (explicitExpectedReturn != null &&
        explicitExpectedReturn!.trim().isNotEmpty) {
      return explicitExpectedReturn!.trim();
    }
    final formattedRate = monthlyReturnRate == monthlyReturnRate.roundToDouble()
        ? monthlyReturnRate.toStringAsFixed(0)
        : monthlyReturnRate.toString();
    return '$formattedRate% Monthly';
  }

  int totalAmountForUnits(int units) {
    if (units <= 0) return 0;
    return unitPrice * units;
  }

  int monthlyReturnForUnits(int units) {
    if (units <= 0) return 0;
    return monthlyReturnAmount * units;
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.round();
    final str = value.toString().trim();
    if (str.isEmpty) return fallback;
    return int.tryParse(str) ?? double.tryParse(str)?.round() ?? fallback;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    return int.tryParse(str) ?? double.tryParse(str)?.round();
  }

  static double _parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    final str = value.toString().trim();
    if (str.isEmpty) return fallback;
    return double.tryParse(str) ?? fallback;
  }

  static bool _parseBool(dynamic value, {bool fallback = true}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    final str = value.toString().trim().toLowerCase();
    if (str == 'true' || str == '1') return true;
    if (str == 'false' || str == '0') return false;
    return fallback;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  factory EvProductModel.fromJson(Map<String, dynamic> json) {
    final parsedGallery = _parseStringList(json['gallery']);
    final rawCover = json['coverImage']?.toString().trim() ?? '';
    final resolvedCover = rawCover.isNotEmpty
        ? rawCover
        : (parsedGallery.isNotEmpty ? parsedGallery.first : '');

    final rawModelName = json['modelName']?.toString().trim() ?? '';
    final rawName = json['name']?.toString().trim() ?? '';
    final resolvedModelName = rawModelName.isNotEmpty ? rawModelName : rawName;

    final rawId = json['id']?.toString().trim() ?? '';
    final rawMongoId = json['_id']?.toString().trim() ?? '';
    final resolvedId = rawId.isNotEmpty ? rawId : rawMongoId;

    final rawCategory = json['category']?.toString().trim().toLowerCase() ?? '';
    final rawType = json['type']?.toString().trim() ?? '';
    final resolvedCategory = rawCategory.isNotEmpty ? rawCategory : 'other';
    final resolvedType = rawType.isNotEmpty ? rawType : 'Other';

    final specsMap = json['specs'] is Map
        ? Map<String, dynamic>.from(json['specs'] as Map)
        : <String, dynamic>{};

    return EvProductModel(
      id: resolvedId,
      mongoId: rawMongoId,
      type: resolvedType,
      category: resolvedCategory,
      brand: json['brand']?.toString().trim() ?? '',
      modelName: resolvedModelName,
      modelYear: _parseInt(json['modelYear'], fallback: DateTime.now().year),
      summary: json['summary']?.toString().trim() ?? '',
      unitPrice: _parseInt(json['unitPrice'], fallback: 0),
      monthlyReturnRate: _parseDouble(json['monthlyReturnRate'], fallback: 0.0),
      explicitMonthlyReturnAmount: _parseNullableInt(
        json['monthlyReturnAmount'],
      ),
      explicitExpectedReturn: json['expectedReturn']?.toString(),
      coverImage: resolvedCover,
      gallery: parsedGallery.isNotEmpty
          ? parsedGallery
          : (resolvedCover.isNotEmpty ? [resolvedCover] : const []),
      infoTags: _parseStringList(json['infoTags']),
      highlights: _parseStringList(json['highlights']),
      specs: EvProductSpecs.fromJson(specsMap),
      isActive: _parseBool(json['isActive'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (mongoId.isNotEmpty) '_id': mongoId,
      'id': id,
      'type': type,
      'category': category,
      'brand': brand,
      'modelName': modelName,
      'modelYear': modelYear,
      'summary': summary,
      'unitPrice': unitPrice,
      'monthlyReturnRate': monthlyReturnRate,
      'monthlyReturnAmount': monthlyReturnAmount,
      'expectedReturn': expectedReturnLabel,
      'coverImage': coverImage,
      'gallery': gallery,
      'infoTags': infoTags,
      'highlights': highlights,
      'specs': specs.toJson(),
      'isActive': isActive,
    };
  }
}
