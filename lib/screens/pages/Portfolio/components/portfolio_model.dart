/// =============================================================
/// PORTFOLIO MODEL
///
/// Based on MongoDB portfolio response.
/// Independent model - No EVProductModel dependency.
/// No dummy data.
///
/// Supports:
/// 1. Overall portfolio monthly investment and return
/// 2. Particular EV monthly investment and return
/// 3. Multiple investment entries per asset
/// 4. Next reinvestment reminder (single editable date)
/// 5. Return payment history
/// 6. 6 and 12 month graph data
/// 7. Zero-value months
///
/// Graph rules:
/// - Investment: investmentHistory with Disbursed status
/// - Legacy fallback: investmentFlow only when history is empty
/// - Return: returnSettlements with Settled or Credited status
/// - Pending and Failed entries are excluded
/// - Overall graph from API should represent ALL assets
/// =============================================================

// =============================================================
// COMMON PARSING HELPERS
// =============================================================

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  if (value is String) {
    final String cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '').trim();

    if (cleaned.isEmpty) return fallback;

    return int.tryParse(cleaned) ??
        double.tryParse(cleaned)?.round() ??
        fallback;
  }

  return fallback;
}

double _toDouble(dynamic value, {double fallback = 0.0}) {
  if (value is num) return value.toDouble();

  if (value is String) {
    final String cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '').trim();

    return double.tryParse(cleaned) ?? fallback;
  }

  return fallback;
}

String _toString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;

  if (value is Map) {
    if (value.containsKey(r'$oid')) {
      return value[r'$oid'].toString();
    }

    if (value.containsKey(r'$date')) {
      return value[r'$date'].toString();
    }
  }

  return value.toString();
}

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  if (value is String) {
    final String normalized = value.toLowerCase().trim();

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
      .map((dynamic item) {
        if (item is Map) {
          final Map<String, dynamic> map = _toMap(item);

          return _toString(
            map['url'] ?? map['imageUrl'] ?? map['src'] ?? map['path'],
          ).trim();
        }

        return _toString(item).trim();
      })
      .where((String item) => item.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> _toMapList(dynamic value) {
  return _toList(
    value,
  ).whereType<Map>().map((dynamic item) => _toMap(item)).toList();
}

String _firstString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final String key in keys) {
    final String value = _toString(json[key]).trim();

    if (value.isNotEmpty) return value;
  }

  return fallback;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;

  if (value is DateTime) return value;

  if (value is Map && value.containsKey(r'$date')) {
    return _parseDate(value[r'$date']);
  }

  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }

  final String dateString = value.toString().trim();

  if (dateString.isEmpty) return null;

  return DateTime.tryParse(dateString);
}

String _monthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

String _monthDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-01';
}

String _normalizeStatus(String value) {
  return value.trim().toLowerCase();
}

// =============================================================
// 1. DEPLOYED CAPITAL SUMMARY
// =============================================================

class DeployedCapitalSummary {
  final int totalInvested;
  final int thisMonthInvested;
  final int totalMonthlyReturn;
  final int thisMonthReturn;
  final int totalReturnedAmount;
  final int totalUnits;
  final int activeAssetsCount;

  const DeployedCapitalSummary({
    required this.totalInvested,
    required this.thisMonthInvested,
    required this.totalMonthlyReturn,
    required this.thisMonthReturn,
    required this.activeAssetsCount,
    this.totalReturnedAmount = 0,
    this.totalUnits = 0,
  });

  factory DeployedCapitalSummary.fromJson(
    Map<String, dynamic> json, {
    int calculatedActiveAssets = 0,
  }) {
    return DeployedCapitalSummary(
      totalInvested: _toInt(
        json['totalInvestedAmount'] ?? json['totalInvested'],
      ),
      thisMonthInvested: _toInt(json['thisMonthInvested']),
      totalMonthlyReturn: _toInt(json['totalMonthlyReturn']),
      thisMonthReturn: _toInt(json['thisMonthReturn']),
      totalReturnedAmount: _toInt(json['totalReturnedAmount']),
      totalUnits: _toInt(json['totalUnits']),
      activeAssetsCount: _toInt(
        json['activeAssetsCount'],
        fallback: calculatedActiveAssets,
      ),
    );
  }
}

