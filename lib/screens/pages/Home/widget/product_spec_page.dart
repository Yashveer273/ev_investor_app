import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../components/app_button.dart';
import '../components/ev_product_model.dart';
import '../components/home_controller.dart';

class ProductSpecPage extends StatefulWidget {
  final EVProductModel product;

  const ProductSpecPage({super.key, required this.product});

  @override
  State<ProductSpecPage> createState() => _ProductSpecPageState();
}

class _ProductSpecPageState extends State<ProductSpecPage> {
  int units = 1;
  int selectedImageIndex = 0;

  HomeController _resolveController() {
    if (Get.isRegistered<HomeController>()) {
      return Get.find<HomeController>();
    }
    return Get.put(HomeController());
  }

  void _onInvestNow(
    BuildContext context,
    HomeController controller,
    EVProductModel p,
  ) {
    final int totalInvest = p.investmentAmount * units;
    final int totalMonthly = p.investorReturnRate * units;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Invest in Scooter', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              Text(
                '${p.vehicleModelName} (${p.vehicleId}) • ${p.clusterCity} Hub',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Scooter Units', style: AppTextStyles.bodyRegular),
                  Text('$units', style: AppTextStyles.bodyBold),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Investment', style: AppTextStyles.bodyRegular),
                  Text('₹$totalInvest', style: AppTextStyles.bodyBold),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Monthly Return', style: AppTextStyles.bodyRegular),
                  Text(
                    '₹$totalMonthly / mo',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.accentDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      type: AppButtonType.secondary,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'Proceed',
                      type: AppButtonType.primary,
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        controller.reserveProduct(
                          p,
                          units: units,
                          openCart: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeController controller = _resolveController();
    final EVProductModel p = widget.product;
    final List<VehicleImageItem> gallery = p.angleGallery;
    final int safeIndex = selectedImageIndex < gallery.length
        ? selectedImageIndex
        : 0;
    final String activeImageUrl = gallery[safeIndex].url;

    final int totalInvest = p.investmentAmount * units;
    final int totalMonthly = p.investorReturnRate * units;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('${p.vehicleModelName} Specs', style: AppTextStyles.h2),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Obx(() {
              final int totalCount = controller.totalReservedUnits;
              return TextButton.icon(
                onPressed: controller.openReservedAssetsPage,
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                label: Text(
                  'Added ($totalCount)',
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main Scooter Image (Crop/Zoom controls removed)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                activeImageUrl,
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 230,
                  color: AppColors.surfaceMuted,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.electric_scooter_rounded,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Multiple Angle Thumbnails
            Row(
              children: List.generate(gallery.length, (index) {
                final bool isSelected = index == safeIndex;
                final VehicleImageItem item = gallery[index];

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < gallery.length - 1 ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedImageIndex = index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.url,
                                height: 56,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  height: 56,
                                  color: AppColors.surfaceMuted,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.electric_scooter_rounded,
                                    size: 22,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Cluster Location Card (before Investment Configurator)
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
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.accentDark,
                      ),
                      const SizedBox(width: 6),
                      Text('Cluster Location Object', style: AppTextStyles.h3),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(p.clusterStreetAddress, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'City: ${p.clusterCity}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Zip: ${p.clusterZipCode}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'State: ${p.clusterState}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Investment Configurator Card
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
                  Text('Investment Configurator', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Units', style: AppTextStyles.bodyMedium),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (units > 1) setState(() => units--);
                              },
                              icon: const Icon(Icons.remove),
                            ),
                            Text('$units', style: AppTextStyles.h3),
                            IconButton(
                              onPressed: () => setState(() => units++),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Investment',
                        style: AppTextStyles.bodyRegular,
                      ),
                      Text('₹$totalInvest', style: AppTextStyles.bodyBold),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monthly Return', style: AppTextStyles.bodyRegular),
                      Text(
                        '₹$totalMonthly / mo',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.accentDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Compact Row: Add / Added (- button when added) + Invest Now
                  Obx(() {
                    final int addedCount = controller
                        .getReservedCountForProduct(p.id);
                    final bool isAdded = addedCount > 0;

                    return Row(
                      children: [
                        if (isAdded) ...[
                          GestureDetector(
                            onTap: () => controller.removeReservedProduct(p),
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.remove,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: AppButton(
                              label: isAdded ? 'Added ($addedCount)' : 'Add',
                              type: AppButtonType.secondary,
                              icon: isAdded
                                  ? Icons.check_circle_outline
                                  : Icons.add_circle_outline,
                              onPressed: () {
                                controller.reserveProduct(p, units: units);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: AppButton(
                              label: 'Invest Now',
                              type: AppButtonType.primary,
                              onPressed: () =>
                                  _onInvestNow(context, controller, p),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Technical Specs Table
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text('TECHNICAL SPECS', style: AppTextStyles.badge),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _specRow('Vehicle ID', p.vehicleId),
                  _specRow('Motor Power', '${p.vehicleMotorPowerKw} kW'),
                  _specRow('Battery Capacity', '${p.batteryCapacityKwh} kWh'),
                  _specRow('Range', '${p.rangeKm} km'),
                  _specRow('Top Speed', '${p.topSpeedKmph} km/h'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyRegular),
          Text(value, style: AppTextStyles.bodyBold),
        ],
      ),
    );
  }
}
