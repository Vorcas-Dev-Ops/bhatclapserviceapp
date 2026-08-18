import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class ProviderPhoneChangeModal extends ConsumerStatefulWidget {
  final String currentPhone;
  final VoidCallback onPhoneUpdated;

  const ProviderPhoneChangeModal({
    super.key,
    required this.currentPhone,
    required this.onPhoneUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentPhone,
    required VoidCallback onPhoneUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProviderPhoneChangeModal(
        currentPhone: currentPhone,
        onPhoneUpdated: onPhoneUpdated,
      ),
    );
  }

  @override
  ConsumerState<ProviderPhoneChangeModal> createState() => _ProviderPhoneChangeModalState();
}

class _ProviderPhoneChangeModalState extends ConsumerState<ProviderPhoneChangeModal> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  int _step = 1; // 1: Enter Phone, 2: Verify OTP
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 60;
      _canResend = false;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        if (mounted) {
          setState(() {
            _cooldownSeconds--;
          });
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  String _formatPhoneForApi(String input) {
    String clean = input.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) return '+91$clean';
    if (clean.length == 12 && clean.startsWith('91')) return '+$clean';
    if (clean.startsWith('91') && clean.length > 10) return '+$clean';
    return '+91$clean';
  }

  Future<void> _handleInitiate() async {
    final rawInput = _phoneController.text.trim();
    final cleanDigits = rawInput.replaceAll(RegExp(r'\D'), '');
    
    if (cleanDigits.length < 10) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    final formattedPhone = _formatPhoneForApi(rawInput);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ref.read(authProvider.notifier).initiatePhoneChange(formattedPhone);

    if (mounted) {
      if (res['success'] == true) {
        setState(() {
          _isLoading = false;
          _step = 2;
        });
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'OTP sent to $formattedPhone'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res['message'] ?? 'Failed to send OTP';
        });
      }
    }
  }

  Future<void> _handleVerify() async {
    final otpCode = _otpControllers.map((c) => c.text).join().trim();
    if (otpCode.length < 6) {
      setState(() {
        _errorMessage = 'Please enter complete 6-digit OTP';
      });
      return;
    }

    final formattedPhone = _formatPhoneForApi(_phoneController.text.trim());

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ref.read(authProvider.notifier).verifyPhoneChange(formattedPhone, otpCode);

    if (mounted) {
      if (res['success'] == true) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pop(context);
        widget.onPhoneUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Registered mobile number updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res['message'] ?? 'Invalid OTP code';
        });
      }
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
        if (_otpControllers.every((c) => c.text.isNotEmpty)) {
          _handleVerify();
        }
      }
    } else {
      if (index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _step == 1 ? 'Change Partner Mobile Number' : 'Verify Partner Mobile',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16155D),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade900, fontSize: 13),
              ),
            ),
          ],
          if (_step == 1) ...[
            const Text(
              'Enter your new 10-digit registered partner phone number. An OTP will be sent to confirm ownership.',
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'New Registered Mobile',
                hintText: '98765 43210',
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Text('+91 ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16155D))),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF16155D), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleInitiate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16155D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send Verification OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ] else ...[
            Text(
              'Enter the 6-digit OTP sent to ${_formatPhoneForApi(_phoneController.text.trim())}',
              style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 44,
                  height: 52,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    onChanged: (val) => _onOtpChanged(index, val),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF16155D)),
                    decoration: InputDecoration(
                      counterText: '',
                      fillColor: const Color(0xFFF5F6FA),
                      filled: true,
                      contentPadding: EdgeInsets.zero,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF16155D), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _otpControllers[index].text.isNotEmpty ? const Color(0xFF16155D) : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _step = 1;
                      _errorMessage = null;
                    });
                  },
                  child: const Text('Change Number', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: _canResend && !_isLoading ? _handleInitiate : null,
                  child: Text(
                    _canResend ? 'Resend OTP' : 'Resend in ${_cooldownSeconds}s',
                    style: TextStyle(
                      color: _canResend ? const Color(0xFF16155D) : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16155D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm & Update Partner Number', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