// =============================================================
// 2. LEGACY INVESTMENT FLOW MODEL
// =============================================================

class InvestmentFlowModel {
  final bool isInvestmentDisbursed;
  final String investmentStatus;
  final int investedAmount;
  final String investmentDate;
  final String disbursedAt;
  final String referenceId;

  const InvestmentFlowModel({
    required this.isInvestmentDisbursed,
    required this.investmentStatus,
    required this.investedAmount,
    required this.investmentDate,
    required this.disbursedAt,
    required this.referenceId,
  });

  bool get isEligibleForGraph {
    final String normalizedStatus = _normalizeStatus(investmentStatus);

    return normalizedStatus == 'disbursed' ||
        (isInvestmentDisbursed && normalizedStatus != 'failed');
  }

  DateTime? get graphInvestmentDate {
    return _parseDate(investmentDate.isNotEmpty ? investmentDate : disbursedAt);
  }

  factory InvestmentFlowModel.fromJson(Map<String, dynamic> json) {
    return InvestmentFlowModel(
      isInvestmentDisbursed: _toBool(json['isInvestmentDisbursed']),
      investmentStatus: _toString(json['investmentStatus']),
      investedAmount: _toInt(json['investedAmount']),
      investmentDate: _firstString(json, [
        'investmentDate',
        'date',
        'purchaseDate',
      ]),
      disbursedAt: _toString(json['disbursedAt']),
      referenceId: _toString(json['referenceId']),
    );
  }
}

// =============================================================
// 3. INVESTMENT HISTORY MODEL
// =============================================================

class InvestmentHistoryModel {
  final String investmentId;
  final String date;
  final int amount;
  final String status;
  final String referenceId;
  final String note;

  const InvestmentHistoryModel({
    required this.investmentId,
    required this.date,
    required this.amount,
    required this.status,
    required this.referenceId,
    required this.note,
  });

  DateTime? get parsedDate => _parseDate(date);

  bool get isEligibleForGraph {
    return _normalizeStatus(status) == 'disbursed' && amount > 0;
  }

  factory InvestmentHistoryModel.fromJson(Map<String, dynamic> json) {
    return InvestmentHistoryModel(
      investmentId: _firstString(json, ['investmentId', '_id', 'id']),
      date: _firstString(json, [
        'date',
        'investmentDate',
        'disbursedAt',
        'createdAt',
      ]),
      amount: _toInt(json['amount'] ?? json['investedAmount']),
      status: _toString(json['status'] ?? json['investmentStatus']),
      referenceId: _toString(json['referenceId']),
      note: _toString(json['note'] ?? json['remarks']),
    );
  }
}

// =============================================================
// 4. NEXT REINVESTMENT REMINDER MODEL
// =============================================================

class NextPaymentModel {
  final String date;
  final int amount;
  final String status;
  final String note;
  final String updatedBy;
  final String updatedAt;

  const NextPaymentModel({
    required this.date,
    required this.amount,
    required this.status,
    required this.note,
    required this.updatedBy,
    required this.updatedAt,
  });

  DateTime? get parsedDate => _parseDate(date);

  bool get isPlanned {
    return _normalizeStatus(status) == 'planned';
  }

  bool get isPaid {
    return _normalizeStatus(status) == 'paid';
  }

  bool get isOverdue {
    if (_normalizeStatus(status) == 'overdue') return true;

    if (!isPlanned) return false;

    final DateTime? paymentDate = parsedDate;

    if (paymentDate == null) return false;

    final DateTime today = DateTime.now();

    return DateTime(
      paymentDate.year,
      paymentDate.month,
      paymentDate.day,
    ).isBefore(DateTime(today.year, today.month, today.day));
  }

