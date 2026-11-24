double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

String _parseString(dynamic value) {
  return value?.toString() ?? '';
}

class VehicleImageItem {
  final String label;
  final String url;

  const VehicleImageItem({required this.label, required this.url});
}

class VehicleClusterLocationModel {
  final double lat;
  final double long;
  final String zipCode;
  final String state;
  final String city;
  final String streetAddress;

  const VehicleClusterLocationModel({
    required this.lat,
    required this.long,
    required this.zipCode,
    required this.state,
    required this.city,
    required this.streetAddress,
  });

  factory VehicleClusterLocationModel.fromJson(Map<String, dynamic> json) {
    return VehicleClusterLocationModel(
      lat: _parseDouble(json['lat']),
      long: _parseDouble(json['long'] ?? json['lng']),
      zipCode: _parseString(json['zipCode']),
      state: _parseString(json['state']),
      city: _parseString(json['city']),
      streetAddress: _parseString(json['streetAddress']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'long': long,
      'zipCode': zipCode,
      'state': state,
      'city': city,
      'streetAddress': streetAddress,
    };
  }
}

class EVProductModel {
  final String id;
  final String vehicleType;
  final String vehicleNoPlate;
  final String companyName;
  final String purchaseLocation;
  final String sellerName;
  final String headquarterLocation;
  final int purchasePrice;
  final int investmentAmount;
  final int investorReturnRate;
  final int outboundRentalRate;
  final String status;
  final String vehicleModelName;
  final int vehicleYearModel;
  final double vehicleMotorPowerKw;
  final int vehicleServiceNo;
  final double batteryCapacityKwh;
  final int rangeKm;
  final int topSpeedKmph;
  final List<String> vehicleImage;
  final String vehicleId;
  final int tenureMonths;

  // Original fields retained for existing UI compatibility.
  final String clusterCity;
  final String clusterState;
  final String clusterZipCode;
  final String clusterStreetAddress;

  // Complete dynamic cluster location object.
  final VehicleClusterLocationModel? vehicleClusterLocation;

  EVProductModel({
    required this.id,
    required this.vehicleType,
    required this.vehicleNoPlate,
    required this.companyName,
    required this.purchaseLocation,
    required this.sellerName,
    required this.headquarterLocation,
    required this.purchasePrice,
    required this.investmentAmount,
    required this.investorReturnRate,
    required this.outboundRentalRate,
    required this.status,
    required this.vehicleModelName,
    required this.vehicleYearModel,
    required this.vehicleMotorPowerKw,
    required this.vehicleServiceNo,
    required this.batteryCapacityKwh,
    required this.rangeKm,
    required this.topSpeedKmph,
    required this.vehicleImage,
    required this.vehicleId,
    this.tenureMonths = 0,
    this.clusterCity = '',
    this.clusterState = '',
    this.clusterZipCode = '',
    this.clusterStreetAddress = '',
    this.vehicleClusterLocation,
  });

  int get totalProfit {
    final int totalReturn = investorReturnRate * tenureMonths;
    return totalReturn - investmentAmount;
  }

  int get profitPercentage {
    if (investmentAmount <= 0) return 0;
    return ((totalProfit / investmentAmount) * 100).round();
  }

