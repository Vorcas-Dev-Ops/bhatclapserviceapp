import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';

class PartnerNotificationsScreen extends ConsumerStatefulWidget {
  const PartnerNotificationsScreen({super.key});

  @override
  ConsumerState<PartnerNotificationsScreen> createState() => _PartnerNotificationsScreenState();
}

class _PartnerNotificationsScreenState extends ConsumerState<PartnerNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1C1F3E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1F3E),
          ),
        ),
      ),
      body: notificationState.status == NotificationStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : notificationState.errorMessage != null
              ? Center(child: Text(notificationState.errorMessage!))
              : notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          final isRead = item['is_read'] ?? false;
                          final title = item['title'] ?? 'Notification';
                          final message = item['message'] ?? '';

                          return ListTile(
                            tileColor: isRead ? Colors.white : const Color(0xFFEFF1FE),
                            leading: CircleAvatar(
                              backgroundColor: isRead ? Colors.grey.shade200 : const Color(0xFF16155D),
                              child: Icon(
                                isRead ? Icons.notifications_outlined : Icons.notifications_active,
                                color: isRead ? Colors.grey : Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                color: const Color(0xFF1C1F3E),
                              ),
                            ),
                            subtitle: Text(message, style: const TextStyle(color: Colors.black87)),
                            onTap: () {
                              if (!isRead && item['_id'] != null) {
                                ref.read(notificationProvider.notifier).markAsRead(item['_id']);
                              }
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
