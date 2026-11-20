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
  String? _copiedField;

  String _formatInr(int amount) {
    final String str = amount.abs().toString();
    if (str.length <= 3) return '₹$str';
    final String lastThree = str.substring(str.length - 3);
    final String rest = str.substring(0, str.length - 3);
    final RegExp reg = RegExp(r'\B(?=(\d{2})+(?!\d))');
    final String formattedRest = rest.replaceAllMapped(reg, (m) => '${m[0]},');
    return '₹$formattedRest,$lastThree';
  }

  Future<void> _copy(String value, String label, String key) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    setState(() => _copiedField = key);

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
    if (mounted && _copiedField == key) {
      setState(() => _copiedField = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PortfolioAssetItemModel asset = widget.asset;
    final bool idCopied = _copiedField == 'id';
    final bool plateCopied = _copiedField == 'plate';

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
            SizedBox(
              height: 175,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    asset.primaryImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.surfaceMuted,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.electric_scooter_rounded,
                        size: 44,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: () => _copy(asset.vehicleId, 'Vehicle ID', 'id'),
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
                              asset.vehicleId,
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
                        '● ${asset.status}',
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
                      child: Text(
                        '${asset.clusterCity} • ${asset.units} Unit(s)',
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.textInverse,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        asset.companyName,
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.accentDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _copy(
                          asset.vehicleNoPlate,
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
                                'Plate: ${asset.vehicleNoPlate}',
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${asset.vehicleModelName} (${asset.vehicleYearModel})',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 10),
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
                          height: 26,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${asset.clusterCity}, ${asset.clusterState}',
                    style: AppTextStyles.caption,
                  ),
                  Row(
                    children: [
                      Text(
                        'View Asset',
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
