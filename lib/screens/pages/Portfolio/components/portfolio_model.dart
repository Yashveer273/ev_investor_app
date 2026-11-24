import '../../Home/components/ev_product_model.dart';

/// =====================================================
/// COMMON PARSING HELPERS
/// =====================================================

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  }

  return fallback;
}

String _toString(dynamic value, {String fallback = ''}) {
  return value == null ? fallback : value.toString();
}

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;

  if (value is num) return value != 0;

  if (value is String) {
    final normalized = value.toLowerCase().trim();

    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }

  return fallback;
}

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

List<dynamic> _toList(dynamic value) {
  return value is List ? value : <dynamic>[];
}

List<String> _toStringList(dynamic value) {
  return _toList(value)
      .map((item) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);

          return _toString(
            map['url'] ?? map['imageUrl'] ?? map['src'] ?? map['path'],
          ).trim();
        }

        return _toString(item).trim();
      })
      .where((item) => item.isNotEmpty)
      .toList();
}

/// =====================================================
/// 1. DEPLOYED CAPITAL SUMMARY
/// =====================================================

class DeployedCapitalSummary {
  final int totalInvested;
  final int thisMonthInvested;
  final int totalMonthlyReturn;
  final int thisMonthReturn;
  final int activeAssetsCount;

  const DeployedCapitalSummary({
    required this.totalInvested,
    required this.thisMonthInvested,
    required this.totalMonthlyReturn,
    required this.thisMonthReturn,
    required this.activeAssetsCount,
  });

  factory DeployedCapitalSummary.fromJson(Map<String, dynamic> json) {
    return DeployedCapitalSummary(
      totalInvested: _toInt(json['totalInvested']),
      thisMonthInvested: _toInt(json['thisMonthInvested']),
      totalMonthlyReturn: _toInt(json['totalMonthlyReturn']),
      thisMonthReturn: _toInt(json['thisMonthReturn']),
      activeAssetsCount: _toInt(json['activeAssetsCount']),
    );
  }
}

/// =====================================================
/// 2. GRAPH POINT MODEL
/// =====================================================

class GraphPointModel {
  final String id;
  final String date;
  final int investedAmount;
  final int monthlyReturn;

  const GraphPointModel({
    required this.id,
    required this.date,
    required this.investedAmount,
    required this.monthlyReturn,
  });

  String get shortMonthLabel {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final DateTime? parsed = DateTime.tryParse(date);

    if (parsed != null && parsed.month >= 1 && parsed.month <= 12) {
      return months[parsed.month - 1];
    }

    return date;
  }

  factory GraphPointModel.fromJson(Map<String, dynamic> json) {
    return GraphPointModel(
      id: _toString(json['id'] ?? json['_id']),
      date: _toString(json['date']),
      investedAmount: _toInt(
        json['investedAmount'] ?? json['investmentAmount'],
      ),
      monthlyReturn: _toInt(json['monthlyReturn'] ?? json['revenueReturn']),
    );
  }
}

/// =====================================================
/// 3. PORTFOLIO GRAPH DATA
/// =====================================================

class PortfolioGraphData {
  final List<GraphPointModel> points;

  const PortfolioGraphData({required this.points});

  List<GraphPointModel> get last6Months {
    return points.length <= 6 ? points : points.sublist(points.length - 6);
  }

  List<GraphPointModel> get last12Months {
    return points.length <= 12 ? points : points.sublist(points.length - 12);
  }

