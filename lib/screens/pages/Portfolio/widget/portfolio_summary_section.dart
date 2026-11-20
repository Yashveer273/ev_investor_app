import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../components/portfolio_model.dart';

class PortfolioSummarySection extends StatelessWidget {
  final DeployedCapitalSummary summary;

  const PortfolioSummarySection({super.key, required this.summary});

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
    return Column(
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
