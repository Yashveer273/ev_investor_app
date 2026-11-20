import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'components/profile_controller.dart';
import 'components/profile_model.dart';
import 'widget/privacy_feedback_sheet.dart';
import 'widget/privacy_policy_page.dart';
import 'widget/profile_bank_card.dart';
import 'widget/profile_bank_edit_sheet.dart';
import 'widget/profile_header_card.dart';
import 'widget/profile_menu_section.dart';
import 'widget/support_page.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback? onLoggedOut;

  const ProfilePage({super.key, this.onLoggedOut});

  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _dark = Color(0xFF0F172A);

  ProfileController _resolveController() {
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>();
    }
    return Get.put(ProfileController());
  }

  void _openBankSheet(BuildContext context, ProfileController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileBankEditSheet(
        initialDetails: controller.profile.value.bankDetails,
        onSave:
            ({
              required String accountHolderName,
              required String accountNumber,
              required String ifscCode,
              required String bankName,
              required String upiId,
            }) {
              return controller.updateBankDetails(
                accountHolderName: accountHolderName,
                accountNumber: accountNumber,
                ifscCode: ifscCode,
                bankName: bankName,
                upiId: upiId,
              );
            },
      ),
    );
  }

  void _openFeedbackSheet(BuildContext context, ProfileController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrivacyFeedbackSheet(
        onSubmit: ({required String topic, required String message}) {
          return controller.submitPrivacyFeedback(
            topic: topic,
            message: message,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = _resolveController();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Obx(() {
          final InvestorProfileModel user = controller.profile.value;

          return RefreshIndicator(
            onRefresh: controller.loadProfile,
            color: _dark,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeaderCard(profile: user),
                  const SizedBox(height: 16),
                  ProfileBankCard(
                    bankDetails: user.bankDetails,
                    onEditTap: () => _openBankSheet(context, controller),
                  ),
                  const SizedBox(height: 16),
                  ProfileMenuSection(
                    onPrivacyPolicyTap: () {
                      Get.to(
                        () => PrivacyPolicyPage(
                          onFeedbackTap: () =>
                              _openFeedbackSheet(context, controller),
                        ),
                      );
                    },
                    onPrivacyFeedbackTap: () =>
                        _openFeedbackSheet(context, controller),
                    onSupportTap: () {
                      Get.to(
                        () => SupportPage(
                          whatsAppDisplay: controller.supportWhatsAppDisplay,
                          email: controller.supportEmail,
                          investorId: user.investorId,
                          onOpenWhatsApp: controller.openWhatsAppSupport,
                          onOpenEmail: controller.openEmailSupport,
                          onCopyWhatsApp: () => controller.copyValue(
                            controller.supportWhatsAppDisplay,
                            'WhatsApp number',
                          ),
                          onCopyEmail: () => controller.copyValue(
                            controller.supportEmail,
                            'Support email',
                          ),
                        ),
                      );
                    },
                    onLogoutTap: () =>
                        controller.logoutSession(onLoggedOut: onLoggedOut),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
