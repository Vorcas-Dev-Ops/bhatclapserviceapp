import 'package:flutter/material.dart';

class AddCreditsScreen extends StatefulWidget {
  const AddCreditsScreen({super.key});

  @override
  State<AddCreditsScreen> createState() => _AddCreditsScreenState();
}

class _AddCreditsScreenState extends State<AddCreditsScreen> {
  int _selectedAmount = 100;
  final TextEditingController _creditsController = TextEditingController(text: '100');

  @override
  void dispose() {
    _creditsController.dispose();
    super.dispose();
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
                onTap: () => _selectAmount(20),
                child: _buildQuickSelectOption(20, false),
              ),
              const SizedBox(width: 14),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Methods',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1F3E),
            ),
          ),
          const SizedBox(height: 16),
          // UPI Expandable Card
          Container(
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
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF1FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_outlined,
                          color: Color(0xFF16155D),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'UPI',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3047),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Instant & Secure',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black38,
                        size: 24,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEFF1FE)),
                // Expanded options row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildUpiOption('GPay', Icons.payments_outlined),
                      _buildUpiOption('PhonePe', Icons.account_balance_wallet_outlined),
                      _buildUpiOption('Other UPI', Icons.qr_code_scanner_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Saved Cards Card
          Container(
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
                    Icons.credit_card_outlined,
                    color: Color(0xFF16155D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Saved Cards',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3047),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'HDFC Debit Card •••• 1234',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black38,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiOption(String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFF16155D),
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF2D3047),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $_selectedAmount credits successfully!'),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                  Navigator.pop(context);
                },
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
                        _buildPaymentMethods(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildBottomStickyBar(),
          ],
        ),
      ),
    );
  }
}
