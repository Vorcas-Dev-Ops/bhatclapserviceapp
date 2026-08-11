import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/wallet_provider.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/providers/api_providers.dart';
import 'package:partner_app/screens/finance/credits_screen.dart';
import 'package:partner_app/screens/auth/bank_details_screen.dart';
import 'package:partner_app/screens/notifications/notifications_screen.dart';
import 'package:partner_app/screens/profile/subscription_screen.dart';
import 'package:partner_app/providers/notification_provider.dart';
import 'package:partner_app/screens/leads/lead_marketplace_screen.dart';
import 'package:partner_app/widgets/razorpay_gateway_modal.dart';

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _earningsData;
  List<dynamic> _settlements = [];
  double _todayEarnings = 0.0;
  int _todayJobs = 0;
  double _monthEarnings = 0.0;
  int _monthJobs = 0;
  double _netEarningsTotal = 0.0;
  double _serviceValueTotal = 0.0;
  double _commissionTotal = 0.0;
  double _gstTotal = 0.0;
  double _codDueBalance = 0.0;
  bool _isRemittingCod = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await Future.wait([
        ref.read(walletProvider.notifier).fetchWalletAndReviews(),
        ref.read(providerProfileProvider.notifier).fetchProfile(),
      ]);

      try {
        final res = await apiClient.dio.get('/api/providers/earnings-payouts');
        if (res.statusCode == 200) {
          final data = res.data;
          _earningsData = data;
          _codDueBalance = (data['codDues'] as num?)?.toDouble() ?? 0.0;
          _settlements = data['settlementHistory'] is List ? data['settlementHistory'] : [];
        }
      } catch (_) {}

      final walletState = ref.read(walletProvider);
      final activeList = _settlements.isNotEmpty ? _settlements : walletState.transactions;
      _calculateAnalytics(activeList);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateAnalytics(List<dynamic> items) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    double todayNet = 0.0;
    int todayCount = 0;
    double monthNet = 0.0;
    int monthCount = 0;
    double netTotal = 0.0;
    double grossTotal = 0.0;
    double commTotal = 0.0;
    double gstSum = 0.0;

    for (var s in items) {
      if (s is! Map) continue;
      final status = (s['status'] ?? '').toString().toLowerCase();
      
      // Skip explicitly failed/cancelled items
      if (status == 'failed' || status == 'cancelled' || status == 'rejected') {
        continue;
      }

      final double rawAmount = (s['net_payable_amount'] as num?)?.toDouble() ?? 
                               (s['gross_amount'] as num?)?.toDouble() ?? 
                               (s['amount'] as num?)?.toDouble() ?? 
                               (s['payable_amount'] as num?)?.toDouble() ?? 0.0;
      
      if (rawAmount <= 0) continue;

      final gross = (s['gross_amount'] as num?)?.toDouble() ?? rawAmount;
      final comm = (s['commission_amount'] as num?)?.toDouble() ?? (gross * 0.10);
      final gst = (s['gst_on_commission'] as num?)?.toDouble() ?? (comm * 0.18);
      final net = (s['net_payable_amount'] as num?)?.toDouble() ?? (gross - comm - gst);

      final createdAtRaw = s['createdAt']?.toString() ?? s['created_at']?.toString() ?? s['timestamp']?.toString();
      final dt = createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;

      netTotal += net;
      grossTotal += gross;
      commTotal += comm;
      gstSum += gst;

      if (dt != null) {
        if (dt.isAfter(startOfToday) || dt.isAtSameMomentAs(startOfToday)) {
          todayNet += net;
          todayCount++;
        }
        if (dt.isAfter(startOfMonth) || dt.isAtSameMomentAs(startOfMonth)) {
          monthNet += net;
          monthCount++;
        }
      } else {
        // Fallback when date string is missing
        todayNet += net;
        todayCount++;
        monthNet += net;
        monthCount++;
      }
    }

    _todayEarnings = todayNet;
    _todayJobs = todayCount;
    _monthEarnings = monthNet;
    _monthJobs = monthCount;
    _netEarningsTotal = netTotal;
    _serviceValueTotal = grossTotal;
    _commissionTotal = commTotal;
    _gstTotal = gstSum;
  }

  Future<void> _handleRemitCOD() async {
    if (_codDueBalance <= 0 || _isRemittingCod) return;

    setState(() => _isRemittingCod = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.post('/api/providers/wallet/remit-cod', data: {
        'amount': _codDueBalance,
      });

      if (mounted && (res.statusCode == 200 || res.statusCode == 201)) {
        final data = res.data;
        if (data['method'] == 'wallet') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'COD dues remitted successfully using wallet credit!'), backgroundColor: Colors.green),
          );
          _fetchData();
          return;
        }

        if (data['method'] == 'online' && data['razorpayOrder'] != null) {
          final rzpOrder = data['razorpayOrder'];
          final orderId = rzpOrder['id']?.toString() ?? '';
          final keyId = data['key_id']?.toString() ?? 'rzp_test_mock';
          final amount = (data['amount'] as num?)?.toDouble() ?? _codDueBalance;

          final paymentResult = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: Colors.transparent,
            builder: (context) => PartnerRazorpayGatewayModalSheet(
              orderId: orderId,
              keyId: keyId,
              amount: amount,
              title: 'COD Dues Remittance',
            ),
          );

          if (paymentResult != null && paymentResult['success'] == true && mounted) {
            final paymentId = paymentResult['razorpay_payment_id'] ?? paymentResult['payment_id'];
            final signature = paymentResult['razorpay_signature'] ?? paymentResult['signature'];

            final verifyRes = await apiClient.dio.post('/api/providers/wallet/remit-cod/verify', data: {
              'razorpay_order_id': orderId,
              'razorpay_payment_id': paymentId,
              'razorpay_signature': signature,
              'amount': amount,
            });

            if (verifyRes.statusCode == 200 && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('COD dues remitted successfully! Lead dispatch unblocked.'), backgroundColor: Colors.green),
              );
              _fetchData();
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process COD remittance: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRemittingCod = false);
    }
  }

  void _showTransactionDetailsSheet(Map<String, dynamic> tx) {
    final double amt = (tx['net_payable_amount'] as num?)?.toDouble() ?? (tx['gross_amount'] as num?)?.toDouble() ?? (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final gross = (tx['gross_amount'] as num?)?.toDouble();
    final comm = (tx['commission_amount'] as num?)?.toDouble();
    final type = (tx['payment_type'] ?? tx['type'] ?? 'online').toString();
    final desc = tx['booking_id'] != null ? 'Booking #${tx['booking_id']}' : (tx['description'] ?? 'Job Settlement').toString();
    final status = (tx['status'] ?? 'paid').toString();
    final createdAtRaw = tx['createdAt']?.toString();
    final createdAt = createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;
    final dateString = createdAt != null
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
        : 'Recent';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Settlement Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'paid' || status == 'cod_settled' ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: status == 'paid' || status == 'cod_settled' ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '+₹${amt.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                desc,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            if (gross != null) _buildDetailRow('Gross Service Value', '₹${gross.toStringAsFixed(2)}'),
            if (comm != null) _buildDetailRow('Platform Fee (10%)', '-₹${comm.toStringAsFixed(2)}'),
            _buildDetailRow('Net Earnings', '₹${amt.toStringAsFixed(2)}'),
            _buildDetailRow('Payment Mode', type.toUpperCase()),
            _buildDetailRow('Date', dateString),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E))),
        ],
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

  Widget _buildTopBar(int credits, int leadCount) {
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
                'Money',
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreditsScreen()),
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
                        credits.toString(),
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
                    if (ref.watch(notificationProvider).unreadCount > 0)
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

  // Top Earnings & Direct Settlement Card (Replacing Manual Withdraw Card)
  Widget _buildEarningsSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16155D),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Settlement Earnings',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6EE7B7), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bolt, color: Color(0xFF34D399), size: 12),
                      SizedBox(width: 3),
                      Text(
                        'Direct Bank Payout',
                        style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${_netEarningsTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'All completed job earnings are automatically settled directly to your verified bank account.',
              style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountCard(Map<String, dynamic>? bankDetails) {
    final hasBank = bankDetails != null && bankDetails['bank_name'] != null && bankDetails['bank_name'].toString().isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF1FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                color: Color(0xFF16155D),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Linked Bank Account',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1F3E),
                        ),
                      ),
                      if (hasBank) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.verified, size: 10, color: Colors.green),
                              SizedBox(width: 2),
                              Text('Verified', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasBank
                        ? '${bankDetails['bank_name']} •••• ${bankDetails['account_number']?.toString().substring((bankDetails['account_number']?.toString().length ?? 4) - 4) ?? '****'}'
                        : 'No bank account linked',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasBank ? Colors.black54 : Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BankDetailsScreen(isEditing: true)),
                ).then((_) {
                  _fetchData();
                });
              },
              child: Text(
                hasBank ? 'Edit' : 'Link',
                style: const TextStyle(
                  color: Color(0xFF16155D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Outstanding COD Dues Banner (If provider collected cash)
  Widget _buildCodDuesBanner() {
    if (_codDueBalance <= 0) return const SizedBox.shrink();

    final bool isNearThreshold = _codDueBalance >= 1500;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isNearThreshold
                ? [const Color(0xFF4A0E17), const Color(0xFF1F080C)]
                : [const Color(0xFF1E1035), const Color(0xFF16155D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isNearThreshold ? Colors.red.withAlpha(50) : Colors.purple.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isNearThreshold ? Colors.redAccent : Colors.purpleAccent, width: 1),
                  ),
                  child: Text(
                    isNearThreshold ? 'ACTION REQUIRED • NEAR BLOCK THRESHOLD' : 'OUTSTANDING COD COLLECTED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: isNearThreshold ? Colors.redAccent : Colors.purpleAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cash Collected from Customer',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${_codDueBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isRemittingCod ? null : _handleRemitCOD,
                  icon: _isRemittingCod
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.payment, size: 16, color: Colors.white),
                  label: const Text('Remit Dues', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Financial Breakdown Card (Gross -> Commission -> GST -> Net)
  Widget _buildFinancialBreakdownCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earnings & Deductions Summary',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E)),
            ),
            const SizedBox(height: 14),
            _buildBreakdownRow('Gross Service Value', '₹${_serviceValueTotal.toStringAsFixed(2)}', isBold: true),
            const Divider(height: 16),
            _buildBreakdownRow('Platform Commission (10%)', '-₹${_commissionTotal.toStringAsFixed(2)}', color: Colors.orange.shade800),
            _buildBreakdownRow('GST on Commission (18%)', '-₹${_gstTotal.toStringAsFixed(2)}', color: Colors.red.shade700),
            const Divider(height: 16),
            _buildBreakdownRow('Net Payable Earnings', '₹${_netEarningsTotal.toStringAsFixed(2)}', isBold: true, color: Colors.green.shade800, fontSize: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool isBold = false, Color? color, double fontSize = 13}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, color: Colors.grey.shade700, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? const Color(0xFF1C1F3E))),
        ],
      ),
    );
  }

  Widget _buildTransfersSection(List<dynamic> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Text(
            'Recent Settlements',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1F3E),
            ),
          ),
        ),
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              'No recent settlements found.',
              style: TextStyle(color: Colors.black38, fontSize: 13),
            ),
          )
        else
          SizedBox(
            height: 124,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                if (tx is! Map) return const SizedBox.shrink();

                final Map<String, dynamic> txMap = Map<String, dynamic>.from(tx);
                final double amt = (txMap['net_payable_amount'] as num?)?.toDouble() ?? (txMap['gross_amount'] as num?)?.toDouble() ?? (txMap['amount'] as num?)?.toDouble() ?? 0.0;
                final type = txMap['payment_type'] ?? txMap['type'] ?? 'online';
                final desc = txMap['booking_id'] != null ? 'Booking #${txMap['booking_id']}' : (txMap['description'] ?? 'Job Settlement').toString();
                final status = (txMap['status'] ?? 'paid').toString();
                
                return GestureDetector(
                  onTap: () => _showTransactionDetailsSheet(txMap),
                  child: Container(
                    width: 170,
                    margin: const EdgeInsets.only(right: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${amt.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1F3E),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              desc,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: status == 'paid' || status == 'cod_settled' ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                status == 'paid' || status == 'cod_settled' ? Icons.check_circle_outline : Icons.schedule,
                                size: 12,
                                color: status == 'paid' || status == 'cod_settled' ? const Color(0xFF2E7D32) : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status == 'paid' || status == 'cod_settled' ? 'Settled' : 'Pending',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'paid' || status == 'cod_settled' ? const Color(0xFF2E7D32) : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildExploreMore(BuildContext context, int credits) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore more',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1F3E),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreditsScreen()),
                );
              },
              child: Container(
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF1FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stars_outlined,
                        color: Color(0xFF16155D),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Credits',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1F3E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$credits available',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.black38,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LeadMarketplaceScreen()),
                );
              },
              child: Container(
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF1FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.card_membership_outlined,
                        color: Color(0xFF16155D),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Lead Packages & Subscriptions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1F3E),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Purchase lead credits & priority dispatch',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.black38,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TODAY'S EARNINGS",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${_todayEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_todayJobs Jobs',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "THIS MONTH",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${_monthEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_monthJobs Jobs',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.indigo.shade700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final profileState = ref.watch(providerProfileProvider);

    final profile = profileState.profileData;
    int creditsVal = 0;
    if (profile != null) {
      final walletBalance = profile['walletBalance'] ?? 0.0;
      final reservedBalance = profile['reservedBalance'] ?? 0.0;
      final creditLimit = profile['creditLimit'] ?? 500.0;
      final availableCredit = (walletBalance as num).toDouble() - (reservedBalance as num).toDouble() + (creditLimit as num).toDouble();
      creditsVal = (availableCredit / 10).toInt();
    }

    return Column(
      children: [
        _buildTopBar(creditsVal, walletState.leadBalance),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF16155D)))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildEarningsSummaryCard(),
                        _buildKpiRow(),
                        _buildBankAccountCard(profileState.profileData?['bank_details']),
                        _buildCodDuesBanner(),
                        _buildFinancialBreakdownCard(),
                        _buildTransfersSection(_settlements.isNotEmpty ? _settlements : walletState.transactions),
                        const SizedBox(height: 16),
                        _buildExploreMore(context, creditsVal),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
