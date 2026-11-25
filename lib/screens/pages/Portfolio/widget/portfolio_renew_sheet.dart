import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../components/app_button.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/components/portfolio_model.dart';

class PortfolioRenewSheet extends StatefulWidget {
  final PortfolioAssetDetailModel detail;

  final Future<void> Function(int reinvestAmount) onConfirm;

  const PortfolioRenewSheet({
    super.key,
    required this.detail,
    required this.onConfirm,
  });

  @override
  State<PortfolioRenewSheet> createState() => _PortfolioRenewSheetState();
}

class _PortfolioRenewSheetState extends State<PortfolioRenewSheet> {
  int _reinvestAmount = 0;
  bool _submitting = false;

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
    final int baseReturn = widget.detail.assetSummary.monthlyReturn;

    // No fixed-duration or automatic bonus calculation.
    // Monthly return remains the value supplied by the backend.
    final int updatedMonthlyReturn = baseReturn;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Renew Asset', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            '${widget.detail.asset.product.brand} ${widget.detail.asset.product.modelName}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 14),

          Text(
            'Additional Investment Amount (Optional)',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 8),

          Row(
            children: [0, 10000, 25000].map((amt) {
              final bool selected = _reinvestAmount == amt;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: amt != 25000 ? 8 : 0),
                  child: GestureDetector(
                    onTap: _submitting
                        ? null
                        : () {
                            setState(() {
                              _reinvestAmount = amt;
                            });
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accentLight
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppColors.accentDark
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        amt == 0 ? 'No Extra' : '+${_formatInr(amt)}',
                        style: AppTextStyles.badge.copyWith(
                          color: selected
                              ? AppColors.accentDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Additional Investment', style: AppTextStyles.bodyRegular),
              Text(_formatInr(_reinvestAmount), style: AppTextStyles.bodyBold),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Return', style: AppTextStyles.bodyRegular),
              Text(
                '${_formatInr(updatedMonthlyReturn)} / mo',
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
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: _submitting ? 'Updating...' : 'Confirm Renew',
                  type: AppButtonType.primary,
                  onPressed: _submitting
                      ? null
                      : () async {
                          setState(() {
                            _submitting = true;
                          });

                          try {
                            await widget.onConfirm(_reinvestAmount);

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() {
                                _submitting = false;
                              });
                            }

                            rethrow;
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
