import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/jobs_provider.dart';
import 'package:partner_app/providers/job_dispatch_provider.dart';
import 'package:partner_app/screens/jobs/job_details_screen.dart';

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

  int _getStatusForDate(DateTime date, List<dynamic> bookings, List<JobRequestModel> newJobs, bool isOnline) {
    if (!isOnline) {
      return 0; // Red cross if provider is OFFLINE / Emergency break
    }

    final dateBookings = bookings.where((b) {
      final sched = b['scheduled_at'] ?? b['scheduled_date'] ?? b['booking_date'] ?? b['date'] ?? b['createdAt'];
      if (sched == null) return false;
      try {
        final bDate = DateTime.parse(sched.toString()).toLocal();
        return _isSameDay(bDate, date);
      } catch (_) {
        return false;
      }
    }).toList();

    final dateJobs = newJobs.where((j) {
      if (j.scheduledAt.isEmpty) return false;
      try {
        final jDate = DateTime.parse(j.scheduledAt).toLocal();
        return _isSameDay(jDate, date);
      } catch (_) {
        return false;
      }
    }).toList();

    if (dateBookings.isNotEmpty || dateJobs.isNotEmpty) {
      final hasActive = dateBookings.any((b) => 
        ['accepted', 'started', 'waiting_start_otp', 'waiting_end_otp', 'in_progress', 'assigned', 'pending']
        .contains(b['status']?.toString().toLowerCase())
      ) || dateJobs.isNotEmpty;

      if (hasActive) return 2; // Orange clock (booking scheduled / pending)
      
      final allCompleted = dateBookings.every((b) => b['status']?.toString().toLowerCase() == 'completed');
      if (allCompleted) return 1; // Green check (completed)
    }

    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return 0; // Red cross on weekends by default unless booked
    }
    return 1; // Green check on available weekdays
  }

  Widget _buildTopBar(BuildContext context) {
    final dispatchState = ref.watch(jobDispatchProvider);
    final isOnline = dispatchState.isOnline;

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
                  title: Text(isOnline ? 'Emergency Break' : 'Resume Work'),
                  content: Text(
                    isOnline
                        ? 'Are you sure you want to take an emergency break? This will turn off your status and make you offline.'
                        : 'Do you want to turn on your availability and resume work?',
                  ),
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
                          SnackBar(
                            content: Text(isOnline ? 'Emergency break activated (Offline)' : 'Work resumed (Online)!'),
                            backgroundColor: isOnline ? Colors.red : Colors.green,
                          ),
                        );
                      },
                      child: Text(
                        isOnline ? 'Yes, Go Offline' : 'Go Online',
                        style: TextStyle(color: isOnline ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(
              isOnline ? Icons.notifications_active_outlined : Icons.play_circle_fill_outlined,
              color: isOnline ? Colors.red : Colors.green,
              size: 18,
            ),
            label: Text(
              isOnline ? 'Emergency Break' : 'Resume Work',
              style: TextStyle(
                color: isOnline ? Colors.red : Colors.green,
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

  Widget _buildCalendarGrid(List<dynamic> bookings, List<JobRequestModel> newJobs, bool isOnline) {
    final weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final weekdayOffset = firstDayOfMonth.weekday % 7;

    final prevMonth = _focusedMonth.month == 1
        ? DateTime(_focusedMonth.year - 1, 12, 1)
        : DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    final prevMonthDaysCount = DateTime(_focusedMonth.year, _focusedMonth.month, 0).day;

    final List<Map<String, dynamic>> gridDays = [];

    for (int i = weekdayOffset - 1; i >= 0; i--) {
      final dayNum = prevMonthDaysCount - i;
      gridDays.add({
        'day': dayNum.toString(),
        'date': DateTime(prevMonth.year, prevMonth.month, dayNum),
        'isCurrentMonth': false,
      });
    }

    final currentMonthDaysCount = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    for (int i = 1; i <= currentMonthDaysCount; i++) {
      gridDays.add({
        'day': i.toString(),
        'date': DateTime(_focusedMonth.year, _focusedMonth.month, i),
        'isCurrentMonth': true,
      });
    }

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

              final int calculatedStatus = _getStatusForDate(date, bookings, newJobs, isOnline);

              Widget statusIcon;
              if (isSelected) {
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

  Widget _buildScheduledBookingsSection(List<dynamic> bookings, List<JobRequestModel> newJobs) {
    final dayBookings = bookings.where((b) {
      final sched = b['scheduled_at'] ?? b['scheduled_date'] ?? b['booking_date'] ?? b['date'] ?? b['createdAt'];
      if (sched == null) return false;
      try {
        final bDate = DateTime.parse(sched.toString()).toLocal();
        return _isSameDay(bDate, _selectedDate);
      } catch (_) {
        return false;
      }
    }).toList();

    final dayRequests = newJobs.where((j) {
      if (j.scheduledAt.isEmpty) return false;
      try {
        final jDate = DateTime.parse(j.scheduledAt).toLocal();
        return _isSameDay(jDate, _selectedDate);
      } catch (_) {
        return false;
      }
    }).toList();

    final totalItems = dayBookings.length + dayRequests.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scheduled Services',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1F3E),
                ),
              ),
              Text(
                '$totalItems Item(s)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
        if (totalItems == 0)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              'No scheduled services for this period.',
              style: TextStyle(color: Colors.black38, fontSize: 13),
            ),
          )
        else ...[
          ...dayBookings.map((b) => _buildBookingCard(b, isNewJob: false)),
          ...dayRequests.map((j) => _buildJobRequestCard(j)),
        ],
      ],
    );
  }

  Widget _buildBookingCard(dynamic b, {required bool isNewJob}) {
    final subservice = b['subservice_id'];
    String serviceName = 'Service Booking';
    if (subservice is Map && subservice['subservice_name'] != null) {
      serviceName = subservice['subservice_name'];
    } else if (b['variant_name'] != null && b['variant_name'].toString().isNotEmpty) {
      serviceName = b['variant_name'];
    } else if (b['items'] is List && (b['items'] as List).isNotEmpty) {
      final firstItem = (b['items'] as List).first;
      if (firstItem is Map) {
        serviceName = firstItem['name'] ?? firstItem['subservice_name'] ?? 'Service Booking';
      }
    }

    final String status = (b['status'] ?? 'ACCEPTED').toString().toUpperCase();
    Color statusBgColor = Colors.blue.shade50;
    Color statusTextColor = const Color(0xFF16155D);

    if (status == 'COMPLETED') {
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green.shade800;
    } else if (status == 'IN_PROGRESS' || status == 'STARTED') {
      statusBgColor = Colors.purple.shade50;
      statusTextColor = Colors.purple.shade800;
    } else if (status == 'CANCELLED' || status == 'REJECTED') {
      statusBgColor = Colors.red.shade50;
      statusTextColor = Colors.red.shade800;
    }

    final double amount = (b['payable_amount'] ?? b['total_amount'] ?? b['final_amount'] ?? b['totalPrice'] ?? 0).toDouble();
    final String timeSlot = b['booking_time'] ?? b['scheduled_time'] ?? 'Scheduled Slot';

    final customer = b['user_id'] ?? b['customer_id'];
    String customerName = 'Customer';
    if (customer is Map) {
      customerName = customer['name'] ?? customer['phone'] ?? 'Customer';
    }

    final address = b['address_id'] ?? b['address'];
    String locationText = '';
    if (address is Map) {
      locationText = address['city'] ?? address['address_line'] ?? '';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailsScreen(booking: b, isNewJob: isNewJob),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1C1F3E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined, size: 14, color: Colors.black45),
                    const SizedBox(width: 6),
                    Text(
                      timeSlot,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    if (locationText.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.black45),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationText,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer: $customerName',
                      style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF16155D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobRequestCard(JobRequestModel j) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailsScreen(booking: j.toJson(), isNewJob: true),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        j.serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1C1F3E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'NEW REQUEST',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined, size: 14, color: Colors.black45),
                    const SizedBox(width: 6),
                    Text(
                      j.bookingTime.isNotEmpty ? j.bookingTime : 'Scheduled Slot',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        j.city,
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Location: ${j.address.isNotEmpty ? j.address : j.city}',
                      style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '₹${j.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF16155D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
              child: RefreshIndicator(
                color: const Color(0xFF16155D),
                onRefresh: () async {
                  await ref.read(jobsProvider.notifier).fetchAllJobs();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMonthPicker(),
                      const SizedBox(height: 8),
                      _buildCalendarGrid(jobsState.bookings, jobsState.newJobs, isOnline),
                      const SizedBox(height: 8),
                      _buildSetJobLimit(),
                      _buildScheduledBookingsSection(jobsState.bookings, jobsState.newJobs),
                      const SizedBox(height: 24),
                    ],
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
