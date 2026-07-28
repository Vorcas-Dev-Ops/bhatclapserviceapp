import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import 'api_providers.dart';
import 'auth_provider.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationState {
  final NotificationStatus status;
  final List<dynamic> notifications;
  final String? errorMessage;

  NotificationState({
    required this.status,
    this.notifications = const [],
    this.errorMessage,
  });

  factory NotificationState.initial() => NotificationState(status: NotificationStatus.initial);

  NotificationState copyWith({
    NotificationStatus? status,
    List<dynamic>? notifications,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  int get unreadCount => notifications.where((n) => n['is_read'] != true).length;
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _apiClient;
  final Ref _ref;

  NotificationNotifier({required ApiClient apiClient, required Ref ref})
      : _apiClient = apiClient,
        _ref = ref,
        super(NotificationState.initial());

  Future<void> fetchNotifications() async {
    state = state.copyWith(status: NotificationStatus.loading);
    try {
      final response = await _apiClient.dio.get('/api/notifications');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? [];
        state = NotificationState(
          status: NotificationStatus.loaded,
          notifications: data,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _ref.read(authProvider.notifier).logout();
      }
      state = state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Failed to load notifications',
      );
    } catch (e) {
      state = state.copyWith(
        status: NotificationStatus.error,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _apiClient.dio.put('/api/notifications/$id/read');
      await fetchNotifications();
    } catch (_) {}
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationNotifier(apiClient: apiClient, ref: ref);
});
