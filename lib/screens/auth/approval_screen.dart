import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/screens/auth/identity_verification_screen.dart';
import 'package:partner_app/screens/home/home_screen.dart';

class ApprovalScreen extends ConsumerStatefulWidget {
  const ApprovalScreen({super.key});

  @override
  ConsumerState<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends ConsumerState<ApprovalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(providerProfileProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(providerProfileProvider);
    final kycStatus = profileState.profileData?['kyc_status'] ?? 'pending';
    final rejectionReason = profileState.profileData?['kyc_rejection_reason'] ?? 'Submitted details did not meet the guidelines.';
    final isLoading = profileState.status == ProfileStatus.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Illustration Image
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/intro3.png',
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Dynamic Content based on KYC Status
              if (kycStatus == 'verified') ...[
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Profile Approved!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16155D),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Congratulations! Your provider profile has been verified. You can now start receiving service bookings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ] else if (kycStatus == 'rejected') ...[
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Verification Rejected',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16155D),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Reason: $rejectionReason',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.redAccent,
                    height: 1.5,
                  ),
                ),
              ] else ...[
                const Text(
                  'Your Profile is Under Review',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16155D),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thank You! We\'ve received your details and our team is reviewing them. Once approved, you\'ll receive a notification.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Action Buttons
              if (kycStatus == 'verified') ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16155D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Enter Application',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else if (kycStatus == 'rejected') ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IdentityVerificationScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16155D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Re-verify Identity',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () => ref.read(providerProfileProvider.notifier).fetchProfile(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF16155D)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Check Status',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF16155D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            // Let them close the screen but keep them unverified
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16155D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Got it',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              if (kycStatus == 'pending') ...[
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: Colors.black45,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Verification usually takes a few hours',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
