import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/components/portfolio_model.dart';

enum PortfolioGraphRange { sixMonths, twelveMonths }

enum PortfolioGraphMetric { monthlyReturn, investedAmount }

class PortfolioReturnsGraph extends StatefulWidget {
  final String title;
  final String subtitle;
  final PortfolioGraphData graphData;
  final int selectedMonths;
  final Future<void> Function(int months)? onRangeChanged;

  const PortfolioReturnsGraph({
    super.key,
    required this.title,
    required this.subtitle,
    required this.graphData,
    this.selectedMonths = 6,
    this.onRangeChanged,
  });

  @override
  State<PortfolioReturnsGraph> createState() => _PortfolioReturnsGraphState();
}

class _PortfolioReturnsGraphState extends State<PortfolioReturnsGraph>
    with SingleTickerProviderStateMixin {
  PortfolioGraphMetric _metric = PortfolioGraphMetric.monthlyReturn;

  int? _selectedIndex;
  bool _changingRange = false;

  late PortfolioGraphRange _range;

  late final AnimationController _animController;
  late final Animation<double> _barProgress;

  final ScrollController _scrollController = ScrollController();
  final ScrollController _monthLabelScrollController = ScrollController();

  static const double _barWidth = 34;
  static const double _barSpacing = 18;
  static const double _chartHeight = 165;

  @override
  void initState() {
    super.initState();

    _range = widget.selectedMonths == 12
        ? PortfolioGraphRange.twelveMonths
        : PortfolioGraphRange.sixMonths;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _barProgress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLatest();
    });
  }

  @override
  void didUpdateWidget(covariant PortfolioReturnsGraph oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedMonths != widget.selectedMonths) {
      _range = widget.selectedMonths == 12
          ? PortfolioGraphRange.twelveMonths
          : PortfolioGraphRange.sixMonths;

      _selectedIndex = null;
    }

    if (oldWidget.graphData != widget.graphData ||
        oldWidget.selectedMonths != widget.selectedMonths) {
      _selectedIndex = null;
      _animController.forward(from: 0);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToLatest();
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    _monthLabelScrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }

    if (_monthLabelScrollController.hasClients) {
      _monthLabelScrollController.animateTo(
        _monthLabelScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _changeRange(PortfolioGraphRange next) async {
    if (_range == next || _changingRange) return;

    final int months = next == PortfolioGraphRange.sixMonths ? 6 : 12;

    setState(() {
      _range = next;
      _selectedIndex = null;
      _changingRange = true;
    });

    _animController.forward(from: 0);

    try {
      await widget.onRangeChanged?.call(months);
    } finally {
      if (mounted) {
        setState(() {
          _changingRange = false;
        });
      }
    }

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLatest();
    });
  }

  void _changeMetric(PortfolioGraphMetric next) {
    if (_metric == next) return;

    setState(() {
      _metric = next;
      _selectedIndex = null;
    });

    _animController.forward(from: 0);
  }

  List<GraphPointModel> get _points {
    if (_range == PortfolioGraphRange.sixMonths) {
      return widget.graphData.last6Months;
    }

    return widget.graphData.last12Months;
  }

  int _valueForPoint(GraphPointModel point) {
    switch (_metric) {
      case PortfolioGraphMetric.monthlyReturn:
        return point.monthlyReturn;
      case PortfolioGraphMetric.investedAmount:
        return point.investedAmount;
    }
  }

  String _metricLabel() {
    switch (_metric) {
      case PortfolioGraphMetric.monthlyReturn:
        return 'Monthly Return';
      case PortfolioGraphMetric.investedAmount:
        return 'Invested Amount';
    }
  }

  String _formatFullInr(int amount) {
    final bool isNegative = amount < 0;
    final String str = amount.abs().toString();

    if (str.length <= 3) {
      return '${isNegative ? '-' : ''}₹$str';
    }

    final String lastThree = str.substring(str.length - 3);
    final String rest = str.substring(0, str.length - 3);

    final RegExp reg = RegExp(r'\B(?=(\d{2})+(?!\d))');

    final String formattedRest = rest.replaceAllMapped(
      reg,
      (match) => '${match[0]},',
    );

    return '${isNegative ? '-' : ''}₹$formattedRest,$lastThree';
  }

  @override
  Widget build(BuildContext context) {
    final List<GraphPointModel> points = _points;
    final List<int> values = points.map(_valueForPoint).toList();

    final int activeIdx =
        (_selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < points.length)
        ? _selectedIndex!
        : (points.isNotEmpty ? points.length - 1 : 0);

    final GraphPointModel? activePoint = points.isNotEmpty
        ? points[activeIdx]
        : null;

    final int activeValue = activePoint != null
        ? _valueForPoint(activePoint)
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTextStyles.h3),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _rangeToggle(),
            ],
          ),

          if (_changingRange) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],

          const SizedBox(height: 12),

          Row(
            children: [
              _metricChip(
                label: 'Monthly Return',
                selected: _metric == PortfolioGraphMetric.monthlyReturn,
                onTap: () => _changeMetric(PortfolioGraphMetric.monthlyReturn),
              ),
              const SizedBox(width: 8),
              _metricChip(
                label: 'Invested Amount',
                selected: _metric == PortfolioGraphMetric.investedAmount,
                onTap: () => _changeMetric(PortfolioGraphMetric.investedAmount),
              ),
            ],
          ),

          if (activePoint != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Date: ${activePoint.monthYearLabel}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${_metricLabel()}: ${_formatFullInr(activeValue)}',
                      textAlign: TextAlign.end,
                      style: AppTextStyles.badge.copyWith(
                        color: AppColors.accentDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          if (points.isEmpty)
            SizedBox(
              height: _chartHeight,
              child: Center(
                child: Text(
                  'No investment records available.',
                  style: AppTextStyles.caption,
                ),
              ),
            )
          else
            _buildScrollableBarChart(points, values, activeIdx),

          if (points.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildMonthLabels(points, activeIdx),
          ],
        ],
      ),
    );
  }

  Widget _buildScrollableBarChart(
    List<GraphPointModel> points,
    List<int> values,
    int activeIdx,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double viewportWidth = constraints.maxWidth;

        final double contentWidth = points.length * (_barWidth + _barSpacing);

        final double chartWidth = contentWidth > viewportWidth
            ? contentWidth
            : viewportWidth;

        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final double itemWidth = _barWidth + _barSpacing;

              final int index = (details.localPosition.dx / itemWidth)
                  .floor()
                  .clamp(0, points.length - 1);

              setState(() {
                _selectedIndex = index;
              });

              _scrollLabelsToIndex(index);
            },
            child: AnimatedBuilder(
              animation: _barProgress,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(chartWidth, _chartHeight),
                  painter: _MonthlyBarChartPainter(
                    values: values,
                    progress: _barProgress.value,
                    selectedIndex: activeIdx,
                    currentMonthIndex: points.length - 1,
                    barWidth: _barWidth,
                    barSpacing: _barSpacing,
                    primaryColor: AppColors.primary,
                    highlightColor: AppColors.accentDark,
                    gridColor: AppColors.border,
                    selectedColor: AppColors.accent,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthLabels(List<GraphPointModel> points, int activeIdx) {
    return SingleChildScrollView(
      controller: _monthLabelScrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(points.length, (index) {
          final bool isCurrentMonth = index == points.length - 1;
          final bool isSelected = index == activeIdx;

          return SizedBox(
            width: _barWidth + _barSpacing,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });

                _scrollToIndex(index);
              },
              child: Text(
                points[index].shortMonthLabel,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  fontWeight: isSelected || isCurrentMonth
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isCurrentMonth
                      ? AppColors.accentDark
                      : isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _scrollLabelsToIndex(int index) {
    if (!_monthLabelScrollController.hasClients) return;

    final double offset = index * (_barWidth + _barSpacing);

    final double target = offset
        .clamp(0.0, _monthLabelScrollController.position.maxScrollExtent)
        .toDouble();

    _monthLabelScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;

    final double offset = index * (_barWidth + _barSpacing);

    final double target = offset
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );

    _scrollLabelsToIndex(index);
  }

  Widget _rangeToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rangePill(
            label: '6M',
            selected: _range == PortfolioGraphRange.sixMonths,
            onTap: () => _changeRange(PortfolioGraphRange.sixMonths),
          ),
          _rangePill(
            label: '12M',
            selected: _range == PortfolioGraphRange.twelveMonths,
            onTap: () => _changeRange(PortfolioGraphRange.twelveMonths),
          ),
        ],
      ),
    );
  }

  Widget _rangePill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTextStyles.badge.copyWith(
            fontSize: 11,
            color: selected ? AppColors.textInverse : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _metricChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accentLight : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.accentDark : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.badge.copyWith(
              fontSize: 11,
              color: selected ? AppColors.accentDark : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthlyBarChartPainter extends CustomPainter {
  final List<int> values;
  final double progress;
  final int selectedIndex;
  final int currentMonthIndex;

  final double barWidth;
  final double barSpacing;

  final Color primaryColor;
  final Color highlightColor;
  final Color gridColor;
  final Color selectedColor;

  _MonthlyBarChartPainter({
    required this.values,
    required this.progress,
    required this.selectedIndex,
    required this.currentMonthIndex,
    required this.barWidth,
    required this.barSpacing,
    required this.primaryColor,
    required this.highlightColor,
    required this.gridColor,
    required this.selectedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const double topPadding = 12;
    const double bottomPadding = 12;

    final double usableHeight = size.height - topPadding - bottomPadding;

    final int maxValue = values.reduce((a, b) => a > b ? a : b);

    final double scaleMax = maxValue <= 0 ? 1 : maxValue.toDouble();

    final Paint gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.65)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final double y = topPadding + usableHeight * (i / 3);

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double itemWidth = barWidth + barSpacing;

    for (int i = 0; i < values.length; i++) {
      final double x = i * itemWidth + (barSpacing / 2);

      final double rawHeight = (values[i] / scaleMax) * usableHeight;

      final double barHeight = rawHeight * progress;

      final double visibleHeight = values[i] > 0 ? barHeight : 2;

      final double top = size.height - bottomPadding - visibleHeight;

      final Rect barRect = Rect.fromLTWH(x, top, barWidth, visibleHeight);

      final bool isCurrentMonth = i == currentMonthIndex;

      final bool isSelected = i == selectedIndex;

      final Color barColor = isCurrentMonth ? highlightColor : primaryColor;

      final Paint barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(6)),
        barPaint,
      );

      if (isSelected) {
        final Paint selectedPaint = Paint()
          ..color = selectedColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect.inflate(2), const Radius.circular(7)),
          selectedPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyBarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.currentMonthIndex != currentMonthIndex;
  }
}
