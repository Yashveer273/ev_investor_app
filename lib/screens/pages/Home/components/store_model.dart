class StoreResponseModel {
  final List<StoreModel> nearestStores;
  final List<StoreModel> searchStores;

  StoreResponseModel({required this.nearestStores, required this.searchStores});

  factory StoreResponseModel.fromJson(Map<String, dynamic> json) {
    return StoreResponseModel(
      nearestStores: _parseStores(json['nearestStores']),
      searchStores: _parseStores(json['searchStores']),
    );
  }

  static List<StoreModel> _parseStores(dynamic data) {
    if (data is! List) return [];

    return data
        .whereType<Map>()
        .map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'nearestStores': nearestStores.map((e) => e.toJson()).toList(),
      'searchStores': searchStores.map((e) => e.toJson()).toList(),
    };
  }
}

class StoreModel {
  final String id;
  final String vehicleClusterOwnerId;
  final int vehicleCapacity;
  final StoreLocationModel vehicleClusterLocation;

  StoreModel({
    required this.id,
    required this.vehicleClusterOwnerId,
    required this.vehicleCapacity,
    required this.vehicleClusterLocation,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final dynamic location = json['vehicleClusterLocation'] ?? json['location'];

    return StoreModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      vehicleClusterOwnerId: (json['vehicleClusterOwnerId'] ?? '').toString(),
      vehicleCapacity: _parseInt(json['vehicleCapacity']),
      vehicleClusterLocation: StoreLocationModel.fromJson(
        location is Map
            ? Map<String, dynamic>.from(location)
            : <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vehicleClusterOwnerId': vehicleClusterOwnerId,
      'vehicleCapacity': vehicleCapacity,
      'vehicleClusterLocation': vehicleClusterLocation.toJson(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class StoreLocationModel {
  final double lat;
  final double lng;
  final String zipCode;
  final String state;
  final String city;
  final String streetAddress;

  StoreLocationModel({
    required this.lat,
    required this.lng,
    required this.zipCode,
    required this.state,
    required this.city,
    required this.streetAddress,
  });

  factory StoreLocationModel.fromJson(Map<String, dynamic> json) {
    return StoreLocationModel(
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['long'] ?? json['lng']),
      zipCode: (json['zipCode'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      streetAddress: (json['streetAddress'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'long': lng,
      'zipCode': zipCode,
      'state': state,
      'city': city,
      'streetAddress': streetAddress,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
