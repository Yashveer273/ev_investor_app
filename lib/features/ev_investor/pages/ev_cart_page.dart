import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/ev_coupon_controller.dart';
import '../controllers/ev_investor_controller.dart';

class EvCartPage extends StatefulWidget {
  final EvInvestorController controller;
  final EvCouponController? couponController;
  final String? phone;
  final void Function(
    int payableAmount,
    int discountAmount,
    String? appliedCoupon,
  )?
  onRazorpaySlideComplete;

  const EvCartPage({
    super.key,
    required this.controller,
    this.couponController,
    this.phone,
    this.onRazorpaySlideComplete,
  });

  static Route<void> route({
    required EvInvestorController controller,
    EvCouponController? couponController,
    String? phone,
    void Function(int payableAmount, int discountAmount, String? appliedCoupon)?
    onRazorpaySlideComplete,
  }) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return EvCartPage(
          controller: controller,
          couponController: couponController,
          phone: phone,
          onRazorpaySlideComplete: onRazorpaySlideComplete,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  @override
  State<EvCartPage> createState() => _EvCartPageState();
}

class _EvCartPageState extends State<EvCartPage> {
  final TextEditingController _couponController = TextEditingController();
  late final EvCouponController _couponCtrl;

  @override
  void initState() {
    super.initState();
    _couponCtrl =
        widget.couponController ??
        (Get.isRegistered<EvCouponController>()
            ? Get.find<EvCouponController>()
            : Get.put(EvCouponController()));
    if (widget.phone != null && widget.phone!.trim().isNotEmpty) {
      _couponCtrl.setPhone(widget.phone!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _couponCtrl.clearCoupon();
      _couponController.clear();
    });
  }

  @override
  void dispose() {
    final couponCtrl = _couponCtrl;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      couponCtrl.clearCoupon();
    });
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _handleApplyCoupon() async {
    FocusScope.of(context).unfocus();
    await _couponCtrl.verifyCoupon(
      rawCode: _couponController.text,
      phone: widget.phone,
      orderAmount: widget.controller.grossCartAmount,
    );
  }

  void _handleRemoveCoupon() {
    _couponController.clear();
    _couponCtrl.clearCoupon();
  }

