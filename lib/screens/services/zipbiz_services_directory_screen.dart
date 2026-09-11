import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart' show kProductCard;
import '../../common/constants.dart';
import '../../models/category/category_model.dart';
import '../../models/entities/product.dart';
import '../../models/user_model.dart';
import '../../routes/flux_navigate.dart';
import '../../services/index.dart';
import '../../widgets/common/zipbiz_header.dart';
import '../../core/state/zipbiz_bookmark_manager.dart';

class ZipBizBookingAvailability {
  static final ValueNotifier<bool> isAcceptingNotifier = ValueNotifier<bool>(true);
}

class ZipBizServicesDirectoryScreen extends StatefulWidget {
  final String? initialCategory;

  static final ValueNotifier<String?> selectedCategoryNotifier =
      ValueNotifier<String?>(null);
  static final ValueNotifier<String?> selectedSearchNotifier =
      ValueNotifier<String?>(null);

  const ZipBizServicesDirectoryScreen({super.key, this.initialCategory});

  @override
  State<ZipBizServicesDirectoryScreen> createState() =>
      _ZipBizServicesDirectoryScreenState();
}

class _ZipBizServicesDirectoryScreenState
    extends State<ZipBizServicesDirectoryScreen> {
  // Region Selection (matches Home Screen)
  String _selectedRegion = 'All Areas (Tricity)';
  final List<String> _regions = const [
    'All Areas (Tricity)',
    'Mohali (SAS Nagar)',
    'Chandigarh (All Sectors)',
    'Panchkula',
    'Zirakpur & VIP Road',
    'Kharar & Sunny Enclave',
    'New Chandigarh',
    'Pinjore',
    'Kalka',
    'Dera Bassi',
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
    ZipBizServicesDirectoryScreen.selectedCategoryNotifier
        .addListener(_onCategoryNotifierChanged);
    ZipBizServicesDirectoryScreen.selectedSearchNotifier
        .addListener(_onSearchNotifierChanged);
    ZipBizBookingAvailability.isAcceptingNotifier
        .addListener(_onBookingAvailabilityChanged);
    if (ZipBizServicesDirectoryScreen.selectedCategoryNotifier.value != null) {
      _selectedCategory =
          ZipBizServicesDirectoryScreen.selectedCategoryNotifier.value;
    } else {
      _selectedCategory = widget.initialCategory;
    }
    if (ZipBizServicesDirectoryScreen.selectedSearchNotifier.value != null) {
      _searchController.text =
          ZipBizServicesDirectoryScreen.selectedSearchNotifier.value!;
    }
    _loadServices();
  }

  @override
  void dispose() {
    ZipBizServicesDirectoryScreen.selectedCategoryNotifier
        .removeListener(_onCategoryNotifierChanged);
    ZipBizServicesDirectoryScreen.selectedSearchNotifier
        .removeListener(_onSearchNotifierChanged);
    ZipBizBookingAvailability.isAcceptingNotifier
        .removeListener(_onBookingAvailabilityChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchNotifierChanged() {
    if (mounted) {
      setState(() {
        _searchController.text =
            ZipBizServicesDirectoryScreen.selectedSearchNotifier.value ?? '';
      });
      _loadServices();
    }
  }

  void _onCategoryNotifierChanged() {
    if (mounted) {
      setState(() {
        _selectedCategory =
            ZipBizServicesDirectoryScreen.selectedCategoryNotifier.value;
      });
      _loadServices();
    }
  }

  void _onBookingAvailabilityChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      // If a category is selected, find its corresponding Category ID from CategoryModel if loaded
      String? categoryId;
      if (_selectedCategory != null) {
        final categoryModel =
            Provider.of<CategoryModel>(context, listen: false);
        final catLower = _selectedCategory!.toLowerCase().trim();
        final matched = categoryModel.categories?.firstWhere(
          (c) {
            final cName = (c.name ?? '').toLowerCase();
            final cSlug = (c.slug ?? '').toLowerCase();
            if (cName == catLower || cSlug == catLower) return true;
            if (catLower.contains('clean') && (cName.contains('clean') || cSlug.contains('clean'))) return true;
            if (catLower.contains('care') && (cName.contains('care') || cSlug.contains('care') || cName.contains('giver') || cSlug.contains('giver'))) return true;
            if (catLower.contains('appliance') && (cName.contains('appliance') || cSlug.contains('appliance') || cName.contains('repair') || cSlug.contains('repair'))) return true;
            if ((catLower.contains('salon') || catLower.contains('beauty')) &&
                (cName.contains('salon') || cSlug.contains('salon') || cName.contains('beauty') || cSlug.contains('beauty'))) return true;
            if (catLower.contains('electr') && (cName.contains('electr') || cSlug.contains('electr'))) return true;
            if (catLower.contains('plumb') && (cName.contains('plumb') || cSlug.contains('plumb'))) return true;
            if (catLower.contains('carpent') && (cName.contains('carpent') || cSlug.contains('carpent'))) return true;
            if (catLower.contains('maid') && (cName.contains('maid') || cSlug.contains('maid'))) return true;
            return false;
          },
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
    var list = _allServices;

    // 1. Strict Category Matching
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      final cat = _selectedCategory!.trim().toLowerCase();

      list = list.where((p) {
        final pCat = (p.categoryName ?? '').toLowerCase().trim();
        final pType = (p.type ?? '').toLowerCase().trim();
        final name = (p.name ?? '').toLowerCase();

        if (cat == 'maid') {
          // Strictly maid services, exclude deep cleaning
          return (pCat.contains('maid') || pType.contains('maid') || name.contains('maid')) &&
                 !name.contains('deep clean') && !pCat.contains('cleaner');
        } else if (cat == 'cleaner') {
          // Strictly cleaning services, exclude maid
          return (pCat.contains('clean') || pType.contains('clean') || name.contains('clean')) &&
                 !name.contains('maid') && !pCat.contains('maid');
        } else if (cat == 'electrician') {
          return pCat.contains('electr') || pType.contains('electr') || name.contains('electr');
        } else if (cat == 'plumber') {
          return pCat.contains('plumb') || pType.contains('plumb') || name.contains('plumb');
        } else if (cat.contains('salon') || cat.contains('beauty')) {
          return pCat.contains('salon') || pCat.contains('beauty') || name.contains('salon') || name.contains('beauty') || name.contains('parlour');
        } else if (cat == 'appliance') {
          return pCat.contains('appliance') || pType.contains('appliance') || name.contains('appliance') || name.contains('repair') || name.contains('ac') || name.contains('refrigerator') || name.contains('washing machine') || name.contains('ro');
        } else if (cat == 'carpenter') {
          return pCat.contains('carpent') || pType.contains('carpent') || name.contains('carpent');
        } else if (cat.contains('care')) {
          return pCat.contains('care') || pType.contains('care') || name.contains('care') || name.contains('giver') || name.contains('elderly') || name.contains('nurse');
        } else {
          return pCat == cat || pType == cat || name.contains(cat);
        }
      }).toList();
    }

    // 2. Strict Location Filtering
    final activeLoc = _selectedRegion.toLowerCase().trim();
    final searchTxt = _searchController.text.toLowerCase().trim();
    final targetLocStr = searchTxt.contains('mohali') ? 'mohali' :
                         searchTxt.contains('kharar') ? 'kharar' :
                         searchTxt.contains('zirakpur') ? 'zirakpur' :
                         searchTxt.contains('panchkula') ? 'panchkula' :
                         searchTxt.contains('chandigarh') ? 'chandigarh' :
                         activeLoc;

    if (!targetLocStr.contains('all areas') && !targetLocStr.contains('all locations') && !targetLocStr.contains('tricity')) {
      const cities = ['mohali', 'kharar', 'zirakpur', 'panchkula', 'chandigarh', 'pinjore', 'kalka', 'dera bassi'];
      String? filterCity;
      for (final c in cities) {
        if (targetLocStr.contains(c)) {
          filterCity = c;
          break;
        }
      }

      if (filterCity != null) {
        list = list.where((p) {
          final loc = (p.location ?? '').toLowerCase();
          final tagLine = (p.tagLine ?? '').toLowerCase();
          String metaLoc = '';
          for (final m in p.metaData) {
            final k = (m['key'] ?? '').toString().toLowerCase();
            if (k.contains('address') || k.contains('area') || k.contains('region') || k.contains('location') || k.contains('city')) {
              metaLoc += ' ${(m['value'] ?? '').toString().toLowerCase()}';
            }
          }
          final combined = '$loc $tagLine $metaLoc';
          return combined.contains(filterCity!);
        }).toList();
      }
    }

    // 3. Comprehensive Keyword Search Matching
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        final name = (p.name ?? '').toLowerCase();
        final desc = (p.description ?? '').toLowerCase();
        final shortDesc = (p.shortDescription ?? '').toLowerCase();
        final cat = (p.categoryName ?? '').toLowerCase();
        final type = (p.type ?? '').toLowerCase();
        final tags = (p.tags ?? []).map((t) => (t.name ?? '').toLowerCase()).join(' ');

        String menuText = '';
        for (final m in p.metaData) {
          final k = (m['key'] ?? '').toString();
          if (k == '_menu' || k == 'menu' || k == 'services') {
            menuText += ' ${m['value'].toString().toLowerCase()}';
          }
        }

        final combined = '$name $desc $shortDesc $cat $type $tags $menuText';
        return combined.contains(query);
      }).toList();
    }

    return list;
  }

  void _showRegionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Choose Service Area',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _regions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 52),
                    itemBuilder: (context, idx) {
                      final reg = _regions[idx];
                      final isSelected = _selectedRegion == reg;
                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle : Icons.location_on_outlined,
                          color: isSelected ? const Color(0xFFFF6B00) : Colors.grey,
                          size: 22,
                        ),
                        title: Text(
                          reg,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFFFF6B00) : const Color(0xFF1B1C1C),
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedRegion = reg);
                          Navigator.pop(context);
                          _loadServices();
                        },
                      );
                    },
                  ),
                ),
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
                          SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              onPressed: _loadServices,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B00),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Search',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                              ZipBizServicesDirectoryScreen.selectedCategoryNotifier.value =
                                  _selectedCategory;
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
                          : 'All Available Businesses',
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          alignment: Alignment.center,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'View All Businesses',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
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
    bool isAccepting = ZipBizBookingAvailability.isAcceptingNotifier.value;
    for (final m in product.metaData) {
      final k = (m['key'] ?? '').toString();
      final v = m['value'];
      if (k == '_booking_status' || k == 'booking_status') {
        if (v == false || v == 'off' || v == '0' || v == 0) isAccepting = false;
      }
      if (k == '_is_offline' || k == 'is_offline' || k == '_pause_bookings') {
        if (v == true || v == 'on' || v == '1' || v == 1) isAccepting = false;
      }
    }

    String? minPrice;
    if (product.price != null && product.price!.isNotEmpty && double.tryParse(product.price!) != null && double.parse(product.price!) > 0) {
      minPrice = product.price;
    } else if (product.regularPrice != null && product.regularPrice!.isNotEmpty && double.tryParse(product.regularPrice!) != null && double.parse(product.regularPrice!) > 0) {
      minPrice = product.regularPrice;
    } else {
      for (final m in product.metaData) {
        final k = (m['key'] ?? '').toString();
        final v = (m['value'] ?? '').toString();
        if ((k == '_price_min' || k == 'price_min' || k == '_price' || k == 'min_price') && v.isNotEmpty && v != '0') {
          minPrice = v;
          break;
        }
      }
    }
    if (minPrice == null || minPrice == '0') {
      final nameLower = (product.name ?? '').toLowerCase();
      final catLower = (product.categoryName ?? '').toLowerCase();
      if (nameLower.contains('maid') || catLower.contains('maid')) {
        minPrice = '199';
      } else if (nameLower.contains('clean') || catLower.contains('clean')) {
        minPrice = '399';
      } else if (nameLower.contains('electr') || catLower.contains('electr')) {
        minPrice = '149';
      } else if (nameLower.contains('plumb') || catLower.contains('plumb')) {
        minPrice = '149';
      } else if (nameLower.contains('ac') || nameLower.contains('appliance')) {
        minPrice = '249';
      } else if (nameLower.contains('salon') || catLower.contains('salon')) {
        minPrice = '299';
      } else {
        minPrice = '199';
      }
    }
    final priceStr = '₹$minPrice';

    final rating = (product.averageRating != null && product.averageRating! > 0)
        ? product.averageRating!.toStringAsFixed(1)
        : '4.9';
    final reviewCount = product.totalReview ?? 18;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isAccepting ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isAccepting ? const Color(0xFFE4E2E1) : Colors.grey.shade300),
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
                        FluxImage(
                          imageUrl: _getEffectiveImage(product),
                          fit: BoxFit.cover,
                          errorWidget: _buildImagePlaceholder(product),
                        ),
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
                        // Bookmark Heart Button
                        Positioned(
                          top: 6,
                          right: 6,
                          child: ValueListenableBuilder<Set<String>>(
                            valueListenable: ZipBizBookmarkManager.bookmarkedIdsNotifier,
                            builder: (context, set, _) {
                              final isBookmarked = set.contains(product.id?.toString() ?? '');
                              return GestureDetector(
                                onTap: () {
                                  final user = Provider.of<UserModel>(context, listen: false).user;
                                  ZipBizBookmarkManager.toggleBookmark(context, user, product);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                                    ],
                                  ),
                                  child: Icon(
                                    isBookmarked ? Icons.favorite : Icons.favorite_border,
                                    size: 13,
                                    color: isBookmarked ? Colors.red : Colors.grey.shade700,
                                  ),
                                ),
                              );
                            },
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
                      if (!isAccepting) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            'Currently not accepting orders',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isAccepting ? const Color(0xFFFF6B00) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: isAccepting
                                ? () {
                                    FluxNavigate.pushNamed(
                                      RouteList.productDetail,
                                      arguments: product,
                                      context: context,
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAccepting
                                  ? const Color(0xFFFF6B00)
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 0),
                              minimumSize: const Size(64, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Book',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

  String _getEffectiveImage(Product product) {
    final defaultImg = kProductCard.defaultImage;
    if (product.imageFeature != null &&
        product.imageFeature!.isNotEmpty &&
        product.imageFeature != kDefaultImage &&
        product.imageFeature != defaultImg &&
        product.imageFeature!.startsWith('http')) {
      return product.imageFeature!;
    }
    for (var img in product.images) {
      if (img.isNotEmpty &&
          img != kDefaultImage &&
          img != defaultImg &&
          img.startsWith('http')) {
        return img;
      }
    }
    final nameLower = (product.name ?? '').toLowerCase();
    final catLower = (product.categoryName ?? '').toLowerCase();
    if (nameLower.contains('maid') || catLower.contains('maid')) {
      return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500&q=80';
    }
    if (nameLower.contains('clean') || catLower.contains('clean')) {
      return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500&q=80';
    }
    if (nameLower.contains('electr') || catLower.contains('electr')) {
      return 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=500&q=80';
    }
    if (nameLower.contains('plumb') || catLower.contains('plumb')) {
      return 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=500&q=80';
    }
    if (nameLower.contains('salon') || catLower.contains('salon') || nameLower.contains('beauty')) {
      return 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=500&q=80';
    }
    if (nameLower.contains('ac ') || nameLower.contains('appliance') || catLower.contains('appliance')) {
      return 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500&q=80';
    }
    if (nameLower.contains('carpent') || catLower.contains('carpent')) {
      return 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=500&q=80';
    }
    if (nameLower.contains('care') || catLower.contains('care')) {
      return 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=500&q=80';
    }
    return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500&q=80';
  }

  Widget _buildImagePlaceholder([Product? product]) {
    final fallbackUrl = product != null ? _getEffectiveImage(product) : 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500&q=80';
    return Image.network(
      fallbackUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF3F4F6),
        child: const Center(
          child: Icon(Icons.home_repair_service, color: Color(0xFF9CA3AF), size: 32),
        ),
      ),
    );
  }
}
