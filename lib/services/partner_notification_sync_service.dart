import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';

class PartnerNotificationSyncService {
  static Timer? _timer;

  static void startSync(WidgetRef ref) {
    _timer?.cancel();
    ref.read(notificationProvider.notifier).fetchNotifications();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  static void stopSync() {
    _timer?.cancel();
    _timer = null;
  }
}
