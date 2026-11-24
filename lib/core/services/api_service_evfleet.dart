import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ev_investors_app/screens/pages/Home/components/store_model.dart';

class ApiServiceEvFleet {
  // ==========================================
  // SERVER CONFIGURATION
  // ==========================================

  static const String vehicleBaseUrl = 'http://192.168.1.8:5003';
  static const String clusterBaseUrl = 'http://192.168.1.8:5000';

  static const String investorEvBaseUrl = '$vehicleBaseUrl/api/investor_EV';

  static const Duration _timeout = Duration(seconds: 10);

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ==========================================
  // VEHICLES API - SERVER 5003
  // ==========================================

  static Future<Map<String, dynamic>> getVehicles({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('$vehicleBaseUrl/api/vehicles/AppsearchVehicles')
          .replace(
            queryParameters: {
              'page': page.toString(),
              'limit': limit.toString(),
            },
          );

      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
          'message': 'Vehicles fetched successfully',
        };
      }

      return {
        'success': false,
        'message': responseData is Map
            ? responseData['message']?.toString() ?? 'Failed to fetch vehicles'
            : 'Failed to fetch vehicles',
        'data': responseData,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Vehicle server request timed out',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Vehicle API Error: $e',
        'data': null,
      };
    }
  }

  // ==========================================
  // CLUSTERS / STORES API - SERVER 5000
  // ==========================================

  static Future<StoreResponseModel> getStores({
    double? lat,
    double? long,
    String? zipCode,
    String? city,
    String? state,
    String? streetAddress,
    String? query,
    String? status,
    String path = '/api/clusters/stores',
  }) async {
    final Map<String, String> params = {};

    if (lat != null) params['lat'] = lat.toString();
    if (long != null) params['long'] = long.toString();

    if (zipCode != null && zipCode.trim().isNotEmpty) {
      params['zipCode'] = zipCode.trim();
    }

    if (city != null && city.trim().isNotEmpty) {
      params['city'] = city.trim();
    }

    if (state != null && state.trim().isNotEmpty) {
      params['state'] = state.trim();
    }

    if (streetAddress != null && streetAddress.trim().isNotEmpty) {
      params['streetAddress'] = streetAddress.trim();
    }

    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }

    if (status != null && status.trim().isNotEmpty) {
      params['status'] = status.trim();
    }

    try {
      final uri = Uri.parse(
        '$clusterBaseUrl$path',
      ).replace(queryParameters: params.isEmpty ? null : params);

      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map) {
          return StoreResponseModel.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }

        throw Exception('Invalid stores API response format');
      }

      final message = decoded is Map
          ? decoded['message']?.toString() ?? 'Failed to fetch stores'
          : 'Failed to fetch stores';

      throw Exception('$message (Status: ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Stores server request timed out');
    } catch (e) {
      throw Exception('Stores API Error: $e');
    }
  }

  // ==========================================
  // VEHICLE DETAILS BY ID
  // ==========================================

  static Future<Map<String, dynamic>> getVehicleById(String vehicleId) async {
    try {
      if (vehicleId.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Vehicle ID is required',
          'data': null,
        };
      }

      final uri = Uri.parse(
        '$vehicleBaseUrl/api/vehicles/AppsearchVehicleById/'
        '${Uri.encodeComponent(vehicleId.trim())}',
      );

      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }

        throw Exception('Invalid vehicle API response');
      }

      return {
        'success': false,
        'message': decoded is Map
            ? decoded['message']?.toString() ?? 'Failed to fetch vehicle'
            : 'Failed to fetch vehicle',
        'data': null,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Vehicle server request timed out',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Vehicle API Error: $e',
        'data': null,
      };
    }
  }

  // ==========================================
  // INVESTOR EV PRODUCTS API
  // ==========================================

  static Future<Map<String, dynamic>> getInvestorEvProducts({
    int page = 1,
    int limit = 10,
    String? category,
    String? search,
  }) async {
    try {
      final Map<String, String> params = {
        'page': (page > 0 ? page : 1).toString(),
        'limit': (limit > 0 ? limit : 10).toString(),
      };

      if (category != null &&
          category.trim().isNotEmpty &&
          category.trim().toLowerCase() != 'all') {
        params['category'] = category.trim();
      }

      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }

      final uri = Uri.parse(
        '$investorEvBaseUrl/products',
      ).replace(queryParameters: params);

      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> bodyMap = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : {'data': decoded};

        return {
          'success': true,
          'data': bodyMap['data'] ?? decoded,
          'pagination': bodyMap['pagination'],
          'count': bodyMap['count'],
          'message':
              bodyMap['message']?.toString() ??
              'Investor EV products fetched successfully',
        };
      }

      return {
        'success': false,
        'message': decoded is Map
            ? decoded['message']?.toString() ??
                  'Failed to fetch investor EV products'
            : 'Failed to fetch investor EV products',
        'data': decoded,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Investor EV server request timed out',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Investor EV API Error: $e',
        'data': null,
      };
    }
  }

  // ==========================================
  // INVESTOR EV PRODUCT DETAILS BY ID
  // ==========================================

  static Future<Map<String, dynamic>> getInvestorEvProductById(
    String productId,
  ) async {
    try {
      if (productId.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Product ID is required',
          'data': null,
        };
      }

      final uri = Uri.parse(
        '$investorEvBaseUrl/products/'
        '${Uri.encodeComponent(productId.trim())}',
      );

      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> bodyMap = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : {'data': decoded};

        return {
          'success': true,
          'data': bodyMap['data'] ?? decoded,
          'message':
              bodyMap['message']?.toString() ??
              'Investor EV product fetched successfully',
        };
      }

      return {
        'success': false,
        'message': decoded is Map
            ? decoded['message']?.toString() ??
                  'Failed to fetch investor EV product'
            : 'Failed to fetch investor EV product',
        'data': decoded,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Investor EV server request timed out',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Investor EV API Error: $e',
        'data': null,
      };
    }
  }

  // ==========================================
  // VALIDATE INVESTOR COUPON
  // ==========================================

  static Future<Map<String, dynamic>> validateCoupon({
    required String code,
    String? phone,
    int? amount,
  }) async {
    return validateInvestorCoupon(code: code, phone: phone, amount: amount);
  }

  static Future<Map<String, dynamic>> validateInvestorCoupon({
    required String code,
    String? phone,
    int? amount,
  }) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      final cleanPhone = (phone ?? '').trim();

      if (cleanCode.isEmpty) {
        return {
          'success': false,
          'valid': false,
          'message': 'Coupon code is required',
          'data': null,
        };
      }

      final uri = Uri.parse('$investorEvBaseUrl/coupons/validate');

      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({
              'code': cleanCode,
              if (cleanPhone.isNotEmpty) 'phone': cleanPhone,
              if (amount != null) 'amount': amount,
            }),
          )
          .timeout(_timeout);

      final dynamic decoded = jsonDecode(response.body);

      final Map<String, dynamic> bodyMap = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'valid': bodyMap['valid'] ?? true,
          'message': bodyMap['message']?.toString() ?? 'Coupon is valid',
          'data': bodyMap['data'] ?? decoded,
        };
      }

      return {
        'success': false,
        'valid': false,
        'step': bodyMap['step'],
        'message': bodyMap['message']?.toString() ?? 'Invalid coupon',
        'data': bodyMap['data'],
      };
    } on TimeoutException {
      return {
        'success': false,
        'valid': false,
        'message': 'Coupon server request timed out',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'valid': false,
        'message': 'Coupon API Error: $e',
        'data': null,
      };
    }
  }
}
