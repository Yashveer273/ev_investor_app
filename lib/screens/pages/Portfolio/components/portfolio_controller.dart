import 'package:get/get.dart';

import '../../../../core/services/api_service.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/widget/portfolio_asset_detail_page.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/components/portfolio_model.dart';

class PortfolioController extends GetxController {
  final RxBool isLoadingOverview = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isLoadingDetail = false.obs;
  final RxBool isLoadingAssetGraph = false.obs;

  final RxBool isLoadingHistory = false.obs;
  final RxBool isLoadingMoreHistory = false.obs;

  final RxBool hasMorePages = true.obs;
  final RxBool hasMoreHistory = true.obs;

  final RxInt currentPage = 1.obs;
  final RxInt currentHistoryPage = 1.obs;

  final RxInt selectedGraphMonths = 6.obs;
  final RxInt selectedAssetGraphMonths = 6.obs;
  final RxInt selectedHistoryMonths = 6.obs;

  static const int pageSize = 10;

  final deployedCapital = DeployedCapitalSummary(
    totalInvested: 0,
    thisMonthInvested: 0,
    totalMonthlyReturn: 0,
    thisMonthReturn: 0,
    totalReturnedAmount: 0,
    totalUnits: 0,
    activeAssetsCount: 0,
  ).obs;

  final overallGraph = const PortfolioGraphData(points: []).obs;

  final Rx<PortfolioGraphData> selectedAssetGraph = const PortfolioGraphData(
    points: [],
  ).obs;

  final RxList<PortfolioAssetItemModel> portfolioAssets =
      <PortfolioAssetItemModel>[].obs;

  final Rxn<PortfolioAssetDetailModel> selectedAssetDetail =
      Rxn<PortfolioAssetDetailModel>();

  // ============================================================
  // HISTORY DATA
  // ============================================================

  final RxList<Map<String, dynamic>> investmentHistory =
      <Map<String, dynamic>>[].obs;

  final RxList<Map<String, dynamic>> returnHistory =
      <Map<String, dynamic>>[].obs;

  final RxMap<String, dynamic> historySummary = <String, dynamic>{}.obs;

  final RxString overviewError = ''.obs;
  final RxString detailError = ''.obs;
  final RxString renewalError = ''.obs;
  final RxString assetGraphError = ''.obs;
  final RxString historyError = ''.obs;

  // ============================================================
  // GRAPH CACHE
  // ============================================================

  final Map<String, PortfolioGraphData> _assetGraphCache = {};

  String _assetGraphCacheKey(String assetId, int months) {
    return '${assetId.trim()}_$months';
  }

  // ============================================================
  // HISTORY CACHE
  // ============================================================

  // Cache each page separately for each month range.
  final Map<int, Map<int, Map<String, dynamic>>> _historyCache = {};

  final Map<int, bool> _historyHasMoreCache = {};

  bool _isValidMonthRange(int months) {
    return months == 6 || months == 12;
  }

