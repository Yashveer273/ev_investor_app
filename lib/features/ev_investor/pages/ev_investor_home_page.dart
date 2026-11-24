import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/home_page_header_two.dart';
import '../components/product_card_two.dart';
import '../controllers/ev_investor_controller.dart';
import '../models/ev_product_model.dart';
import 'ev_cart_page.dart';
import 'ev_product_detail_page.dart';

class EvInvestorHomePage extends StatefulWidget {
  const EvInvestorHomePage({super.key});

  @override
  State<EvInvestorHomePage> createState() => _EvInvestorHomePageState();
}

class _EvInvestorHomePageState extends State<EvInvestorHomePage>
    with TickerProviderStateMixin {
  late final EvInvestorController _controller;
  final GlobalKey _basketKey = GlobalKey();
  final List<OverlayEntry> _activeFlyEntries = [];

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<EvInvestorController>()
        ? Get.find<EvInvestorController>()
        : Get.put(EvInvestorController());
  }

  @override
  void dispose() {
    for (final entry in List<OverlayEntry>.from(_activeFlyEntries)) {
      if (entry.mounted) {
        entry.remove();
      }
    }
    _activeFlyEntries.clear();
    super.dispose();
  }

  void _launchCubeToCircleFlyAnimation(GlobalKey sourceKey, String labelText) {
    final srcContext = sourceKey.currentContext;
    final dstContext = _basketKey.currentContext;
    final overlay = Overlay.of(context, rootOverlay: true);

    if (srcContext == null || dstContext == null) return;

    final srcBox = srcContext.findRenderObject() as RenderBox?;
    final dstBox = dstContext.findRenderObject() as RenderBox?;
    if (srcBox == null ||
        dstBox == null ||
        !srcBox.attached ||
        !dstBox.attached) {
      return;
    }

    final srcOffset = srcBox.localToGlobal(Offset.zero);
    final dstOffset = dstBox.localToGlobal(Offset.zero);

    final startCenter = Offset(
      srcOffset.dx + srcBox.size.width / 2,
      srcOffset.dy + srcBox.size.height / 2,
    );
    final endCenter = Offset(
      dstOffset.dx + dstBox.size.width / 2,
      dstOffset.dy + dstBox.size.height / 2,
    );

    final animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    final curved = CurvedAnimation(
      parent: animController,
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    );
    final opacityCurved = CurvedAnimation(
      parent: animController,
      curve: Curves.easeIn,
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return AnimatedBuilder(
          animation: animController,
          builder: (ctx, child) {
            final t = curved.value;
            final currentX =
                startCenter.dx + (endCenter.dx - startCenter.dx) * t;
            final currentY =
                startCenter.dy + (endCenter.dy - startCenter.dy) * t;
            final currentRadius = 10.0 + (999.0 - 10.0) * t;
            final currentScale = 1.0 + (0.55 - 1.0) * t;
            final currentAngle = (math.pi * t);
            final currentOpacity = 1.0 + (0.2 - 1.0) * opacityCurved.value;

            return Positioned(
              left: currentX - 18,
              top: currentY - 18,
              width: 36,
              height: 36,
              child: IgnorePointer(
                child: Opacity(
                  opacity: currentOpacity.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: currentAngle,
                    child: Transform.scale(
                      scale: currentScale,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF047857),
                          borderRadius: BorderRadius.circular(currentRadius),
                          border: Border.all(
                            color: const Color(
                              0xFF6EE7B7,
                            ).withValues(alpha: 0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          labelText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
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
    overlay.insert(entry);

    animController.forward().whenComplete(() {
      if (entry.mounted) {
        entry.remove();
      }
      _activeFlyEntries.remove(entry);
      animController.dispose();
    });
  }

  void _handleCardCartUpdate(
    EvProductModel product,
    int delta,
    GlobalKey triggerKey,
  ) {
    _controller.updateCartUnits(product.id, delta);
    if (delta > 0) {
      _launchCubeToCircleFlyAnimation(triggerKey, '+$delta');
    }
  }

  void _openCartPage() {
    Navigator.of(context).push(
      EvCartPage.route(
        controller: _controller,
        onRazorpaySlideComplete:
            (payableAmount, discountAmount, appliedCoupon) {
              // Trigger Razorpay checkout here with payableAmount
            },
      ),
    );
  }

  void _openDetailPage(EvProductModel product) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return EvProductDetailPage(product: product, controller: _controller);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(child: _EvAmbientTextureLayer()),
          ),
          SafeArea(
            child: Column(
              children: [
                RepaintBoundary(
                  child: HomePageHeaderTwo(
                    controller: _controller,
                    basketKey: _basketKey,
                    onBasketTap: _openCartPage,
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final products = _controller.filteredProducts;
                    return ListView.separated(
                      key: ValueKey(_controller.activeFilterId.value),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      physics: const ClampingScrollPhysics(),
                      cacheExtent: 600,
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return RepaintBoundary(
                          key: ValueKey(product.id),
                          child: ProductCardTwo(
                            product: product,
                            controller: _controller,
                            onViewDetails: () => _openDetailPage(product),
                            onUpdateCart: (delta, triggerKey) =>
                                _handleCardCartUpdate(
                                  product,
                                  delta,
                                  triggerKey,
                                ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvAmbientTextureLayer extends StatelessWidget {
  const _EvAmbientTextureLayer();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, -0.8),
                radius: 1.2,
                colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.76, -0.56),
                radius: 1.0,
                colors: [
                  const Color(0xFF059669).withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, 0.7),
                radius: 1.1,
                colors: [
                  const Color(0xFF34D399).withValues(alpha: 0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
