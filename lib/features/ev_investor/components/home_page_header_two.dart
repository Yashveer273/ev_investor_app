import 'package:ev_investors_app/core/theme/app_colors.dart';
import 'package:ev_investors_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ev_investor_controller.dart';
import '../models/ev_filter_model.dart';
import '../pages/ev_cart_page.dart';

class HomePageHeaderTwo extends StatelessWidget {
  final EvInvestorController controller;
  final GlobalKey basketKey;
  final VoidCallback? onBasketTap;
  final void Function(
    int payableAmount,
    int discountAmount,
    String? appliedCoupon,
  )?
  onRazorpaySlideComplete;

  const HomePageHeaderTwo({
    super.key,
    required this.controller,
    required this.basketKey,
    this.onBasketTap,
    this.onRazorpaySlideComplete,
  });

  void _openCartPage(BuildContext context) {
    if (onBasketTap != null) {
      onBasketTap!();
      return;
    }

    Navigator.of(context).push(
      EvCartPage.route(
        controller: controller,
        onRazorpaySlideComplete: onRazorpaySlideComplete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4), Color(0xFFE6F7EF)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xB3A7F3D0), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bolt,
                      color: AppColors.accentMint,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('EV', style: AppTextStyles.h1),
                          const SizedBox(width: 6),
                          Text(
                            'Investors',
                            style: AppTextStyles.h1.copyWith(
                              color: AppColors.accentMint,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Invest in Electric Vehicles',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Obx(() {
                final totalUnits = controller.totalCartUnits;
                return SizedBox(
                  key: basketKey,
                  width: 40,
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: Colors.white,
                        shape: CircleBorder(
                          side: BorderSide(
                            color: const Color(
                              0xFFA7F3D0,
                            ).withValues(alpha: 0.8),
                            width: 1,
                          ),
                        ),
                        elevation: 0.5,
                        child: InkWell(
                          onTap: () => _openCartPage(context),
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
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
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
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final currentFilterId = controller.activeFilterId.value;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: EvFilterModel.filterCategories.map((cat) {
                  final isActive = currentFilterId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => controller.setFilter(cat.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF047857)
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(999),
                          border: isActive
                              ? null
                              : Border.all(
                                  color: const Color(
                                    0xFFA7F3D0,
                                  ).withValues(alpha: 0.7),
                                  width: 1,
                                ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF022C22),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
