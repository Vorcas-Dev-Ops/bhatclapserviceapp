import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/jobs_provider.dart';
import 'package:partner_app/providers/job_dispatch_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobsProvider.notifier).fetchAllJobs();
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = _focusedMonth.month == 1
          ? DateTime(_focusedMonth.year - 1, 12, 1)
          : DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = _focusedMonth.month == 12
          ? DateTime(_focusedMonth.year + 1, 1, 1)
          : DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _selectToday() {
    setState(() {
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _focusedMonth = DateTime(now.year, now.month, 1);
    });
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  int _getStatusForDate(DateTime date, List<dynamic> bookings, bool isOnline) {
    // Check if there are bookings on this date
    final dateBookings = bookings.where((b) {
      if (b['scheduled_at'] == null) return false;
      try {
        final bDate = DateTime.parse(b['scheduled_at']);
        return _isSameDay(bDate, date);
      } catch (_) {
        return false;
      }
    }).toList();

    if (dateBookings.isNotEmpty) {
      final hasActive = dateBookings.any((b) => 
        ['accepted', 'started', 'waiting_start_otp', 'waiting_end_otp', 'in_progress']
        .contains(b['status'])
      );
      if (hasActive) return 2; // orange clock (booking scheduled)
      
      final allCompleted = dateBookings.every((b) => b['status'] == 'completed');
      if (allCompleted) return 1; // green check (completed)
    }

    if (!isOnline) {
      return 0; // Show cross (unavailable) for all days if OFFLINE
    }

    // Default fallback: Weekdays available (1), weekends busy/cross (0)
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return 0; // red cross
    }
    return 1; // green check
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
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Emergency Break'),
                  content: const Text('Are you sure you want to take an emergency break? This will turn off your status and make you offline.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(jobDispatchProvider.notifier).toggleAvailability();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Availability status updated!'), backgroundColor: Colors.red),
                        );
                      },
                      child: const Text('Yes, Go Offline', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
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
    final title = '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF2D3047)),
                onPressed: _prevMonth,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3047),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF2D3047)),
                onPressed: _nextMonth,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
          OutlinedButton(
            onPressed: _selectToday,
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

  Widget _buildCalendarGrid(List<dynamic> bookings, bool isOnline) {
    final weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    // Generate days dynamically
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final weekdayOffset = firstDayOfMonth.weekday % 7; // Sunday is 0, Monday is 1, etc.

    final prevMonth = _focusedMonth.month == 1
        ? DateTime(_focusedMonth.year - 1, 12, 1)
        : DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    final prevMonthDaysCount = DateTime(_focusedMonth.year, _focusedMonth.month, 0).day;

    final List<Map<String, dynamic>> gridDays = [];

    // Pad previous month days
    for (int i = weekdayOffset - 1; i >= 0; i--) {
      final dayNum = prevMonthDaysCount - i;
      gridDays.add({
        'day': dayNum.toString(),
        'date': DateTime(prevMonth.year, prevMonth.month, dayNum),
        'isCurrentMonth': false,
      });
    }

    // Current month days
    final currentMonthDaysCount = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    for (int i = 1; i <= currentMonthDaysCount; i++) {
      gridDays.add({
        'day': i.toString(),
        'date': DateTime(_focusedMonth.year, _focusedMonth.month, i),
        'isCurrentMonth': true,
      });
    }

    // Pad next month days to align grid to multiples of 7
    final totalCells = ((gridDays.length + 6) ~/ 7) * 7;
    final nextMonth = _focusedMonth.month == 12
        ? DateTime(_focusedMonth.year + 1, 1, 1)
        : DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    int nextMonthDay = 1;
    while (gridDays.length < totalCells) {
      gridDays.add({
        'day': nextMonthDay.toString(),
        'date': DateTime(nextMonth.year, nextMonth.month, nextMonthDay),
        'isCurrentMonth': false,
      });
      nextMonthDay++;
    }

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
            itemCount: gridDays.length,
            itemBuilder: (context, index) {
              final d = gridDays[index];
              final date = d['date'] as DateTime;
              final bool isSelected = _isSameDay(date, _selectedDate);
              final bool isCurrentMonth = d['isCurrentMonth'];

              // Retrieve the visual status index
              final int calculatedStatus = _getStatusForDate(date, bookings, isOnline);

              Widget statusIcon;
              if (isSelected) {
                // Tapped active date gets a white access clock under it (status 3 equivalent visual)
                statusIcon = const Icon(Icons.access_time, color: Colors.white, size: 12);
              } else {
                if (calculatedStatus == 0) {
                  statusIcon = const Icon(Icons.close, color: Colors.red, size: 12);
                } else if (calculatedStatus == 1) {
                  statusIcon = const Icon(Icons.check, color: Colors.green, size: 12);
                } else {
                  statusIcon = const Icon(Icons.access_time, color: Colors.orange, size: 12);
                }
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF16155D) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          d['day'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isCurrentMonth ? const Color(0xFF1C1F3E) : Colors.black26),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    statusIcon,
                  ],
                ),
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
      child: GestureDetector(
        onTap: () {
          final controller = TextEditingController(text: '5');
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Set Daily Job Limit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter maximum jobs you want to accept per day:'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Job Limit',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Daily job limit set to ${controller.text} successfully!')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
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
      ),
    );
  }

  Widget _buildScheduledBookingsSection(List<dynamic> bookings) {
    // Filter bookings by selected day & status list
    final dayBookings = bookings.where((b) {
      if (b['scheduled_at'] == null) return false;
      try {
        final bDate = DateTime.parse(b['scheduled_at']);
        return _isSameDay(bDate, _selectedDate);
      } catch (_) {
        return false;
      }
    }).toList();

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
        if (dayBookings.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              'No scheduled services for this period.',
              style: TextStyle(color: Colors.black38, fontSize: 13),
            ),
          )
        else
          ...dayBookings.map((b) {
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${b['scheduled_at'] != null ? DateTime.parse(b['scheduled_at']).toLocal().toString().split(' ')[0] : 'Today'} at ${b['booking_time'] ?? 'Now'}',
                          style: const TextStyle(color: Colors.black38, fontSize: 12),
                        ),
                      ],
                    ),
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
    final dispatchState = ref.watch(jobDispatchProvider);
    final isOnline = dispatchState.isOnline;
    
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
                    _buildCalendarGrid(jobsState.bookings, isOnline),
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
