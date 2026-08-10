import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:partner_app/providers/job_dispatch_provider.dart';
import 'package:partner_app/providers/jobs_provider.dart';
import 'package:partner_app/utils/address_utils.dart';

class JobDetailsScreen extends ConsumerStatefulWidget {
  final dynamic booking;
  final String? bookingId;
  final bool isNewJob;
  const JobDetailsScreen({super.key, this.booking, this.bookingId, this.isNewJob = false});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  dynamic _loadedBooking;
  // Screen steps: 0 -> Main Job Details, 1 -> Enter Start OTP, 2 -> Service in Progress, 3 -> Enter End OTP
  int _stepIndex = 0;
  // Sub-steps for accepted job on Main Job Details screen (Step 0):
  // 0 -> Leaving for Service
  // 1 -> Arrived at Location
  // 2 -> Start Service
  int _acceptedSubStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.booking == null && widget.bookingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBookingById();
      });
    } else if (!widget.isNewJob && widget.booking != null) {
      _syncStatusStep();
    }
  }

  void _syncStatusStep() {
    final status = _getVal('status');
    if (status == 'accepted' || status == 'assigned' || status == 'confirmed') {
      _stepIndex = 0;
      _acceptedSubStep = 0;
    } else if (status == 'on_the_way') {
      _stepIndex = 0;
      _acceptedSubStep = 1;
    } else if (status == 'arrived' || status == 'reached') {
      _stepIndex = 0;
      _acceptedSubStep = 2;
    } else if (status == 'waiting_start_otp') {
      _stepIndex = 1;
    } else if (status == 'in_progress') {
      _stepIndex = 2;
    } else if (status == 'waiting_end_otp') {
      _stepIndex = 3;
    }
  }

  void _loadBookingById() {
    final jobs = ref.read(jobsProvider).bookings;
    final match = jobs.firstWhere(
      (j) => (j is Map && (j['_id']?.toString() == widget.bookingId || j['booking_id']?.toString() == widget.bookingId)),
      orElse: () => null,
    );
    if (match != null && mounted) {
      setState(() {
        _loadedBooking = match;
        _syncStatusStep();
      });
    }
  }

  dynamic _getVal(String key) {
    final b = widget.booking ?? _loadedBooking;
    if (b == null) {
      if (key == '_id' || key == 'booking_id' || key == 'requestId' || key == 'request_id') return widget.bookingId;
      return null;
    }
    if (b is JobRequestModel) {
      if (key == 'requestId' || key == 'request_id') return b.requestId;
      if (key == '_id') return b.bookingId;
      if (key == 'booking_id') return b.displayId.isNotEmpty ? b.displayId : b.bookingId;
      if (key == 'service_name') return b.serviceName;
      if (key == 'amount' || key == 'payable_amount') return b.amount;
      if (key == 'scheduled_at') return b.scheduledAt;
      if (key == 'booking_time') return b.bookingTime;
      if (key == 'address_id') {
        return {
          'address_line': b.address,
          'city': b.city,
          'pincode': b.pincode,
        };
      }
      if (key == 'user_id') {
        return {
          'name': 'Customer',
        };
      }
      if (key == 'status') return 'pending';
      return null;
    }
    if (b is Map) {
      if (key == 'requestId' || key == 'request_id') {
        return b['requestId'] ?? b['request_id'] ?? b['_id'];
      }
      if (key == '_id') {
        return b['_id'] ?? b['booking_id'] ?? b['id'];
      }
      if (key == 'booking_id') {
        return b['booking_id'] ?? b['display_id'] ?? b['_id'];
      }
      return b[key];
    }
    return null;
  }

  // Start OTP inputs state (6 digits)
  final List<TextEditingController> _startOtpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _startOtpFocusNodes = List.generate(6, (_) => FocusNode());

  // End OTP inputs state (6 digits)
  final List<TextEditingController> _endOtpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _endOtpFocusNodes = List.generate(6, (_) => FocusNode());

  // Photos state (Base64 strings)
  final List<String> _beforePhotos = [];
  final List<String> _afterPhotos = [];
  bool _afterPhotosUploaded = false;

  String _getCustomerName() {
    final user = _getVal('user_id') ?? _getVal('customer');
    if (user != null && user is Map) {
      final n = user['name'] ?? user['fullName'] ?? user['phone'];
      if (n != null && n.toString().isNotEmpty) return n.toString();
    }
    final address = _getVal('address_id');
    if (address != null && address is Map) {
      final name = address['name'];
      if (name != null && name.toString().isNotEmpty) return name.toString();
    }
    return 'Customer';
  }

  String _getCustomerPhone() {
    final user = _getVal('user_id') ?? _getVal('customer');
    if (user != null && user is Map) {
      final p = user['phone'] ?? user['mobile'];
      if (p != null && p.toString().isNotEmpty) return p.toString();
    }
    final address = _getVal('address_id');
    if (address != null && address is Map) {
      final phone = address['phone'];
      if (phone != null && phone.toString().isNotEmpty) return phone.toString();
    }
    return '';
  }

  Future<void> _openGoogleMaps(String fullAddress) async {
    final cleanAddress = fullAddress.trim();
    if (cleanAddress.isEmpty) return;

    final addressObj = _getVal('address_id');
    String query = cleanAddress;
    if (addressObj is Map && addressObj['latitude'] != null && addressObj['longitude'] != null) {
      final lat = addressObj['latitude'];
      final lng = addressObj['longitude'];
      query = '$lat,$lng';
    }

    final encodedQuery = Uri.encodeComponent(query);
    final httpsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedQuery');
    final geoUrl = Uri.parse('geo:0,0?q=$encodedQuery');

    try {
      final launched = await launchUrl(httpsUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(httpsUrl, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please perform a full app restart/rebuild to register map plugin.'),
              backgroundColor: Color(0xFF16155D),
            ),
          );
        }
      }
    }
  }

  Future<void> _makePhoneCall() async {
    final phone = _getCustomerPhone();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer phone number unavailable'),
          backgroundColor: Color(0xFF16155D),
        ),
      );
      return;
    }
    final telUrl = Uri(scheme: 'tel', path: phone.trim());
    try {
      if (await canLaunchUrl(telUrl)) {
        await launchUrl(telUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling customer: $phone'),
              backgroundColor: const Color(0xFF16155D),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling customer: $phone'),
            backgroundColor: const Color(0xFF16155D),
          ),
        );
      }
    }
  }

  void _openChat() {
    final name = _getCustomerName();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with $name'),
        backgroundColor: const Color(0xFF0F9D58),
      ),
    );
  }

  Future<void> _pickPhoto({required bool isBefore}) async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 60);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          if (isBefore) {
            _beforePhotos.add(base64Image);
          } else {
            _afterPhotos.add(base64Image);
            _afterPhotosUploaded = _afterPhotos.isNotEmpty;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching camera: $e')),
        );
      }
    }
  }

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
    final bookingId = _getVal('_id');
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
    final bookingId = _getVal('_id');
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCOD() {
    final method = (_getVal('payment_method') ?? _getVal('payment_type') ?? _getVal('paymentMethod') ?? '').toString().toLowerCase();
    final pStatus = (_getVal('payment_status') ?? _getVal('paymentStatus') ?? '').toString().toLowerCase();

    if (method == 'cod' || method == 'cash' || method == 'cash_on_delivery' || method.contains('cod')) {
      return true;
    }
    if (method == 'online' || method == 'razorpay' || method == 'upi' || method == 'card' || pStatus == 'paid' || pStatus == 'completed') {
      return false;
    }
    return pStatus != 'paid' && pStatus != 'completed';
  }

  Widget _buildPaymentStatusSection() {
    final isCOD = _isCOD();
    final amount = _getVal('payable_amount') ?? _getVal('amount') ?? 450;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCOD ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCOD ? const Color(0xFFFFB74D) : const Color(0xFF81C784),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isCOD ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                    color: isCOD ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCOD ? 'COD - CASH TO COLLECT' : 'ONLINE PAID',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isCOD ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCOD ? const Color(0xFFEF6C00) : const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCOD ? 'COLLECT ₹$amount CASH' : 'NO CASH NEEDED',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isCOD
                ? '⚠️ REMINDER: Collect ₹$amount in cash from the customer before ending the service.'
                : '✅ Customer has already paid ₹$amount online. Do NOT collect any cash.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isCOD ? const Color(0xFFBF360C) : const Color(0xFF1B5E20),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showCodCashCollectionDialog(VoidCallback onConfirmed) {
    if (!_isCOD()) {
      onConfirmed();
      return;
    }

    final amount = _getVal('payable_amount') ?? _getVal('amount') ?? 450;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.payments_outlined, color: Color(0xFFE65100)),
              SizedBox(width: 8),
              Text('Collect Cash (COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This booking is Cash on Delivery (COD).',
                style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Have you collected ₹$amount in cash from the customer?',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFBF360C)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onConfirmed();
              },
              icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              label: Text('Yes, Collected ₹$amount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
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
    final address = _getVal('address_id') ?? {};
    final addressLine = address['address_line'] ?? 'No 48, 5th Cross, Hennur Rd';
    final city = address['city'] ?? 'Bengaluru';
    final dateVal = _formatDateVal(_getVal('scheduled_at'));
    final timeVal = _getVal('booking_time') ?? 'Now';
    
    final userName = _getCustomerName();

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
                                _getVal('booking_id') ?? '#BC-88241',
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
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _makePhoneCall,
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
                    ],
                  ),
                ),
                _buildCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          if (_acceptedSubStep == 0 && !widget.isNewJob) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please tap "Leaving for Service" to start navigation.'),
                                backgroundColor: Color(0xFF16155D),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          _openGoogleMaps('$addressLine, $city');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF16155D), Color(0xFF28277D)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF16155D).withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.near_me_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatAddress(addressLine, city: city),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF1C1F3E),
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.directions_outlined,
                                          size: 13,
                                          color: Color(0xFF4285F4),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Tap to navigate in Google Maps',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF4285F4),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF4285F4),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
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
                            _getVal('service_name') ?? 'Cleaning Service',
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
                        '₹${_getVal('payable_amount') ?? _getVal('amount') ?? 450}',
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
                            '₹${_getVal('payable_amount') ?? _getVal('amount') ?? 450}',
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
                            '₹${((_getVal('payable_amount') ?? _getVal('amount') ?? 450) * 0.2).toStringAsFixed(0)}',
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
                            '₹${((_getVal('payable_amount') ?? _getVal('amount') ?? 450) * 0.8).toStringAsFixed(0)}',
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
                _buildPaymentStatusSection(),
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
                          final reqId = (_getVal('requestId') ?? _getVal('request_id') ?? _getVal('_id'))?.toString() ?? '';
                          final success = await ref
                              .read(jobsProvider.notifier)
                              .acceptJob(reqId);
                          if (mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Job accepted successfully!'),
                                  backgroundColor: Color(0xFF2E7D32),
                                ),
                              );
                              Navigator.pop(context);
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
                    : (_acceptedSubStep == 0
                        ? ElevatedButton.icon(
                            onPressed: () async {
                              final bookingId = _getVal('_id')?.toString();
                              if (bookingId != null) {
                                ref.read(jobsProvider.notifier).updateBookingStatus(bookingId, 'on_the_way');
                              }
                              setState(() {
                                _acceptedSubStep = 1;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('On the way! Opening Google Maps...'),
                                  backgroundColor: Color(0xFF16155D),
                                ),
                              );
                              _openGoogleMaps('$addressLine, $city');
                            },
                            icon: const Icon(
                              Icons.directions_car_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              'Leaving for Service',
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
                          )
                        : (_acceptedSubStep == 1
                            ? ElevatedButton.icon(
                                onPressed: () async {
                                  final bookingId = _getVal('_id')?.toString();
                                  if (bookingId != null) {
                                    ref.read(jobsProvider.notifier).updateBookingStatus(bookingId, 'arrived');
                                  }
                                  setState(() {
                                    _acceptedSubStep = 2;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Arrived at location! Tap Start Service when ready.'),
                                      backgroundColor: Color(0xFF2E7D32),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.location_on_outlined,
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
                              )
                            : ElevatedButton.icon(
                                onPressed: () async {
                                  final beforePhotosToSend = _beforePhotos.isNotEmpty
                                      ? _beforePhotos
                                      : ['data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='];
                                  final success = await ref
                                      .read(jobsProvider.notifier)
                                      .startService(_getVal('_id'), beforePhotosToSend);
                                  if (success && mounted) {
                                    setState(() {
                                      _stepIndex = 1;
                                    });
                                  }
                                },
                                icon: const Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Start Service',
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
                              ))),
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
    final userName = _getCustomerName();
    
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
                            _getVal('service_name') ?? 'Cleaning Service',
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
                        '₹${_getVal('payable_amount') ?? _getVal('amount') ?? 450}',
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
                                _getVal('booking_id') ?? '#BC-88241',
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
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _makePhoneCall,
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
                    ],
                  ),
                ),

                _buildPaymentStatusSection(),
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
                  onPressed: () {
                    _showCodCashCollectionDialog(() async {
                      final afterPhotosToSend = ['data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='];
                      final success = await ref
                          .read(jobsProvider.notifier)
                          .finishService(_getVal('_id'), afterPhotosToSend);
                      if (success && mounted) {
                        setState(() {
                          _stepIndex = 3; // Move to entering End OTP
                        });
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.check_circle_outline,
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

    final String serviceTitle = _getVal('service_name') ?? 'Service Details';

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
