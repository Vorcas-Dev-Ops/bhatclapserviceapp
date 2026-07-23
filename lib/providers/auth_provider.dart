import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';
import 'api_providers.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  pendingRegistration,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? pendingPhone;
  final String? pendingEmail;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.pendingPhone,
    this.pendingEmail,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    String? pendingPhone,
    String? pendingEmail,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      pendingEmail: pendingEmail ?? this.pendingEmail,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthNotifier({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        super(AuthState.initial()) {
    checkAuth();
  }

  // Check if user session already exists
  Future<void> checkAuth() async {
    print('=== AuthProvider: checkAuth started ===');
    state = state.copyWith(status: AuthStatus.loading);
    final token = await _tokenStorage.getAccessToken();
    print('=== AuthProvider: getAccessToken returned: $token ===');
    if (token == null || token.isEmpty) {
      print('=== AuthProvider: token is null or empty, setting unauthenticated ===');
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      print('=== AuthProvider: requesting /api/users/me ===');
      final response = await _apiClient.dio.get('/api/users/me');
      print('=== AuthProvider: /api/users/me status code: ${response.statusCode} ===');
      if (response.statusCode == 200) {
        final userData = response.data['user'] ?? response.data;
        final userModel = UserModel.fromJson(userData);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: userModel,
        );
        print('=== AuthProvider: authenticated user ${userModel.name} ===');
      } else {
        print('=== AuthProvider: status code not 200, setting unauthenticated ===');
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      print('=== AuthProvider: checkAuth threw exception: $e ===');
      // If endpoint check fails, token might be invalid or expired (and refresh failed)
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  String _normalizePhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    if (clean.startsWith('+')) {
      return clean;
    }
    if (clean.length == 10) {
      return '+91$clean';
    }
    return clean;
  }

  // Step 1: Send OTP to Phone
  Future<bool> sendOtp(String phone) async {
    final normalized = _normalizePhone(phone);
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _apiClient.dio.post(
        '/api/users/send-otp',
        data: {
          'identifier': normalized,
          'role': 'provider',
          'useEmail': false,
          'mode': 'login',
        },
      );
      if (response.statusCode == 200) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          pendingPhone: normalized,
        );
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: response.data['message'] ?? 'Failed to send OTP',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Network error occurred',
      );
      return false;
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle(String googleToken) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _apiClient.dio.post(
        '/api/users/google-login',
        data: {
          'token': googleToken,
          'role': 'provider', // Backend requires this for partner app login if modified, else it ignores it
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['user'] != null) {
          final userJson = data['user'];
          final token = userJson['token'];
          final userId = userJson['_id'];
          final role = userJson['role'] ?? 'provider';

          final refreshToken = await _tokenStorage.getRefreshToken() ?? '';

          await _tokenStorage.saveTokens(
            accessToken: token,
            refreshToken: refreshToken,
            userId: userId,
            userRole: role,
          );

          final userModel = UserModel.fromJson(userJson);
          state = AuthState(
            status: AuthStatus.authenticated,
            user: userModel,
          );
          return true;
        }
      }
      
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: response.data['message'] ?? 'Invalid response from server',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Network error occurred',
      );
      return false;
    }
  }

  // Step 2: Verify OTP code
  Future<bool> verifyOtp(String otp) async {
    final phone = state.pendingPhone;
    if (phone == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Missing phone identifier. Restart login flow.',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _apiClient.dio.post(
        '/api/users/verify-otp',
        data: {
          'identifier': phone,
          'otp': otp,
          'useEmail': false,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['user'] != null && data['user']['_id'] != 'pending_verification') {
          // User exists, save tokens
          final userJson = data['user'];
          final token = userJson['token'];
          final userId = userJson['_id'];
          final role = userJson['role'] ?? 'provider';

          // Extract refresh token from Set-Cookie header parsed in Interceptor
          final refreshToken = await _tokenStorage.getRefreshToken() ?? '';

          await _tokenStorage.saveTokens(
            accessToken: token,
            refreshToken: refreshToken,
            userId: userId,
            userRole: role,
          );

          final userModel = UserModel.fromJson(userJson);
          state = AuthState(
            status: AuthStatus.authenticated,
            user: userModel,
          );
          return true;
        } else {
          // New User, needs to fill registration details
          state = state.copyWith(
            status: AuthStatus.pendingRegistration,
            pendingPhone: phone,
          );
          return true;
        }
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: response.data['message'] ?? 'OTP verification failed',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Network error during verification',
      );
      return false;
    }
  }

  // Step 3: Register new user
  Future<bool> registerUser({
    required String name,
    required String email,
    required String gender,
  }) async {
    final phone = state.pendingPhone;
    if (phone == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Missing registration state context',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _apiClient.dio.post(
        '/api/users/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'role': 'provider',
          'gender': gender,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;
        final token = data['token'];
        final userId = data['_id'];
        final role = data['role'] ?? 'provider';
        
        final refreshToken = await _tokenStorage.getRefreshToken() ?? '';

        await _tokenStorage.saveTokens(
          accessToken: token,
          refreshToken: refreshToken,
          userId: userId,
          userRole: role,
        );

        final userModel = UserModel.fromJson(data);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: userModel,
        );
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: response.data['message'] ?? 'Registration failed',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Error during registration',
      );
      return false;
    }
  }

  // Update user profile image (Selfie)
  Future<bool> updateProfileImage(String base64Image) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/users/me',
        data: {
          'profile_image': base64Image,
        },
      );
      if (response.statusCode == 200) {
        final userData = response.data['user'] ?? response.data;
        final userModel = UserModel.fromJson(userData);
        state = state.copyWith(user: userModel);
        return true;
      }
      return false;
    } on DioException catch (e) {
      print('=== AuthNotifier: updateProfileImage exception: status=${e.response?.statusCode}, data=${e.response?.data}, error=${e.message} ===');
      state = state.copyWith(
        errorMessage: e.response?.data['message'] ?? 'Failed to upload selfie profile picture',
      );
      return false;
    }
  }

  // Sign out user
  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/api/users/logout');
    } catch (_) {
      // Ignore network errors on logout, proceed with local data clear
    }
    await _tokenStorage.clear();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(apiClient: apiClient, tokenStorage: tokenStorage);
});
