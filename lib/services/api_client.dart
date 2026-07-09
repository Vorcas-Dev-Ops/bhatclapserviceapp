import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiClient {
  late final Dio dio;
  final TokenStorage _tokenStorage = TokenStorage();
  
  // Base URL configured for Android Emulator pointing to local API Gateway
  static const String baseUrl = 'http://10.0.2.2:5000';

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          // Check if there is a set-cookie header containing a rotated jwt token
          final newRefreshToken = _extractRefreshTokenFromResponse(response);
          if (newRefreshToken != null) {
            final currentAccessToken = await _tokenStorage.getAccessToken() ?? '';
            final userId = await _tokenStorage.getUserId() ?? '';
            final userRole = await _tokenStorage.getUserRole() ?? '';
            
            // Save rotated refresh token
            await _tokenStorage.saveTokens(
              accessToken: currentAccessToken,
              refreshToken: newRefreshToken,
              userId: userId,
              userRole: userRole,
            );
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // If we receive a 401 Unauthorized, try to refresh the token
          if (e.response?.statusCode == 401 && 
              e.requestOptions.path != '/api/users/refresh' && 
              e.requestOptions.path != '/api/users/login' &&
              e.requestOptions.path != '/api/users/verify-otp') {
            
            final refreshToken = await _tokenStorage.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Try to refresh token using refresh endpoint with cookie header
                final refreshResponse = await Dio(BaseOptions(baseUrl: baseUrl)).post(
                  '/api/users/refresh',
                  options: Options(
                    headers: {
                      'Cookie': 'jwt=$refreshToken',
                    },
                  ),
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['token'];
                  final rotatedRefreshToken = _extractRefreshTokenFromResponse(refreshResponse) ?? refreshToken;
                  final userId = await _tokenStorage.getUserId() ?? '';
                  final userRole = await _tokenStorage.getUserRole() ?? '';
                  
                  // Save updated credentials
                  await _tokenStorage.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: rotatedRefreshToken,
                    userId: userId,
                    userRole: userRole,
                  );

                  // Retry original request with the new access token
                  final cloneReq = e.requestOptions;
                  cloneReq.headers['Authorization'] = 'Bearer $newAccessToken';
                  
                  final response = await dio.request(
                    cloneReq.path,
                    data: cloneReq.data,
                    queryParameters: cloneReq.queryParameters,
                    options: Options(
                      method: cloneReq.method,
                      headers: cloneReq.headers,
                    ),
                  );
                  return handler.resolve(response);
                }
              } catch (refreshErr) {
                // Refresh failed: token expired or deleted on backend. Log out user.
                await _tokenStorage.clear();
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  String? _extractRefreshTokenFromResponse(Response response) {
    final cookies = response.headers['set-cookie'];
    if (cookies != null && cookies.isNotEmpty) {
      for (var cookie in cookies) {
        if (cookie.startsWith('jwt=')) {
          final parts = cookie.split(';');
          if (parts.isNotEmpty) {
            return parts[0].substring(4); // Remove 'jwt=' prefix
          }
        }
      }
    }
    return null;
  }
}
