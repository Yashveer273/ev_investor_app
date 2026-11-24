import 'dart:async';

import 'package:ev_investors_app/core/services/api_service_evfleet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../widget/product_spec_page.dart';
import '../widget/reserved_assets_page.dart';
import 'ev_product_model.dart';
import 'store_model.dart';

class HomeController extends GetxController {
  final TextEditingController searchController = TextEditingController();

  static const String allStoreKey = 'ALL';

  // Search
  final RxString searchQuery = ''.obs;
  final RxString debouncedQuery = ''.obs;
  final RxBool isSearching = false.obs;

  // Loading states
  final RxBool isLoadingStores = false.obs;
  final RxBool isLoadingProducts = false.obs;

  // API errors
  final RxString storeError = ''.obs;
  final RxString productError = ''.obs;

  // Store selection
  final RxString selectedStoreKey = allStoreKey.obs;
  final Rxn<StoreModel> selectedStore = Rxn<StoreModel>();

  // Store lists
  final RxList<StoreModel> nearestStores = <StoreModel>[].obs;
  final RxList<StoreModel> searchStores = <StoreModel>[].obs;
  final RxList<StoreModel> filteredStores = <StoreModel>[].obs;

  // Vehicle lists
  final RxList<EVProductModel> allProducts = <EVProductModel>[].obs;
  final RxList<EVProductModel> filteredProducts = <EVProductModel>[].obs;

  // Product pagination
  final RxInt visibleProductCount = 6.obs;

  // Reserved assets
  final RxList<ReservedAssetItem> reservedAssets = <ReservedAssetItem>[].obs;

  Timer? _debounceTimer;

  static const Duration debounceDuration = Duration(milliseconds: 500);

  @override
  void onInit() {
    super.onInit();

    loadAllStoresData();
    loadProductsData();
  }

  // =====================================================
  // VISIBLE PRODUCTS
  // =====================================================

  List<EVProductModel> get visibleProducts {
    if (filteredProducts.length <= visibleProductCount.value) {
      return filteredProducts.toList();
    }

    return filteredProducts.take(visibleProductCount.value).toList();
  }

  bool get hasMoreProducts {
    return visibleProductCount.value < filteredProducts.length;
  }

  // =====================================================
  // LOAD STORES FROM CLUSTER API (PORT 5000)
  // =====================================================

  Future<void> loadAllStoresData() async {
    isLoadingStores.value = true;
    storeError.value = '';

    try {
      final StoreResponseModel response = await ApiServiceEvFleet.getStores();

      nearestStores.assignAll(response.nearestStores);
      searchStores.assignAll(response.searchStores);

      // Reset selection if selected store no longer exists.
      if (selectedStore.value != null) {
        final exists = searchStores.any(
          (store) => store.id == selectedStore.value!.id,
        );

        if (!exists) {
          selectedStore.value = null;
          selectedStoreKey.value = allStoreKey;
        }
      }

      _applyTextSearch(debouncedQuery.value);
      _applyProductSearchAndStore();
    } catch (e) {
      storeError.value = e.toString();

      nearestStores.clear();
      searchStores.clear();
      filteredStores.clear();

      selectedStore.value = null;
      selectedStoreKey.value = allStoreKey;

      _applyProductSearchAndStore();
    } finally {
      isLoadingStores.value = false;
    }
  }

  // =====================================================
  // LOAD VEHICLES FROM VEHICLE API (PORT 5003)
  // =====================================================
  Future<void> loadProductsData({int page = 1, int limit = 10}) async {
    isLoadingProducts.value = true;
    productError.value = '';

    try {
      final Map<String, dynamic> response = await ApiServiceEvFleet.getVehicles(
        page: page,
        limit: limit,
      );

      if (response['success'] != true) {
        throw Exception(
          response['message']?.toString() ?? 'Unable to load vehicles',
        );
      }

      dynamic vehicleList = response['data'];

      // Support different API response structures.
      while (vehicleList is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          vehicleList,
        );

        if (data['vehicles'] is List) {
          vehicleList = data['vehicles'];
        } else if (data['data'] is List) {
          vehicleList = data['data'];
        } else if (data['results'] is List) {
          vehicleList = data['results'];
        } else if (data['items'] is List) {
          vehicleList = data['items'];
        } else {
          throw Exception('Vehicle list not found in API response.');
        }
      }

      if (vehicleList is! List) {
        throw Exception('Vehicle list not found in API response.');
      }

      final List<EVProductModel> products = vehicleList
          .whereType<Map>()
          .map(
            (item) => EVProductModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

      allProducts.assignAll(products);

      visibleProductCount.value = 6;
      _applyProductSearchAndStore();
    } catch (e) {
      productError.value = e.toString();

      // Keep previously loaded products if refresh fails.
      if (allProducts.isEmpty) {
        filteredProducts.clear();
      }
    } finally {
      isLoadingProducts.value = false;
    }
  }
  // =====================================================
  // REFRESH BOTH APIS
  // =====================================================

