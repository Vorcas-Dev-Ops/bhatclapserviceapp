import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import 'api_providers.dart';
import 'auth_provider.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState {
  final ProfileStatus status;
  final Map<String, dynamic>? profileData;
  final String? errorMessage;

  ProfileState({
    required this.status,
    this.profileData,
    this.errorMessage,
  });

  factory ProfileState.initial() => ProfileState(status: ProfileStatus.initial);

  ProfileState copyWith({
    ProfileStatus? status,
    Map<String, dynamic>? profileData,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profileData: profileData ?? this.profileData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ProviderProfileNotifier extends StateNotifier<ProfileState> {
  final ApiClient _apiClient;
  final Ref _ref;

  ProviderProfileNotifier({required ApiClient apiClient, required Ref ref})
      : _apiClient = apiClient,
        _ref = ref,
        super(ProfileState.initial());

  Future<void> fetchProfile() async {
    print('=== ProviderProfileNotifier: fetchProfile started ===');
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      print('=== ProviderProfileNotifier: requesting /api/providers/me ===');
      final response = await _apiClient.dio.get('/api/providers/me');
      print('=== ProviderProfileNotifier: /api/providers/me status code: ${response.statusCode} ===');
      if (response.statusCode == 200) {
        state = ProfileState(
          status: ProfileStatus.loaded,
          profileData: response.data,
        );
        print('=== ProviderProfileNotifier: loaded profile successfully ===');
      }
    } on DioException catch (e) {
      print('=== ProviderProfileNotifier: fetchProfile threw DioException: $e ===');
      state = ProfileState(
        status: ProfileStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Failed to load profile',
      );
    }
  }

  Future<bool> updateProfile({
    String? availabilityStatus,
    String? aadharId,
    Map<String, dynamic>? bankDetails,
    Map<String, dynamic>? verificationDocs,
    List<String>? serviceLocations,
  }) async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final data = <String, dynamic>{};
      if (availabilityStatus != null) data['availability_status'] = availabilityStatus;
      if (aadharId != null) data['aadhar_id'] = aadharId;
      if (bankDetails != null) data['bank_details'] = bankDetails;
      if (verificationDocs != null) data['verification_docs'] = verificationDocs;
      if (serviceLocations != null) data['service_locations'] = serviceLocations;

      final response = await _apiClient.dio.put('/api/providers/me', data: data);
      if (response.statusCode == 200) {
        state = ProfileState(
          status: ProfileStatus.loaded,
          profileData: response.data,
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      print('=== ProviderProfileNotifier: updateProfile DioException: $e ===');
      print('=== Response status code: ${e.response?.statusCode} ===');
      print('=== Response data: ${e.response?.data} ===');
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Failed to update profile',
      );
      return false;
    }
  }

  Future<bool> updateBankDetails({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    String? upiId,
  }) async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final response = await _apiClient.dio.post(
        '/api/providers/bank-details',
        data: {
          'accountHolderName': accountHolderName,
          'accountNumber': accountNumber,
          'ifscCode': ifscCode,
          'bankName': bankName,
          if (upiId != null && upiId.isNotEmpty) 'upiId': upiId,
          if (upiId != null && upiId.isNotEmpty) 'vpa': upiId,
        },
      );
      if (response.statusCode == 200) {
        await fetchProfile();
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Failed to update bank details',
      );
      return false;
    }
  }


  Future<bool> addService({
    required List<String> subserviceIds,
    required double price,
    required double experience,
  }) async {
    final providerId = state.profileData?['_id'];
    if (providerId == null) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Provider profile not loaded yet.',
      );
      return false;
    }

    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final response = await _apiClient.dio.post(
        '/api/provider-services',
        data: {
          'provider_id': providerId,
          'subservice_ids': subserviceIds,
          'price': price,
          'experience': experience,
        },
      );
      if (response.statusCode == 201) {
        await fetchProfile();
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Failed to register services',
      );
      return false;
    }
  }
}

final providerProfileProvider =
    StateNotifierProvider<ProviderProfileNotifier, ProfileState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProviderProfileNotifier(apiClient: apiClient, ref: ref);
});
