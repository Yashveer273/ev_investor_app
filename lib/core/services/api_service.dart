import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import '../../screens/pages/Portfolio/components/portfolio_model.dart';
import '../../screens/pages/Profile/components/profile_model.dart';

/// Top-level Base URL configuration
const String kApiBaseUrl = 'http://192.168.1.8:5004/api';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, {this.statusCode = 500});

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();

  static const String baseUrl = kApiBaseUrl;
  static const String tokenKey = 'auth_jwt_token';

  static final GetStorage _storage = GetStorage();

  static String? get token => _storage.read<String>(tokenKey);

  static Future<void> saveToken(String? jwtToken) async {
    if (jwtToken != null && jwtToken.trim().isNotEmpty) {
      await _storage.write(tokenKey, jwtToken.trim());
    }
  }

  static Future<void> clearToken() async {
    await _storage.remove(tokenKey);
  }

  static String normalizePhone(String raw) {
    String clean = raw.replaceAll(RegExp(r'\s+'), '').trim();

    if (clean.startsWith('+91')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('91') && clean.length > 10) {
      clean = clean.substring(2);
    }

    return clean;
  }

  static Map<String, String> _headers({bool requiresAuth = false}) {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final String? currentToken = token;

      if (currentToken != null && currentToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $currentToken';
      }
    }

    return headers;
  }

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static Map<String, dynamic> _decodeBody(http.Response response) {
    final String raw = response.body.trim();

    if (raw.isEmpty) return <String, dynamic>{};

    final dynamic decoded = jsonDecode(raw);

    if (decoded is Map<String, dynamic>) return decoded;

    return <String, dynamic>{'data': decoded};
  }

  static void _checkResponse(
    http.Response response,
    Map<String, dynamic> body,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final String msg =
          (body['message'] ?? 'Request failed (${response.statusCode})')
              .toString();

      throw ApiException(msg, statusCode: response.statusCode);
    }

    if (body.containsKey('success') && body['success'] == false) {
      throw ApiException(
        (body['message'] ?? 'Operation failed').toString(),
        statusCode: response.statusCode,
      );
    }
  }

  // =========================================================================
  // AUTH APIs
  // =========================================================================

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String city = 'Aligarh, Uttar Pradesh',
  }) async {
    final String cleanPhone = normalizePhone(phone);

    final http.Response response = await http.post(
      _uri('/auth/register'),
      headers: _headers(),
      body: jsonEncode(<String, dynamic>{
        'fullName': fullName.trim(),
        'phone': cleanPhone,
        'email': email.trim().toLowerCase(),
        'password': password,
        'city': city.trim(),
      }),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    await saveToken(body['token']?.toString());

    return body;
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final String cleanPhone = normalizePhone(phone);

    final http.Response response = await http.post(
      _uri('/auth/login'),
      headers: _headers(),
      body: jsonEncode(<String, dynamic>{
        'phone': cleanPhone,
        'password': password,
      }),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    await saveToken(body['token']?.toString());

    return body;
  }

  static Future<void> logout() async {
    try {
      if (token != null && token!.isNotEmpty) {
        await http.post(
          _uri('/auth/logout'),
          headers: _headers(requiresAuth: true),
        );
      }
    } finally {
      await clearToken();
    }
  }

  // =========================================================================
  // PROFILE APIs
  // =========================================================================

  static Future<InvestorProfileModel> getProfile() async {
    final http.Response response = await http.get(
      _uri('/profile'),
      headers: _headers(requiresAuth: true),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    final Map<String, dynamic> rawProfile = Map<String, dynamic>.from(
      body['profile'] ?? body['investor'] ?? body,
    );

    return InvestorProfileModel.fromJson(rawProfile);
  }

  static Future<InvestorProfileModel> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? city,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{};

    if (fullName != null) payload['fullName'] = fullName.trim();
    if (phone != null) payload['phone'] = normalizePhone(phone);
    if (email != null) payload['email'] = email.trim().toLowerCase();
    if (city != null) payload['city'] = city.trim();

    final http.Response response = await http.put(
      _uri('/profile'),
      headers: _headers(requiresAuth: true),
      body: jsonEncode(payload),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    final Map<String, dynamic> rawProfile = Map<String, dynamic>.from(
      body['profile'] ?? body['investor'] ?? body,
    );

    return InvestorProfileModel.fromJson(rawProfile);
  }

  static Future<InvestorProfileModel> updateBankDetails({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    required String upiId,
  }) async {
    final http.Response response = await http.put(
      _uri('/profile/bank-details'),
      headers: _headers(requiresAuth: true),
      body: jsonEncode(<String, dynamic>{
        'accountHolderName': accountHolderName.trim(),
        'accountNumber': accountNumber.trim(),
        'ifscCode': ifscCode.trim().toUpperCase(),
        'bankName': bankName.trim(),
        'upiId': upiId.trim(),
      }),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    final Map<String, dynamic> rawProfile = Map<String, dynamic>.from(
      body['profile'] ?? body['investor'] ?? body,
    );

    return InvestorProfileModel.fromJson(rawProfile);
  }

  // =========================================================================
  // KYC APIs
  // =========================================================================

  /// Get investor KYC status
  static Future<Map<String, dynamic>> getKycStatus() async {
    final http.Response response = await http.get(
      _uri('/profile/kyc/status'),
      headers: _headers(requiresAuth: true),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return body;
  }

  static http.MediaType _resolveKycMediaType(String filename) {
    final String lower = filename.toLowerCase().trim();
    if (lower.endsWith('.png')) {
      return http.MediaType('image', 'png');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }

  static String _ensureImageExtension(String rawName, String fieldName) {
    final String clean = rawName.trim();
    if (clean.isEmpty) {
      return '$fieldName.jpg';
    }
    final String lower = clean.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return clean;
    }
    return '$clean.jpg';
  }

  static Future<http.MultipartFile?> _buildKycMultipartFile({
    required String fieldName,
    File? file,
    XFile? xFile,
  }) async {
    if (xFile != null) {
      final Uint8List bytes = await xFile.readAsBytes();
      if (bytes.isEmpty) return null;

      final String filename = _ensureImageExtension(xFile.name, fieldName);
      final http.MediaType mediaType = _resolveKycMediaType(filename);

      return http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType: mediaType,
      );
    }

    if (!kIsWeb && file != null && await file.exists()) {
      final String baseName = file.path.split(RegExp(r'[/\\]')).last;
      final String filename = _ensureImageExtension(baseName, fieldName);
      final http.MediaType mediaType = _resolveKycMediaType(filename);

      return http.MultipartFile.fromPath(
        fieldName,
        file.path,
        filename: filename,
        contentType: mediaType,
      );
    }

    return null;
  }

  /// Submit investor KYC details
  static Future<Map<String, dynamic>> submitKyc({
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
    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      _uri('/profile/kyc/submit'),
    );

    final Map<String, String> headers = Map<String, String>.from(
      _headers(requiresAuth: true),
    );
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    request.fields.addAll(<String, String>{
      'fullNameAsPerPan': fullNameAsPerPan.trim(),
      'panNumber': panNumber.trim().toUpperCase(),
      'aadhaarNumber': aadhaarNumber.replaceAll(RegExp(r'\s+'), '').trim(),
      'dob': dob.trim(),
      'address': address.trim(),
    });

    final http.MultipartFile? panMultipart = await _buildKycMultipartFile(
      fieldName: 'panImage',
      file: panImage,
      xFile: panXFile,
    );
    if (panMultipart != null) {
      request.files.add(panMultipart);
    }

    final http.MultipartFile? aadhaarMultipart = await _buildKycMultipartFile(
      fieldName: 'aadhaarImage',
      file: aadhaarImage,
      xFile: aadhaarXFile,
    );
    if (aadhaarMultipart != null) {
      request.files.add(aadhaarMultipart);
    }

    final http.StreamedResponse streamedResponse = await request.send();
    final http.Response response = await http.Response.fromStream(
      streamedResponse,
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return body;
  }
  // =========================================================================
  // PRIVACY FEEDBACK API
  // =========================================================================

  static Future<Map<String, dynamic>> submitFeedback({
    required String topic,
    required String message,
    String? submittedDate,
  }) async {
    final http.Response response = await http.post(
      _uri('/profile/feedback'),
      headers: _headers(requiresAuth: true),
      body: jsonEncode(<String, dynamic>{
        'topic': topic.trim(),
        'message': message.trim(),
        if (submittedDate != null) 'submittedDate': submittedDate,
      }),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return body;
  }

  // =========================================================================
  // PORTFOLIO APIs
  // =========================================================================

  static Future<PortfolioOverviewResponse> getPortfolioOverview() async {
    final http.Response response = await http.get(
      _uri('/portfolio/overview'),
      headers: _headers(requiresAuth: true),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return PortfolioOverviewResponse.fromJson(body);
  }

  static Future<Map<String, dynamic>> buyPortfolioProduct(
    Map<String, dynamic> payload,
  ) async {
    final http.Response response = await http.post(
      _uri('/portfolio/buy'),
      headers: _headers(requiresAuth: true),
      body: jsonEncode(payload),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return body;
  }

  static Future<PortfolioAssetDetailModel> getAssetDetail(
    String assetId,
  ) async {
    final http.Response response = await http.get(
      _uri('/portfolio/assets/$assetId'),
      headers: _headers(requiresAuth: true),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    final Map<String, dynamic> rawDetail = Map<String, dynamic>.from(
      body['detail'] ?? body,
    );

    return PortfolioAssetDetailModel.fromJson(rawDetail);
  }

  static Future<Map<String, dynamic>> renewAsset({
    required String assetId,
    required int extraMonths,
    required int reinvestAmount,
  }) async {
    final http.Response response = await http.post(
      _uri('/portfolio/assets/$assetId/renew'),
      headers: _headers(requiresAuth: true),
      body: jsonEncode(<String, dynamic>{
        'extraMonths': extraMonths,
        'reinvestAmount': reinvestAmount,
      }),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return body;
  }
}
