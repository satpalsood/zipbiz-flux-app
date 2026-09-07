import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../frameworks/listing/screens/booking/booking.dart';
import '../../models/entities/back_drop_arguments.dart';
import '../../models/entities/product.dart';
import '../../models/index.dart' show AppModel, UserModel;
import '../../routes/flux_navigate.dart';
import '../../services/services.dart';
import '../../widgets/common/zipbiz_header.dart';

class ZipBizHomeView extends StatefulWidget {
  final ScrollController? scrollController;

  const ZipBizHomeView({super.key, this.scrollController});

  @override
  State<ZipBizHomeView> createState() => _ZipBizHomeViewState();
}

class _ZipBizHomeViewState extends State<ZipBizHomeView> {
  // Region Selection
  String _selectedRegion = 'Chandigarh, Mohali, Kharar, Zirakpur';
  final List<String> _regions = const [
    'Chandigarh, Mohali, Kharar, Zirakpur',
    'Chandigarh (All Sectors)',
    'Mohali (Phase 1-11 & Aerocity)',
    'Kharar & Sunny Enclave',
    'Zirakpur & VIP Road',
    'Panchkula',
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
    FluxNavigate.pushNamed(
      RouteList.search,
      arguments: {
        'search': query ?? _searchController.text.trim(),
        'category': category,
        'location': _selectedRegion,
      },
      context: context,
    );
  }

