import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/jobs_provider.dart';

class JobDetailsScreen extends ConsumerStatefulWidget {
  final dynamic booking;
  final bool isNewJob;
  const JobDetailsScreen({super.key, required this.booking, this.isNewJob = false});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  // Steps: 0 -> Arrived at Location, 1 -> Enter Start OTP, 2 -> Service in Progress, 3 -> Enter End OTP
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.isNewJob && widget.booking != null) {
      final status = widget.booking['status'];
      if (status == 'accepted') {
        _stepIndex = 0;
      } else if (status == 'waiting_start_otp') {
        _stepIndex = 1;
      } else if (status == 'in_progress') {
        _stepIndex = 2;
      } else if (status == 'waiting_end_otp') {
        _stepIndex = 3;
      }
    }
  }

  // Start OTP inputs state (6 digits)
  final List<TextEditingController> _startOtpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _startOtpFocusNodes = List.generate(6, (_) => FocusNode());

  // End OTP inputs state (6 digits)
  final List<TextEditingController> _endOtpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _endOtpFocusNodes = List.generate(6, (_) => FocusNode());

  // Photos status
  bool _afterPhotosUploaded = false;

  @override
  void dispose() {
    for (var c in _startOtpControllers) {
      c.dispose();
    }
    for (var f in _startOtpFocusNodes) {
      f.dispose();
    }
    for (var c in _endOtpControllers) {
      c.dispose();
    }
    for (var f in _endOtpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onStartOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _startOtpFocusNodes[index + 1].requestFocus();
      } else {
        _startOtpFocusNodes[index].unfocus();
        if (_startOtpControllers.every((c) => c.text.isNotEmpty)) {
          _verifyStartServiceOtp();
        }
      }
    } else {
      if (index > 0) {
        _startOtpFocusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _verifyStartServiceOtp() async {
    final otpCode = _startOtpControllers.map((c) => c.text).join();
    final bookingId = widget.booking['_id'];
    final success = await ref.read(jobsProvider.notifier).verifyStartOtp(bookingId, otpCode);
    if (success && mounted) {
      setState(() {
        _stepIndex = 2; // Move to Service in Progress
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service started successfully!'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect OTP or verification failed'), backgroundColor: Colors.red),
      );
    }
  }

  void _onEndOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _endOtpFocusNodes[index + 1].requestFocus();
      } else {
        _endOtpFocusNodes[index].unfocus();
        if (_endOtpControllers.every((c) => c.text.isNotEmpty)) {
          _verifyEndServiceOtp();
        }
      }
    } else {
      if (index > 0) {
        _endOtpFocusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _verifyEndServiceOtp() async {
    final otpCode = _endOtpControllers.map((c) => c.text).join();
    final bookingId = widget.booking['_id'];
    final success = await ref.read(jobsProvider.notifier).verifyEndOtp(bookingId, otpCode);
    if (success && mounted) {
      _showCompletionDialog();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect OTP or verification failed'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Service Completed!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF16155D),
          ),
        ),
        content: const Text(
          'The service has been successfully completed. Thank you!',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Pop JobDetailsScreen
            },
            child: const Text(
              'OK',
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

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3047),
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildCircularIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFEFF1FE),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: const Color(0xFF16155D),
        size: 18,
      ),
    );
  }

  String _formatDateVal(dynamic rawDate) {
    if (rawDate == null) return 'Today';
    final str = rawDate.toString();
    if (str.isEmpty) return 'Today';
    try {
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    if (str.contains('T')) {
      return str.split('T').first;
    }
    return str;
  }

  Widget _buildStep0ArrivedView() {
    final address = widget.booking['address_id'] ?? {};
    final addressLine = address['address_line'] ?? 'No 48, 5th Cross, Hennur Rd';
    final city = address['city'] ?? 'Bengaluru';
    final dateVal = _formatDateVal(widget.booking['scheduled_at']);
    final timeVal = widget.booking['booking_time'] ?? 'Now';
    
    final user = widget.booking['user_id'] ?? {};
    final userName = user['name'] ?? 'Virat Sharma';

    return Expanded(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Details
                _buildSectionHeader('Customer Details'),
                _buildCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1F3E),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Job ID',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black38,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.booking['booking_id'] ?? '#BC-88241',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16155D),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Color(0xFF0F9D58),
                                  size: 18,
                                ),
                                label: const Text(
                                  'Chat',
                                  style: TextStyle(
                                    color: Color(0xFF0F9D58),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF5F6FA),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.phone_outlined,
                                  color: Color(0xFF16155D),
                                  size: 18,
                                ),
                                label: const Text(
                                  'Call',
                                  style: TextStyle(
                                    color: Color(0xFF16155D),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEFF1FE),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                _buildCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCircularIcon(Icons.location_on_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$addressLine, $city',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1C1F3E),
                                  fontWeight: FontWeight.w500,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _buildCircularIcon(Icons.calendar_today_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Date',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black38,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateVal,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1C1F3E),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                _buildCircularIcon(Icons.access_time_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Time',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black38,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timeVal,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1C1F3E),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Service Breakdown
                _buildSectionHeader('Service Breakdown'),
                _buildCardContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.booking['service_name'] ?? 'Cleaning Service',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1F3E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '60 mins • 1 Service Unit',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${widget.booking['payable_amount'] ?? widget.booking['amount'] ?? 450}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1F3E),
                        ),
                      ),
                    ],
                  ),
                ),

                // Earning Summary
                _buildSectionHeader('Earning Summary'),
                _buildCardContainer(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Service Total',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₹${widget.booking['payable_amount'] ?? widget.booking['amount'] ?? 450}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1C1F3E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Platform Fee / Comm.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₹${((widget.booking['payable_amount'] ?? widget.booking['amount'] ?? 450) * 0.2).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(
                          color: Color(0xFFEFF1FE),
                          thickness: 1,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Final Earnings',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1F3E),
                            ),
                          ),
                          Text(
                            '₹${((widget.booking['payable_amount'] ?? widget.booking['amount'] ?? 450) * 0.8).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16155D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sticky Bottom Action Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: widget.isNewJob
                    ? ElevatedButton(
                        onPressed: () async {
                          final success = await ref
                              .read(jobsProvider.notifier)
                              .acceptJob(widget.booking.requestId);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Job accepted successfully!'),
                                backgroundColor: Color(0xFF2E7D32),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16155D),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Accept Job',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () async {
                          final success = await ref
                              .read(jobsProvider.notifier)
                              .startService(widget.booking['_id'], ['https://cloudinary.com/mock-before.jpg']);
                          if (success && mounted) {
                            setState(() {
                              _stepIndex = 1;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Arrived at Location',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16155D),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1EnterStartOtpView() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: DashedCirclePainter(
                    color: const Color(0xFFC5C9E0),
                    strokeWidth: 1.5,
                    gap: 6.0,
                    dashLength: 8.0,
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF1FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        color: Color(0xFF16155D),
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Enter Start OTP',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1F3E),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Ask the customer for the 6-digit OTP shown on their BharatClap app to begin the service.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black45,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 36),
            // Row of OTP fields (6 digits)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _startOtpControllers[index],
                    focusNode: _startOtpFocusNodes[index],
                    onChanged: (val) => _onStartOtpChanged(index, val),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16155D),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      fillColor: const Color(0xFFF5F6FA),
                      filled: true,
                      contentPadding: EdgeInsets.zero,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF16155D),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _startOtpControllers[index].text.isNotEmpty
                              ? const Color(0xFF16155D)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashedPhotoContainer({
    required String title,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: DashedRectPainter(
            color: isUploaded ? const Color(0xFF0F9D58) : const Color(0xFFC5C9E0),
            strokeWidth: 1.5,
            gap: 5.0,
            strokeLength: 8.0,
            borderRadius: 16.0,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  color: isUploaded ? const Color(0xFF0F9D58) : const Color(0xFF7E7E9A),
                  size: 26,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isUploaded ? const Color(0xFF0F9D58) : const Color(0xFF7E7E9A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2ServiceInProgressView() {
    final user = widget.booking['user_id'] ?? {};
    final userName = user['name'] ?? 'Virat Sharma';
    
    return Expanded(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.access_time_filled,
                          color: Color(0xFF16155D),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '2 hrs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16155D),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Started at 11:00 AM',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Service Breakdown
                _buildSectionHeader('Service Breakdown'),
                _buildCardContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.booking['service_name'] ?? 'Cleaning Service',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1F3E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '60 mins • 1 Service Unit',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${widget.booking['payable_amount'] ?? widget.booking['amount'] ?? 450}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1F3E),
                        ),
                      ),
                    ],
                  ),
                ),

                // Customer Details
                _buildSectionHeader('Customer Details'),
                _buildCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1F3E),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Job ID',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black38,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.booking['booking_id'] ?? '#BC-88241',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16155D),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Color(0xFF0F9D58),
                                  size: 16,
                                ),
                                label: const Text(
                                  'Chat',
                                  style: TextStyle(
                                    color: Color(0xFF0F9D58),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF5F6FA),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.phone_outlined,
                                  color: Color(0xFF16155D),
                                  size: 16,
                                ),
                                label: const Text(
                                  'Call',
                                  style: TextStyle(
                                    color: Color(0xFF16155D),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEFF1FE),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
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

                // Service Photos Section
                _buildSectionHeader('Service Photos'),
                Row(
                  children: [
                    _buildDashedPhotoContainer(
                      title: 'Before Photos',
                      isUploaded: true,
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _buildDashedPhotoContainer(
                      title: 'After Photos',
                      isUploaded: _afterPhotosUploaded,
                      onTap: () {
                        setState(() {
                          _afterPhotosUploaded = !_afterPhotosUploaded;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF0F9D58),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Uploaded',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0F9D58),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _afterPhotosUploaded ? Icons.check_circle : Icons.circle,
                            color: _afterPhotosUploaded ? const Color(0xFF0F9D58) : Colors.black12,
                            size: _afterPhotosUploaded ? 14 : 6,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _afterPhotosUploaded ? 'Uploaded' : 'Pending completion',
                            style: TextStyle(
                              fontSize: 12,
                              color: _afterPhotosUploaded ? const Color(0xFF0F9D58) : Colors.black38,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Sticky Bottom "Complete Job" Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _afterPhotosUploaded
                      ? () async {
                          final success = await ref
                              .read(jobsProvider.notifier)
                              .finishService(widget.booking['_id'], ['https://cloudinary.com/mock-after.jpg']);
                          if (success && mounted) {
                            setState(() {
                              _stepIndex = 3; // Move to entering End OTP
                            });
                          }
                        }
                      : null,
                  icon: Icon(
                    _afterPhotosUploaded ? Icons.check_circle_outline : Icons.lock_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Complete Job',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _afterPhotosUploaded ? const Color(0xFF16155D) : const Color(0xFF7E7E9A),
                    disabledBackgroundColor: const Color(0xFF7E7E9A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3EnterEndOtpView() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: DashedCirclePainter(
                    color: const Color(0xFFC5C9E0),
                    strokeWidth: 1.5,
                    gap: 6.0,
                    dashLength: 8.0,
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF1FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        color: Color(0xFF16155D),
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Enter End OTP',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1F3E),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Ask the customer for the 6-digit OTP shown on their BharatClap app to end the service.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black45,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 36),
            // Row of End OTP fields (6 digits)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _endOtpControllers[index],
                    focusNode: _endOtpFocusNodes[index],
                    onChanged: (val) => _onEndOtpChanged(index, val),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16155D),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      fillColor: const Color(0xFFF5F6FA),
                      filled: true,
                      contentPadding: EdgeInsets.zero,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF16155D),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _endOtpControllers[index].text.isNotEmpty
                              ? const Color(0xFF16155D)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget activeContent;
    if (_stepIndex == 0) {
      activeContent = _buildStep0ArrivedView();
    } else if (_stepIndex == 1) {
      activeContent = _buildStep1EnterStartOtpView();
    } else if (_stepIndex == 2) {
      activeContent = _buildStep2ServiceInProgressView();
    } else {
      activeContent = _buildStep3EnterEndOtpView();
    }

    final String serviceTitle = widget.booking['service_name'] ?? 'Service Details';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF1C1F3E),
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      serviceTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1F3E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            activeContent,
          ],
        ),
      ),
    );
  }
}

// Painters remain same
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;

  DashedCirclePainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    final double circumference = 2 * 3.1415926535 * radius;
    final int dashCount = (circumference / (dashLength + gap)).floor();
    final double sweepAngle = (dashLength / circumference) * 2 * 3.1415926535;
    final double gapAngle = (gap / circumference) * 2 * 3.1415926535;

    const double startAngleOffset = -3.1415926535 / 2;

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = startAngleOffset + i * (sweepAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double strokeLength;
  final double borderRadius;

  DashedRectPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.strokeLength = 6.0,
    this.borderRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = _dashPath(path, gap, strokeLength);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path source, double gap, double dashLength) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashLength : gap;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
