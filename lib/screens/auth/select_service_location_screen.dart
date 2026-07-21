import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/api_providers.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/screens/auth/identity_verification_screen.dart';

class SelectServiceLocationScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  const SelectServiceLocationScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<SelectServiceLocationScreen> createState() => _SelectServiceLocationScreenState();
}

class _SelectServiceLocationScreenState extends ConsumerState<SelectServiceLocationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _allLocations = [];
  final Set<String> _selectedLocationIds = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/api/locations');
      if (response.statusCode == 200 && response.data is List) {
        final rawList = List<Map<String, dynamic>>.from(response.data);
        
        // Pre-select already assigned service_locations if present in profile
        final profile = ref.read(providerProfileProvider).profileData;
        final existingLocations = profile?['service_locations'] as List?;
        if (existingLocations != null) {
          for (var item in existingLocations) {
            if (item is String) {
              _selectedLocationIds.add(item);
            } else if (item is Map && item['_id'] != null) {
              _selectedLocationIds.add(item['_id'].toString());
            }
          }
        }

        setState(() {
          _allLocations = rawList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load service locations.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error connecting to server. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredLocations {
    if (_searchQuery.trim().isEmpty) {
      return _allLocations;
    }
    final q = _searchQuery.toLowerCase().trim();
    return _allLocations.where((loc) {
      final name = (loc['name'] ?? '').toString().toLowerCase();
      final pincode = (loc['pincode'] ?? '').toString().toLowerCase();
      final type = (loc['type'] ?? '').toString().toLowerCase();
      final parentName = (loc['parent_id'] != null && loc['parent_id'] is Map && loc['parent_id']['name'] != null)
          ? loc['parent_id']['name'].toString().toLowerCase()
          : '';
      return name.contains(q) || pincode.contains(q) || type.contains(q) || parentName.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLocations;
    final profileState = ref.watch(providerProfileProvider);
    final isSaving = profileState.status == ProfileStatus.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Progress Bar (Step 2 of 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: List.generate(
                  5,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index == 4 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: index <= 1 ? const Color(0xFF16155D) : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Work Locations',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16155D),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose the cities and areas where you are available to accept service bookings.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Input Box
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF16155D),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search city, area or pincode...',
                          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF16155D)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Colors.black45),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF16155D)),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchLocations,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16155D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching locations found',
                                style: TextStyle(color: Colors.black45, fontSize: 15),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final loc = filtered[index];
                                final id = loc['_id']?.toString() ?? '';
                                final name = loc['name']?.toString() ?? 'Unknown';
                                final type = loc['type']?.toString().toUpperCase() ?? 'CITY';
                                final pincode = loc['pincode']?.toString();
                                final isSelected = _selectedLocationIds.contains(id);

                                String subtitle = type;
                                if (pincode != null && pincode.isNotEmpty) {
                                  subtitle += ' • Pincode $pincode';
                                }
                                if (loc['parent_id'] != null && loc['parent_id'] is Map && loc['parent_id']['name'] != null) {
                                  subtitle += ' (${loc['parent_id']['name']})';
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFEFF1FE) : const Color(0xFFF8F9FD),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF16155D) : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    activeColor: const Color(0xFF16155D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    title: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: const Color(0xFF16155D),
                                      ),
                                    ),
                                    subtitle: Text(
                                      subtitle,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    onChanged: (bool? checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedLocationIds.add(id);
                                        } else {
                                          _selectedLocationIds.remove(id);
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
            ),

            // Bottom Selection Action Bar
            Container(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 20.0, top: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
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
                        onPressed: isSaving || _selectedLocationIds.isEmpty
                            ? null
                            : () async {
                                final success = await ref
                                    .read(providerProfileProvider.notifier)
                                    .updateProfile(
                                      serviceLocations: _selectedLocationIds.toList(),
                                    );

                                if (success && mounted) {
                                  if (widget.isEditing) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Service locations updated successfully!')),
                                    );
                                    Navigator.pop(context);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const IdentityVerificationScreen(),
                                      ),
                                    );
                                  }
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        profileState.errorMessage ?? 'Failed to update work locations',
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
                        child: isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _selectedLocationIds.isEmpty
                                        ? 'Select Location'
                                        : 'Continue (${_selectedLocationIds.length})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, color: Colors.white, size: 18),
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
