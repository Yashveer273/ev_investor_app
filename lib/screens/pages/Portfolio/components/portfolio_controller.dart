import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widget/portfolio_asset_detail_page.dart';
import 'portfolio_model.dart';

class PortfolioController extends GetxController {
  // Loading states
  final RxBool isLoadingOverview = false.obs;
  final RxBool isLoadingDetail = false.obs;

  // Portfolio overview
  final deployedCapital = const DeployedCapitalSummary(
    totalInvested: 0,
    thisMonthInvested: 0,
    totalMonthlyReturn: 0,
    thisMonthReturn: 0,
    activeAssetsCount: 0,
  ).obs;

  final overallGraph = const PortfolioGraphData(points: []).obs;

  // Portfolio assets
  final RxList<PortfolioAssetItemModel> portfolioAssets =
      <PortfolioAssetItemModel>[].obs;

  // Selected asset detail
  final Rxn<PortfolioAssetDetailModel> selectedAssetDetail =
      Rxn<PortfolioAssetDetailModel>();

  // Error states
  final RxString overviewError = ''.obs;
  final RxString detailError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPortfolioOverview();
  }

  // ==========================================
  // PORTFOLIO OVERVIEW
  // ==========================================

  Future<void> loadPortfolioOverview() async {
    isLoadingOverview.value = true;
    overviewError.value = '';

    try {
      // Portfolio Overview API will be integrated here.
      // Update deployedCapital, overallGraph and portfolioAssets
      // using actual API response.
    } catch (e) {
      overviewError.value = e.toString();
      debugPrint('Portfolio Overview Error: $e');
    } finally {
      isLoadingOverview.value = false;
    }
  }

  // ==========================================
  // ASSET DETAIL
  // ==========================================

  Future<void> openAssetDetail(PortfolioAssetItemModel asset) async {
    isLoadingDetail.value = true;
    detailError.value = '';
    selectedAssetDetail.value = null;

    Get.to(() => PortfolioAssetDetailPage(assetId: asset.id));

    try {
      // Asset Detail API will be integrated here.
      // Set selectedAssetDetail using actual API response.
    } catch (e) {
      detailError.value = e.toString();
      debugPrint('Portfolio Asset Detail Error: $e');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ==========================================
  // ASSET RENEWAL
  // ==========================================

  Future<void> renewSelectedAsset({
    required int extraMonths,
    required int reinvestAmount,
  }) async {
    // Renewal API will be integrated here.
    // Do not update investment or return values locally.
    debugPrint(
      'Renewal API pending: extraMonths=$extraMonths, '
      'reinvestAmount=$reinvestAmount',
    );
  }

  // ==========================================
  // CLEAR SELECTED ASSET
  // ==========================================

  void clearSelectedAsset() {
    selectedAssetDetail.value = null;
    detailError.value = '';
  }

  // ==========================================
  // REFRESH
  // ==========================================

  Future<void> refreshPortfolio() async {
    await loadPortfolioOverview();
  }
}
