import 'package:flutter/material.dart';
import '../../models/entities/user.dart';
import '../../models/entities/product.dart';
import '../../core/api/zipbiz_api_service.dart';
import '../../core/theme/zipbiz_colors.dart';

class ZipBizBookmarkManager {
  static final ValueNotifier<Set<String>> bookmarkedIdsNotifier = ValueNotifier<Set<String>>({});
  static final ValueNotifier<List<dynamic>> bookmarkedItemsNotifier = ValueNotifier<List<dynamic>>([]);
  static bool _isLoading = false;

  static bool isBookmarked(String id) {
    return bookmarkedIdsNotifier.value.contains(id);
  }

  static Future<void> loadBookmarks(User? user) async {
    if (user == null || _isLoading) return;
    _isLoading = true;
    try {
      final res = await ZipBizApiService().getUserBookmarks(user);
      final rawList = (res['bookmarks'] as List?) ?? [];
      final idSet = rawList.map((e) => e.toString()).toSet();
      bookmarkedIdsNotifier.value = idSet;
      bookmarkedItemsNotifier.value = (res['items'] as List?) ?? [];
    } catch (_) {
      // ignore
    } finally {
      _isLoading = false;
    }
  }

  static Future<bool> toggleBookmark(BuildContext context, User? user, dynamic item) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save businesses to bookmarks!')),
      );
      return false;
    }

    String idStr = '';
    String titleStr = 'Business';
    if (item is Product) {
      idStr = item.id?.toString() ?? '';
      titleStr = item.name ?? 'Business';
    } else if (item is Map) {
      idStr = item['id']?.toString() ?? item['listing_id']?.toString() ?? '';
      titleStr = item['title']?.toString() ?? item['name']?.toString() ?? 'Business';
    }

    final idInt = int.tryParse(idStr) ?? 0;
    if (idInt <= 0) return false;

    // Optimistic toggle
    final currentSet = Set<String>.from(bookmarkedIdsNotifier.value);
    final isCurrentlyBookmarked = currentSet.contains(idStr);

    if (isCurrentlyBookmarked) {
      currentSet.remove(idStr);
      bookmarkedItemsNotifier.value = List.from(bookmarkedItemsNotifier.value)
        ..removeWhere((b) => b['id']?.toString() == idStr);
    } else {
      currentSet.add(idStr);
      if (item is Product) {
        bookmarkedItemsNotifier.value = List.from(bookmarkedItemsNotifier.value)
          ..add({
            'id': item.id,
            'title': item.name,
            'featured_image': item.imageFeature,
            'rating': item.averageRating ?? 4.9,
            'price': item.price ?? item.regularPrice ?? '399',
            'tagline': item.tagLine ?? '',
            'address': item.location ?? 'Mohali / Chandigarh',
          });
      } else if (item is Map) {
        bookmarkedItemsNotifier.value = List.from(bookmarkedItemsNotifier.value)..add(item);
      }
    }
    bookmarkedIdsNotifier.value = currentSet;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCurrentlyBookmarked ? 'Removed from bookmarks' : 'Added to bookmarks: $titleStr',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isCurrentlyBookmarked ? Colors.grey.shade700 : ZipBizColors.statusOpen,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final res = await ZipBizApiService().toggleUserBookmark(user: user, listingId: idInt);
      if (res['bookmarks'] is List) {
        final syncedList = (res['bookmarks'] as List).map((e) => e.toString()).toSet();
        bookmarkedIdsNotifier.value = syncedList;
      }
      return !isCurrentlyBookmarked;
    } catch (e) {
      // Revert if API fails
      loadBookmarks(user);
      return isCurrentlyBookmarked;
    }
  }
}
