class VehicleImageItem {
  final String label;
  final String url;

  const VehicleImageItem({required this.label, required this.url});
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
  final String clusterCity;
  final String clusterState;
  final String clusterZipCode;
  final String clusterStreetAddress;

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
    this.tenureMonths = 36,
    this.clusterCity = 'Aligarh',
    this.clusterState = 'Uttar Pradesh',
    this.clusterZipCode = '202138',
    this.clusterStreetAddress = 'MOH MALIPURA PAINTH MAIDAN KHAIR, 24',
  });

  int get totalProfit {
    final int totalReturn = investorReturnRate * tenureMonths;
    return totalReturn - investmentAmount;
  }

  int get profitPercentage {
    if (investmentAmount <= 0) return 0;
    return ((totalProfit / investmentAmount) * 100).round();
  }

  /// Multiple vehicle image URLs array (guaranteed non-empty with angle fallbacks)
  List<String> get vehicleImages {
    final List<String> cleaned = vehicleImage
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final List<String> defaults = [
      'https://5.imimg.com/data5/SELLER/Default/2022/1/LL/EY/AW/21369253/hero-destini-125cc-scooty.jpg',
      'https://tse2.mm.bing.net/th/id/OIP.2rHyt0irjyVvIe8RMWUEZwHaGW?r=0&pid=Api&h=220&P=0',
      'https://tse4.mm.bing.net/th/id/OIP._REB424hq76CWXsxtIT7dQHaFL?r=0&pid=Api&h=220&P=0',
    ];

    if (cleaned.isEmpty) {
      return defaults;
    }

    if (cleaned.length == 1) {
      return [cleaned.first, defaults[1], defaults[2]];
    }

    return cleaned;
  }

  /// Multiple angle items with labels for thumbnail selection
  List<VehicleImageItem> get angleGallery {
    const List<String> angleNames = [
      'Front / Primary',
      'Side View',
      'Rear & Hub',
      'Detail View',
    ];

    final List<String> urls = vehicleImages;
    return List.generate(urls.length, (index) {
      final String label = index < angleNames.length
          ? angleNames[index]
          : 'Angle ${index + 1}';
      return VehicleImageItem(label: label, url: urls[index]);
    });
  }

  String get primaryImageUrl => vehicleImages.first;

  factory EVProductModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> companyMap = Map<String, dynamic>.from(
      json['companyData'] ?? {},
    );
    final Map<String, dynamic> pricingMap = Map<String, dynamic>.from(
      json['pricing'] ?? {},
    );
    final Map<String, dynamic> locMap = Map<String, dynamic>.from(
      json['vehicleClusterLocation'] ?? {},
    );

    final List<dynamic> rawImages =
        json['vehicleImage'] as List<dynamic>? ??
        json['vehicleImages'] as List<dynamic>? ??
        [];

    final List<String> parsedImages = rawImages
        .map((e) {
          if (e is String) return e.trim();
          if (e is Map) {
            final dynamic candidate =
                e['url'] ?? e['imageUrl'] ?? e['src'] ?? e['path'];
            return candidate?.toString().trim() ?? '';
          }
          return '';
        })
        .where((s) => s.isNotEmpty)
        .toList();

    final String cityVal =
        (locMap['city'] ?? companyMap['purchaseLocation'] ?? 'Aligarh')
            .toString();

    return EVProductModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      vehicleType: (json['vehicleType'] ?? '2-Wheeler').toString(),
      vehicleNoPlate: (json['vehicleNoPlate'] ?? '').toString(),
      companyName: (companyMap['companyName'] ?? 'EV').toString(),
      purchaseLocation: (companyMap['purchaseLocation'] ?? cityVal).toString(),
      sellerName: (companyMap['sellerName'] ?? 'Company Direct').toString(),
      headquarterLocation: (companyMap['headquarterLocation'] ?? '').toString(),
      purchasePrice: _parseInt(pricingMap['purchasePrice']),
      investmentAmount: _parseInt(pricingMap['investmentAmount']),
      investorReturnRate: _parseInt(pricingMap['investorReturnRate']),
      outboundRentalRate: _parseInt(pricingMap['outboundRentalRate']),
      status: (json['status'] ?? 'Active').toString(),
      vehicleModelName: (json['vehicleModelName'] ?? '').toString(),
      vehicleYearModel: _parseInt(json['vehicleYearModel'], fallback: 2026),
      vehicleMotorPowerKw: _parseDouble(json['vehicleMotorPowerKw']),
      vehicleServiceNo: _parseInt(json['vehicleServiceNo'], fallback: 1),
      batteryCapacityKwh: _parseDouble(json['batteryCapacityKwh']),
      rangeKm: _parseInt(json['rangeKm']),
      topSpeedKmph: _parseInt(json['topSpeedKmph']),
      vehicleImage: parsedImages,
      vehicleId: (json['vehicleId'] ?? '').toString(),
      tenureMonths: _parseInt(json['tenureMonths'], fallback: 36),
      clusterCity: cityVal,
      clusterState: (locMap['state'] ?? 'Uttar Pradesh').toString(),
      clusterZipCode: (locMap['zipCode'] ?? '202138').toString(),
      clusterStreetAddress:
          (locMap['streetAddress'] ?? 'MOH MALIPURA PAINTH MAIDAN KHAIR, 24')
              .toString(),
    );
  }

  static List<EVProductModel> dummyProducts() {
    final List<Map<String, dynamic>> rawList = [
      {
        '_id': '6addbadda6574ace355165e4',
        'vehicleType': '2-Wheeler',
        'vehicleNoPlate': '2254fg',
        'companyData': {
          'companyName': 'xyz',
          'purchaseLocation': 'noida',
          'sellerName': 'Company Direct',
          'headquarterLocation': '',
        },
        'pricing': {
          'purchasePrice': 70000,
          'investmentAmount': 50000,
          'investorReturnRate': 2500,
          'outboundRentalRate': 4000,
        },
        'status': 'Active',
        'vehicleModelName': 'balno',
        'vehicleYearModel': 2026,
        'vehicleMotorPowerKw': 6.2,
        'vehicleServiceNo': 1,
        'batteryCapacityKwh': 3.7,
        'rangeKm': 105,
        'topSpeedKmph': 85,
        'vehicleImage': [
          'https://5.imimg.com/data5/SELLER/Default/2022/1/LL/EY/AW/21369253/hero-destini-125cc-scooty.jpg',
          'https://tse2.mm.bing.net/th/id/OIP.2rHyt0irjyVvIe8RMWUEZwHaGW?r=0&pid=Api&h=220&P=0',
          'https://tse4.mm.bing.net/th/id/OIP._REB424hq76CWXsxtIT7dQHaFL?r=0&pid=Api&h=220&P=0',
        ],
        'vehicleId': 'EV-724EE501',
        'tenureMonths': 36,
        'vehicleClusterLocation': {
          'city': 'Aligarh',
          'state': 'Uttar Pradesh',
          'zipCode': '202138',
          'streetAddress': 'MOH MALIPURA PAINTH MAIDAN KHAIR, 24',
        },
      },
      {
        '_id': '6addbadda6574ace355165e7',
        'vehicleType': '2-Wheeler',
        'vehicleNoPlate': '5512ka',
        'companyData': {
          'companyName': 'EV Scooters',
          'purchaseLocation': 'noida',
          'sellerName': 'Company Direct',
          'headquarterLocation': '',
        },
        'pricing': {
          'purchasePrice': 130000,
          'investmentAmount': 45000,
          'investorReturnRate': 2300,
          'outboundRentalRate': 3700,
        },
        'status': 'Active',
        'vehicleModelName': 'EV Pro Gen 2',
        'vehicleYearModel': 2026,
        'vehicleMotorPowerKw': 11.0,
        'vehicleServiceNo': 2,
        'batteryCapacityKwh': 4.0,
        'rangeKm': 181,
        'topSpeedKmph': 120,
        'vehicleImage': [
          'https://tse2.mm.bing.net/th/id/OIP.2rHyt0irjyVvIe8RMWUEZwHaGW?r=0&pid=Api&h=220&P=0',
          'https://5.imimg.com/data5/SELLER/Default/2022/1/LL/EY/AW/21369253/hero-destini-125cc-scooty.jpg',
          'https://tse4.mm.bing.net/th/id/OIP._REB424hq76CWXsxtIT7dQHaFL?r=0&pid=Api&h=220&P=0',
        ],
        'vehicleId': 'EV-551BL22',
        'tenureMonths': 36,
        'vehicleClusterLocation': {
          'city': 'Noida',
          'state': 'Uttar Pradesh',
          'zipCode': '201301',
          'streetAddress': 'Sector 62 Institutional Area, Block C',
        },
      },
      {
        '_id': '6addbadda6574ace355165e8',
        'vehicleType': '2-Wheeler',
        'vehicleNoPlate': '7734dl',
        'companyData': {
          'companyName': 'EV Mobility',
          'purchaseLocation': 'delhi',
          'sellerName': 'Direct',
          'headquarterLocation': '',
        },
        'pricing': {
          'purchasePrice': 145000,
          'investmentAmount': 55000,
          'investorReturnRate': 2800,
          'outboundRentalRate': 4400,
        },
        'status': 'Active',
        'vehicleModelName': 'EV Aero 450X',
        'vehicleYearModel': 2026,
        'vehicleMotorPowerKw': 6.4,
        'vehicleServiceNo': 1,
        'batteryCapacityKwh': 3.7,
        'rangeKm': 115,
        'topSpeedKmph': 90,
        'vehicleImage': [
          'https://tse4.mm.bing.net/th/id/OIP._REB424hq76CWXsxtIT7dQHaFL?r=0&pid=Api&h=220&P=0',
          'https://5.imimg.com/data5/SELLER/Default/2022/1/LL/EY/AW/21369253/hero-destini-125cc-scooty.jpg',
          'https://tse2.mm.bing.net/th/id/OIP.2rHyt0irjyVvIe8RMWUEZwHaGW?r=0&pid=Api&h=220&P=0',
        ],
        'vehicleId': 'EV-884ND99',
        'tenureMonths': 36,
        'vehicleClusterLocation': {
          'city': 'New Delhi',
          'state': 'Delhi',
          'zipCode': '110037',
          'streetAddress': 'Aerocity Hospitality District, Plot 14',
        },
      },
    ];

    return rawList.map(EVProductModel.fromJson).toList();
  }

  static int _parseInt(dynamic val, {int fallback = 0}) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  static double _parseDouble(dynamic val, {double fallback = 0.0}) {
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? fallback;
    return fallback;
  }
}

class ReservedAssetItem {
  final EVProductModel product;
  int units;

  ReservedAssetItem({required this.product, this.units = 1});

  int get totalInvestment => product.investmentAmount * units;
  int get totalMonthlyReturn => product.investorReturnRate * units;
}
