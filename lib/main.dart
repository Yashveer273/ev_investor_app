import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const EvvaaInvestorApp());
}

class EvvaaInvestorApp extends StatelessWidget {
  const EvvaaInvestorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EV Investors App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: AppTextStyles.h1,
        ),
        textTheme: const TextTheme(
          headlineLarge: AppTextStyles.displayLarge,
          headlineMedium: AppTextStyles.h1,
          headlineSmall: AppTextStyles.h2,
          titleMedium: AppTextStyles.h3,
          bodyLarge: AppTextStyles.bodyBold,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodyRegular,
          labelSmall: AppTextStyles.caption,
        ),
      ),
      initialRoute: AppRoutes.entry,
      getPages: AppRoutes.routes,
    );
  }
}
