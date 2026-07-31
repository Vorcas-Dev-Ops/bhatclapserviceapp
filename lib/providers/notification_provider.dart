import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
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
  final Set<String> _shownNotificationIds = <String>{};

  NotificationNotifier({required ApiClient apiClient, required Ref ref})
      : _apiClient = apiClient,
        _ref = ref,
        super(NotificationState.initial());

  Future<void> fetchNotifications() async {
    try {
      final response = await _apiClient.dio.get('/api/notifications');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? [];

        // Check for new unread notifications and pop OS push banners
        for (var item in data) {
          final id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
          final isRead = item['is_read'] == true;
          final title = item['title'] ?? 'Notification';
          final message = item['message'] ?? item['body'] ?? '';
          final type = (item['type'] ?? '').toString().toLowerCase();

          if (!isRead && id.isNotEmpty && !_shownNotificationIds.contains(id) && !type.contains('otp')) {
            _shownNotificationIds.add(id);
            int notifId = id.hashCode.abs() % 100000;
            Map<String, dynamic> payloadMap = {};
            if (item['metadata'] != null && item['metadata'] is Map) {
              payloadMap = Map<String, dynamic>.from(item['metadata']);
            }
            if (!payloadMap.containsKey('booking_id') && item['booking_id'] != null) {
              payloadMap['booking_id'] = item['booking_id'];
            }
            payloadMap['type'] = type;

            NotificationService.showNotification(
              id: notifId,
              title: title,
              body: message,
              payload: jsonEncode(payloadMap),
            );
          }
        }

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
