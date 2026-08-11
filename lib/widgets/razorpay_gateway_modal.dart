import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PartnerRazorpayGatewayModalSheet extends StatefulWidget {
  final String orderId;
  final String keyId;
  final double amount;
  final String title;

  const PartnerRazorpayGatewayModalSheet({
    super.key,
    required this.orderId,
    required this.keyId,
    required this.amount,
    this.title = 'BharatClap Partner',
  });

  @override
  State<PartnerRazorpayGatewayModalSheet> createState() => _PartnerRazorpayGatewayModalSheetState();
}

class _PartnerRazorpayGatewayModalSheetState extends State<PartnerRazorpayGatewayModalSheet> {
  late Razorpay _razorpay;
  int _selectedTab = 0; // 0: UPI, 1: Card, 2: NetBanking
  String _selectedUpiApp = 'Google Pay';
  bool _isProcessing = false;
  String _processingStep = '';
  bool _isSuccess = false;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();

  final List<Map<String, dynamic>> _upiApps = [
    {'name': 'Google Pay', 'icon': Icons.account_balance_wallet_outlined, 'popular': true},
    {'name': 'PhonePe', 'icon': Icons.send_to_mobile_outlined, 'popular': true},
    {'name': 'Paytm', 'icon': Icons.account_balance_outlined, 'popular': true},
    {'name': 'BHIM UPI', 'icon': Icons.qr_code_2_outlined, 'popular': false},
  ];

  final List<String> _banks = ['HDFC Bank', 'State Bank of India', 'ICICI Bank', 'Axis Bank', 'Kotak Bank'];
  String _selectedBank = 'HDFC Bank';

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
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    Navigator.pop(context, {
      'success': true,
      'razorpay_order_id': response.orderId ?? widget.orderId,
      'razorpay_payment_id': response.paymentId,
      'razorpay_signature': response.signature,
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    final reason = response.message ?? 'Payment cancelled or declined by bank/gateway.';
    _showFailureDialog(reason);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _showFailureDialog('External wallet selected: ${response.walletName}');
  }

  void _showFailureDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
          'Payment process failed: $reason',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16155D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext); // close dialog
              Navigator.pop(context, {'success': false, 'message': reason}); // return failed result
            },
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executePayment() async {
    if (widget.orderId.isEmpty || widget.orderId.contains('mock')) {
      _showFailureDialog('Invalid Order ID returned from server.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStep = 'Opening Razorpay Gateway...';
    });

    try {
      final activeKey = widget.keyId.isNotEmpty && !widget.keyId.contains('mock')
          ? widget.keyId
          : (dotenv.env['NEXT_PUBLIC_RAZORPAY_KEY_ID'] ?? 'rzp_test_TCwlsGgFYgQdGL');

      final options = {
        'key': activeKey,
        'amount': (widget.amount * 100).toInt(),
        'name': widget.title,
        'description': widget.title,
        'order_id': widget.orderId,
        'timeout': 180,
      };

      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        _showFailureDialog(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0C2340),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shield_rounded, color: Colors.blueAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'RAZORPAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'SECURE',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              widget.title,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                      onPressed: _isProcessing ? null : () => Navigator.pop(context, {'success': false}),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ID: ${widget.orderId}', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                          const SizedBox(height: 2),
                          const Text('Amount Payable', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      Text(
                        '₹${widget.amount.toInt()}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _isSuccess ? Colors.green.shade50 : const Color(0xFF0C2340).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: _isSuccess
                        ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60)
                        : const SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(color: Color(0xFF0C2340), strokeWidth: 3.5),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isSuccess ? 'Payment Successful!' : 'Processing Payment...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isSuccess ? Colors.green.shade800 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _processingStep,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else ...[
            Container(
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  _buildTabItem(0, 'UPI Apps', Icons.qr_code_scanner_rounded),
                  _buildTabItem(1, 'Card', Icons.credit_card_rounded),
                  _buildTabItem(2, 'NetBanking', Icons.account_balance_rounded),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedTab == 0) ...[
                    const Text('Select UPI App', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Column(
                      children: _upiApps.map((app) {
                        final isAppSelected = _selectedUpiApp == app['name'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedUpiApp = app['name']),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isAppSelected ? const Color(0xFF0C2340).withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAppSelected ? const Color(0xFF0C2340) : Colors.grey.shade200,
                                width: isAppSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(app['icon'] as IconData, color: const Color(0xFF0C2340), size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(app['name'], style: TextStyle(fontSize: 13, fontWeight: isAppSelected ? FontWeight.bold : FontWeight.w500)),
                                ),
                                Radio<String>(
                                  value: app['name'],
                                  groupValue: _selectedUpiApp,
                                  activeColor: const Color(0xFF0C2340),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedUpiApp = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else if (_selectedTab == 1) ...[
                    const Text('Card Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Card Number',
                        hintText: '4000 1234 5678 9010',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cardExpiryController,
                            decoration: InputDecoration(
                              labelText: 'Expiry (MM/YY)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _cardCvvController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text('Choose Your Bank', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _banks.map((bank) => DropdownMenuItem(value: bank, child: Text(bank, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBank = val);
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, {'success': false}),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _executePayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C2340),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Pay ₹${widget.amount.toInt()}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF0C2340) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? const Color(0xFF0C2340) : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0C2340) : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
