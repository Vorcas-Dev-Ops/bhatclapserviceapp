import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/job_dispatch_provider.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/screens/jobs/jobs_screen.dart';
import 'package:partner_app/screens/finance/money_screen.dart';
import 'package:partner_app/screens/profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(providerProfileProvider.notifier).fetchProfile();
    });
  }

  Widget _buildTopBar() {
    final dispatchState = ref.watch(jobDispatchProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Credits pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Hexagon/diamond shape simulated
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
                const Text(
                  '200',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3047),
                  ),
                ),
              ],
            ),
          ),
          
          // Online Switch
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dispatchState.isOnline ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: dispatchState.isOnline ? Colors.green : Colors.red,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: dispatchState.isOnline,
                  onChanged: (val) {
                    ref.read(jobDispatchProvider.notifier).toggleAvailability();
                  },
                  activeColor: Colors.green,
                ),
              ),
            ],
          ),

          // Actions
          Row(
            children: [
              // Notification Bell
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
              const SizedBox(width: 12),
              // Siren Alert
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEFF1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: Colors.red,
                  size: 22,
                ),
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
                  '${job.address}, ${job.city}',
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
                          '${job.scheduledAt} • ${job.bookingTime}',
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
                            await ref.read(jobDispatchProvider.notifier).rejectJob(job.requestId);
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
                            final success = await ref.read(jobDispatchProvider.notifier).acceptJob(job.requestId);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Job accepted! Navigate to Jobs tab for instructions.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
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

  Widget _buildGreetingHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning, Muthupandi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1F3E),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ready for today\'s bookings?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, {bool showStar = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16155D),
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
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          _buildStatCard('Today\'s Jobs', '12'),
          const SizedBox(width: 12),
          _buildStatCard('Earnings', '₹0'),
          const SizedBox(width: 12),
          _buildStatCard('Rating', '4.8', showStar: true),
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
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
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
                onPressed: () {},
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
          _buildTimelineCard(
            status: 'ONGOING',
            time: 'Now - 11:00 AM',
            title: 'Bathroom Cleaning',
            location: 'Sector 45, Gurgaon, HR',
            isOngoing: true,
            isLast: false,
          ),
          const SizedBox(height: 12),
          _buildTimelineCard(
            status: 'UPCOMING',
            time: '02:00 PM - 03:30 PM',
            title: 'Kitchen Sanitization',
            location: 'Paschim Vihar, Delhi',
            isOngoing: false,
            isLast: true,
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
          return Container(
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
          );
        },
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

  Widget _buildNewJobRequests() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
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
                    child: const Text(
                      '1 New',
                      style: TextStyle(
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
          // Job Request Card with thick left accent border
          Container(
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
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bathroom Cleaning',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1C1F3E),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Hennur, Bengaluru • 27 Jun',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    '₹450',
                                    style: TextStyle(
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
                          Row(
                            children: [
                              _buildTimeChip(Icons.calendar_today_outlined, '27-06-26'),
                              const SizedBox(width: 8),
                              _buildTimeChip(Icons.access_time_outlined, '11:30 AM'),
                              const SizedBox(width: 8),
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
                                    onPressed: () {},
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
                                    onPressed: () {},
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
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String text) {
    return Container(
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
              _buildQuickActionCard(Icons.calendar_today_outlined, 'Availability'),
              _buildQuickActionCard(Icons.account_balance_wallet_outlined, 'Add Credits'),
              _buildQuickActionCard(Icons.description_outlined, 'Documents'),
              _buildQuickActionCard(Icons.school_outlined, 'Training'),
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

    return Scaffold(
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
                          : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildTopBar(),
                          const SizedBox(height: 12),
                          _buildGreetingHeader(),
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
    );
  }
}
