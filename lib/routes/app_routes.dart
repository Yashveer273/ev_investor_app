import 'package:ev_investors_app/screens/entrypoint/entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';


class AppRoutes {
  AppRoutes._();

  // Route Constants
  static const String entry = '/entry';

  // Route Definitions
  static final List<GetPage> routes = [
    GetPage(
      name: entry,
      page: () => const EntryScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
  ];

  // Helper Navigation Method for Entry Screen
  static Future<T?>? toEntry<T>({dynamic arguments}) {
    return Get.offAllNamed<T>(entry, arguments: arguments);
  }

  // Optional Route Theme Helper
  static ThemeData get routeTheme => ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
        textTheme: const TextTheme(
          titleMedium: AppTextStyles.h3,
          bodyMedium: AppTextStyles.bodyMedium,
        ),
      );
}