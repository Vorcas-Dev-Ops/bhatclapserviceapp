import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/auth_provider.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/screens/auth/approval_screen.dart';
import 'package:partner_app/screens/auth/tell_us_about_yourself_screen.dart';
import 'package:partner_app/screens/auth/services_you_offer_screen.dart';
import 'package:partner_app/screens/auth/identity_verification_screen.dart';
import 'package:partner_app/screens/auth/bank_details_screen.dart';
import 'package:partner_app/screens/home/home_screen.dart';
import 'package:partner_app/screens/onboarding/onboarding_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF16155D),
          ),
        ),
      );
    }

    if (authState.status == AuthStatus.unauthenticated ||
        authState.status == AuthStatus.error) {
      return const OnboardingScreen();
    }

    if (authState.status == AuthStatus.pendingRegistration) {
      return const TellUsAboutYourselfScreen();
    }

    if (authState.status == AuthStatus.authenticated) {
      final user = authState.user;
      final nameEntered = user?.name != null && user!.name!.isNotEmpty;
      final emailEntered = user?.email != null && user!.email!.isNotEmpty;

      if (!nameEntered || !emailEntered) {
        return const TellUsAboutYourselfScreen();
      }

      // If registered details are entered, perform the profile KYC check
      return const InitialProfileCheckGate();
    }

    return const OnboardingScreen();
  }
}

class InitialProfileCheckGate extends ConsumerStatefulWidget {
  const InitialProfileCheckGate({super.key});

  @override
  ConsumerState<InitialProfileCheckGate> createState() => _InitialProfileCheckGateState();
}

class _InitialProfileCheckGateState extends ConsumerState<InitialProfileCheckGate> {
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

    if (profileState.status == ProfileStatus.initial ||
        (profileState.status == ProfileStatus.loading && profileState.profileData == null)) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF16155D),
          ),
        ),
      );
    }

    if (profileState.status == ProfileStatus.error && profileState.profileData == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile: ${profileState.errorMessage}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 150,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(providerProfileProvider.notifier).fetchProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16155D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = profileState.profileData;
    if (profile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF16155D),
          ),
        ),
      );
    }

    // 1. Select Services Completeness Check
    final services = profile['services'] as List?;
    if (services == null || services.isEmpty) {
      return const ServicesYouOfferScreen();
    }

    // 2. Identity Verification (Aadhaar / ID Proof) Completeness Check
    final aadharLast4 = profile['aadhar_last4'];
    final idProofUrl = profile['verification_docs']?['id_proof_url'];
    if (aadharLast4 == null || idProofUrl == null || idProofUrl.toString().isEmpty) {
      return const IdentityVerificationScreen();
    }

    // 3. Bank Account Details Completeness Check
    final bankDetails = profile['bank_details'];
    if (bankDetails == null || bankDetails['bank_name'] == null || bankDetails['bank_name'].toString().isEmpty) {
      return const BankDetailsScreen();
    }

    // 4. KYC Approval Check
    final kycStatus = profile['kyc_status'] ?? 'pending';
    if (kycStatus == 'verified') {
      return const HomeScreen();
    } else {
      return const ApprovalScreen();
    }
  }
}