  Map<String, dynamic> _getHistoryPayload(Map<String, dynamic> response) {
    final dynamic data = response['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return response;
  }

  List<Map<String, dynamic>> _parseHistoryList(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  bool _getHistoryHasMore(
    Map<String, dynamic> payload, {
    required int investmentCount,
    required int returnCount,
  }) {
    // Prefer explicit pagination information from backend.
    final dynamic pagination = payload['pagination'];

    if (pagination is Map) {
      final dynamic hasMore = pagination['hasMore'];

      if (hasMore is bool) return hasMore;

      final dynamic totalPages = pagination['totalPages'];
      final dynamic current = pagination['currentPage'];

      if (totalPages != null && current != null) {
        return (int.tryParse('$current') ?? 1) <
            (int.tryParse('$totalPages') ?? 1);
      }
    }

    // Fallback when backend does not send pagination metadata.
    return investmentCount >= pageSize || returnCount >= pageSize;
  }

  void _appendUniqueHistory(
    RxList<Map<String, dynamic>> target,
    List<Map<String, dynamic>> incoming,
    String primaryKey,
  ) {
    final Set<String> existingIds = target
        .map((item) => '${item[primaryKey] ?? ''}')
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final item in incoming) {
      final String id = '${item[primaryKey] ?? ''}';

      if (id.isEmpty || !existingIds.contains(id)) {
        target.add(item);

        if (id.isNotEmpty) {
          existingIds.add(id);
        }
      }
    }
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void onInit() {
    super.onInit();
    _initializePortfolio();
  }

  Future<void> _initializePortfolio() async {
    await loadPortfolioOverview();
  }

  Future<void> ensureInvestorId() async {
    await ApiService.ensureInvestorId();
  }

  // ============================================================
  // OVERALL GRAPH
  // ============================================================

  void _updateOverallGraph(PortfolioGraphData graph) {
    overallGraph.value = graph;
  }

  Future<void> changeGraphRange(int months) async {
    if (!_isValidMonthRange(months)) return;
    if (selectedGraphMonths.value == months) return;

    selectedGraphMonths.value = months;
    await loadPortfolioOverview();
  }

  PortfolioGraphData getOverallGraph({int? months}) {
    final int range = months ?? selectedGraphMonths.value;

    if (range == selectedGraphMonths.value) {
      return overallGraph.value;
    }

    return const PortfolioGraphData(points: []);
  }

  // ============================================================
  // PORTFOLIO OVERVIEW
  // ============================================================

  Future<void> loadPortfolioOverview() async {
    if (isLoadingOverview.value) return;

    isLoadingOverview.value = true;
    overviewError.value = '';

    try {
      await ensureInvestorId();
      final PortfolioOverviewResponse response =
          await ApiService.getPortfolioOverview(
            page: 1,
            limit: pageSize,
            months: selectedGraphMonths.value,
          );

      deployedCapital.value = response.deployedCapital;
      portfolioAssets.assignAll(response.portfolioAssets);

      currentPage.value = 1;
      hasMorePages.value = response.portfolioAssets.length >= pageSize;

      _updateOverallGraph(response.overallGraph);
    } catch (e) {
      overviewError.value = e.toString();
    } finally {
      isLoadingOverview.value = false;
    }
  }

  // ============================================================
  // PORTFOLIO PAGINATION
  // ============================================================

  Future<void> loadMorePortfolioAssets() async {
    if (isLoadingMore.value || isLoadingOverview.value || !hasMorePages.value) {
      return;
    }

    isLoadingMore.value = true;

    final int nextPage = currentPage.value + 1;

    try {
      await ensureInvestorId();
      final PortfolioOverviewResponse response =
          await ApiService.getPortfolioOverview(
            page: nextPage,
            limit: pageSize,
            months: selectedGraphMonths.value,
          );

      final List<PortfolioAssetItemModel> newAssets = response.portfolioAssets;

      if (newAssets.isEmpty) {
        hasMorePages.value = false;
        return;
      }

      final Set<String> existingIds = portfolioAssets
          .map((asset) => asset.assetId)
          .toSet();

      final List<PortfolioAssetItemModel> uniqueAssets = newAssets.where((
        asset,
      ) {
        return asset.assetId.isNotEmpty && !existingIds.contains(asset.assetId);
      }).toList();

      portfolioAssets.addAll(uniqueAssets);

      currentPage.value = nextPage;
      hasMorePages.value = newAssets.length >= pageSize;
    } catch (e) {
      overviewError.value = e.toString();
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ============================================================
  // ASSET DETAILS
  // ============================================================

  Future<void> openAssetDetail(PortfolioAssetItemModel asset) async {
    isLoadingDetail.value = true;
    detailError.value = '';
    assetGraphError.value = '';

    selectedAssetDetail.value = null;
    selectedAssetGraph.value = const PortfolioGraphData(points: []);

    selectedAssetGraphMonths.value = 6;

    Get.to(() => PortfolioAssetDetailPage(assetId: asset.assetId));

    try {
      await ensureInvestorId();
      final PortfolioAssetDetailModel detail = await ApiService.getAssetDetail(
        asset.assetId,
        months: 6,
      );

      selectedAssetDetail.value = detail;

      await loadSelectedAssetGraph(assetId: asset.assetId, months: 6);
    } catch (e) {
      detailError.value = e.toString();
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<void> refreshSelectedAssetDetail() async {
    final PortfolioAssetDetailModel? detail = selectedAssetDetail.value;

    if (detail == null) return;

    isLoadingDetail.value = true;
    detailError.value = '';

    try {
      await ensureInvestorId();
      final PortfolioAssetDetailModel updatedDetail =
          await ApiService.getAssetDetail(
            detail.asset.assetId,
            months: selectedAssetGraphMonths.value,
          );

      selectedAssetDetail.value = updatedDetail;

      _assetGraphCache.remove(_assetGraphCacheKey(detail.asset.assetId, 6));

      _assetGraphCache.remove(_assetGraphCacheKey(detail.asset.assetId, 12));

      await loadSelectedAssetGraph(
        assetId: detail.asset.assetId,
        months: selectedAssetGraphMonths.value,
        forceRefresh: true,
      );
    } catch (e) {
      detailError.value = e.toString();
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ============================================================
  // ASSET GRAPH: 6M / 12M API + CACHE
  // ============================================================

  Future<void> changeSelectedAssetGraphRange(int months) async {
    if (!_isValidMonthRange(months)) return;

    if (selectedAssetGraphMonths.value == months) return;

    final PortfolioAssetDetailModel? detail = selectedAssetDetail.value;

    if (detail == null) return;

    selectedAssetGraphMonths.value = months;

    await loadSelectedAssetGraph(
      assetId: detail.asset.assetId,
      months: months,
      forceRefresh: true,
    );
  }

  Future<void> loadSelectedAssetGraph({
    required String assetId,
    required int months,
    bool forceRefresh = false,
  }) async {
    if (!_isValidMonthRange(months)) return;

    final String cacheKey = _assetGraphCacheKey(assetId, months);

    if (!forceRefresh && _assetGraphCache.containsKey(cacheKey)) {
      selectedAssetGraph.value = _assetGraphCache[cacheKey]!;

      return;
    }

    isLoadingAssetGraph.value = true;
    assetGraphError.value = '';

    try {
      await ensureInvestorId();
      final PortfolioGraphData graph = await ApiService.getAssetGraph(
        assetId: assetId,
        months: months,
      );

      _assetGraphCache[cacheKey] = graph;
      selectedAssetGraph.value = graph;
    } catch (e) {
      assetGraphError.value = e.toString();
      rethrow;
    } finally {
      isLoadingAssetGraph.value = false;
    }
  }

  PortfolioGraphData getAssetGraph({required String assetId, int months = 6}) {
    if (!_isValidMonthRange(months)) {
      return const PortfolioGraphData(points: []);
    }

    return _assetGraphCache[_assetGraphCacheKey(assetId, months)] ??
        const PortfolioGraphData(points: []);
  }

  PortfolioGraphData getSelectedAssetGraph({int? months}) {
    final int range = months ?? selectedAssetGraphMonths.value;

    final PortfolioAssetDetailModel? detail = selectedAssetDetail.value;

    if (detail == null || !_isValidMonthRange(range)) {
      return const PortfolioGraphData(points: []);
    }

    if (range == selectedAssetGraphMonths.value) {
      return selectedAssetGraph.value;
    }

    return getAssetGraph(assetId: detail.asset.assetId, months: range);
  }

  // ============================================================
  // INVESTOR HISTORY: API + PAGINATION + CACHE
  // ============================================================

  Future<void> loadInvestorHistory({
    int? months,
    bool forceRefresh = false,
  }) async {
    final int range = months ?? selectedHistoryMonths.value;

    if (!_isValidMonthRange(range)) return;

    if (isLoadingHistory.value) return;

    selectedHistoryMonths.value = range;

    final Map<int, Map<String, dynamic>> rangeCache = _historyCache.putIfAbsent(
      range,
      () => {},
    );

    // If first page is already cached, use it.
    if (!forceRefresh && rangeCache.containsKey(1)) {
      _displayCachedHistory(range, 1);
      return;
    }

    isLoadingHistory.value = true;
    historyError.value = '';

    try {
      await ensureInvestorId();
      final Map<String, dynamic> response =
          await ApiService.getInvestorPortfolioHistory(
            months: range,
            page: 1,
            limit: pageSize,
          );

      final Map<String, dynamic> payload = _getHistoryPayload(response);

      rangeCache[1] = payload;

      _displayCachedHistory(range, 1);
    } catch (e) {
      historyError.value = e.toString();
    } finally {
      isLoadingHistory.value = false;
    }
  }

  void _displayCachedHistory(int months, int page) {
    final Map<int, Map<String, dynamic>>? rangeCache = _historyCache[months];

    if (rangeCache == null || !rangeCache.containsKey(page)) {
      return;
    }

    investmentHistory.clear();
    returnHistory.clear();
    historySummary.clear();

    final List<int> pages = rangeCache.keys.where((p) => p <= page).toList()
      ..sort();

    bool moreAvailable = false;

    for (final int cachedPage in pages) {
      final Map<String, dynamic> payload = rangeCache[cachedPage]!;

      final List<Map<String, dynamic>> investments = _parseHistoryList(
        payload['investmentHistory'],
      );

      final List<Map<String, dynamic>> returns = _parseHistoryList(
        payload['returnHistory'],
      );

      _appendUniqueHistory(investmentHistory, investments, 'investmentId');

      _appendUniqueHistory(returnHistory, returns, 'historyId');

      final dynamic summary = payload['summary'];

      if (summary is Map) {
        historySummary.assignAll(Map<String, dynamic>.from(summary));
      }

      moreAvailable = _getHistoryHasMore(
        payload,
        investmentCount: investments.length,
        returnCount: returns.length,
      );
    }

    currentHistoryPage.value = page;

    hasMoreHistory.value = _historyHasMoreCache[months] ?? moreAvailable;
  }

  Future<void> loadMoreHistory() async {
    if (isLoadingMoreHistory.value ||
        isLoadingHistory.value ||
        !hasMoreHistory.value) {
      return;
    }

    isLoadingMoreHistory.value = true;
    historyError.value = '';

    final int range = selectedHistoryMonths.value;
    final int nextPage = currentHistoryPage.value + 1;

    try {
      await ensureInvestorId();
      final Map<int, Map<String, dynamic>> rangeCache = _historyCache
          .putIfAbsent(range, () => {});

      // Use cached page instead of making another API call.
      if (rangeCache.containsKey(nextPage)) {
        _displayCachedHistory(range, nextPage);
        return;
      }

      final Map<String, dynamic> response =
          await ApiService.getInvestorPortfolioHistory(
            months: range,
            page: nextPage,
            limit: pageSize,
          );

      final Map<String, dynamic> payload = _getHistoryPayload(response);

      final List<Map<String, dynamic>> investments = _parseHistoryList(
        payload['investmentHistory'],
      );

      final List<Map<String, dynamic>> returns = _parseHistoryList(
        payload['returnHistory'],
      );

      rangeCache[nextPage] = payload;

      final bool moreAvailable = _getHistoryHasMore(
        payload,
        investmentCount: investments.length,
        returnCount: returns.length,
      );

      _historyHasMoreCache[range] = moreAvailable;

      _displayCachedHistory(range, nextPage);
    } catch (e) {
      historyError.value = e.toString();
    } finally {
      isLoadingMoreHistory.value = false;
    }
  }

  Future<void> changeHistoryRange(int months) async {
    if (!_isValidMonthRange(months)) return;

    if (selectedHistoryMonths.value == months) return;

    selectedHistoryMonths.value = months;

    currentHistoryPage.value = 1;
    hasMoreHistory.value = true;

    investmentHistory.clear();
    returnHistory.clear();
    historySummary.clear();

    await loadInvestorHistory(months: months);
  }

  Future<void> refreshInvestorHistory() async {
    final int range = selectedHistoryMonths.value;

    _historyCache.remove(range);
    _historyHasMoreCache.remove(range);

    currentHistoryPage.value = 1;
    hasMoreHistory.value = true;

    investmentHistory.clear();
    returnHistory.clear();
    historySummary.clear();

    await loadInvestorHistory(months: range, forceRefresh: true);
  }

  // ============================================================
  // RENEW / REINVEST
  // ============================================================

  Future<void> renewSelectedAsset({required int reinvestAmount}) async {
    await ensureInvestorId();
    final PortfolioAssetDetailModel? detail = selectedAssetDetail.value;

    if (detail == null) {
      renewalError.value = 'Asset details not available.';
      return;
    }

    if (reinvestAmount < 0) {
      renewalError.value = 'Reinvestment amount cannot be negative.';
      return;
    }

    renewalError.value = '';

    try {
      await ApiService.renewAsset(
        assetId: detail.asset.assetId,
        reinvestAmount: reinvestAmount,
      );

      _assetGraphCache.remove(_assetGraphCacheKey(detail.asset.assetId, 6));

      _assetGraphCache.remove(_assetGraphCacheKey(detail.asset.assetId, 12));

      await loadPortfolioOverview();
      await refreshSelectedAssetDetail();

      // History may also have changed after reinvestment.
      _historyCache.clear();
      _historyHasMoreCache.clear();
    } catch (e) {
      renewalError.value = e.toString();
      rethrow;
    }
  }

  // ============================================================
  // CLEAR / REFRESH
  // ============================================================

  void clearSelectedAsset() {
    selectedAssetDetail.value = null;

    selectedAssetGraph.value = const PortfolioGraphData(points: []);

    selectedAssetGraphMonths.value = 6;

    detailError.value = '';
    renewalError.value = '';
    assetGraphError.value = '';
  }

  Future<void> refreshPortfolio() async {
    currentPage.value = 1;
    hasMorePages.value = true;

    await loadPortfolioOverview();
  }
}
