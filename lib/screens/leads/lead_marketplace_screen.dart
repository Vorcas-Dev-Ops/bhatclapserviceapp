import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:partner_app/providers/api_providers.dart';
import 'package:partner_app/providers/auth_provider.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'lead_package_store_screen.dart';

class LeadMarketplaceScreen extends ConsumerStatefulWidget {
  const LeadMarketplaceScreen({super.key});

  @override
  ConsumerState<LeadMarketplaceScreen> createState() => _LeadMarketplaceScreenState();
}

class _LeadMarketplaceScreenState extends ConsumerState<LeadMarketplaceScreen> {
  List<dynamic> _leads = [];
  bool _isLoading = true;
  int _walletCredits = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeadsAndCredits();
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

  Future<void> _claimLead(String leadId, int cost) async {
    if (_walletCredits < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient lead credits ($cost required, you have $_walletCredits). Please buy lead credits!'),
          backgroundColor: Colors.orange.shade900,
          action: SnackBarAction(
            label: 'BUY CREDITS',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeadPackageStoreScreen()),
              ).then((_) => _fetchLeadsAndCredits());
            },
          ),
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
        title: const Text(
          'Lead Marketplace',
          style: TextStyle(color: Color(0xFF16155D), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF16155D)),
            onPressed: _fetchLeadsAndCredits,
          ),
        ],
      ),
      body: Column(
        children: [
          // Wallet Credits Banner
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16155D), Color(0xFF2E2D8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16155D).withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Lead Credits',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_walletCredits Credits',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('Buy Credits', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LeadPackageStoreScreen()),
                    ).then((_) => _fetchLeadsAndCredits());
                  },
                ),
              ],
            ),
          ),

          // Leads List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      )
                    : _leads.isEmpty
                        ? const Center(
                            child: Text(
                              'No job leads available right now. Check back soon!',
                              style: TextStyle(color: Colors.black45),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchLeadsAndCredits,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          ),
          ),
        ],
      ),
    );
  }
}
