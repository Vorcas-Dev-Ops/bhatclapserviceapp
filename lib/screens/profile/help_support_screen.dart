import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/provider_profile_provider.dart';
import '../auth/login_screen.dart';

class PartnerHelpSupportScreen extends ConsumerStatefulWidget {
  const PartnerHelpSupportScreen({super.key});

  @override
  ConsumerState<PartnerHelpSupportScreen> createState() => _PartnerHelpSupportScreenState();
}

class _PartnerHelpSupportScreenState extends ConsumerState<PartnerHelpSupportScreen> {
  bool _isLoading = false;
  bool _hasDeletionRequest = false;
  String? _deletionScheduledDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileStatus();
    });
  }

  void _checkProfileStatus() {
    final profileData = ref.read(providerProfileProvider).profileData;
    if (profileData != null) {
      if (profileData['deletion_requested_at'] != null || profileData['deletion_scheduled_at'] != null) {
        setState(() {
          _hasDeletionRequest = true;
          _deletionScheduledDate = profileData['deletion_scheduled_at']?.toString().split('T').first;
        });
      }
    }
  }

  Future<void> _handleExportData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.get('/api/users/me/export');
      if (mounted && res.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.download_done_rounded, color: Colors.green),
                SizedBox(width: 8),
                Text('Data Exported', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Your partner profile data, earnings, documents, and service history have been compiled in compliance with DPDPA Data Portability guidelines.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16155D))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Request Partner Deletion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Under DPDPA Right to Erasure rules, requesting partner account deletion initiates a 30-day cooling period.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 10),
            Text(
              '• Your partner account will be scheduled for permanent anonymization in 30 days.\n'
              '• You can cancel your deletion request anytime during these 30 days.\n'
              '• Any outstanding COD dues must be remitted before final erasure.\n'
              '• You will be logged out immediately.',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmAccountDeletion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Request Deletion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAccountDeletion() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.post('/api/users/me/delete-request');
      if (mounted && (res.statusCode == 200 || res.statusCode == 201)) {
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Text('Deletion Requested', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                'Account deletion requested successfully. Your account will be anonymized in 30 days.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16155D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Error requesting account deletion';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map) {
            msg = data['message']?.toString() ?? data['error']?.toString() ?? msg;
            if (data['blocking_obligations'] is List && (data['blocking_obligations'] as List).isNotEmpty) {
              msg = 'Please resolve the following obligations before deleting your account:\n\n• ${ (data['blocking_obligations'] as List).join('\n• ') }';
            }
          }
        } else {
          msg = e.toString();
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text('Pending Obligations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              msg,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16155D))),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelAccountDeletion() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.delete('/api/users/me/delete-request');
      if (mounted && res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deletion request cancelled. Your partner account remains active!'), backgroundColor: Colors.green),
        );
        setState(() => _hasDeletionRequest = false);
        ref.read(providerProfileProvider.notifier).fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _makeCall(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Partner Support Helpline: $phone'), backgroundColor: const Color(0xFF16155D)),
    );
  }

  void _sendEmail(String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Partner Support Email: $email'), backgroundColor: const Color(0xFF16155D)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF16155D), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Color(0xFF1C1F3E), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16155D)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partner Support Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16155D),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Partner Support & Help Center',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Need assistance with job dispatch, payouts, or document verification?',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _makeCall('+9118001234567'),
                                icon: const Icon(Icons.call, size: 16, color: Color(0xFF16155D)),
                                label: const Text('Call Support', style: TextStyle(color: Color(0xFF16155D), fontWeight: FontWeight.bold, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _sendEmail('partner-support@bharatclap.com'),
                                icon: const Icon(Icons.email_outlined, size: 16, color: Colors.white),
                                label: const Text('Email Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white70, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Partner FAQs
                  const Text(
                    'Partner Frequently Asked Questions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E)),
                  ),
                  const SizedBox(height: 12),
                  _buildFaqTile('How are job dispatches assigned?', 'Jobs are dispatched based on your active service categories, location, and available lead credits.'),
                  _buildFaqTile('When do automated bank payouts occur?', 'Payouts are automatically settled to your verified bank account once completed job holds expire.'),
                  _buildFaqTile('How do I remit Cash on Delivery (COD) dues?', 'Go to the Money tab and click "Remit Dues" to pay outstanding COD balance online via UPI or Razorpay.'),

                  const SizedBox(height: 24),

                  // Account Privacy & Data Rights (DPDPA Section)
                  const Text(
                    'Account & Data Privacy (DPDPA)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Color(0xFFEFF1FE), shape: BoxShape.circle),
                            child: const Icon(Icons.download_outlined, color: Color(0xFF16155D), size: 20),
                          ),
                          title: const Text('Export My Partner Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E))),
                          subtitle: const Text('Download copy of partner profile, payouts & documents', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: _handleExportData,
                        ),
                        const Divider(height: 1),
                        if (_hasDeletionRequest)
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.orange.shade50,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.schedule, color: Colors.orange, size: 18),
                                    SizedBox(width: 8),
                                    Text('Account Deletion Requested', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Your partner account is scheduled for permanent anonymization on $_deletionScheduledDate.',
                                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _cancelAccountDeletion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade700,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Cancel Deletion Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          )
                        else
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Color(0xFFFFF0F0), shape: BoxShape.circle),
                              child: const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 20),
                            ),
                            title: const Text('Delete Partner Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                            subtitle: const Text('Initiate 30-day cooling period for permanent erasure', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.red, size: 20),
                            onTap: _showDeleteAccountDialog,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildFaqTile(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E))),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(content, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
        ],
      ),
    );
  }
}
