import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:partner_app/config/config.dart';
import 'package:partner_app/providers/api_providers.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/widgets/razorpay_gateway_modal.dart';

class StarterKitScreen extends ConsumerStatefulWidget {
  final String providerName;

  const StarterKitScreen({super.key, this.providerName = ''});

  @override
  ConsumerState<StarterKitScreen> createState() => _StarterKitScreenState();
}

class _StarterKitScreenState extends ConsumerState<StarterKitScreen> {
  String _selectedSize = 'L';
  bool _wantsAccessories = false;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _dbOrderId;
  String? _lastOrderId;

  late Razorpay _razorpay;

  final List<String> _sizes = ['S', 'M', 'L', 'XL', 'XXL'];
  
  // Kit Details
  final double kitPrice = 699;
  final double gstPercent = 0.18;
  final double deliveryCharge = 50;
  final double convenienceFee = 20;

  double get gstAmount => kitPrice * gstPercent;
  double get grandTotal => kitPrice + gstAmount + deliveryCharge + convenienceFee;

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
    super.dispose();
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startPaymentFlow() async {
    if (!_acceptedTerms) {
      _showToast('Please accept the terms and conditions');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final apiClient = ref.read(apiClientProvider);
      
      String? kitId;
      try {
        final kitRes = await apiClient.dio.get('/api/providers/onboarding/starter-kit');
        kitId = kitRes.data?['_id'];
      } catch (_) {}

      final response = await apiClient.dio.post(
        '/api/providers/onboarding/create-order',
        data: {
          if (kitId != null) 'kitId': kitId,
          'kitSize': _selectedSize,
          'accessories': [],
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final options = {
          'key': Config.razorpayKeyId,
          'amount': data['amount'],
          'name': 'BharathClap Provider',
          'description': 'Provider Starter Kit',
          'order_id': data['orderId'],
          'notes': {
            'dbOrderId': data['dbOrderId'],
          },
          'prefill': {
            'contact': ref.read(providerProfileProvider).profileData?['user_id']?['phone'] ?? '',
            'email': ref.read(providerProfileProvider).profileData?['user_id']?['email'] ?? '',
          },
          'theme': {'color': '#3B41C5'}
        };
        
        _dbOrderId = data['dbOrderId'];
        final orderId = data['orderId'];
        _lastOrderId = orderId;
        try {
          _razorpay.open(options);
        } catch (_) {
          await _triggerGatewayModalFallback(orderId);
        }
      } else {
        _showToast('Failed to create order');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showToast('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerGatewayModalFallback(String orderId) async {
    final paymentResult = await _showRazorpayGatewayModal(orderId, Config.razorpayKeyId, grandTotal);
    if (paymentResult != null && paymentResult['success'] == true) {
      await _handlePaymentSuccess(PaymentSuccessResponse.fromMap({
        'payment_id': paymentResult['razorpay_payment_id'],
        'order_id': paymentResult['razorpay_order_id'],
        'signature': paymentResult['razorpay_signature'],
      }));
    } else {
      _showToast('Payment cancelled.');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _showRazorpayGatewayModal(String orderId, String keyId, double amount) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => PartnerRazorpayGatewayModalSheet(
        orderId: orderId,
        keyId: keyId,
        amount: amount,
        title: 'BharatClap Starter Kit',
      ),
    );
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      if (_dbOrderId == null) throw Exception('Order ID missing locally');

      final apiClient = ref.read(apiClientProvider);
      final verifyResponse = await apiClient.dio.post(
        '/api/providers/onboarding/verify-payment',
        data: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'dbOrderId': _dbOrderId,
        },
      );

      if (verifyResponse.data['success'] == true) {
        _showToast('Payment Successful! Kit Purchased.');
        // Refresh profile data
        ref.read(providerProfileProvider.notifier).fetchProfile();
        if (mounted) Navigator.pop(context);
      } else {
        _showToast('Verification failed by server');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showToast('Payment Verification Failed: $e');
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    if (_lastOrderId != null && _lastOrderId!.isNotEmpty) {
      await _triggerGatewayModalFallback(_lastOrderId!);
    } else {
      _showToast('Payment Failed: ${response.message}');
      setState(() => _isLoading = false);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showToast('External Wallet Selected: ${response.walletName}');
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B41C5), // Matches banner
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Onboarding Kit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blue Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Color(0xFF3B41C5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Verification Approved',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Complete Your Onboarding',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome, ${widget.providerName.toUpperCase()}! Purchase your mandatory Provider Kit to get started. You may also add category-specific accessories.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Kit Details Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fixvo Professional Starter Kit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Complete onboarding kit for providers available', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Kit image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/starterkit.png',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('WHAT\'S INCLUDED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildIncludedItem('Fixvo Uniform T-Shirt', 'Professional branded uniform')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildIncludedItem('Fixvo Carry Bag', 'Durable equipment bag')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildIncludedItem('Provider ID Card', 'Official identification lanyard'),
                        
                        const SizedBox(height: 24),
                        const Text('SELECT UNIFORM SIZE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(
                          children: _sizes.map((size) {
                            final isSelected = size == _selectedSize;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSize = size;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF1E1B4B) : Colors.white,
                                  border: Border.all(color: isSelected ? const Color(0xFF1E1B4B) : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  size,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text('Delivered in 5 days via Delhivery', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(width: 16),
                            Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text('GST 18% included', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Accessories Card
                  _buildCard(
                    child: CheckboxListTile(
                      value: _wantsAccessories,
                      onChanged: (val) {
                        setState(() {
                          _wantsAccessories = val ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Yes, I would like to purchase additional accessories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Browse and select professional tools and equipment specific to your service category.', style: TextStyle(fontSize: 12)),
                      secondary: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                    )
                  ),

                  const SizedBox(height: 16),

                  // Payment Summary
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 20),
                        const Text('PROVIDER KIT', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildPriceRow('Fixvo Professional Starter Kit', '₹699'),
                        const SizedBox(height: 8),
                        _buildPriceRow('GST (18%)', '₹126'),
                        const SizedBox(height: 8),
                        _buildPriceRow('Delivery', '₹50'),
                        const SizedBox(height: 8),
                        _buildPriceRow('Convenience Fee', '₹20'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('₹895', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E1B4B))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 8),
                              const Text('By proceeding, you agree to:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              _buildBullet('Wear the uniform during all jobs.'),
                              _buildBullet('Maintain a minimum rating of 4.2 stars.'),
                              _buildBullet('Follow the standard pricing guidelines.'),
                              _buildBullet('Complete the mandatory training.'),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _acceptedTerms,
                                      onChanged: (val) {
                                        setState(() {
                                          _acceptedTerms = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'I have read and agree to the platform guidelines and terms of service.',
                                      style: TextStyle(fontSize: 12, color: Colors.black87),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : (_acceptedTerms ? _startPaymentFlow : null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E1B4B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Proceed to Payment >', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Skip for now →',
                              style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                        const Center(
                          child: Text(
                            'You can complete payment later from your profile',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        )
                      ],
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

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIncludedItem(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        Text(amount, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }
}