  void _handleSwipeCompleted() {
    final gross = widget.controller.grossCartAmount;
    final discount = _couponCtrl.discountAmountFor(gross);
    final payable = _couponCtrl.payableAmountFor(gross);
    final appliedCode = _couponCtrl.verifiedCoupon.value?.code;

    widget.controller.completeRazorpaySwipeCheckout(
      onRazorpaySlideComplete: (_, __, ___) {
        _couponCtrl.clearCoupon();
        _couponController.clear();
        if (widget.onRazorpaySlideComplete != null) {
          widget.onRazorpaySlideComplete!(payable, discount, appliedCode);
        }
      },
      onNavigateBack: () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'Selected Assets',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Obx(() {
                    final totalUnits = widget.controller.totalCartUnits;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF6EE7B7).withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$totalUnits ${totalUnits == 1 ? 'Unit' : 'Units'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF064E3B),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final items = widget.controller.cartItems;

                if (items.isEmpty) {
                  return const _EmptyEvCartState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final cartItem = items[index];
                    final ev = widget.controller.findProductById(cartItem.evId);
                    if (ev == null) return const SizedBox.shrink();

                    final subtotal = ev.totalAmountForUnits(cartItem.units);
                    final monthlyReturn = ev.monthlyReturnForUnits(
                      cartItem.units,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFA7F3D0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: Image.network(
                                ev.coverImage,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFECFDF5),
                                  alignment: Alignment.center,
                                  child: Text(
                                    ev.brand,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF064E3B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ev.type} • ${ev.brand}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ev.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${EvInvestorController.formatINR(subtotal)}  •  +${EvInvestorController.formatINR(monthlyReturn)}/mo',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF064E3B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${EvInvestorController.formatINR(ev.unitPrice)} / unit',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFA7F3D0),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => widget.controller
                                                .updateCartUnits(ev.id, -1),
                                            child: const SizedBox(
                                              width: 26,
                                              height: 26,
                                              child: Center(
                                                child: Icon(
                                                  Icons.remove_rounded,
                                                  size: 13,
                                                  color: Color(0xFF064E3B),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              '${cartItem.units}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF064E3B),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => widget.controller
                                                .updateCartUnits(ev.id, 1),
                                            child: const SizedBox(
                                              width: 26,
                                              height: 26,
                                              child: Center(
                                                child: Icon(
                                                  Icons.add_rounded,
                                                  size: 13,
                                                  color: Color(0xFF064E3B),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            Obx(() {
              if (widget.controller.cartItems.isEmpty &&
                  !widget.controller.swipeCheckoutCompleted.value) {
                return const SizedBox.shrink();
              }

              final grossAmount = widget.controller.grossCartAmount;
              final coupon = _couponCtrl.verifiedCoupon.value;
              final errorText = _couponCtrl.couponErrorMessage.value;
              final isVerifying = _couponCtrl.isVerifyingCoupon.value;
              final totalMonthlyReturn =
                  widget.controller.totalCartMonthlyReturn;
              final discount = _couponCtrl.discountAmountFor(grossAmount);
              final payableAmount = _couponCtrl.payableAmountFor(grossAmount);
              final isRewardDone =
                  widget.controller.swipeCheckoutCompleted.value;

              return Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
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
                  children: [
                    _RefinedCouponCard(
                      controller: _couponController,
                      appliedCode: coupon?.code,
                      discountAmount: discount > 0 ? discount : null,
                      errorMessage: errorText,
                      isLoading: isVerifying,
                      onApply: _handleApplyCoupon,
                      onRemove: _handleRemoveCoupon,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Est. Monthly Return',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '+${EvInvestorController.formatINR(totalMonthlyReturn)} / mo',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF064E3B),
                          ),
                        ),
                      ],
                    ),
                    if (discount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Coupon Discount',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '-${EvInvestorController.formatINR(discount)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payable via Razorpay',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          EvInvestorController.formatINR(payableAmount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: isRewardDone
                          ? _PremiumRewardBanner(
                              key: const ValueKey('reward_banner'),
                              payableLabel: EvInvestorController.formatINR(
                                payableAmount,
                              ),
                              monthlyLabel:
                                  '+${EvInvestorController.formatINR(totalMonthlyReturn)}/mo',
                            )
                          : _RazorpaySlideToPayBar(
                              key: ValueKey(
                                'rzp_${payableAmount}_${coupon?.code ?? 'none'}',
                              ),
                              amountLabel: EvInvestorController.formatINR(
                                payableAmount,
                              ),
                              onSlideCompleted: _handleSwipeCompleted,
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

class _EmptyEvCartState extends StatelessWidget {
  const _EmptyEvCartState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 108,
              height: 108,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.electric_car_rounded,
                        size: 46,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF4FAF6),
                          width: 2.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 18,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: const Text(
                'No EV selected yet',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: const Text(
                'Select an EV to continue.',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefinedCouponCard extends StatelessWidget {
  final TextEditingController controller;
  final String? appliedCode;
  final int? discountAmount;
  final String errorMessage;
  final bool isLoading;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const _RefinedCouponCard({
    required this.controller,
    required this.appliedCode,
    required this.discountAmount,
    required this.errorMessage,
    required this.isLoading,
    required this.onApply,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoupon = appliedCode != null && discountAmount != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasCoupon ? const Color(0xFF34D399) : const Color(0xFFA7F3D0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 14,
                color: Color(0xFF064E3B),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Promo & Investor Voucher',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF064E3B),
                  ),
                ),
              ),
              if (hasCoupon)
                Text(
                  '-${EvInvestorController.formatINR(discountAmount!)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 40,
            padding: const EdgeInsets.only(left: 12, right: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: errorMessage.isNotEmpty
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFA7F3D0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => onApply(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF064E3B),
                      letterSpacing: 0.6,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Enter voucher code',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: Material(
                    color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: isLoading ? null : onApply,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Apply',
                                  style: TextStyle(
                                    fontSize: 11,
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
          if (errorMessage.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB91C1C),
              ),
            ),
          ],
          if (hasCoupon) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: Color(0xFF064E3B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$appliedCode active',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onRemove,
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB91C1C),
                    ),
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

class _RazorpaySlideToPayBar extends StatefulWidget {
  final String amountLabel;
  final VoidCallback onSlideCompleted;

  const _RazorpaySlideToPayBar({
    super.key,
    required this.amountLabel,
    required this.onSlideCompleted,
  });

  @override
  State<_RazorpaySlideToPayBar> createState() => _RazorpaySlideToPayBarState();
}

class _RazorpaySlideToPayBarState extends State<_RazorpaySlideToPayBar> {
  double _dragX = 0.0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double barHeight = 52.0;
        const double padding = 4.0;
        const double thumbSize = barHeight - (padding * 2);
        final double maxDrag = math.max(
          0.0,
          constraints.maxWidth - thumbSize - (padding * 2),
        );
        final double currentX = _dragX.clamp(0.0, maxDrag);
        final double progress = maxDrag > 0 ? (currentX / maxDrag) : 0.0;

        return Container(
          height: barHeight,
          width: double.infinity,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(barHeight / 2),
            border: Border.all(color: const Color(0xFF6EE7B7), width: 1.2),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: (1.0 - (progress * 1.35)).clamp(0.0, 1.0),
                    child: Text(
                      'Slide to Pay ${widget.amountLabel}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: currentX,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onHorizontalDragUpdate: _completed
                        ? null
                        : (details) {
                            setState(() {
                              _dragX = (_dragX + details.delta.dx).clamp(
                                0.0,
                                maxDrag,
                              );
                            });
                          },
                    onHorizontalDragEnd: _completed
                        ? null
                        : (_) {
                            if (maxDrag > 0 && currentX >= maxDrag * 0.82) {
                              setState(() {
                                _dragX = maxDrag;
                                _completed = true;
                              });
                              HapticFeedback.mediumImpact();
                              widget.onSlideCompleted();
                            } else {
                              setState(() {
                                _dragX = 0.0;
                              });
                            }
                          },
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: const BoxDecoration(
                        color: Color(0xFF064E3B),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PremiumRewardBanner extends StatelessWidget {
  final String payableLabel;
  final String monthlyLabel;

  const _PremiumRewardBanner({
    super.key,
    required this.payableLabel,
    required this.monthlyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF34D399), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 20,
            color: Color(0xFF059669),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Asset allocation confirmed ($payableLabel • $monthlyLabel)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF064E3B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
