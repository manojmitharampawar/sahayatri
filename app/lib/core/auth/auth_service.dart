import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahayatri/core/api/api_client.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _apiClient;

  bool _isAuthenticated = false;
  String? _email;
  int? _userId;

  bool get isAuthenticated => _isAuthenticated;
  String? get email => _email;
  int? get userId => _userId;

  AuthService(this._apiClient) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    _isAuthenticated = token != null;
    _email = prefs.getString('user_email');
    notifyListeners();
  }

  Future<bool> register(String email, String phone, String password) async {
    try {
      final response = await _apiClient.register(email, phone, password);
      if (response.statusCode == 201) {
        await _saveTokens(response.data);
        _isAuthenticated = true;
        _email = email;
        _userId = response.data['user']['id'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Registration failed: $e');
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiClient.login(email, password);
      if (response.statusCode == 200) {
        await _saveTokens(response.data);
        _isAuthenticated = true;
        _email = email;
        _userId = response.data['user']['id'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login failed: $e');
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_email');
    _isAuthenticated = false;
    _email = null;
    _userId = null;
    notifyListeners();
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token']);
    await prefs.setString('refresh_token', data['refresh_token']);
    if (data['user'] != null && data['user']['email'] != null) {
      await prefs.setString('user_email', data['user']['email']);
    }
  }
}
