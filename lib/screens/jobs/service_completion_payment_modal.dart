import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/api_providers.dart';
import '../../providers/jobs_provider.dart';

class ServiceCompletionPaymentModal extends ConsumerStatefulWidget {
  final String bookingId;
  final double amount;
  final String customerName;
  final VoidCallback onPaymentCompleted;

  const ServiceCompletionPaymentModal({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.customerName,
    required this.onPaymentCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required String bookingId,
    required double amount,
    required String customerName,
    required VoidCallback onPaymentCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceCompletionPaymentModal(
        bookingId: bookingId,
        amount: amount,
        customerName: customerName,
        onPaymentCompleted: onPaymentCompleted,
      ),
    );
  }

  @override
  ConsumerState<ServiceCompletionPaymentModal> createState() =>
      _ServiceCompletionPaymentModalState();
}

class _ServiceCompletionPaymentModalState
    extends ConsumerState<ServiceCompletionPaymentModal> {
  int _selectedTab = 0; // 0: UPI QR, 1: Cash
  bool _isLoadingQr = true;
  String? _qrPayload;
  String? _qrError;
  Timer? _statusTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 900; // 15 minutes
  bool _isPaymentSuccess = false;
  bool _isConfirmingCash = false;

  @override
  void initState() {
    super.initState();
    _fetchQrCode();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQrCode() async {
    setState(() {
      _isLoadingQr = true;
      _qrError = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post(
        '/api/bookings/${widget.bookingId}/request-upi',
      );

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          final linkObj = response.data['payment_link'];
          final payload = (linkObj is Map ? linkObj['url'] : null) ??
              response.data['qr_payload'] ??
              response.data['short_url'] ??
              response.data['url'];
          if (payload != null && payload.toString().isNotEmpty) {
            setState(() {
              _qrPayload = payload.toString();
              _isLoadingQr = false;
            });
            _startPollingStatus();
            _startCountdown();
          } else {
            setState(() {
              _qrError = 'Failed to retrieve UPI payment link.';
              _isLoadingQr = false;
            });
          }
        } else {
          setState(() {
            _qrError = response.data['message'] ?? 'Failed to generate UPI QR code.';
            _isLoadingQr = false;
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        final serverMessage = e.response?.data is Map ? e.response?.data['message']?.toString() : null;
        setState(() {
          _qrError = serverMessage ?? 'Network error generating UPI QR code.';
          _isLoadingQr = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _qrError = 'Failed to generate QR code: $e';
          _isLoadingQr = false;
        });
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        timer.cancel();
        _statusTimer?.cancel();
      }
    });
  }

  void _startPollingStatus() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final apiClient = ref.read(apiClientProvider);
        final res = await apiClient.dio.get(
          '/api/bookings/${widget.bookingId}/payment-collection',
        );

        if (mounted && res.statusCode == 200) {
          final pc = res.data['payment_collection'];
          final bookingStatus = res.data['status']?.toString().toLowerCase();
          final pcStatus = (pc != null && pc is Map ? pc['status'] : null)?.toString().toLowerCase();

          if (pcStatus == 'upi_completed' || pcStatus == 'verified' || pcStatus == 'cash_collected' || bookingStatus == 'completed') {
            timer.cancel();
            _countdownTimer?.cancel();
            setState(() {
              _isPaymentSuccess = true;
            });

            await Future.delayed(const Duration(milliseconds: 1500));
            if (mounted) {
              Navigator.pop(context);
              widget.onPaymentCompleted();
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _handleConfirmCash() async {
    setState(() {
      _isConfirmingCash = true;
    });

    try {
      final success = await ref.read(jobsProvider.notifier).collectCash(widget.bookingId);

      if (mounted) {
        setState(() {
          _isConfirmingCash = false;
        });

        if (success) {
          Navigator.pop(context);
          widget.onPaymentCompleted();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to record cash payment. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isConfirmingCash = false;
        });
        Navigator.pop(context);
        widget.onPaymentCompleted();
      }
    }
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            if (_isPaymentSuccess) ...[
              const SizedBox(height: 20),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 72),
              const SizedBox(height: 12),
              const Text(
                'Payment Received!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16155D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${widget.amount.toStringAsFixed(2)} confirmed via Razorpay UPI',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collect Service Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16155D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Customer: ${widget.customerName}',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF1FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹${widget.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF16155D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Segmented Control Tabs
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 18,
                                color: _selectedTab == 0
                                    ? const Color(0xFF16155D)
                                    : Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Razorpay UPI QR',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTab == 0
                                      ? const Color(0xFF16155D)
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                size: 18,
                                color: _selectedTab == 1
                                    ? const Color(0xFFE65100)
                                    : Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Cash On-Site',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTab == 1
                                      ? const Color(0xFFE65100)
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_selectedTab == 0) ...[
                // UPI QR View
                if (_isLoadingQr) ...[
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16155D)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Generating dynamic Razorpay UPI QR...',
                      style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 40),
                ] else if (_qrError != null) ...[
                  const SizedBox(height: 20),
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                  const SizedBox(height: 10),
                  Text(_qrError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.redAccent)),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _fetchQrCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16155D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Retry QR', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                ] else if (_qrPayload != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8E8FF), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _qrPayload!,
                      version: QrVersions.auto,
                      size: 200.0,
                      gapless: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        'QR expires in ${_formatTimer(_secondsRemaining)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_moon_outlined, size: 16, color: Color(0xFF16155D)),
                        SizedBox(width: 6),
                        Text(
                          'Ask customer to scan with Google Pay / PhonePe / Paytm',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16155D)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16155D))),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Waiting for customer payment confirmation...',
                        style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                // Cash View
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.payments_rounded, color: Color(0xFFE65100), size: 40),
                      const SizedBox(height: 10),
                      Text(
                        'Collect ₹${widget.amount.toStringAsFixed(0)} Cash On-Site',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFBF360C)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Confirm only after receiving cash in hand from the customer.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isConfirmingCash ? null : _handleConfirmCash,
                    icon: _isConfirmingCash
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: Text(
                      'Confirm ₹${widget.amount.toStringAsFixed(0)} Cash Received',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
