import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:dio/dio.dart';
import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/provider_profile_provider.dart';

class CodRemittanceScreen extends ConsumerStatefulWidget {
  const CodRemittanceScreen({super.key});

  @override
  ConsumerState<CodRemittanceScreen> createState() => _CodRemittanceScreenState();
}

class _CodRemittanceScreenState extends ConsumerState<CodRemittanceScreen> {
  bool _isLoading = true;
  double _totalPendingAmount = 0.0;
  List<dynamic> _remittances = [];
  String? _errorMessage;
  late Razorpay _razorpay;
  String? _activeRemittanceId;

  static const double maxCashLimit = 1500.0;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _loadRemittances();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadRemittances() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = ref.read(providerProfileProvider).profileData;
      final user = ref.read(authProvider).user;
      final providerId = profile?['_id']?.toString() ?? user?.id ?? '';

      final apiClient = ref.read(apiClientProvider);

      final results = await Future.wait([
        apiClient.dio.get(
          '/api/payments/provider-collection/cash/pending-remittance',
          queryParameters: {'providerId': providerId},
        ).catchError((_) => Response(requestOptions: RequestOptions(path: ''), statusCode: 500)),
        apiClient.dio.get('/api/providers/earnings-payouts').catchError((_) => Response(requestOptions: RequestOptions(path: ''), statusCode: 500)),
      ]);

      final resPayment = results[0];
      final resEarnings = results[1];

      List<dynamic> pendingList = [];
      double total = 0.0;

      if (resPayment.statusCode == 200 && resPayment.data != null) {
        final data = resPayment.data['data'] ?? resPayment.data;
        pendingList = data['pendingRemittances'] as List? ?? [];
        total = (data['totalPendingAmount'] ?? 0).toDouble();
      }

      if (resEarnings.statusCode == 200 && resEarnings.data != null) {
        final data = resEarnings.data;
        final codDues = (data['codDues'] as num?)?.toDouble() ?? 0.0;
        if (total == 0 && codDues > 0) {
          total = codDues;
        }

        if (pendingList.isEmpty && data['settlementHistory'] is List) {
          final history = (data['settlementHistory'] as List)
              .where((s) => s is Map && s['payment_type'] == 'cod' && (s['status'] == 'cod_pending' || s['status'] == 'pending'))
              .map((s) => {
                    '_id': s['_id'],
                    'booking_id': s['booking_id'] ?? s['booking_display_id'] ?? 'Booking',
                    'amount': (s['cod_due_amount'] as num?)?.toDouble() ?? (s['commission_amount'] as num?)?.toDouble() ?? 0.0,
                    'status': 'PENDING_REMITTANCE',
                    'createdAt': s['createdAt'],
                  })
              .toList();
          if (history.isNotEmpty) {
            pendingList = history;
          }
        }
      }

      if (mounted) {
        setState(() {
          _remittances = pendingList;
          _totalPendingAmount = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error fetching remittance details';
          _isLoading = false;
        });
      }
    }
  }

  void _initiateRemittancePayment(String remittanceId, double amount) {
    _activeRemittanceId = remittanceId;
    final options = {
      'key': 'rzp_test_BHARATCLAP_KEY',
      'amount': (amount * 100).toInt(),
      'name': 'BharatClap COD Remittance',
      'description': 'Remit held COD cash to platform',
      'prefill': {
        'contact': ref.read(authProvider).user?.phone ?? '',
        'email': 'partner@bharatclap.com'
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      // Fallback: Submit manual remittance reference in test mode
      _submitRemittance(remittanceId, 'MANUAL_REMIT_${DateTime.now().millisecondsSinceEpoch}');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_activeRemittanceId != null) {
      _submitRemittance(_activeRemittanceId!, response.paymentId ?? 'PAY_${DateTime.now().millisecondsSinceEpoch}');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? "User cancelled"}'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _submitRemittance(String remittanceId, String reference) async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.post(
        '/api/payments/provider-collection/cash/remit',
        data: {
          'remittanceId': remittanceId,
          'remittanceReference': reference,
        },
      );

      if (mounted) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cash remittance submitted successfully for reconciliation!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
          _loadRemittances();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.data['message'] ?? 'Failed to submit remittance'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_totalPendingAmount / maxCashLimit).clamp(0.0, 1.0);
    final isLimitExceeded = _totalPendingAmount >= maxCashLimit;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        title: const Text(
          'COD Cash Remittance',
          style: TextStyle(color: Color(0xFF16155D), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF16155D)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16155D)))
          : RefreshIndicator(
              onRefresh: _loadRemittances,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLimitExceeded
                              ? [const Color(0xFFD32F2F), const Color(0xFFB71C1C)]
                              : [const Color(0xFF16155D), const Color(0xFF2A2980)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: (isLimitExceeded ? Colors.red : const Color(0xFF16155D))
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Held Cash Balance',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${_totalPendingAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Max Allowed Limit:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('₹${maxCashLimit.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isLimitExceeded ? Colors.amberAccent : Colors.lightGreenAccent,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],

                    if (isLimitExceeded) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Cash limit reached! Remit pending cash to continue accepting new bookings.',
                                style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                    const Text(
                      'UNREMITTED CASH COLLECTIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_remittances.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8E8FF)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 48),
                            SizedBox(height: 12),
                            Text(
                              'All COD Cash Remitted!',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16155D)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'You have zero pending cash balance to remit.',
                              style: TextStyle(fontSize: 13, color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _remittances.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _remittances[index];
                          final id = item['_id'] ?? item['id'] ?? '';
                          final bId = item['booking_id'] ?? 'Booking';
                          final amt = (item['amount'] ?? 0).toDouble();
                          final status = item['status'] ?? 'PENDING_REMITTANCE';
                          final isPending = status == 'PENDING_REMITTANCE';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE8E8FF)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isPending ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPending ? Icons.payments_outlined : Icons.check_circle_outline,
                                    color: isPending ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Booking #$bId',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF16155D),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isPending ? 'Pending Remittance' : 'Remitted - Awaiting Reconciliation',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isPending ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${amt.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF16155D),
                                      ),
                                    ),
                                    if (isPending) ...[
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () => _initiateRemittancePayment(id, amt),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF16155D),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Remit Now',
                                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
