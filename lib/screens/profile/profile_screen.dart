import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:partner_app/providers/auth_provider.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/providers/job_dispatch_provider.dart';
import 'package:partner_app/screens/onboarding/onboarding_screen.dart';
import 'package:partner_app/screens/finance/loans_screen.dart';
import 'package:partner_app/screens/profile/profile_identity_verification_screen.dart';
import 'package:partner_app/screens/jobs/calendar_screen.dart';
import 'package:partner_app/screens/jobs/job_history_screen.dart';
import 'package:partner_app/screens/finance/credits_screen.dart';
import 'package:partner_app/screens/profile/performance_screen.dart';
import 'package:partner_app/screens/finance/insurance_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _localSelfiePath;

  @override
  void initState() {
    super.initState();
    _loadLocalSelfie();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(providerProfileProvider.notifier).fetchProfile();
    });
  }

  Future<void> _loadLocalSelfie() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString('local_selfie_path');
      if (savedPath != null && File(savedPath).existsSync()) {
        setState(() {
          _localSelfiePath = savedPath;
        });
      }
    } catch (e) {
      debugPrint('Error loading local selfie path: $e');
    }
  }

  ImageProvider? _resolveProfileImageProvider(String? remoteOrLocalPath) {
    // 1. Try local selfie file if it exists
    if (_localSelfiePath != null && _localSelfiePath!.isNotEmpty) {
      final file = File(_localSelfiePath!);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    if (remoteOrLocalPath == null || remoteOrLocalPath.trim().isEmpty) {
      return null;
    }

    final pathStr = remoteOrLocalPath.trim();

    // 2. Try file path
    if (pathStr.startsWith('/') || pathStr.startsWith('file:') || (pathStr.length > 3 && pathStr[1] == ':')) {
      final cleanPath = pathStr.replaceFirst('file://', '');
      final file = File(cleanPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    // 3. Try Base64 string
    if (pathStr.startsWith('data:image/') || pathStr.startsWith('data:;base64,')) {
      try {
        final base64Content = pathStr.split(',').last;
        final bytes = base64Decode(base64Content);
        return MemoryImage(bytes);
      } catch (_) {}
    } else if (!pathStr.startsWith('http://') && !pathStr.startsWith('https://') && pathStr.length > 100) {
      try {
        final bytes = base64Decode(pathStr);
        return MemoryImage(bytes);
      } catch (_) {}
    }

    // 4. Try Network URL
    if (pathStr.startsWith('http://') || pathStr.startsWith('https://')) {
      return NetworkImage(pathStr);
    }

    return null;
  }

  Widget _buildTopBar() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Text(
        'My Profile',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1C1F3E),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(providerProfileProvider);
    final dispatchState = ref.watch(jobDispatchProvider);

    final user = authState.user;
    final profileData = profileState.profileData;

    final name = (user?.name != null && user!.name!.isNotEmpty)
        ? user.name!
        : (profileData?['name'] != null && profileData!['name'].toString().isNotEmpty)
            ? profileData!['name'].toString()
            : 'Partner';

    final email = (user?.email != null && user!.email!.isNotEmpty)
        ? user.email!
        : (profileData?['email'] != null)
            ? profileData!['email'].toString()
            : '';

    final phone = (user?.phone != null && user!.phone!.isNotEmpty)
        ? user.phone!
        : (profileData?['phone'] != null)
            ? profileData!['phone'].toString()
            : '';

    final rawImage = user?.profileImage ??
        profileData?['user_id']?['profile_image']?.toString() ??
        profileData?['profile_image']?.toString() ??
        profileData?['verification_docs']?['id_proof_url']?.toString();

    final imageProvider = _resolveProfileImageProvider(rawImage);
    final isOnline = dispatchState.isOnline;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Profile Picture with Available Badge
            Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFFEFF1FE),
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? const Icon(
                          Icons.person,
                          size: 46,
                          color: Color(0xFF16155D),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFFFEFEF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFF2E7D32) : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'Available' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOnline ? const Color(0xFF2E7D32) : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Right info block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1F3E),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.edit,
                          color: Color(0xFF16155D),
                          size: 18,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black38,
                      height: 1.3,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black38,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? const Color(0xFFFEEFF1) : const Color(0xFFEFF1FE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF16155D),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDestructive ? Colors.red : const Color(0xFF2D3047),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.red : Colors.black26,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityGroup(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _buildListTile(
                icon: Icons.badge_outlined,
                title: 'Identity Verification',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileIdentityVerificationScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEFF1FE)),
              _buildListTile(
                icon: Icons.calendar_today_outlined,
                title: 'Calendar',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEFF1FE)),
              _buildListTile(
                icon: Icons.work_outline,
                title: 'Job History',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JobHistoryScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEFF1FE)),
              _buildListTile(
                icon: Icons.payment_outlined,
                title: 'Loans',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoansScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEFF1FE)),
              _buildListTile(
                icon: Icons.stars_outlined,
                title: 'Credits',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreditsScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEFF1FE)),
              _buildListTile(
                icon: Icons.poll_outlined,
                title: 'Performance',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PerformanceScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEFF1FE)),
              _buildListTile(
                icon: Icons.shield_outlined,
                title: 'Insurance',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InsuranceScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEFF1FE)),
              _buildListTile(
                icon: Icons.shopping_bag_outlined,
                title: 'Shop',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shop coming soon!')),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEFF1FE)),
              _buildListTile(
                icon: Icons.people_outline,
                title: 'Invite a friend',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite program coming soon!')),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEFF1FE)),
              _buildListTile(
                icon: Icons.headset_mic_outlined,
                title: 'Help & Support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support center coming soon!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountGroup(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _buildListTile(
                icon: Icons.translate_outlined,
                title: 'Change Language',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language settings coming soon!')),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFEFF1FE)),
              _buildListTile(
                icon: Icons.logout_outlined,
                title: 'Logout',
                isDestructive: true,
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OnboardingScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(),
                _buildSectionHeader('MY ACTIVITY'),
                _buildActivityGroup(context),
                _buildSectionHeader('ACCOUNT'),
                _buildAccountGroup(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