  Future<void> refreshHomeData() async {
    await Future.wait([loadAllStoresData(), loadProductsData()]);
  }

  // =====================================================
  // STORE SELECTION
  // =====================================================

  void onStoreChipSelected(StoreModel? store) {
    if (store == null) {
      selectedStoreKey.value = allStoreKey;
      selectedStore.value = null;

      _applyProductSearchAndStore();
      return;
    }

    selectedStoreKey.value = store.id;
    selectedStore.value = store;

    // Do not modify the original API store lists.
    _applyProductSearchAndStore();
  }

  // =====================================================
  // SEARCH
  // =====================================================

  void onSearchChanged(String value) {
    searchQuery.value = value;
    isSearching.value = true;

    _debounceTimer?.cancel();

    _debounceTimer = Timer(debounceDuration, () {
      _executeSearch(value.trim());
    });
  }

  void _executeSearch(String query) {
    debouncedQuery.value = query;

    _applyTextSearch(query);
    _applyProductSearchAndStore();

    isSearching.value = false;
  }

  void clearSearch() {
    _debounceTimer?.cancel();

    searchController.clear();

    searchQuery.value = '';
    debouncedQuery.value = '';
    isSearching.value = false;

    _applyTextSearch('');
    _applyProductSearchAndStore();
  }

  // =====================================================
  // STORE SEARCH FILTER
  // =====================================================

  void _applyTextSearch(String query) {
    if (query.isEmpty) {
      filteredStores.assignAll(searchStores);
      return;
    }

    final String search = query.toLowerCase();

    final results = searchStores.where((store) {
      final location = store.vehicleClusterLocation;

      return store.vehicleClusterOwnerId.toLowerCase().contains(search) ||
          store.id.toLowerCase().contains(search) ||
          store.vehicleCapacity.toString().contains(search) ||
          location.city.toLowerCase().contains(search) ||
          location.state.toLowerCase().contains(search) ||
          location.zipCode.toLowerCase().contains(search) ||
          location.streetAddress.toLowerCase().contains(search);
    }).toList();

    filteredStores.assignAll(results);
  }

  // =====================================================
  // VEHICLE SEARCH AND STORE FILTER
  // =====================================================

  void _applyProductSearchAndStore() {
    final String query = debouncedQuery.value.toLowerCase();

    final StoreModel? activeStore = selectedStore.value;

    final String selectedCity =
        activeStore?.vehicleClusterLocation.city.toLowerCase() ?? '';

    final String selectedState =
        activeStore?.vehicleClusterLocation.state.toLowerCase() ?? '';

    final String selectedZip =
        activeStore?.vehicleClusterLocation.zipCode.toLowerCase() ?? '';

    final results = allProducts.where((item) {
      // Store filter
      final bool matchesStore =
          activeStore == null ||
          item.clusterCity.toLowerCase() == selectedCity ||
          item.purchaseLocation.toLowerCase() == selectedCity ||
          (item.clusterState.toLowerCase() == selectedState &&
              item.clusterZipCode.toLowerCase() == selectedZip);

      // Search filter
      final bool matchesQuery =
          query.isEmpty ||
          item.vehicleModelName.toLowerCase().contains(query) ||
          item.vehicleId.toLowerCase().contains(query) ||
          item.companyName.toLowerCase().contains(query) ||
          item.vehicleNoPlate.toLowerCase().contains(query) ||
          item.clusterCity.toLowerCase().contains(query) ||
          item.clusterState.toLowerCase().contains(query) ||
          item.clusterZipCode.toLowerCase().contains(query) ||
          item.purchaseLocation.toLowerCase().contains(query);

      return matchesStore && matchesQuery;
    }).toList();

    filteredProducts.assignAll(results);

    visibleProductCount.value = 6;
  }

