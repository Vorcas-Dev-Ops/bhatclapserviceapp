import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:partner_app/providers/api_providers.dart';
import '../../widgets/razorpay_gateway_modal.dart';

class LeadPackageStoreScreen extends ConsumerStatefulWidget {
  const LeadPackageStoreScreen({super.key});

  @override
  ConsumerState<LeadPackageStoreScreen> createState() => _LeadPackageStoreScreenState();
}

class _LeadPackageStoreScreenState extends ConsumerState<LeadPackageStoreScreen> {
  List<dynamic> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.get('/api/providers/lead-packages');
      if (mounted && res.statusCode == 200) {
        final data = res.data;
        setState(() {
          _isLoading = false;
          _packages = (data is Map && data['data'] != null) ? data['data'] : (data is List ? data : []);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _packages = [
            {'id': 'pkg_299', 'name': 'Starter', 'title': 'Starter', 'price': 299, 'leads': 25, 'bonusLeads': 0, 'validityDays': 30, 'hasPriorityDispatch': false},
            {'id': 'pkg_499', 'name': 'Basic', 'title': 'Basic', 'price': 499, 'leads': 60, 'bonusLeads': 10, 'validityDays': 30, 'hasPriorityDispatch': false},
            {'id': 'pkg_999', 'name': 'Silver', 'title': 'Silver', 'price': 999, 'leads': 120, 'bonusLeads': 20, 'validityDays': 60, 'hasPriorityDispatch': true},
            {'id': 'pkg_1999', 'name': 'Gold', 'title': 'Gold', 'price': 1999, 'leads': 300, 'bonusLeads': 50, 'validityDays': 90, 'hasPriorityDispatch': true},
          ];
        });
      }
    }
  }

  void _showFailureDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(
              'Payment Failed',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          reason.isNotEmpty ? reason : 'The payment transaction could not be completed. Please try again.',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16155D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _buyPackage(Map<String, dynamic> pkg) async {
    final title = pkg['name'] ?? pkg['title'] ?? 'Lead Package';
    final price = (pkg['price'] ?? 499).toDouble();
    final pkgId = pkg['_id'] ?? pkg['id'] ?? 'pkg_10';

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.post('/api/providers/lead-packages/purchase', data: {
        'packageId': pkgId,
      });

      if (mounted && res.statusCode == 200 && res.data != null) {
        final orderData = res.data;

        // Check for Free Access bypass
        if (orderData['freeAccess'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(orderData['message'] ?? 'Lead package activated successfully!'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
          return;
        }

        final rzpOrder = orderData['razorpayOrder'] ?? orderData['order'];
        final orderId = rzpOrder?['id'] ?? orderData['order_id'] ?? orderData['razorpay_order_id'];
        final keyId = orderData['key_id'] ?? orderData['keyId'] ?? '';

        if (orderId == null || orderId.toString().isEmpty) {
          _showFailureDialog(orderData['message'] ?? 'Invalid order response returned from server.');
          return;
        }

        final paymentResult = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (context) => PartnerRazorpayGatewayModalSheet(
            orderId: orderId.toString(),
            keyId: keyId.toString(),
            amount: price,
            title: title,
          ),
        );

        if (paymentResult != null && paymentResult['success'] == true && mounted) {
          final paymentId = paymentResult['razorpay_payment_id'] ?? paymentResult['payment_id'];
          final signature = paymentResult['razorpay_signature'] ?? paymentResult['signature'];
          await apiClient.dio.post('/api/providers/lead-packages/verify', data: {
            'razorpay_order_id': orderId,
            'razorpay_payment_id': paymentId,
            'razorpay_signature': signature,
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lead credits added to wallet successfully!'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        } else if (mounted) {
          _showFailureDialog(paymentResult?['message'] ?? 'Payment failed or cancelled.');
        }
      } else if (mounted) {
        _showFailureDialog(res.data?['message'] ?? 'Failed to create order on payment server.');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        if (e is DioException && e.response?.data != null && e.response?.data['message'] != null) {
          msg = e.response!.data['message'].toString();
        }
        _showFailureDialog(msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lead Credit Packages',
          style: TextStyle(color: Color(0xFF16155D), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _packages.length,
              itemBuilder: (context, index) {
                final pkg = _packages[index];
                final title = pkg['name'] ?? pkg['title'] ?? 'Lead Package';
                final baseLeads = pkg['leads'] ?? pkg['baseLeads'] ?? pkg['credits'] ?? 10;
                final bonusLeads = pkg['bonusLeads'] ?? 0;
                final totalLeads = baseLeads + bonusLeads;
                final validityDays = pkg['validityDays'] ?? 30;
                final price = pkg['price'] ?? 299;
                final hasPriority = pkg['hasPriorityDispatch'] == true;

                final leadsSubtext = bonusLeads > 0
                    ? '$totalLeads Job Lead Credits ($baseLeads Base + $bonusLeads Bonus)'
                    : '$totalLeads Job Lead Credits';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16155D)),
                                ),
                                if (hasPriority) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '⚡ PRIORITY',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              leadsSubtext,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Valid for $validityDays days',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹$price',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16155D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () => _buyPackage(pkg),
                        child: const Text('Buy Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
