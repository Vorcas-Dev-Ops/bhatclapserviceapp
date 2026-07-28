import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import 'api_providers.dart';
import 'auth_provider.dart';

enum AnalyticsStatus { initial, loading, loaded, error }

class AnalyticsState {
  final AnalyticsStatus status;
  final Map<String, dynamic>? analyticsData;
  final String? errorMessage;

  AnalyticsState({
    required this.status,
    this.analyticsData,
    this.errorMessage,
  });

  factory AnalyticsState.initial() => AnalyticsState(status: AnalyticsStatus.initial);

  AnalyticsState copyWith({
    AnalyticsStatus? status,
    Map<String, dynamic>? analyticsData,
    String? errorMessage,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      analyticsData: analyticsData ?? this.analyticsData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ProviderAnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final ApiClient _apiClient;
  final Ref _ref;

  ProviderAnalyticsNotifier({required ApiClient apiClient, required Ref ref})
      : _apiClient = apiClient,
        _ref = ref,
        super(AnalyticsState.initial());

  Future<void> fetchAnalytics() async {
    state = state.copyWith(status: AnalyticsStatus.loading);
    try {
      final response = await _apiClient.dio.get('/api/providers/dashboard-analytics');
      if (response.statusCode == 200) {
        state = AnalyticsState(
          status: AnalyticsStatus.loaded,
          analyticsData: response.data,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _ref.read(authProvider.notifier).logout();
      }
      state = AnalyticsState(
        status: AnalyticsStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Failed to load analytics',
      );
    } catch (e) {
      state = AnalyticsState(
        status: AnalyticsStatus.error,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }
}

final providerAnalyticsProvider = StateNotifierProvider<ProviderAnalyticsNotifier, AnalyticsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProviderAnalyticsNotifier(apiClient: apiClient, ref: ref);
});