  void _navigateToCategory(String categoryName) {
    FluxNavigate.pushNamed(
      RouteList.backdrop,
      arguments: BackDropArguments(
        cateName: categoryName,
      ),
      context: context,
    );
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

                  // 7. DEDICATED SLIDING SECTIONS FOR EACH TRADE
                  _buildTradeSliders(context, theme),
                  const SizedBox(height: 24),

                  // 8. PROMOTIONAL OFFERS & GUARANTEES
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
                            ElevatedButton(
                              onPressed: slide['action'] as VoidCallback,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: slide['badgeBg'] == const Color(0xFF6B4EA4)
                                    ? Colors.white
                                    : const Color(0xFFFF6B00),
                                foregroundColor: slide['badgeBg'] == const Color(0xFF6B4EA4)
                                    ? const Color(0xFF4F3287)
                                    : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    slide['cta'] as String,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(slide['ctaIcon'] as IconData, size: 13),
                                ],
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
              ElevatedButton.icon(
                onPressed: () => _navigateToSearch(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.search, size: 16),
                label: const Text(
                  'Search',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? const Color(0xFFFF6B00) : Colors.grey,
                      size: 20,
                    ),
                    title: Text(
                      reg,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFFFF6B00) : const Color(0xFF1B1C1C),
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedRegion = reg);
                      Navigator.pop(context);
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
              FluxNavigate.pushNamed(RouteList.category, context: context);
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
    // Fallback curated services if API list is empty
    final defaultServices = [
      {
        'title': 'Full Home Deep Cleaning',
        'rating': '4.9 (1.2k)',
        'duration': '4-5 hrs',
        'price': '₹1,499',
        'oldPrice': '₹1,999',
        'image':
            'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500&q=80',
      },
      {
        'title': 'AC Comprehensive Service',
        'rating': '4.8 (890)',
        'duration': '60 mins',
        'price': '₹499',
        'oldPrice': '₹799',
        'image':
            'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500&q=80',
      },
      {
        'title': 'Bathroom Deep Cleaning',
        'rating': '4.7 (650)',
        'duration': '90 mins',
        'price': '₹399',
        'oldPrice': '₹599',
        'image':
            'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&q=80',
      },
      {
        'title': 'Kitchen Modular Cleaning',
        'rating': '4.9 (430)',
        'duration': '2 hrs',
        'price': '₹699',
        'oldPrice': '₹999',
        'image':
            'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=500&q=80',
      },
      {
        'title': 'Water Purifier RO Repair',
        'rating': '4.8 (310)',
        'duration': '45 mins',
        'price': '₹299',
        'oldPrice': '₹450',
        'image':
            'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500&q=80',
      },
    ];

    final hasLive = _popularServices.isNotEmpty;
    final count = hasLive ? _popularServices.length : defaultServices.length;

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
              onTap: () => _navigateToSearch(),
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
          child: _isLoadingServices
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: count,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    Product? liveProduct;
                    String title;
                    String rating;
                    String duration;
                    String price;
                    String? oldPrice;
                    String img;

                    if (hasLive) {
                      liveProduct = _popularServices[index];
                      title = liveProduct.name ?? 'Service';
                      rating = '${liveProduct.averageRating ?? 4.8}';
                      duration = '30-60 mins';
                      price = liveProduct.price?.isNotEmpty ?? false
                          ? '₹${liveProduct.price}'
                          : '₹499';
                      oldPrice = liveProduct.regularPrice?.isNotEmpty ?? false
                          ? '₹${liveProduct.regularPrice}'
                          : null;
                      img = liveProduct.imageFeature?.isNotEmpty ?? false
                          ? liveProduct.imageFeature!
                          : (liveProduct.images.isNotEmpty
                              ? liveProduct.images.first
                              : defaultServices[index % defaultServices.length]['image']!);
                    } else {
                      final item = defaultServices[index];
                      title = item['title']!;
                      rating = item['rating']!;
                      duration = item['duration']!;
                      price = item['price']!;
                      oldPrice = item['oldPrice'];
                      img = item['image']!;
                    }

                    return GestureDetector(
                      onTap: () {
                        if (liveProduct != null) {
                          FluxNavigate.pushNamed(
                            RouteList.productDetail,
                            arguments: liveProduct,
                            context: context,
                          );
                        } else {
                          _openBooking(null);
                        }
                      },
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
                                  child: Image.network(
                                    img,
                                    height: 100,
                                    width: 170,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
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
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              price,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFFF6B00),
                                              ),
                                            ),
                                            if (oldPrice != null) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                oldPrice,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.grey,
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        ElevatedButton(
                                          onPressed: () => _openBooking(liveProduct),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFF6B00),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Text('Add', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
            onPressed: () => _navigateToSearch(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF6B00)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final defaultProviders = [
      {
        'name': "Sunita's Cleaning",
        'rating': '4.9 (128 reviews)',
        'price': 'Starts ₹599',
        'avatar':
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&q=80',
      },
      {
        'name': 'Rajesh Electrician',
        'rating': '4.8 (124 reviews)',
        'price': 'Starts ₹150',
        'avatar':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
      },
      {
        'name': 'Kumar Carpentry',
        'rating': '4.7 (85 reviews)',
        'price': 'Starts ₹299',
        'avatar':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
      },
      {
        'name': 'TriCity Plumber',
        'rating': '4.9 (110 reviews)',
        'price': 'Starts ₹199',
        'avatar':
            'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=200&q=80',
      },
      {
        'name': 'Home Care Nursing',
        'rating': '4.9 (64 reviews)',
        'price': 'Starts ₹799',
        'avatar':
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&q=80',
      },
    ];

    final hasLive = _popularProviders.isNotEmpty;
    final count = hasLive ? _popularProviders.length : defaultProviders.length;

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
              onTap: () => _navigateToSearch(),
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
                      name = liveProvider.name ?? 'Verified Pro';
                      rating = '${liveProvider.averageRating ?? 4.9} (${liveProvider.ratingCount ?? 45} reviews)';
                      price = liveProvider.price?.isNotEmpty ?? false
                          ? 'Starts ₹${liveProvider.price}'
                          : 'Starts ₹199';
                      avatar = liveProvider.imageFeature?.isNotEmpty ?? false
                          ? liveProvider.imageFeature!
                          : defaultProviders[index % defaultProviders.length]['avatar']!;
                    } else {
                      final item = defaultProviders[index];
                      name = item['name']!;
                      rating = item['rating']!;
                      price = item['price']!;
                      avatar = item['avatar']!;
                    }