  factory PortfolioGraphData.fromJson(Map<String, dynamic> json) {
    final rawList = _toList(json['points'] ?? json['data']);

    return PortfolioGraphData(
      points: rawList
          .whereType<Map>()
          .map(
            (item) => GraphPointModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

/// =====================================================
/// 4. PORTFOLIO ASSET ITEM MODEL
/// =====================================================

class PortfolioAssetItemModel {
  final String id;
  final String investorId;
  final String vehicleId;
  final String storeId;
  final String vehicleNoPlate;
  final String vehicleModelName;
  final int vehicleYearModel;
  final String companyName;
  final List<String> vehicleImage;
  final String clusterCity;
  final String clusterState;
  final int units;
  final int investedAmount;
  final int monthlyReturn;
  final String status;
  final bool isRenewable;
  final String purchaseDate;

  const PortfolioAssetItemModel({
    required this.id,
    required this.investorId,
    required this.vehicleId,
    required this.storeId,
    required this.vehicleNoPlate,
    required this.vehicleModelName,
    required this.vehicleYearModel,
    required this.companyName,
    required this.vehicleImage,
    required this.clusterCity,
    required this.clusterState,
    required this.units,
    required this.investedAmount,
    required this.monthlyReturn,
    required this.status,
    required this.isRenewable,
    required this.purchaseDate,
  });

  String get primaryImageUrl {
    for (final String url in vehicleImage) {
      if (url.trim().isNotEmpty) {
        return url.trim();
      }
    }

    return '';
  }

  factory PortfolioAssetItemModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> location = _toMap(
      json['vehicleClusterLocation'],
    );

    return PortfolioAssetItemModel(
      id: _toString(json['id'] ?? json['_id']),
      investorId: _toString(json['investorId']),
      vehicleId: _toString(json['vehicleId']),
      storeId: _toString(
        json['storeId'] ?? json['clusterId'] ?? json['vehicleClusterId'],
      ),
      vehicleNoPlate: _toString(json['vehicleNoPlate']),
      vehicleModelName: _toString(json['vehicleModelName']),
      vehicleYearModel: _toInt(json['vehicleYearModel']),
      companyName: _toString(json['companyName']),
      vehicleImage: _toStringList(
        json['vehicleImage'] ?? json['vehicleImages'],
      ),
      clusterCity: _toString(json['clusterCity'] ?? location['city']),
      clusterState: _toString(json['clusterState'] ?? location['state']),
      units: _toInt(json['units']),
      investedAmount: _toInt(
        json['investedAmount'] ?? json['investedPrincipal'],
      ),
      monthlyReturn: _toInt(json['monthlyReturn'] ?? json['revenueReturn']),
      status: _toString(json['status']),
      isRenewable: _toBool(json['isRenewable']),
      purchaseDate: _toString(json['purchaseDate'] ?? json['date']),
    );
  }
}

/// =====================================================
/// 5. PORTFOLIO OVERVIEW RESPONSE
/// =====================================================

class PortfolioOverviewResponse {
  final DeployedCapitalSummary deployedCapital;
  final PortfolioGraphData overallGraph;
  final List<PortfolioAssetItemModel> portfolioAssets;

  const PortfolioOverviewResponse({
    required this.deployedCapital,
    required this.overallGraph,
    required this.portfolioAssets,
  });

  factory PortfolioOverviewResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> deployedJson = _toMap(json['deployedCapital']);

    final Map<String, dynamic> graphJson = _toMap(json['overallGraph']);

    final List<dynamic> rawAssets = _toList(
      json['portfolioAssets'] ?? json['assets'],
    );

    return PortfolioOverviewResponse(
      deployedCapital: DeployedCapitalSummary.fromJson(deployedJson),
      overallGraph: PortfolioGraphData.fromJson(graphJson),
      portfolioAssets: rawAssets
          .whereType<Map>()
          .map(
            (item) => PortfolioAssetItemModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

/// =====================================================
/// 6. ASSET SUMMARY MODEL
/// =====================================================

class AssetSummaryModel {
  final int investedAmount;
  final String purchaseDate;
  final int monthlyReturn;
  final int nextReturnAmount;
  final String nextReturnDate;

  const AssetSummaryModel({
    required this.investedAmount,
    required this.purchaseDate,
    required this.monthlyReturn,
    required this.nextReturnAmount,
    required this.nextReturnDate,
  });

  factory AssetSummaryModel.fromJson(Map<String, dynamic> json) {
    return AssetSummaryModel(
      investedAmount: _toInt(
        json['investedAmount'] ?? json['investmentPrincipal'],
      ),
      purchaseDate: _toString(json['purchaseDate']),
      monthlyReturn: _toInt(json['monthlyReturn']),
      nextReturnAmount: _toInt(
        json['nextReturnAmount'] ?? json['nextRevenueAmount'],
      ),
      nextReturnDate: _toString(
        json['nextReturnDate'] ?? json['nextRevenueDate'],
      ),
    );
  }
}

/// =====================================================
/// 7. ASSET RENEWAL MODEL
/// =====================================================

class AssetRenewalModel {
  final int tenureMonths;
  final int completedMonths;
  final int remainingMonths;
  final bool isRenewable;
  final int renewalBonusPercent;
  final String? renewedDate;

  const AssetRenewalModel({
    required this.tenureMonths,
    required this.completedMonths,
    required this.remainingMonths,
    required this.isRenewable,
    required this.renewalBonusPercent,
    this.renewedDate,
  });

  factory AssetRenewalModel.fromJson(Map<String, dynamic> json) {
    final int tenure = _toInt(json['tenureMonths']);
    final int completed = _toInt(json['completedMonths']);

    final int remaining = json['remainingMonths'] != null
        ? _toInt(json['remainingMonths'])
        : (tenure - completed).clamp(0, tenure);

    return AssetRenewalModel(
      tenureMonths: tenure,
      completedMonths: completed,
      remainingMonths: remaining,
      isRenewable: _toBool(json['isRenewable']),
      renewalBonusPercent: _toInt(json['renewalBonusPercent']),
      renewedDate: json['renewedDate']?.toString(),
    );
  }
}

/// =====================================================
/// 8. PORTFOLIO ASSET DETAIL MODEL
/// =====================================================

class PortfolioAssetDetailModel {
  final String id;
  final String investorId;
  final String vehicleId;
  final String storeId;
  final String status;
  final int units;
  final AssetSummaryModel assetSummary;
  final AssetRenewalModel renewal;
  final PortfolioGraphData assetGraph;
  final EVProductModel productSpecs;

  const PortfolioAssetDetailModel({
    required this.id,
    required this.investorId,
    required this.vehicleId,
    required this.storeId,
    required this.status,
    required this.units,
    required this.assetSummary,
    required this.renewal,
    required this.assetGraph,
    required this.productSpecs,
  });

  factory PortfolioAssetDetailModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> productJson = _toMap(
      json['productSpecs'] ?? json['vehicle'] ?? json['product'],
    );

    final Map<String, dynamic> summaryJson = _toMap(
      json['assetSummary'] ?? json['assetFinancials'],
    );

    final Map<String, dynamic> renewalJson = _toMap(json['renewal']);

    final Map<String, dynamic> graphJson = _toMap(
      json['assetGraph'] ?? json['evGraph'],
    );

    return PortfolioAssetDetailModel(
      id: _toString(json['id'] ?? json['_id']),
      investorId: _toString(json['investorId']),
      vehicleId: _toString(json['vehicleId']),
      storeId: _toString(
        json['storeId'] ?? json['clusterId'] ?? json['vehicleClusterId'],
      ),
      status: _toString(json['status']),
      units: _toInt(json['units']),
      assetSummary: AssetSummaryModel.fromJson(summaryJson),
      renewal: AssetRenewalModel.fromJson(renewalJson),
      assetGraph: PortfolioGraphData.fromJson(graphJson),
      productSpecs: EVProductModel.fromJson(productJson),
    );
  }
}

/// =====================================================
/// 9. DUMMY PORTFOLIO OVERVIEW DATA
/// =====================================================

final Map<String, dynamic> portfolioOverviewDummyJson = {
  'deployedCapital': {
    'totalInvested': 500000,
    'thisMonthInvested': 50000,
    'totalMonthlyReturn': 25000,
    'thisMonthReturn': 12500,
    'activeAssetsCount': 3,
  },
  'overallGraph': {
    'points': [
      {
        'id': 'graph001',
        'date': '2026-01-01',
        'investedAmount': 100000,
        'monthlyReturn': 5000,
      },
      {
        'id': 'graph002',
        'date': '2026-02-01',
        'investedAmount': 150000,
        'monthlyReturn': 7500,
      },
      {
        'id': 'graph003',
        'date': '2026-03-01',
        'investedAmount': 200000,
        'monthlyReturn': 10000,
      },
      {
        'id': 'graph004',
        'date': '2026-04-01',
        'investedAmount': 300000,
        'monthlyReturn': 15000,
      },
      {
        'id': 'graph005',
        'date': '2026-05-01',
        'investedAmount': 400000,
        'monthlyReturn': 20000,
      },
      {
        'id': 'graph006',
        'date': '2026-06-01',
        'investedAmount': 500000,
        'monthlyReturn': 25000,
      },
    ],
  },
  'portfolioAssets': [
    {
      '_id': 'asset001',
      'investorId': 'investor001',
      'vehicleId': 'vehicle001',
      'storeId': 'store001',
      'vehicleNoPlate': 'UP16AB1234',
      'vehicleModelName': 'Electric Scooter',
      'vehicleYearModel': 2025,
      'companyName': 'EV Mobility Pvt Ltd',
      'vehicleImage': [],
      'clusterCity': 'Noida',
      'clusterState': 'Uttar Pradesh',
      'units': 2,
      'investedAmount': 200000,
      'monthlyReturn': 10000,
      'status': 'Active',
      'isRenewable': true,
      'purchaseDate': '2026-01-15',
    },
    {
      '_id': 'asset002',
      'investorId': 'investor001',
      'vehicleId': 'vehicle002',
      'storeId': 'store002',
      'vehicleNoPlate': 'DL8CAF5678',
      'vehicleModelName': 'Electric Bike',
      'vehicleYearModel': 2025,
      'companyName': 'Green EV Motors',
      'vehicleImage': [],
      'clusterCity': 'Delhi',
      'clusterState': 'Delhi',
      'units': 1,
      'investedAmount': 150000,
      'monthlyReturn': 7500,
      'status': 'Active',
      'isRenewable': true,
      'purchaseDate': '2026-02-10',
    },
    {
      '_id': 'asset003',
      'investorId': 'investor001',
      'vehicleId': 'vehicle003',
      'storeId': 'store003',
      'vehicleNoPlate': 'HR26DE9012',
      'vehicleModelName': 'Electric Delivery Scooter',
      'vehicleYearModel': 2026,
      'companyName': 'EV Mobility Pvt Ltd',
      'vehicleImage': [],
      'clusterCity': 'Gurugram',
      'clusterState': 'Haryana',
      'units': 2,
      'investedAmount': 150000,
      'monthlyReturn': 7500,
      'status': 'Active',
      'isRenewable': false,
      'purchaseDate': '2026-03-05',
    },
  ],
};

/// Ready-to-use typed portfolio overview dummy object.
final PortfolioOverviewResponse portfolioOverviewDummy =
    PortfolioOverviewResponse.fromJson(portfolioOverviewDummyJson);

/// =====================================================
/// 10. DUMMY PORTFOLIO ASSET DETAIL DATA
/// =====================================================

final Map<String, dynamic> portfolioAssetDetailDummyJson = {
  '_id': 'asset001',
  'investorId': 'investor001',
  'vehicleId': 'vehicle001',
  'storeId': 'store001',
  'status': 'Active',
  'units': 2,
  'assetSummary': {
    'investedAmount': 200000,
    'purchaseDate': '2026-01-15',
    'monthlyReturn': 10000,
    'nextReturnAmount': 10000,
    'nextReturnDate': '2026-12-01',
  },
  'renewal': {
    'tenureMonths': 24,
    'completedMonths': 10,
    'remainingMonths': 14,
    'isRenewable': true,
    'renewalBonusPercent': 5,
    'renewedDate': null,
  },
  'assetGraph': {
    'points': [
      {
        'id': 'assetGraph001',
        'date': '2026-01-01',
        'investedAmount': 200000,
        'monthlyReturn': 10000,
      },
      {
        'id': 'assetGraph002',
        'date': '2026-02-01',
        'investedAmount': 200000,
        'monthlyReturn': 10000,
      },
      {
        'id': 'assetGraph003',
        'date': '2026-03-01',
        'investedAmount': 200000,
        'monthlyReturn': 10000,
      },
      {
        'id': 'assetGraph004',
        'date': '2026-04-01',
        'investedAmount': 200000,
        'monthlyReturn': 10000,
      },
      {
        'id': 'assetGraph005',
        'date': '2026-05-01',
        'investedAmount': 200000,
        'monthlyReturn': 10000,
      },
      {
        'id': 'assetGraph006',
        'date': '2026-06-01',
        'investedAmount': 200000,
        'monthlyReturn': 10000,
      },
    ],
  },
  // Fill this map using the exact fields expected by EVProductModel.fromJson.
  'productSpecs': {},
};

/// Create this detail model after adding the required EVProductModel fields
/// inside productSpecs above. An empty map may not satisfy EVProductModel.
// final PortfolioAssetDetailModel portfolioAssetDetailDummy =
//     PortfolioAssetDetailModel.fromJson(portfolioAssetDetailDummyJson);
