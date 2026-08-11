import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:partner_app/providers/wallet_provider.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/config/config.dart';
import 'package:partner_app/widgets/razorpay_gateway_modal.dart';

class AddCreditsScreen extends ConsumerStatefulWidget {
  const AddCreditsScreen({super.key});

  @override
  ConsumerState<AddCreditsScreen> createState() => _AddCreditsScreenState();
}

class _AddCreditsScreenState extends ConsumerState<AddCreditsScreen> {
  int _selectedAmount = 100;
  final TextEditingController _creditsController = TextEditingController(text: '100');
  bool _isLoading = false;
  late Razorpay _razorpay;
  Completer<Map<String, dynamic>?>? _razorpayCompleter;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _creditsController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_razorpayCompleter != null && !_razorpayCompleter!.isCompleted) {
      _razorpayCompleter!.complete({
        'success': true,
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_razorpayCompleter != null && !_razorpayCompleter!.isCompleted) {
      _razorpayCompleter!.complete({'success': false, 'message': response.message});
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (_razorpayCompleter != null && !_razorpayCompleter!.isCompleted) {
      _razorpayCompleter!.complete({'success': false, 'message': 'External wallet'});
    }
  }

  void _selectAmount(int amount) {
    setState(() {
      _selectedAmount = amount;
      _creditsController.text = amount.toString();
    });
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1C1F3E), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Add Credits',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1F3E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsInputCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter number of Credits',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _creditsController,
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final amt = int.tryParse(val) ?? 0;
                setState(() {
                  _selectedAmount = amt;
                });
              },
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1F3E),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectOption(int amount, bool isPopular) {
    final bool isSelected = _selectedAmount == amount;
    final cardContent = Container(
      width: 86,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF16155D) : const Color(0xFFE5E7EB),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Center(
        child: Text(
          amount.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF16155D) : const Color(0xFF2D3047),
          ),
        ),
      ),
    );

    if (isPopular) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          cardContent,
          Positioned(
            bottom: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2979FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'POPULAR',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return cardContent;
  }

  Widget _buildQuickSelectRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            'Quick select:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            children: [
              GestureDetector(
                onTap: () => _selectAmount(50),
                child: _buildQuickSelectOption(50, false),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _selectAmount(100),
                child: _buildQuickSelectOption(100, true),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _selectAmount(200),
                child: _buildQuickSelectOption(200, false),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _selectAmount(500),
                child: _buildQuickSelectOption(500, false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRazorpayInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF1FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF16155D),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Razorpay Secure Gateway',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3047),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Instant & secure checkout via UPI, Cards, NetBanking or Wallets',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
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

  Future<void> _handlePayment() async {
    final int amountInRupees = _selectedAmount * 10;
    if (amountInRupees < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum recharge amount is ₹500 (50 credits).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Create Razorpay order on backend
      final orderRes = await ref.read(walletProvider.notifier).createRechargeOrder(amountInRupees.toDouble());

      String orderId;
      if (orderRes != null && orderRes['rzpOrder'] != null && orderRes['rzpOrder']['id'] != null) {
        orderId = orderRes['rzpOrder']['id'].toString();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          _showFailureDialog('Failed to create recharge order on payment server.');
        }
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // 2. Open in-app Razorpay Gateway Modal Sheet for smooth, secure checkout
      await _triggerGatewayModalFallback(orderId, amountInRupees.toDouble());
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showFailureDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _triggerGatewayModalFallback(String orderId, double amountInRupees) async {
    final paymentResult = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => PartnerRazorpayGatewayModalSheet(
        orderId: orderId,
        keyId: Config.razorpayKeyId,
        amount: amountInRupees,
        title: 'Partner Credit Recharge',
      ),
    );

    if (paymentResult != null && paymentResult['success'] == true) {
      await _verifyAndFinalizePayment(
        orderId: paymentResult['razorpay_order_id'] ?? orderId,
        paymentId: paymentResult['razorpay_payment_id'] ?? '',
        signature: paymentResult['razorpay_signature'] ?? '',
        amountInRupees: amountInRupees,
      );
    } else {
      if (mounted) {
        _showFailureDialog(paymentResult?['message'] ?? 'Payment transaction failed or cancelled.');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndFinalizePayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required double amountInRupees,
  }) async {
    setState(() {
      _isLoading = true;
    });

    final verifySuccess = await ref.read(walletProvider.notifier).verifyRecharge(
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
      amount: amountInRupees,
    );

    setState(() {
      _isLoading = false;
    });

    if (verifySuccess) {
      if (mounted) {
        _showSuccessDialog();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verification failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF2E7D32),
                size: 72,
              ),
              const SizedBox(height: 24),
              const Text(
                'Recharge Successful',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16155D),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '₹${(_selectedAmount * 10).toString()} has been credited to your wallet, adding $_selectedAmount credits.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(walletProvider.notifier).fetchWalletAndReviews();
                    ref.read(providerProfileProvider.notifier).fetchProfile();
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Pop screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16155D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _showRazorpayGatewayModal(String orderId, String keyId, double amountInRupees) async {
    _razorpayCompleter = Completer<Map<String, dynamic>?>();

    final profile = ref.read(providerProfileProvider).profileData;
    final phone = profile?['user_id']?['phone'] ?? profile?['phone'] ?? '';
    final email = profile?['user_id']?['email'] ?? profile?['email'] ?? '';

    final options = {
      'key': Config.razorpayKeyId,
      'amount': (amountInRupees * 100).toInt(),
      'name': 'BharatClap Partner',
      'description': 'Partner Wallet Credit Recharge',
      'order_id': orderId,
      'prefill': {
        'contact': phone,
        'email': email,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }

    return _razorpayCompleter!.future;
  }

  Widget _buildBottomStickyBar() {
    final int amount = _selectedAmount * 10;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16155D),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _handlePayment,
                icon: const Text(
                  'Proceed to Pay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                label: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16155D),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: [
                        _buildCreditsInputCard(),
                        _buildQuickSelectRow(),
                        const SizedBox(height: 16),
                        _buildRazorpayInfoCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildBottomStickyBar(),
            if (_isLoading)
              Container(
                color: Colors.black.withAlpha(77),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF16155D),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


