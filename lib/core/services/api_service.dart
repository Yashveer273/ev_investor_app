import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../screens/pages/Portfolio/components/portfolio_model.dart';
import '../../screens/pages/Profile/components/profile_model.dart';

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
  static const String investorIdKey = 'auth_investor_id';

  static final GetStorage _storage = GetStorage();

  // ============================================================
  // AUTH SESSION / CENTRAL INVESTOR ID
  // ============================================================

  static String _cachedInvestorId = '';

  static String? get token => _storage.read<String>(tokenKey);

  /// Central Investor ID.
  /// Storage is read only when the in-memory cache is empty.
  static String get investorId {
    if (_cachedInvestorId.isNotEmpty) {
      return _cachedInvestorId;
    }

    _cachedInvestorId = (_storage.read(investorIdKey) ?? '').toString().trim();

    return _cachedInvestorId;
  }

  static Future<void> saveToken(String? jwtToken) async {
    if (jwtToken != null && jwtToken.trim().isNotEmpty) {
      await _storage.write(tokenKey, jwtToken.trim());
    }
  }

  static Future<void> saveInvestorId(String? id) async {
    final String cleanId = (id ?? '').trim();

    if (cleanId.isEmpty) return;

    _cachedInvestorId = cleanId;
    await _storage.write(investorIdKey, cleanId);
  }

  static Future<void> clearToken() async {
    await _storage.remove(tokenKey);
  }

  static Future<void> clearInvestorId() async {
    _cachedInvestorId = '';
    await _storage.remove(investorIdKey);
  }

  /// Loads and caches the investor ID when it is missing after app refresh.
  static Future<String> ensureInvestorId() async {
    final String savedId = investorId;
    if (savedId.isNotEmpty) return savedId;

    await getProfile();

    final String profileId = investorId;
    if (profileId.isNotEmpty) return profileId;

    throw const ApiException(
      'Investor ID is unavailable for this account',
      statusCode: 401,
    );
  }

  static String _unwrapId(dynamic value) {
    if (value is Map) {
      return _unwrapId(
        value[r'$oid'] ?? value['_id'] ?? value['investorId'] ?? value['id'],
      );
    }
    return (value ?? '').toString().trim();
  }

  /// Always prefers the current logged-in investor ID.
  /// The optional fallback is retained for backward compatibility.
  static String _getInvestorId([String? fallbackId]) {
    final String currentId = investorId;

    if (currentId.isNotEmpty) {
      return currentId;
    }

    final String fallback = (fallbackId ?? '').trim();

    if (fallback.isNotEmpty) {
      return fallback;
    }

    throw const ApiException(
      'Investor ID not found. Please login again.',
      statusCode: 400,
    );
  }

  // ============================================================
  // COMMON HELPERS
  // ============================================================

  static String normalizePhone(String raw) {
    String clean = raw.replaceAll(RegExp(r'\s+'), '').trim();

    if (clean.startsWith('+91')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('91') && clean.length > 10) {
      clean = clean.substring(2);
    }

    return clean;
  }

  static Map<String, String> _headers({
    bool requiresAuth = false,
    String? investorId,
  }) {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final String id = (investorId ?? '').trim();

    if (id.isNotEmpty) {
      headers['x-investor-id'] = id;
    }

    if (requiresAuth) {
      final String? currentToken = token;

      if (currentToken != null && currentToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $currentToken';
      }
    }

    return headers;
  }

  static Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final Uri uri = Uri.parse('$baseUrl$path');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: queryParameters);
  }

  static Map<String, dynamic> _decodeBody(http.Response response) {
    final String raw = response.body.trim();

    if (raw.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final dynamic decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{'data': decoded};
    } catch (_) {
      throw ApiException(
        'Invalid server response (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }

  static void _checkResponse(
    http.Response response,
    Map<String, dynamic> body,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        (body['message'] ?? 'Request failed (${response.statusCode})')
            .toString(),
        statusCode: response.statusCode,
      );
    }

    if (body['success'] == false) {
      throw ApiException(
        (body['message'] ?? 'Operation failed').toString(),
        statusCode: response.statusCode,
      );
    }
  }

  static int _validatePortfolioMonths(int months) {
    if (months != 6 && months != 12) {
      throw const ApiException(
        'months must be either 6 or 12',
        statusCode: 400,
      );
    }

    return months;
  }

  static String _requireAssetId(String assetId) {
    final String cleanId = assetId.trim();

    if (cleanId.isEmpty) {
      throw const ApiException('assetId is required', statusCode: 400);
    }

    return cleanId;
  }

  static Map<String, dynamic> _responseData(Map<String, dynamic> body) {
    final dynamic data = body['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return body;
  }

  static String? _extractInvestorId(Map<String, dynamic> body) {
    final Map<String, dynamic> data = _responseData(body);

    final dynamic investor = data['investor'] ?? data['profile'];

    if (investor is Map) {
      final String id = _unwrapId(
        investor['investorId'] ??
            investor['investor_id'] ??
            investor['_id'] ??
            investor['id'],
      );

      if (id.isNotEmpty) return id;
    }

    final String id = _unwrapId(
      data['investorId'] ?? data['investor_id'] ?? data['_id'] ?? data['id'],
    );

    return id.isEmpty ? null : id;
  }

  // ============================================================
  // AUTH APIs
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String city = 'Aligarh, Uttar Pradesh',
  }) async {
    final http.Response response = await http.post(
      _uri('/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'fullName': fullName.trim(),
        'phone': normalizePhone(phone),
        'email': email.trim().toLowerCase(),
        'password': password,
        'city': city.trim(),
      }),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    await saveToken(body['token']?.toString());
    await saveInvestorId(_extractInvestorId(body));

    return body;
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final http.Response response = await http.post(
      _uri('/auth/login'),
      headers: _headers(),
      body: jsonEncode({'phone': normalizePhone(phone), 'password': password}),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    await saveToken(body['token']?.toString());
    await saveInvestorId(_extractInvestorId(body));

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
      await clearInvestorId();
    }
  }

  // ============================================================
  // PROFILE APIs
  // ============================================================

  static Future<InvestorProfileModel> getProfile() async {
    final http.Response response = await http.get(
      _uri('/profile'),
      headers: _headers(requiresAuth: true),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    final Map<String, dynamic> data = _responseData(body);

    final Map<String, dynamic> rawProfile = Map<String, dynamic>.from(
      data['profile'] ?? data['investor'] ?? data,
    );

    final String profileId = _unwrapId(
      rawProfile['investorId'] ??
          rawProfile['investor_id'] ??
          rawProfile['_id'] ??
          rawProfile['id'],
    );

    await saveInvestorId(profileId);

    return InvestorProfileModel.fromJson(rawProfile);
  }

  static Future<InvestorProfileModel> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? city,
  }) async {
    final Map<String, dynamic> payload = {};

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

    final Map<String, dynamic> data = _responseData(body);

    final Map<String, dynamic> rawProfile = Map<String, dynamic>.from(
      data['profile'] ?? data['investor'] ?? data,
    );

    await saveInvestorId(
      (rawProfile['_id'] ?? rawProfile['id'] ?? rawProfile['investorId'] ?? '')
          .toString(),
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
      body: jsonEncode({
        'accountHolderName': accountHolderName.trim(),
        'accountNumber': accountNumber.trim(),
        'ifscCode': ifscCode.trim().toUpperCase(),
        'bankName': bankName.trim(),
        'upiId': upiId.trim(),
      }),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    final Map<String, dynamic> data = _responseData(body);

    final Map<String, dynamic> rawProfile = Map<String, dynamic>.from(
      data['profile'] ?? data['investor'] ?? data,
    );

    return InvestorProfileModel.fromJson(rawProfile);
  }

  // ============================================================
  // KYC APIs
  // ============================================================

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
      return http.MediaType('image', 'webp');
    }

    return http.MediaType('image', 'jpeg');
  }

  static String _ensureImageExtension(String rawName, String fieldName) {
    final String clean = rawName.trim();

    if (clean.isEmpty) return '$fieldName.jpg';

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

      return http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType: _resolveKycMediaType(filename),
      );
    }

    if (!kIsWeb && file != null && await file.exists()) {
      final String baseName = file.path.split(RegExp(r'[/\\]')).last;

      final String filename = _ensureImageExtension(baseName, fieldName);

      return http.MultipartFile.fromPath(
        fieldName,
        file.path,
        filename: filename,
        contentType: _resolveKycMediaType(filename),
      );
    }

    return null;
  }

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

    request.fields.addAll({
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

  // ============================================================
  // PRIVACY FEEDBACK API
  // ============================================================

  static Future<Map<String, dynamic>> submitFeedback({
    required String topic,
    required String message,
    String? submittedDate,
  }) async {
    final http.Response response = await http.post(
      _uri('/profile/feedback'),
      headers: _headers(requiresAuth: true),
      body: jsonEncode({
        'topic': topic.trim(),
        'message': message.trim(),
        if (submittedDate != null) 'submittedDate': submittedDate,
      }),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return body;
  }

  // ============================================================
  // INVESTOR PORTFOLIO APIs
  // All methods use the centralized investorId.
  // ============================================================

  // GET /portfolio/overview?page=1&limit=10&months=6

  static Future<PortfolioOverviewResponse> getPortfolioOverview({
    int page = 1,
    int limit = 10,
    int months = 6,
  }) async {
    final String cleanInvestorId = _getInvestorId();
    final int graphMonths = _validatePortfolioMonths(months);

    final http.Response response = await http.get(
      _uri(
        '/portfolio/overview',
        queryParameters: {
          'investorId': cleanInvestorId,
          'page': page.toString(),
          'limit': limit.toString(),
          'months': graphMonths.toString(),
        },
      ),
      headers: _headers(requiresAuth: true, investorId: cleanInvestorId),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return PortfolioOverviewResponse.fromJson(_responseData(body));
  }

  // GET /portfolio/graph?months=6|12
  // Use only if this route exists in your backend.

  static Future<PortfolioGraphData> getPortfolioGraph({int months = 6}) async {
    final String cleanInvestorId = _getInvestorId();
    final int graphMonths = _validatePortfolioMonths(months);

    final http.Response response = await http.get(
      _uri(
        '/portfolio/graph',
        queryParameters: {
          'investorId': cleanInvestorId,
          'months': graphMonths.toString(),
        },
      ),
      headers: _headers(requiresAuth: true, investorId: cleanInvestorId),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    final Map<String, dynamic> data = _responseData(body);
    final dynamic rawGraph = data['graph'] ?? data;

    if (rawGraph is! Map) {
      throw const ApiException('Invalid portfolio graph response');
    }

    return PortfolioGraphData.fromJson(Map<String, dynamic>.from(rawGraph));
  }

  // POST /portfolio/buy

  static Future<Map<String, dynamic>> buyPortfolioProduct(
    Map<String, dynamic> payload,
  ) async {
    final String cleanInvestorId = _getInvestorId();

    final Map<String, dynamic> requestBody = {
      ...payload,
      'investorId': cleanInvestorId,
    };

    final http.Response response = await http.post(
      _uri('/portfolio/buy'),
      headers: _headers(requiresAuth: true, investorId: cleanInvestorId),
      body: jsonEncode(requestBody),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return _responseData(body);
  }

  // BUY PRODUCT ASSET
  // Investor ID is automatically taken from ApiService.investorId.
  // No plan duration / tenure is sent.

  static Future<Map<String, dynamic>> buyProductAsset({
    required Map<String, dynamic> productJson,
    required num investmentAmount,
    int units = 1,
    String? purchaseDate,
    String? nextReinvestmentDate,
    num? nextReinvestmentAmount,
    num? monthlyReturn,
  }) async {
    final String cleanInvestorId = _getInvestorId();

    final String productId =
        (productJson['id'] ??
                productJson['mongoId'] ??
                productJson['_id'] ??
                productJson['productId'] ??
                '')
            .toString()
            .trim();

    if (productId.isEmpty) {
      throw const ApiException('productId is required', statusCode: 400);
    }

    if (units <= 0) {
      throw const ApiException(
        'units must be greater than zero',
        statusCode: 400,
      );
    }

    if (investmentAmount <= 0) {
      throw const ApiException(
        'investmentAmount must be greater than zero',
        statusCode: 400,
      );
    }

    final Map<String, dynamic> payload = {
      'investorId': cleanInvestorId,
      'productId': productId,
      'product': productJson,
      'investmentAmount': investmentAmount,
      'units': units,
      if (purchaseDate != null && purchaseDate.trim().isNotEmpty)
        'purchaseDate': purchaseDate.trim(),
      if (nextReinvestmentDate != null &&
          nextReinvestmentDate.trim().isNotEmpty)
        'nextReinvestmentDate': nextReinvestmentDate.trim(),
      if (nextReinvestmentAmount != null)
        'nextReinvestmentAmount': nextReinvestmentAmount,
      if (monthlyReturn != null) 'monthlyReturn': monthlyReturn,
    };

    return buyPortfolioProduct(payload);
  }

  // GET /portfolio/assets/:assetId

  static Future<PortfolioAssetDetailModel> getAssetDetail(
    String assetId, {
    int months = 6,
  }) async {
    final String cleanInvestorId = _getInvestorId();
    final String cleanAssetId = _requireAssetId(assetId);
    final int graphMonths = _validatePortfolioMonths(months);

    final http.Response response = await http.get(
      _uri(
        '/portfolio/assets/$cleanAssetId',
        queryParameters: {
          'investorId': cleanInvestorId,
          'months': graphMonths.toString(),
        },
      ),
      headers: _headers(requiresAuth: true, investorId: cleanInvestorId),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return PortfolioAssetDetailModel.fromJson(_responseData(body));
  }

  // GET /portfolio/assets/:assetId/graph?months=6|12

  static Future<PortfolioGraphData> getAssetGraph({
    required String assetId,
    int months = 6,
  }) async {
    final String cleanInvestorId = _getInvestorId();
    final String cleanAssetId = _requireAssetId(assetId);
    final int graphMonths = _validatePortfolioMonths(months);

    final http.Response response = await http.get(
      _uri(
        '/portfolio/assets/$cleanAssetId/graph',
        queryParameters: {
          'investorId': cleanInvestorId,
          'months': graphMonths.toString(),
        },
      ),
      headers: _headers(requiresAuth: true, investorId: cleanInvestorId),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    final Map<String, dynamic> data = _responseData(body);

    // API response graph is a List, not a Map.
    final dynamic rawGraph = data['graph'];

    if (rawGraph is! List) {
      throw const ApiException(
        'Invalid asset graph response: graph must be a List',
      );
    }

    // Convert API response into the model's expected JSON structure.
    return PortfolioGraphData.fromJson({
      'graph': rawGraph,
      'points': rawGraph,
      'months': graphMonths,
      'scope': 'asset',
      'assetId': cleanAssetId,
    });
  }
  // POST /portfolio/assets/:assetId/renew
  // No plan duration / tenure.

  static Future<Map<String, dynamic>> renewAsset({
    required String assetId,
    required num reinvestAmount,
    String? investmentDate,
    String? nextReinvestmentDate,
    num? nextReinvestmentAmount,
  }) async {
    final String cleanInvestorId = _getInvestorId();
    final String cleanAssetId = _requireAssetId(assetId);

    final Map<String, dynamic> payload = {
      'investorId': cleanInvestorId,
      'reinvestAmount': reinvestAmount,
      if (investmentDate != null && investmentDate.trim().isNotEmpty)
        'investmentDate': investmentDate.trim(),
      if (nextReinvestmentDate != null &&
          nextReinvestmentDate.trim().isNotEmpty)
        'nextReinvestmentDate': nextReinvestmentDate.trim(),
      if (nextReinvestmentAmount != null)
        'nextReinvestmentAmount': nextReinvestmentAmount,
    };

    final http.Response response = await http.post(
      _uri('/portfolio/assets/$cleanAssetId/renew'),
      headers: _headers(requiresAuth: true, investorId: cleanInvestorId),
      body: jsonEncode(payload),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return _responseData(body);
  }

  // GET /portfolio/next-payment

  static Future<Map<String, dynamic>> getInvestorNextPayments() async {
    final String cleanInvestorId = _getInvestorId();

    final http.Response response = await http.get(
      _uri(
        '/portfolio/next-payment',
        queryParameters: {'investorId': cleanInvestorId},
      ),
      headers: _headers(requiresAuth: true, investorId: cleanInvestorId),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return body;
  }

  // GET /portfolio/return-history?page=1&limit=10

  static Future<Map<String, dynamic>> getInvestorReturnHistory({
    int page = 1,
    int limit = 10,
  }) async {
    final String cleanInvestorId = _getInvestorId();

    final http.Response response = await http.get(
      _uri(
        '/portfolio/return-history',
        queryParameters: {
          'investorId': cleanInvestorId,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      ),
      headers: _headers(requiresAuth: true, investorId: cleanInvestorId),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return body;
  }

  static Future<Map<String, dynamic>> getInvestorPortfolioHistory({
    int months = 6,
    int page = 1,
    int limit = 10,
  }) async {
    final String cleanInvestorId = _getInvestorId();

    final http.Response response = await http.get(
      _uri(
        '/portfolio/history',
        queryParameters: {
          'investorId': cleanInvestorId,
          'months': months.toString(),
          'page': page.toString(),
          'limit': limit.toString(),
        },
      ),
      headers: _headers(requiresAuth: true, investorId: cleanInvestorId),
    );

    final Map<String, dynamic> body = _decodeBody(response);
    _checkResponse(response, body);

    return body;
  }
}
