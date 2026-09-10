import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../models/category/category_model.dart';
import '../../models/entities/product.dart';
import '../../models/user_model.dart';
import '../../routes/flux_navigate.dart';
import '../../services/index.dart';
import '../../widgets/common/zipbiz_header.dart';

class ZipBizServicesDirectoryScreen extends StatefulWidget {
  final String? initialCategory;

  const ZipBizServicesDirectoryScreen({super.key, this.initialCategory});

  @override
  State<ZipBizServicesDirectoryScreen> createState() =>
      _ZipBizServicesDirectoryScreenState();
}

class _ZipBizServicesDirectoryScreenState
    extends State<ZipBizServicesDirectoryScreen> {
  // Region Selection (matches Home Screen)
  String _selectedRegion = 'Chandigarh, Mohali, Kharar, Zirakpur';
  final List<String> _regions = const [
    'Chandigarh, Mohali, Kharar, Zirakpur',
    'Chandigarh (All Sectors)',
    'Mohali (Phase 1-11 & Aerocity)',
    'Kharar & Sunny Enclave',
    'Zirakpur & VIP Road',
    'Panchkula',
  ];

  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  List<Product> _allServices = [];

  // The 8 Listeo Service Categories
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Electrician',
      'icon': Icons.bolt,
      'bg': const Color(0xFFFEF3C7),
      'iconColor': const Color(0xFFD97706),
    },
    {
      'name': 'Plumber',
      'icon': Icons.plumbing,
      'bg': const Color(0xFFE0F2FE),
      'iconColor': const Color(0xFF0284C7),
    },
    {
      'name': 'Cleaner',
      'icon': Icons.cleaning_services,
      'bg': const Color(0xFFFFEDD5),
      'iconColor': const Color(0xFFFF6B00),
    },
    {
      'name': 'Home Salon',
      'icon': Icons.face_retouching_natural,
      'bg': const Color(0xFFF3E8FF),
      'iconColor': const Color(0xFF7E22CE),
    },
    {
      'name': 'Appliance',
      'icon': Icons.build,
      'bg': const Color(0xFFDBEAFE),
      'iconColor': const Color(0xFF1D4ED8),
    },
    {
      'name': 'Carpenter',
      'icon': Icons.handyman,
      'bg': const Color(0xFFFEF9C3),
      'iconColor': const Color(0xFF854D0E),
    },
    {
      'name': 'Maid',
      'icon': Icons.dry_cleaning,
      'bg': const Color(0xFFFFE4E6),
      'iconColor': const Color(0xFFE11D48),
    },
    {
      'name': 'Care Giver',
      'icon': Icons.volunteer_activism,
      'bg': const Color(0xFFD1FAE5),
      'iconColor': const Color(0xFF047857),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      // If a category is selected, find its corresponding Category ID from CategoryModel if loaded
      String? categoryId;
      if (_selectedCategory != null) {
        final categoryModel =
            Provider.of<CategoryModel>(context, listen: false);
        final matched = categoryModel.categories?.firstWhere(
          (c) =>
              (c.name?.toLowerCase().trim() ==
                  _selectedCategory!.toLowerCase().trim()) ||
              (c.slug?.toLowerCase().trim() ==
                  _selectedCategory!.toLowerCase().trim()),
          orElse: () => null as dynamic,
        );
        if (matched != null) {
          categoryId = matched.id;
        }
      }

      final query = _searchController.text.trim();
      final results = await Services().api.fetchProductsByCategory(
        page: 1,
        categoryId: categoryId,
        search: query.isNotEmpty ? query : null,
      );

      if (mounted) {
        setState(() {
          _allServices = results ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Product> get _filteredServices {
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      return _allServices;
    }

    final catLower = _selectedCategory!.toLowerCase();
    final filtered = _allServices.where((p) {
      final name = (p.name ?? '').toLowerCase();
      final cat = (p.categoryName ?? '').toLowerCase();
      final desc = (p.shortDescription ?? '').toLowerCase();
      return name.contains(catLower) ||
          cat.contains(catLower) ||
          desc.contains(catLower);
    }).toList();

    return filtered.isNotEmpty ? filtered : _allServices;
  }

  void _showRegionPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choose Service Area',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                ..._regions.map((reg) {
                  final isSelected = _selectedRegion == reg;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color:
                          isSelected ? const Color(0xFFFF6B00) : Colors.grey,
                      size: 20,
                    ),
                    title: Text(
                      reg,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFFFF6B00)
                            : const Color(0xFF1B1C1C),
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedRegion = reg);
                      Navigator.pop(context);
                      _loadServices();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = _filteredServices;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: const ZipBizTopHeader(showBackButton: true),
      body: RefreshIndicator(
        onRefresh: _loadServices,
        color: const Color(0xFFFF6B00),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. TOP SEARCH BAR (Exact match to Home Page)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE4E2E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Region Selector
                      GestureDetector(
                        onTap: _showRegionPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F7),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: const Color(0xFFE4E2E1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.explore,
                                  size: 18, color: Color(0xFFFF6B00)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SELECT REGION',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5A4136),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      _selectedRegion,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1B1C1C),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.unfold_more,
                                  size: 16, color: Color(0xFF5A4136)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Search Input & Search Button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F7),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFE4E2E1)),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (_) => _loadServices(),
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF1B1C1C)),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search Electrician, Plumber, Maid...',
                                  hintStyle: TextStyle(
                                      fontSize: 11, color: Color(0xFF8E7164)),
                                  prefixIcon: Icon(Icons.search,
                                      size: 18, color: Color(0xFF5A4136)),
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _loadServices,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B00),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.search, size: 16),
                            label: const Text(
                              'Search',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. SERVICE CATEGORIES SELECTOR (The 8 Listeo Categories)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Service Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B1C1C),
                          ),
                        ),
                        if (_selectedCategory != null)
                          GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategory = null);
                              _loadServices();
                            },
                            child: const Text(
                              'Clear Filter',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF6B00),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Categories Grid (4 x 2)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.9,
                      ),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = (_selectedCategory == cat['name']);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory =
                                  isSelected ? null : cat['name'];
                            });
                            _loadServices();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF6B00).withOpacity(0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF6B00)
                                    : const Color(0xFFE4E2E1),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: cat['bg'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    cat['icon'] as IconData,
                                    color: cat['iconColor'] as Color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  cat['name'] as String,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFFFF6B00)
                                        : const Color(0xFF1B1C1C),
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 3. ALL LISTINGS HEADER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory != null
                          ? '$_selectedCategory Services'
                          : 'All Available Listings',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B1C1C),
                      ),
                    ),
                    Text(
                      '${services.length} Listed',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A4136),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. LISTINGS CONTENT (Zomato / Swiggy List Format)
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child:
                      CircularProgressIndicator(color: Color(0xFFFF6B00)),
                ),
              )
            else if (services.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No services found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try clearing your category filter or adjusting your search query',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = null;
                            _searchController.clear();
                          });
                          _loadServices();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('View All Listings'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = services[index];
                      return _buildZomatoStyleListCard(item);
                    },
                    childCount: services.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ZOMATO / SWIGGY STYLE LIST CARD
  // =========================================================
  Widget _buildZomatoStyleListCard(Product product) {
    final priceStr = (product.price != null && product.price!.isNotEmpty)
        ? '₹${product.price}'
        : (product.regularPrice != null && product.regularPrice!.isNotEmpty)
            ? '₹${product.regularPrice}'
            : '₹499';

    final rating = (product.averageRating != null && product.averageRating! > 0)
        ? product.averageRating!.toStringAsFixed(1)
        : '4.9';
    final reviewCount = product.totalReview ?? 18;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E2E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            FluxNavigate.pushNamed(
              RouteList.productDetail,
              arguments: product,
              context: context,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: 95x95 Rounded Image Thumbnail with Badge
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 95,
                    height: 95,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        (product.imageFeature != null &&
                                product.imageFeature!.isNotEmpty)
                            ? Image.network(
                                product.imageFeature!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildImagePlaceholder(),
                              )
                            : _buildImagePlaceholder(),
                        // Verified badge on image
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified,
                                    size: 10, color: Color(0xFFFF6B00)),
                                SizedBox(width: 3),
                                Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Right: Details (Title, Rating, Category, Price & Book CTA)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        product.name ?? 'ZipBiz Service Partner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B1C1C),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Rating & Reviews Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF047857),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  rating,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.star,
                                    size: 11, color: Colors.white),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '($reviewCount reviews)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('•',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              product.categoryName ?? 'Expert Service',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Price & Book Button Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Starts at',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                priceStr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF6B00),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              FluxNavigate.pushNamed(
                                RouteList.productDetail,
                                arguments: product,
                                context: context,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B00),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Book',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 13),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(
          Icons.home_repair_service,
          color: Color(0xFF9CA3AF),
          size: 32,
        ),
      ),
    );
  }
}
