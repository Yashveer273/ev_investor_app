import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../components/portfolio_model.dart';

class PortfolioProductSpecPage extends StatefulWidget {
  final PortfolioProductModel product;

  const PortfolioProductSpecPage({super.key, required this.product});

  @override
  State<PortfolioProductSpecPage> createState() =>
      _PortfolioProductSpecPageState();
}

class _PortfolioProductSpecPageState extends State<PortfolioProductSpecPage> {
  int selectedImageIndex = 0;

  PortfolioProductModel get product => widget.product;

  List<String> get productImages {
    final List<String> images = [];

    if (product.primaryImageUrl.trim().isNotEmpty) {
      images.add(product.primaryImageUrl.trim());
    }

    for (final image in product.gallery) {
      final String url = image.trim();

      if (url.isNotEmpty && !images.contains(url)) {
        images.add(url);
      }
    }

    return images;
  }

  @override
  Widget build(BuildContext context) {
    final specs = product.specs;
    final images = productImages;

    final String mainImage = images.isNotEmpty
        ? images[selectedImageIndex.clamp(0, images.length - 1)]
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Product Specifications', style: AppTextStyles.h2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PRODUCT IMAGE AND INFORMATION
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MAIN IMAGE
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 230,
                      child: mainImage.isNotEmpty
                          ? Image.network(
                              mainImage,
                              width: double.infinity,
                              height: 230,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                    ),
                  ),

                  // IMAGE THUMBNAILS
                  if (images.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                      child: SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final bool isSelected = selectedImageIndex == index;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedImageIndex = index;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 76,
                                height: 76,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accentDark
                                        : AppColors.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.accentDark
                                                .withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Image.network(
                                    images[index],
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _thumbnailPlaceholder(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // PRODUCT INFORMATION
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product.brand} ${product.modelName}'.trim(),
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${product.type} • ${product.category}',
                          style: AppTextStyles.caption,
                        ),
                        if (product.summary.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            product.summary,
                            style: AppTextStyles.bodyRegular,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // PRODUCT DETAILS
            _section(
              title: 'Product Details',
              children: [
                _specRow('Brand', product.brand),
                _specRow('Model', product.modelName),
                _specRow('Model Year', product.modelYear.toString()),
                _specRow('Product Type', product.type),
                _specRow('Category', product.category),
                _specRow('Unit Price', '₹${product.unitPrice}'),
                _specRow(
                  'Monthly Return Rate',
                  '${product.monthlyReturnRate}%',
                ),
                _specRow(
                  'Monthly Return Amount',
                  '₹${product.explicitMonthlyReturnAmount}',
                ),
                _specRow('Expected Return', product.explicitExpectedReturn),
              ],
            ),

            const SizedBox(height: 16),

            // SPECIFICATIONS
            _section(
              title: 'Specifications',
              children: [
                _specRow('Brand / Model', specs.brandModel),
                _specRow('Vehicle Age', specs.vehicleAge),
                _specRow('Range', specs.range),
                _specRow('Battery', specs.battery),
                _specRow('Charging Time', specs.chargingTime),
              ],
            ),

            // INFORMATION
            if (product.infoTags.isNotEmpty) ...[
              const SizedBox(height: 16),
              _section(
                title: 'Information',
                children: product.infoTags
                    .map(
                      (tag) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: AppColors.accentDark,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tag,
                                style: AppTextStyles.bodyRegular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            // HIGHLIGHTS
            if (product.highlights.isNotEmpty) ...[
              const SizedBox(height: 16),
              _section(
                title: 'Highlights',
                children: product.highlights
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 7,
                              color: AppColors.accentDark,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: AppTextStyles.bodyRegular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder({double height = 230}) {
    return Container(
      width: double.infinity,
      height: height,
      color: AppColors.background,
      alignment: Alignment.center,
      child: Icon(
        Icons.electric_moped_outlined,
        size: 55,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 22,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyBold,
            ),
          ),
        ],
      ),
    );
  }
}
