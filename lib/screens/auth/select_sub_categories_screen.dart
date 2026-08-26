import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/catalog_provider.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/providers/auth_provider.dart';
import 'package:partner_app/screens/auth/select_service_location_screen.dart';

class SelectSubCategoriesScreen extends ConsumerStatefulWidget {
  final List<dynamic> selectedCategories;

  const SelectSubCategoriesScreen({
    super.key,
    required this.selectedCategories,
  });

  @override
  ConsumerState<SelectSubCategoriesScreen> createState() => _SelectSubCategoriesScreenState();
}

class _SelectSubCategoriesScreenState extends ConsumerState<SelectSubCategoriesScreen> {
  final List<String> _selectedSubserviceIds = [];

  @override
  void initState() {
    super.initState();
    // Pre-fetch the provider profile to ensure we have the provider ID ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(providerProfileProvider.notifier).fetchProfile();
    });
  }

  void _onSelectionChanged(String subserviceId, bool isSelected) {
    setState(() {
      if (isSelected) {
        if (!_selectedSubserviceIds.contains(subserviceId)) {
          _selectedSubserviceIds.add(subserviceId);
        }
      } else {
        _selectedSubserviceIds.remove(subserviceId);
      }
    });
  }

  void _onBulkSelectionChanged(List<String> subserviceIds, bool selectAll) {
    setState(() {
      if (selectAll) {
        for (var id in subserviceIds) {
          if (!_selectedSubserviceIds.contains(id)) {
            _selectedSubserviceIds.add(id);
          }
        }
      } else {
        for (var id in subserviceIds) {
          _selectedSubserviceIds.remove(id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(providerProfileProvider);
    final isLoading = profileState.status == ProfileStatus.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Progress Bar (Step 2 of 4)
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
                        color: index <= 1 ? const Color(0xFF16155D) : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header (Title & Subtitle)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Services You Offer',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16155D),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Select Sub-Categories',
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

            // Sub Categories Scroll List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.selectedCategories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 28.0),
                      child: CategorySubservicesSection(
                        categoryId: category['_id'],
                        categoryName: category['category_name'],
                        selectedSubserviceIds: _selectedSubserviceIds,
                        onSelectionChanged: _onSelectionChanged,
                        onBulkSelectionChanged: _onBulkSelectionChanged,
                      ),
                    );
                  }).toList(),
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
                      child: ElevatedButton(
                        onPressed: isLoading || _selectedSubserviceIds.isEmpty
                            ? null
                            : () async {
                                final success = await ref
                                    .read(providerProfileProvider.notifier)
                                    .addService(
                                      subserviceIds: _selectedSubserviceIds,
                                      price: 499.0, // Default base package price
                                      experience: 2.0, // Default experience placeholder
                                    );

                                if (success && mounted) {
                                  await ref.read(providerProfileProvider.notifier).updateProfile(onboardingStep: 1);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SelectServiceLocationScreen(),
                                    ),
                                  );
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        profileState.errorMessage ?? 'Failed to submit services',
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

class CategorySubservicesSection extends ConsumerWidget {
  final String categoryId;
  final String categoryName;
  final List<String> selectedSubserviceIds;
  final Function(String, bool) onSelectionChanged;
  final Function(List<String>, bool) onBulkSelectionChanged;

  const CategorySubservicesSection({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.selectedSubserviceIds,
    required this.onSelectionChanged,
    required this.onBulkSelectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subservicesAsync = ref.watch(subservicesProvider(categoryId));
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(providerProfileProvider);

    final genderStr = (authState.user?.gender ??
                       profileState.profileData?['gender'] ??
                       profileState.profileData?['user_id']?['gender'] ??
                       '').toString().trim().toLowerCase();

    final isFemaleProvider = genderStr == 'female' || genderStr == 'f';
    final isMaleProvider = genderStr == 'male' || genderStr == 'm';
    final isBeautyCategory = categoryName.toLowerCase().contains('beauty') ||
                             categoryName.toLowerCase().contains('wellness');

    List<dynamic> filterSubservices(List<dynamic> list) {
      if (!isBeautyCategory) return list;

      if (isFemaleProvider) {
        return list.where((subservice) {
          final targetGender = (subservice['target_gender'] ?? subservice['gender'] ?? '').toString().toLowerCase();
          if (targetGender == 'female' || targetGender == 'women') return true;
          if (targetGender == 'male' || targetGender == 'men') return false;

          final name = (subservice['subservice_name'] ?? subservice['name'] ?? '').toString().toLowerCase();
          final desc = (subservice['description'] ?? '').toString().toLowerCase();
          final combined = '$name $desc';

          final hasMaleKeyword = (combined.contains('men') && !combined.contains('women')) ||
                                 combined.contains('male') ||
                                 combined.contains('beard') ||
                                 combined.contains('barber');

          return !hasMaleKeyword;
        }).toList();
      }

      if (isMaleProvider) {
        return list.where((subservice) {
          final targetGender = (subservice['target_gender'] ?? subservice['gender'] ?? '').toString().toLowerCase();
          if (targetGender == 'male' || targetGender == 'men') return true;
          if (targetGender == 'female' || targetGender == 'women') return false;

          final name = (subservice['subservice_name'] ?? subservice['name'] ?? '').toString().toLowerCase();
          final desc = (subservice['description'] ?? '').toString().toLowerCase();
          final combined = '$name $desc';

          final hasFemaleKeyword = combined.contains('women') ||
                                   combined.contains('female') ||
                                   combined.contains('waxing') ||
                                   combined.contains('threading') ||
                                   combined.contains('makeup') ||
                                   combined.contains('bridal');

          return !hasFemaleKeyword;
        }).toList();
      }

      return list;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              categoryName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16155D),
              ),
            ),
            subservicesAsync.when(
              data: (subservices) {
                final displayList = filterSubservices(subservices);
                if (displayList.isEmpty) return const SizedBox.shrink();
                final ids = displayList.map((s) => s['_id'].toString()).toList();
                final allSelected = ids.every((id) => selectedSubserviceIds.contains(id));
                return GestureDetector(
                  onTap: () {
                    onBulkSelectionChanged(ids, !allSelected);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Select All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: allSelected ? const Color(0xFF16155D) : const Color(0xFFC5C9E0),
                            width: 1.5,
                          ),
                          color: allSelected ? const Color(0xFF16155D) : Colors.transparent,
                        ),
                        child: allSelected
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        subservicesAsync.when(
          data: (subservices) {
            final displayList = filterSubservices(subservices);
            if (displayList.isEmpty) {
              return const Text('No female subservices available in this category.');
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.9,
              ),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final subservice = displayList[index];
                final subserviceId = subservice['_id'];
                final name = subservice['subservice_name'];
                final isSelected = selectedSubserviceIds.contains(subserviceId);

                return GestureDetector(
                  onTap: () {
                    onSelectionChanged(subserviceId, !isSelected);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF16155D) : const Color(0xFFEFF1FE),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF16155D),
                            ),
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF16155D) : const Color(0xFFC5C9E0),
                              width: 1.5,
                            ),
                            color: isSelected ? const Color(0xFF16155D) : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF16155D)),
            ),
          ),
          error: (err, stack) => Text('Error loading sub-services: $err'),
        ),
      ],
    );
  }
}
