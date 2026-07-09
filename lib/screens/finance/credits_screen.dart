import 'package:flutter/material.dart';
import 'package:partner_app/screens/finance/add_credits_screen.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  Widget _buildTopBar(BuildContext context) {
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
            'Credits',
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

  Widget _buildBalanceCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF1FE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Balance',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.hexagon,
                          color: Color(0xFF16155D),
                          size: 32,
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '144',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16155D),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCreditsScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16155D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '+ Add',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTabs() {
    final List<String> tabs = ['All History', 'Recharges', 'Expenses', 'Pending'];
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final bool isActive = index == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? const Color(0xFF1C1F3E) : Colors.black38,
                  ),
                ),
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 24,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1F3E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  const SizedBox(height: 8.5),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitlePrefix,
    String? subtitleName,
    required String value,
    required bool isPositive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(3),
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
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3047),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                      children: [
                        TextSpan(text: subtitlePrefix),
                        if (subtitleName != null) ...[
                          const TextSpan(text: ' • '),
                          TextSpan(
                            text: subtitleName,
                            style: const TextStyle(
                              color: Color(0xFF16155D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isPositive ? const Color(0xFF2E7D32) : const Color(0xFF2D3047),
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
        child: Column(
          children: [
            _buildTopBar(context),
            _buildBalanceCard(context),
            const SizedBox(height: 8),
            _buildPillTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTransactionCard(
                      icon: Icons.account_balance_wallet_outlined,
                      iconBgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                      title: 'Lead Refunded',
                      subtitlePrefix: '03 Jun 2026 • 04:45 PM',
                      subtitleName: 'Srishti',
                      value: '+ 32 cr.',
                      isPositive: true,
                    ),
                    _buildTransactionCard(
                      icon: Icons.shopping_bag_outlined,
                      iconBgColor: const Color(0xFFEFF1FE),
                      iconColor: const Color(0xFF16155D),
                      title: 'Lead Bought',
                      subtitlePrefix: '03 Jun 2026 • 04:31 PM',
                      subtitleName: 'Srishti',
                      value: '- 32 cr.',
                      isPositive: false,
                    ),
                    _buildTransactionCard(
                      icon: Icons.shopping_bag_outlined,
                      iconBgColor: const Color(0xFFEFF1FE),
                      iconColor: const Color(0xFF16155D),
                      title: 'Lead Bought',
                      subtitlePrefix: '31 May 2026 • 11:24 AM',
                      subtitleName: 'Sonali Kumari',
                      value: '- 36 cr.',
                      isPositive: false,
                    ),
                    _buildTransactionCard(
                      icon: Icons.payments_outlined,
                      iconBgColor: const Color(0xFFFFF9C4),
                      iconColor: const Color(0xFFF57F17),
                      title: 'Added from payout',
                      subtitlePrefix: '27 May 2026 • 07:36 AM',
                      value: '+ 91 cr.',
                      isPositive: true,
                    ),
                    _buildTransactionCard(
                      icon: Icons.shield_outlined,
                      iconBgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                      title: 'System Refund',
                      subtitlePrefix: '25 May 2026 • 10:15 AM',
                      value: '+ 10 cr.',
                      isPositive: true,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