  factory NextPaymentModel.fromJson(Map<String, dynamic> json) {
    return NextPaymentModel(
      date: _firstString(json, [
        'date',
        'nextReinvestmentDate',
        'nextPaymentDate',
        'nextReturnDate',
      ]),
      amount: _toInt(
        json['amount'] ??
            json['expectedAmount'] ??
            json['nextReinvestmentAmount'] ??
            json['nextReturnAmount'],
      ),
      status: _toString(json['status'], fallback: 'Planned'),
      note: _toString(json['note']),
      updatedBy: _toString(json['updatedBy']),
      updatedAt: _toString(json['updatedAt']),
    );
  }

  factory NextPaymentModel.empty() {
    return const NextPaymentModel(
      date: '',
      amount: 0,
      status: '',
      note: '',
      updatedBy: '',
      updatedAt: '',
    );
  }
}

// =============================================================
// 5. ASSET SUMMARY MODEL
// =============================================================

class AssetSummaryModel {
  final int investedAmount;
  final String purchaseDate;
  final int monthlyReturn;
  final int totalReturnedAmount;
  final String? lastReturnDate;
  final int nextReturnAmount;
  final String nextReturnDate;

  const AssetSummaryModel({
    required this.investedAmount,
    required this.purchaseDate,
    required this.monthlyReturn,
    required this.totalReturnedAmount,
    this.lastReturnDate,
    required this.nextReturnAmount,
    required this.nextReturnDate,
  });

  factory AssetSummaryModel.fromJson(Map<String, dynamic> json) {
    final String lastDate = _toString(json['lastReturnDate']);

    return AssetSummaryModel(
      investedAmount: _toInt(json['investedAmount']),
      purchaseDate: _toString(json['purchaseDate']),
      monthlyReturn: _toInt(json['monthlyReturn']),
      totalReturnedAmount: _toInt(json['totalReturnedAmount']),
      lastReturnDate: lastDate.isEmpty ? null : lastDate,
      nextReturnAmount: _toInt(
        json['nextReinvestmentAmount'] ?? json['nextReturnAmount'],
      ),
      nextReturnDate: _firstString(json, [
        'nextReinvestmentDate',
        'nextReturnDate',
      ]),
    );
  }
}

// =============================================================
// 6. ASSET RENEWAL MODEL
// No fixed tenure or duration fields.
// =============================================================

class AssetRenewalModel {
  final bool isRenewable;
  final String? lastReinvestedDate;
  final String? renewedDate;
  final int totalReinvestedAmount;

  const AssetRenewalModel({
    required this.isRenewable,
    this.lastReinvestedDate,
    this.renewedDate,
    this.totalReinvestedAmount = 0,
  });

  factory AssetRenewalModel.fromJson(Map<String, dynamic> json) {
    final String lastReinvested = _toString(json['lastReinvestedDate']);

    final String renewed = _toString(json['renewedDate']);

    return AssetRenewalModel(
      isRenewable: _toBool(json['isRenewable']),
      lastReinvestedDate: lastReinvested.isEmpty ? null : lastReinvested,
      renewedDate: renewed.isEmpty ? null : renewed,
      totalReinvestedAmount: _toInt(json['totalReinvestedAmount']),
    );
  }
}

// =============================================================
// 7. RETURN SETTLEMENT MODEL
// =============================================================

class ReturnSettlementModel {
  final String settlementId;
  final String date;
  final int amount;
  final String status;
  final String note;
  final String settledBy;

  const ReturnSettlementModel({
    required this.settlementId,
    required this.date,
    required this.amount,
    required this.status,
    required this.note,
    this.settledBy = '',
  });

  bool get isEligibleForGraph {
    final String normalizedStatus = _normalizeStatus(status);

    return (normalizedStatus == 'settled' || normalizedStatus == 'credited') &&
        amount > 0;
  }

  bool get isPending {
    return _normalizeStatus(status) == 'pending';
  }

  DateTime? get graphReturnDate => _parseDate(date);

  factory ReturnSettlementModel.fromJson(Map<String, dynamic> json) {
    return ReturnSettlementModel(
      settlementId: _firstString(json, ['settlementId', '_id', 'id']),
      date: _firstString(json, ['date', 'settledDate', 'paymentDate']),
      amount: _toInt(json['amount'] ?? json['returnAmount']),
      status: _toString(json['status']),
      note: _toString(json['note'] ?? json['remarks']),
      settledBy: _toString(json['settledBy']),
    );
  }
}

