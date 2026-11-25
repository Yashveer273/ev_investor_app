import 'dart:async';
import 'package:ev_investors_app/core/services/api_service.dart';
import 'package:ev_investors_app/core/services/api_service_evfleet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/ev_filter_model.dart';
import '../models/ev_product_model.dart';

class EvCartItem {
  final String evId;
  int units;

  EvCartItem({required this.evId, required this.units});
}

class EvInvestorController extends GetxController {
  static const String _keyInvestorId = 'auth_investor_id';
  final GetStorage _storage = GetStorage();

  // Single product array — updated directly on initial load, category filter, search, or pagination
  final RxList<EvProductModel> allProducts = <EvProductModel>[].obs;
  final RxString activeFilterId = EvFilterModel.defaultFilter.id.obs;
  final RxString searchText = ''.obs;
  final RxBool isLoadingProducts = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreProducts = true.obs;

  final RxString productsError = ''.obs;
  final RxBool isCheckoutLoading = false.obs;
  final RxMap<String, int> cartUnitsMap = <String, int>{}.obs;
  final RxBool swipeCheckoutCompleted = false.obs;
  final RxBool isCheckoutSuccess = false.obs;
  final RxString checkoutErrorMessage = ''.obs;

  Timer? _debounce;

  String get savedInvestorId {
    return (_storage.read<String>(_keyInvestorId) ?? '').trim();
  }

  String resolveInvestorId({String? explicitInvestorId}) {
    final passed = (explicitInvestorId ?? '').trim();
    if (passed.isNotEmpty) return passed;
    return savedInvestorId;
  }

  void resetCheckoutStatus() {
    isCheckoutLoading.value = false;
    swipeCheckoutCompleted.value = false;
    isCheckoutSuccess.value = false;
    checkoutErrorMessage.value = '';
  }

