import 'ev_product_model.dart';

class EvFilterModel {
  final String id;
  final String label;

  const EvFilterModel({required this.id, required this.label});

  static const EvFilterModel defaultFilter = EvFilterModel(
    id: 'all',
    label: 'All EVs',
  );

  static const List<String> knownCategoryIds = [
    'electric-scooty',
    'electric-bike',
    'three-wheeler',
    'electric-car',
  ];

  static const List<EvFilterModel> filterCategories = [
    defaultFilter,
    EvFilterModel(id: 'electric-scooty', label: 'Electric Scooty'),
    EvFilterModel(id: 'electric-bike', label: 'Electric Bike'),
    EvFilterModel(id: 'three-wheeler', label: 'Three-Wheeler'),
    EvFilterModel(id: 'electric-car', label: 'Electric Car'),
    EvFilterModel(id: 'other', label: 'Other'),
  ];

  bool matchesProduct(EvProductModel product) {
    final normalizedFilter = id.trim().toLowerCase();
    final normalizedProductCat = product.category.trim().toLowerCase();

    if (normalizedFilter == 'all') {
      return true;
    }

    if (normalizedFilter == 'other') {
      return normalizedProductCat == 'other' ||
          !knownCategoryIds.contains(normalizedProductCat);
    }

    return normalizedProductCat == normalizedFilter;
  }

  factory EvFilterModel.fromJson(Map<String, dynamic> json) {
    return EvFilterModel(
      id: json['id'] as String? ?? 'all',
      label: json['label'] as String? ?? 'All EVs',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label};
  }
}
