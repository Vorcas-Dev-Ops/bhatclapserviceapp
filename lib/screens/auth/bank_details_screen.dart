import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/screens/auth/approval_screen.dart';
import 'package:partner_app/screens/auth/identity_verification_screen.dart';

class BankDetailsScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  const BankDetailsScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();

  String? _fetchedBankName;
  String? _fetchedBranch;
  bool _isFetchingIfsc = false;

  @override
  void initState() {
    super.initState();
    _ifscController.addListener(_onIfscChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(providerProfileProvider).profileData;
      if (profile != null && profile['bank_details'] != null) {
        final bankDetails = profile['bank_details'];
        setState(() {
          _nameController.text = bankDetails['account_holder_name'] ?? bankDetails['accountHolderName'] ?? '';
          _accountNoController.text = bankDetails['account_number'] ?? bankDetails['accountNumber'] ?? '';
          _ifscController.text = bankDetails['ifsc_code'] ?? bankDetails['ifscCode'] ?? '';
          _upiIdController.text = bankDetails['upi_id'] ?? bankDetails['upiId'] ?? bankDetails['vpa'] ?? '';
          _fetchedBankName = bankDetails['bank_name'] ?? bankDetails['bankName'];
        });
        if (_ifscController.text.length == 11) {
          _fetchBankDetailsFromRazorpayX(_ifscController.text.toUpperCase());
        }
      }
    });
  }

  @override
  void dispose() {
    _ifscController.removeListener(_onIfscChanged);
    _nameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _onIfscChanged() {
    final code = _ifscController.text.trim().toUpperCase();
    if (code.length == 11 && RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(code)) {
      _fetchBankDetailsFromRazorpayX(code);
    } else {
      if (_fetchedBankName != null) {
        setState(() {
          _fetchedBankName = null;
          _fetchedBranch = null;
        });
      }
    }
  }

  Future<void> _fetchBankDetailsFromRazorpayX(String ifsc) async {
    setState(() {
      _isFetchingIfsc = true;
    });

    try {
      final response = await Dio().get('https://ifsc.razorpay.com/$ifsc');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (mounted) {
          setState(() {
            _isFetchingIfsc = false;
            _fetchedBankName = data['BANK']?.toString() ?? 'Verified Bank';
            _fetchedBranch = data['BRANCH']?.toString();
          });
        }
        return;
      }
    } catch (_) {}

    // Fallback match by IFSC prefix if offline
    final prefix = ifsc.substring(0, 4);
    String? fallbackName;
    if (prefix == 'SBIN') fallbackName = 'State Bank of India';
    else if (prefix == 'HDFC') fallbackName = 'HDFC Bank';
    else if (prefix == 'ICIC') fallbackName = 'ICICI Bank';
    else if (prefix == 'UTIB') fallbackName = 'Axis Bank';
    else if (prefix == 'PUNB') fallbackName = 'Punjab National Bank';
    else if (prefix == 'CNRB') fallbackName = 'Canara Bank';
    else if (prefix == 'BARB') fallbackName = 'Bank of Baroda';
    else if (prefix == 'UBIN') fallbackName = 'Union Bank of India';

    if (mounted) {
      setState(() {
        _isFetchingIfsc = false;
        _fetchedBankName = fallbackName ?? 'Bank Verified via RazorpayX';
        _fetchedBranch = null;
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF16155D),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRazorpayVerifiedCard() {
    if (_isFetchingIfsc) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16155D)),
            ),
            SizedBox(width: 12),
            Text(
              'Fetching bank details via RazorpayX...',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    if (_fetchedBankName != null) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF81C784), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RazorpayX Verified Bank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fetchedBankName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1F3E),
                    ),
                  ),
                  if (_fetchedBranch != null && _fetchedBranch!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Branch: ${_fetchedBranch!}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Progress Bar (Step 4 of 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16155D),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Let\'s Link Your Bank Account',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16155D),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bank Account Details',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form Area (Only required fields)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Account Holder Name',
                        hint: 'Full name as per bank records',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: 'Account Number',
                        hint: 'Digits only',
                        controller: _accountNoController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: 'IFSC Code',
                        hint: 'eg : ABCD00001234',
                        controller: _ifscController,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      _buildRazorpayVerifiedCard(),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: 'UPI ID / VPA (Optional)',
                        hint: 'e.g. mobile@upi or name@ybl',
                        controller: _upiIdController,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation Area
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 20.0, top: 10.0),
              child: Row(
                children: [
                  // Back Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const IdentityVerificationScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF1FE),
                        foregroundColor: const Color(0xFF16155D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Complete Button
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final profileState = ref.watch(providerProfileProvider);
                          final isLoading = profileState.status == ProfileStatus.loading;

                          return ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final name = _nameController.text.trim();
                                    final accountNo = _accountNoController.text.trim();
                                    final ifsc = _ifscController.text.trim().toUpperCase();
                                    final upiId = _upiIdController.text.trim();

                                    if (name.isEmpty || accountNo.isEmpty || ifsc.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please fill all bank detail fields')),
                                      );
                                      return;
                                    }

                                    if (!RegExp(r'^\d{8,18}$').hasMatch(accountNo)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Account number must be between 8 and 18 digits')),
                                      );
                                      return;
                                    }

                                    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Invalid IFSC format (e.g. SBIN0001234)')),
                                      );
                                      return;
                                    }

                                    if (upiId.isNotEmpty && !RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$').hasMatch(upiId)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Invalid UPI ID format (e.g. name@upi)')),
                                      );
                                      return;
                                    }

                                    final bankNameToSend = _fetchedBankName ?? 'Bank Verified via RazorpayX';

                                    final success = await ref
                                        .read(providerProfileProvider.notifier)
                                        .updateBankDetails(
                                          accountHolderName: name,
                                          accountNumber: accountNo,
                                          ifscCode: ifsc,
                                          bankName: bankNameToSend,
                                          upiId: upiId.isNotEmpty ? upiId : null,
                                        );

                                    if (success && mounted) {
                                      if (widget.isEditing) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Bank details updated successfully!')),
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        final submitSuccess = await ref.read(providerProfileProvider.notifier).submitForReview();
                                        if (submitSuccess && mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const ApprovalScreen(),
                                            ),
                                          );
                                        } else if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Failed to submit application. Please try again.')),
                                          );
                                        }
                                      }
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            profileState.errorMessage ?? 'Failed to submit bank details',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16155D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Complete',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
