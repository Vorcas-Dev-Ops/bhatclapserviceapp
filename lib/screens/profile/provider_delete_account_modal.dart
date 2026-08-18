import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class ProviderDeleteAccountModal extends ConsumerStatefulWidget {
  const ProviderDeleteAccountModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProviderDeleteAccountModal(),
    );
  }

  @override
  ConsumerState<ProviderDeleteAccountModal> createState() => _ProviderDeleteAccountModalState();
}

class _ProviderDeleteAccountModalState extends ConsumerState<ProviderDeleteAccountModal> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  List<String> _blockingObligations = [];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _blockingObligations = [];
    });

    final res = await ref.read(authProvider.notifier).requestAccountDeletion(
      reason: _reasonController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      final obligations = res['blocking_obligations'];
      if (obligations != null && obligations is List && obligations.isNotEmpty) {
        setState(() {
          _blockingObligations = List<String>.from(obligations);
          _errorMessage = 'Account deletion is currently blocked due to active financial or operational obligations.';
        });
      } else if (res['success'] == true) {
        setState(() {
          _successMessage = res['message'] ?? 'Account deletion request submitted. Your account will enter a 3-5 day SLA financial clearance grace period.';
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to submit account deletion request.';
        });
      }
    }
  }

  Future<void> _handleCancelRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _blockingObligations = [];
    });

    final res = await ref.read(authProvider.notifier).cancelAccountDeletion();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (res['success'] == true) {
        setState(() {
          _successMessage = 'Account deletion request cancelled successfully. Your partner profile remains active.';
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to cancel deletion request.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                SizedBox(width: 10),
                Text(
                  'Delete Partner Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16155D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Partner account deletion requires zero active jobs, cleared COD cash balances, and no pending settlements.',
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF1FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF16155D).withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF16155D), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Financial Audit Gates: 3-5 day SLA clearance before account erasure.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF16155D), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reason for deletion (optional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tell us why you are deleting your partner account...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_blockingObligations.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Obligations Mandatory Resolution:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 6),
                    ..._blockingObligations.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.close, size: 14, color: Colors.redAccent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_errorMessage != null && _blockingObligations.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Close', style: TextStyle(color: Colors.black87)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleDeleteRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Request Deletion',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _handleCancelRequest,
                child: const Text(
                  'Cancel Existing Deletion Request',
                  style: TextStyle(color: Color(0xFF16155D), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
