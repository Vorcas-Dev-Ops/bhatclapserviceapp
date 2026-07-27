import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';
import 'package:partner_app/providers/api_providers.dart';
import 'starter_kit_screen.dart';
import 'category_products_screen.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _currentAddress = 'Fetching location...';
  final List<String> _savedAddresses = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoadingOrders = false;
  List<Map<String, dynamic>> _dynamicCategories = [];

  List<Map<String, dynamic>> _myOrders = [
    {
      'id': 'BC9283-X',
      'title': 'Order #BC9283-X',
      'items': '4 Items • Mandatory Starter Kit & Accessories',
      'status': 'Delivered',
      'date': '12 Oct 2026',
      'amount': '₹895',
      'icon': Icons.receipt_long,
      'iconColor': Colors.blue,
      'address': 'Flat 402, Green Valley Apartments, Mumbai',
      'step': 4,
    },
    {
      'id': 'BC9124-B',
      'title': 'Order #BC9124-B',
      'items': '1 Item • Professional Grooming Tool Set',
      'status': 'Out for Delivery',
      'date': '24 Jul 2026',
      'amount': '₹1,249',
      'icon': Icons.local_shipping,
      'iconColor': Colors.green,
      'address': 'Block B, Sector 15, Navi Mumbai',
      'step': 3,
    },
  ];

  @override
  void initState() {
    super.initState();
    _getAddress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrdersFromBackend();
      _fetchCategoriesFromBackend();
    });
  }

  Future<void> _fetchCategoriesFromBackend() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/api/categories');
      if (response.statusCode == 200 && response.data is List) {
        final List rawCategories = response.data;
        if (rawCategories.isNotEmpty) {
          final List<Map<String, dynamic>> parsed = rawCategories.map<Map<String, dynamic>>((item) {
            final name = item['category_name'] ?? item['name'] ?? 'Category';
            return {
              'name': name.toString(),
              'displayName': name.toString().replaceAll(' for ', '\n(') + (name.toString().contains(' for ') ? ')' : ''),
              'icon': _getIconForCategory(name.toString()),
              'id': item['_id']?.toString() ?? '',
            };
          }).toList();

          parsed.add({'name': 'Show\nmore', 'displayName': 'Show\nmore', 'icon': Icons.more_horiz});

          if (mounted) {
            setState(() {
              _dynamicCategories = parsed;
            });
          }
        }
      }
    } catch (e) {
      print('Fetch categories error: $e');
    }
  }

  IconData _getIconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('salon')) return Icons.face_retouching_natural;
    if (lower.contains('spa')) return Icons.spa;
    if (lower.contains('hair')) return Icons.cut;
    if (lower.contains('bridal') || lower.contains('makeup')) return Icons.brush;
    if (lower.contains('grooming') || lower.contains('men')) return Icons.content_cut;
    if (lower.contains('massage')) return Icons.sports_kabaddi;
    if (lower.contains('clean') || lower.contains('pest')) return Icons.cleaning_services;
    if (lower.contains('repair') || lower.contains('handyman')) return Icons.handyman;
    if (lower.contains('appliance')) return Icons.kitchen;
    if (lower.contains('paint') || lower.contains('wallpaper')) return Icons.format_paint;
    if (lower.contains('bag') || lower.contains('shirt')) return Icons.shopping_bag;
    return Icons.category_outlined;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrdersFromBackend() async {
    setState(() => _isLoadingOrders = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/api/kit-orders');
      if (response.statusCode == 200) {
        final data = response.data;
        List rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map && data['data'] is List) {
          rawList = data['data'];
        }

        if (rawList.isNotEmpty) {
          final List<Map<String, dynamic>> fetchedOrders = rawList.map((item) {
            final statusStr = item['status']?.toString() ?? 'Delivered';
            int stepNum = 4;
            if (statusStr.toLowerCase().contains('pending')) stepNum = 1;
            if (statusStr.toLowerCase().contains('process')) stepNum = 2;
            if (statusStr.toLowerCase().contains('transit') || statusStr.toLowerCase().contains('out')) stepNum = 3;

            return {
              'id': item['orderId'] ?? item['_id'] ?? 'BC-${item.hashCode}',
              'title': 'Order #${item['orderId'] ?? 'BC-KIT'}',
              'items': '${item['service'] ?? 'Kit Order'} • Size: ${item['size'] ?? 'Standard'}',
              'status': statusStr,
              'date': item['createdAt'] != null ? item['createdAt'].toString().split('T')[0] : 'Recent',
              'amount': '₹${item['amount'] ?? 895}',
              'icon': statusStr.toLowerCase().contains('out') ? Icons.local_shipping : Icons.receipt_long,
              'iconColor': statusStr.toLowerCase().contains('out') ? Colors.green : Colors.blue,
              'address': item['address'] ?? 'Registered Address',
              'step': stepNum,
            };
          }).toList();

          if (mounted) {
            setState(() {
              _myOrders = fetchedOrders;
            });
          }
        }
      }
    } catch (e) {
      print('Fetch orders error (using local cache): $e');
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _getAddress() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _currentAddress = 'Location services disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _currentAddress = 'Location permissions denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _currentAddress = 'Location permissions permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _currentAddress = '${place.subLocality ?? place.locality}, ${place.administrativeArea}';
          });
        }
      }
    } catch (e) {
      print('Location error: $e');
      if (mounted) setState(() => _currentAddress = 'Mountain View, California');
    }
  }

  final List<Map<String, dynamic>> allCategories = const [
    {'name': 'BC T-Shirts\n& Bags', 'icon': Icons.shopping_bag},
    {'name': 'Salon\n(Women)', 'icon': Icons.face_retouching_natural},
    {'name': 'Spa\n(Women)', 'icon': Icons.spa},
    {'name': 'Hair Styling\n(Women)', 'icon': Icons.cut},
    {'name': 'Bridal\nMakeup', 'icon': Icons.brush},
    {'name': 'Men\'s\nGrooming', 'icon': Icons.content_cut},
    {'name': 'Massage\n(Men)', 'icon': Icons.sports_kabaddi},
    {'name': 'Cleaning &\nPest Control', 'icon': Icons.cleaning_services},
    {'name': 'Home\nRepairs', 'icon': Icons.handyman},
    {'name': 'Appliance\nRepairs', 'icon': Icons.kitchen},
    {'name': 'Wallpaper\nrenovation', 'icon': Icons.format_paint},
    {'name': 'Show\nmore', 'icon': Icons.more_horiz},
  ];

  final List<Map<String, dynamic>> expandedCategories = const [
    {'name': 'Painting &\nWaterproofing', 'icon': Icons.format_color_fill},
    {'name': 'Electrician &\nWiring', 'icon': Icons.electrical_services},
    {'name': 'Plumbing\nServices', 'icon': Icons.plumbing},
    {'name': 'AC Repair &\nService', 'icon': Icons.ac_unit},
    {'name': 'Car Cleaning\n& Care', 'icon': Icons.directions_car},
    {'name': 'Disinfection &\nSanitization', 'icon': Icons.sanitizer},
  ];

  void _showAllCategoriesBottomSheet() {
    final combined = [...allCategories.where((c) => c['name'] != 'Show\nmore'), ...expandedCategories];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(top: 80),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Product & Equipment Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: combined.length,
                  itemBuilder: (context, index) {
                    final item = combined[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryProductsScreen(
                              categoryName: item['name']!.replaceAll('\n', ' '),
                            ),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item['icon'], color: const Color(0xFF1E1B4B), size: 26),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['name']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLoanEligibilityDialog() {
    double selectedAmount = 50000;
    int selectedTenure = 12;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double monthlyInterestRate = 0.012;
            final double totalRepayment = selectedAmount * (1 + (monthlyInterestRate * selectedTenure));
            final double monthlyEmi = totalRepayment / selectedTenure;

            return Container(
              margin: const EdgeInsets.only(top: kToolbarHeight),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Easy Business Financing',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pre-approved instant equipment loans for top-performing partners.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B4B).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E1B4B).withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Desired Loan Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                '₹${selectedAmount.toInt()}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                              ),
                            ],
                          ),
                          Slider(
                            value: selectedAmount,
                            min: 10000,
                            max: 1500000,
                            divisions: 149,
                            activeColor: const Color(0xFF1E1B4B),
                            onChanged: (val) {
                              setModalState(() {
                                selectedAmount = (val / 5000).round() * 5000;
                              });
                            },
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('₹10,000', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text('₹15,00,000', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    const Text('Tenure (Months)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [6, 12, 24, 36].map((tenure) {
                        final isSelected = selectedTenure == tenure;
                        return ChoiceChip(
                          label: Text('$tenure Months'),
                          selected: isSelected,
                          onSelected: (sel) {
                            if (sel) setModalState(() => selectedTenure = tenure);
                          },
                          selectedColor: const Color(0xFF1E1B4B),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: Colors.grey.shade100,
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Estimated Monthly EMI', style: TextStyle(fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 2),
                              Text(
                                '₹${monthlyEmi.toStringAsFixed(0)} / mo',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '@ 1.2% / mo',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Application Submitted!'),
                              content: Text(
                                'Your financing request for ₹${selectedAmount.toInt()} (Reference: LOAN-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}) has been submitted to partner NBFCs. Our loan specialist will call you within 2 hours.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1B4B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Submit Loan Application',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderDetailsBottomSheet(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(top: kToolbarHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order['title'] ?? 'Order Details',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Placed on: ${order['date']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order['status'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              const Text('Delivery Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusStep('Placed', true),
                  _buildStatusStep('Packed', order['step'] >= 2),
                  _buildStatusStep('Dispatched', order['step'] >= 3),
                  _buildStatusStep('Delivered', order['step'] >= 4),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              
              const Text('Items in Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1E1B4B)),
                ),
                title: Text(order['items'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Verified Official Kit', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: Text(order['amount'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(order['address'], style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusStep(String label, bool isDone) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.green : Colors.grey.shade300,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
              color: isDone ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(providerProfileProvider);
    final kitPurchased = profileState.profileData?['kitPurchased'] == true || profileState.profileData?['providerKitCompleted'] == true;
    final providerName = profileState.profileData?['user_id']?['name'] ?? 'Provider';

    final categoriesToUse = _dynamicCategories.isNotEmpty ? _dynamicCategories : allCategories;
    final filteredCategories = categoriesToUse.where((cat) {
      if (_searchQuery.isEmpty) return true;
      final nameClean = (cat['displayName'] ?? cat['name'])!.toString().replaceAll('\n', ' ').toLowerCase();
      return nameClean.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shop',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!kitPurchased)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StarterKitScreen(providerName: providerName),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B41C5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Complete Your Onboarding',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Purchase your mandatory Provider Kit',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),

              // Location Selector
              InkWell(
                onTap: _showAddressBottomSheet,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentAddress,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryProductsScreen(categoryName: val.trim()),
                        ),
                      );
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search products, tools, brands...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Categories Header
              const Text(
                'Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Categories Grid
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final cat = filteredCategories[index];
                  return GestureDetector(
                    onTap: () {
                      if (cat['name'] == 'Show\nmore') {
                        _showAllCategoriesBottomSheet();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryProductsScreen(
                              categoryName: cat['name']!.replaceAll('\n', ' '),
                            ),
                          ),
                        );
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            cat['icon'],
                            color: Colors.black87,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['name']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Loan Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B4B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Easy Business Loans',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Instant equipment financing\nfor top-tier professionals.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _showLoanEligibilityDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E1B4B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            child: const Text('Check Eligibility', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // My Orders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Orders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_isLoadingOrders)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E1B4B)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              ..._myOrders.map((order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () => _showOrderDetailsBottomSheet(order),
                    child: _buildOrderItem(
                      order['title'],
                      '${order['items']}',
                      order['icon'],
                      order['iconColor'],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(String title, String subtitle, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  void _showAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Delivery Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.my_location, color: Colors.blue),
                title: const Text('Current Location'),
                subtitle: Text(_currentAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              if (_savedAddresses.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(),
                ),
              ..._savedAddresses.map((address) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
                    title: Text(address, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      setState(() {
                        _currentAddress = address;
                      });
                      Navigator.pop(context);
                    },
                  )),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add, color: Color(0xFF1E1B4B)),
                title: const Text('Add New Address', style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddAddressDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddAddressDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddAddressBottomSheet(),
    ).then((newAddress) {
      if (newAddress != null && newAddress is String && newAddress.isNotEmpty) {
        setState(() {
          _savedAddresses.add(newAddress);
          _currentAddress = newAddress;
        });
      }
    });
  }
}

class AddAddressBottomSheet extends StatefulWidget {
  const AddAddressBottomSheet({super.key});

  @override
  State<AddAddressBottomSheet> createState() => _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends State<AddAddressBottomSheet> {
  final _houseNoController = TextEditingController();
  final _areaController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  String _selectedType = 'Home';

  @override
  void dispose() {
    _houseNoController.dispose();
    _areaController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (_houseNoController.text.trim().isEmpty || _areaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    
    final fullAddress = '${_houseNoController.text.trim()}, ${_areaController.text.trim()}';
    final cityPincode = '${_cityController.text.trim()} ${_pincodeController.text.trim()}'.trim();
    final finalAddress = cityPincode.isNotEmpty ? '$fullAddress, $cityPincode' : fullAddress;
    
    Navigator.pop(context, '$_selectedType - $finalAddress');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      margin: const EdgeInsets.only(top: kToolbarHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Address',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              const Text('Save address as', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 12),
              Row(
                children: ['Home', 'Work', 'Other'].map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = type);
                      },
                      selectedColor: const Color(0xFF1E1B4B),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: isSelected ? const Color(0xFF1E1B4B) : Colors.transparent)
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              _buildTextField('House / Flat / Block No.', _houseNoController, Icons.home_outlined),
              const SizedBox(height: 16),
              _buildTextField('Apartment / Road / Area', _areaController, Icons.map_outlined),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Pincode', _pincodeController, Icons.pin_drop_outlined, isNumber: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('City', _cityController, Icons.location_city_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1B4B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E1B4B), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
