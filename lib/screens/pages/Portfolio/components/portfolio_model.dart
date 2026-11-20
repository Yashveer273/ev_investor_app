import '../../Home/components/ev_product_model.dart';

/// 1. Deployed Capital Summary (Top Summary Cards)
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

/// 2. Date-Based Graph Point (Investment & Monthly Return)
class GraphPointModel {
  final String id;
  final String date; // YYYY-MM-DD
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
      id: (json['id'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      investedAmount: _toInt(json['investedAmount']),
      monthlyReturn: _toInt(json['monthlyReturn'] ?? json['revenueReturn']),
    );
  }
}

/// 3. Graph Data Container (6M & 12M slices)
class PortfolioGraphData {
  final List<GraphPointModel> points;

  const PortfolioGraphData({required this.points});

  List<GraphPointModel> get last6Months =>
      points.length <= 6 ? points : points.sublist(points.length - 6);

  List<GraphPointModel> get last12Months =>
      points.length <= 12 ? points : points.sublist(points.length - 12);

  factory PortfolioGraphData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawList = (json['points'] as List<dynamic>?) ?? [];
    return PortfolioGraphData(
      points: rawList
          .whereType()
          .map((e) => GraphPointModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// 4. Portfolio Asset Card Model (Lightweight List Item)
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
  final String purchaseDate; // YYYY-MM-DD

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
      if (url.trim().isNotEmpty) return url.trim();
    }
    return 'https://5.imimg.com/data5/SELLER/Default/2022/1/LL/EY/AW/21369253/hero-destini-125cc-scooty.jpg';
  }

  factory PortfolioAssetItemModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawImages =
        (json['vehicleImage'] as List<dynamic>?) ?? [];
    final List<String> parsedImages = rawImages
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return PortfolioAssetItemModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      investorId: (json['investorId'] ?? '').toString(),
      vehicleId: (json['vehicleId'] ?? '').toString(),
      storeId: (json['storeId'] ?? json['clusterId'] ?? '').toString(),
      vehicleNoPlate: (json['vehicleNoPlate'] ?? '').toString(),
      vehicleModelName: (json['vehicleModelName'] ?? '').toString(),
      vehicleYearModel: _toInt(json['vehicleYearModel'], fallback: 2026),
      companyName: (json['companyName'] ?? 'EV').toString(),
      vehicleImage: parsedImages,
      clusterCity: (json['clusterCity'] ?? 'Aligarh').toString(),
      clusterState: (json['clusterState'] ?? 'Uttar Pradesh').toString(),
      units: _toInt(json['units'], fallback: 1),
      investedAmount: _toInt(
        json['investedAmount'] ?? json['investedPrincipal'],
      ),
      monthlyReturn: _toInt(json['monthlyReturn']),
      status: (json['status'] ?? 'Active').toString(),
      isRenewable: json['isRenewable'] == true,
      purchaseDate: (json['purchaseDate'] ?? json['date'] ?? '').toString(),
    );
  }
}

