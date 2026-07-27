import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/providers/auth_provider.dart';
import 'package:partner_app/screens/auth/select_service_location_screen.dart';
import 'package:partner_app/screens/auth/bank_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:partner_app/services/token_storage.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  final bool fromProfile;
  const IdentityVerificationScreen({super.key, this.fromProfile = false});

  @override
  ConsumerState<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends ConsumerState<IdentityVerificationScreen> {
  String? _selfiePath;
  String? _aadhaarFrontPath;
  String? _aadhaarBackPath;
  String? _panFrontPath;
  String? _panBackPath;

  @override
  void initState() {
    super.initState();
    _loadSavedDocuments();
  }

  Future<void> _loadSavedDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selfiePath = prefs.getString('local_selfie_path');
        _aadhaarFrontPath = prefs.getString('local_aadhaar_front_path');
        _aadhaarBackPath = prefs.getString('local_aadhaar_back_path');
        _panFrontPath = prefs.getString('local_pan_front_path');
        _panBackPath = prefs.getString('local_pan_back_path');
      });
    } catch (e) {
      debugPrint('Error loading saved documents: $e');
    }
  }

  Future<String?> _saveSingleDocumentLocally(String tempPath, String prefKey, String prefix) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final prefs = await SharedPreferences.getInstance();

      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        final extension = tempPath.split('.').last;
        final localFile = File('${directory.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$extension');
        await tempFile.copy(localFile.path);
        await prefs.setString(prefKey, localFile.path);
        return localFile.path;
      }
    } catch (e) {
      debugPrint('Error saving single document locally: $e');
    }
    return null;
  }

  Future<void> _takeSelfie() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 40,
      );
      if (photo != null) {
        final savedPath = await _saveSingleDocumentLocally(photo.path, 'local_selfie_path', 'selfie');
        setState(() {
          _selfiePath = savedPath ?? photo.path;
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
          final savedPath = await _saveSingleDocumentLocally(pictures.first, 'local_aadhaar_front_path', 'aadhaar_front');
          setState(() {
            _aadhaarFrontPath = savedPath ?? pictures.first;
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
          final savedPath = await _saveSingleDocumentLocally(pictures.first, 'local_aadhaar_back_path', 'aadhaar_back');
          setState(() {
            _aadhaarBackPath = savedPath ?? pictures.first;
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
          final savedPath = await _saveSingleDocumentLocally(pictures.first, 'local_pan_front_path', 'pan_front');
          setState(() {
            _panFrontPath = savedPath ?? pictures.first;
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
          final savedPath = await _saveSingleDocumentLocally(pictures.first, 'local_pan_back_path', 'pan_back');
          setState(() {
            _panBackPath = savedPath ?? pictures.first;
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

  Future<void> _pickFromGallery(String prefKey, String prefix, Function(String) onSaved) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (photo != null) {
        final savedPath = await _saveSingleDocumentLocally(photo.path, prefKey, prefix);
        setState(() {
          onSaved(savedPath ?? photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  void _showUploadOptions({
    required String documentTitle,
    required String scanOptionTitle,
    required String scanOptionSubtitle,
    required IconData scanIcon,
    required VoidCallback onScan,
    required VoidCallback onPickGallery,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Upload $documentTitle',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16155D),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose how you would like to provide this document',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onScan();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16155D).withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            scanIcon,
                            color: const Color(0xFF16155D),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scanOptionTitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16155D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                scanOptionSubtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black38),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onPickGallery();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16155D).withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            color: Color(0xFF16155D),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload from Device',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16155D),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Select photo or image from gallery/device',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black38),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
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
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 110,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF16155D),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
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
          onTap: () {
            _showUploadOptions(
              documentTitle: 'Selfie Verification',
              scanOptionTitle: 'Take Selfie Photo',
              scanOptionSubtitle: 'Use front camera to capture photo',
              scanIcon: Icons.camera_front_outlined,
              onScan: _takeSelfie,
              onPickGallery: () => _pickFromGallery(
                'local_selfie_path',
                'selfie',
                (path) => _selfiePath = path,
              ),
            );
          },
          child: _buildDashedContainer(
            height: 100,
            child: _selfiePath != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_selfiePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 100,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16155D),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
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
              onTap: () {
                _showUploadOptions(
                  documentTitle: 'Aadhaar Front Side',
                  scanOptionTitle: 'Scan Document',
                  scanOptionSubtitle: 'Use camera scanner with auto-crop',
                  scanIcon: Icons.document_scanner_outlined,
                  onScan: _scanAadhaarFront,
                  onPickGallery: () => _pickFromGallery(
                    'local_aadhaar_front_path',
                    'aadhaar_front',
                    (path) => _aadhaarFrontPath = path,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildCardSideUpload(
              title: 'Back Side',
              imagePath: _aadhaarBackPath,
              onTap: () {
                _showUploadOptions(
                  documentTitle: 'Aadhaar Back Side',
                  scanOptionTitle: 'Scan Document',
                  scanOptionSubtitle: 'Use camera scanner with auto-crop',
                  scanIcon: Icons.document_scanner_outlined,
                  onScan: _scanAadhaarBack,
                  onPickGallery: () => _pickFromGallery(
                    'local_aadhaar_back_path',
                    'aadhaar_back',
                    (path) => _aadhaarBackPath = path,
                  ),
                );
              },
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
              onTap: () {
                _showUploadOptions(
                  documentTitle: 'PAN Front Side',
                  scanOptionTitle: 'Scan Document',
                  scanOptionSubtitle: 'Use camera scanner with auto-crop',
                  scanIcon: Icons.document_scanner_outlined,
                  onScan: _scanPanFront,
                  onPickGallery: () => _pickFromGallery(
                    'local_pan_front_path',
                    'pan_front',
                    (path) => _panFrontPath = path,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildCardSideUpload(
              title: 'Back Side',
              imagePath: _panBackPath,
              onTap: () {
                _showUploadOptions(
                  documentTitle: 'PAN Back Side',
                  scanOptionTitle: 'Scan Document',
                  scanOptionSubtitle: 'Use camera scanner with auto-crop',
                  scanIcon: Icons.document_scanner_outlined,
                  onScan: _scanPanBack,
                  onPickGallery: () => _pickFromGallery(
                    'local_pan_back_path',
                    'pan_back',
                    (path) => _panBackPath = path,
                  ),
                );
              },
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
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => SelectServiceLocationScreen()),
                          );
                        }
                      },
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

                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(context);

                                    // 1. Process Selfie image and upload as Profile Image
                                    final selfieBytes = await File(_selfiePath!).readAsBytes();
                                    final selfieMime = _selfiePath!.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
                                    final base64Selfie = 'data:$selfieMime;base64,${base64Encode(selfieBytes)}';

                                    final selfieSuccess = await ref
                                        .read(authProvider.notifier)
                                        .updateProfileImage(base64Selfie);

                                    // 2. Process Aadhaar front image and upload as Document Image
                                    final frontBytes = await File(_aadhaarFrontPath!).readAsBytes();
                                    final frontMime = _aadhaarFrontPath!.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
                                    final base64Doc = 'data:$frontMime;base64,${base64Encode(frontBytes)}';
                                    await TokenStorage().saveIdProofUrl(base64Doc);

                                    final isAlreadyVerified = ref.read(providerProfileProvider).profileData?['kyc_status'] == 'verified';

                                    final success = await ref
                                        .read(providerProfileProvider.notifier)
                                        .updateProfile(
                                          aadharId: '763273659842',
                                          verificationDocs: {
                                            'id_proof_url': base64Doc,
                                          },
                                        );

                                    if ((success || isAlreadyVerified) && mounted) {
                                      if (widget.fromProfile) {
                                        navigator.pop();
                                        messenger.showSnackBar(
                                          const SnackBar(content: Text('Identity documents submitted successfully.')),
                                        );
                                      } else {
                                        navigator.push(
                                          MaterialPageRoute(
                                            builder: (context) => const BankDetailsScreen(),
                                          ),
                                        );
                                      }
                                    } else if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ref.read(providerProfileProvider).errorMessage ?? 'Failed to submit identity docs',
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