// =============================================================
// 8. GRAPH POINT MODEL
// =============================================================

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

  DateTime? get parsedDate => _parseDate(date);

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

    final DateTime? parsed = parsedDate;

    if (parsed != null && parsed.month >= 1 && parsed.month <= 12) {
      return months[parsed.month - 1];
    }

    return date;
  }

  String get monthYearLabel {
    final DateTime? parsed = parsedDate;

    if (parsed == null) return date;

    return '$shortMonthLabel ${parsed.year}';
  }

  bool get hasInvestment => investedAmount > 0;

  bool get hasReturn => monthlyReturn > 0;

  factory GraphPointModel.fromJson(Map<String, dynamic> json) {
    return GraphPointModel(
      id: _toString(json['id'] ?? json['_id']),
      date: _toString(json['date'] ?? json['month']),
      investedAmount: _toInt(
        json['investedAmount'] ?? json['investmentAmount'],
      ),
      monthlyReturn: _toInt(
        json['monthlyReturn'] ?? json['revenueReturn'] ?? json['returnAmount'],
      ),
    );
  }
}

// =============================================================
// 9. PORTFOLIO GRAPH DATA
// =============================================================

class PortfolioGraphData {
  final List<GraphPointModel> points;
  final int rangeMonths;
  final String scope;

  const PortfolioGraphData({
    required this.points,
    this.rangeMonths = 0,
    this.scope = 'all',
  });

  List<GraphPointModel> get last6Months {
    return points.length <= 6 ? points : points.sublist(points.length - 6);
  }

  List<GraphPointModel> get last12Months {
    return points.length <= 12 ? points : points.sublist(points.length - 12);
  }

  int get totalInvested {
    return points.fold(
      0,
      (int total, GraphPointModel point) => total + point.investedAmount,
    );
  }

  int get totalReturned {
    return points.fold(
      0,
      (int total, GraphPointModel point) => total + point.monthlyReturn,
    );
  }

  /// Generates continuous monthly series including zero months.
  List<GraphPointModel> monthlySeries(int monthCount, {DateTime? endDate}) {
    if (monthCount <= 0) return <GraphPointModel>[];

    final DateTime end = endDate ?? DateTime.now();

    final DateTime currentMonth = DateTime(end.year, end.month, 1);

    final DateTime startMonth = DateTime(
      currentMonth.year,
      currentMonth.month - monthCount + 1,
      1,
    );

    final Map<String, GraphPointModel> indexedPoints = {
      for (final GraphPointModel point in points)
        if (point.parsedDate != null) _monthKey(point.parsedDate!): point,
    };

    final List<GraphPointModel> result = [];

    for (int i = 0; i < monthCount; i++) {
      final DateTime month = DateTime(startMonth.year, startMonth.month + i, 1);

      final String key = _monthKey(month);
      final GraphPointModel? existing = indexedPoints[key];

      result.add(
        GraphPointModel(
          id: existing?.id ?? key,
          date: _monthDate(month),
          investedAmount: existing?.investedAmount ?? 0,
          monthlyReturn: existing?.monthlyReturn ?? 0,
        ),
      );
    }

    return result;
  }

  /// Particular asset graph.
  factory PortfolioGraphData.fromAsset(
    PortfolioAssetItemModel asset, {
    int months = 6,
    DateTime? endDate,
  }) {
    return PortfolioGraphData(
      points: _aggregateMonthlyData(
        assets: <PortfolioAssetItemModel>[asset],
        months: months,
        endDate: endDate,
      ),
      rangeMonths: months,
      scope: 'asset',
    );
  }

  /// All-assets graph.
  factory PortfolioGraphData.fromAssets(
    List<PortfolioAssetItemModel> assets, {
    int months = 6,
    DateTime? endDate,
  }) {
    return PortfolioGraphData(
      points: _aggregateMonthlyData(
        assets: assets,
        months: months,
        endDate: endDate,
      ),
      rangeMonths: months,
      scope: 'all',
    );
  }

