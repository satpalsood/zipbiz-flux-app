import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../core/state/zipbiz_bookmark_manager.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../widgets/common/zipbiz_card.dart';
import '../../widgets/common/zipbiz_button.dart';
import 'package:flux_ui/flux_ui.dart';
import '../../common/constants.dart';
import '../../menu/maintab_delegate.dart';
import '../../routes/flux_navigate.dart';
import '../../services/index.dart';

class ZipBizBookmarksScreen extends StatefulWidget {
  const ZipBizBookmarksScreen({super.key});

  @override
  State<ZipBizBookmarksScreen> createState() => _ZipBizBookmarksScreenState();
}

class _ZipBizBookmarksScreenState extends State<ZipBizBookmarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserModel>(context, listen: false).user;
      ZipBizBookmarkManager.loadBookmarks(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('My Bookmarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B1C1C),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ValueListenableBuilder<List<dynamic>>(
        valueListenable: ZipBizBookmarkManager.bookmarkedItemsNotifier,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border, size: 40, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    Text('No Bookmarked Businesses Yet', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 18)),
                    const SizedBox(height: 6),
                    Text(
                      'Tap the heart icon on any business or service to save it for quick booking later.',
                      textAlign: TextAlign.center,
                      style: ZipBizTypography.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    ZipBizButton(
                      text: 'Explore Businesses',
                      onPressed: () {
                        Navigator.pop(context);
                        MainTabControlDelegate.getInstance().changeTab(RouteList.category);
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final b = items[index];
              final id = b['id']?.toString() ?? '';
              final title = b['title'] ?? 'Business Partner';
              final img = b['featured_image'] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500&q=80';
              final rating = (b['rating'] != null) ? b['rating'].toString() : '4.9';
              final price = b['price']?.toString() ?? '399';
              final address = b['address'] ?? 'Mohali / Chandigarh';

              return ZipBizCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FluxImage(
                        imageUrl: img,
                        width: 85,
                        height: 85,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                                onPressed: () {
                                  ZipBizBookmarkManager.toggleBookmark(context, user, b);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 3),
                              Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 8),
                              const Icon(Icons.location_on, color: Colors.grey, size: 13),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Starts at ₹$price',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B00), fontSize: 13),
                              ),
                              SizedBox(
                                height: 28,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B00),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: () async {
                                    final p = await Services().api.getProduct(id);
                                    if (p != null && context.mounted) {
                                      FluxNavigate.pushNamed(RouteList.productDetail, arguments: p, context: context);
                                    }
                                  },
                                  child: const Text('Book Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
          );
        },
      ),
    );
  }
}
