import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../core/services/api_service.dart';
import '../../../../routes/app_routes.dart';

class AuthController extends GetxController {
  static const Color _dark = Color(0xFF0F172A);

  static const String _keyLoggedIn = 'auth_is_logged_in';
  static const String _keyInvestorId = 'auth_investor_id';
  static const String _keyPhone = 'auth_phone';
  static const String _keyName = 'auth_full_name';
  static const String _keyEmail = 'auth_email';

  final GetStorage _storage = GetStorage();

  final RxBool isSubmitting = false.obs;
  final RxBool obscureLoginPassword = true.obs;
  final RxBool obscureRegisterPassword = true.obs;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  bool get hasActiveSession {
    final bool loggedIn = _storage.read<bool>(_keyLoggedIn) ?? false;
    final String savedPhone = (_storage.read<String>(_keyPhone) ?? '').trim();
    final String savedToken = (ApiService.token ?? '').trim();
    return loggedIn && savedPhone.isNotEmpty && savedToken.isNotEmpty;
  }

  /// Removes +91 or leading 91 so plain phone number is stored and sent
  String normalizePhone(String raw) {
    return ApiService.normalizePhone(raw);
  }

  void toggleLoginPasswordVisibility() {
    obscureLoginPassword.value = !obscureLoginPassword.value;
  }

  void toggleRegisterPasswordVisibility() {
    obscureRegisterPassword.value = !obscureRegisterPassword.value;
  }

  Future<void> _persistSession({
    required String phone,
    String investorId = '',
    String fullName = '',
    String email = '',
  }) async {
    await _storage.write(_keyLoggedIn, true);
    await _storage.write(_keyPhone, phone);
    if (investorId.isNotEmpty) {
      await _storage.write(_keyInvestorId, investorId);
    }
    if (fullName.isNotEmpty) {
      await _storage.write(_keyName, fullName);
    }
    if (email.isNotEmpty) {
      await _storage.write(_keyEmail, email);
    }
  }

  void _notify(String message) {
    Get.snackbar(
      'Notice',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: _dark,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(12),
    );
  }

  Future<bool> login({VoidCallback? onSuccess}) async {
    final String phone = normalizePhone(phoneController.text);
    final String password = passwordController.text;

    if (phone.length < 10) {
      _notify('Please enter your registered phone number');
      return false;
    }
    if (password.isEmpty) {
      _notify('Please enter your password');
      return false;
    }

    isSubmitting.value = true;
    try {
      final Map<String, dynamic> response = await ApiService.login(
        phone: phone,
        password: password,
      );
      final Map<String, dynamic> investor = Map<String, dynamic>.from(
        response['investor'] ?? response['profile'] ?? <String, dynamic>{},
      );

      final String resolvedPhone = normalizePhone(
        (investor['phone'] ?? phone).toString(),
      );

      await _persistSession(
        phone: resolvedPhone,
        investorId: (investor['investorId'] ?? investor['id'] ?? '').toString(),
        fullName: (investor['fullName'] ?? investor['name'] ?? '').toString(),
        email: (investor['email'] ?? '').toString(),
      );

      passwordController.clear();
      _notify('Signed in with $resolvedPhone');

      if (onSuccess != null) {
        onSuccess();
      } else {
        AppRoutes.toEntry();
      }
      return true;
    } on ApiException catch (e) {
      _notify(e.message);
      return false;
    } catch (e) {
      _notify('Unable to login right now');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> register({VoidCallback? onSuccess}) async {
    final String name = nameController.text.trim();
    final String phone = normalizePhone(phoneController.text);
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (name.isEmpty) {
      _notify('Please enter your full name');
      return false;
    }
    if (phone.length < 10) {
      _notify('Please enter a valid 10-digit phone number');
      return false;
    }
    if (email.isEmpty || !email.contains('@')) {
      _notify('Please enter a valid email address');
      return false;
    }
    if (password.length < 6) {
      _notify('Password must be at least 6 characters');
      return false;
    }

    isSubmitting.value = true;
    try {
      final Map<String, dynamic> response = await ApiService.register(
        fullName: name,
        phone: phone,
        email: email,
        password: password,
      );
      final Map<String, dynamic> investor = Map<String, dynamic>.from(
        response['investor'] ?? response['profile'] ?? <String, dynamic>{},
      );

      final String resolvedPhone = normalizePhone(
        (investor['phone'] ?? phone).toString(),
      );

      await _persistSession(
        phone: resolvedPhone,
        investorId: (investor['investorId'] ?? investor['id'] ?? '').toString(),
        fullName: (investor['fullName'] ?? name).toString(),
        email: (investor['email'] ?? email).toString(),
      );

      passwordController.clear();
      _notify('Registered $name ($resolvedPhone)');

      if (onSuccess != null) {
        onSuccess();
      } else {
        AppRoutes.toEntry();
      }
      return true;
    } on ApiException catch (e) {
      _notify(e.message);
      return false;
    } catch (e) {
      _notify('Unable to register right now');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
