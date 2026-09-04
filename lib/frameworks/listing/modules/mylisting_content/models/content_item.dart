import 'package:collection/collection.dart';

enum ContentItemType {
  gallery,
  table,
  text,
  accordion,
  categories,
  author,
  tags,
  video,
  location,
  ;

  static ContentItemType? initFrom(String? value) {
    return ContentItemType.values.firstWhereOrNull(
        (ContentItemType e) => e.name.toLowerCase() == value?.toLowerCase());
  }
}

class ContentItem {
  const ContentItem({
    this.title,
    this.icon,
    this.type,
  });

  final String? title;
  final String? icon;
  final ContentItemType? type;
}
