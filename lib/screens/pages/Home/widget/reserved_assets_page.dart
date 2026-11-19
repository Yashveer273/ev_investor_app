import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../components/app_button.dart';
import '../components/home_controller.dart';

class ReservedAssetsPage extends StatelessWidget {
  const ReservedAssetsPage({super.key});

  HomeController _resolveController() {
    if (Get.isRegistered<HomeController>()) {
      return Get.find<HomeController>();
    }
    return Get.put(HomeController());
  }

  void _backToHomeMarketplace(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final HomeController controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Reserved Investment Assets', style: AppTextStyles.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => _backToHomeMarketplace(context),
        ),
      ),
      body: Obx(() {
        final items = controller.reservedAssets;

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      size: 44,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text('No reserved assets yet', style: AppTextStyles.h3),
                    const SizedBox(height: 6),
                    Text(
                      'Reserve electric scooter assets from the fleet to review them here.',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Browse Fleet',
                      type: AppButtonType.primary,
                      onPressed: () => _backToHomeMarketplace(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final int totalPrincipal = items.fold<int>(
          0,
          (sum, item) => sum + item.totalInvestment,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = items[index];
                  final product = entry.product;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            product.primaryImageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 64,
                              height: 64,
                              color: AppColors.surfaceMuted,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.electric_scooter_rounded,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${product.vehicleModelName} (${product.vehicleId})',
                                style: AppTextStyles.bodyBold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${product.clusterCity} • Units: ${entry.units}',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${entry.totalInvestment} • +₹${entry.totalMonthlyReturn}/mo',
                                style: AppTextStyles.badge.copyWith(
                                  color: AppColors.accentDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => controller
                              .removeReservedItemCompletely(product.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Reserved Principal',
                          style: AppTextStyles.bodyRegular,
                        ),
                        Text('₹$totalPrincipal', style: AppTextStyles.h3),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'Browse Fleet',
                      type: AppButtonType.secondary,
                      isFullWidth: true,
                      onPressed: () => _backToHomeMarketplace(context),
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
}
