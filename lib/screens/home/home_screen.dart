import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/job_dispatch_provider.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/providers/auth_provider.dart';
import 'package:partner_app/providers/wallet_provider.dart';
import 'package:partner_app/providers/jobs_provider.dart';
import 'package:partner_app/providers/provider_analytics_provider.dart';
import 'package:partner_app/providers/notification_provider.dart';
import 'package:partner_app/screens/notifications/notifications_screen.dart';
import 'package:partner_app/screens/jobs/jobs_screen.dart';
import 'package:partner_app/screens/jobs/job_details_screen.dart';
import 'package:partner_app/screens/chat/partner_chat_screen.dart';
import 'package:partner_app/screens/finance/money_screen.dart';
import 'package:partner_app/screens/profile/profile_screen.dart';
import 'package:partner_app/screens/profile/subscription_screen.dart';
import 'package:partner_app/screens/leads/lead_marketplace_screen.dart';
import 'package:partner_app/screens/shop/starter_kit_screen.dart';
import 'package:partner_app/screens/profile/referral_screen.dart';
import 'package:partner_app/services/notification_service.dart';
import 'package:partner_app/services/partner_notification_sync_service.dart';
import 'package:partner_app/utils/address_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  StreamSubscription<String>? _notificationSub;

  @override
  void initState() {
    super.initState();
    _notificationSub = NotificationService.selectNotificationStream.stream.listen((payload) {
      _handleNotificationClick(payload);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(providerProfileProvider.notifier).fetchProfile();
      ref.read(walletProvider.notifier).fetchWalletAndReviews();
      ref.read(jobsProvider.notifier).fetchAllJobs();
      ref.read(providerAnalyticsProvider.notifier).fetchAnalytics();
      PartnerNotificationSyncService.startSync(ref);
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    PartnerNotificationSyncService.stopSync();
    super.dispose();
  }

  void _handleNotificationClick(String payload) {
    try {
      Map<String, dynamic> data = {};
      if (payload.startsWith('{')) {
        data = jsonDecode(payload);
      }
      final type = data['type']?.toString();
      final bookingId = data['booking_id'] ?? data['bookingId'] ?? data['booking'] ?? data['request_id'];
      if (type == 'chat' && bookingId != null && bookingId.toString().isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PartnerChatScreen(bookingId: bookingId.toString()),
          ),
        );
        return;
      }
      if (bookingId != null && bookingId.toString().isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailsScreen(bookingId: bookingId.toString()),
          ),
        );
      } else if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PartnerNotificationsScreen()),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PartnerNotificationsScreen()),
        );
      }
    }
  }

  void _navigateToDetails(dynamic booking, {bool isNewJob = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailsScreen(booking: booking, isNewJob: isNewJob),
      ),
    );
  }

  Widget _buildRedLeadCountBadge(BuildContext context, int leadCount) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF3B30), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flash_on,
              color: Color(0xFFE53935),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '$leadCount Leads',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE53935),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final profileState = ref.watch(providerProfileProvider);
    final profile = profileState.profileData;
    final walletState = ref.watch(walletProvider);
    final leadCount = walletState.leadBalance;
    
    int creditsVal = 0;
    if (profile != null) {
      final walletBalance = profile['walletBalance'] ?? 0.0;
      final reservedBalance = profile['reservedBalance'] ?? 0.0;
      final creditLimit = profile['creditLimit'] ?? 500.0;
      final availableCredit = (walletBalance as num).toDouble() - (reservedBalance as num).toDouble() + (creditLimit as num).toDouble();
      creditsVal = (availableCredit / 10).toInt();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Credits & Lead Count pills
              Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LeadMarketplaceScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.hexagon,
                            color: Color(0xFF2D3047),
                            size: 20,
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$creditsVal',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3047),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildRedLeadCountBadge(context, leadCount),
            ],
          ),

          // Actions
          Row(
            children: [
              // Notification Bell
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PartnerNotificationsScreen()),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF1FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_outlined,
                        color: Color(0xFF16155D),
                        size: 22,
                      ),
                    ),
                    if (ref.watch(notificationProvider).unreadCount > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
  }

  void _showIncomingJobBottomSheet(BuildContext context, JobRequestModel job) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NEW JOB REQUEST',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Expires in 10m',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  job.serviceName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1F3E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatAddress(job.address, city: job.city),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PAYOUT',
                          style: TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${job.amount}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'SCHEDULED',
                          style: TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDateString(job.scheduledAt)} • ${job.bookingTime}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final targetId = job.requestId.isNotEmpty ? job.requestId : job.bookingId;
                            await ref.read(jobDispatchProvider.notifier).rejectJob(targetId);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final targetId = job.requestId.isNotEmpty ? job.requestId : job.bookingId;
                            final success = await ref.read(jobDispatchProvider.notifier).acceptJob(targetId);
                            if (mounted) {
                              if (!context.mounted) return;
                              if (success) {
                                showTopPillToast(context, 'Job accepted! Navigate to Jobs tab for instructions.');
                              } else {
                                final errorMsg = ref.read(jobDispatchProvider).error ?? 'Failed to accept job. Please try again.';
                                showTopPillToast(context, errorMsg, isError: true);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16155D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Accept Job',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildGreetingHeader() {
    final authState = ref.watch(authProvider);
    final dispatchState = ref.watch(jobDispatchProvider);
    final name = authState.user?.name ?? 'Partner';
    final greeting = _getGreeting();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $name',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1F3E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ready for today\'s bookings?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SquareOnlineSlider(
            isOnline: dispatchState.isOnline,
            onTap: () async {
              final success = await ref.read(jobDispatchProvider.notifier).toggleAvailability();
              if (mounted) {
                final dispatchState = ref.read(jobDispatchProvider);
                if (success) {
                  final isOnline = dispatchState.isOnline;
                  showTopPillToast(
                    context,
                    isOnline ? 'You are online!' : 'You are offline',
                    isError: false,
                    isOffline: !isOnline,
                  );
                } else {
                  final err = dispatchState.error;
                  showTopPillToast(
                    context,
                    err ?? 'Failed to update availability status.',
                    isError: true,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKitBanner() {
    final profileState = ref.watch(providerProfileProvider);
    final kitPurchased = profileState.profileData?['kitPurchased'] == true || profileState.profileData?['providerKitCompleted'] == true;
    final providerName = profileState.profileData?['user_id']?['name'] ?? 'Provider';

    if (kitPurchased) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StarterKitScreen(providerName: providerName),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF3B41C5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Your Onboarding',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Purchase your mandatory Provider Kit',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  bool _isTodayDate(dynamic dateVal) {
    if (dateVal == null) return false;
    final String dateStr = dateVal.toString();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (dateStr.toLowerCase().contains('today')) return true;
    if (dateStr.startsWith(todayStr)) return true;

    final dt = DateTime.tryParse(dateStr);
    if (dt != null) {
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    }
    return false;
  }

  bool _isThisMonthDate(dynamic dateVal) {
    if (dateVal == null) return false;
    final String dateStr = dateVal.toString();
    final now = DateTime.now();

    final dt = DateTime.tryParse(dateStr);
    if (dt != null) {
      return dt.year == now.year && dt.month == now.month;
    }
    return false;
  }

  Widget _buildStatCard(String title, String value, {bool showStar = false, VoidCallback? onTap}) {
    final cardContent = Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16155D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showStar) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
              ]
            ],
          ),
        ],
      ),
    );

    return Expanded(
      child: onTap != null
          ? GestureDetector(
              onTap: onTap,
              child: cardContent,
            )
          : cardContent,
    );
  }

  void _showDailyIncomeModal(BuildContext context, List<dynamic> todayBookings, double dailyIncome) {
    final completedStatuses = ['completed', 'finished'];

    final filteredTodayBookings = todayBookings.where((b) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      return completedStatuses.contains(status);
    }).toList();

    final onlineJobs = filteredTodayBookings.where((b) {
      final method = (b['payment_method'] ?? b['paymentMode'] ?? b['payment_type'] ?? '').toString().toLowerCase();
      return !method.contains('cod') && !method.contains('cash');
    }).toList();

    final codJobs = filteredTodayBookings.where((b) {
      final method = (b['payment_method'] ?? b['paymentMode'] ?? b['payment_type'] ?? '').toString().toLowerCase();
      return method.contains('cod') || method.contains('cash');
    }).toList();

    double completedDailyNetTotal = 0;
    for (final b in filteredTodayBookings) {
      completedDailyNetTotal += _calculateNetJobIncome(b);
    }
    final displayTotal = completedDailyNetTotal > 0 ? completedDailyNetTotal : dailyIncome;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Income Breakdown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16155D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Today\'s Net Income: ₹${displayTotal.toStringAsFixed(0)} (Platform Fee Deducted)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Container(
                  color: const Color(0xFFF5F6FA),
                  child: const TabBar(
                    labelColor: Color(0xFF16155D),
                    unselectedLabelColor: Colors.black45,
                    indicatorColor: Color(0xFF16155D),
                    indicatorWeight: 3,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: [
                      Tab(text: 'Online Payment'),
                      Tab(text: 'COD'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildDailyIncomeJobsList(onlineJobs, isCod: false),
                      _buildDailyIncomeJobsList(codJobs, isCod: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculateNetJobIncome(dynamic booking) {
    final grossAmt = (booking['payable_amount'] as num?)?.toDouble() ??
                     (booking['total_amount'] as num?)?.toDouble() ??
                     (booking['amount'] as num?)?.toDouble() ?? 0.0;

    double platformFee = (booking['platform_fee'] as num?)?.toDouble() ??
                         (booking['commission_fee'] as num?)?.toDouble() ??
                         (booking['commission'] as num?)?.toDouble() ?? 0.0;

    if (platformFee == 0.0 && grossAmt > 0) {
      platformFee = grossAmt * 0.10; // Default 10% platform fee
    }

    final netAmt = grossAmt - platformFee;
    return netAmt > 0 ? netAmt : 0.0;
  }

  Widget _buildDailyIncomeJobsList(List<dynamic> jobs, {required bool isCod}) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCod ? Icons.money_off_csred_outlined : Icons.credit_card_off_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isCod ? 'No completed Cash on Delivery (COD) jobs today' : 'No completed Online Payment jobs today',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = jobs[index];
        final subservice = job['subservice_id'] ?? {};
        final title = subservice['subservice_name'] ?? job['variant_name'] ?? 'Service';
        final bookingId = job['display_id'] ?? job['booking_id']?.toString() ?? job['_id']?.toString() ?? '';
        final grossAmt = (job['payable_amount'] as num?)?.toDouble() ?? (job['total_amount'] as num?)?.toDouble() ?? (job['amount'] as num?)?.toDouble() ?? 0.0;
        
        double platformFee = (job['platform_fee'] as num?)?.toDouble() ?? (job['commission_fee'] as num?)?.toDouble() ?? (job['commission'] as num?)?.toDouble() ?? 0.0;
        if (platformFee == 0.0 && grossAmt > 0) {
          platformFee = grossAmt * 0.10;
        }
        final netAmt = _calculateNetJobIncome(job);
        final status = (job['status'] ?? 'completed').toString();
        final time = job['booking_time'] ?? 'Today';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1F3E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bookingId.isNotEmpty ? "Ref: $bookingId • " : ""}$time',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCod ? Colors.orange.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCod ? 'Cash on Delivery (COD)' : 'Online Payment (Paid)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCod ? Colors.orange.shade800 : Colors.green.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fee: -₹${platformFee.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${netAmt.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16155D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gross: ₹${grossAmt.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    final analyticsState = ref.watch(providerAnalyticsProvider);
    final analytics = analyticsState.analyticsData;

    final jobsState = ref.watch(jobsProvider);
    final bookings = jobsState.bookings;

    final completedStatuses = ['completed', 'finished'];

    // 1. Calculate Today's Jobs (ONLY completed jobs today)
    final todayBookings = bookings.where((b) {
      final scheduledAt = b['scheduled_at'] ?? b['createdAt'] ?? b['date'];
      final status = (b['status'] ?? '').toString().toLowerCase();
      if (!completedStatuses.contains(status)) return false;
      return _isTodayDate(scheduledAt);
    }).toList();

    int todaysJobsCount = todayBookings.length;

    // 2. Calculate Daily Net Income (ONLY completed jobs today with platform fee deducted)
    double dailyIncome = 0;
    for (final b in todayBookings) {
      dailyIncome += _calculateNetJobIncome(b);
    }

    // 3. Calculate Monthly Net Income (ONLY completed jobs this month with platform fee deducted)
    double monthlyIncome = 0;
    for (final b in bookings) {
      final scheduledAt = b['scheduled_at'] ?? b['createdAt'] ?? b['date'];
      final status = (b['status'] ?? '').toString().toLowerCase();
      if (completedStatuses.contains(status) && _isThisMonthDate(scheduledAt)) {
        monthlyIncome += _calculateNetJobIncome(b);
      }
    }
    if (analytics?['monthRevenue'] != null) {
      final analyticsMonth = (analytics!['monthRevenue'] as num).toDouble();
      if (analyticsMonth > monthlyIncome) {
        monthlyIncome = analyticsMonth;
      }
    } else if (analytics?['totalRevenue'] != null) {
      final analyticsTotal = (analytics!['totalRevenue'] as num).toDouble();
      if (analyticsTotal > monthlyIncome) {
        monthlyIncome = analyticsTotal;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          _buildStatCard('Today\'s Jobs', '$todaysJobsCount'),
          const SizedBox(width: 8),
          _buildStatCard('Monthly Income', '₹${monthlyIncome.toStringAsFixed(0)}'),
          const SizedBox(width: 8),
          _buildStatCard(
            'Daily Income',
            '₹${dailyIncome.toStringAsFixed(0)}',
            onTap: () => _showDailyIncomeModal(context, todayBookings, dailyIncome),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard({
    required String status,
    required String time,
    required String title,
    required String location,
    required bool isOngoing,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left timeline track
        Column(
          children: [
            isOngoing
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16155D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 14,
                    ),
                  )
                : Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                  ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Card content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFF1FE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isOngoing ? const Color(0xFF16155D) : Colors.black38,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1F3E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSchedule() {
    final jobsState = ref.watch(jobsProvider);
    final upcomingAndOngoing = jobsState.bookings.where((b) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      return ['accepted', 'assigned', 'confirmed', 'started', 'waiting_start_otp', 'waiting_end_otp', 'in_progress'].contains(status);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1F3E),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 1; // Navigates to Jobs tab
                  });
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF16155D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcomingAndOngoing.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'No upcoming schedule bookings.',
                  style: TextStyle(color: Colors.black38, fontSize: 14),
                ),
              ),
            )
          else
            ...List.generate(
              upcomingAndOngoing.length > 2 ? 2 : upcomingAndOngoing.length,
              (index) {
                final booking = upcomingAndOngoing[index];
                final isOngoing = ['on_the_way', 'arrived', 'reached', 'started', 'waiting_start_otp', 'waiting_end_otp', 'in_progress', 'ongoing']
                    .contains((booking['status'] ?? '').toString().toLowerCase());
                final status = isOngoing ? 'ONGOING' : 'UPCOMING';
                final subservice = booking['subservice_id'] ?? {};
                final serviceName = subservice['subservice_name'] ?? booking['variant_name'] ?? 'Cleaning Service';
                final address = booking['address_id'] ?? {};
                final addressLine = address['address_line'] ?? 'Address';
                final city = address['city'] ?? 'City';
                final rawSchedDate = (booking['scheduled_at'] ?? '').toString();
                final cleanSchedDate = rawSchedDate.contains('T') ? rawSchedDate.split('T')[0] : (rawSchedDate.contains(' ') ? rawSchedDate.split(' ')[0] : rawSchedDate);
                final dateDisplay = cleanSchedDate.isNotEmpty ? cleanSchedDate : 'Today';
                final time = '$dateDisplay • ${booking['booking_time'] ?? 'Now'}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () => _navigateToDetails(booking),
                    child: _buildTimelineCard(
                      status: status,
                      time: time,
                      title: serviceName,
                      location: formatAddress(addressLine, city: city),
                      isOngoing: isOngoing,
                      isLast: index == (upcomingAndOngoing.length > 2 ? 1 : upcomingAndOngoing.length - 1),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    final List<Map<String, dynamic>> banners = [
      {
        'title': 'Weekly Target',
        'header': 'Earn ₹500 bonus',
        'subtitle': 'Complete 15 more jobs by Sunday to unlock rewards.',
        'color': const Color(0xFF6B4EFF),
      },
      {
        'title': 'Referral Program',
        'header': 'Refer a partner',
        'subtitle': 'Get ₹1,000 for every successful partner onboarding.',
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF5E3A), Color(0xFFFF2A68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'title': 'Skill Up',
        'header': 'Training center',
        'subtitle': 'Access new courses and boost your earning potential.',
        'color': const Color(0xFF00B17B),
      },
    ];

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final banner = banners[index];
          return GestureDetector(
            onTap: () {
              if (banner['title'] == 'Referral Program') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReferralScreen()),
                );
              }
            },
            child: Container(
              width: 300,
              margin: EdgeInsets.only(right: index == banners.length - 1 ? 0 : 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: banner['color'],
                gradient: banner['gradient'],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    banner['title'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60, // Light white/blueish
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner['header'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        banner['subtitle'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDateString(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(rawDate);
      if (dt != null) {
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    if (rawDate.contains('T')) {
      return rawDate.split('T').first;
    }
    return rawDate;
  }

  Widget _buildTimeChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewJobRequests() {
    final jobsState = ref.watch(jobsProvider);

    if (jobsState.newJobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Job Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1F3E),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'No new job requests at the moment.',
                  style: TextStyle(color: Colors.black38, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'New Job Requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1F3E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF1FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${jobsState.newJobs.length} New',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16155D),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...jobsState.newJobs.map((job) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    // Blue left bar
                    Container(
                      width: 4,
                      height: 154,
                      color: const Color(0xFF16155D),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job.serviceName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1C1F3E),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatAddress(job.address, city: job.city),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${job.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF16155D),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Earnings',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Row of chips
                            // Chips layout
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildTimeChip(Icons.calendar_today_outlined, _formatDateString(job.scheduledAt)),
                                _buildTimeChip(Icons.access_time_outlined, job.bookingTime),
                                _buildTimeChip(Icons.history_toggle_off_outlined, '60 Mins'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final success = await ref.read(jobsProvider.notifier).acceptJob(job.requestId);
                                        if (mounted) {
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Job request accepted successfully!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            final err = ref.read(jobsProvider).errorMessage ?? 'Failed to accept job';
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(err),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF16155D),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Accept Job',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: () => _navigateToDetails(job, isNewJob: true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF5F6FA),
                                        foregroundColor: const Color(0xFF16155D),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'View Details',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF1FE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF16155D),
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1F3E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1F3E),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _buildQuickActionCard(Icons.account_balance_wallet_outlined, 'Add Credits', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                );
              }),
              _buildQuickActionCard(Icons.school_outlined, 'Training', () {
                showTopPillToast(context, 'Training modules coming soon!');
              }),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<JobRequestModel?>(
      jobDispatchProvider.select((s) => s.activeJob),
      (previous, next) {
        if (next != null && previous?.requestId != next.requestId) {
          _showIncomingJobBottomSheet(context, next);
        }
      },
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF0FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.exit_to_app_rounded,
                      color: Color(0xFF16155D),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Leave BharatClap Partner?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16155D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to exit the app?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(color: Color(0xFF16155D)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Stay',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16155D),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            backgroundColor: const Color(0xFF16155D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Exit',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        if (shouldExit == true && context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _currentIndex == 1
                    ? const JobsScreen()
                    : _currentIndex == 2
                        ? const MoneyScreen()
                        : _currentIndex == 3
                            ? const ProfileScreen()
                            : RefreshIndicator(
                                color: const Color(0xFF16155D),
                                onRefresh: () async {
                                  await ref.read(providerProfileProvider.notifier).fetchProfile();
                                  await ref.read(jobsProvider.notifier).fetchAllJobs();
                                },
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    children: [
                                      _buildTopBar(),
                                      const SizedBox(height: 12),
                                      _buildGreetingHeader(),
                                      const SizedBox(height: 20),
                                      _buildKitBanner(),
                                      if (ref.watch(providerProfileProvider).profileData?['kitPurchased'] != true && ref.watch(providerProfileProvider).profileData?['providerKitCompleted'] != true)
                                        const SizedBox(height: 20),
                                      _buildStatsRow(),
                                      const SizedBox(height: 24),
                                      _buildUpcomingSchedule(),
                                      const SizedBox(height: 24),
                                      _buildBannerCarousel(),
                                      const SizedBox(height: 24),
                                      _buildNewJobRequests(),
                                      const SizedBox(height: 24),
                                      _buildQuickActions(),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ),
              ),
              // Custom Navigation Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  backgroundColor: Colors.white,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: const Color(0xFF16155D),
                  unselectedItemColor: Colors.black38,
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.assignment_outlined),
                      label: 'Jobs',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      label: 'Money',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SquareOnlineSlider extends StatelessWidget {
  final bool isOnline;
  final bool isLoading;
  final VoidCallback onTap;

  const SquareOnlineSlider({
    super.key,
    required this.isOnline,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(4),
        width: 92,
        height: 38,
        decoration: BoxDecoration(
          color: isOnline ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isOnline
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Dynamic Label: "ON" on left when online, "OFF" on right when offline
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              alignment: isOnline ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: isOnline ? 14.0 : 0.0,
                  right: isOnline ? 0.0 : 14.0,
                ),
                child: Text(
                  isOnline ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isOnline ? Colors.white : const Color(0xFFEF4444),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            // Sliding Square Knob
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF10B981),
                          ),
                        )
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showTopPillToast(BuildContext context, String message, {bool isError = false, bool isOffline = false}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _TopPillToastWidget(
      message: message,
      isError: isError,
      isOffline: isOffline,
      onDismiss: () {
        entry.remove();
      },
    ),
  );

  overlay.insert(entry);
}

class _TopPillToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isOffline;
  final VoidCallback onDismiss;

  const _TopPillToastWidget({
    required this.message,
    required this.isError,
    this.isOffline = false,
    required this.onDismiss,
  });

  @override
  State<_TopPillToastWidget> createState() => _TopPillToastWidgetState();
}

class _TopPillToastWidgetState extends State<_TopPillToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 2300), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final Color toastBgColor = widget.isError
        ? const Color(0xFFEF4444)
        : (widget.isOffline ? const Color(0xFF475569) : const Color(0xFF10B981));

    return Positioned(
      top: topPadding + 12,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: toastBgColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: toastBgColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isError 
                          ? Icons.error_outline_rounded 
                          : (widget.isOffline ? Icons.power_settings_new_rounded : Icons.check_circle_rounded),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
