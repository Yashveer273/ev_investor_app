import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../components/ev_product_model.dart';
import '../components/home_controller.dart';

class ProductCardWidget extends StatelessWidget {
  const ProductCardWidget({super.key});

  HomeController _resolveController() {
    if (Get.isRegistered<HomeController>()) {
      return Get.find<HomeController>();
    }
    return Get.put(HomeController());
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
    final HomeController controller = _resolveController();

    return Obx(() {
      final List<EVProductModel> items = controller.filteredProducts;
      final int limit = controller.visibleProductCount.value;
      final int showingCount = limit < items.length ? limit : items.length;
      final List<EVProductModel> visibleItems = items
          .take(showingCount)
          .toList();
      final bool hasMore = items.length > showingCount;

      return Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'ELECTRIC SCOOTER FLEET',
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Showing $showingCount of ${items.length} Scooters',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (visibleItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No electric scooters found.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _SingleProductCard(
                    product: visibleItems[index],
                    controller: controller,
                    formatInr: _formatInr,
                  );
                },
              ),

            // Load More Scooters button connected to HomeController
            if (items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton(
                  onPressed: hasMore ? controller.loadMoreScooters : null,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    disabledBackgroundColor: AppColors.surfaceMuted,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    hasMore
                        ? 'Load More Scooters ▾'
                        : 'All Scooters Loaded ($showingCount/${items.length})',
                    style: AppTextStyles.badge.copyWith(
                      color: hasMore
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _SingleProductCard extends StatefulWidget {
  final EVProductModel product;
  final HomeController controller;
  final String Function(int) formatInr;

  const _SingleProductCard({
    required this.product,
    required this.controller,
    required this.formatInr,
  });

  @override
  State<_SingleProductCard> createState() => _SingleProductCardState();
}

class _SingleProductCardState extends State<_SingleProductCard> {
  String? _copiedField;

  Future<void> _copyText(String value, String label, String fieldKey) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    setState(() => _copiedField = fieldKey);

    Get.snackbar(
      'Copied',
      '$label ($value) copied.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primary,
      colorText: AppColors.textInverse,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(12),
    );

    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted && _copiedField == fieldKey) {
      setState(() => _copiedField = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final EVProductModel product = widget.product;
    final HomeController controller = widget.controller;
    final bool idCopied = _copiedField == 'id';
    final bool plateCopied = _copiedField == 'plate';

    return GestureDetector(
      onTap: () => controller.openProductSpecs(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 195,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.primaryImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.surfaceMuted,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.electric_scooter_rounded,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: () =>
                          _copyText(product.vehicleId, 'Vehicle ID', 'id'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: idCopied
                                ? AppColors.accentDark
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.vehicleId,
                              style: AppTextStyles.badge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              idCopied ? Icons.check : Icons.copy_rounded,
                              size: 13,
                              color: idCopied
                                  ? AppColors.accentDark
                                  : AppColors.textSecondary,
                            ),
                            if (idCopied) ...[
                              const SizedBox(width: 3),
                              Text(
                                'Copied',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentDark,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '● ${product.status}',
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.accentDark,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.accentMint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.clusterCity} Hub',
                            style: AppTextStyles.badge.copyWith(
                              color: AppColors.textInverse,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.companyName,
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.accentDark,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _copyText(
                          product.vehicleNoPlate.toUpperCase(),
                          'Plate Number',
                          'plate',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: plateCopied
                                ? AppColors.accentLight
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: plateCopied
                                  ? AppColors.accentDark
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Plate: ',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                product.vehicleNoPlate.toUpperCase(),
                                style: AppTextStyles.badge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                plateCopied ? Icons.check : Icons.copy_rounded,
                                size: 12,
                                color: plateCopied
                                    ? AppColors.accentDark
                                    : AppColors.textSecondary,
                              ),
                              if (plateCopied) ...[
                                const SizedBox(width: 2),
                                Text(
                                  'Copied',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentDark,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.vehicleModelName} (${product.vehicleYearModel})',
                    style: AppTextStyles.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Investment',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.formatInr(product.investmentAmount),
                                style: AppTextStyles.badge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: AppColors.border,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly Return',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.formatInr(product.investorReturnRate)}/mo',
                                style: AppTextStyles.badge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: AppColors.border,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profit (${product.profitPercentage}%)',
                                style: AppTextStyles.badge.copyWith(
                                  color: AppColors.accentDark,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+${widget.formatInr(product.totalProfit)}',
                                style: AppTextStyles.badge.copyWith(
                                  color: AppColors.accentDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${product.clusterCity}, ${product.clusterState}',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Obx(() {
                    final int addedCount = controller
                        .getReservedCountForProduct(product.id);
                    final bool isAdded = addedCount > 0;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAdded) ...[
                          GestureDetector(
                            onTap: () =>
                                controller.removeReservedProduct(product),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.remove,
                                size: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        GestureDetector(
                          onTap: () => controller.reserveProduct(product),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isAdded
                                  ? AppColors.accent
                                  : AppColors.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAdded
                                      ? Icons.check_circle_outline
                                      : Icons.add_circle_outline,
                                  size: 14,
                                  color: isAdded
                                      ? const Color(0xFF020617)
                                      : AppColors.accentDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAdded ? 'Added ($addedCount)' : 'Add',
                                  style: AppTextStyles.badge.copyWith(
                                    color: isAdded
                                        ? const Color(0xFF020617)
                                        : AppColors.accentDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => controller.openProductSpecs(product),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Specs',
                            style: AppTextStyles.badge.copyWith(
                              color: AppColors.textInverse,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right,
                            size: 15,
                            color: AppColors.textInverse,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
