import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_account.dart';
import '../models/meal_record.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class NutriMateApi {
  NutriMateApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(baseUrl ?? _defaultApiBaseUrl());

  static const _accessKey = 'nutrimate.api.access';
  static const _refreshKey = 'nutrimate.api.refresh';

  final http.Client _client;
  final String _baseUrl;
  SharedPreferences? _preferences;
  String? _accessToken;
  String? _refreshToken;

  static String _defaultApiBaseUrl() {
    const configured = String.fromEnvironment('NUTRIMATE_API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000/api/v1/'
        : 'http://127.0.0.1:8000/api/v1/';
  }

  static String _normalizeBaseUrl(String value) =>
      value.endsWith('/') ? value : '$value/';

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    _accessToken = _preferences!.getString(_accessKey);
    _refreshToken = _preferences!.getString(_refreshKey);
  }

  Future<LocalAccount?> restoreSession() async {
    if (_accessToken == null) return null;
    try {
      return await currentUser();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await logout();
        return null;
      }
      rethrow;
    }
  }

  Future<LocalAccount> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _request(
      'POST',
      'auth/register/',
      body: {'name': name.trim(), 'email': email.trim(), 'password': password},
      authenticated: false,
    );
    return login(email, password);
  }

  Future<LocalAccount> login(String email, String password) async {
    final result = await _request(
      'POST',
      'auth/token/',
      body: {'email': email.trim(), 'password': password},
      authenticated: false,
    );
    _accessToken = result['access'] as String?;
    _refreshToken = result['refresh'] as String?;
    if (_accessToken == null || _refreshToken == null) {
      throw const ApiException(
        'The server returned an invalid login response.',
      );
    }
    await _preferences!.setString(_accessKey, _accessToken!);
    await _preferences!.setString(_refreshKey, _refreshToken!);
    return currentUser();
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    await _preferences?.remove(_accessKey);
    await _preferences?.remove(_refreshKey);
  }

  Future<LocalAccount> currentUser() async =>
      LocalAccount.fromJson(await _request('GET', 'auth/me/'));

  Future<Map<String, dynamic>> adminDashboard() =>
      _request('GET', 'admin/dashboard/');

  Future<List<LocalAccount>> adminUsers({String search = ''}) async {
    final query = search.trim().isEmpty
        ? ''
        : '?search=${Uri.encodeQueryComponent(search.trim())}';
    final rows = await _requestList('admin/users/$query');
    return rows.map(LocalAccount.fromJson).toList();
  }

  Future<LocalAccount> setAccountActive(
    LocalAccount account, {
    required bool active,
  }) async => LocalAccount.fromJson(
    await _request(
      'PATCH',
      'admin/users/${account.id}/',
      body: {'is_active': active},
    ),
  );

  Future<LocalAccount> createAdminUser({
    required String name,
    required String email,
    required String password,
  }) async => LocalAccount.fromJson(
    await _request(
      'POST',
      'admin/users/create/',
      body: {'name': name, 'email': email, 'password': password},
    ),
  );

  Future<List<Map<String, dynamic>>> categories() =>
      _requestList('categories/');

  Future<Map<String, dynamic>> createCategory(String name) =>
      _request('POST', 'categories/', body: {'name': name});

  Future<void> deleteCategory(int id) async {
    await _request('DELETE', 'categories/$id/');
  }

  Future<Map<String, dynamic>> updateCategory(int id, {required bool active}) =>
      _request('PATCH', 'categories/$id/', body: {'is_active': active});

  Future<List<Map<String, dynamic>>> foods({
    String search = '',
    int? categoryId,
  }) async {
    final parameters = <String, String>{};
    if (search.trim().isNotEmpty) parameters['search'] = search.trim();
    if (categoryId != null) parameters['category'] = '$categoryId';
    final suffix = parameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: parameters).query}';
    return _requestList('foods/$suffix');
  }

  Future<Map<String, dynamic>> saveFood(Map<String, dynamic> food, {int? id}) =>
      _request(
        id == null ? 'POST' : 'PATCH',
        id == null ? 'foods/' : 'foods/$id/',
        body: food,
      );

  Future<void> deleteFood(int id) async {
    await _request('DELETE', 'foods/$id/');
  }

  Future<List<MealRecord>> meals() async =>
      (await _requestList('meals/')).map(MealRecord.fromJson).toList();

  Future<MealRecord> createMeal(MealRecord meal) async => MealRecord.fromJson(
    await _request('POST', 'meals/', body: _mealPayload(meal)),
  );

  Future<MealRecord> updateMeal(String id, MealRecord meal) async =>
      MealRecord.fromJson(
        await _request('PATCH', 'meals/$id/', body: _mealPayload(meal)),
      );

  Future<void> deleteMeal(MealRecord meal) async {
    await _request('DELETE', 'meals/${meal.id}/');
  }

  Map<String, dynamic> _mealPayload(MealRecord meal) => {
    if (meal.foodId != null) 'food': meal.foodId,
    if (meal.foodId != null) 'servings': meal.servings,
    'name': meal.name,
    'category': meal.category,
    'calories': meal.calories,
    'protein': meal.protein,
    'carbs': meal.carbs,
    'fat': meal.fat,
    'notes': meal.notes,
    'created_at': meal.createdAt.toIso8601String(),
  };

  Future<int> todayWater() async {
    final result = await _request('GET', 'water/today/');
    return result['amount_ml'] as int? ?? 0;
  }

  Future<int> setTodayWater(int amountMl) async {
    final result = await _request(
      'PUT',
      'water/today/',
      body: {'amount_ml': amountMl},
    );
    return result['amount_ml'] as int;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    bool retryUnauthorized = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (authenticated && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    late http.Response response;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(headers)
        ..body = body == null ? '' : jsonEncode(body);
      response = await http.Response.fromStream(await _client.send(request));
    } on http.ClientException catch (error) {
      throw ApiException('Cannot connect to NutriMate API: ${error.message}');
    } on FormatException {
      throw const ApiException('The API address is invalid.');
    }

    if (response.statusCode == 401 &&
        authenticated &&
        retryUnauthorized &&
        await _refreshAccessToken()) {
      return _request(
        method,
        path,
        body: body,
        authenticated: authenticated,
        retryUnauthorized: false,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
    if (response.bodyBytes.isEmpty) return {};
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('The API returned an unexpected response.');
  }

  Future<List<Map<String, dynamic>>> _requestList(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{'Accept': 'application/json'};
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    late http.Response response;
    try {
      response = await _client.get(uri, headers: headers);
    } on http.ClientException catch (error) {
      throw ApiException('Cannot connect to NutriMate API: ${error.message}');
    }
    if (response.statusCode == 401 && await _refreshAccessToken()) {
      return _requestList(path);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List<dynamic>) {
      throw const ApiException('The API returned an unexpected list response.');
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) return false;
    late Map<String, dynamic> response;
    try {
      response = await _request(
        'POST',
        'auth/token/refresh/',
        body: {'refresh': refreshToken},
        authenticated: false,
        retryUnauthorized: false,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await logout();
        return false;
      }
      rethrow;
    }
    final access = response['access'] as String?;
    if (access == null) {
      await logout();
      return false;
    }
    _accessToken = access;
    await _preferences!.setString(_accessKey, access);
    return true;
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String) return detail;
        final messages = decoded.values
            .expand((value) => value is List ? value : [value])
            .whereType<String>()
            .toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }
    } on FormatException {
      // Use the status-based message below for non-JSON error responses.
    }
    return 'The API request failed (${response.statusCode}).';
  }
}