/// 5. Portfolio Overview Response (With Fluctuations in Overall Graph)
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
    final List<dynamic> rawAssets =
        (json['portfolioAssets'] as List<dynamic>?) ?? [];

    return PortfolioOverviewResponse(
      deployedCapital: DeployedCapitalSummary.fromJson(
        Map<String, dynamic>.from(json['deployedCapital'] ?? {}),
      ),
      overallGraph: PortfolioGraphData.fromJson(
        Map<String, dynamic>.from(json['overallGraph'] ?? {}),
      ),
      portfolioAssets: rawAssets
          .whereType()
          .map(
            (e) =>
                PortfolioAssetItemModel.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }

  static PortfolioOverviewResponse dummyOverview() {
    return PortfolioOverviewResponse.fromJson({
      'deployedCapital': {
        'totalInvested': 150000,
        'thisMonthInvested': 50000,
        'totalMonthlyReturn': 7600,
        'thisMonthReturn': 2500,
        'activeAssetsCount': 3,
      },
      'overallGraph': {
        'points': [
          {
            'id': 'pt_20251205',
            'date': '2025-12-05',
            'investedAmount': 50000,
            'monthlyReturn': 2400,
          },
          {
            'id': 'pt_20260105',
            'date': '2026-01-05',
            'investedAmount': 50000,
            'monthlyReturn': 3150,
          },
          {
            'id': 'pt_20260205',
            'date': '2026-02-05',
            'investedAmount': 65000,
            'monthlyReturn': 2750,
          },
          {
            'id': 'pt_20260305',
            'date': '2026-03-05',
            'investedAmount': 95000,
            'monthlyReturn': 4900,
          },
          {
            'id': 'pt_20260405',
            'date': '2026-04-05',
            'investedAmount': 85000,
            'monthlyReturn': 4100,
          },
          {
            'id': 'pt_20260505',
            'date': '2026-05-05',
            'investedAmount': 110000,
            'monthlyReturn': 5850,
          },
          {
            'id': 'pt_20260605',
            'date': '2026-06-05',
            'investedAmount': 95000,
            'monthlyReturn': 4600,
          },
          {
            'id': 'pt_20260705',
            'date': '2026-07-05',
            'investedAmount': 125000,
            'monthlyReturn': 6400,
          },
          {
            'id': 'pt_20260805',
            'date': '2026-08-05',
            'investedAmount': 105000,
            'monthlyReturn': 5200,
          },
          {
            'id': 'pt_20260905',
            'date': '2026-09-05',
            'investedAmount': 135000,
            'monthlyReturn': 6950,
          },
          {
            'id': 'pt_20261005',
            'date': '2026-10-05',
            'investedAmount': 115000,
            'monthlyReturn': 5750,
          },
          {
            'id': 'pt_20261105',
            'date': '2026-11-05',
            'investedAmount': 150000,
            'monthlyReturn': 7600,
          },
        ],
      },
      'portfolioAssets': [
        {
          'id': '90128471',
          'investorId': '10018492',
          'vehicleId': 'EV-724EE501',
          'storeId': 'STR-1042',
          'vehicleNoPlate': '2254FG',
          'vehicleModelName': 'balno',
          'vehicleYearModel': 2026,
          'companyName': 'xyz',
          'vehicleImage': [
            'https://5.imimg.com/data5/SELLER/Default/2022/1/LL/EY/AW/21369253/hero-destini-125cc-scooty.jpg',
            'https://tse2.mm.bing.net/th/id/OIP.2rHyt0irjyVvIe8RMWUEZwHaGW?r=0&pid=Api&h=220&P=0',
            'https://tse4.mm.bing.net/th/id/OIP._REB424hq76CWXsxtIT7dQHaFL?r=0&pid=Api&h=220&P=0',
          ],
          'clusterCity': 'Aligarh',
          'clusterState': 'Uttar Pradesh',
          'units': 1,
          'investedAmount': 50000,
          'monthlyReturn': 2500,
          'status': 'Active',
          'isRenewable': true,
          'purchaseDate': '2026-02-10',
        },
        {
          'id': '90241835',
          'investorId': '10018492',
          'vehicleId': 'EV-551BL22',
          'storeId': 'STR-1088',
          'vehicleNoPlate': '5512KA',
          'vehicleModelName': 'EV Pro Gen 2',
          'vehicleYearModel': 2026,
          'companyName': 'EV Scooters',
          'vehicleImage': [
            'https://tse2.mm.bing.net/th/id/OIP.2rHyt0irjyVvIe8RMWUEZwHaGW?r=0&pid=Api&h=220&P=0',
            'https://5.imimg.com/data5/SELLER/Default/2022/1/LL/EY/AW/21369253/hero-destini-125cc-scooty.jpg',
            'https://tse4.mm.bing.net/th/id/OIP._REB424hq76CWXsxtIT7dQHaFL?r=0&pid=Api&h=220&P=0',
          ],
          'clusterCity': 'Noida',
          'clusterState': 'Uttar Pradesh',
          'units': 1,
          'investedAmount': 45000,
          'monthlyReturn': 2300,
          'status': 'Expiring Soon',
          'isRenewable': true,
          'purchaseDate': '2026-03-01',
        },
        {
          'id': '90376194',
          'investorId': '10018492',
          'vehicleId': 'EV-884ND99',
          'storeId': 'STR-1105',
          'vehicleNoPlate': '7734DL',
          'vehicleModelName': 'EV Aero 450X',
          'vehicleYearModel': 2026,
          'companyName': 'EV Mobility',
          'vehicleImage': [
            'https://tse4.mm.bing.net/th/id/OIP._REB424hq76CWXsxtIT7dQHaFL?r=0&pid=Api&h=220&P=0',
            'https://5.imimg.com/data5/SELLER/Default/2022/1/LL/EY/AW/21369253/hero-destini-125cc-scooty.jpg',
            'https://tse2.mm.bing.net/th/id/OIP.2rHyt0irjyVvIe8RMWUEZwHaGW?r=0&pid=Api&h=220&P=0',
          ],
          'clusterCity': 'New Delhi',
          'clusterState': 'Delhi',
          'units': 1,
          'investedAmount': 55000,
          'monthlyReturn': 2800,
          'status': 'Active',
          'isRenewable': false,
          'purchaseDate': '2026-10-12',
        },
      ],
    });
  }
}

/// 6. Asset Summary Block
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
      purchaseDate: (json['purchaseDate'] ?? '').toString(),
      monthlyReturn: _toInt(json['monthlyReturn']),
      nextReturnAmount: _toInt(
        json['nextReturnAmount'] ?? json['nextRevenueAmount'],
      ),
      nextReturnDate: (json['nextReturnDate'] ?? json['nextRevenueDate'] ?? '')
          .toString(),
    );
  }
}

