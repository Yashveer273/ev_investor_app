import 'package:ev_investors_app/features/ev_investor/pages/ev_investor_home_page.dart';
import 'package:ev_investors_app/screens/pages/Home/components/home_controller.dart';
import 'package:ev_investors_app/screens/pages/Home/home_page.dart';
import 'package:ev_investors_app/screens/pages/Portfolio/portfolio.dart';
import 'package:ev_investors_app/screens/pages/Profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

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

    final List<Widget> pages = const [
      // HomePage(), // 0: Marketplace
      EvInvestorHomePage(),
      PortfolioPage(), // 1: Portfolio
      ProfilePage(), // 2: My Profile
    ];

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,

        // ==================== TOP APP BAR ====================

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
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
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
              unselectedLabelStyle: AppTextStyles.caption.copyWith(
                fontSize: 10,
              ),
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
      ),
    );
  }
}
