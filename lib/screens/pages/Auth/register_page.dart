import 'package:ev_investors_app/screens/pages/Auth/components/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const RegisterPage({super.key, this.onAuthSuccess});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.055),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  AuthController _resolveController() {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>();
    }
    return Get.put(AuthController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navigation
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 21,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'Back',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Brand
                  Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bolt,
                          color: AppColors.accentMint,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          Text('EV', style: AppTextStyles.h1),
                          const SizedBox(width: 5),
                          Text(
                            'Investors',
                            style: AppTextStyles.h1.copyWith(
                              color: AppColors.accentMint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 39),

                  // Heading
                  Text(
                    'Create your\ninvestor account.',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 32,
                      height: 1.18,
                      letterSpacing: -1.15,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Enter your details below to get started '
                    'with EV Investors.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Section heading
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.accentMint,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'PERSONAL DETAILS',
                        style: AppTextStyles.badge.copyWith(
                          fontSize: 11,
                          letterSpacing: 1.1,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 23),

                  // Full Name
                  _fieldLabel('Full Name'),

                  const SizedBox(height: 9),

                  _textField(
                    controller: controller.nameController,
                    hint: 'Enter your full name',
                    icon: Icons.person_outline_rounded,
                    action: TextInputAction.next,
                  ),

                  const SizedBox(height: 21),

                  // Phone
                  _fieldLabel('Phone Number'),

                  const SizedBox(height: 9),

                  _phoneField(controller),

                  const SizedBox(height: 21),

                  // Email
                  _fieldLabel('Email Address'),

                  const SizedBox(height: 9),

                  _textField(
                    controller: controller.emailController,
                    hint: 'name@example.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    action: TextInputAction.next,
                  ),

                  const SizedBox(height: 21),

                  // Password
                  _fieldLabel('Create Password'),

                  const SizedBox(height: 9),

                  Obx(
                    () => _textField(
                      controller: controller.passwordController,
                      hint: 'Minimum 6 characters',
                      icon: Icons.lock_outline_rounded,
                      obscure: controller.obscureRegisterPassword.value,
                      suffix: IconButton(
                        onPressed: controller.toggleRegisterPasswordVisibility,
                        icon: Icon(
                          controller.obscureRegisterPassword.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      action: TextInputAction.done,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Registration button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () => controller.register(
                                onSuccess: widget.onAuthSuccess,
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textInverse,
                          disabledBackgroundColor: AppColors.primary
                              .withOpacity(0.55),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: controller.isSubmitting.value
                              ? const SizedBox(
                                  key: ValueKey('loading'),
                                  height: 21,
                                  width: 21,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textInverse,
                                  ),
                                )
                              : Row(
                                  key: const ValueKey('register'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Create Account',
                                      style: AppTextStyles.bodyBold.copyWith(
                                        color: AppColors.textInverse,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 19,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Existing account
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Text(
                            'Sign In',
                            style: AppTextStyles.badge.copyWith(
                              color: AppColors.accentMint,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: Text(
                      'EV Investors',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.done,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: action,
        obscureText: obscure,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 19, color: AppColors.textSecondary),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 12,
          ),
        ),
      ),
    );
  }

  Widget _phoneField(AuthController controller) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '+91',
              style: AppTextStyles.bodyBold.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(width: 1, height: 25, color: AppColors.border),
          Expanded(
            child: TextField(
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 13,
              textInputAction: TextInputAction.next,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Enter phone number',
                hintStyle: AppTextStyles.caption,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(
              Icons.phone_android_rounded,
              color: AppColors.textSecondary,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}
