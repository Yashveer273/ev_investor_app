import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../components/portfolio_model.dart';

class PortfolioProductCard extends StatefulWidget {
  final PortfolioAssetItemModel asset;
  final VoidCallback onTap;

  const PortfolioProductCard({
    super.key,
    required this.asset,
    required this.onTap,
  });

  @override
  State<PortfolioProductCard> createState() => _PortfolioProductCardState();
}

class _PortfolioProductCardState extends State<PortfolioProductCard> {
  bool _productIdCopied = false;

  String _formatInr(int amount) {
    final String str = amount.abs().toString();

    if (str.length <= 3) return '₹$str';

    final String lastThree = str.substring(str.length - 3);
    final String rest = str.substring(0, str.length - 3);

    final RegExp reg = RegExp(r'\B(?=(\d{2})+(?!\d))');

    final String formattedRest = rest.replaceAllMapped(reg, (m) => '${m[0]},');

    return '₹$formattedRest,$lastThree';
  }

  String _unitLabel(int units) {
    return '$units ${units == 1 ? 'Unit' : 'Units'}';
  }

  String get _imageUrl {
    final String coverImage = widget.asset.product.coverImage.trim();

    if (coverImage.isNotEmpty) {
      return coverImage;
    }

    if (widget.asset.product.gallery.isNotEmpty) {
      return widget.asset.product.gallery.first;
    }

    return '';
  }

  Future<void> _copyProductId() async {
    final String id = widget.asset.productId.trim();

    if (id.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: id));

    if (!mounted) return;

    setState(() => _productIdCopied = true);

    Get.snackbar(
      'Copied',
      'Product ID copied successfully.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primary,
      colorText: AppColors.textInverse,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(12),
    );

    await Future<void>.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _productIdCopied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PortfolioAssetItemModel asset = widget.asset;
    final product = asset.product;

    final String productName = '${product.brand} ${product.modelName}'.trim();

    final String modelYear = product.modelYear > 0
        ? ' (${product.modelYear})'
        : '';

    final String imageUrl = _imageUrl;

    return GestureDetector(
      onTap: widget.onTap,
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
            // PRODUCT IMAGE
            SizedBox(
              height: 175,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  else
                    _imagePlaceholder(),

                  // Asset Status
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
                        '● ${asset.status}',
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.accentDark,
                        ),
                      ),
                    ),
                  ),

                  // Units
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _unitLabel(asset.units),
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.textInverse,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PRODUCT DETAILS
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand,
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.accentDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$productName$modelYear',
                    style: AppTextStyles.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Investment and return details
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
                          child: _miniStat(
                            'Invested Amount',
                            _formatInr(asset.investedAmount),
                            AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: AppColors.border,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _miniStat(
                            'Monthly Return',
                            '${_formatInr(asset.monthlyReturn)}/mo',
                            AppColors.accentDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // PRODUCT ID - BELOW IMAGE, WITH ELLIPSIS AND COPY
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Text(
                    'Product ID:',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      asset.productId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  GestureDetector(
                    onTap: _copyProductId,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _productIdCopied
                            ? AppColors.accentLight
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _productIdCopied
                              ? AppColors.accentDark
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _productIdCopied ? Icons.check : Icons.copy_rounded,
                            size: 13,
                            color: _productIdCopied
                                ? AppColors.accentDark
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _productIdCopied ? 'Copied' : 'Copy',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _productIdCopied
                                  ? AppColors.accentDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // VIEW ASSET
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: const Icon(
        Icons.electric_scooter_rounded,
        size: 44,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _miniStat(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          val,
          style: AppTextStyles.badge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
