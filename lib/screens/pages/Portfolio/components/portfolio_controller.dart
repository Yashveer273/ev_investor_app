import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../widget/portfolio_asset_detail_page.dart';
import 'portfolio_model.dart';

class PortfolioController extends GetxController {
  var isLoadingOverview = false.obs;
  var isLoadingDetail = false.obs;

  var deployedCapital = const DeployedCapitalSummary(
    totalInvested: 0,
    thisMonthInvested: 0,
    totalMonthlyReturn: 0,
    thisMonthReturn: 0,
    activeAssetsCount: 0,
  ).obs;

  var overallGraph = const PortfolioGraphData(points: []).obs;
  var portfolioAssets = <PortfolioAssetItemModel>[].obs;
  var selectedAssetDetail = Rxn<PortfolioAssetDetailModel>();

  @override
  void onInit() {
    super.onInit();
    loadPortfolioOverview();
  }

  Future<void> loadPortfolioOverview() async {
    isLoadingOverview.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final PortfolioOverviewResponse data =
        PortfolioOverviewResponse.dummyOverview();
    deployedCapital.value = data.deployedCapital;
    overallGraph.value = data.overallGraph;
    portfolioAssets.assignAll(data.portfolioAssets);

    isLoadingOverview.value = false;
  }

  Future<void> openAssetDetail(PortfolioAssetItemModel asset) async {
    isLoadingDetail.value = true;
    selectedAssetDetail.value = PortfolioAssetDetailModel.dummyDetailByAsset(
      asset,
    );
    Get.to(() => PortfolioAssetDetailPage(assetId: asset.id));

    await Future<void>.delayed(const Duration(milliseconds: 150));
    selectedAssetDetail.value = PortfolioAssetDetailModel.dummyDetailByAsset(
      asset,
    );
    isLoadingDetail.value = false;
  }

  Future<void> renewSelectedAsset({
    required int extraMonths,
    required int reinvestAmount,
  }) async {
    final PortfolioAssetDetailModel? current = selectedAssetDetail.value;
    if (current == null) return;

    final int newTenure = current.renewal.tenureMonths + extraMonths;
    final int newRemaining = (newTenure - current.renewal.completedMonths)
        .clamp(0, newTenure);
    final int newInvestedAmount =
        current.assetSummary.investedAmount + reinvestAmount;
    final int bonus =
        (current.assetSummary.monthlyReturn *
            current.renewal.renewalBonusPercent) ~/
        100;
    final int extraReturn = reinvestAmount > 0
        ? (reinvestAmount * 5) ~/ 100
        : 0;
    final int newMonthlyReturn =
        current.assetSummary.monthlyReturn + bonus + extraReturn;

    final PortfolioAssetDetailModel updatedDetail = PortfolioAssetDetailModel(
      id: current.id,
      investorId: current.investorId,
      vehicleId: current.vehicleId,
      storeId: current.storeId,
      status: 'Active',
      units: current.units,
      assetSummary: AssetSummaryModel(
        investedAmount: newInvestedAmount,
        purchaseDate: current.assetSummary.purchaseDate,
        monthlyReturn: newMonthlyReturn,
        nextReturnAmount: newMonthlyReturn,
        nextReturnDate: current.assetSummary.nextReturnDate,
      ),
      renewal: AssetRenewalModel(
        tenureMonths: newTenure,
        completedMonths: current.renewal.completedMonths,
        remainingMonths: newRemaining,
        isRenewable: true,
        renewalBonusPercent: current.renewal.renewalBonusPercent,
        renewedDate: '2026-11-20',
      ),
      assetGraph: current.assetGraph,
      productSpecs: current.productSpecs,
    );

    selectedAssetDetail.value = updatedDetail;

    final int idx = portfolioAssets.indexWhere((a) => a.id == current.id);
    if (idx != -1) {
      final PortfolioAssetItemModel old = portfolioAssets[idx];
      portfolioAssets[idx] = PortfolioAssetItemModel(
        id: old.id,
        investorId: old.investorId,
        vehicleId: old.vehicleId,
        storeId: old.storeId,
        vehicleNoPlate: old.vehicleNoPlate,
        vehicleModelName: old.vehicleModelName,
        vehicleYearModel: old.vehicleYearModel,
        companyName: old.companyName,
        vehicleImage: old.vehicleImage,
        clusterCity: old.clusterCity,
        clusterState: old.clusterState,
        units: old.units,
        investedAmount: newInvestedAmount,
        monthlyReturn: newMonthlyReturn,
        status: 'Active',
        isRenewable: true,
        purchaseDate: old.purchaseDate,
      );
      portfolioAssets.refresh();
    }

    final int returnDiff =
        newMonthlyReturn - current.assetSummary.monthlyReturn;
    deployedCapital.value = DeployedCapitalSummary(
      totalInvested: deployedCapital.value.totalInvested + reinvestAmount,
      thisMonthInvested:
          deployedCapital.value.thisMonthInvested + reinvestAmount,
      totalMonthlyReturn: deployedCapital.value.totalMonthlyReturn + returnDiff,
      thisMonthReturn: deployedCapital.value.thisMonthReturn + returnDiff,
      activeAssetsCount: deployedCapital.value.activeAssetsCount,
    );

    Get.snackbar(
      'Renewed',
      '${current.productSpecs.vehicleModelName} extended by +$extraMonths months.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primary,
      colorText: AppColors.textInverse,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(12),
    );
  }
}