  // Only API images. No dummy image fallback.
  List<String> get vehicleImages {
    return vehicleImage
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<VehicleImageItem> get angleGallery {
    const List<String> angleNames = [
      'Front / Primary',
      'Side View',
      'Rear & Hub',
      'Detail View',
    ];

    final List<String> urls = vehicleImages;

    return List.generate(urls.length, (index) {
      return VehicleImageItem(
        label: index < angleNames.length
            ? angleNames[index]
            : 'Angle ${index + 1}',
        url: urls[index],
      );
    });
  }

  String get primaryImageUrl {
    return vehicleImages.isNotEmpty ? vehicleImages.first : '';
  }

  factory EVProductModel.fromJson(Map<String, dynamic> json) {
    final companyMap = _parseMap(json['companyData']);
    final pricingMap = _parseMap(json['pricing']);
    final locationMap = _parseMap(json['vehicleClusterLocation']);

    final VehicleClusterLocationModel? location =
        json['vehicleClusterLocation'] is Map
        ? VehicleClusterLocationModel.fromJson(locationMap)
        : null;

    final dynamic rawImages = json['vehicleImage'] ?? json['vehicleImages'];

    final List<String> parsedImages = _parseImages(rawImages);

    return EVProductModel(
      id: _parseString(json['_id'] ?? json['id']),
      vehicleType: _parseString(json['vehicleType']),
      vehicleNoPlate: _parseString(json['vehicleNoPlate']),

      companyName: _parseString(companyMap['companyName']),
      purchaseLocation: _parseString(companyMap['purchaseLocation']),
      sellerName: _parseString(companyMap['sellerName']),
      headquarterLocation: _parseString(companyMap['headquarterLocation']),

      purchasePrice: _parseInt(pricingMap['purchasePrice']),
      investmentAmount: _parseInt(pricingMap['investmentAmount']),
      investorReturnRate: _parseInt(pricingMap['investorReturnRate']),
      outboundRentalRate: _parseInt(pricingMap['outboundRentalRate']),

      status: _parseString(json['status']),
      vehicleModelName: _parseString(json['vehicleModelName']),
      vehicleYearModel: _parseInt(json['vehicleYearModel']),
      vehicleMotorPowerKw: _parseDouble(json['vehicleMotorPowerKw']),
      vehicleServiceNo: _parseInt(json['vehicleServiceNo']),
      batteryCapacityKwh: _parseDouble(json['batteryCapacityKwh']),
      rangeKm: _parseInt(json['rangeKm']),
      topSpeedKmph: _parseInt(json['topSpeedKmph']),

      vehicleImage: parsedImages,
      vehicleId: _parseString(json['vehicleId']),
      tenureMonths: _parseInt(json['tenureMonths']),

      // Old fields populated from the new dynamic location object.
      clusterCity: _parseString(locationMap['city']),
      clusterState: _parseString(locationMap['state']),
      clusterZipCode: _parseString(locationMap['zipCode']),
      clusterStreetAddress: _parseString(locationMap['streetAddress']),

      vehicleClusterLocation: location,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vehicleType': vehicleType,
      'vehicleNoPlate': vehicleNoPlate,
      'companyData': {
        'companyName': companyName,
        'purchaseLocation': purchaseLocation,
        'sellerName': sellerName,
        'headquarterLocation': headquarterLocation,
      },
      'pricing': {
        'purchasePrice': purchasePrice,
        'investmentAmount': investmentAmount,
        'investorReturnRate': investorReturnRate,
        'outboundRentalRate': outboundRentalRate,
      },
      'status': status,
      'vehicleModelName': vehicleModelName,
      'vehicleYearModel': vehicleYearModel,
      'vehicleMotorPowerKw': vehicleMotorPowerKw,
      'vehicleServiceNo': vehicleServiceNo,
      'batteryCapacityKwh': batteryCapacityKwh,
      'rangeKm': rangeKm,
      'topSpeedKmph': topSpeedKmph,
      'vehicleImage': vehicleImage,
      'vehicleId': vehicleId,
      'tenureMonths': tenureMonths,
      'vehicleClusterLocation': vehicleClusterLocation?.toJson(),
    };
  }

  static Map<String, dynamic> _parseMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  static List<String> _parseImages(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) {
          if (item is String) return item.trim();

          if (item is Map) {
            final dynamic url =
                item['url'] ?? item['imageUrl'] ?? item['src'] ?? item['path'];

            return url?.toString().trim() ?? '';
          }

          return '';
        })
        .where((url) => url.isNotEmpty)
        .toList();
  }

  static String _parseString(dynamic value) {
    return value?.toString() ?? '';
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ReservedAssetItem {
  final EVProductModel product;
  int units;

  ReservedAssetItem({required this.product, this.units = 1});

  int get totalInvestment => product.investmentAmount * units;

  int get totalMonthlyReturn => product.investorReturnRate * units;
}
