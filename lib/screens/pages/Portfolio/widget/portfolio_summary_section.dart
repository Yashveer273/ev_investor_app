import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../components/portfolio_model.dart';
import '../widget/portfolio_history_page.dart';

class PortfolioSummarySection extends StatelessWidget {
  final DeployedCapitalSummary summary;

  const PortfolioSummarySection({super.key, required this.summary});

  String _formatInr(num amount) {
    final bool negative = amount < 0;
    final String value = amount.abs().toStringAsFixed(0);

    if (value.length <= 3) {
      return '${negative ? '-' : ''}₹$value';
    }

    final String lastThree = value.substring(value.length - 3);
    final String rest = value.substring(0, value.length - 3);
    final RegExp reg = RegExp(r'\B(?=(\d{2})+(?!\d))');

    return '${negative ? '-' : ''}₹${rest.replaceAllMapped(reg, (m) => '${m[0]},')},$lastThree';
  }

  void _openHistory() {
    Get.to(
      () => const PortfolioHistoryPage(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total Invested',
                value: _formatInr(summary.totalInvested),
                subLabel: '${summary.activeAssetsCount} Active Assets',
                valueColor: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'This Month Invested',
                value: _formatInr(summary.thisMonthInvested),
                subLabel: 'Current Month',
                valueColor: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Monthly Return',
                value: '${_formatInr(summary.totalMonthlyReturn)}/mo',
                subLabel: 'Total Active Return',
                valueColor: AppColors.accentDark,
                highlight: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'This Month Return',
                value: _formatInr(summary.thisMonthReturn),
                subLabel: 'Latest Payout',
                valueColor: AppColors.accentDark,
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Portfolio History Navigation
        SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openHistory,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accentDark.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: AppColors.accentLight.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: AppColors.accentDark,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Portfolio History',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'View all investments and payout transactions',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.accentDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subLabel;
  final Color valueColor;
  final bool highlight;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subLabel,
    required this.valueColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.accentLight.withValues(alpha: 0.45)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? AppColors.accentDark.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subLabel,
            style: AppTextStyles.caption.copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
