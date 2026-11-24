import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/api_service.dart';
import '../../../../routes/app_routes.dart';
import '../../Auth/components/auth_controller.dart';
import '../../Home/components/home_controller.dart';
import '../../Portfolio/components/portfolio_controller.dart';
import 'profile_model.dart';

class ProfileController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isKycSubmitting = false.obs;
  final Rx<InvestorProfileModel> profile = InvestorProfileModel.empty().obs;

  final String supportEmail = 'support@evfleet.in';
  final String supportWhatsAppNumber = '919876543210';
  final String supportWhatsAppDisplay = '+91 98765 43210';
  final String privacyEmail = 'privacy@evfleet.in';

  static final RegExp _panRegex = RegExp(
    r'^[A-Z]{3}[ABCFGHLJPT][A-Z](?!0000)[0-9]{4}[A-Z]$',
  );
  static final RegExp _aadhaarRegex = RegExp(r'^[0-9]{12}$');

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  String _currentIsoDate() {
    final DateTime now = DateTime.now();
    final String mm = now.month.toString().padLeft(2, '0');
    final String dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  Map<String, dynamic> _extractDataMap(Map<String, dynamic> raw) {
    final dynamic nestedData = raw['data'];
    if (nestedData is Map<String, dynamic>) {
      return nestedData;
    }
    final dynamic nestedProfile = raw['profile'];
    if (nestedProfile is Map<String, dynamic>) {
      return nestedProfile;
    }
    return raw;
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final InvestorProfileModel remoteProfile = await ApiService.getProfile();
      profile.value = remoteProfile;
    } on ApiException catch (e) {
      _notify(e.message);
    } catch (_) {
      _notify('Unable to load profile from server');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshKycStatus() async {
    try {
      final Map<String, dynamic> response = await ApiService.getKycStatus();
      final Map<String, dynamic> kycData = _extractDataMap(response);

      final String status =
          (kycData['kycStatus'] ??
                  response['kycStatus'] ??
                  profile.value.kycStatus)
              .toString();
      final KycDetailsModel kycDetails = KycDetailsModel.fromJson(kycData);

      profile.value = profile.value.copyWith(
        kycStatus: status,
        kyc: kycDetails,
      );
    } on ApiException catch (e) {
      _notify(e.message);
    } catch (_) {
      _notify('Unable to refresh KYC status');
    }
  }

  Future<bool> submitKycDetails({
    required String fullNameAsPerPan,
    required String panNumber,
    required String aadhaarNumber,
    required String dob,
    required String address,
    File? panImage,
    File? aadhaarImage,
    XFile? panXFile,
    XFile? aadhaarXFile,
  }) async {
    final String name = fullNameAsPerPan.trim();
    final String pan = panNumber.trim().toUpperCase();
    final String aadhaar = aadhaarNumber.replaceAll(RegExp(r'\s+'), '').trim();
    final String cleanDob = dob.trim();
    final String cleanAddress = address.trim();
    print(
      "${panImage}, ${aadhaarImage}, ${panXFile}, ${aadhaarXFile},${pan}, ${aadhaar}",
    );

    debugPrint(
      'PAN debug -> value="$pan", len=${pan.length}, runes=${pan.runes.toList()}',
    );
    final bool hasPanPhoto =
        panImage != null ||
        panXFile != null ||
        profile.value.kyc.panImageUrl.trim().isNotEmpty;
    final bool hasAadhaarPhoto =
        aadhaarImage != null ||
        aadhaarXFile != null ||
        profile.value.kyc.aadhaarImageUrl.trim().isNotEmpty;

    if (name.length < 2) {
      _notify('Please enter full name as per PAN');
      return false;
    }
    if (!_panRegex.hasMatch(pan)) {
      _notify(
        'Invalid PAN ($pan, len ${pan.length}). Format: 3 letters + P/C/H/F/A/T/B/L/J/G + 1 letter + 4 digits + 1 letter (e.g. ABCPD1234F)',
      );
      return false;
    }
    if (!_aadhaarRegex.hasMatch(aadhaar)) {
      _notify('Enter a valid 12-digit Aadhaar number');
      return false;
    }
    if (!hasPanPhoto) {
      _notify('Please upload PAN card photo');
      return false;
    }
    if (!hasAadhaarPhoto) {
      _notify('Please upload Aadhaar card photo');
      return false;
    }
    if (cleanDob.isEmpty) {
      _notify('Please enter Date of Birth');
      return false;
    }
    if (cleanAddress.length < 6) {
      _notify('Please enter complete address');
      return false;
    }

    isKycSubmitting.value = true;
    try {
      final Map<String, dynamic> responseData = await ApiService.submitKyc(
        fullNameAsPerPan: name,
        panNumber: pan,
        aadhaarNumber: aadhaar,
        dob: cleanDob,
        address: cleanAddress,
        panImage: panImage,
        aadhaarImage: aadhaarImage,
        panXFile: panXFile,
        aadhaarXFile: aadhaarXFile,
      );

      final Map<String, dynamic> payload = _extractDataMap(responseData);
      final String nextStatus =
          (payload['kycStatus'] ?? responseData['kycStatus'] ?? 'Pending')
              .toString();
      final KycDetailsModel updatedKyc = KycDetailsModel.fromJson(payload);

      profile.value = profile.value.copyWith(
        kycStatus: nextStatus,
        kyc: updatedKyc,
      );
      _notify('KYC submitted successfully');
      return true;
    } on ApiException catch (e) {
      _notify(e.message);
      return false;
    } catch (_) {
      _notify('Unable to submit KYC details');
      return false;
    } finally {
      isKycSubmitting.value = false;
    }
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

    try {
      final InvestorProfileModel updatedProfile =
          await ApiService.updateBankDetails(
            accountHolderName: holder,
            accountNumber: accNo,
            ifscCode: ifsc,
            bankName: bank,
            upiId: upi,
          );
      profile.value = updatedProfile;
      _notify('Bank & payout details updated successfully');
      return true;
    } on ApiException catch (e) {
      _notify(e.message);
      return false;
    } catch (_) {
      _notify('Unable to update bank details');
      return false;
    }
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

    final String submittedDate = _currentIsoDate();

    try {
      await ApiService.submitFeedback(
        topic: topic,
        message: cleanMsg,
        submittedDate: submittedDate,
      );

      final PrivacyFeedbackModel payload = PrivacyFeedbackModel(
        investorId: profile.value.investorId,
        topic: topic,
        message: cleanMsg,
        submittedDate: submittedDate,
      );
      debugPrint('PrivacyFeedback payload: ${payload.toJson()}');

      _notify('Privacy feedback submitted');
      return true;
    } on ApiException catch (e) {
      _notify(e.message);
      return false;
    } catch (_) {
      _notify('Unable to submit privacy feedback');
      return false;
    }
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
    try {
      await ApiService.logout();
    } catch (_) {}

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
