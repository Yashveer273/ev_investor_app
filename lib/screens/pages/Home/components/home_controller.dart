import 'dart:async';
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

  var searchQuery = ''.obs;
  var debouncedQuery = ''.obs;
  var isSearching = false.obs;

  var selectedStoreKey = allStoreKey.obs;
  var selectedStore = Rxn<StoreModel>();

  var nearestStores = <StoreModel>[].obs;
  var searchStores = <StoreModel>[].obs;
  var filteredStores = <StoreModel>[].obs;

  var allProducts = <EVProductModel>[].obs;
  var filteredProducts = <EVProductModel>[].obs;
  var visibleProductCount = 6.obs;

  var reservedAssets = <ReservedAssetItem>[].obs;

  Timer? _debounceTimer;
  static const Duration debounceDuration = Duration(milliseconds: 500);

  @override
  void onInit() {
    super.onInit();
    loadAllStoresData();
    loadProductsData();
  }

  void loadAllStoresData() {
    final StoreResponseModel dummy = StoreResponseModel.dummyData();
    selectedStoreKey.value = allStoreKey;
    selectedStore.value = null;

    nearestStores.assignAll(dummy.nearestStores);
    searchStores.assignAll(dummy.searchStores);
    filteredStores.assignAll(dummy.searchStores);
  }

  void loadProductsData() {
    final List<EVProductModel> items = EVProductModel.dummyProducts();
    allProducts.assignAll(items);
    filteredProducts.assignAll(items);
  }

  /// Triggered when a store chip is clicked.
  /// Intended to trigger an API search/fetch around the selected store and
  /// insert the returned data (rather than client-side filtering).
  void onStoreChipSelected(StoreModel? store) {
    if (store == null) {
      loadAllStoresData();
      _applyProductSearchAndStore();
      return;
    }

    selectedStoreKey.value = store.id;
    selectedStore.value = store;

    final StoreResponseModel dummy = StoreResponseModel.dummyData();
    final List<StoreModel> matched = dummy.searchStores
        .where(
          (item) =>
              item.id == store.id ||
              item.vehicleClusterLocation.city.toLowerCase() ==
                  store.vehicleClusterLocation.city.toLowerCase(),
        )
        .toList();

    final List<StoreModel> nextStores = matched.isNotEmpty ? matched : [store];
    searchStores.assignAll(nextStores);
    filteredStores.assignAll(nextStores);
    _applyProductSearchAndStore();
  }

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

  void _applyTextSearch(String query) {
    if (query.isEmpty) {
      filteredStores.assignAll(searchStores);
      return;
    }

    final String q = query.toLowerCase();
    final List<StoreModel> results = searchStores.where((store) {
      return store.vehicleClusterOwnerId.toLowerCase().contains(q) ||
          store.vehicleClusterLocation.city.toLowerCase().contains(q) ||
          store.vehicleClusterLocation.state.toLowerCase().contains(q) ||
          store.vehicleClusterLocation.streetAddress.toLowerCase().contains(
            q,
          ) ||
          store.vehicleClusterLocation.zipCode.toLowerCase().contains(q);
    }).toList();

    filteredStores.assignAll(results);
  }

  void _applyProductSearchAndStore() {
    final String q = debouncedQuery.value.toLowerCase();
    final StoreModel? activeStore = selectedStore.value;

    final List<EVProductModel> results = allProducts.where((item) {
      final bool matchesStore =
          activeStore == null ||
          item.clusterCity.toLowerCase() ==
              activeStore.vehicleClusterLocation.city.toLowerCase() ||
          item.purchaseLocation.toLowerCase() ==
              activeStore.vehicleClusterLocation.city.toLowerCase();

      final bool matchesQuery =
          q.isEmpty ||
          item.vehicleModelName.toLowerCase().contains(q) ||
          item.vehicleId.toLowerCase().contains(q) ||
          item.companyName.toLowerCase().contains(q) ||
          item.vehicleNoPlate.toLowerCase().contains(q) ||
          item.clusterCity.toLowerCase().contains(q);

      return matchesStore && matchesQuery;
    }).toList();

    filteredProducts.assignAll(results);
  }

  void loadMoreScooters() {
    visibleProductCount.value += 3;
  }

  int getReservedCountForProduct(String productId) {
    final ReservedAssetItem? found = reservedAssets.firstWhereOrNull(
      (item) => item.product.id == productId,
    );
    return found?.units ?? 0;
  }

  int get totalReservedUnits {
    return reservedAssets.fold<int>(0, (sum, item) => sum + item.units);
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

  void openProductSpecs(EVProductModel product) {
    Get.to(() => ProductSpecPage(product: product));
  }

  void openReservedAssetsPage() {
    Get.to(() => const ReservedAssetsPage());
  }

  void onReservedButtonPressed() {
    openReservedAssetsPage();
  }

  void onFindStoreTap() {
    // Map screen navigation will be added here next
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
