import '../../core/state/zipbiz_cart_manager.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../frameworks/listing/screens/booking/booking.dart';
import '../../menu/maintab_delegate.dart';
import '../../models/entities/back_drop_arguments.dart';
import '../../models/entities/product.dart';
import '../../models/index.dart' show AppModel, UserModel;
import '../../routes/flux_navigate.dart';
import '../../services/services.dart';
import '../../widgets/common/zipbiz_header.dart';
import '../services/zipbiz_services_directory_screen.dart';

class ZipBizHomeView extends StatefulWidget {
  final ScrollController? scrollController;

  const ZipBizHomeView({super.key, this.scrollController});

  @override
  State<ZipBizHomeView> createState() => _ZipBizHomeViewState();
}

class _ZipBizHomeViewState extends State<ZipBizHomeView> {
  // Region Selection
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

  // Search
  final TextEditingController _searchController = TextEditingController();

  // Banner Carousel
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  // Dynamic API Data
  List<Product> _popularServices = [];
  List<Product> _popularProviders = [];
  bool _isLoadingServices = true;
  bool _isLoadingProviders = true;

  @override
  void initState() {
    super.initState();
    _startBannerAutoPlay();
    _loadApiData();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startBannerAutoPlay() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % 3;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadApiData() async {
    // 1. Fetch Popular Services
    try {
      final services = await Services().api.fetchProductsLayout(
        config: {
          'limit': 10,
          'orderby': 'popularity',
          'order': 'desc',
        },
      );
      if (mounted) {
        setState(() {
          _popularServices = services ?? [];
          _isLoadingServices = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingServices = false);
      }
    }

    // 2. Fetch Popular Service Providers / Featured Listings
    try {
      final providers = await Services().api.fetchProductsByCategory(
        page: 1,
        featured: true,
      );
      if (mounted) {
        setState(() {
          _popularProviders = providers ?? [];
          _isLoadingProviders = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProviders = false);
      }
    }
  }

  void _navigateToSearch({String? query, String? category}) {
    final q = query ?? _searchController.text.trim();
    if (category != null && category.isNotEmpty) {
      ZipBizServicesDirectoryScreen.selectedCategoryNotifier.value = category;
    } else {
      ZipBizServicesDirectoryScreen.selectedCategoryNotifier.value = null;
    }
    ZipBizServicesDirectoryScreen.selectedSearchNotifier.value = q.isNotEmpty ? q : null;
    MainTabControlDelegate.getInstance().changeTab(RouteList.category);
  }

  void _navigateToCategory(String categoryName) {
    ZipBizServicesDirectoryScreen.selectedCategoryNotifier.value = categoryName;
    ZipBizServicesDirectoryScreen.selectedSearchNotifier.value = null;
    MainTabControlDelegate.getInstance().changeTab(RouteList.category);
  }

  Future<void> _openServiceBySlug(
      String slug, String fallbackTitle, String webUrl) async {
    Product? matched;
    for (final p in [..._popularServices, ..._popularProviders]) {
      if ((p.permalink ?? '').contains(slug) ||
          (p.name ?? '').toLowerCase().contains(fallbackTitle.toLowerCase())) {
        matched = p;
        break;
      }
    }

    if (matched != null) {
      FluxNavigate.pushNamed(
        RouteList.productDetail,
        arguments: matched,
        context: context,
      );
      return;
    }

    try {
      final results = await Services().api.fetchProductsByCategory(
        page: 1,
        search: fallbackTitle,
      );
      if (results != null && results.isNotEmpty) {
        if (mounted) {
          FluxNavigate.pushNamed(
            RouteList.productDetail,
            arguments: results.first,
            context: context,
          );
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      FluxNavigate.pushNamed(
        RouteList.category,
        arguments: fallbackTitle,
        context: context,
      );
    }
  }

  void _openBooking(Product? product) {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) {
      FluxNavigate.pushNamed(RouteList.login, context: context);
      return;
    }
    if (product != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingScreen(product: product),
        ),
      );
    } else {
      FluxNavigate.pushNamed(RouteList.search, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      color: const Color(0xFFFF6B00),
      onRefresh: _loadApiData,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP APP HEADER
            _buildAppHeader(context, theme),

            // Main Content Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // 2. HERO SLIDESHOW / BANNER CAROUSEL
                  _buildHeroCarousel(context),
                  const SizedBox(height: 16),

                  // 3. SEARCH SERVICES CARD (Region dropdown + Search input + Button)
                  _buildSearchCard(context, theme),
                  const SizedBox(height: 24),

                  // 4. POPULAR CATEGORIES GRID (8 Custom Categories)
                  _buildPopularCategoriesGrid(context, theme),
                  const SizedBox(height: 24),

                  // 5. SLIDING SECTION: POPULAR SERVICES + BUTTON
                  _buildPopularServicesSlider(context, theme),
                  const SizedBox(height: 24),

                  // 6. SLIDING SECTION: POPULAR SERVICE PROVIDERS + BUTTON
                  _buildPopularProvidersSlider(context, theme),
                  const SizedBox(height: 24),

                  // 6a. SLIDING SECTION: MAID SERVICES + BUTTON
                  _buildMaidServicesSlider(context, theme),
                  const SizedBox(height: 24),

                  // 6b. SLIDING SECTION: DEEP CLEANING SERVICES + BUTTON
                  _buildDeepCleaningServicesSlider(context, theme),
                  const SizedBox(height: 24),

                  // 7. PROMOTIONAL OFFERS & GUARANTEES
                  _buildPromotionalOffers(context, theme),
                  const SizedBox(height: 24),

                  // 9. SERVICE PROVIDER RECRUITMENT BANNER
                  _buildPartnerRecruitmentBanner(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. TOP APP HEADER
  // ==========================================
  Widget _buildAppHeader(BuildContext context, ThemeData theme) {
    return const ZipBizTopHeader();
  }

  // ==========================================
  // 2. HERO SLIDESHOW / BANNER CAROUSEL
  // ==========================================
  Widget _buildHeroCarousel(BuildContext context) {
    final slides = [
      {
        'badge': 'LIMITED OFFER',
        'badgeBg': const Color(0xFFFF6B00),
        'title': '50% OFF AC Deep Cleaning',
        'subtitle': 'Certified jet pump service & gas recharge',
        'cta': 'Book Now',
        'ctaIcon': Icons.arrow_forward,
        'image':
            'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800&q=80',
        'gradient': [
          Colors.black.withOpacity(0.85),
          Colors.black.withOpacity(0.4),
          Colors.transparent
        ],
        'action': () => _navigateToCategory('Cleaner'),
      },
      {
        'badge': 'TOP RATED',
        'badgeBg': const Color(0xFF6B4EA4),
        'title': 'Trusted Maids & Cleaners',
        'subtitle': 'Background verified staff with 100% safety',
        'cta': 'Explore Packages',
        'ctaIcon': Icons.arrow_forward,
        'image':
            'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80',
        'gradient': [
          const Color(0xFF4F3287).withOpacity(0.9),
          const Color(0xFF4F3287).withOpacity(0.5),
          Colors.transparent
        ],
        'action': () => _navigateToCategory('Maid'),
      },
      {
        'badge': 'QUICK DISPATCH',
        'badgeBg': const Color(0xFF0062A1),
        'title': 'Expert Repairs in 30 Mins',
        'subtitle': 'Electricians & Plumbers right at doorstep',
        'cta': 'Get Help Now',
        'ctaIcon': Icons.bolt,
        'image':
            'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=800&q=80',
        'gradient': [
          const Color(0xFF003357).withOpacity(0.9),
          const Color(0xFF003357).withOpacity(0.55),
          Colors.transparent
        ],
        'action': () => _navigateToCategory('Electrician'),
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black87,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      Image.network(
                        slide['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900),
                      ),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: slide['gradient'] as List<Color>,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Badge Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: slide['badgeBg'] as Color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                slide['badge'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            // Text block
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slide['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  slide['subtitle'] as String,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            // Action button
                            SizedBox(
                              height: 28,
                              child: ElevatedButton(
                                onPressed: slide['action'] as VoidCallback,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: slide['badgeBg'] == const Color(0xFF6B4EA4)
                                      ? Colors.white
                                      : const Color(0xFFFF6B00),
                                  foregroundColor: slide['badgeBg'] == const Color(0xFF6B4EA4)
                                      ? const Color(0xFF4F3287)
                                      : Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  alignment: Alignment.center,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      slide['cta'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(slide['ctaIcon'] as IconData, size: 13),
                                  ],
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
            },
          ),
        ),
        const SizedBox(height: 8),
        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slides.length,
            (idx) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBannerIndex == idx ? 20 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: _currentBannerIndex == idx
                    ? const Color(0xFFFF6B00)
                    : const Color(0xFFE2BFB0).withOpacity(0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. SEARCH SERVICES SECTION (Region + Search)
  // ==========================================
  Widget _buildSearchCard(BuildContext context, ThemeData theme) {
    return Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE4E2E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.explore, size: 18, color: Color(0xFFFF6B00)),
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
                  const Icon(Icons.unfold_more, size: 16, color: Color(0xFF5A4136)),
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
                    border: Border.all(color: const Color(0xFFE4E2E1)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (val) => _navigateToSearch(query: val),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1B1C1C)),
                    decoration: const InputDecoration(
                      hintText: 'Search Electrician, Plumber, Maid...',
                      hintStyle: TextStyle(fontSize: 11, color: Color(0xFF8E7164)),
                      prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF5A4136)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: () => _navigateToSearch(),
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
    );
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

  // ==========================================
  // 4. POPULAR CATEGORIES GRID (8 Custom Categories)
  // ==========================================
  Widget _buildPopularCategoriesGrid(BuildContext context, ThemeData theme) {
    final categories = [
      {
        'name': 'Electrician',
        'icon': Icons.bolt,
        'bg': const Color(0xFFFEF3C7), // amber-100
        'iconColor': const Color(0xFFD97706), // amber-600
      },
      {
        'name': 'Plumber',
        'icon': Icons.plumbing,
        'bg': const Color(0xFFE0F2FE), // sky-100
        'iconColor': const Color(0xFF0284C7), // sky-600
      },
      {
        'name': 'Cleaner',
        'icon': Icons.cleaning_services,
        'bg': const Color(0xFFFFEDD5), // orange-100
        'iconColor': const Color(0xFFFF6B00), // orange-500
      },
      {
        'name': 'Home Salon',
        'icon': Icons.face_retouching_natural,
        'bg': const Color(0xFFF3E8FF), // purple-100
        'iconColor': const Color(0xFF7E22CE), // purple-700
      },
      {
        'name': 'Appliance',
        'icon': Icons.build,
        'bg': const Color(0xFFDBEAFE), // blue-100
        'iconColor': const Color(0xFF1D4ED8), // blue-700
      },
      {
        'name': 'Carpenter',
        'icon': Icons.handyman,
        'bg': const Color(0xFFFEF9C3), // amber-50
        'iconColor': const Color(0xFF854D0E), // yellow-800
      },
      {
        'name': 'Maid',
        'icon': Icons.dry_cleaning,
        'bg': const Color(0xFFFFE4E6), // rose-100
        'iconColor': const Color(0xFFE11D48), // rose-600
      },
      {
        'name': 'Care Giver',
        'icon': Icons.volunteer_activism,
        'bg': const Color(0xFFD1FAE5), // emerald-100
        'iconColor': const Color(0xFF047857), // emerald-700
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.grid_view, color: Color(0xFFFF6B00), size: 19),
                SizedBox(width: 6),
                Text(
                  'Popular Categories',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1C1C),
                  ),
                ),
              ],
            ),
            const Text(
              '8 Categories',
              style: TextStyle(fontSize: 11, color: Color(0xFF5A4136), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 Columns Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return GestureDetector(
              onTap: () => _navigateToCategory(cat['name'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E2E1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cat['bg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        cat['icon'] as IconData,
                        color: cat['iconColor'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat['name'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B1C1C),
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
        const SizedBox(height: 10),

        // All Categories Button
        SizedBox(
          width: double.infinity,
          height: 38,
          child: OutlinedButton(
            onPressed: () {
              ZipBizServicesDirectoryScreen.selectedCategoryNotifier.value = null;
              MainTabControlDelegate.getInstance().changeTab(RouteList.category);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: const Color(0xFF8E7164).withOpacity(0.3)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'All Categories',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B1C1C),
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF1B1C1C)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 5. SLIDING SECTION: POPULAR SERVICES
  // ==========================================
  Widget _buildPopularServicesSlider(BuildContext context, ThemeData theme) {
    final popularServices5 = [
      {
        'title': '2 Hours Maid Service',
        'rating': '4.9 (520)',
        'duration': '2 hrs',
        'price': '₹399',
        'image':
            'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500&q=80',
        'type': 'maid',
      },
      {
        'title': '4 Hours Maid Service',
        'rating': '4.9 (780)',
        'duration': '4 hrs',
        'price': '₹799',
        'image':
            'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=500&q=80',
        'type': 'maid',
      },
      {
        'title': '3 Bathroom cleaning',
        'rating': '4.8 (640)',
        'duration': '2-3 hrs',
        'price': '₹1299',
        'image':
            'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&q=80',
        'type': 'cleaning',
      },
      {
        'title': 'Full 2BHK Home Deep Cleaning',
        'rating': '4.9 (1.1k)',
        'duration': '4-5 hrs',
        'price': '₹3499',
        'image':
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=500&q=80',
        'type': 'cleaning',
      },
      {
        'title': 'Full 3BHK Home Deep Cleaning',
        'rating': '4.9 (1.4k)',
        'duration': '5-6 hrs',
        'price': '₹5499',
        'image':
            'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?w=500&q=80',
        'type': 'cleaning',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Popular Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1C1C),
                  ),
                ),
                Text(
                  'Most booked services in Tricity',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5A4136)),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                ZipBizServicesDirectoryScreen.selectedCategoryNotifier.value = null;
                MainTabControlDelegate.getInstance().changeTab(RouteList.category);
              },
              child: Row(
                children: const [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B00),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFFFF6B00)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal Slider (5 services)
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popularServices5.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = popularServices5[index];
              final title = item['title']!;
              final rating = item['rating']!;
              final duration = item['duration']!;
              final price = item['price']!;
              final img = item['image']!;
              final type = item['type']!;

              void handleServiceTap() {
                if (type == 'maid') {
                  _openServiceBySlug(
                    'zipbiz-maid-service',
                    'Zipbiz Maid Service',
                    'https://zipbiz.in/business/zipbiz-maid-service/',
                  );
                } else {
                  _openServiceBySlug(
                    'zipbiz-cleaning-services',
                    'Zipbiz Cleaning Service',
                    'https://zipbiz.in/business/zipbiz-cleaning-services/',
                  );
                }
              }

              return GestureDetector(
                onTap: handleServiceTap,
                child: Container(
                  width: 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4E2E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Image with Rating Overlay
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            child: FluxImage(
                              imageUrl: img,
                              height: 100,
                              width: 170,
                              fit: BoxFit.cover,
                              errorWidget: Container(
                                height: 100,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.cleaning_services, color: Colors.grey),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 10),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Content Details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1B1C1C),
                                      height: 1.15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 10, color: Color(0xFF5A4136)),
                                      const SizedBox(width: 3),
                                      Text(
                                        duration,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF5A4136),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Pricing & CTA
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    price,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF6B00),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 22,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final numPrice = double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
                                        ZipBizCartManager.addToCart(
                                          ZipBizCartItem(
                                            id: title,
                                            title: title,
                                            serviceName: title,
                                            price: numPrice,
                                            businessTitle: type == 'maid' ? 'Zipbiz Maid Service' : 'Zipbiz Cleaning Service',
                                            businessSlug: type == 'maid' ? 'zipbiz-maid-services' : 'zipbiz-cleaning-services',
                                          ),
                                          context,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF6B00),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        minimumSize: const Size(36, 20),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        alignment: Alignment.center,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      child: const Text(
                                        'Add',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          height: 1.0,
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // All Services Button
        SizedBox(
          width: double.infinity,
          height: 38,
          child: OutlinedButton(
            onPressed: () {
              ZipBizServicesDirectoryScreen.selectedCategoryNotifier.value = null;
              MainTabControlDelegate.getInstance().changeTab(RouteList.category);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF6B00)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
            ),
            child: const Text(
              'All Services',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B00),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 6. SLIDING SECTION: POPULAR SERVICE PROVIDERS
  // ==========================================
  Widget _buildPopularProvidersSlider(BuildContext context, ThemeData theme) {
    final hasLive = _popularProviders.isNotEmpty;
    final count = hasLive ? _popularProviders.length : 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Popular Service Providers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1C1C),
                  ),
                ),
                Text(
                  'Top-rated background-checked professionals',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5A4136)),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                ZipBizServicesDirectoryScreen.selectedCategoryNotifier.value = null;
                MainTabControlDelegate.getInstance().changeTab(RouteList.category);
              },
              child: Row(
                children: const [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B00),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFFFF6B00)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal Slider of Providers
        SizedBox(
          height: 126,
          child: _isLoadingProviders
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: count,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    Product? liveProvider;
                    String name;
                    String rating;
                    String price;
                    String avatar;

                    if (hasLive) {
                      liveProvider = _popularProviders[index];
                      name = liveProvider.name ?? 'Verified';
                      rating = '${liveProvider.averageRating ?? 4.9} (${liveProvider.ratingCount ?? 45} reviews)';
                      price = liveProvider.price?.isNotEmpty ?? false
                          ? 'Starts ₹${liveProvider.price}'
                          : 'Starts ₹199';
                      avatar = liveProvider.imageFeature ?? '';
                    } else {
                      name = 'Professional Partner';
                      rating = '4.9 (100+ reviews)';
                      price = 'Starts ₹199';
                      avatar = '';
                    }

                    void openProvider() {
                      if (liveProvider != null) {
                        FluxNavigate.pushNamed(
                          RouteList.productDetail,
                          arguments: liveProvider,
                          context: context,
                        );
                      } else {
                        FluxNavigate.pushNamed(RouteList.category, context: context);
                      }
                    }

                    return GestureDetector(
                      onTap: openProvider,
                      child: Container(
                        width: 210,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE4E2E1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.5),
                                    child: avatar.isNotEmpty
                                        ? FluxImage(
                                            imageUrl: avatar,
                                            fit: BoxFit.cover,
                                            errorWidget: Container(
                                              color: Colors.grey.shade100,
                                              child: const Icon(Icons.person, color: Colors.grey, size: 22),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey.shade100,
                                            child: const Icon(Icons.person, color: Colors.grey, size: 22),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1FAE5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.verified, size: 9, color: Color(0xFF047857)),
                                            SizedBox(width: 2),
                                            Text(
                                              'Verified',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF047857),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1B1C1C),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, size: 10, color: Colors.amber),
                                          const SizedBox(width: 2),
                                          Text(
                                            rating,
                                            style: const TextStyle(fontSize: 9, color: Color(0xFF5A4136)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  price,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B1C1C),
                                  ),
                                ),
                                SizedBox(
                                  height: 24,
                                  child: ElevatedButton(
                                    onPressed: openProvider,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6B00),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      alignment: Alignment.center,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: const Text(
                                      'Book',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),

        // All Service Providers Button
        SizedBox(
          width: double.infinity,
          height: 38,
          child: OutlinedButton(
            onPressed: () {
              ZipBizServicesDirectoryScreen.selectedCategoryNotifier.value = null;
              MainTabControlDelegate.getInstance().changeTab(RouteList.category);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6B4EA4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
            ),
            child: const Text(
              'All Service Providers',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4EA4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 6a. SLIDING SECTION: MAID SERVICES
  // ==========================================
  Widget _buildMaidServicesSlider(BuildContext context, ThemeData theme) {
    final maidServices = [
      {
        'title': '1 Hour Maid Service',
        'rating': '4.8 (320)',
        'duration': '1 hr',
        'price': '₹199',
        'image':
            'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500&q=80',
      },
      {
        'title': '2 Hours Maid Service',
        'rating': '4.9 (520)',
        'duration': '2 hrs',
        'price': '₹399',
        'image':
            'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=500&q=80',
      },
      {
        'title': '4 Hours Maid Service',
        'rating': '4.9 (780)',
        'duration': '4 hrs',
        'price': '₹799',
        'image':
            'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&q=80',
      },
      {
        'title': 'Full Day Maid Service',
        'rating': '4.9 (410)',
        'duration': '8 hrs',
        'price': '₹1,499',
        'image':
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=500&q=80',
      },
    ];

    void redirectToMaidListing() {
      _openServiceBySlug(
        'zipbiz-maid-service',
        'Zipbiz Maid Service',
        'https://zipbiz.in/business/zipbiz-maid-service/',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Maid Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1C1C),
                  ),
                ),
                Text(
                  'Daily chores, cooking & housekeeping assistants',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5A4136)),
                ),
              ],
            ),
            GestureDetector(
              onTap: redirectToMaidListing,
              child: Row(
                children: const [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B00),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFFFF6B00)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal Slider
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: maidServices.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = maidServices[index];
              final title = item['title']!;
              final rating = item['rating']!;
              final duration = item['duration']!;
              final price = item['price']!;
              final img = item['image']!;

              return GestureDetector(
                onTap: redirectToMaidListing,
                child: Container(
                  width: 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4E2E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            child: FluxImage(
                              imageUrl: img,
                              height: 100,
                              width: 170,
                              fit: BoxFit.cover,
                              errorWidget: Container(
                                height: 100,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.cleaning_services, color: Colors.grey),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 10),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1B1C1C),
                                      height: 1.15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 10, color: Color(0xFF5A4136)),
                                      const SizedBox(width: 3),
                                      Text(
                                        duration,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF5A4136),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    price,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF6B00),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 24,
                                    child: ElevatedButton(
                                      onPressed: redirectToMaidListing,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF6B00),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        minimumSize: const Size(44, 22),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        alignment: Alignment.center,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Add',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // View Services Button (Redirects to Maid Service listing details)
        SizedBox(
          width: double.infinity,
          height: 38,
          child: OutlinedButton(
            onPressed: redirectToMaidListing,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF6B00)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
            ),
            child: const Text(
              'View Services',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B00),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 6b. SLIDING SECTION: DEEP CLEANING SERVICES
  // ==========================================
  Widget _buildDeepCleaningServicesSlider(BuildContext context, ThemeData theme) {
    final cleaningServices = [
      {
        'title': 'Bathroom Cleaning',
        'rating': '4.8 (390)',
        'duration': '1-2 hrs',
        'price': '₹499',
        'image':
            'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&q=80',
      },
      {
        'title': '3 Bathroom cleaning',
        'rating': '4.8 (640)',
        'duration': '2-3 hrs',
        'price': '₹1299',
        'image':
            'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&q=80',
      },
      {
        'title': 'Kitchen Deep Cleaning',
        'rating': '4.9 (450)',
        'duration': '2-3 hrs',
        'price': '₹999',
        'image':
            'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=500&q=80',
      },
      {
        'title': 'Sofa Cleaning',
        'rating': '4.8 (520)',
        'duration': '1-2 hrs',
        'price': '₹799',
        'image':
            'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500&q=80',
      },
      {
        'title': '1 BHK Deep Cleaning',
        'rating': '4.9 (350)',
        'duration': '3-4 hrs',
        'price': '₹2,199',
        'image':
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=500&q=80',
      },
      {
        'title': '2 BHK Deep Cleaning',
        'rating': '4.9 (1.1k)',
        'duration': '4-5 hrs',
        'price': '₹3499',
        'image':
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=500&q=80',
      },
      {
        'title': '3 BHK Deep Cleaning',
        'rating': '4.9 (1.4k)',
        'duration': '5-6 hrs',
        'price': '₹5499',
        'image':
            'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?w=500&q=80',
      },
    ];

    void redirectToCleaningListing() {
      _openServiceBySlug(
        'zipbiz-cleaning-services',
        'Zipbiz Cleaning Service',
        'https://zipbiz.in/business/zipbiz-cleaning-services/',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Deep Cleaning Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1C1C),
                  ),
                ),
                Text(
                  'Intensive deep cleaning & sanitization packages',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5A4136)),
                ),
              ],
            ),
            GestureDetector(
              onTap: redirectToCleaningListing,
              child: Row(
                children: const [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0062A1),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFF0062A1)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal Slider
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cleaningServices.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = cleaningServices[index];
              final title = item['title']!;
              final rating = item['rating']!;
              final duration = item['duration']!;
              final price = item['price']!;
              final img = item['image']!;

              return GestureDetector(
                onTap: redirectToCleaningListing,
                child: Container(
                  width: 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4E2E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            child: FluxImage(
                              imageUrl: img,
                              height: 100,
                              width: 170,
                              fit: BoxFit.cover,
                              errorWidget: Container(
                                height: 100,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.cleaning_services, color: Colors.grey),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 10),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1B1C1C),
                                      height: 1.15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 10, color: Color(0xFF5A4136)),
                                      const SizedBox(width: 3),
                                      Text(
                                        duration,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF5A4136),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    price,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF6B00),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 24,
                                    child: ElevatedButton(
                                      onPressed: redirectToCleaningListing,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF6B00),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        minimumSize: const Size(44, 22),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        alignment: Alignment.center,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Add',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // View Services Button (Redirects to Cleaning Service listing details)
        SizedBox(
          width: double.infinity,
          height: 38,
          child: OutlinedButton(
            onPressed: redirectToCleaningListing,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0062A1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
            ),
            child: const Text(
              'View Services',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0062A1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 7. PROMOTIONAL OFFERS & GUARANTEES (Cards Only, No Buttons)
  // ==========================================
  Widget _buildPromotionalOffers(BuildContext context, ThemeData theme) {
    final offers = [
      {
        'badge': 'FESTIVAL SPECIAL',
        'title': 'Flat ₹150 OFF on Cleaning',
        'desc': 'Use code ZIPFEST on checkout',
        'gradient': const [Color(0xFFEA580C), Color(0xFFF59E0B)],
        'icon': Icons.savings,
      },
      {
        'badge': 'LIMITED SLOT',
        'title': 'Free AC Inspection Visit',
        'desc': 'Zero diagnosis charges on first service',
        'gradient': const [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
        'icon': Icons.ac_unit,
      },
      {
        'badge': 'TRUST & QUALITY',
        'title': '100% Satisfaction Guarantee',
        'desc': 'Verified Pros or free rework within 7 days',
        'gradient': const [Color(0xFF047857), Color(0xFF0D9488)],
        'icon': Icons.verified_user,
      },
      {
        'badge': 'REFERRAL PROGRAM',
        'title': 'Earn ₹200 ZipCredits',
        'desc': 'Invite neighbors in Chandigarh & Mohali',
        'gradient': const [Color(0xFF6B4EA4), Color(0xFF4338CA)],
        'icon': Icons.group_add,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.local_offer, color: Color(0xFFFF6B00), size: 18),
            SizedBox(width: 6),
            Text(
              'Exclusive Offers & Guarantees',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B1C1C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final offer = offers[idx];
              return GestureDetector(
                onTap: () => FluxNavigate.pushNamed(RouteList.category, context: context),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: offer['gradient'] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (offer['gradient'] as List<Color>).first.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        offer['icon'] as IconData,
                        size: 70,
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            offer['badge'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          offer['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          offer['desc'] as String,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 8. SERVICE PROVIDER RECRUITMENT BANNER
  // ==========================================
  Widget _buildPartnerRecruitmentBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1C1C), Color(0xFF2D221E), Color(0xFF401802)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -20,
            child: Icon(
              Icons.handshake_outlined,
              size: 110,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.business_center, color: Color(0xFFFF6B00), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'PARTNER WITH US',
                    style: TextStyle(
                      color: Color(0xFFFF6B00),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Are you a Service Provider?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Join ZipBiz to get your services listed on our platform and grow your business in Chandigarh, Mohali & Panchkula.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    FluxNavigate.pushNamed(RouteList.register, context: context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        'Start Now',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.1),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
