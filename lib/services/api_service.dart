import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/dashboard_models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl =
      'https://critter-liver-bodacious.ngrok-free.dev';

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// POST /api/auth/login
  /// Returns { token, role, user }
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    print("||||||||||||||||||||||||||||||||||||||||||||||");
    print(response.body);
    print("||||||||||||||||||||||||||||||||||||||||||||||");

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw ApiException(
        body['message'] as String,
        statusCode: response.statusCode,
      );
    }
    return body['data'] as Map<String, dynamic>;
  }

  // ── Admin — Users ─────────────────────────────────────────────────────────

  /// GET /api/admin/users
  static Future<List<UserModel>> getUsers(String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/admin/users'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parse(response);
    return (body['data'] as List)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/admin/users
  static Future<UserModel> createUser({
    required String token,
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/admin/users'),
          headers: _authJsonHeaders(token),
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'role': role,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parse(response);
    return UserModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// PUT /api/admin/users/:id/reset-password
  static Future<void> resetPassword({
    required String token,
    required String userId,
    required String newPassword,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/admin/users/$userId/reset-password'),
          headers: _authJsonHeaders(token),
          body: jsonEncode({'newPassword': newPassword}),
        )
        .timeout(const Duration(seconds: 15));

    _parse(response);
  }

  /// PUT /api/admin/users/:id/disable  (toggles)
  static Future<UserModel> toggleDisableUser({
    required String token,
    required String userId,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/admin/users/$userId/disable'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parse(response);
    return UserModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// DELETE /api/admin/users/:id
  static Future<void> deleteUser({
    required String token,
    required String userId,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/api/admin/users/$userId'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    _parse(response);
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  /// GET /api/dashboard/revenue
  static Future<RevenueData> getRevenue(String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/dashboard/revenue'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parse(response);
    return RevenueData.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// GET /api/dashboard/sales-summary
  static Future<SalesSummary> getSalesSummary(String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/dashboard/sales-summary'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parse(response);
    return SalesSummary.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// GET /api/dashboard/countries
  static Future<List<CountrySales>> getCountries(String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/dashboard/countries'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parse(response);
    return (body['data'] as List)
        .map((e) => CountrySales.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/dashboard/states/:country
  static Future<List<StateSales>> getStates({
    required String token,
    required String country,
  }) async {
    final encodedCountry = Uri.encodeComponent(country);
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/dashboard/states/$encodedCountry'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parse(response);
    return (body['data'] as List)
        .map((e) => StateSales.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/dashboard/cities/:state?page=&limit=
  static Future<CitiesPage> getCities({
    required String token,
    required String state,
    int page = 1,
    int limit = 20,
  }) async {
    final encodedState = Uri.encodeComponent(state);
    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/api/dashboard/cities/$encodedState?page=$page&limit=$limit',
          ),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parse(response);
    return CitiesPage.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// GET /api/dashboard/hourly-growth
  static Future<List<HourlyGrowth>> getHourlyGrowth(String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/dashboard/hourly-growth'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parse(response);
    return (body['data'] as List)
        .map((e) => HourlyGrowth.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
  };

  static Map<String, String> _authJsonHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  /// Parses response, throws [ApiException] on non-success.
  static Map<String, dynamic> _parse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw ApiException(
        body['message'] as String,
        statusCode: response.statusCode,
      );
    }
    return body;
  }
}
