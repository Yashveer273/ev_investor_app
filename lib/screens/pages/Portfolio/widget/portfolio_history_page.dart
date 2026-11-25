import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PortfolioHistoryItem {
  final String productName;
  final String orderId;
  final String type;
  final num amount;
  final num receivedAmount;
  final num pendingAmount;
  final DateTime date;
  final String status;

  const PortfolioHistoryItem({
    required this.productName,
    required this.orderId,
    required this.type,
    required this.amount,
    this.receivedAmount = 0,
    this.pendingAmount = 0,
    required this.date,
    required this.status,
  });
}

class PortfolioHistoryPage extends StatefulWidget {
  final List<PortfolioHistoryItem> history;
  final bool isLoading;

  const PortfolioHistoryPage({
    super.key,
    this.history = const [],
    this.isLoading = false,
  });

  @override
  State<PortfolioHistoryPage> createState() => _PortfolioHistoryPageState();
}

class _PortfolioHistoryPageState extends State<PortfolioHistoryPage> {
  String selectedFilter = 'All';

  final List<String> filters = ['All', 'Investment', 'Payout'];

  List<PortfolioHistoryItem> get filteredHistory {
    final items = widget.history.where((item) {
      if (selectedFilter == 'All') return true;

      return item.type.toLowerCase() == selectedFilter.toLowerCase();
    }).toList();

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  String _formatInr(num amount) {
    final value = amount.abs().toStringAsFixed(0);

    if (value.length <= 3) {
      return '${amount < 0 ? '-' : ''}₹$value';
    }

    final lastThree = value.substring(value.length - 3);
    final rest = value.substring(0, value.length - 3);
    final reg = RegExp(r'\B(?=(\d{2})+(?!\d))');

    return '${amount < 0 ? '-' : ''}₹${rest.replaceAllMapped(reg, (m) => '${m[0]},')},$lastThree';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'received':
      case 'completed':
      case 'paid':
      case 'invested':
        return Colors.green;

      case 'pending':
      case 'processing':
        return Colors.orange;

      case 'failed':
      case 'rejected':
        return Colors.red;

      default:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredHistory;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'Portfolio History',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Transactions',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Track investments and payouts across all your products.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final filter = filters[index];
                        final selected = selectedFilter == filter;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFilter = filter;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.accentDark
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: selected
                                    ? AppColors.accentDark
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _HistoryCard(
                          item: items[index],
                          formatInr: _formatInr,
                          formatDate: _formatDate,
                          statusColor: _statusColor,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: AppColors.textPrimary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'No History Found',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Your investment and payout transactions will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final PortfolioHistoryItem item;
  final String Function(num) formatInr;
  final String Function(DateTime) formatDate;
  final Color Function(String) statusColor;

  const _HistoryCard({
    required this.item,
    required this.formatInr,
    required this.formatDate,
    required this.statusColor,
  });

  bool get isInvestment => item.type.toLowerCase() == 'investment';

  @override
  Widget build(BuildContext context) {
    final color = isInvestment ? AppColors.accentDark : Colors.green;

    return Container(
      padding: const EdgeInsets.all(15),
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
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isInvestment
                      ? Icons.trending_up_rounded
                      : Icons.account_balance_wallet_outlined,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Order ID: ${item.orderId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatInr(item.amount),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor(item.status).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: statusColor(item.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.textPrimary.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 6),
              Text(formatDate(item.date), style: AppTextStyles.caption),
              const Spacer(),
              Text(
                isInvestment ? 'Investment' : 'Payout',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (!isInvestment) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _AmountInfo(
                    label: 'Received',
                    amount: formatInr(item.receivedAmount),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AmountInfo(
                    label: 'Pending',
                    amount: formatInr(item.pendingAmount),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountInfo extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _AmountInfo({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 5),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
