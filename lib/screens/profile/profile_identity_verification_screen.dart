import 'package:flutter/material.dart';

class ProfileIdentityVerificationScreen extends StatefulWidget {
  const ProfileIdentityVerificationScreen({super.key});

  @override
  State<ProfileIdentityVerificationScreen> createState() => _ProfileIdentityVerificationScreenState();
}

class _ProfileIdentityVerificationScreenState extends State<ProfileIdentityVerificationScreen> {
  bool _isAadhaarExpanded = true;
  bool _isPanExpanded = true;
  final TextEditingController _panController = TextEditingController(text: 'ABCDE1234F');

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  Widget _buildAadhaarCardMockup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          // National emblem / Tricolor top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Indian emblem placeholder
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFC),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.account_balance, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Govt.',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              // Tricolor bar
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.white, Colors.green],
                        stops: [0.33, 0.66, 1.0],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Government of India',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              // UIDAI Logo placeholder
              Container(
                width: 24,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(10),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Center(
                  child: Icon(Icons.wb_sunny_outlined, size: 10, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Aadhaar photo and info fields row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo box
              Container(
                width: 76,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 40, color: Colors.black26),
                ),
              ),
              const SizedBox(width: 16),
              // Name / details placeholder lines
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(width: 80, height: 12, decoration: BoxDecoration(color: const Color(0xFFEFF1FE), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(width: 60, height: 12, decoration: BoxDecoration(color: const Color(0xFFEFF1FE), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(width: 70, height: 12, decoration: BoxDecoration(color: const Color(0xFFEFF1FE), borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
              // QR Code box
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_2, size: 44, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Aadhaar ID digits
          const Center(
            child: Text(
              'X X X',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
                color: Color(0xFF1C1F3E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentBox() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                color: const Color(0xFF16155D),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'By continuing, I freely and explicitly consent to Bharat Clap receiving my Aadhaar demographic information (name, date of birth, address) and photograph via UIDAI’s secure app integration, solely to verify my identity during onboarding.\n\n'
                    'I may withdraw this consent by writing to privacy@bharatclap.com, although I acknowledge that this may affect my ability to complete onboarding or continue to avail services on the Bharat Clap platform.\n\n'
                    'I agree and acknowledge that my data will be treated as per Bharat Clap\'s privacy policy.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withAlpha(160),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanCardMockup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'INCOME TAX DEPARTMENT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16155D)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Govt. of India',
                    style: TextStyle(fontSize: 8, color: Colors.black54),
                  ),
                ],
              ),
              const Icon(Icons.account_balance, size: 20, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 64,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 36, color: Colors.black26),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 12, decoration: BoxDecoration(color: const Color(0xFFEFF1FE), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 10),
                    Container(width: 80, height: 12, decoration: BoxDecoration(color: const Color(0xFFEFF1FE), borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _panController.text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: Color(0xFF1C1F3E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
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
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1C1F3E), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Identity Verification',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1F3E),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aadhar Card Accordion
                    Theme(
                      data: ThemeData().copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        tilePadding: EdgeInsets.zero,
                        onExpansionChanged: (val) {
                          setState(() {
                            _isAadhaarExpanded = val;
                          });
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF1FE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.badge_outlined, color: Color(0xFF16155D), size: 20),
                        ),
                        title: const Text(
                          'Aadhar Card',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3047),
                          ),
                        ),
                        trailing: Icon(
                          _isAadhaarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: const Color(0xFF2D3047),
                        ),
                        children: [
                          const SizedBox(height: 8),
                          _buildAadhaarCardMockup(),
                          const SizedBox(height: 16),
                          const Text(
                            'Allow Bharat Clap to verify Aadhaar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1F3E),
                            ),
                          ),
                          _buildConsentBox(),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFFEFF1FE), thickness: 1, height: 32),

                    // PAN Card Accordion
                    Theme(
                      data: ThemeData().copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        tilePadding: EdgeInsets.zero,
                        onExpansionChanged: (val) {
                          setState(() {
                            _isPanExpanded = val;
                          });
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF1FE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.credit_card_outlined, color: Color(0xFF16155D), size: 20),
                        ),
                        title: const Text(
                          'PAN Card',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3047),
                          ),
                        ),
                        trailing: Icon(
                          _isPanExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: const Color(0xFF2D3047),
                        ),
                        children: [
                          const SizedBox(height: 8),
                          _buildPanCardMockup(),
                          const SizedBox(height: 20),
                          const Text(
                            'Enter PAN Number',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3047),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _panController,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1F3E),
                            ),
                            decoration: InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF16155D), width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoBox(
                            icon: Icons.info_outline,
                            text: 'Please ensure the name on your PAN card matches your bank account details for successful payouts.',
                            backgroundColor: const Color(0xFFF5F6FA),
                            iconColor: const Color(0xFF16155D),
                            textColor: Colors.black87,
                          ),
                          _buildInfoBox(
                            icon: Icons.info_outline,
                            text: 'Verification usually takes less than 60 seconds after providing OTP.',
                            backgroundColor: const Color(0xFFEFF1FE),
                            iconColor: const Color(0xFF16155D),
                            textColor: const Color(0xFF16155D),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
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
