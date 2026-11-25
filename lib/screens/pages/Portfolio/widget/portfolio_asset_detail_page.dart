import 'dart:async';

import 'package:ev_investors_app/screens/pages/Portfolio/widget/portfolio_returns_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import 'package:ev_investors_app/screens/pages/Portfolio/components/portfolio_controller.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/components/portfolio_model.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/widget/portfolio_product_spec_page.dart';
import 'portfolio_renew_sheet.dart';

class PortfolioAssetDetailPage extends StatefulWidget {
  final String assetId;

  const PortfolioAssetDetailPage({super.key, required this.assetId});

  @override
  State<PortfolioAssetDetailPage> createState() =>
      _PortfolioAssetDetailPageState();
}

class _PortfolioAssetDetailPageState extends State<PortfolioAssetDetailPage> {
  late final PortfolioController controller;

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    controller = Get.isRegistered<PortfolioController>()
        ? Get.find<PortfolioController>()
        : Get.put(PortfolioController());

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatInr(int amount) {
    final String str = amount.abs().toString();

    if (str.length <= 3) return '₹$str';

    final String lastThree = str.substring(str.length - 3);
    final String rest = str.substring(0, str.length - 3);

    final RegExp reg = RegExp(r'\B(?=(\d{2})+(?!\d))');
    final String formattedRest = rest.replaceAllMapped(reg, (m) => '${m[0]},');

    return '${amount < 0 ? '-' : ''}₹$formattedRest,$lastThree';
  }

  String _getProductId(PortfolioProductModel product) {
    return product.id.toString().trim();
  }

  DateTime? _parseDate(String rawDate) {
    final String value = rawDate.trim();

    if (value.isEmpty) return null;

    final DateTime? isoDate = DateTime.tryParse(value);

    if (isoDate != null) {
      return DateTime(isoDate.year, isoDate.month, isoDate.day);
    }

    final List<String> parts = value.split(RegExp(r'[/\-]'));

    if (parts.length == 3) {
      final int? first = int.tryParse(parts[0]);
      final int? second = int.tryParse(parts[1]);
      final int? third = int.tryParse(parts[2]);

      if (first != null && second != null && third != null) {
        // Supports dd/MM/yyyy and yyyy-MM-dd.
        if (parts[0].length == 4) {
          return DateTime(first, second, third);
        }

        return DateTime(third, second, first);
      }
    }

    return null;
  }

  String _formatHumanDate(String rawDate) {
    final DateTime? date = _parseDate(rawDate);

    if (date == null) return '-';

    const List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  DateTime? _getDueDateTime(String rawDate) {
    final DateTime? date = _parseDate(rawDate);
    if (date == null) return null;

    return DateTime(date.year, date.month, date.day);
  }

  Duration? _getRemainingTime(String rawDate) {
    final DateTime? dueDateTime = _getDueDateTime(rawDate);

    if (dueDateTime == null) return null;

    return dueDateTime.difference(DateTime.now());
  }

  bool _isReinvestmentDue(String rawDate) {
    final Duration? remaining = _getRemainingTime(rawDate);

    return remaining != null && remaining.inSeconds <= 0;
  }

  String _formatCountdown(String rawDate) {
    final Duration? remaining = _getRemainingTime(rawDate);

    if (remaining == null) {
      return 'Date not available';
    }

    if (remaining.inSeconds <= 0) {
      return 'Reinvestment is due';
    }

    final int days = remaining.inDays;
    final int hours = remaining.inHours % 24;
    final int minutes = remaining.inMinutes % 60;
    final int seconds = remaining.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m ${seconds}s remaining';
    }

    return '${hours}h ${minutes}m ${seconds}s remaining';
  }

  String _shortAssetId(String value) {
    final String id = value.trim();

    if (id.length <= 16) return id;

    return '${id.substring(0, 8)}...${id.substring(id.length - 4)}';
  }

