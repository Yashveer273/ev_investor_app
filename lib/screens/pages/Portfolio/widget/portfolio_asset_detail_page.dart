import 'package:ev_investors_app/screens/pages/Portfolio/widget/portfolio_returns_graph.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../components/app_button.dart';
import '../../Home/widget/product_spec_page.dart';
import '../components/portfolio_controller.dart';
import '../components/portfolio_model.dart';
import 'portfolio_renew_sheet.dart';

class PortfolioAssetDetailPage extends StatelessWidget {
  final String assetId;

  const PortfolioAssetDetailPage({super.key, required this.assetId});

  PortfolioController _resolveController() {
    if (Get.isRegistered<PortfolioController>()) {
      return Get.find<PortfolioController>();
    }
    return Get.put(PortfolioController());
  }

  String _formatInr(int amount) {
    final String str = amount.abs().toString();
    if (str.length <= 3) return '₹$str';
    final String lastThree = str.substring(str.length - 3);
    final String rest = str.substring(0, str.length - 3);
    final RegExp reg = RegExp(r'\B(?=(\d{2})+(?!\d))');
    final String formattedRest = rest.replaceAllMapped(reg, (m) => '${m[0]},');
    return '₹$formattedRest,$lastThree';
  }

  @override
  Widget build(BuildContext context) {
    final PortfolioController controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Asset Details', style: AppTextStyles.h2),
      ),
      body: Obx(() {
        if (controller.isLoadingDetail.value &&
            controller.selectedAssetDetail.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final PortfolioAssetDetailModel? detail =
            controller.selectedAssetDetail.value;
        if (detail == null) {
          return Center(
            child: Text(
              'Asset details unavailable.',
              style: AppTextStyles.bodyMedium,
            ),
          );
        }

        final spec = detail.productSpecs;
        final sum = detail.assetSummary;
        final ren = detail.renewal;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Asset Name, Location & Compact View Specs / Renew Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${spec.vehicleModelName} (${spec.vehicleId})',
                            style: AppTextStyles.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '● ${detail.status}',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.accentDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${spec.clusterStreetAddress}, ${spec.clusterCity} - ${spec.clusterZipCode}, ${spec.clusterState}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Store ID: ${detail.storeId}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Get.to(() => ProductSpecPage(product: spec));
                            },
                            icon: const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.textPrimary,
                            ),
                            label: Text(
                              'View Specs',
                              style: AppTextStyles.badge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.background,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        if (ren.isRenewable) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: AppButton(
                                label: 'Renew',
                                type: AppButtonType.primary,
                                icon: Icons.autorenew,
                                onPressed: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    backgroundColor: AppColors.surface,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (_) => PortfolioRenewSheet(
                                      detail: detail,
                                      onConfirm: (months, extraAmt) =>
                                          controller.renewSelectedAsset(
                                            extraMonths: months,
                                            reinvestAmount: extraAmt,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Smooth Animated Graph (6M / 12M)
              PortfolioReturnsGraph(
                title: 'Asset Investment & Return',
                subtitle: 'Monthly timeline by date',
                graphData: detail.assetGraph,
              ),

              const SizedBox(height: 16),

              // Simple Non-Technical Summary (Invested Amount, Purchase Date, Return)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Summary', style: AppTextStyles.h3),
                    const SizedBox(height: 12),
                    _rowItem('Invested Amount', _formatInr(sum.investedAmount)),
                    _rowItem(
                      'Purchased On',
                      sum.purchaseDate.isEmpty ? '-' : sum.purchaseDate,
                    ),
                    _rowItem(
                      'Monthly Return',
                      '${_formatInr(sum.monthlyReturn)} / mo',
                      highlight: true,
                    ),
                    _rowItem(
                      'Next Return',
                      '${_formatInr(sum.nextReturnAmount)} (${sum.nextReturnDate})',
                      highlight: true,
                    ),
                    _rowItem(
                      'Plan Duration',
                      '${ren.completedMonths}/${ren.tenureMonths} Months',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _rowItem(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyRegular),
          Text(
            value,
            style: AppTextStyles.bodyBold.copyWith(
              color: highlight ? AppColors.accentDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
