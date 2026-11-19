class StoreResponseModel {
  final List<StoreModel> nearestStores;
  final List<StoreModel> searchStores;

  StoreResponseModel({required this.nearestStores, required this.searchStores});

  factory StoreResponseModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawNearest =
        json['nearestStores'] as List<dynamic>? ?? [];
    final List<dynamic> rawSearch =
        json['searchStores'] as List<dynamic>? ?? [];

    return StoreResponseModel(
      nearestStores: rawNearest
          .map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      searchStores: rawSearch
          .map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// Dummy data directly inside the model (no API call needed right now)
  factory StoreResponseModel.dummyData() {
    return StoreResponseModel.fromJson(dummyStoresJson);
  }

  static const Map<String, dynamic> dummyStoresJson = {
    'nearestStores': [
      {
        '_id': '6af9defa5428cc289fb00b76',
        'vehicleClusterOwnerId': 'VCO-9293',
        'vehicleCapacity': 5,
        'vehicleClusterLocation': {
          'lat': 27.872132,
          'long': 77.9968,
          'zipCode': '202138',
          'state': 'Uttar Pradesh',
          'city': 'Aligarh',
          'streetAddress': 'MOH MALIPURA PAINTH MAIDAN KHAIR, 24',
        },
      },
      {
        '_id': '6af9defa5428cc289fb00b81',
        'vehicleClusterOwnerId': 'VCO-9304',
        'vehicleCapacity': 8,
        'vehicleClusterLocation': {
          'lat': 28.5355,
          'long': 77.3910,
          'zipCode': '201301',
          'state': 'Uttar Pradesh',
          'city': 'Noida',
          'streetAddress': 'Sector 62 Institutional Area, Block C',
        },
      },
      {
        '_id': '6af9defa5428cc289fb00b89',
        'vehicleClusterOwnerId': 'VCO-9315',
        'vehicleCapacity': 6,
        'vehicleClusterLocation': {
          'lat': 28.5562,
          'long': 77.1000,
          'zipCode': '110037',
          'state': 'Delhi',
          'city': 'New Delhi',
          'streetAddress': 'Aerocity Hospitality District, Plot 14',
        },
      },
    ],
    'searchStores': [
      {
        '_id': '6af9defa5428cc289fb00b76',
        'vehicleClusterOwnerId': 'VCO-9293',
        'vehicleCapacity': 5,
        'vehicleClusterLocation': {
          'lat': 27.872132,
          'long': 77.9968,
          'zipCode': '202138',
          'state': 'Uttar Pradesh',
          'city': 'Aligarh',
          'streetAddress': 'MOH MALIPURA PAINTH MAIDAN KHAIR, 24',
        },
      },
      {
        '_id': '6af9defa5428cc289fb00b81',
        'vehicleClusterOwnerId': 'VCO-9304',
        'vehicleCapacity': 8,
        'vehicleClusterLocation': {
          'lat': 28.5355,
          'long': 77.3910,
          'zipCode': '201301',
          'state': 'Uttar Pradesh',
          'city': 'Noida',
          'streetAddress': 'Sector 62 Institutional Area, Block C',
        },
      },
      {
        '_id': '6af9defa5428cc289fb00b89',
        'vehicleClusterOwnerId': 'VCO-9315',
        'vehicleCapacity': 6,
        'vehicleClusterLocation': {
          'lat': 28.5562,
          'long': 77.1000,
          'zipCode': '110037',
          'state': 'Delhi',
          'city': 'New Delhi',
          'streetAddress': 'Aerocity Hospitality District, Plot 14',
        },
      },
      {
        '_id': '6af9defa5428cc289fb00b92',
        'vehicleClusterOwnerId': 'VCO-9328',
        'vehicleCapacity': 10,
        'vehicleClusterLocation': {
          'lat': 19.1136,
          'long': 72.8697,
          'zipCode': '400093',
          'state': 'Maharashtra',
          'city': 'Mumbai',
          'streetAddress': 'Andheri East MIDC Industrial Estate, 18',
        },
      },
    ],
  };

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
    final Map<String, dynamic> locMap = Map<String, dynamic>.from(
      json['vehicleClusterLocation'] ?? json['location'] ?? {},
    );

    return StoreModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      vehicleClusterOwnerId: (json['vehicleClusterOwnerId'] ?? '').toString(),
      vehicleCapacity: _parseInt(json['vehicleCapacity']),
      vehicleClusterLocation: StoreLocationModel.fromJson(locMap),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vehicleClusterOwnerId': vehicleClusterOwnerId,
      'vehicleCapacity': vehicleCapacity,
      'vehicleClusterLocation': locationJson(),
    };
  }

  Map<String, dynamic> locationJson() => vehicleClusterLocation.toJson();

  static int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
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

  static double _parseDouble(dynamic val) {
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
