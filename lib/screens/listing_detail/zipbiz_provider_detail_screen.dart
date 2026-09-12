import '../../core/state/zipbiz_bookmark_manager.dart';
import '../services/zipbiz_services_directory_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/state/zipbiz_cart_manager.dart';
import '../../common/config.dart';
import '../../common/constants.dart';
import '../../core/api/zipbiz_api_service.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../models/entities/product.dart';
import '../../models/entities/menu_price.dart';
import '../../models/entities/menu.dart';
import '../../models/user_model.dart';
import '../../routes/flux_navigate.dart';
import '../../widgets/common/zipbiz_badge.dart';
import '../../widgets/common/zipbiz_button.dart';
import '../../widgets/common/zipbiz_card.dart';
import '../../widgets/common/zipbiz_header.dart';
import '../booking/zipbiz_booking_flow_screen.dart';

class ZipBizProviderDetailScreen extends StatefulWidget {
  final Product product;

  const ZipBizProviderDetailScreen({super.key, required this.product});

  @override
  State<ZipBizProviderDetailScreen> createState() =>
      _ZipBizProviderDetailScreenState();
}

class _ZipBizProviderDetailScreenState
    extends State<ZipBizProviderDetailScreen> {
  final Set<String> _selectedPackageNames = {};
  double _totalSelectedPrice = 0;
  bool _hasConfirmedBooking = false;
  bool _isCheckingBooking = true;

  late List<Map<String, dynamic>> _packages;

  @override
  void initState() {
    super.initState();
    _initPackages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBookingStatus();
    });
  }

  void _checkBookingStatus() async {
    final userModel = Provider.of<UserModel>(context, listen: false);
    final user = userModel.user;
    if (user != null && user.id != null) {
      final listingId = int.tryParse(widget.product.id ?? '0');
      final hasConfirmed = await ZipBizApiService().hasConfirmedBooking(
        user: user,
        listingId: listingId,
      );
      if (mounted) {
        setState(() {
          _hasConfirmedBooking = hasConfirmed;
          _isCheckingBooking = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasConfirmedBooking = false;
          _isCheckingBooking = false;
        });
      }
    }
  }

  String? get _heroImage {
    final p = widget.product;
    final defaultImg = kProductCard.defaultImage;
    if (p.imageFeature != null && p.imageFeature!.isNotEmpty && p.imageFeature != kDefaultImage && p.imageFeature != defaultImg) {
      return p.imageFeature;
    }
    if (p.images.isNotEmpty) {
      final valid = p.images.firstWhere((img) => img.isNotEmpty && img != kDefaultImage && img != defaultImg, orElse: () => '');
      if (valid.isNotEmpty) return valid;
    }
    return p.imageFeature;
  }

  String? _getMeta(String key) {
    try {
      for (var item in widget.product.metaData) {
        if (item['key'] == key) {
          final val = item['value']?.toString();
          if (val != null && val.trim().isNotEmpty) {
            return val.trim();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  List<Map<String, String>> _getFaqs() {
    final faqs = <Map<String, String>>[];
    try {
      for (var item in widget.product.metaData) {
        final k = item['key']?.toString();
        if (k == '_faq' || k == 'faq' || k == '_listing_faq' || k == 'listing_faq') {
          var val = item['value'];
          if (val is String && val.trim().startsWith('[') && val.trim().endsWith(']')) {
            try {
              val = jsonDecode(val);
            } catch (_) {}
          }
          if (val is List) {
            for (var f in val) {
              if (f is Map) {
                final q = (f['question']?.toString() ?? f['title']?.toString() ?? '')
                    .replaceAll('&#8217;', "'")
                    .replaceAll('&amp;', '&');
                final a = (f['answer']?.toString() ?? f['content']?.toString() ?? '')
                    .replaceAll('&#8217;', "'")
                    .replaceAll('&amp;', '&');
                if (q.isNotEmpty) {
                  faqs.add({'question': q, 'answer': a});
                }
              }
            }
          }
        }
      }
    } catch (_) {}
    return faqs;
  }

  List<Map<String, dynamic>> _getCoupons() {
    bool showCoupons = true;
    for (var item in widget.product.metaData) {
      if (item['key'] == 'show_coupons' || item['key'] == '_show_coupons') {
        final v = item['value'];
        if (v == false || v == 'off' || v == '0' || v == 0) {
          showCoupons = false;
        }
      }
    }
    if (!showCoupons) return [];

    final coupons = <Map<String, dynamic>>[];
    try {
      for (var item in widget.product.metaData) {
        if (item['key'] == 'coupons' || item['key'] == '_coupons') {
          var val = item['value'];
          if (val is String && val.trim().startsWith('[') && val.trim().endsWith(']')) {
            try {
              val = jsonDecode(val);
            } catch (_) {}
          }
          if (val is List) {
            for (var c in val) {
              if (c is Map) {
                coupons.add(Map<String, dynamic>.from(c));
              }
            }
          }
        }
      }
    } catch (_) {}
    return coupons;
  }

  void _initPackages() {
    _packages = [];
    final menuItems = widget.product.listingMenu;
    if (menuItems != null && menuItems.isNotEmpty) {
      for (var group in menuItems) {
        if (group is ListingMenu) {
          for (var elem in group.menu) {
            final name = elem.name ?? 'Service Package';
            final price = double.tryParse(elem.price ?? '499') ?? 499.0;
            _packages.add({
              'name': name,
              'price': price,
              'description': elem.description ?? 'Complete expert service with verified tools',
              'duration': '60 mins',
            });
          }
        } else if (group is Map) {
          final elements = group['menu_elements'] ?? group['menu'];
          if (elements is List) {
            for (var elem in elements) {
              final name = elem is Map ? (elem['name']?.toString() ?? 'Service Package') : 'Service Package';
              final price = elem is Map ? (double.tryParse('${elem['price']}') ?? 499.0) : 499.0;
              _packages.add({
                'name': name,
                'price': price,
                'description': elem is Map ? (elem['description']?.toString() ?? 'Complete expert service with verified tools') : 'Complete expert service with verified tools',
                'duration': '60 mins',
              });
            }
          }
        }
      }
    }

    if (_packages.isEmpty) {
      final basePrice = double.tryParse(widget.product.price ?? widget.product.regularPrice ?? '499') ?? 499.0;
      _packages = [
        {
          'name': '${widget.product.name} - Standard Package',
          'price': basePrice,
          'description': 'Comprehensive home service with standard checklist and guaranteed satisfaction',
          'duration': '45 mins',
        },
        {
          'name': 'Deep Care & Sanitization Add-on',
          'price': 299.0,
          'description': 'High-grade chemical treatment and hygienic final touch',
          'duration': '30 mins',
        },
      ];
    }

    // Default select first package
    if (_packages.isNotEmpty) {
      final first = _packages.first;
      _selectedPackageNames.add(first['name']);
      _totalSelectedPrice = first['price'];
    }
  }

  void _togglePackage(String name, double price) {
    setState(() {
      if (_selectedPackageNames.contains(name)) {
        if (_selectedPackageNames.length > 1) {
          _selectedPackageNames.remove(name);
          _totalSelectedPrice -= price;
        }
      } else {
        _selectedPackageNames.add(name);
        _totalSelectedPrice += price;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    bool isAccepting = ZipBizBookingAvailability.isAcceptingNotifier.value;
    for (final m in p.metaData) {
      final k = (m['key'] ?? '').toString();
      final v = m['value'];
      if (k == '_booking_status' || k == 'booking_status') {
        if (v == false || v == 'off' || v == '0' || v == 0) isAccepting = false;
      }
      if (k == '_is_offline' || k == 'is_offline' || k == '_pause_bookings') {
        if (v == true || v == 'on' || v == '1' || v == 1) isAccepting = false;
      }
    }
    double minPrice = double.infinity;
    for (final pkg in _packages) {
      final pr = double.tryParse(pkg['price']?.toString() ?? '');
      if (pr != null && pr > 0 && pr < minPrice) {
        minPrice = pr;
      }
    }
    if (minPrice == double.infinity) {
      minPrice = double.tryParse(p.price ?? p.regularPrice ?? '499') ?? 499.0;
    }
    final startsAt = '₹${minPrice.toStringAsFixed(0)}';
    final isVerified = p.verified == true || p.isFeatured == true || p.featured == 'on' || p.featured == '1';

    return Scaffold(
      backgroundColor: ZipBizColors.surface,
      appBar: const ZipBizTopHeader(showBackButton: true),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumbs
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      Text('Services', style: ZipBizTypography.labelMedium.copyWith(color: ZipBizColors.primaryContainer)),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      Text('Home Care', style: ZipBizTypography.labelMedium),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      Expanded(
                        child: Text(
                          p.name ?? 'Provider',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ZipBizTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, color: ZipBizColors.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),

                if (!isAccepting)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pause_circle_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Currently Paused / Offline: This business is not taking new bookings at the moment.',
                            style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Hero Image & Gallery
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Container(
                          height: 220,
                          width: double.infinity,
                          color: ZipBizColors.surfaceContainer,
                          child: (_heroImage != null && _heroImage!.isNotEmpty)
                              ? Image.network(
                                  _heroImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.home_repair_service,
                                      size: 60,
                                      color: Colors.grey),
                                )
                              : const Icon(Icons.home_repair_service,
                                  size: 60, color: Colors.grey),
                        ),
                        // Gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                              ),
                            ),
                          ),
                        ),
                        // Status Pill
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ZipBizColors.statusOpen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: Colors.white),
                                SizedBox(width: 5),
                                Text('Open Now • 9 AM - 6 PM', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        // Verified Badge
                        if (isVerified)
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified, size: 16, color: ZipBizColors.primaryContainer),
                                  SizedBox(width: 5),
                                  Text('Verified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ZipBizColors.onSurface)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Provider Summary Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ZipBizCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.name ?? 'ZipBiz Service Provider',
                                          style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20),
                                        ),
                                      ),
                                      const Icon(Icons.check_circle, size: 20, color: ZipBizColors.tertiary),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: ZipBizColors.primaryContainer),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          p.location ?? 'Chandigarh, Mohali, Panchkula & Zirakpur',
                                          style: ZipBizTypography.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Starts at', style: ZipBizTypography.labelSmall),
                                Text(startsAt, style: ZipBizTypography.headlineSmall.copyWith(color: ZipBizColors.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Tags
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: const [
                            ZipBizBadge(text: 'Home Services', variant: ZipBizBadgeVariant.category),
                            ZipBizBadge(text: 'Verified Tech', variant: ZipBizBadgeVariant.category),
                            ZipBizBadge(text: 'Top Rated Pro', variant: ZipBizBadgeVariant.topRated),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Rating row
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ZipBizColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: ZipBizColors.statusOpen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const Text('5.0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: List.generate(
                                      5,
                                      (index) => const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Based on ${p.totalReview ?? 6} verified reviews', style: ZipBizTypography.labelSmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Service Packages Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Service Packages', style: ZipBizTypography.headlineSmall),
                      Text('Select to book', style: ZipBizTypography.labelMedium),
                    ],
                  ),
                ),

                // Packages List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _packages.map((pkg) {
                      final name = pkg['name'] as String;
                      final price = pkg['price'] as double;
                      final isSelected = _selectedPackageNames.contains(name);

                      return ZipBizCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: isSelected ? ZipBizColors.primaryFixed.withOpacity(0.2) : ZipBizColors.surfaceContainerLowest,
                        border: Border.all(
                          color: isSelected ? ZipBizColors.primaryContainer : ZipBizColors.surfaceContainer,
                          width: isSelected ? 1.5 : 1,
                        ),
                        onTap: () => _togglePackage(name, price),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isSelected,
                              activeColor: ZipBizColors.primaryContainer,
                              onChanged: (_) => _togglePackage(name, price),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: ZipBizTypography.labelLarge.copyWith(fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(pkg['description'], style: ZipBizTypography.bodySmall),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(pkg['duration'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('₹${price.toStringAsFixed(0)}', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 17, color: ZipBizColors.primary)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // About Description
                if (p.description != null && p.description!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('About This Service', style: ZipBizTypography.headlineSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ZipBizCard(
                      child: Text(
                        p.description!.replaceAll(RegExp(r'<[^>]*>'), ''),
                        style: ZipBizTypography.bodyMedium,
                      ),
                    ),
                  ),
                ],

                // Additional Fees & Details (Visiting fee / Inspection fee / Custom fee)
                Builder(
                  builder: (context) {
                    final visitingFee = _getMeta('_visiting_fee') ?? _getMeta('visiting_fee');
                    final additionalFeeLabel = _getMeta('_additional_fee_label');
                    final additionalFeeAmount = _getMeta('_additional_fee_amount');
                    final inspectionFee = _getMeta('_inspection_fee');
                    final hasAdditionalFees = inspectionFee != null || (additionalFeeLabel != null && additionalFeeAmount != null);

                    if (!hasAdditionalFees) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text('Additional Fees & Details', style: ZipBizTypography.headlineSmall),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ZipBizCard(
                            child: Column(
                              children: [

                                if (inspectionFee != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.search, size: 18, color: ZipBizColors.primaryContainer),
                                          SizedBox(width: 8),
                                          Text('Inspection Fee', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        ],
                                      ),
                                      Text('₹$inspectionFee', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ZipBizColors.primary)),
                                    ],
                                  ),
                                if (additionalFeeLabel != null && additionalFeeAmount != null) ...[
                                  if (inspectionFee != null)
                                    const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.info_outline, size: 18, color: ZipBizColors.primaryContainer),
                                          const SizedBox(width: 8),
                                          Text(additionalFeeLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        ],
                                      ),
                                      Text('₹$additionalFeeAmount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ZipBizColors.primary)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Available Coupons
                Builder(
                  builder: (context) {
                    final coupons = _getCoupons();
                    if (coupons.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              const Icon(Icons.local_offer_outlined, size: 20, color: Colors.purple),
                              const SizedBox(width: 8),
                              Text('Available Offers & Coupons', style: ZipBizTypography.headlineSmall),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 95,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: coupons.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, idx) {
                              final c = coupons[idx];
                              final code = c['code']?.toString() ?? 'COUPON';
                              final amount = c['amount']?.toString() ?? c['discount']?.toString() ?? '10';
                              final type = c['discount_type']?.toString() ?? c['type']?.toString() ?? 'percent';
                              final discountText = type == 'percent' ? '$amount% OFF' : '₹$amount OFF';
                              final desc = c['description']?.toString() ?? 'On all services';

                              return Container(
                                width: 220,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.purple.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(discountText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple)),
                                          const SizedBox(height: 2),
                                          Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: code));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Coupon code "$code" copied!'),
                                            backgroundColor: Colors.purple,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.purple.shade400),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purple)),
                                            const Text('TAP TO COPY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // FAQs (Dynamic from API; hidden if empty)
                Builder(
                  builder: (context) {
                    final faqs = _getFaqs();
                    if (faqs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text('Frequently Asked Questions', style: ZipBizTypography.headlineSmall),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: faqs.map((faq) {
                              return ZipBizCard(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Q: ${faq['question']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'A: ${faq['answer']}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Sticky Bottom Booking & Chat Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFF0EDED), width: 1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: Row(
                children: [
                  // Price column
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_selectedPackageNames.length} Selected', style: ZipBizTypography.labelSmall),
                      Text('₹${_totalSelectedPrice.toStringAsFixed(0)}', style: ZipBizTypography.headlineMedium.copyWith(color: ZipBizColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Book Service Button
                  Expanded(
                    child: ZipBizButton(
                      text: isAccepting ? 'Book Service' : 'Currently Offline',
                      icon: isAccepting ? Icons.calendar_month : Icons.block,
                      height: 42,
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      backgroundColor: isAccepting ? ZipBizColors.primaryContainer : Colors.grey.shade400,
                      onPressed: isAccepting ? () {
                        final selectedItems = _packages
                            .where((pkg) => _selectedPackageNames.contains(pkg['name']))
                            .toList();

                        ZipBizCartManager().syncFromSelectedServices(p, selectedItems);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ZipBizBookingFlowScreen(
                              product: p,
                              selectedPackages: selectedItems,
                              totalPrice: _totalSelectedPrice,
                            ),
                          ),
                        );
                      } : null,
                    ),
                  ),
                ],
              ),
            ),

          ),
        ],
      ),
    );
  }
}