  // =====================================================
  // LOAD MORE PRODUCTS
  // =====================================================

  void loadMoreScooters() {
    if (!hasMoreProducts) return;

    final int nextCount = visibleProductCount.value + 3;

    visibleProductCount.value = nextCount > filteredProducts.length
        ? filteredProducts.length
        : nextCount;
  }

  // =====================================================
  // RESERVED ASSETS
  // =====================================================

  int getReservedCountForProduct(String productId) {
    final ReservedAssetItem? found = reservedAssets.firstWhereOrNull(
      (item) => item.product.id == productId,
    );

    return found?.units ?? 0;
  }

  int get totalReservedUnits {
    return reservedAssets.fold<int>(0, (sum, item) => sum + item.units);
  }

  int get totalReservedInvestment {
    return reservedAssets.fold<int>(
      0,
      (sum, item) => sum + item.totalInvestment,
    );
  }

  int get totalReservedMonthlyReturn {
    return reservedAssets.fold<int>(
      0,
      (sum, item) => sum + item.totalMonthlyReturn,
    );
  }

  void reserveProduct(
    EVProductModel product, {
    int units = 1,
    bool openCart = false,
  }) {
    if (units < 1) units = 1;

    final ReservedAssetItem? existing = reservedAssets.firstWhereOrNull(
      (item) => item.product.id == product.id,
    );

    if (existing != null) {
      existing.units += units;
      reservedAssets.refresh();
    } else {
      reservedAssets.add(ReservedAssetItem(product: product, units: units));
    }

    Get.snackbar(
      'Reserved',
      '${product.vehicleModelName} (${product.vehicleId}) added to reserved list.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primary,
      colorText: AppColors.textInverse,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(12),
    );

    if (openCart) {
      openReservedAssetsPage();
    }
  }

  void removeReservedProduct(EVProductModel product) {
    final ReservedAssetItem? existing = reservedAssets.firstWhereOrNull(
      (item) => item.product.id == product.id,
    );

    if (existing == null) return;

    if (existing.units > 1) {
      existing.units -= 1;
      reservedAssets.refresh();
    } else {
      reservedAssets.remove(existing);
    }

    Get.snackbar(
      'Removed',
      '${product.vehicleModelName} removed from reserved list.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primary,
      colorText: AppColors.textInverse,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(12),
    );
  }

  void removeReservedItemCompletely(String productId) {
    reservedAssets.removeWhere((item) => item.product.id == productId);
  }

  void clearReservedAssets() {
    reservedAssets.clear();
  }

  // =====================================================
  // NAVIGATION
  // =====================================================

  final RxBool isLoadingProductDetail = false.obs;
  Future<void> openProductSpecs(EVProductModel product) async {
    if (isLoadingProductDetail.value) return;

    isLoadingProductDetail.value = true;

    try {
      final Map<String, dynamic> response =
          await ApiServiceEvFleet.getVehicleById(product.vehicleId);

      if (response['success'] != true) {
        throw Exception(
          response['message']?.toString() ??
              'Unable to fetch vehicle specifications',
        );
      }

      dynamic vehicleData = response['data'];

      // Support direct vehicle object or nested data response.
      while (vehicleData is Map &&
          vehicleData['data'] is Map &&
          vehicleData['_id'] == null &&
          vehicleData['vehicleId'] == null) {
        vehicleData = vehicleData['data'];
      }

      if (vehicleData is! Map) {
        throw Exception('Invalid vehicle details response');
      }

      final EVProductModel vehicle = EVProductModel.fromJson(
        Map<String, dynamic>.from(vehicleData),
      );

      Get.to(() => ProductSpecPage(product: vehicle));
    } catch (e) {
      debugPrint('Product Specification API Error: $e');

      Get.snackbar(
        'Unable to Load Specifications',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primary,
        colorText: AppColors.textInverse,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isLoadingProductDetail.value = false;
    }
  }

  void openReservedAssetsPage() {
    Get.to(() => const ReservedAssetsPage());
  }

  void onReservedButtonPressed() {
    openReservedAssetsPage();
  }

  void onFindStoreTap() {
    // Add store map navigation here.
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchController.dispose();

    super.onClose();
  }
}
