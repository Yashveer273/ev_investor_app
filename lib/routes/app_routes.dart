import 'package:ev_investors_app/screens/entrypoint/entry_screen.dart';
import 'package:ev_investors_app/screens/pages/Auth/login_page.dart';
import 'package:ev_investors_app/screens/pages/Auth/register_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class _AuthGuardMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!AppRoutes.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

class AppRoutes {
  AppRoutes._();

  // Route Constants
  static const String login = '/login';
  static const String register = '/register';
  static const String entry = '/entry';

  // Checks GetStorage for active login session data
  static bool get isAuthenticated {
    final GetStorage box = GetStorage();
    final bool loggedIn = box.read<bool>('auth_is_logged_in') ?? false;
    final String phone = (box.read<String>('auth_phone') ?? '').trim();
    return loggedIn && phone.isNotEmpty;
  }

  // Starts on /entry only when storage has valid login data; otherwise /login
  static String get initialRoute => isAuthenticated ? entry : login;

  // Route Definitions
  static final List<GetPage> routes = [
    GetPage(
      name: login,
      page: () => const LoginPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: register,
      page: () => const RegisterPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: entry,
      page: () => const EntryScreen(),
      middlewares: [_AuthGuardMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
  ];

  // Replaces stack so Back button never returns to Login/Register
  static Future<T?>? toEntry<T>({dynamic arguments}) {
    return Get.offAllNamed<T>(entry, arguments: arguments);
  }

  // Clears stack & sends user back to LoginPage on logout
  static Future<T?>? toLogin<T>({dynamic arguments}) {
    return Get.offAllNamed<T>(login, arguments: arguments);
  }

  static Future<T?>? toRegister<T>({dynamic arguments}) {
    return Get.toNamed<T>(register, arguments: arguments);
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
