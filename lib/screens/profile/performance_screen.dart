import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/providers/wallet_provider.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).fetchWalletAndReviews();
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
            'Performance',
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

  Widget _buildScoreHeader(double rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$rating / 5.0 Star Rating',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16155D),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Top Partner in your area',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final List<Map<String, dynamic>> chartData = [
      {'label': 'M', 'height': 48.0, 'isSelected': false},
      {'label': 'T', 'height': 56.0, 'isSelected': false},
      {'label': 'W', 'height': 32.0, 'isSelected': false},
      {'label': 'T', 'height': 68.0, 'isSelected': false},
      {'label': 'F', 'height': 52.0, 'isSelected': false},
      {'label': 'S', 'height': 72.0, 'isSelected': false},
      {'label': 'S', 'height': 85.0, 'isSelected': true},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: chartData.map((data) {
          final bool isSelected = data['isSelected'];
          return Column(
            children: [
              Container(
                width: 36,
                height: data['height'],
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF16155D) : const Color(0xFFEFF1FE),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data['label'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF16155D) : Colors.black38,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIndicatorCard({
    required Widget header,
    required String subtext,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          header,
          Text(
            subtext,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildIndicatorCard(
            header: const Text(
              '4.8',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3047),
              ),
            ),
            subtext: 'Average Rating',
            subtextColor: Colors.black38,
          ),
          _buildIndicatorCard(
            header: const Text(
              '98%',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3047),
              ),
            ),
            subtext: 'Response Rate',
            subtextColor: Colors.black38,
          ),
          _buildIndicatorCard(
            header: const Text(
              '99%',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            subtext: 'Job Acceptance',
            subtextColor: const Color(0xFF2E7D32),
          ),
          _buildIndicatorCard(
            header: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '100%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16155D),
                  ),
                ),
                Icon(Icons.bolt_outlined, color: Color(0xFF16155D), size: 20),
              ],
            ),
            subtext: 'On time Arrival',
            subtextColor: Colors.black38,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(List<dynamic> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Text(
            'Customer Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1F3E),
            ),
          ),
        ),
        if (reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              'No reviews submitted yet.',
              style: TextStyle(color: Colors.black38, fontSize: 13),
            ),
          )
        else
          ...reviews.map((r) {
            final int stars = (r['rating'] as num?)?.toInt() ?? 5;
            final user = r['user_id'] ?? {};
            final userName = user['name'] ?? 'Customer';
            final comment = r['comment'] ?? 'No comment provided.';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            Icons.star,
                            color: i < stars ? Colors.orange : Colors.grey[300],
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final profileState = ref.watch(providerProfileProvider);
    final profile = profileState.profileData ?? {};
    final rating = (profile['average_rating'] as num?)?.toDouble() ?? 5.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(walletProvider.notifier).fetchWalletAndReviews(),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildScoreHeader(rating),
                      _buildWeeklyChart(),
                      const SizedBox(height: 8),
                      _buildIndicatorsGrid(),
                      const SizedBox(height: 8),
                      _buildReviewsSection(walletState.reviews),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
