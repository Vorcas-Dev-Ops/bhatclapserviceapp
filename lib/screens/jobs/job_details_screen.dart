import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:partner_app/providers/job_dispatch_provider.dart';
import 'package:partner_app/providers/jobs_provider.dart';
import 'package:partner_app/utils/address_utils.dart';
import 'package:partner_app/screens/chat/partner_chat_screen.dart';
import 'package:partner_app/screens/jobs/service_completion_payment_modal.dart';

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
  bool _isJobUnavailable = false;

  bool _isQrGenerated = false;
  String? _qrUrl;
  bool _checkingStatus = false;
  Timer? _statusTimer;

  bool get _isCancelledOrExpired {
    final status = (_getVal('status') ?? '').toString().toLowerCase().trim();
    return _isJobUnavailable ||
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'expired' ||
        status == 'expired_timeout' ||
        status == 'unassigned_timeout' ||
        status == 'high_demand_timeout' ||
        status == 'rejected' ||
        status == 'failed';
  }

  bool get _isUnaccepted {
    if (widget.isNewJob) return true;
    final status = (_getVal('status') ?? '').toString().toLowerCase().trim();
    if (status == 'pending' || status == 'provider_searching' || status == 'new' || status.isEmpty) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    if (widget.booking == null && widget.bookingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBookingById();
      });
    } else if (!_isUnaccepted && widget.booking != null) {
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
    } else if (status == 'waiting_end_otp' || status == 'service_completed' || status == 'completed') {
      final isCOD = _isCOD();
      final pc = _getVal('payment_collection');
      final pcStatus = (pc != null && pc is Map) ? (pc['status'] ?? '').toString().toLowerCase() : '';
      final pStatus = (_getVal('payment_status') ?? '').toString().toLowerCase();

      if (isCOD && pcStatus != 'cash_collected' && pcStatus != 'upi_completed' && pStatus != 'paid' && pStatus != 'completed') {
        _stepIndex = 3; // Move to COD Payment Collection only if payment is NOT yet collected
      } else {
        _stepIndex = 4; // Move directly to Enter End OTP
      }
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
    _statusTimer?.cancel();
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
      final isCOD = _isCOD();
      final pc = _getVal('payment_collection');
      final pcStatus = (pc != null && pc is Map) ? (pc['status'] ?? '').toString().toLowerCase() : '';
      final pStatus = (_getVal('payment_status') ?? '').toString().toLowerCase();

      if (isCOD && pcStatus != 'cash_collected' && pcStatus != 'upi_completed' && pStatus != 'paid' && pStatus != 'completed') {
        _showCodCashCollectionDialog(() {
          _showCompletionDialog();
        });
      } else {
        _showCompletionDialog();
      }
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

    final rawAmount = _getVal('payable_amount') ?? _getVal('amount') ?? 450;
    final double amount = (rawAmount is num) ? rawAmount.toDouble() : (double.tryParse(rawAmount.toString()) ?? 450.0);
    final bookingId = (_getVal('_id') ?? _getVal('booking_id') ?? '').toString();
    final customerName = _getCustomerName();

    ServiceCompletionPaymentModal.show(
      context,
      bookingId: bookingId,
      amount: amount,
      customerName: customerName,
      onPaymentCompleted: onConfirmed,
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

  Widget _buildTravelBufferCard() {
    final rawTravel = _getVal('travel_minutes') ?? _getVal('travel_time') ?? 5;
    final rawBuffer = _getVal('safety_buffer_minutes') ?? _getVal('buffer_minutes') ?? 10;
    final int travelMins = (rawTravel is num) ? rawTravel.toInt() : (int.tryParse(rawTravel.toString()) ?? 5);
    final int bufferMins = (rawBuffer is num) ? rawBuffer.toInt() : (int.tryParse(rawBuffer.toString()) ?? 10);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC5CAE9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF16155D),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Travel ($travelMins mins) + Prep Buffer ($bufferMins mins)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16155D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sequential schedule buffer calculated via live OSRM navigation.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final bId = (_getVal('booking_id') ?? _getVal('display_id') ?? _getVal('_id') ?? _getVal('id'))?.toString();
                                  if (bId != null && bId.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PartnerChatScreen(
                                          bookingId: bId,
                                          customerName: userName,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF16155D),
                                  size: 18,
                                ),
                                label: const Text(
                                  'Chat',
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _makePhoneCall,
                                icon: const Icon(
                                  Icons.phone_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Call',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16155D),
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
                _buildTravelBufferCard(),
                _buildCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          if (_acceptedSubStep == 0 && !_isUnaccepted) {
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
                child: _buildBottomActionButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton() {
    if (_isCancelledOrExpired) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'This job is no longer available',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      );
    }

    if (_isUnaccepted) {
      return ElevatedButton(
        onPressed: () async {
          final reqId = (_getVal('requestId') ?? _getVal('request_id') ?? _getVal('_id') ?? widget.bookingId)?.toString() ?? '';
          bool success = await ref.read(jobDispatchProvider.notifier).acceptJob(reqId);
          if (!success) {
            success = await ref.read(jobsProvider.notifier).acceptJob(reqId);
          }
          if (mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Job accepted successfully!'),
                  backgroundColor: Color(0xFF2E7D32),
                ),
              );
              await ref.read(jobsProvider.notifier).fetchAllJobs();
              if (!mounted) return;
              Navigator.pop(context);
            } else {
              final err = ref.read(jobDispatchProvider).error ?? ref.read(jobsProvider).errorMessage ?? 'Request is no longer valid or has already been processed';
              setState(() {
                _isJobUnavailable = true;
              });
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
      );
    }

    final addressLine = _getVal('address_id')?['address_line'] ?? '';
    final city = _getVal('address_id')?['city'] ?? '';

    if (_acceptedSubStep == 0) {
      return ElevatedButton.icon(
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
      );
    }

    if (_acceptedSubStep == 1) {
      return ElevatedButton.icon(
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
      );
    }

    return ElevatedButton.icon(
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
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () async {
                final bId = _getVal('_id');
                final success = await ref.read(jobsProvider.notifier).resendOtp(bId, 'start');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Resent Start OTP to customer\'s mobile number!' : 'Failed to resend OTP'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send_to_mobile, size: 16, color: Color(0xFF16155D)),
              label: const Text(
                'Resend Start OTP to Customer',
                style: TextStyle(
                  color: Color(0xFF16155D),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
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
                  onPressed: () async {
                    final afterPhotosToSend = ['data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='];
                    await ref
                        .read(jobsProvider.notifier)
                        .finishService(_getVal('_id'), afterPhotosToSend);
                    if (mounted) {
                      setState(() {
                        _stepIndex = 4; // Move directly to Enter End OTP (Step 4)
                      });
                    }
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
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () async {
                final bId = _getVal('_id');
                final success = await ref.read(jobsProvider.notifier).resendOtp(bId, 'end');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Resent Completion OTP to customer\'s mobile number!' : 'Failed to resend OTP'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send_to_mobile, size: 16, color: Color(0xFF16155D)),
              label: const Text(
                'Resend Completion OTP to Customer',
                style: TextStyle(color: Color(0xFF16155D), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4PaymentCollectionView() {
    final amount = _getVal('payable_amount') ?? _getVal('amount') ?? 450;

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.payments_outlined, color: Color(0xFFE65100), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'COD PAYMENT COLLECTION',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Collect ₹$amount from the customer to complete this job.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (!_isQrGenerated) ...[
              // Option 1: QR Payment
              ElevatedButton.icon(
                onPressed: () {
                  final rawAmount = _getVal('payable_amount') ?? _getVal('amount') ?? 450;
                  final double amount = (rawAmount is num) ? rawAmount.toDouble() : (double.tryParse(rawAmount.toString()) ?? 450.0);
                  final bId = (_getVal('_id') ?? _getVal('booking_id') ?? widget.bookingId ?? '').toString();
                  final customerName = _getCustomerName();

                  ServiceCompletionPaymentModal.show(
                    context,
                    bookingId: bId,
                    amount: amount,
                    customerName: customerName,
                    onPaymentCompleted: () {
                      if (mounted) {
                        setState(() {
                          _stepIndex = 4; // Move to Enter End OTP
                        });
                      }
                    },
                  );
                },
                icon: const Icon(Icons.qr_code_2, color: Colors.white),
                label: const Text('Generate UPI QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16155D),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 16),
              // Option 2: Collect Cash
              ElevatedButton.icon(
                onPressed: () {
                  final rawAmount = _getVal('payable_amount') ?? _getVal('amount') ?? 450;
                  final double amount = (rawAmount is num) ? rawAmount.toDouble() : (double.tryParse(rawAmount.toString()) ?? 450.0);
                  final bId = (_getVal('_id') ?? _getVal('booking_id') ?? widget.bookingId ?? '').toString();
                  final customerName = _getCustomerName();

                  ServiceCompletionPaymentModal.show(
                    context,
                    bookingId: bId,
                    amount: amount,
                    customerName: customerName,
                    onPaymentCompleted: () {
                      if (mounted) {
                        setState(() {
                          _stepIndex = 4; // Move to Enter End OTP
                        });
                      }
                    },
                  );
                },
                icon: const Icon(Icons.money, color: Colors.white),
                label: const Text('Cash Collected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ] else ...[
              // QR Code is generated
              const Text(
                'Scan QR to Pay via UPI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.network(
                  _qrUrl!,
                  width: 200,
                  height: 200,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: Icon(Icons.qr_code, size: 80, color: Colors.grey)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16155D)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Awaiting customer payment...',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Check Payment Status manual check button
              OutlinedButton.icon(
                onPressed: _checkPaymentStatus,
                icon: _checkingStatus
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 16),
                label: const Text('Check Payment Status'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16155D),
                  side: const BorderSide(color: Color(0xFF16155D)),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              // Back to options
              TextButton(
                onPressed: () {
                  _statusTimer?.cancel();
                  setState(() {
                    _isQrGenerated = false;
                    _qrUrl = null;
                  });
                },
                child: const Text('Change Payment Method', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startPaymentPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_checkingStatus) return;
    final bookingId = _getVal('_id');
    setState(() {
      _checkingStatus = true;
    });

    final res = await ref.read(jobsProvider.notifier).getPaymentCollection(bookingId);
    setState(() {
      _checkingStatus = false;
    });

    if (res != null) {
      final pc = res['payment_collection'];
      final bookingStatus = res['status']?.toString().toLowerCase();
      final pcStatus = pc?['status']?.toString().toLowerCase();

      if (pcStatus == 'upi_completed' || pcStatus == 'verified') {
        _statusTimer?.cancel();
        if (mounted) {
          setState(() {
            _stepIndex = 4; // Move to Enter End OTP (Step 4)
          });
        }
      } else if (bookingStatus == 'completed') {
        _statusTimer?.cancel();
        if (mounted) {
          _showCompletionDialog();
        }
      }
    }
  }

  void _showConfirmCashDialog(String bookingId) {
    final amount = _getVal('payable_amount') ?? _getVal('amount') ?? 450;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Cash Collection', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you have collected ₹$amount in cash from the customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _checkingStatus = true;
              });
              final success = await ref.read(jobsProvider.notifier).collectCash(bookingId);
              setState(() {
                _checkingStatus = false;
              });
              if (success && mounted) {
                setState(() {
                  _stepIndex = 4; // Move to Enter End OTP (Step 4)
                });
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to confirm cash collection. Please try again.'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Yes, Collected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
    } else if (_stepIndex == 3) {
      activeContent = _buildStep4PaymentCollectionView(); // Step 3: COD Payment Collection
    } else {
      activeContent = _buildStep3EnterEndOtpView(); // Step 4: Enter End OTP
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
