import 'package:ev_investors_app/screens/pages/Auth/components/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const LoginPage({super.key, this.onAuthSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.045),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 56,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),

                        // Brand
                        Row(
                          children: [
                            Container(
                              height: 43,
                              width: 43,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.bolt,
                                color: AppColors.accentMint,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                Text(
                                  'Invest in Electric Vehicles',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 65),

                        // Heading
                        Text(
                          'Welcome back.',
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 31,
                            height: 1.2,
                            letterSpacing: -1.1,
                          ),
                        ),

                        const SizedBox(height: 9),

                        Text(
                          'Sign in to access your investor account '
                          'and manage your investments.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 38),

                        // Form
                        _sectionLabel('PHONE NUMBER'),

                        const SizedBox(height: 10),

                        _phoneField(controller),

                        const SizedBox(height: 25),

                        _sectionLabel('PASSWORD'),

                        const SizedBox(height: 10),

                        Obx(
                          () => _inputField(
                            controller: controller.passwordController,
                            hint: 'Enter your password',
                            obscure: controller.obscureLoginPassword.value,
                            suffix: IconButton(
                              onPressed:
                                  controller.toggleLoginPasswordVisibility,
                              icon: Icon(
                                controller.obscureLoginPassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            action: TextInputAction.done,
                          ),
                        ),

                        const SizedBox(height: 34),

                        // Login button
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: controller.isSubmitting.value
                                  ? null
                                  : () => controller.login(
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
                                duration: const Duration(milliseconds: 200),
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
                                        key: const ValueKey('login'),
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign In',
                                            style: AppTextStyles.bodyBold
                                                .copyWith(
                                                  color: AppColors.textInverse,
                                                ),
                                          ),
                                          const SizedBox(width: 9),
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

                        const SizedBox(height: 29),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                'NEW TO EV INVESTORS?',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // Create account
                        SizedBox(
                          width: double.infinity,
                          height: 53,
                          child: OutlinedButton(
                            onPressed: () {
                              Get.to(
                                () => RegisterPage(
                                  onAuthSuccess: widget.onAuthSuccess,
                                ),
                                transition: Transition.rightToLeft,
                                duration: const Duration(milliseconds: 320),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(
                                color: AppColors.border,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Create Investor Account',
                              style: AppTextStyles.bodyBold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        Center(
                          child: Text(
                            'EV Investors  •  Secure Account Access',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 1.15,
      ),
    );
  }

  Widget _phoneField(AuthController controller) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text('+91', style: AppTextStyles.bodyBold),
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
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    TextInputAction action = TextInputAction.done,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textInputAction: action,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.caption,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 16,
          ),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