  factory PortfolioGraphData.fromJson(Map<String, dynamic> json) {
    final dynamic rawPoints = json['points'] ?? json['data'];

    return PortfolioGraphData(
      points: _toMapList(rawPoints).map(GraphPointModel.fromJson).toList(),
      rangeMonths: _toInt(json['rangeMonths'] ?? json['months']),
      scope: _toString(json['scope'], fallback: 'all'),
    );
  }
}

// =============================================================
// MONTHLY AGGREGATION
// =============================================================

List<GraphPointModel> _aggregateMonthlyData({
  required List<PortfolioAssetItemModel> assets,
  required int months,
  DateTime? endDate,
}) {
  if (months <= 0) return <GraphPointModel>[];

  final DateTime end = endDate ?? DateTime.now();

  final DateTime currentMonth = DateTime(end.year, end.month, 1);

  final DateTime startMonth = DateTime(
    currentMonth.year,
    currentMonth.month - months + 1,
    1,
  );

  final DateTime nextMonth = DateTime(
    currentMonth.year,
    currentMonth.month + 1,
    1,
  );

  final Map<String, int> monthlyInvestments = {};
  final Map<String, int> monthlyReturns = {};

  bool isInsideRange(DateTime date) {
    return !date.isBefore(startMonth) && date.isBefore(nextMonth);
  }

  for (final PortfolioAssetItemModel asset in assets) {
    // INVESTMENT HISTORY
    if (asset.investmentHistory.isNotEmpty) {
      for (final InvestmentHistoryModel investment in asset.investmentHistory) {
        if (!investment.isEligibleForGraph) continue;

        final DateTime? investmentDate = investment.parsedDate;

        if (investmentDate == null || !isInsideRange(investmentDate)) {
          continue;
        }

        final String key = _monthKey(investmentDate);

        monthlyInvestments[key] =
            (monthlyInvestments[key] ?? 0) + investment.amount;
      }
    } else {
      // LEGACY FALLBACK - avoids double counting.
      final InvestmentFlowModel investment = asset.investmentFlow;

      if (investment.isEligibleForGraph && investment.investedAmount > 0) {
        final DateTime? investmentDate = investment.graphInvestmentDate;

        if (investmentDate != null && isInsideRange(investmentDate)) {
          final String key = _monthKey(investmentDate);

          monthlyInvestments[key] =
              (monthlyInvestments[key] ?? 0) + investment.investedAmount;
        }
      }
    }

    // SETTLED / CREDITED RETURNS ONLY
    for (final ReturnSettlementModel settlement in asset.returnSettlements) {
      if (!settlement.isEligibleForGraph) continue;

      final DateTime? returnDate = settlement.graphReturnDate;

      if (returnDate == null || !isInsideRange(returnDate)) {
        continue;
      }

      final String key = _monthKey(returnDate);

      monthlyReturns[key] = (monthlyReturns[key] ?? 0) + settlement.amount;
    }
  }

  // Continuous series with zero-value months.
  final List<GraphPointModel> result = [];

  for (int i = 0; i < months; i++) {
    final DateTime month = DateTime(startMonth.year, startMonth.month + i, 1);

    final String key = _monthKey(month);

    result.add(
      GraphPointModel(
        id: key,
        date: _monthDate(month),
        investedAmount: monthlyInvestments[key] ?? 0,
        monthlyReturn: monthlyReturns[key] ?? 0,
      ),
    );
  }

  return result;
}

// =============================================================
// 10. PRODUCT SPECIFICATIONS MODEL
// =============================================================

class ProductSpecsModel {
  final String brandModel;
  final String vehicleAge;
  final String range;
  final String battery;
  final String chargingTime;

  const ProductSpecsModel({
    required this.brandModel,
    required this.vehicleAge,
    required this.range,
    required this.battery,
    required this.chargingTime,
  });

  factory ProductSpecsModel.fromJson(Map<String, dynamic> json) {
    return ProductSpecsModel(
      brandModel: _toString(json['brandModel']),
      vehicleAge: _toString(json['vehicleAge']),
      range: _toString(json['range']),
      battery: _toString(json['battery']),
      chargingTime: _toString(json['chargingTime']),
    );
  }
}

