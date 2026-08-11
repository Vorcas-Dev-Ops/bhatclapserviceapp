import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/jobs_provider.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/screens/finance/add_credits_screen.dart';
import 'package:partner_app/screens/jobs/job_details_screen.dart';
import 'package:partner_app/screens/notifications/notifications_screen.dart';
import 'package:partner_app/providers/notification_provider.dart';

import 'package:partner_app/providers/wallet_provider.dart';
import 'package:partner_app/screens/profile/subscription_screen.dart';
import 'package:partner_app/utils/address_utils.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  // Tabs: 0 -> Upcoming, 1 -> Ongoing, 2 -> New
  int _activeTab = 2; // Default to 'New' as shown in the first screenshot

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobsProvider.notifier).fetchAllJobs();
      ref.read(notificationProvider.notifier).fetchNotifications();
      ref.read(walletProvider.notifier).fetchWalletAndReviews();
    });
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
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.unreadCount;
    final walletState = ref.watch(walletProvider);
    final leadCount = walletState.leadBalance;
    
    String creditsText = '...';
    if (profile != null) {
      final walletBalance = profile['walletBalance'] ?? 0.0;
      final reservedBalance = profile['reservedBalance'] ?? 0.0;
      final creditLimit = profile['creditLimit'] ?? 500.0;
      final availableCredit = (walletBalance as num).toDouble() - (reservedBalance as num).toDouble() + (creditLimit as num).toDouble();
      final credits = (availableCredit / 10).toInt();
      creditsText = '$credits';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'BharatClap',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF16155D),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Jobs',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1F3E),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildRedLeadCountBadge(context, leadCount),
              const SizedBox(width: 8),
              // Credits Pill
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddCreditsScreen()),
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
                        creditsText,
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
              const SizedBox(width: 12),
              // Notification Bell with Badge
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
                    if (unreadCount > 0)
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
    );
  }

  Widget _buildTabButton({
    required String label,
    required String count,
    required int index,
  }) {
    final bool isActive = _activeTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? Border.all(color: const Color(0xFF16155D), width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isActive ? const Color(0xFF16155D) : Colors.black38,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF16155D) : const Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    count,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabsRow() {
    final jobsState = ref.watch(jobsProvider);
    final upcomingCount = jobsState.bookings.where((b) {
      if (b is! Map) return false;
      final status = (b['status'] ?? '').toString().toLowerCase();
      return ['accepted', 'assigned', 'confirmed', 'scheduled'].contains(status);
    }).length;

    final ongoingCount = jobsState.bookings.where((b) {
      if (b is! Map) return false;
      final status = (b['status'] ?? '').toString().toLowerCase();
      return ['accepted', 'assigned', 'confirmed', 'scheduled', 'on_the_way', 'arrived', 'reached', 'waiting_start_otp', 'in_progress', 'started', 'ongoing', 'waiting_end_otp'].contains(status);
    }).length;

    final newCount = jobsState.newJobs.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          _buildTabButton(label: 'Upcoming', count: '$upcomingCount', index: 0),
          const SizedBox(width: 8),
          _buildTabButton(label: 'Ongoing', count: '$ongoingCount', index: 1),
          const SizedBox(width: 8),
          _buildTabButton(label: 'New', count: '$newCount', index: 2),
        ],
      ),
    );
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

  Widget _buildJobCard({
    required String title,
    required String earnings,
    required String location,
    required String date,
    required String time,
    required String duration,
    Widget? actionSection,
    Widget? footerSection,
    required double cardHeight,
  }) {
    final formattedDate = _formatDateString(date);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Blue accent left bar
                  Container(
                    width: 4,
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
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1C1F3E),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      location,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black38,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    earnings,
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
                          // Time Chips Row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTimeChip(Icons.calendar_today_outlined, formattedDate),
                                const SizedBox(width: 8),
                                _buildTimeChip(Icons.access_time_outlined, time),
                                const SizedBox(width: 8),
                                _buildTimeChip(Icons.history_toggle_off_outlined, duration),
                              ],
                            ),
                          ),
                          if (actionSection != null) ...[
                            const SizedBox(height: 16),
                            actionSection,
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ?footerSection,
          ],
        ),
      ),
    );
  }

  Widget _buildNewJobsView() {
    final jobsState = ref.watch(jobsProvider);
    if (jobsState.newJobs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            'No new job requests at the moment.',
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: jobsState.newJobs.map((job) {
        return _buildJobCard(
          title: job.serviceName,
          earnings: '₹${job.amount}',
          location: formatAddress(job.address, city: job.city),
          date: job.scheduledAt,
          time: job.bookingTime,
          duration: '60 Mins',
          cardHeight: 154,
          actionSection: Row(
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
                            const SnackBar(content: Text('Job request accepted successfully!'), backgroundColor: Colors.green),
                          );
                        } else {
                          final err = ref.read(jobsProvider).errorMessage ?? 'Failed to accept job';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err), backgroundColor: Colors.red),
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
                  child: OutlinedButton(
                    onPressed: () => _navigateToDetails(job, isNewJob: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16155D),
                      side: const BorderSide(color: Color(0xFF16155D), width: 1.5),
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
        );
      }).toList(),
    );
  }

  Widget _buildUpcomingJobsView() {
    final jobsState = ref.watch(jobsProvider);
    final upcomingList = jobsState.bookings.where((b) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      return ['accepted', 'assigned', 'confirmed'].contains(status);
    }).toList();

    if (upcomingList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            'No upcoming schedule bookings.',
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Jobs',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1F3E),
          ),
        ),
        const SizedBox(height: 12),
        ...upcomingList.map((booking) {
          final subservice = booking['subservice_id'] ?? {};
          final serviceName = subservice['subservice_name'] ?? booking['variant_name'] ?? 'Cleaning Service';
          final address = booking['address_id'] ?? {};
          final addressLine = address['address_line'] ?? 'Address';
          final city = address['city'] ?? 'City';

          return _buildJobCard(
            title: serviceName,
            earnings: '₹${booking['payable_amount']}',
            location: formatAddress(addressLine, city: city),
            date: booking['scheduled_at'] ?? 'Today',
            time: booking['booking_time'] ?? 'Now',
            duration: '60 Mins',
            cardHeight: 154,
            actionSection: SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () => _navigateToDetails(booking, isNewJob: false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16155D),
                  side: const BorderSide(color: Color(0xFF16155D), width: 1.5),
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
          );
        }).toList(),
      ],
    );
  }

  Widget _buildOngoingJobsView() {
    final jobsState = ref.watch(jobsProvider);
    final ongoingList = jobsState.bookings.where((b) {
      if (b is! Map) return false;
      final status = (b['status'] ?? '').toString().toLowerCase();
      return ['accepted', 'assigned', 'confirmed', 'scheduled', 'on_the_way', 'arrived', 'reached', 'waiting_start_otp', 'in_progress', 'started', 'ongoing', 'waiting_end_otp'].contains(status);
    }).toList();

    if (ongoingList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            'No ongoing services.',
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: ongoingList.map((booking) {
        final subservice = booking['subservice_id'] ?? {};
        final serviceName = subservice['subservice_name'] ?? booking['variant_name'] ?? 'Cleaning Service';
        final address = booking['address_id'] ?? {};
        final addressLine = address['address_line'] ?? 'Address';
        final city = address['city'] ?? 'City';
        final rawStatus = (booking['status'] ?? 'started').toString().toLowerCase();
        final displayStatus = rawStatus == 'waiting_start_otp'
            ? 'WAITING FOR START OTP'
            : rawStatus == 'waiting_end_otp'
                ? 'WAITING FOR END OTP'
                : rawStatus == 'in_progress' || rawStatus == 'started' || rawStatus == 'ongoing'
                    ? 'SERVICE IN PROGRESS'
                    : rawStatus == 'on_the_way'
                        ? 'ON THE WAY TO LOCATION'
                        : rawStatus == 'arrived' || rawStatus == 'reached'
                            ? 'ARRIVED AT LOCATION'
                            : 'ASSIGNED / CONFIRMED';

        return _buildJobCard(
          title: serviceName,
          earnings: '₹${booking['payable_amount']}',
          location: formatAddress(addressLine, city: city),
          date: booking['scheduled_at'] ?? 'Today',
          time: booking['booking_time'] ?? 'Now',
          duration: '60 Mins',
          cardHeight: 194,
          actionSection: SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () => _navigateToDetails(booking, isNewJob: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16155D),
                side: const BorderSide(color: Color(0xFF16155D), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'View Progress Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          footerSection: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFFEFF1FE),
            child: Center(
              child: Text(
                displayStatus,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16155D),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);
    final isLoading = jobsState.status == JobsStatus.loading;

    Widget activeView;
    if (isLoading) {
      activeView = const Padding(
        padding: EdgeInsets.symmetric(vertical: 80.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_activeTab == 0) {
      activeView = _buildUpcomingJobsView();
    } else if (_activeTab == 1) {
      activeView = _buildOngoingJobsView();
    } else {
      activeView = _buildNewJobsView();
    }

    return Column(
      children: [
        _buildTopBar(),
        const SizedBox(height: 12),
        _buildTabsRow(),
        const SizedBox(height: 24),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF16155D),
            onRefresh: () async {
              await ref.read(providerProfileProvider.notifier).fetchProfile();
              await ref.read(jobsProvider.notifier).fetchAllJobs();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: activeView,
            ),
          ),
        ),
      ],
    );
  }
}
