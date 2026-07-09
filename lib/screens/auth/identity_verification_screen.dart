import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/screens/auth/bank_details_screen.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends ConsumerState<IdentityVerificationScreen> {
  String? _selfiePath;
  String? _aadhaarFrontPath;
  String? _aadhaarBackPath;
  String? _panFrontPath;
  String? _panBackPath;

  Future<void> _takeSelfie() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
      if (photo != null) {
        setState(() {
          _selfiePath = photo.path;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to take a selfie.')),
        );
      }
    }
  }

  Future<void> _scanAadhaarFront() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        List<String>? pictures = await CunningDocumentScanner.getPictures(
          androidScannerMode: AndroidScannerMode.base,
        );
        if (pictures != null && pictures.isNotEmpty) {
          setState(() {
            _aadhaarFrontPath = pictures.first;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scanner error: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to scan documents.')),
        );
      }
    }
  }

  Future<void> _scanAadhaarBack() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        List<String>? pictures = await CunningDocumentScanner.getPictures(
          androidScannerMode: AndroidScannerMode.base,
        );
        if (pictures != null && pictures.isNotEmpty) {
          setState(() {
            _aadhaarBackPath = pictures.first;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scanner error: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to scan documents.')),
        );
      }
    }
  }

  Future<void> _scanPanFront() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        List<String>? pictures = await CunningDocumentScanner.getPictures(
          androidScannerMode: AndroidScannerMode.base,
        );
        if (pictures != null && pictures.isNotEmpty) {
          setState(() {
            _panFrontPath = pictures.first;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scanner error: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to scan documents.')),
        );
      }
    }
  }

  Future<void> _scanPanBack() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        List<String>? pictures = await CunningDocumentScanner.getPictures(
          androidScannerMode: AndroidScannerMode.base,
        );
        if (pictures != null && pictures.isNotEmpty) {
          setState(() {
            _panBackPath = pictures.first;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scanner error: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to scan documents.')),
        );
      }
    }
  }

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

  Widget _buildCardSideUpload({
    required String title,
    required String? imagePath,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: _buildDashedContainer(
          height: 110,
          child: imagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 110,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF16155D),
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
        ),
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
        GestureDetector(
          onTap: _takeSelfie,
          child: _buildDashedContainer(
            height: 100,
            child: _selfiePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_selfiePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 100,
                    ),
                  )
                : const Column(
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
          'Upload front and back photos of your Aadhaar Card',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCardSideUpload(
              title: 'Front Side',
              imagePath: _aadhaarFrontPath,
              onTap: _scanAadhaarFront,
            ),
            const SizedBox(width: 12),
            _buildCardSideUpload(
              title: 'Back Side',
              imagePath: _aadhaarBackPath,
              onTap: _scanAadhaarBack,
            ),
          ],
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
          'Upload front and back photos of your Pan Card',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCardSideUpload(
              title: 'Front Side',
              imagePath: _panFrontPath,
              onTap: _scanPanFront,
            ),
            const SizedBox(width: 12),
            _buildCardSideUpload(
              title: 'Back Side',
              imagePath: _panBackPath,
              onTap: _scanPanBack,
            ),
          ],
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
                                    if (_selfiePath == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please upload your selfie verification photo.')),
                                      );
                                      return;
                                    }
                                    if (_aadhaarFrontPath == null || _aadhaarBackPath == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please capture both front and back of your Aadhaar Card.')),
                                      );
                                      return;
                                    }
                                    if (_panFrontPath == null || _panBackPath == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please capture both front and back of your Pan Card.')),
                                      );
                                      return;
                                    }

                                    final frontBytes = await File(_aadhaarFrontPath!).readAsBytes();
                                    final base64Doc = 'data:image/png;base64,${base64Encode(frontBytes)}';

                                    final success = await ref
                                        .read(providerProfileProvider.notifier)
                                        .updateProfile(
                                          aadharId: '763273659842',
                                          verificationDocs: {
                                            'id_proof_url': base64Doc,
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
