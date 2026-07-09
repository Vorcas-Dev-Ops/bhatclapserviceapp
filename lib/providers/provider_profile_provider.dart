import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import 'api_providers.dart';

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

  ProviderProfileNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(ProfileState.initial());

  Future<void> fetchProfile() async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final response = await _apiClient.dio.get('/api/providers/me');
      if (response.statusCode == 200) {
        state = ProfileState(
          status: ProfileStatus.loaded,
          profileData: response.data,
        );
      }
    } on DioException catch (e) {
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
  }) async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final data = <String, dynamic>{};
      if (availabilityStatus != null) data['availability_status'] = availabilityStatus;
      if (aadharId != null) data['aadhar_id'] = aadharId;
      if (bankDetails != null) data['bank_details'] = bankDetails;
      if (verificationDocs != null) data['verification_docs'] = verificationDocs;

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
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Failed to update profile',
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
  return ProviderProfileNotifier(apiClient: apiClient);
});