  Future<void> _copyValue(
    BuildContext context,
    String value,
    String label,
  ) async {
    if (value.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: value.trim()));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _copyableId({
    required BuildContext context,
    required String label,
    required String value,
    bool shorten = false,
  }) {
    final String displayValue = shorten ? _shortAssetId(value) : value;

    return _rowItem(
      label,
      value.isEmpty ? '-' : displayValue,
      trailing: value.isEmpty
          ? null
          : IconButton(
              onPressed: () => _copyValue(context, value, label),
              icon: const Icon(
                Icons.copy_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              tooltip: 'Copy $label',
            ),
    );
  }

  Widget _rowItem(
    String label,
    String value, {
    bool highlight = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: highlight
                          ? AppColors.accentDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 5), trailing],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
          const SizedBox(height: 8),
          ...children.asMap().entries.map((entry) {
            return Column(
              children: [
                entry.value,
                if (entry.key != children.length - 1)
                  Divider(height: 1, color: AppColors.border),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _openReinvestmentSheet(
    BuildContext context,
    PortfolioAssetDetailModel detail,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PortfolioRenewSheet(
        detail: detail,
        onConfirm: (reinvestAmount) {
          return controller.renewSelectedAsset(reinvestAmount: reinvestAmount);
        },
      ),
    );
  }

  Widget _reinvestButton({
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: enabled
              ? AppColors.accentLight
              : AppColors.background,
          foregroundColor: Colors.grey.shade700,
          disabledForegroundColor: Colors.grey.shade500,
          side: BorderSide(
            color: enabled ? AppColors.accentDark : AppColors.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_money_rounded,
              size: 19,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              'Reinvest',
              style: AppTextStyles.badge.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextInvestmentPanel({
    required String date,
    required bool canReinvest,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Next Investment', style: AppTextStyles.bodyBold),
              ),
              Text(
                canReinvest ? 'Available' : 'Scheduled',
                style: AppTextStyles.badge.copyWith(
                  color: canReinvest
                      ? AppColors.accentDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _rowItem('Investment Date', _formatHumanDate(date)),
          Divider(height: 1, color: AppColors.border),
          _rowItem(
            canReinvest ? 'Status' : 'Time Remaining',
            canReinvest ? 'Reinvestment is due' : _formatCountdown(date),
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _graphErrorWidget(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.show_chart,
              size: 28,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Graph Unavailable',
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Investment graph data could not be loaded. Please try again.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              controller.loadSelectedAssetGraph(
                assetId: widget.assetId,
                months: controller.selectedAssetGraphMonths.value,
                forceRefresh: true,
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              error,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Asset Details', style: AppTextStyles.h2),
      ),
      body: Obx(() {
        if (controller.isLoadingDetail.value &&
            controller.selectedAssetDetail.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final PortfolioAssetDetailModel? detail =
            controller.selectedAssetDetail.value;

        if (detail == null || detail.asset.assetId != widget.assetId) {
          return Center(
            child: Text(
              controller.detailError.value.isNotEmpty
                  ? controller.detailError.value
                  : 'Asset details unavailable.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          );
        }

        final sum = detail.assetSummary;
        final product = detail.asset.product;

        final String productId = _getProductId(product);
        final String currentAssetId = detail.asset.assetId;
        final String nextReinvestmentDate = detail.nextPayment.date;

        final bool canReinvest = _isReinvestmentDue(nextReinvestmentDate);

        final PortfolioGraphData assetMonthlyGraph = controller
            .getSelectedAssetGraph();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ASSET HEADER
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
                        Expanded(
                          child: Text(
                            '${product.brand} ${product.modelName} (${product.modelYear})',
                            style: AppTextStyles.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '● ${detail.asset.status}',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.accentDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _copyableId(
                      context: context,
                      label: 'Asset ID',
                      value: currentAssetId,
                      shorten: true,
                    ),

                    _copyableId(
                      context: context,
                      label: 'Product ID',
                      value: productId,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Product: ${product.type} • ${product.category}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Get.to(
                                  () => PortfolioProductSpecPage(
                                    product: product,
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.shopping_bag_outlined,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                              label: Text(
                                'View Product',
                                style: AppTextStyles.badge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.background,
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _reinvestButton(
                            enabled: canReinvest,
                            onPressed: canReinvest
                                ? () {
                                    _openReinvestmentSheet(context, detail);
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _nextInvestmentPanel(
                      date: nextReinvestmentDate,
                      canReinvest: canReinvest,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // GRAPH RANGE SELECTOR
              const SizedBox(height: 10),

              if (controller.isLoadingAssetGraph.value)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.assetGraphError.value.isNotEmpty)
                _graphErrorWidget(controller.assetGraphError.value)
              else
                PortfolioReturnsGraph(
                  title: 'Asset Investment & Return',
                  subtitle:
                      '${controller.selectedAssetGraphMonths.value} month timeline',
                  graphData: assetMonthlyGraph,
                  selectedMonths: controller.selectedAssetGraphMonths.value,
                  onRangeChanged: (months) {
                    return controller.changeSelectedAssetGraphRange(months);
                  },
                ),

              const SizedBox(height: 16),

              // SUMMARY
              _sectionContainer(
                title: 'Summary',
                children: [
                  _rowItem('Invested Amount', _formatInr(sum.investedAmount)),
                  _rowItem('Purchased On', _formatHumanDate(sum.purchaseDate)),
                  _rowItem(
                    'Monthly Return',
                    '${_formatInr(sum.monthlyReturn)} / mo',
                    highlight: true,
                  ),
                  _rowItem(
                    'Total Returned',
                    _formatInr(sum.totalReturnedAmount),
                    highlight: true,
                  ),
                  _rowItem(
                    'Next Return',
                    '${_formatInr(sum.nextReturnAmount)} (${_formatHumanDate(sum.nextReturnDate)})',
                    highlight: true,
                  ),
                  _rowItem(
                    'Next Reinvestment',
                    _formatHumanDate(nextReinvestmentDate),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _graphRangeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? AppColors.accentDark
              : AppColors.background,
          foregroundColor: selected ? Colors.white : AppColors.textPrimary,
          side: BorderSide(
            color: selected ? AppColors.accentDark : AppColors.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: AppTextStyles.badge.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