// =============================================================
// 11. PORTFOLIO PRODUCT MODEL
// =============================================================

class PortfolioProductModel {
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
  final int explicitMonthlyReturnAmount;
  final String explicitExpectedReturn;
  final String coverImage;
  final List<String> gallery;
  final List<String> infoTags;
  final List<String> highlights;
  final ProductSpecsModel specs;

  const PortfolioProductModel({
    required this.id,
    required this.mongoId,
    required this.type,
    required this.category,
    required this.brand,
    required this.modelName,
    required this.modelYear,
    required this.summary,
    required this.unitPrice,
    required this.monthlyReturnRate,
    required this.explicitMonthlyReturnAmount,
    required this.explicitExpectedReturn,
    required this.coverImage,
    required this.gallery,
    required this.infoTags,
    required this.highlights,
    required this.specs,
  });

  String get displayName {
    if (modelName.isNotEmpty) return modelName;
    if (brand.isNotEmpty) return brand;
    return type;
  }

  String get primaryImageUrl {
    if (coverImage.trim().isNotEmpty) {
      return coverImage.trim();
    }

    for (final String image in gallery) {
      if (image.trim().isNotEmpty) return image.trim();
    }

    return '';
  }

  factory PortfolioProductModel.fromJson(Map<String, dynamic> json) {
    return PortfolioProductModel(
      id: _toString(json['id'] ?? json['_id']),
      mongoId: _toString(json['mongoId']),
      type: _toString(json['type']),
      category: _toString(json['category']),
      brand: _toString(json['brand']),
      modelName: _toString(json['modelName']),
      modelYear: _toInt(json['modelYear']),
      summary: _toString(json['summary']),
      unitPrice: _toInt(json['unitPrice']),
      monthlyReturnRate: _toDouble(json['monthlyReturnRate']),
      explicitMonthlyReturnAmount: _toInt(json['explicitMonthlyReturnAmount']),
      explicitExpectedReturn: _toString(json['explicitExpectedReturn']),
      coverImage: _toString(json['coverImage']),
      gallery: _toStringList(json['gallery']),
      infoTags: _toStringList(json['infoTags']),
      highlights: _toStringList(json['highlights']),
      specs: ProductSpecsModel.fromJson(_toMap(json['specs'])),
    );
  }
}

// =============================================================
// 12. PORTFOLIO ASSET ITEM MODEL
// =============================================================

class PortfolioAssetItemModel {
  final String assetId;
  final String productId;
  final int units;
  final int investedAmount;
  final int monthlyReturn;
  final int totalReturnedAmount;
  final String status;
  final bool isRenewable;
  final String purchaseDate;

  final InvestmentFlowModel investmentFlow;
  final List<InvestmentHistoryModel> investmentHistory;

  final AssetSummaryModel assetSummary;
  final AssetRenewalModel renewal;

  final NextPaymentModel nextPayment;
  final List<ReturnSettlementModel> returnSettlements;

  /// Legacy graph response for UI compatibility.
  /// Graph calculations use investmentHistory and settlements.
  final PortfolioGraphData assetGraph;

  final PortfolioProductModel product;

  const PortfolioAssetItemModel({
    required this.assetId,
    required this.productId,
    required this.units,
    required this.investedAmount,
    required this.monthlyReturn,
    required this.totalReturnedAmount,
    required this.status,
    required this.isRenewable,
    required this.purchaseDate,
    required this.investmentFlow,
    required this.investmentHistory,
    required this.assetSummary,
    required this.renewal,
    required this.nextPayment,
    required this.returnSettlements,
    required this.assetGraph,
    required this.product,
  });

  // Existing UI compatibility getters.

  String get id => assetId;

  String get vehicleId => productId;

  String get primaryImageUrl => product.primaryImageUrl;

  String get vehicleModelName => product.modelName;

  String get companyName => product.brand;

  int get vehicleYearModel => product.modelYear;

  List<String> get vehicleImage => product.gallery;

