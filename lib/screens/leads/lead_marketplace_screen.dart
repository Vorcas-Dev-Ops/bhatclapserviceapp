import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:partner_app/providers/api_providers.dart';
import 'package:partner_app/providers/auth_provider.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import '../../widgets/razorpay_gateway_modal.dart';

class LeadMarketplaceScreen extends ConsumerStatefulWidget {
  const LeadMarketplaceScreen({super.key});

  @override
  ConsumerState<LeadMarketplaceScreen> createState() => _LeadMarketplaceScreenState();
}

class _LeadMarketplaceScreenState extends ConsumerState<LeadMarketplaceScreen> {
  List<dynamic> _leads = [];
  List<dynamic> _packages = [];
  bool _isLoading = true;
  int _walletCredits = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeadsAndCredits();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.get('/api/providers/lead-packages');
      if (mounted && res.statusCode == 200) {
        final data = res.data;
        final list = (data is Map && data['data'] != null) ? data['data'] : (data is List ? data : []);
        if (list is List && list.isNotEmpty) {
          setState(() {
            _packages = list;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _packages = [
          {'id': 'pkg_299', 'name': 'Starter', 'title': 'Starter', 'price': 299, 'leads': 25, 'bonusLeads': 0, 'validityDays': 30, 'hasPriorityDispatch': false},
          {'id': 'pkg_499', 'name': 'Basic', 'title': 'Basic', 'price': 499, 'leads': 60, 'bonusLeads': 10, 'validityDays': 30, 'hasPriorityDispatch': false},
          {'id': 'pkg_999', 'name': 'Silver', 'title': 'Silver', 'price': 999, 'leads': 120, 'bonusLeads': 20, 'validityDays': 60, 'hasPriorityDispatch': true},
          {'id': 'pkg_1999', 'name': 'Gold', 'title': 'Gold', 'price': 1999, 'leads': 300, 'bonusLeads': 50, 'validityDays': 90, 'hasPriorityDispatch': true},
        ];
      });
    }
  }

  Future<void> _fetchLeadsAndCredits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      Response? leadsRes;
      Response? walletRes;

      // Fetch Available Lead Requests / Job Dispatches
      try {
        leadsRes = await apiClient.dio.get('/api/providers/job-requests');
      } catch (_) {
        try {
          leadsRes = await apiClient.dio.get('/api/providers/lead-balance');
        } catch (_) {}
      }

      // Fetch Wallet & Lead Balance
      try {
        walletRes = await apiClient.dio.get('/api/providers/wallet/balance');
      } catch (_) {
        try {
          walletRes = await apiClient.dio.get('/api/providers/lead-balance');
        } catch (_) {}
      }