                    return Container(
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
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    avatar,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey),
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
                                            'Verified Pro',
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
                              ElevatedButton(
                                onPressed: () => _openBooking(liveProvider),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B00),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text('Book Pro', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
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
            onPressed: () => _navigateToSearch(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6B4EA4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  // 7. DEDICATED SLIDERS FOR EACH TRADE
  // ==========================================
  Widget _buildTradeSliders(BuildContext context, ThemeData theme) {
    final trades = [
      {
        'category': 'Electrician',
        'title': 'Electrician Services',
        'icon': Icons.bolt,
        'iconBg': const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFFD97706),
        'services': [
          {'title': 'Fan Repair', 'duration': '30 mins', 'price': '₹149'},
          {'title': 'Switch Replacement', 'duration': '20 mins', 'price': '₹99'},
          {'title': 'MCB / Fuse Box Repair', 'duration': '45 mins', 'price': '₹249'},
          {'title': 'Chandelier Light Install', 'duration': '40 mins', 'price': '₹199'},
          {'title': 'Inverter Setup', 'duration': '60 mins', 'price': '₹499'},
          {'title': 'Geyser Installation', 'duration': '45 mins', 'price': '₹399'},
          {'title': 'Full House Rewiring', 'duration': 'Full Day', 'price': '₹2,499'},
        ]
      },
      {
        'category': 'Plumber',
        'title': 'Plumber Services',
        'icon': Icons.plumbing,
        'iconBg': const Color(0xFFE0F2FE),
        'iconColor': const Color(0xFF0284C7),
        'services': [
          {'title': 'Tap & Mixer Repair', 'duration': '30 mins', 'price': '₹129'},
          {'title': 'Drain Clearing', 'duration': '45 mins', 'price': '₹299'},
          {'title': 'Toilet Seat Install', 'duration': '60 mins', 'price': '₹349'},
          {'title': 'Water Tank Cleaning', 'duration': '90 mins', 'price': '₹799'},
          {'title': 'Pipe Leakage Fix', 'duration': '40 mins', 'price': '₹199'},
          {'title': 'Shower Fitting', 'duration': '35 mins', 'price': '₹249'},
        ]
      },
      {
        'category': 'Carpenter',
        'title': 'Carpenter Services',
        'icon': Icons.handyman,
        'iconBg': const Color(0xFFFEF9C3),
        'iconColor': const Color(0xFF854D0E),
        'services': [
          {'title': 'Door Lock Repair', 'duration': '30 mins', 'price': '₹199'},
          {'title': 'Furniture Assembly', 'duration': '90 mins', 'price': '₹499'},
          {'title': 'Cupboard Hinge Fix', 'duration': '25 mins', 'price': '₹149'},
          {'title': 'Wooden Partition', 'duration': '2 hrs', 'price': '₹599'},
          {'title': 'Custom Shelves', 'duration': '2.5 hrs', 'price': '₹699'},
          {'title': 'Bed Repair', 'duration': '60 mins', 'price': '₹399'},
        ]
      },
      {
        'category': 'Cleaner',
        'title': 'Cleaner Services',
        'icon': Icons.cleaning_services,
        'iconBg': const Color(0xFFFFEDD5),
        'iconColor': const Color(0xFFFF6B00),
        'services': [
          {'title': 'Balcony Deep Clean', 'duration': '45 mins', 'price': '₹299'},
          {'title': 'Sofa & Carpet Shampoo', 'duration': '90 mins', 'price': '₹699'},
          {'title': 'Kitchen Exhaust Clean', 'duration': '60 mins', 'price': '₹399'},
          {'title': 'Floor Scrubbing', 'duration': '2 hrs', 'price': '₹499'},
          {'title': 'Window Glass Polish', 'duration': '40 mins', 'price': '₹199'},
          {'title': 'Sanitization Treatment', 'duration': '60 mins', 'price': '₹349'},
        ]
      },
      {
        'category': 'Maid',
        'title': 'Maid Services',
        'icon': Icons.dry_cleaning,
        'iconBg': const Color(0xFFFFE4E6),
        'iconColor': const Color(0xFFE11D48),
        'services': [
          {'title': 'Daily House Chores', 'duration': 'Per Visit', 'price': '₹299/day'},
          {'title': 'Cooking & Prep', 'duration': 'Per Meal', 'price': '₹350/meal'},
          {'title': 'Baby Care Assistance', 'duration': '4-8 hrs', 'price': '₹500/day'},
          {'title': 'Elder Companionship', 'duration': 'Full Day', 'price': '₹600/day'},
          {'title': 'Dishwashing Service', 'duration': 'Per Session', 'price': '₹150/day'},
          {'title': 'Ironing & Laundry', 'duration': '60 mins', 'price': '₹200'},
        ]
      },
      {
        'category': 'Gardener',
        'title': 'Gardener Services',
        'icon': Icons.yard,
        'iconBg': const Color(0xFFD1FAE5),
        'iconColor': const Color(0xFF047857),
        'services': [
          {'title': 'Lawn Mowing & Weeding', 'duration': '60 mins', 'price': '₹399'},
          {'title': 'Plant Pruning', 'duration': '45 mins', 'price': '₹299'},
          {'title': 'Potting & Soil Prep', 'duration': '30 mins', 'price': '₹199'},
          {'title': 'Pest Spray & Fertilize', 'duration': '45 mins', 'price': '₹249'},
          {'title': 'Balcony Garden Setup', 'duration': '3 hrs', 'price': '₹799'},
          {'title': 'Hedge Cutting', 'duration': '50 mins', 'price': '₹349'},
        ]
      },
      {
        'category': 'Care Giver',
        'title': 'Care Services',
        'icon': Icons.volunteer_activism,
        'iconBg': const Color(0xFFCCFBF1),
        'iconColor': const Color(0xFF0F766E),
        'services': [
          {'title': 'Post-Operative Care', 'duration': '12 hrs shift', 'price': '₹899/day'},
          {'title': 'Elderly Nursing Care', 'duration': '24 hrs shift', 'price': '₹999/day'},
          {'title': 'Physiotherapy at Home', 'duration': '45 mins', 'price': '₹650'},
          {'title': 'Vital Check & Dressing', 'duration': '30 mins', 'price': '₹299'},
          {'title': 'Medication Mgmt', 'duration': 'Weekly', 'price': '₹399'},
        ]
      },
      {
        'category': 'Appliance',
        'title': 'Appliance Repair Services',
        'icon': Icons.build,
        'iconBg': const Color(0xFFDBEAFE),
        'iconColor': const Color(0xFF1D4ED8),
        'services': [
          {'title': 'Washing Machine Fix', 'duration': '60 mins', 'price': '₹299'},
          {'title': 'Fridge Gas Refill', 'duration': '90 mins', 'price': '₹599'},
          {'title': 'Microwave Oven Fix', 'duration': '45 mins', 'price': '₹349'},
          {'title': 'RO Water Purifier', 'duration': '45 mins', 'price': '₹299'},
          {'title': 'Chimney Deep Service', 'duration': '60 mins', 'price': '₹499'},
          {'title': 'TV Wall Mounting', 'duration': '30 mins', 'price': '₹249'},
        ]
      },
    ];

    return Column(
      children: trades.map((trade) {
        final tradeCat = trade['category'] as String;
        final tradeTitle = trade['title'] as String;
        final tradeIcon = trade['icon'] as IconData;
        final iconBg = trade['iconBg'] as Color;
        final iconColor = trade['iconColor'] as Color;
        final services = trade['services'] as List<Map<String, String>>;

        return Padding(
          padding: const EdgeInsets.only(bottom: 22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(tradeIcon, color: iconColor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tradeTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B1C1C),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _navigateToCategory(tradeCat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EDED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: const [
                          Text(
                            'Explore',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5A4136),
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 13, color: Color(0xFF5A4136)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Horizontal Scrollable Cards
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final item = services[idx];
                    return Container(
                      width: 130,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE4E2E1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['duration']!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF5A4136),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item['title']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B1C1C),
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['price']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF6B00),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _openBooking(null),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B00),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
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
      }).toList(),
    );
  }

  // ==========================================
  // 8. PROMOTIONAL OFFERS & GUARANTEES
  // ==========================================
  Widget _buildPromotionalOffers(BuildContext context, ThemeData theme) {
    final offers = [
      {
        'badge': 'FESTIVAL SPECIAL',
        'title': 'Flat ₹150 OFF on Cleaning',
        'desc': 'Use code ZIPFEST on checkout',
        'cta': 'Claim Offer',
        'gradient': const [Color(0xFFEA580C), Color(0xFFF59E0B)],
        'icon': Icons.savings,
      },
      {
        'badge': 'LIMITED SLOT',
        'title': 'Free AC Inspection Visit',
        'desc': 'Zero diagnosis charges on first service',
        'cta': 'Book Check',
        'gradient': const [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
        'icon': Icons.ac_unit,
      },
      {
        'badge': 'TRUST & QUALITY',
        'title': '100% Satisfaction Guarantee',
        'desc': 'Verified Pros or free rework within 7 days',
        'cta': 'Learn More',
        'gradient': const [Color(0xFF047857), Color(0xFF0D9488)],
        'icon': Icons.verified_user,
      },
      {
        'badge': 'REFERRAL PROGRAM',
        'title': 'Earn ₹200 ZipCredits',
        'desc': 'Invite neighbors in Chandigarh & Mohali',
        'cta': 'Invite Now',
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
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final offer = offers[idx];
              return Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(height: 4),
                            Text(
                              offer['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              offer['desc'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () => _navigateToSearch(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1B1C1C),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text(
                            offer['cta'] as String,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 9. SERVICE PROVIDER RECRUITMENT BANNER
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
              ElevatedButton.icon(
                onPressed: () async {
                  await Tools.launchURL('https://zipbiz.in');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Text(
                  'Start Now',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                label: const Icon(Icons.arrow_forward, size: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
