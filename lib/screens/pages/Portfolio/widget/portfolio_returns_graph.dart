import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../components/portfolio_model.dart';

enum PortfolioGraphRange { sixMonths, twelveMonths }

enum PortfolioGraphMetric { monthlyReturn, investedAmount }

class PortfolioReturnsGraph extends StatefulWidget {
  final String title;
  final String subtitle;
  final PortfolioGraphData graphData;

  const PortfolioReturnsGraph({
    super.key,
    required this.title,
    required this.subtitle,
    required this.graphData,
  });

  @override
  State<PortfolioReturnsGraph> createState() => _PortfolioReturnsGraphState();
}

class _PortfolioReturnsGraphState extends State<PortfolioReturnsGraph>
    with SingleTickerProviderStateMixin {
  PortfolioGraphRange _range = PortfolioGraphRange.sixMonths;
  PortfolioGraphMetric _metric = PortfolioGraphMetric.monthlyReturn;
  int? _selectedIndex;

  late final AnimationController _animController;
  late final Animation<double> _curveProgress;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _curveProgress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant PortfolioReturnsGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graphData != widget.graphData) {
      _selectedIndex = null;
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _changeRange(PortfolioGraphRange next) {
    if (_range == next) return;
    setState(() {
      _range = next;
      _selectedIndex = null;
    });
    _animController.forward(from: 0);
  }

  void _changeMetric(PortfolioGraphMetric next) {
    if (_metric == next) return;
    setState(() {
      _metric = next;
      _selectedIndex = null;
    });
    _animController.forward(from: 0);
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

  String _formatCompactInr(int amount) {
    if (amount.abs() >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount.abs() >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '₹$amount';
  }

  String _formatFullInr(int amount) {
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
    final List<GraphPointModel> points = _range == PortfolioGraphRange.sixMonths
        ? widget.graphData.last6Months
        : widget.graphData.last12Months;

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
                  Text(
                    'Date: ${activePoint.date}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_metricLabel()}: ${_formatFullInr(activeValue)}',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.accentDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (points.length < 2)
            SizedBox(
              height: 165,
              child: Center(
                child: Text(
                  'Not enough date points for graph.',
                  style: AppTextStyles.caption,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                const double height = 165;
                return GestureDetector(
                  onTapDown: (details) {
                    final double step = width / (points.length - 1);
                    final int idx = (details.localPosition.dx / step)
                        .round()
                        .clamp(0, points.length - 1);
                    setState(() => _selectedIndex = idx);
                  },
                  child: AnimatedBuilder(
                    animation: _curveProgress,
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size(width, height),
                        painter: _SmoothCurveAreaPainter(
                          values: values,
                          progress: _curveProgress.value,
                          selectedIndex: activeIdx,
                          lineColor: AppColors.accentDark,
                          strokeColor: AppColors.primary,
                          areaTopColor: AppColors.accent.withValues(
                            alpha: 0.28,
                          ),
                          areaBottomColor: AppColors.accent.withValues(
                            alpha: 0.02,
                          ),
                          gridColor: AppColors.border,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          if (points.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(points.length, (index) {
                final bool showLabel =
                    points.length <= 6 ||
                    index == 0 ||
                    index == points.length - 1 ||
                    index % 2 == 0;
                final bool isSelected = index == activeIdx;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Text(
                      showLabel ? points[index].shortMonthLabel : '',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min: ${_formatCompactInr(values.reduce((a, b) => a < b ? a : b))}',
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
                Text(
                  'Max: ${_formatCompactInr(values.reduce((a, b) => a > b ? a : b))}',
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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

class _SmoothCurveAreaPainter extends CustomPainter {
  final List<int> values;
  final double progress;
  final int selectedIndex;
  final Color lineColor;
  final Color strokeColor;
  final Color areaTopColor;
  final Color areaBottomColor;
  final Color gridColor;

  _SmoothCurveAreaPainter({
    required this.values,
    required this.progress,
    required this.selectedIndex,
    required this.lineColor,
    required this.strokeColor,
    required this.areaTopColor,
    required this.areaBottomColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final int minVal = values.reduce((a, b) => a < b ? a : b);
    final int maxVal = values.reduce((a, b) => a > b ? a : b);
    final double range = (maxVal - minVal) == 0
        ? (maxVal == 0 ? 1.0 : maxVal.toDouble())
        : (maxVal - minVal).toDouble();

    const double topPad = 14;
    const double bottomPad = 14;
    final double usableHeight = size.height - topPad - bottomPad;

    final Paint gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (int i = 0; i <= 2; i++) {
      final double y = topPad + (usableHeight * (i / 2));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final List<Offset> allPoints = List.generate(values.length, (i) {
      final double x = (size.width * i) / (values.length - 1);
      final double norm = (values[i] - minVal) / range;
      final double targetY = topPad + usableHeight * (1 - norm);
      final double y =
          topPad +
          usableHeight -
          ((topPad + usableHeight - targetY) * progress);
      return Offset(x, y);
    });

    final Path curvePath = _buildSmoothPath(allPoints);

    final Path areaPath = Path.from(curvePath)
      ..lineTo(allPoints.last.dx, size.height - bottomPad)
      ..lineTo(allPoints.first.dx, size.height - bottomPad)
      ..close();

    final Paint areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [areaTopColor, areaBottomColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curvePath, linePaint);

    for (int i = 0; i < allPoints.length; i++) {
      final bool isSelected = i == selectedIndex;
      canvas.drawCircle(
        allPoints[i],
        isSelected ? 5.5 : 3.2,
        Paint()..color = isSelected ? strokeColor : lineColor,
      );
      if (isSelected) {
        canvas.drawCircle(allPoints[i], 2.3, Paint()..color = Colors.white);
      }
    }
  }

  Path _buildSmoothPath(List<Offset> pts) {
    final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final Offset p0 = pts[i];
      final Offset p1 = pts[i + 1];
      final double midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _SmoothCurveAreaPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