  @override
  void onInit() {
    super.onInit();
    searchEvProducts('');
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  /// All EVs shows every loaded product; specific category filters cleanly
  List<EvProductModel> get filteredProducts {
    if (activeFilterId.value == EvFilterModel.defaultFilter.id) {
      return allProducts;
    }

    final currentFilter = EvFilterModel.filterCategories.firstWhere(
      (cat) => cat.id == activeFilterId.value,
      orElse: () => EvFilterModel.defaultFilter,
    );

    final matched = allProducts.where(currentFilter.matchesProduct).toList();
    if (matched.isNotEmpty || searchText.value.trim().isNotEmpty) {
      return matched;
    }
    return allProducts;
  }

  List<EvCartItem> get cartItems {
    return cartUnitsMap.entries
        .where((entry) => entry.value > 0)
        .map((entry) => EvCartItem(evId: entry.key, units: entry.value))
        .toList();
  }

  int get totalCartUnits {
    return cartUnitsMap.values.fold<int>(0, (sum, units) => sum + units);
  }

  int getCartUnitsForProduct(String evId) {
    return cartUnitsMap[evId] ?? 0;
  }

  EvProductModel? findProductById(String evId) {
    for (final item in allProducts) {
      if (item.id == evId) return item;
    }
    return null;
  }

  int get grossCartAmount {
    var total = 0;
    for (final item in cartItems) {
      final ev = findProductById(item.evId);
      if (ev != null) {
        total += ev.totalAmountForUnits(item.units);
      }
    }
    return total;
  }

  int get totalCartMonthlyReturn {
    var totalMonthly = 0;
    for (final item in cartItems) {
      final ev = findProductById(item.evId);
      if (ev != null) {
        totalMonthly += ev.monthlyReturnForUnits(item.units);
      }
    }
    return totalMonthly;
  }

  int get payableCartAmount => grossCartAmount;

  void setFilter(String categoryId) {
    if (activeFilterId.value == categoryId) return;
    activeFilterId.value = categoryId;
    searchEvProducts(searchText.value);
  }

  void onSearchInputChanged(String query) {
    searchText.value = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchEvProducts(query);
    });
  }

  /// Main search & fetch function: updates `allProducts` with matched `EvProductModel` items
  Future<void> searchEvProducts(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    _debounce?.cancel();
    final cleanQuery = query.trim();
    searchText.value = cleanQuery;
    isLoadingProducts.value = true;
    productsError.value = '';
    currentPage.value = page;

    final categoryParam = activeFilterId.value == EvFilterModel.defaultFilter.id
        ? null
        : activeFilterId.value;

    try {
      final response = await ApiServiceEvFleet.getInvestorEvProducts(
        page: page,
        limit: limit,
        category: categoryParam,
        search: cleanQuery.isEmpty ? null : cleanQuery,
      );

      if (response['success'] == true) {
        final parsedList = _parseEvProducts(response['data']);
        allProducts.assignAll(parsedList);
        _syncPaginationMeta(response, parsedList.length, page, limit);
      } else {
        productsError.value =
            response['message']?.toString() ?? 'Failed to fetch EVs';
      }
    } catch (e) {
      productsError.value = e.toString();
    } finally {
      isLoadingProducts.value = false;
    }
  }

  /// Loads next page of EVs for current category + search query and appends unique products
  Future<void> loadMoreEvProducts({int limit = 20}) async {
    if (isLoadingProducts.value ||
        isLoadingMore.value ||
        !hasMoreProducts.value) {
      return;
    }

    isLoadingMore.value = true;
    final nextPage = currentPage.value + 1;

    final categoryParam = activeFilterId.value == EvFilterModel.defaultFilter.id
        ? null
        : activeFilterId.value;

    try {
      final response = await ApiServiceEvFleet.getInvestorEvProducts(
        page: nextPage,
        limit: limit,
        category: categoryParam,
        search: searchText.value.trim().isEmpty
            ? null
            : searchText.value.trim(),
      );

      if (response['success'] == true) {
        final nextItems = _parseEvProducts(response['data']);
        final existingIds = allProducts.map((e) => e.id).toSet();
        final uniqueNew = nextItems
            .where((item) => !existingIds.contains(item.id))
            .toList();

        allProducts.addAll(uniqueNew);
        currentPage.value = nextPage;
        _syncPaginationMeta(response, nextItems.length, nextPage, limit);
      }
    } catch (e) {
      productsError.value = e.toString();
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _syncPaginationMeta(
    Map<String, dynamic> response,
    int fetchedCount,
    int page,
    int limit,
  ) {
    final pagination = response['pagination'];
    if (pagination is Map) {
      if (pagination['currentPage'] != null) {
        currentPage.value =
            int.tryParse(pagination['currentPage'].toString()) ?? page;
      }
      if (pagination['hasNextPage'] != null) {
        hasMoreProducts.value = pagination['hasNextPage'] == true;
        return;
      }
      if (pagination['totalPages'] != null) {
        final totalPages =
            int.tryParse(pagination['totalPages'].toString()) ?? page;
        hasMoreProducts.value = currentPage.value < totalPages;
        return;
      }
    }
    hasMoreProducts.value = fetchedCount >= limit;
  }

  Future<void> clearSearchEvProducts() async {
    _debounce?.cancel();
    searchText.value = '';
    productsError.value = '';
    await searchEvProducts('');
  }

  List<EvProductModel> _parseEvProducts(dynamic rawData) {
    List<dynamic> rawList = const [];
    if (rawData is List) {
      rawList = rawData;
    } else if (rawData is Map && rawData['data'] is List) {
      rawList = rawData['data'] as List;
    }

    final result = <EvProductModel>[];
    for (final item in rawList) {
      if (item is Map) {
        try {
          result.add(EvProductModel.fromJson(Map<String, dynamic>.from(item)));
        } catch (err) {
          productsError.value = 'Model parse error: $err';
        }
      }
    }
    return result;
  }

  void updateCartUnits(String evId, int delta) {
    final currentUnits = cartUnitsMap[evId] ?? 0;
    final nextUnits = currentUnits + delta;

    if (nextUnits <= 0) {
      cartUnitsMap.remove(evId);
    } else {
      cartUnitsMap[evId] = nextUnits;
    }
  }

  void removeCartProduct(String evId) {
    cartUnitsMap.remove(evId);
  }

  void clearCartArray() {
    cartUnitsMap.clear();
  }

  String _formatDateYMD(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> completeRazorpaySwipeCheckout({
    int? overridePayableAmount,
    int discountAmount = 0,
    String? appliedCoupon,
    void Function(int payableAmount, int discountAmount, String? appliedCoupon)?
    onRazorpaySlideComplete,
    required void Function() onNavigateBack,
  }) async {
    if (isCheckoutLoading.value) return;

    if (cartItems.isEmpty) {
      checkoutErrorMessage.value = 'Please add products to your cart.';
      isCheckoutSuccess.value = false;
      Get.snackbar('Cart Empty', 'Please add products to your cart.');
      return;
    }

    isCheckoutLoading.value = true;
    swipeCheckoutCompleted.value = false;
    isCheckoutSuccess.value = false;
    checkoutErrorMessage.value = '';

    try {
      final int finalPayable = overridePayableAmount ?? payableCartAmount;

      final DateTime purchaseDate = DateTime.now();

      // Next reinvestment reminder: 8 months after purchase.
      final DateTime nextReinvestmentDate = DateTime(
        purchaseDate.year,
        purchaseDate.month + 8,
        purchaseDate.day,
      );

      // Keep cart unchanged until every API call succeeds.
      for (final cartItem in cartItems.toList()) {
        final product = allProducts.firstWhereOrNull(
          (item) => item.id == cartItem.evId,
        );

        if (product == null) {
          throw Exception('Product not found for ID: ${cartItem.evId}');
        }

        final int productInvestmentAmount = product.totalAmountForUnits(
          cartItem.units,
        );

        final int productMonthlyReturn = product.monthlyReturnForUnits(
          cartItem.units,
        );

        // Investor ID is automatically read from GetStorage
        // inside ApiService.buyProductAsset().
        final response = await ApiService.buyProductAsset(
          productJson: product.toJson(),
          investmentAmount: productInvestmentAmount,
          units: cartItem.units,
          purchaseDate: _formatDateYMD(purchaseDate),
          nextReinvestmentDate: _formatDateYMD(nextReinvestmentDate),
          monthlyReturn: productMonthlyReturn,
        );

        if (response['success'] == false) {
          throw Exception(
            response['message']?.toString() ??
                'Unable to purchase ${product.name}',
          );
        }
      }

      isCheckoutSuccess.value = true;
      swipeCheckoutCompleted.value = true;

      await Future.delayed(const Duration(milliseconds: 550));

      clearCartArray();

      onRazorpaySlideComplete?.call(
        finalPayable,
        discountAmount,
        appliedCoupon,
      );

      swipeCheckoutCompleted.value = false;

      onNavigateBack();
    } catch (e) {
      isCheckoutSuccess.value = false;
      swipeCheckoutCompleted.value = false;

      final errMsg = e.toString().replaceFirst('Exception: ', '');
      checkoutErrorMessage.value = errMsg;

      Get.snackbar(
        'Purchase Failed',
        errMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isCheckoutLoading.value = false;
    }
  }

  static String formatINR(int amount) {
    final isNegative = amount < 0;
    final digits = amount.abs().toString();
    if (digits.length <= 3) {
      return '${isNegative ? '-' : ''}₹$digits';
    }

    final lastThree = digits.substring(digits.length - 3);
    var remaining = digits.substring(0, digits.length - 3);
    final parts = <String>[];

    while (remaining.length > 2) {
      parts.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return '${isNegative ? '-' : ''}₹${parts.join(',')},$lastThree';
  }
}
