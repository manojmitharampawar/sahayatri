import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late final Dio _dio;

  static const String _baseUrl = 'http://localhost:8080/api/v1';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final retryResponse = await _retry(error.requestOptions);
            return handler.resolve(retryResponse);
          }
        }
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '$_baseUrl/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        await prefs.setString(
            _accessTokenKey, response.data['access_token']);
        await prefs.setString(
            _refreshTokenKey, response.data['refresh_token']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // Auth endpoints
  Future<Response> register(String email, String phone, String password) {
    return _dio.post('/auth/register', data: {
      'email': email,
      'phone': phone,
      'password': password,
    });
  }

  Future<Response> login(String email, String password) {
    return _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  // Station endpoints
  Future<Response> getStations() => _dio.get('/stations');
  Future<Response> searchStations(String query) =>
      _dio.get('/stations/search', queryParameters: {'q': query});

  // Train endpoints
  Future<Response> getTrainStatus(String trainNumber) =>
      _dio.get('/trains/$trainNumber/status');

  // PNR endpoints
  Future<Response> getPNRStatus(String pnr) =>
      _dio.get('/pnr/$pnr/status');

  // Yatra endpoints
  Future<Response> createYatraCard(Map<String, dynamic> data) =>
      _dio.post('/yatra', data: data);
  Future<Response> getYatraCards() => _dio.get('/yatra');
  Future<Response> getYatraCard(int id) => _dio.get('/yatra/$id');
  Future<Response> updateLocation(int yatraId, double lat, double lon) =>
      _dio.put('/yatra/$yatraId/location', data: {'lat': lat, 'lon': lon});

  // Family endpoints
  Future<Response> createFamilyGroup(String name) =>
      _dio.post('/family', data: {'name': name});
  Future<Response> getFamilyGroups() => _dio.get('/family');
  Future<Response> getFamilyGroup(int id) => _dio.get('/family/$id');
  Future<Response> addFamilyMember(int groupId, int userId, String role) =>
      _dio.post('/family/$groupId/members',
          data: {'user_id': userId, 'role': role});
  Future<Response> removeFamilyMember(int groupId, int userId) =>
      _dio.delete('/family/$groupId/members/$userId');

  // Shapefile endpoints
  Future<Response> getTrackShapefiles() => _dio.get('/shapefiles/tracks');
}
