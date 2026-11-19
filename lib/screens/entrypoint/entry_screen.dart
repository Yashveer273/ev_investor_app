import 'package:ev_investors_app/screens/pages/Home/components/home_controller.dart';
import 'package:ev_investors_app/screens/pages/Home/home_page.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/portfolio.dart';
import 'package:ev_investors_app/screens/pages/Profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../components/app_button.dart';

class EntryController extends GetxController {
  var currentIndex = 0.obs;
  late PageController pageController;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
  }

  void onTabTapped(int index) {
    currentIndex.value = index;
    pageController.jumpToPage(index);
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  HomeController _resolveHomeController() {
    if (Get.isRegistered<HomeController>()) {
      return Get.find<HomeController>();
    }
    return Get.put(HomeController());
  }

  @override
  Widget build(BuildContext context) {
    final EntryController controller = Get.put(EntryController());
    final HomeController homeController = _resolveHomeController();

    final List<Widget> pages = const [
      HomePage(), // 0: Marketplace
      PortfolioPage(), // 1: Portfolio
      ProfilePage(), // 2: My Profile
    ];

    return Scaffold(
      backgroundColor: AppColors.background,

      // ==================== TOP APP BAR ====================
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
        title: GestureDetector(
          onTap: () => controller.onTabTapped(0),
          child: Row(
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
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Obx(() {
              final int count = homeController.totalReservedUnits;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  AppButton(
                    label: 'Reserved',
                    type: AppButtonType.primary,
                    icon: Icons.shopping_cart_outlined,
                    height: 34,
                    borderRadius: 12,
                    onPressed: homeController.onReservedButtonPressed,
                  ),
                  if (count > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '$count',
                          style: AppTextStyles.badge.copyWith(
                            color: const Color(0xFF020617),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),

      // ==================== PAGE BUILDER ====================
      body: PageView.builder(
        controller: controller.pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: controller.onPageChanged,
        itemCount: pages.length,
        itemBuilder: (context, index) => pages[index],
      ),

      // ==================== BOTTOM BAR (HTML THEME) ====================
      bottomNavigationBar: Obx(
        () => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            elevation: 0,
            selectedItemColor: AppColors.accentDark,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle: AppTextStyles.badge.copyWith(
              color: AppColors.accentDark,
            ),
            unselectedLabelStyle: AppTextStyles.caption.copyWith(fontSize: 10),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded, size: 20),
                label: 'Marketplace',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.work_outline_rounded, size: 20),
                label: 'Portfolio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded, size: 20),
                label: 'My Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
