import 'package:flutter/material.dart';
import '../../models/entities/product.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../screens/booking/zipbiz_booking_flow_screen.dart';

class ZipBizCartItem {
  final String id;
  final String title;
  final double price;
  final String duration;
  final String? category;
  final String? providerName;
  final int? listingId;
  final Product? product;

  ZipBizCartItem({
    required this.id,
    required this.title,
    required this.price,
    this.duration = '60 mins',
    this.category,
    this.providerName,
    this.listingId,
    this.product,
  });
}

class ZipBizCartManager {
  static final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);
  static final List<ZipBizCartItem> _items = [];

  static List<ZipBizCartItem> get items => List.unmodifiable(_items);

  static void addItem(ZipBizCartItem item, BuildContext context) {
    // Avoid duplicate service additions of same item
    final exists = _items.any((i) => i.id == item.id);
    if (!exists) {
      _items.add(item);
      cartCountNotifier.value = _items.length;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${item.title} added to cart!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: ZipBizColors.statusOpen,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () => showCartModal(context),
        ),
      ),
    );
  }

  static void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    cartCountNotifier.value = _items.length;
  }

  static void clearCart() {
    _items.clear();
    cartCountNotifier.value = 0;
  }

  static double get totalPrice {
    return _items.fold(0.0, (sum, i) => sum + i.price);
  }

  static void showCartModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, color: ZipBizColors.primaryContainer, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Selected Services (${_items.length})',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.remove_shopping_cart_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text('Your cart is empty', style: ZipBizTypography.bodyMedium),
                              const SizedBox(height: 4),
                              const Text('Choose any home service from the listings to book.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 12),
                          itemBuilder: (context, idx) {
                            final item = _items[idx];
                            return Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEDD5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.home_repair_service, color: Color(0xFFFF6B00), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${item.providerName ?? "ZipBiz Pro"} • ${item.duration}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${item.price.toInt()}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFFF6B00)),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () {
                                    removeItem(item.id);
                                    setMState(() {});
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text(
                              '₹${totalPrice.toInt()}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFFF6B00)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            final first = _items.first;
                            if (first.product != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ZipBizBookingFlowScreen(
                                    product: first.product!,
                                    totalPrice: totalPrice,
                                    selectedPackages: _items.map((i) => {
                                      'name': i.title,
                                      'price': i.price,
                                    }).toList(),
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a business to finalize booking.')),
                              );
                            }
                          },
                          child: const Center(
                            child: Text(
                              'Proceed to Book Appointment',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
