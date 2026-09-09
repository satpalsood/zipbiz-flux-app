import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/constants.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../models/entities/product.dart';
import '../../models/user_model.dart';
import '../../routes/flux_navigate.dart';
import '../../services/index.dart';
import '../../widgets/common/zipbiz_badge.dart';
import '../../widgets/common/zipbiz_button.dart';
import '../../widgets/common/zipbiz_card.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'booked', 'speed', 'emergency'
  String? _selectedCategory;
  String _selectedRegion = 'mohali';
  bool _isLoading = false;
  List<Product> _services = [];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Electrician', 'icon': Icons.bolt, 'color': Color(0xFFFFB693), 'iconColor': Color(0xFFA04100), 'count': '28'},
    {'name': 'Plumber', 'icon': Icons.plumbing, 'color': Color(0xFFD0E4FF), 'iconColor': Color(0xFF0062A1), 'count': '19'},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services, 'color': Color(0xFFEADDFF), 'iconColor': Color(0xFF6B4EA4), 'count': '42'},
    {'name': 'Appliance', 'icon': Icons.build, 'color': Color(0xFFFFDAD6), 'iconColor': Color(0xFFBA1A1A), 'count': '31'},
    {'name': 'Carpenter', 'icon': Icons.handyman, 'color': Color(0xFFFFDBCC), 'iconColor': Color(0xFF7A3000), 'count': '15'},
    {'name': 'Maid Help', 'icon': Icons.dry_cleaning, 'color': Color(0xFFF6F3F2), 'iconColor': Color(0xFF5A4136), 'count': '24'},
    {'name': 'Gardening', 'icon': Icons.yard, 'color': Color(0xFFE8F5E9), 'iconColor': Color(0xFF2E7D32), 'count': '12'},
    {'name': 'Caregiver', 'icon': Icons.volunteer_activism, 'color': Color(0xFFFCE4EC), 'iconColor': Color(0xFFC2185B), 'count': '8'},
    {'name': 'Home Salon', 'icon': Icons.face_retouching_natural, 'color': Color(0xFFF3E5F5), 'iconColor': Color(0xFF7B1FA2), 'count': '18'},
    {'name': 'Pest Control', 'icon': Icons.pest_control, 'color': Color(0xFFFFF3E0), 'iconColor': Color(0xFFE65100), 'count': '14'},
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
      final results = await Services().api.fetchProductsByCategory(
        page: 1,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      if (mounted) {
        setState(() {
          _services = results ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZipBizColors.surface,
      appBar: const ZipBizTopHeader(showBackButton: true),
      body: RefreshIndicator(
        onRefresh: _loadServices,
        color: ZipBizColors.primaryContainer,
        child: CustomScrollView(
          slivers: [
            // Region & Online Pros Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: ZipBizColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, size: 20, color: ZipBizColors.primaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Service Area', style: ZipBizTypography.labelSmall),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRegion,
                                isDense: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                items: const [
                                  DropdownMenuItem(value: 'mohali', child: Text('Mohali (Phases 1-11)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                  DropdownMenuItem(value: 'chandigarh', child: Text('Chandigarh (Sec 1-45)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                  DropdownMenuItem(value: 'kharar', child: Text('Kharar & Sunny Enclave', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                  DropdownMenuItem(value: 'zirakpur', child: Text('Zirakpur & VIP Road', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedRegion = val);
                                    _loadServices();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ZipBizColors.secondaryFixed.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: ZipBizColors.statusOpen, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text('142 Pros Online', style: ZipBizTypography.labelSmall.copyWith(color: ZipBizColors.onSecondaryFixed, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search Bar with Search CTA
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: ZipBizColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: ZipBizColors.outline, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Search Electrician, Plumber, Cleaner...',
                                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                onSubmitted: (_) => _loadServices(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ZipBizButton(
                      text: 'Search',
                      onPressed: _loadServices,
                      height: 44,
                      borderRadius: 12,
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Filter Chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('All Services', 'all', null),
                    _buildFilterChip('Most Booked', 'booked', Icons.local_fire_department),
                    _buildFilterChip('Quickest 15m', 'speed', Icons.bolt),
                    _buildFilterChip('Emergency', 'emergency', Icons.emergency),
                  ],
                ),
              ),
            ),

            // Categories Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Explore Categories', style: ZipBizTypography.headlineSmall),
                        const SizedBox(height: 2),
                        Text('Verified technicians & home experts', style: ZipBizTypography.labelMedium),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ZipBizColors.primaryFixed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('All Types', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ZipBizColors.onPrimaryFixedVariant)),
                    ),
                  ],
                ),
              ),
            ),

            // Category Grid (5 columns x 2 rows)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    final isSelected = (_selectedCategory == cat['name']);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = isSelected ? null : cat['name'];
                        });
                        _loadServices();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? ZipBizColors.primaryFixed : ZipBizColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? ZipBizColors.primaryContainer : ZipBizColors.surfaceContainer,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: cat['color'],
                                  child: Icon(cat['icon'], size: 20, color: cat['iconColor']),
                                ),
                                Positioned(
                                  top: -3,
                                  right: -3,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: ZipBizColors.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      cat['count'],
                                      style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              cat['name'],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: ZipBizColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Services List Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Available Services', style: ZipBizTypography.headlineSmall),
                    Text('${_services.length} Listed', style: ZipBizTypography.labelMedium),
                  ],
                ),
              ),
            ),

            // Services Items or Loading State
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: ZipBizColors.primaryContainer),
                ),
              )
            else if (_services.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No services found', style: ZipBizTypography.headlineSmall.copyWith(color: Colors.grey.shade700)),
                      const SizedBox(height: 6),
                      Text('Try adjusting your search or region', style: ZipBizTypography.labelMedium),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _services[index];
                      return _buildServiceCard(item);
                    },
                    childCount: _services.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, IconData? icon) {
    final isSelected = (_selectedFilter == key);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : ZipBizColors.primaryContainer),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : ZipBizColors.onSurfaceVariant,
        ),
        backgroundColor: ZipBizColors.surfaceContainerLow,
        selectedColor: ZipBizColors.secondary,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (val) {
          setState(() => _selectedFilter = key);
          _loadServices();
        },
      ),
    );
  }

  Widget _buildServiceCard(Product product) {
    final priceStr = (product.price != null && product.price!.isNotEmpty)
        ? '₹${product.price}'
        : (product.regularPrice != null && product.regularPrice!.isNotEmpty)
            ? '₹${product.regularPrice}'
            : '₹499';

    return ZipBizCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        FluxNavigate.pushNamed(
          RouteList.productDetail,
          arguments: product,
          context: context,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (product.imageFeature != null && product.imageFeature!.isNotEmpty)
                ? Image.network(
                    product.imageFeature!,
                    width: 85,
                    height: 85,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name ?? 'Service',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ZipBizTypography.labelLarge.copyWith(fontSize: 15),
                      ),
                    ),
                    const Icon(Icons.verified, size: 16, color: ZipBizColors.primaryContainer),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 3),
                    Text(
                      '${product.averageRating ?? 4.9} (${product.totalReview ?? 12})',
                      style: ZipBizTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    const Icon(Icons.schedule, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    const Text('45 mins', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Starts at', style: ZipBizTypography.labelSmall.copyWith(fontSize: 10)),
                        Text(priceStr, style: ZipBizTypography.labelLarge.copyWith(color: ZipBizColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ZipBizButton(
                      text: 'Book Now',
                      height: 32,
                      borderRadius: 8,
                      onPressed: () {
                        FluxNavigate.pushNamed(
                          RouteList.productDetail,
                          arguments: product,
                          context: context,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 85,
      height: 85,
      color: ZipBizColors.surfaceContainer,
      child: const Icon(Icons.home_repair_service, color: ZipBizColors.outline, size: 28),
    );
  }
}
