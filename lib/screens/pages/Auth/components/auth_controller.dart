import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../routes/app_routes.dart';

class AuthController extends GetxController {
  static const Color _dark = Color(0xFF0F172A);

  static const String _keyLoggedIn = 'auth_is_logged_in';
  static const String _keyPhone = 'auth_phone';
  static const String _keyName = 'auth_full_name';
  static const String _keyEmail = 'auth_email';

  final GetStorage _storage = GetStorage();

  var isSubmitting = false.obs;
  var obscureLoginPassword = true.obs;
  var obscureRegisterPassword = true.obs;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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
    return loggedIn && savedPhone.isNotEmpty;
  }

  /// Removes +91 or leading 91 so plain phone number is stored and sent
  String normalizePhone(String raw) {
    String clean = raw.replaceAll(RegExp(r'\s+'), '').trim();
    if (clean.startsWith('+91')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('91') && clean.length > 10) {
      clean = clean.substring(2);
    }
    return clean;
  }

  void toggleLoginPasswordVisibility() {
    obscureLoginPassword.value = !obscureLoginPassword.value;
  }

  void toggleRegisterPasswordVisibility() {
    obscureRegisterPassword.value = !obscureRegisterPassword.value;
  }

  Future<void> _persistSession({
    required String phone,
    String fullName = '',
    String email = '',
  }) async {
    await _storage.write(_keyLoggedIn, true);
    await _storage.write(_keyPhone, phone);
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
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _persistSession(phone: phone);
    isSubmitting.value = false;

    passwordController.clear();
    _notify('Signed in with $phone');

    if (onSuccess != null) {
      onSuccess();
    } else {
      AppRoutes.toEntry();
    }
    return true;
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
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _persistSession(phone: phone, fullName: name, email: email);
    isSubmitting.value = false;

    passwordController.clear();
    _notify('Registered $name ($phone)');

    if (onSuccess != null) {
      onSuccess();
    } else {
      AppRoutes.toEntry();
    }
    return true;
  }
}
