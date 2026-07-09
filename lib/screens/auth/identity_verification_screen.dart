import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/screens/auth/bank_details_screen.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends ConsumerState<IdentityVerificationScreen> {
  Widget _buildDashedContainer({required double height, required Widget child}) {
    return CustomPaint(
      painter: DashedRectPainter(
        color: const Color(0xFFC5C9E0),
        strokeWidth: 1.0,
        gap: 5.0,
        strokeLength: 8.0,
        borderRadius: 16.0,
      ),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }

  Widget _buildCameraIcon() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.add_a_photo_outlined,
        color: Color(0xFF16155D),
        size: 26,
      ),
    );
  }

  Widget _buildSelfieVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selfie Verification',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF16155D),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ensure your face is clearly visible without glasses or hats',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 12),
        _buildDashedContainer(
          height: 100,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: Color(0xFF16155D),
                size: 28,
              ),
              SizedBox(height: 6),
              Text(
                'Upload or take a photo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAadhaarVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aadhaar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF16155D),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Upload a clear photo of your Aadhaar Card',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 12),
        _buildDashedContainer(
          height: 110,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Mock Aadhaar Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFCFD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        // Profile Pic Mock
                        Container(
                          width: 40,
                          height: 50,
                          color: const Color(0xFFE5E7EB),
                          child: const Icon(Icons.person, size: 24, color: Colors.black26),
                        ),
                        const SizedBox(width: 10),
                        // Text Lines Mock
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Government Text
                              Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  Container(width: 40, height: 4, color: Colors.black12),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Name
                              Container(width: 60, height: 4, color: Colors.black26),
                              const SizedBox(height: 4),
                              // Aadhaar Number (simulated red number from design)
                              const Text(
                                '7632 7365 9842',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.redAccent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Footer Green Line
                              Container(width: double.infinity, height: 3, color: Colors.green.shade400),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildCameraIcon(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF16155D),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Upload a clear photo of your Pan Card',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 12),
        _buildDashedContainer(
          height: 110,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Mock PAN Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFEBF3FC), const Color(0xFFE1EDFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD0E1F5)),
                    ),
                    child: Row(
                      children: [
                        // Profile Pic Mock
                        Container(
                          width: 40,
                          height: 50,
                          color: const Color(0x0D000000),
                          child: const Icon(Icons.person, size: 24, color: Colors.black12),
                        ),
                        const SizedBox(width: 10),
                        // PAN Text Lines Mock
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(width: 30, height: 4, color: Colors.black26),
                                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(width: 50, height: 4, color: Colors.black12),
                              const SizedBox(height: 4),
                              Container(width: 70, height: 4, color: Colors.black12),
                              const SizedBox(height: 6),
                              // Hologram/Barcode Mock
                              Row(
                                children: [
                                  Container(width: 15, height: 15, color: Colors.amber.shade300),
                                  const SizedBox(width: 8),
                                  Container(width: 45, height: 8, color: Colors.black38),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildCameraIcon(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Progress Bar (Step 3 of 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: index <= 2 ? const Color(0xFF16155D) : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Let\'s Verify Your Identity',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16155D),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Identity Verification',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Documents Verification Scroll list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildSelfieVerification(),
                    const SizedBox(height: 24),
                    _buildAadhaarVerification(),
                    const SizedBox(height: 24),
                    _buildPanVerification(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Area
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 20.0, top: 10.0),
              child: Row(
                children: [
                  // Back Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF1FE),
                        foregroundColor: const Color(0xFF16155D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Continue Button
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final profileState = ref.watch(providerProfileProvider);
                          final isLoading = profileState.status == ProfileStatus.loading;

                          return ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final success = await ref
                                        .read(providerProfileProvider.notifier)
                                        .updateProfile(
                                          aadharId: '763273659842',
                                          verificationDocs: {
                                            'id_proof_url': 'https://cloudinary.com/mock-id-proof.jpg',
                                          },
                                        );

                                    if (success && mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const BankDetailsScreen(),
                                        ),
                                      );
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            profileState.errorMessage ?? 'Failed to submit identity docs',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16155D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.chevron_right, color: Colors.white, size: 18),
                                    ],
                                  ),
                          );
                        },
                      ),
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
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double strokeLength;
  final double borderRadius;

  DashedRectPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.strokeLength = 6.0,
    this.borderRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    // Dash the path
    final dashPath = _dashPath(path, gap, strokeLength);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path source, double gap, double dashLength) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashLength : gap;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
