import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/components/portfolio_controller.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/components/portfolio_model.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/widget/portfolio_product_card.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/widget/portfolio_returns_graph.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/widget/portfolio_summary_section.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  PortfolioController _resolveController() {
    if (Get.isRegistered<PortfolioController>()) {
      return Get.find<PortfolioController>();
    }
    return Get.put(PortfolioController());
  }

  @override
  Widget build(BuildContext context) {
    final PortfolioController controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingOverview.value &&
              controller.portfolioAssets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final DeployedCapitalSummary summary =
              controller.deployedCapital.value;

          final PortfolioGraphData graphData = controller.overallGraph.value;

          final List<PortfolioAssetItemModel> assets = controller
              .portfolioAssets
              .toList();

          return RefreshIndicator(
            onRefresh: controller.loadPortfolioOverview,
            color: AppColors.primary,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200 &&
                    !controller.isLoadingMore.value &&
                    controller.hasMorePages.value) {
                  controller.loadMorePortfolioAssets();
                }
                return false;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Portfolio', style: AppTextStyles.h1),
                            const SizedBox(height: 2),
                            Text(
                              'Active EV investments & monthly returns',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${assets.length} Assets',
                            style: AppTextStyles.badge.copyWith(
                              color: AppColors.accentDark,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    PortfolioSummarySection(summary: summary),
                    const SizedBox(height: 16),

                    PortfolioReturnsGraph(
                      title: 'Investment & Revenue Returns',
                      subtitle: 'Monthly performance by date',
                      graphData: graphData,
                      selectedMonths: controller.selectedGraphMonths.value,
                      onRangeChanged: controller.changeGraphRange,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'INVESTED SCOOTERS',
                      style: AppTextStyles.badge.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 0.6,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (assets.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text(
                            'No active EV investments found.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: assets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final PortfolioAssetItemModel item = assets[index];

                          return PortfolioProductCard(
                            asset: item,
                            onTap: () => controller.openAssetDetail(item),
                          );
                        },
                      ),

                    if (controller.isLoadingMore.value)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                    if (!controller.hasMorePages.value && assets.isNotEmpty)
                      const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
