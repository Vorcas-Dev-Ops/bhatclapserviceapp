import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/jobs_provider.dart';

class JobHistoryScreen extends ConsumerStatefulWidget {
  const JobHistoryScreen({super.key});

  @override
  ConsumerState<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends ConsumerState<JobHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobsProvider.notifier).fetchAllJobs();
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
            'Job History',
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

  Widget _buildJobHistoryCard({
    required String name,
    required String category,
    required String time,
    required String date,
    required String jobValue,
    required String paidAmount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1F3E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF16155D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1F3E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(
                color: Color(0xFFEFF1FE),
                thickness: 1,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.black38,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Job Value: $jobValue',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFF2E7D32),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Payout: $paidAmount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);
    final completedBookings = jobsState.bookings.where((b) => b['status'] == 'completed').toList();
    final isLoading = jobsState.status == JobsStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => ref.read(jobsProvider.notifier).fetchAllJobs(),
                      child: completedBookings.isEmpty
                          ? const Center(
                              child: Text(
                                'No completed job history yet.',
                                style: TextStyle(color: Colors.black38, fontSize: 14),
                              ),
                            )
                          : ListView.builder(
                              itemCount: completedBookings.length,
                              itemBuilder: (context, index) {
                                final booking = completedBookings[index];
                                final subservice = booking['subservice_id'] ?? {};
                                final serviceName = subservice['subservice_name'] ?? booking['variant_name'] ?? 'Cleaning Service';
                                final user = booking['user_id'] ?? {};
                                final userName = user['name'] ?? 'Customer';
                                final amount = booking['payable_amount'] ?? booking['amount'] ?? 0;
                                final payout = (amount * 0.8).toStringAsFixed(0);

                                return _buildJobHistoryCard(
                                  name: userName,
                                  category: serviceName,
                                  time: booking['booking_time'] ?? 'Now',
                                  date: booking['scheduled_at'] ?? 'Today',
                                  jobValue: '₹$amount',
                                  paidAmount: '₹$payout',
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
