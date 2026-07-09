import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/catalog_provider.dart';
import 'package:partner_app/screens/auth/select_sub_categories_screen.dart';

class ServicesYouOfferScreen extends ConsumerStatefulWidget {
  const ServicesYouOfferScreen({super.key});

  @override
  ConsumerState<ServicesYouOfferScreen> createState() => _ServicesYouOfferScreenState();
}

class _ServicesYouOfferScreenState extends ConsumerState<ServicesYouOfferScreen> {
  final List<dynamic> _selectedCategories = [];
  String _searchQuery = '';
  bool _isSearching = false;

  void _toggleCategory(dynamic category) {
    setState(() {
      final exists = _selectedCategories.any((c) => c['_id'] == category['_id']);
      if (exists) {
        _selectedCategories.removeWhere((c) => c['_id'] == category['_id']);
      } else {
        if (_selectedCategories.length >= 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Choose up to 2 categories'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF16155D),
            ),
          );
        } else {
          _selectedCategories.add(category);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

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

            // Header (Title, Subtitle, and Search)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _isSearching
                          ? Expanded(
                              child: TextField(
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Search services...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.black38),
                                ),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF16155D)),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                              ),
                            )
                          : const Text(
                              'Services You Offer',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16155D),
                                letterSpacing: -0.5,
                              ),
                            ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(_isSearching ? Icons.close : Icons.search, color: const Color(0xFF16155D), size: 26),
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchQuery = '';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose up to 2 categories',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Services Grid
            Expanded(
              child: categoriesAsync.when(
                data: (categoriesList) {
                  final filteredCategories = categoriesList.where((category) {
                    final name = category['category_name'] as String;
                    final desc = category['description'] as String;
                    return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        desc.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  return GridView.builder(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      final isSelected = _selectedCategories.any((c) => c['_id'] == category['_id']);
                      
                      return GestureDetector(
                        onTap: () => _toggleCategory(category),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF16155D) : const Color(0xFFEFF1FE),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mock icon representation
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFEFF1FE) : const Color(0xFFF5F6FA),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.handyman_outlined,
                                  color: Color(0xFF16155D),
                                  size: 22,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                category['category_name'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16155D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                category['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black45,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF16155D),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Text('Failed to load categories: $err'),
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
                  // Select Button
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _selectedCategories.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SelectSubCategoriesScreen(
                                      selectedCategories: _selectedCategories,
                                    ),
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Select',
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
