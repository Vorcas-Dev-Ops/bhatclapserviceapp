import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF16155D), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Color(0xFF1C1F3E), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BharatClap Partner Privacy & Data Protection Policy',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16155D)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Updated: August 2026 • DPDPA 2023 Compliant',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const Divider(height: 24),
                  _buildSection(
                    '1. Data Collection & Usage',
                    'BharatClap collects necessary partner information including full name, phone number, government identity proof (Aadhaar/PAN/Voter ID), bank details for payouts, and real-time location data when online to match you with nearby job dispatches.',
                  ),
                  _buildSection(
                    '2. Location Access & Dispatch Matching',
                    'Foreground and background location access is used strictly to enable lead marketplace matching, route optimization to customer locations, and safety tracking during active jobs.',
                  ),
                  _buildSection(
                    '3. Financial & Payout Security',
                    'Bank account details and UPI IDs are processed securely through certified PCI-DSS payment partners (Razorpay). Earnings and COD remittances are recorded in append-only financial audit logs.',
                  ),
                  _buildSection(
                    '4. DPDPA Right to Erasure & Data Portability',
                    'Under the Digital Personal Data Protection Act (DPDPA 2023), you have the right to request a complete export of your personal data or initiate account deletion. Account deletion initiates a 30-day cooling period during which all active job obligations and COD dues must be settled.',
                  ),
                  _buildSection(
                    '5. Contact Data Protection Officer',
                    'For privacy inquiries or compliance concerns, reach out to our Data Protection Officer at privacy@bharatclap.com.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E)),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.45),
          ),
        ],
      ),
    );
  }
}
