import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../components/home_controller.dart';
import '../components/store_model.dart';

class SearchSectionWidget extends StatelessWidget {
  const SearchSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar + Find Store Button (same row, compact Find Store button)
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => TextField(
                    controller: controller.searchController,
                    onChanged: controller.onSearchChanged,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search electric scooter model, ID or brand...',
                      hintStyle: AppTextStyles.bodyRegular.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      suffixIcon: controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              onPressed: controller.clearSearch,
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: controller.onFindStoreTap,
                  icon: Icon(
                    Icons.storefront_outlined,
                    size: 16,
                    color: AppColors.accentMint,
                  ),
                  label: Text(
                    'Find Store',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.textInverse,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textInverse,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // All Store (Default Selected) + Nearest Store Chips
          SizedBox(
            height: 34,
            child: Obx(() {
              final bool isAllSelected =
                  controller.selectedStoreKey.value ==
                  HomeController.allStoreKey;
              final List<StoreModel> stores = controller.nearestStores;

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stores.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _StoreOptionChip(
                      label: 'All Store',
                      isSelected: isAllSelected,
                      onTap: () => controller.onStoreChipSelected(null),
                    );
                  }

                  final StoreModel store = stores[index - 1];
                  final bool isSelected =
                      controller.selectedStoreKey.value == store.id;

                  return _StoreOptionChip(
                    label: '${store.vehicleClusterLocation.city} Store',
                    isSelected: isSelected,
                    onTap: () => controller.onStoreChipSelected(store),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StoreOptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StoreOptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 12,
            color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
