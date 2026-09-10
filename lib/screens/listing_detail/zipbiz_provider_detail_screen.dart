import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/constants.dart';
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
import '../../vendor/messages/zipbiz_chat_detail_screen.dart';

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

  late List<Map<String, dynamic>> _packages;

  @override
  void initState() {
    super.initState();
    _initPackages();
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
    final startsAt = (p.price != null && p.price!.isNotEmpty) ? '₹${p.price}' : '₹499';

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
                          child: (p.imageFeature != null && p.imageFeature!.isNotEmpty)
                              ? Image.network(p.imageFeature!, fit: BoxFit.cover)
                              : const Icon(Icons.home_repair_service, size: 60, color: Colors.grey),
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
                        // Tricity Verified Badge
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
                                Text('Tricity Verified Partner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ZipBizColors.onSurface)),
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

                // ZipBiz Transparency & Guarantees
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('ZipBiz Guarantee & Fees', style: ZipBizTypography.headlineSmall),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ZipBizCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.verified_user, color: Colors.green, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Doorstep Diagnosis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Standard inspection fee of ₹149 applicable if no further repairs needed.', style: ZipBizTypography.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.security, color: Colors.blue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('30-Day Service Guarantee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Free rework or full refund if issues persist after service completion.', style: ZipBizTypography.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // FAQs
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Frequently Asked Questions', style: ZipBizTypography.headlineSmall),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: const [
                      ZipBizCard(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Q: How quickly will the pro arrive?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(height: 4),
                            Text('A: The technician will arrive precisely during your selected time slot. You can track their status and message them directly in the app.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      ZipBizCard(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Q: Can I pay after the service is completed?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(height: 4),
                            Text('A: Yes! You can choose Pay on Service (Cash/UPI upon work completion) or pay securely in advance online.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                  const Spacer(),
                  // Message Pro Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ZipBizColors.primaryContainer),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16, color: ZipBizColors.primaryContainer),
                    label: const Text('Chat', style: TextStyle(color: ZipBizColors.primaryContainer, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final vendorId = int.tryParse(p.id ?? '1') ?? 1;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ZipBizChatDetailScreen(
                            recipientId: vendorId,
                            recipientName: p.name ?? 'Vendor',
                            listingTitle: p.name,
                            listingId: int.tryParse(p.id ?? '0'),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Book Service Button
                  ZipBizButton(
                    text: 'Book Service',
                    icon: Icons.calendar_month,
                    onPressed: () {
                      final selectedItems = _packages
                          .where((pkg) => _selectedPackageNames.contains(pkg['name']))
                          .toList();

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
                    },
                    height: 44,
                    borderRadius: 10,
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
