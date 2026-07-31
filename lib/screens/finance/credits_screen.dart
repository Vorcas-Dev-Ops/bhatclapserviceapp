import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/wallet_provider.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/screens/finance/add_credits_screen.dart';

class CreditsScreen extends ConsumerStatefulWidget {
  const CreditsScreen({super.key});

  @override
  ConsumerState<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends ConsumerState<CreditsScreen> {
  int _activeTab = 0; // 0: All, 1: Recharges, 2: Expenses, 3: Pending

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).fetchWalletAndReviews();
      ref.read(providerProfileProvider.notifier).fetchProfile();
    });
  }

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

  Widget _buildBalanceCard(BuildContext context, int credits) {
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
                    Text(
                      credits.toString(),
                      style: const TextStyle(
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
                      ).then((_) {
                        ref.read(walletProvider.notifier).fetchWalletAndReviews();
                        ref.read(providerProfileProvider.notifier).fetchProfile();
                      });
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
          final bool isActive = index == _activeTab;
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = index;
                });
              },
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                        if (subtitleName != null && subtitleName.isNotEmpty) ...[
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
            const SizedBox(width: 8),
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

  String _formatDateTime(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(rawDate);
      if (dt == null) return '';
      
      final localDt = dt.toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final day = localDt.day.toString().padLeft(2, '0');
      final month = months[localDt.month - 1];
      final year = localDt.year;
      
      final hourNum = localDt.hour > 12 ? localDt.hour - 12 : (localDt.hour == 0 ? 12 : localDt.hour);
      final hour = hourNum.toString().padLeft(2, '0');
      final minute = localDt.minute.toString().padLeft(2, '0');
      final period = localDt.hour >= 12 ? 'PM' : 'AM';
      
      return '$day $month $year • $hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(providerProfileProvider);
    final profile = profileState.profileData;
    
    int credits = 0;
    if (profile != null) {
      final walletBalance = profile['walletBalance'] ?? 0.0;
      final reservedBalance = profile['reservedBalance'] ?? 0.0;
      final creditLimit = profile['creditLimit'] ?? 500.0;
      final availableCredit = (walletBalance as num).toDouble() - (reservedBalance as num).toDouble() + (creditLimit as num).toDouble();
      credits = (availableCredit / 10).toInt();
    }

    final walletState = ref.watch(walletProvider);
    final allTx = walletState.transactions;

    // Filter transactions based on active tab
    // 0: All, 1: Recharges, 2: Expenses, 3: Pending
    final filteredTx = allTx.where((tx) {
      final status = tx['status'] ?? 'success';
      final type = tx['type'] ?? '';

      if (_activeTab == 3) {
        return status == 'pending';
      }
      
      // Filter out pending from history / recharges / expenses
      if (status == 'pending') {
        return false;
      }

      if (_activeTab == 1) {
        return type == 'recharge';
      } else if (_activeTab == 2) {
        return type == 'deduction' || type == 'hold';
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            _buildBalanceCard(context, credits),
            const SizedBox(height: 8),
            _buildPillTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(walletProvider.notifier).fetchWalletAndReviews();
                  await ref.read(providerProfileProvider.notifier).fetchProfile();
                },
                child: filteredTx.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: const Text(
                            'No transactions found for this category.',
                            style: TextStyle(color: Colors.black38, fontSize: 14),
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredTx.length,
                        itemBuilder: (context, index) {
                          final tx = filteredTx[index];
                          final type = tx['type'] ?? '';
                          final rawAmount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                          final creditsValue = (rawAmount / 10).toInt();
                          final description = tx['description'] ?? 'Transaction';
                          final dateStr = _formatDateTime(tx['createdAt'] ?? '');
                          final status = tx['status'] ?? '';
                          
                          IconData icon = Icons.account_balance_wallet_outlined;
                          Color iconBgColor = const Color(0xFFEFF1FE);
                          Color iconColor = const Color(0xFF16155D);
                          bool isPositive = true;

                          if (type == 'recharge') {
                            icon = Icons.payments_outlined;
                            iconBgColor = const Color(0xFFFFF9C4);
                            iconColor = const Color(0xFFF57F17);
                            isPositive = true;
                          } else if (type == 'refund' || type == 'release') {
                            icon = Icons.shield_outlined;
                            iconBgColor = const Color(0xFFE8F5E9);
                            iconColor = const Color(0xFF2E7D32);
                            isPositive = true;
                          } else if (type == 'deduction') {
                            icon = Icons.shopping_bag_outlined;
                            iconBgColor = const Color(0xFFEFF1FE);
                            iconColor = const Color(0xFF16155D);
                            isPositive = false;
                          } else if (type == 'hold') {
                            icon = Icons.flash_on_outlined;
                            iconBgColor = const Color(0xFFFFEBEE);
                            iconColor = Colors.red;
                            isPositive = false;
                          }

                          String displayTitle = description;
                          if (status == 'pending') {
                            displayTitle = '$description (Pending)';
                          }

                          return _buildTransactionCard(
                            icon: icon,
                            iconBgColor: iconBgColor,
                            iconColor: iconColor,
                            title: displayTitle,
                            subtitlePrefix: dateStr,
                            value: '${isPositive ? "+" : "-"} $creditsValue cr.',
                            isPositive: isPositive,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
