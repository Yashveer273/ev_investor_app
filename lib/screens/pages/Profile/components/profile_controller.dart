import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../routes/app_routes.dart';
import '../../Auth/components/auth_controller.dart';
import '../../Home/components/home_controller.dart';
import '../../Portfolio/components/portfolio_controller.dart';
import 'profile_model.dart';

class ProfileController extends GetxController {
  var isLoading = false.obs;
  var profile = InvestorProfileModel.dummyProfile().obs;

  final String supportEmail = 'support@evfleet.in';
  final String supportWhatsAppNumber = '919876543210';
  final String supportWhatsAppDisplay = '+91 98765 43210';
  final String privacyEmail = 'privacy@evfleet.in';

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 150));
    profile.value = InvestorProfileModel.dummyProfile();
    isLoading.value = false;
  }

  Future<bool> updateBankDetails({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    required String upiId,
  }) async {
    final String holder = accountHolderName.trim();
    final String accNo = accountNumber.trim();
    final String ifsc = ifscCode.trim().toUpperCase();
    final String bank = bankName.trim();
    final String upi = upiId.trim();

    if (holder.isEmpty) {
      _notify('Please enter account holder name');
      return false;
    }
    if (accNo.isEmpty && upi.isEmpty) {
      _notify('Enter bank account number or UPI ID');
      return false;
    }
    if (accNo.isNotEmpty && (ifsc.isEmpty || bank.isEmpty)) {
      _notify('Please enter bank name and IFSC code');
      return false;
    }

    final InvestorProfileModel current = profile.value;
    profile.value = InvestorProfileModel(
      investorId: current.investorId,
      fullName: current.fullName,
      phone: current.phone,
      email: current.email,
      city: current.city,
      kycStatus: current.kycStatus,
      bankDetails: BankPayoutDetailsModel(
        accountHolderName: holder,
        accountNumber: accNo,
        ifscCode: ifsc,
        bankName: bank,
        upiId: upi,
        updatedAt: '2026-11-20',
      ),
    );

    _notify('Bank & payout details updated successfully');
    return true;
  }

  Future<bool> submitPrivacyFeedback({
    required String topic,
    required String message,
  }) async {
    final String cleanMsg = message.trim();
    if (cleanMsg.isEmpty) {
      _notify('Please enter your feedback');
      return false;
    }

    final PrivacyFeedbackModel payload = PrivacyFeedbackModel(
      investorId: profile.value.investorId,
      topic: topic,
      message: cleanMsg,
      submittedDate: '2026-11-20',
    );
    debugPrint('PrivacyFeedback payload: ${payload.toJson()}');

    _notify('Privacy feedback submitted');
    return true;
  }

  Future<void> openWhatsAppSupport() async {
    final String text = Uri.encodeComponent(
      'Hello Support, I need assistance with my EV assets (Investor ID: ${profile.value.investorId}).',
    );
    final Uri uri = Uri.parse(
      'https://wa.me/$supportWhatsAppNumber?text=$text',
    );
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await copyValue(supportWhatsAppDisplay, 'WhatsApp number');
    }
  }

  Future<void> openEmailSupport() async {
    final String subject = Uri.encodeComponent(
      'EV Asset Support — Investor ${profile.value.investorId}',
    );
    final Uri uri = Uri.parse('mailto:$supportEmail?subject=$subject');
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await copyValue(supportEmail, 'Support email');
    }
  }

  Future<void> copyValue(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    _notify('$label copied');
  }

  Future<void> logoutSession({VoidCallback? onLoggedOut}) async {
    final GetStorage box = GetStorage();
    await box.erase();

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    if (Get.isRegistered<HomeController>()) {
      Get.delete<HomeController>(force: true);
    }
    if (Get.isRegistered<PortfolioController>()) {
      Get.delete<PortfolioController>(force: true);
    }
    if (Get.isRegistered<AuthController>()) {
      Get.delete<AuthController>(force: true);
    }
    if (Get.isRegistered<ProfileController>()) {
      Get.delete<ProfileController>(force: true);
    }

    if (onLoggedOut != null) {
      onLoggedOut();
    } else {
      AppRoutes.toLogin();
    }
  }

  void _notify(String message) {
    Get.snackbar(
      'Notice',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF0F172A),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(12),
    );
  }
}
