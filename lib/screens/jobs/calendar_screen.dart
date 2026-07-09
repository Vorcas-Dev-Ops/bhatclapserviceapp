import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/jobs_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobsProvider.notifier).fetchAllJobs();
    });
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1C1F3E), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'Calendar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1F3E),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.red, size: 18),
            label: const Text(
              'Emergency Break',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF2D3047)),
                onPressed: () {},
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'July 2026',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3047),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF2D3047)),
                onPressed: () {},
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Today',
              style: TextStyle(
                color: Color(0xFF16155D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // days list structure
    final List<Map<String, dynamic>> days = [
      {'day': '30', 'status': 0, 'isCurrentMonth': false},
      {'day': '1', 'status': 1, 'isCurrentMonth': true},
      {'day': '2', 'status': 1, 'isCurrentMonth': true},
      {'day': '3', 'status': 0, 'isCurrentMonth': true},
      {'day': '4', 'status': 0, 'isCurrentMonth': true},
      {'day': '5', 'status': 0, 'isCurrentMonth': true},
      {'day': '6', 'status': 0, 'isCurrentMonth': true},
      {'day': '7', 'status': 0, 'isCurrentMonth': true},
      {'day': '8', 'status': 0, 'isCurrentMonth': true},
      {'day': '9', 'status': 3, 'isCurrentMonth': true}, // Highlight today
      {'day': '10', 'status': 0, 'isCurrentMonth': true},
      {'day': '11', 'status': 2, 'isCurrentMonth': true},
      {'day': '12', 'status': 2, 'isCurrentMonth': true},
      {'day': '13', 'status': 2, 'isCurrentMonth': true},
      {'day': '14', 'status': 2, 'isCurrentMonth': true},
      {'day': '15', 'status': 2, 'isCurrentMonth': true},
      {'day': '16', 'status': 2, 'isCurrentMonth': true},
      {'day': '17', 'status': 2, 'isCurrentMonth': true},
      {'day': '18', 'status': 2, 'isCurrentMonth': true},
      {'day': '19', 'status': 2, 'isCurrentMonth': true},
      {'day': '20', 'status': 2, 'isCurrentMonth': true},
      {'day': '21', 'status': 2, 'isCurrentMonth': true},
      {'day': '22', 'status': 2, 'isCurrentMonth': true},
      {'day': '23', 'status': 1, 'isCurrentMonth': true},
      {'day': '24', 'status': 1, 'isCurrentMonth': true},
      {'day': '25', 'status': 1, 'isCurrentMonth': true},
      {'day': '26', 'status': 1, 'isCurrentMonth': true},
      {'day': '27', 'status': 1, 'isCurrentMonth': true},
    ];

    final weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekLabels.map((l) {
              return SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    l,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black38,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final d = days[index];
              final bool isActive = d['status'] == 3;
              final bool isCurrentMonth = d['isCurrentMonth'];

              Widget statusIcon;
              if (d['status'] == 0) {
                statusIcon = const Icon(Icons.close, color: Colors.red, size: 12);
              } else if (d['status'] == 1) {
                statusIcon = const Icon(Icons.check, color: Colors.green, size: 12);
              } else if (d['status'] == 2) {
                statusIcon = const Icon(Icons.access_time, color: Colors.orange, size: 12);
              } else {
                statusIcon = const Icon(Icons.access_time, color: Colors.white, size: 12);
              }

              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF16155D) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        d['day'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : (isCurrentMonth ? const Color(0xFF1C1F3E) : Colors.black26),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  statusIcon,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSetJobLimit() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: const [
            Icon(
              Icons.work_outline,
              color: Color(0xFF16155D),
              size: 22,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Set Job Limit',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3047),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.black38,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledBookingsSection(List<dynamic> bookings) {
    final acceptedBookings = bookings.where((b) => b['status'] == 'accepted').toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Text(
            'Scheduled Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1F3E),
            ),
          ),
        ),
        if (acceptedBookings.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              'No scheduled services for this period.',
              style: TextStyle(color: Colors.black38, fontSize: 13),
            ),
          )
        else
          ...acceptedBookings.map((b) {
            final subservice = b['subservice_id'] ?? {};
            final serviceName = subservice['subservice_name'] ?? b['variant_name'] ?? 'Cleaning Service';
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${b['scheduled_at'] ?? 'Today'} at ${b['booking_time'] ?? 'Now'}',
                        style: const TextStyle(color: Colors.black38, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    '₹${b['payable_amount']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16155D)),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthPicker(),
                    const SizedBox(height: 8),
                    _buildCalendarGrid(),
                    const SizedBox(height: 8),
                    _buildSetJobLimit(),
                    _buildScheduledBookingsSection(jobsState.bookings),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
