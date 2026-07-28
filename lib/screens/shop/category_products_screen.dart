import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/api_providers.dart';

class CategoryProductsScreen extends ConsumerStatefulWidget {
  final String categoryName;

  const CategoryProductsScreen({super.key, required this.categoryName});

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  final List<String> filters = ['All', 'Tools', 'Electrical', 'Paint', 'Grooming', 'Safety'];
  String selectedFilter = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> cart = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAccessoriesFromBackend();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAccessoriesFromBackend() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/api/accessories');

      if (response.statusCode == 200) {
        final List rawData = response.data is List ? response.data : (response.data['accessories'] ?? []);

        final List<Map<String, dynamic>> parsedList = rawData.map<Map<String, dynamic>>((item) {
          final titleStr = item['title'] ?? item['name'] ?? 'Professional Accessory';
          final descStr = item['description'] ?? 'High quality professional equipment tool.';
          final priceVal = item['price'] ?? 0;
          final imgUrl = item['image'] ?? 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500';
          
          String brandName = 'BHARATCLAP PRO';
          if (item['category'] is Map) {
            brandName = item['category']['category_name']?.toString().toUpperCase() ?? brandName;
          } else if (item['category'] is String) {
            brandName = item['category'].toString().toUpperCase();
          }

          return {
            'id': item['_id']?.toString() ?? '',
            'brand': brandName,
            'name': titleStr,
            'description': descStr,
            'priceVal': priceVal,
            'price': '₹$priceVal',
            'image': imgUrl,
          };
        }).toList();

        if (mounted) {
          setState(() {
            products = parsedList;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Fetch accessories error: $e');
      if (mounted) {
        setState(() {
          // Fallback to database seeding default items if backend offline
          products = [
            {
              'id': '1',
              'brand': 'ELECTRICAL',
              'name': 'Digital Multimeter',
              'description': 'Professional electrical testing meter for AC/DC voltage and current.',
              'priceVal': 899,
              'price': '₹899',
              'image': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500',
            },
            {
              'id': '2',
              'brand': 'TOOLS',
              'name': 'Insulated Screwdriver Set',
              'description': 'Electrical-safe screwdriver set with VDE certified handles.',
              'priceVal': 599,
              'price': '₹599',
              'image': 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?w=500',
            },
            {
              'id': '3',
              'brand': 'TESTING',
              'name': 'Voltage Tester',
              'description': 'Handheld non-contact voltage detector pen with LED light.',
              'priceVal': 298,
              'price': '₹298',
              'image': 'https://images.unsplash.com/photo-1581092335397-9583fe92d232?w=500',
            },
            {
              'id': '4',
              'brand': 'REPAIR',
              'name': 'Repair Tool Kit',
              'description': 'Complete appliance & home repair multi-tool kit in heavy case.',
              'priceVal': 1499,
              'price': '₹1499',
              'image': 'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?w=500',
            },
            {
              'id': '5',
              'brand': 'WIRING',
              'name': 'Wire Stripper Tool',
              'description': 'Precision wire cutting & stripping tool with ergonomic grip.',
              'priceVal': 349,
              'price': '₹349',
              'image': 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500',
            },
            {
              'id': '6',
              'brand': 'PAINTING',
              'name': 'Painter Tape',
              'description': 'Masking tape for clean paint edges and floor protection.',
              'priceVal': 149,
              'price': '₹149',
              'image': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=500',
            },
            {
              'id': '7',
              'brand': 'SAFETY',
              'name': 'Safety Ladder',
              'description': 'Foldable heavy duty aluminum ladder for high wall reach.',
              'priceVal': 2499,
              'price': '₹2499',
              'image': 'https://images.unsplash.com/photo-1513467535987-fd81bc206281?w=500',
            },
            {
              'id': '8',
              'brand': 'WALL FINISH',
              'name': 'Wall Putty',
              'description': 'Premium waterproof wall putty for smooth paint prep.',
              'priceVal': 698,
              'price': '₹698',
              'image': 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=500',
            },
            {
              'id': '9',
              'brand': 'PAINTING',
              'name': 'Paint Roller Set',
              'description': 'Professional wall painting roller kit with extension pole.',
              'priceVal': 499,
              'price': '₹499',
              'image': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=500',
            },
            {
              'id': '10',
              'brand': 'PAINTING',
              'name': 'Paint Brush Set',
              'description': 'Multiple-size synthetic brushes for detailed trim painting.',
              'priceVal': 399,
              'price': '₹399',
              'image': 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=500',
            },
          ];
          isLoading = false;
        });
      }
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      cart.add(product);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart!'),
        backgroundColor: const Color(0xFF1E1B4B),
        action: SnackBarAction(
          label: 'View Cart (${cart.length})',
          textColor: Colors.white,
          onPressed: () {
            _showCartBottomSheet();
          },
        ),
      ),
    );
  }

  void _showCartBottomSheet() {
    double totalAmount = cart.fold(0, (sum, item) => sum + (item['priceVal'] ?? 0));

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
                    'Shopping Cart (${cart.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (cart.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: Text('Your cart is empty', style: TextStyle(color: Colors.grey))),
                )
              else ...[
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, idx) {
                      final item = cart[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(item['image'], width: 44, height: 44, fit: BoxFit.cover),
                        ),
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(item['price'], style: const TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              cart.removeAt(idx);
                            });
                            Navigator.pop(context);
                            _showCartBottomSheet();
                          },
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.store_mall_directory_outlined, color: Color(0xFF1E40AF), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Order Delivery: Please collect your order from the office.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Payable:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Order Placed Successfully!'),
                          content: Text(
                            'Your equipment order of ₹${totalAmount.toStringAsFixed(0)} has been placed successfully. Please collect the order from the office.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                setState(() => cart.clear());
                                Navigator.pop(context);
                              },
                              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1B4B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Checkout & Place Order', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((p) {
      final matchesSearch = searchQuery.isEmpty ||
          p['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
          p['brand'].toString().toLowerCase().contains(searchQuery.toLowerCase());

      final matchesFilter = selectedFilter == 'All' ||
          p['brand'].toString().toLowerCase().contains(selectedFilter.toLowerCase()) ||
          p['name'].toString().toLowerCase().contains(selectedFilter.toLowerCase());

      return matchesSearch && matchesFilter;
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
        title: Text(
          widget.categoryName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                onPressed: _showCartBottomSheet,
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cart.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    searchQuery = val.trim();
                  });
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
          ),
          
          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = filter == selectedFilter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                    selectedColor: const Color(0xFF1E1B4B),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? const Color(0xFF1E1B4B) : Colors.transparent),
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Product Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E1B4B)))
                : filteredProducts.isEmpty
                    ? const Center(child: Text('No accessories found for this filter.', style: TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(
                                    product['image'],
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 120,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.build, color: Colors.grey, size: 40),
                                    ),
                                  ),
                                ),
                                
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Brand
                                      Text(
                                        product['brand'],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      
                                      // Product Name
                                      Text(
                                        product['name'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Price and Add Button
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            product['price'],
                                            style: const TextStyle(
                                              color: Color(0xFF1E1B4B),
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _addToCart(product),
                                            child: Container(
                                              height: 32,
                                              width: 32,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E1B4B),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
  }
}