/// 7. Asset Renewal Block
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
    final int tenure = _toInt(json['tenureMonths'], fallback: 36);
    final int completed = _toInt(json['completedMonths']);
    final int remaining = json['remainingMonths'] != null
        ? _toInt(json['remainingMonths'])
        : (tenure - completed).clamp(0, tenure);

    return AssetRenewalModel(
      tenureMonths: tenure,
      completedMonths: completed,
      remainingMonths: remaining,
      isRenewable: json['isRenewable'] != false,
      renewalBonusPercent: _toInt(json['renewalBonusPercent'], fallback: 2),
      renewedDate: json['renewedDate']?.toString(),
    );
  }
}

/// 8. Portfolio Asset Detail Model (With Fluctuations in Particular Asset Graph)
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
    final Map<String, dynamic> productJson = Map<String, dynamic>.from(
      json['productSpecs'] ?? {},
    );

    return PortfolioAssetDetailModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      investorId: (json['investorId'] ?? '').toString(),
      vehicleId: (json['vehicleId'] ?? '').toString(),
      storeId: (json['storeId'] ?? json['clusterId'] ?? '').toString(),
      status: (json['status'] ?? 'Active').toString(),
      units: _toInt(json['units'], fallback: 1),
      assetSummary: AssetSummaryModel.fromJson(
        Map<String, dynamic>.from(
          json['assetSummary'] ?? json['assetFinancials'] ?? {},
        ),
      ),
      renewal: AssetRenewalModel.fromJson(
        Map<String, dynamic>.from(json['renewal'] ?? {}),
      ),
      assetGraph: PortfolioGraphData.fromJson(
        Map<String, dynamic>.from(json['assetGraph'] ?? json['evGraph'] ?? {}),
      ),
      productSpecs: EVProductModel.fromJson(productJson),
    );
  }

  static PortfolioAssetDetailModel dummyDetailByAsset(
    PortfolioAssetItemModel asset,
  ) {
    final List<EVProductModel> dummyList = EVProductModel.dummyProducts();
    final EVProductModel matchedProduct = dummyList.firstWhere(
      (p) => p.vehicleId == asset.vehicleId,
      orElse: () => EVProductModel(
        id: asset.id,
        vehicleType: '2-Wheeler',
        vehicleNoPlate: asset.vehicleNoPlate,
        companyName: asset.companyName,
        purchaseLocation: asset.clusterCity,
        sellerName: 'Company Direct',
        headquarterLocation: '',
        purchasePrice: asset.investedAmount + 20000,
        investmentAmount: asset.investedAmount,
        investorReturnRate: asset.monthlyReturn,
        outboundRentalRate: asset.monthlyReturn + 1500,
        status: asset.status,
        vehicleModelName: asset.vehicleModelName,
        vehicleYearModel: asset.vehicleYearModel,
        vehicleMotorPowerKw: 6.2,
        vehicleServiceNo: 1,
        batteryCapacityKwh: 3.7,
        rangeKm: 110,
        topSpeedKmph: 85,
        vehicleImage: asset.vehicleImage,
        vehicleId: asset.vehicleId,
        clusterCity: asset.clusterCity,
        clusterState: asset.clusterState,
      ),
    );

    final int mRet = asset.monthlyReturn;
    final int inv = asset.investedAmount;
    final int completed = asset.status == 'Expiring Soon' ? 34 : 9;

    // 12-month fluctuation multipliers so both 6M and 12M curves show real movement
    const List<double> returnFactors = [
      0.88,
      1.06,
      0.94,
      1.12,
      0.91,
      1.15,
      0.96,
      1.10,
      0.92,
      1.08,
      0.97,
      1.00,
    ];
    const List<double> investFactors = [
      0.90,
      1.00,
      0.95,
      1.08,
      0.94,
      1.12,
      0.98,
      1.06,
      0.93,
      1.05,
      0.97,
      1.00,
    ];
    const List<String> dates = [
      '2025-12-05',
      '2026-01-05',
      '2026-02-05',
      '2026-03-05',
      '2026-04-05',
      '2026-05-05',
      '2026-06-05',
      '2026-07-05',
      '2026-08-05',
      '2026-09-05',
      '2026-10-05',
      '2026-11-05',
    ];

    final List<GraphPointModel> fluctuatingPoints = List.generate(12, (i) {
      return GraphPointModel(
        id: 'as_${dates[i].replaceAll('-', '')}',
        date: dates[i],
        investedAmount: (inv * investFactors[i]).round(),
        monthlyReturn: (mRet * returnFactors[i]).round(),
      );
    });

    return PortfolioAssetDetailModel(
      id: asset.id,
      investorId: asset.investorId,
      vehicleId: asset.vehicleId,
      storeId: asset.storeId,
      status: asset.status,
      units: asset.units,
      assetSummary: AssetSummaryModel(
        investedAmount: inv,
        purchaseDate: asset.purchaseDate,
        monthlyReturn: mRet,
        nextReturnAmount: mRet,
        nextReturnDate: '2026-12-05',
      ),
      renewal: AssetRenewalModel(
        tenureMonths: 36,
        completedMonths: completed,
        remainingMonths: 36 - completed,
        isRenewable: asset.isRenewable,
        renewalBonusPercent: 2,
      ),
      assetGraph: PortfolioGraphData(points: fluctuatingPoints),
      productSpecs: matchedProduct,
    );
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
