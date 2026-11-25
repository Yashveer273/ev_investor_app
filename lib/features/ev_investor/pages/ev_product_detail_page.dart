import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/ev_coupon_controller.dart';
import '../controllers/ev_investor_controller.dart';
import '../models/ev_product_model.dart';
import 'ev_cart_page.dart';

class EvProductDetailPage extends StatefulWidget {
  final EvProductModel product;
  final EvInvestorController controller;
  final EvCouponController? couponController;
  final String? phone;
  final void Function(int units)? onUnitsAdded;
  final void Function(
    int payableAmount,
    int discountAmount,
    String? appliedCoupon,
  )?
  onRazorpaySlideComplete;

  const EvProductDetailPage({
    super.key,
    required this.product,
    required this.controller,
    this.couponController,
    this.phone,
    this.onUnitsAdded,
    this.onRazorpaySlideComplete,
  });

  @override
  State<EvProductDetailPage> createState() => _EvProductDetailPageState();
}

class _EvProductDetailPageState extends State<EvProductDetailPage>
    with TickerProviderStateMixin {
  final RxInt _selectedUnits = 1.obs;
  final RxInt _selectedGalleryIndex = 0.obs;

  final GlobalKey _basketKey = GlobalKey();
  final GlobalKey _addButtonKey = GlobalKey();

  final List<OverlayEntry> _activeFlyEntries = [];

  @override
  void dispose() {
    for (final entry in _activeFlyEntries) {
      if (entry.mounted) {
        entry.remove();
      }
    }
    _activeFlyEntries.clear();
    super.dispose();
  }

  void _triggerFlyQuantityAnimation(int units) {
    final overlayState = Overlay.maybeOf(context);
    final sourceContext = _addButtonKey.currentContext;
    final targetContext = _basketKey.currentContext;

    if (overlayState == null ||
        sourceContext == null ||
        targetContext == null) {
      return;
    }

    final sourceBox = sourceContext.findRenderObject() as RenderBox?;
    final targetBox = targetContext.findRenderObject() as RenderBox?;
    if (sourceBox == null ||
        targetBox == null ||
        !sourceBox.hasSize ||
        !targetBox.hasSize) {
      return;
    }

    final startOffset = sourceBox.localToGlobal(
      Offset(sourceBox.size.width / 2, sourceBox.size.height / 2),
    );
    final endOffset = targetBox.localToGlobal(
      Offset(targetBox.size.width / 2, targetBox.size.height / 2),
    );

    final flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    final curved = CurvedAnimation(
      parent: flyController,
      curve: Curves.easeInOutCubic,
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) {
        return AnimatedBuilder(
          animation: curved,
          builder: (context, child) {
            final t = curved.value;
            // Subtle upward arc along the flight path
            final arcLift = -42.0 * 4 * t * (1 - t);
            final dx = startOffset.dx + (endOffset.dx - startOffset.dx) * t;
            final dy =
                startOffset.dy + (endOffset.dy - startOffset.dy) * t + arcLift;
            final scale = (1.0 - (0.32 * t)).clamp(0.68, 1.0);
            final opacity = t > 0.85 ? ((1.0 - t) / 0.15).clamp(0.0, 1.0) : 1.0;

            return Positioned(
              left: dx - 18,
              top: dy - 18,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF059669,
                            ).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+$units',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    _activeFlyEntries.add(entry);
    overlayState.insert(entry);

    flyController.forward().whenCompleteOrCancel(() {
      if (entry.mounted) {
        entry.remove();
      }
      _activeFlyEntries.remove(entry);
      flyController.dispose();
    });
  }

  void _changeUnits(int delta) {
    final next = _selectedUnits.value + delta;
    if (next < 1 || next > 50) return;
    HapticFeedback.selectionClick();
    _selectedUnits.value = next;
  }

  void _handleAddAsset() {
    final units = _selectedUnits.value;
    widget.controller.updateCartUnits(widget.product.id, units);
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    _triggerFlyQuantityAnimation(units);
    if (widget.onUnitsAdded != null) {
      widget.onUnitsAdded!(units);
    }
  }

  void _handleRemoveProductFromCart() {
    widget.controller.removeCartProduct(widget.product.id);
    HapticFeedback.mediumImpact();
    _selectedUnits.value = 1;
  }

  Future<void> _copyProductId() async {
    final String productId = widget.product.id.trim();
    if (productId.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: productId));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product ID copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openCartPage() {
    Navigator.of(context).push(
      EvCartPage.route(
        controller: widget.controller,
        couponController: widget.couponController,
        phone: widget.phone,
        onRazorpaySlideComplete: widget.onRazorpaySlideComplete,
      ),
    );
  }

  List<String> _resolveGallery(EvProductModel ev) {
    final validGallery = ev.gallery.where((u) => u.trim().isNotEmpty).toList();
    if (validGallery.isNotEmpty) return validGallery;
    if (ev.coverImage.trim().isNotEmpty) return [ev.coverImage.trim()];
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.product;
    final gallery = _resolveGallery(ev);
    final monthlyAmount = ev.monthlyReturnAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFECFDF5),
                    Color(0xFFF0FDF4),
                    Color(0xFFE6F7EF),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFA7F3D0), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.white,
                    shape: CircleBorder(
                      side: BorderSide(
                        color: const Color(0xFF6EE7B7).withValues(alpha: 0.7),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 16,
                            color: Color(0xFF064E3B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    ev.type,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Obx(() {
                    final totalUnits = widget.controller.totalCartUnits;
                    return SizedBox(
                      key: _basketKey,
                      width: 36,
                      height: 36,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Material(
                            color: Colors.white,
                            shape: CircleBorder(
                              side: BorderSide(
                                color: const Color(
                                  0xFF6EE7B7,
                                ).withValues(alpha: 0.7),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: _openCartPage,
                              customBorder: const CircleBorder(),
                              child: const Center(
                                child: Icon(
                                  Icons.work_outline_rounded,
                                  size: 16,
                                  color: Color(0xFF064E3B),
                                ),
                              ),
                            ),
                          ),
                          if (totalUnits > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: IgnorePointer(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$totalUnits',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() {
                            final activeIndex = gallery.isEmpty
                                ? 0
                                : _selectedGalleryIndex.value.clamp(
                                    0,
                                    gallery.length - 1,
                                  );
                            final imageUrl = gallery.isNotEmpty
                                ? gallery[activeIndex]
                                : '';

                            return SizedBox(
                              height: 208,
                              width: double.infinity,
                              child: ColoredBox(
                                color: const Color(0xFFF1F5F9),
                                child: imageUrl.isEmpty
                                    ? _ImagePlaceholder(label: ev.type)
                                    : Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 208,
                                        gaplessPlayback: true,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return _ImagePlaceholder(
                                                label: ev.type,
                                              );
                                            },
                                      ),
                              ),
                            );
                          }),
                          if (gallery.length > 1)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Obx(() {
                                final currentIdx = _selectedGalleryIndex.value
                                    .clamp(0, gallery.length - 1);
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate(gallery.length, (
                                      idx,
                                    ) {
                                      final isSelected = idx == currentIdx;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        child: GestureDetector(
                                          onTap: () =>
                                              _selectedGalleryIndex.value = idx,
                                          child: Opacity(
                                            opacity: isSelected ? 1.0 : 0.6,
                                            child: Container(
                                              width: 64,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFECFDF5),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: isSelected
                                                    ? Border.all(
                                                        color: const Color(
                                                          0xFF065F46,
                                                        ),
                                                        width: 2,
                                                      )
                                                    : null,
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Image.network(
                                                gallery[idx],
                                                fit: BoxFit.cover,
                                                width: 64,
                                                height: 48,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return const ColoredBox(
                                                        color: Color(
                                                          0xFFE2E8F0,
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .image_not_supported_outlined,
                                                          size: 16,
                                                          color: Color(
                                                            0xFF64748B,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFA7F3D0,
                                  ).withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ev.type,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF064E3B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                ev.brand,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ev.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ev.type} • ${ev.specs.brandModel}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ev.summary,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Investment / Unit',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        EvInvestorController.formatINR(
                                          ev.unitPrice,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Monthly Return (${ev.expectedReturnLabel})',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '+${EvInvestorController.formatINR(monthlyAmount)} / mo',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF065F46),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'EV SPECIFICATIONS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: Color(0xFF064E3B),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (ev.id.trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: _DetailSpecBox(
                                        label: 'Product ID',
                                        value: ev.id,
                                        trailing: IconButton(
                                          onPressed: _copyProductId,
                                          icon: const Icon(
                                            Icons.copy_rounded,
                                            size: 16,
                                            color: Color(0xFF64748B),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 30,
                                            minHeight: 30,
                                          ),
                                          tooltip: 'Copy Product ID',
                                        ),
                                      ),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DetailSpecBox(
                                        label: 'Vehicle Type',
                                        value: ev.type,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _DetailSpecBox(
                                        label: 'Company & Model',
                                        value: ev.specs.brandModel,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DetailSpecBox(
                                        label: 'Certified Range',
                                        value: ev.specs.range,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _DetailSpecBox(
                                        label: 'Battery Capacity & Info',
                                        value: ev.specs.battery,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: _DetailSpecBox(
                                    label: 'Charging Time',
                                    value: ev.specs.chargingTime,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ASSET HIGHLIGHTS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: Color(0xFF064E3B),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...ev.highlights.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 16,
                                            color: Color(0xFF064E3B),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF475569),
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Obx(() {
              final units = _selectedUnits.value;
              final addedUnits = widget.controller.getCartUnitsForProduct(
                ev.id,
              );
              final totalAmount = ev.totalAmountForUnits(units);
              final estMonthlyReturn = ev.monthlyReturnForUnits(units);

              return Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: Color(0xFFA7F3D0), width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF064E3B).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount ($units ${units > 1 ? 'Units' : 'Unit'})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          EvInvestorController.formatINR(totalAmount),
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 20,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Monthly Return',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '+${EvInvestorController.formatINR(estMonthlyReturn)} / mo (${ev.monthlyReturnRate}%)',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF064E3B),
                          ),
                        ),
                      ],
                    ),
                    if (addedUnits > 0) ...[
                      const Divider(
                        height: 20,
                        thickness: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF064E3B,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFF064E3B,
                                ).withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Total Added Units: $addedUnits',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF064E3B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: const Color(0xFFFEF2F2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                color: Color(0xFFFECACA),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: _handleRemoveProductFromCart,
                              borderRadius: BorderRadius.circular(10),
                              splashColor: const Color(
                                0xFFFCA5A5,
                              ).withValues(alpha: 0.4),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Remove',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _changeUnits(-1),
                                    borderRadius: BorderRadius.circular(8),
                                    splashColor: const Color(
                                      0xFF6EE7B7,
                                    ).withValues(alpha: 0.45),
                                    child: const SizedBox(
                                      width: 36,
                                      height: 38,
                                      child: Center(
                                        child: Icon(
                                          Icons.remove_rounded,
                                          size: 17,
                                          color: Color(0xFF064E3B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    '$units',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF064E3B),
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _changeUnits(1),
                                    borderRadius: BorderRadius.circular(8),
                                    splashColor: const Color(
                                      0xFF6EE7B7,
                                    ).withValues(alpha: 0.45),
                                    child: const SizedBox(
                                      width: 36,
                                      height: 38,
                                      child: Center(
                                        child: Icon(
                                          Icons.add_rounded,
                                          size: 17,
                                          color: Color(0xFF064E3B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            key: _addButtonKey,
                            height: 46,
                            child: Material(
                              color: const Color(0xFF064E3B),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: _handleAddAsset,
                                borderRadius: BorderRadius.circular(12),
                                splashColor: const Color(
                                  0xFF34D399,
                                ).withValues(alpha: 0.35),
                                highlightColor: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.2),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 28),
                                  child: Center(
                                    child: Text(
                                      'Add',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DetailSpecBox extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _DetailSpecBox({
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1FAE5), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final String label;

  const _ImagePlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFECFDF5),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.electric_car_rounded,
            size: 36,
            color: Color(0xFF065F46),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF064E3B),
            ),
          ),
        ],
      ),
    );
  }
}