  String get vehicleNoPlate => '';

  String get clusterCity => '';

  String get clusterState => '';

  String get nextReturnDate {
    if (nextPayment.date.isNotEmpty) {
      return nextPayment.date;
    }

    return assetSummary.nextReturnDate;
  }

  int get nextReturnAmount {
    if (nextPayment.amount > 0) {
      return nextPayment.amount;
    }

    return assetSummary.nextReturnAmount;
  }

  String get nextPaymentStatus => nextPayment.status;

  String get nextReinvestmentDate => nextPayment.date;

  int get nextReinvestmentAmount => nextPayment.amount;

  /// Particular asset graph.
  PortfolioGraphData monthlyGraph(int months, {DateTime? endDate}) {
    return PortfolioGraphData.fromAsset(this, months: months, endDate: endDate);
  }

  factory PortfolioAssetItemModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> productJson = _toMap(json['product']);

    final Map<String, dynamic> summaryJson = _toMap(json['assetSummary']);

    final Map<String, dynamic> paymentJson = _toMap(json['nextPayment']);

    final Map<String, dynamic> renewalJson = _toMap(json['renewal']);

    final List<InvestmentHistoryModel> history = _toMapList(
      json['investmentHistory'],
    ).map(InvestmentHistoryModel.fromJson).toList();

    return PortfolioAssetItemModel(
      assetId: _toString(json['assetId'] ?? json['_id'] ?? json['id']),
      productId: _toString(
        json['productId'] ?? productJson['id'] ?? productJson['_id'],
      ),
      units: _toInt(json['units']),
      investedAmount: _toInt(
        json['investedAmount'] ?? summaryJson['investedAmount'],
      ),
      monthlyReturn: _toInt(
        json['monthlyReturn'] ?? summaryJson['monthlyReturn'],
      ),
      totalReturnedAmount: _toInt(
        json['totalReturnedAmount'] ?? summaryJson['totalReturnedAmount'],
      ),
      status: _toString(json['status']),
      isRenewable: _toBool(json['isRenewable'] ?? renewalJson['isRenewable']),
      purchaseDate: _firstString(json, [
        'purchaseDate',
      ], fallback: _toString(summaryJson['purchaseDate'])),
      investmentFlow: InvestmentFlowModel.fromJson(
        _toMap(json['investmentFlow']),
      ),
      investmentHistory: history,
      assetSummary: AssetSummaryModel.fromJson(summaryJson),
      renewal: AssetRenewalModel.fromJson(renewalJson),
      nextPayment: paymentJson.isNotEmpty
          ? NextPaymentModel.fromJson(paymentJson)
          : NextPaymentModel.fromJson({
              'date':
                  summaryJson['nextReinvestmentDate'] ??
                  summaryJson['nextReturnDate'],
              'amount':
                  summaryJson['nextReinvestmentAmount'] ??
                  summaryJson['nextReturnAmount'],
              'status': 'Planned',
            }),
      returnSettlements: _toMapList(
        json['returnSettlements'],
      ).map(ReturnSettlementModel.fromJson).toList(),
      assetGraph: PortfolioGraphData.fromJson(_toMap(json['assetGraph'])),
      product: PortfolioProductModel.fromJson(productJson),
    );
  }
}

// =============================================================
// 13. PORTFOLIO ASSET DETAIL MODEL
// =============================================================

class PortfolioAssetDetailModel {
  final String id;
  final String investorId;
  final String status;
  final PortfolioAssetItemModel asset;

  const PortfolioAssetDetailModel({
    required this.id,
    required this.investorId,
    required this.status,
    required this.asset,
  });

  String get vehicleId => asset.productId;

  String get storeId => '';

  int get units => asset.units;

  AssetSummaryModel get assetSummary => asset.assetSummary;

  AssetRenewalModel get renewal => asset.renewal;

  NextPaymentModel get nextPayment => asset.nextPayment;

  List<InvestmentHistoryModel> get investmentHistory => asset.investmentHistory;

  List<ReturnSettlementModel> get returnSettlements => asset.returnSettlements;