      if (mounted) {
        final authState = ref.read(authProvider);
        final profileState = ref.read(providerProfileProvider);

        final genderStr = (authState.user?.gender ??
                           profileState.profileData?['gender'] ??
                           profileState.profileData?['user_id']?['gender'] ??
                           '').toString().trim().toLowerCase();

        final isFemaleProvider = genderStr == 'female' || genderStr == 'f';
        final isMaleProvider = genderStr == 'male' || genderStr == 'm';

        List rawLeads = [];
        if (leadsRes != null && (leadsRes.statusCode == 200 || leadsRes.statusCode == 201)) {
          final data = leadsRes.data;
          if (data is Map && data['data'] != null) {
            rawLeads = data['data'] is List ? data['data'] : [];
          } else if (data is Map && data['jobRequests'] != null) {
            rawLeads = data['jobRequests'] is List ? data['jobRequests'] : [];
          } else if (data is List) {
            rawLeads = data;
          }
        }

        int fetchedCredits = 0;
        if (walletRes != null && (walletRes.statusCode == 200 || walletRes.statusCode == 201)) {
          final wData = walletRes.data;
          final payload = (wData is Map && wData['data'] != null) ? wData['data'] : wData;
          if (payload is Map) {
            final val = payload['leadBalance'] ??
                        payload['lead_credits'] ??
                        payload['credits'] ??
                        payload['availableBalance'] ??
                        payload['walletBalance'] ?? 0;
            if (val is num) fetchedCredits = val.toInt();
          }
        }

        setState(() {
          _isLoading = false;
          _walletCredits = fetchedCredits;

          if (isFemaleProvider) {
            _leads = rawLeads.where((lead) {
              final catName = (lead['category_name'] ?? lead['category']?['category_name'] ?? '').toString().toLowerCase();
              final isBeauty = catName.contains('beauty') || catName.contains('wellness');
              if (!isBeauty) return true;

              final targetGender = (lead['target_gender'] ?? lead['service_gender'] ?? '').toString().toLowerCase();
              if (targetGender == 'female' || targetGender == 'women') return true;
              if (targetGender == 'male' || targetGender == 'men') return false;

              final title = (lead['service_name'] ?? lead['title'] ?? '').toString().toLowerCase();
              final hasMaleKeyword = (title.contains('men') && !title.contains('women')) ||
                                     title.contains('male') ||
                                     title.contains('beard') ||
                                     title.contains('barber');
              return !hasMaleKeyword;
            }).toList();
          } else if (isMaleProvider) {
            _leads = rawLeads.where((lead) {
              final catName = (lead['category_name'] ?? lead['category']?['category_name'] ?? '').toString().toLowerCase();
              final isBeauty = catName.contains('beauty') || catName.contains('wellness');
              if (!isBeauty) return true;

              final targetGender = (lead['target_gender'] ?? lead['service_gender'] ?? '').toString().toLowerCase();
              if (targetGender == 'male' || targetGender == 'men') return true;
              if (targetGender == 'female' || targetGender == 'women') return false;

              final title = (lead['service_name'] ?? lead['title'] ?? '').toString().toLowerCase();
              final hasFemaleKeyword = title.contains('women') ||
                                       title.contains('female') ||
                                       title.contains('waxing') ||
                                       title.contains('threading') ||
                                       title.contains('makeup') ||
                                       title.contains('bridal');
              return !hasFemaleKeyword;
            }).toList();
          } else {
            _leads = rawLeads;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _leads = [];
          _errorMessage = null;
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
    final price = (pkg['price'] ?? 299).toDouble();
    final pkgId = pkg['_id'] ?? pkg['id'] ?? 'pkg_10';

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.post('/api/providers/lead-packages/purchase', data: {
        'packageId': pkgId,
      });

      if (mounted && res.statusCode == 200 && res.data != null) {
        final orderData = res.data;

        if (orderData['freeAccess'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(orderData['message'] ?? 'Lead package activated successfully!'), backgroundColor: Colors.green),
            );
            _fetchLeadsAndCredits();
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
            _fetchLeadsAndCredits();
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

  Future<void> _claimLead(String leadId, int cost) async {
    if (_walletCredits < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient lead credits ($cost required, you have $_walletCredits). Please buy lead credits below!'),
          backgroundColor: Colors.orange.shade900,
        ),
      );
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      Response res;
      try {
        res = await apiClient.dio.post('/api/providers/job-requests/$leadId/accept');
      } catch (_) {
        res = await apiClient.dio.post('/api/providers/leads/claim', data: {
          'lead_id': leadId,
        });
      }

      if (mounted && (res.statusCode == 200 || res.statusCode == 201)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lead claimed successfully! Check My Jobs tab for customer contact.'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchLeadsAndCredits();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim lead: ${e is DioException ? (e.response?.data['message'] ?? e.message) : e}'),
            backgroundColor: Colors.red,
          ),
        );
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
          'Lead Marketplace',
          style: TextStyle(color: Color(0xFF16155D), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF16155D)),
            onPressed: () {
              _fetchLeadsAndCredits();
              _fetchPackages();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Wallet Credits Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16155D), Color(0xFF2E2D8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16155D).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Lead Credits',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_walletCredits Credits',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Main Area (Lead Credit Packages & Job Leads)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await _fetchLeadsAndCredits();
                      await _fetchPackages();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_leads.isNotEmpty) ...[
                            const Text(
                              'Available Job Leads',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16155D),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _leads.length,
                              itemBuilder: (context, index) {
                                final lead = _leads[index];
                                final leadId = lead['_id'] ?? lead['id'] ?? '';
                                final serviceName = lead['service_name'] ?? lead['title'] ?? 'On-Demand Service';
                                final area = lead['area_name'] ?? lead['address'] ?? 'Nearby Location';
                                final cost = lead['credit_cost'] ?? lead['lead_cost'] ?? 1;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
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
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF16155D),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '$cost Credits',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: Colors.black45),
                                          const SizedBox(width: 4),
                                          Text(
                                            area,
                                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF16155D),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text('Claim Lead', style: TextStyle(color: Colors.white)),
                                          onPressed: () => _claimLead(leadId, cost),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Lead Credit Packages Section (Image 1 Cards)
                          const Text(
                            'Lead Credit Packages',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16155D),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
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
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF16155D),
                                                ),
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
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
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
                                      child: const Text(
                                        'Buy Now',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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
}
