import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'components/profile_controller.dart';
import 'components/profile_model.dart';
import 'widget/feedback.dart' as feedback_widget;
import 'widget/kyc_view.dart';
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
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

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

  void _openFeedbackSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => feedback_widget.Feedback(
        onSubmit: ({required String topic, required String message}) async {
          Get.snackbar('Feedback unavailable', 'Please try again later.');
          return false;
        },
      ),
    );
  }

  Widget _kycCard(InvestorProfileModel user, VoidCallback onTap) {
    final String rawStatus = user.kycStatus.trim();
    final String statusText = rawStatus.isEmpty ? 'Pending' : rawStatus;
    final String lower = statusText.toLowerCase();
    final bool verified = lower == 'verified';
    final bool rejected = lower == 'rejected';

    final Color badgeBg = verified
        ? const Color(0xFFD1FAE5)
        : rejected
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFEF3C7);
    final Color badgeFg = verified
        ? const Color(0xFF065F46)
        : rejected
        ? const Color(0xFFB91C1C)
        : const Color(0xFF92400E);

    final String subtitle = verified
        ? 'Identity & PAN verified'
        : rejected
        ? 'Action required — update & resubmit KYC'
        : 'Complete PAN & Aadhaar verification';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'KYC Verification',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: _muted),
          ],
        ),
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
                  ProfileHeaderCard(
                    profile: user,
                    onCopy: controller.copyValue,
                  ),
                  const SizedBox(height: 16),
                  _kycCard(user, () async {
                    await Get.to(() => const KycView());
                    controller.refreshKycStatus();
                  }),
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
                          onFeedbackTap: () => _openFeedbackSheet(context),
                        ),
                      );
                    },
                    onPrivacyFeedbackTap: () => _openFeedbackSheet(context),
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
