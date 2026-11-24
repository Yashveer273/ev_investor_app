import 'package:ev_investors_app/core/services/api_service_evfleet.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/ev_coupon_model.dart';

class EvCouponController extends GetxController {
  /// Dummy fallback 10-digit phone number without country code
  static const String dummyPhone = '9999999999';

  static const String _keyPhone = 'auth_phone';

  final GetStorage _storage = GetStorage();

  final RxString activePhone = dummyPhone.obs;
  final Rxn<EvCouponModel> verifiedCoupon = Rxn<EvCouponModel>();
  final RxString couponErrorMessage = ''.obs;
  final RxBool isVerifyingCoupon = false.obs;

  @override
  void onInit() {
    super.onInit();
    activePhone.value = _readStoredPhone();
  }

  String _normalizePhone(String raw) {
    var digits = raw
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'\D+'), '');
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    return digits;
  }

  String _readStoredPhone() {
    final storedPhone = _normalizePhone(_storage.read<String>(_keyPhone) ?? '');
    if (storedPhone.isNotEmpty) return storedPhone;
    return dummyPhone;
  }

  String resolvePhone({String? passedPhone}) {
    if (passedPhone != null && passedPhone.trim().isNotEmpty) {
      final clean = _normalizePhone(passedPhone);
      if (clean.isNotEmpty) return clean;
    }
    return _readStoredPhone();
  }

  void setPhone(String phone) {
    final clean = _normalizePhone(phone);
    activePhone.value = clean.isNotEmpty ? clean : _readStoredPhone();
  }

  int discountAmountFor(int grossAmount) {
    final coupon = verifiedCoupon.value;
    if (coupon == null || grossAmount <= 0) return 0;
    return coupon.computeDiscount(grossAmount);
  }

  int payableAmountFor(int grossAmount) {
    if (grossAmount <= 0) return 0;
    return (grossAmount - discountAmountFor(grossAmount)).clamp(0, grossAmount);
  }

  Future<bool> verifyCoupon({
    required String rawCode,
    String? phone,
    int? orderAmount,
  }) async {
    if (RegExp(r'\s').hasMatch(rawCode.trim())) {
      verifiedCoupon.value = null;
      couponErrorMessage.value = 'Coupon code cannot contain spaces';
      return false;
    }

    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      verifiedCoupon.value = null;
      couponErrorMessage.value = 'Please enter a coupon code';
      return false;
    }

    final resolvedPhone = resolvePhone(passedPhone: phone);
    activePhone.value = resolvedPhone;

    isVerifyingCoupon.value = true;
    couponErrorMessage.value = '';

    try {
      final response = await ApiServiceEvFleet.validateCoupon(
        code: code,
        phone: resolvedPhone,
        amount: orderAmount,
      );

      final isValid = response['success'] == true && response['valid'] == true;
      final rawData = response['data'];

      if (isValid && rawData is Map) {
        verifiedCoupon.value = EvCouponModel.fromJson(
          Map<String, dynamic>.from(rawData),
        );
        couponErrorMessage.value = '';
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.lightImpact();
        return true;
      }

      verifiedCoupon.value = null;
      couponErrorMessage.value =
          response['message']?.toString() ?? 'Coupon verification failed';
      return false;
    } catch (e) {
      verifiedCoupon.value = null;
      couponErrorMessage.value = e.toString();
      return false;
    } finally {
      isVerifyingCoupon.value = false;
    }
  }

  void clearCoupon() {
    verifiedCoupon.value = null;
    couponErrorMessage.value = '';
  }
}