  PortfolioGraphData get assetGraph => asset.assetGraph;

  PortfolioProductModel get productSpecs => asset.product;

  /// Particular EV graph.
  PortfolioGraphData monthlyGraph(int months, {DateTime? endDate}) {
    return asset.monthlyGraph(months, endDate: endDate);
  }

  factory PortfolioAssetDetailModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> nestedAsset = _toMap(json['asset']);

    final Map<String, dynamic> assetJson = nestedAsset.isNotEmpty
        ? nestedAsset
        : json;

    final PortfolioAssetItemModel parsedAsset =
        PortfolioAssetItemModel.fromJson(assetJson);

    return PortfolioAssetDetailModel(
      id: _firstString(json, [
        'assetId',
        '_id',
        'id',
      ], fallback: parsedAsset.assetId),
      investorId: _toString(json['investorId']),
      status: _firstString(json, ['status'], fallback: parsedAsset.status),
      asset: parsedAsset,
    );
  }
}

// =============================================================
// 14. PORTFOLIO OVERVIEW RESPONSE
// =============================================================

class PortfolioOverviewResponse {
  final String id;
  final String investorId;
  final DeployedCapitalSummary deployedCapital;
  final PortfolioGraphData overallGraph;
  final List<PortfolioAssetItemModel> portfolioAssets;

  const PortfolioOverviewResponse({
    required this.id,
    required this.investorId,
    required this.deployedCapital,
    required this.overallGraph,
    required this.portfolioAssets,
  });

  List<PortfolioAssetItemModel> get assets => portfolioAssets;

  /// Local graph from available assets.
  /// Use API overallGraph for the complete portfolio.
  PortfolioGraphData monthlyGraph(int months, {DateTime? endDate}) {
    return PortfolioGraphData.fromAssets(
      portfolioAssets,
      months: months,
      endDate: endDate,
    );
  }

  PortfolioGraphData get overallLast6Months {
    return overallGraph.last6Months.isNotEmpty
        ? PortfolioGraphData(
            points: overallGraph.last6Months,
            rangeMonths: 6,
            scope: 'all',
          )
        : monthlyGraph(6);
  }

  PortfolioGraphData get overallLast12Months {
    return overallGraph.last12Months.isNotEmpty
        ? PortfolioGraphData(
            points: overallGraph.last12Months,
            rangeMonths: 12,
            scope: 'all',
          )
        : monthlyGraph(12);
  }

  factory PortfolioOverviewResponse.fromJson(Map<String, dynamic> json) {
    // Supports direct response and API data envelope.
    final Map<String, dynamic> nestedData = _toMap(json['data']);

    final Map<String, dynamic> data = nestedData.isNotEmpty ? nestedData : json;

    final List<PortfolioAssetItemModel> assets = _toMapList(
      data['assets'] ?? data['portfolioAssets'],
    ).map(PortfolioAssetItemModel.fromJson).toList();

    final Map<String, dynamic> summaryJson = {
      ...data,
      ..._toMap(data['deployedCapital']),
    };

    final int activeCount = assets
        .where(
          (PortfolioAssetItemModel asset) =>
              _normalizeStatus(asset.status) == 'active',
        )
        .length;

    final PortfolioGraphData apiGraph = PortfolioGraphData.fromJson(
      _toMap(data['overallGraph'] ?? data['portfolioGraph'] ?? data['graph']),
    );

    // API graph takes priority because it should include
    // all assets, including assets outside the current page.
    final PortfolioGraphData calculatedGraph = PortfolioGraphData.fromAssets(
      assets,
      months: apiGraph.rangeMonths > 0 ? apiGraph.rangeMonths : 6,
    );

    return PortfolioOverviewResponse(
      id: _toString(data['_id'] ?? data['id']),
      investorId: _toString(data['investorId']),
      deployedCapital: DeployedCapitalSummary.fromJson(
        summaryJson,
        calculatedActiveAssets: activeCount,
      ),
      overallGraph: apiGraph.points.isNotEmpty ? apiGraph : calculatedGraph,
      portfolioAssets: assets,
    );
  }
}
