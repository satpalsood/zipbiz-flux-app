import 'content_item.dart';

class GalleryContent extends ContentItem {
  const GalleryContent({
    this.gallery,
    super.title,
    super.type = ContentItemType.gallery,
    super.icon,
  });

  final List<String>? gallery;

  factory GalleryContent.fromJson(Map parsedJson) => GalleryContent(
        title: parsedJson['title'],
        icon: parsedJson['icon'],
        gallery: parsedJson['gallery'] != null && parsedJson['gallery'] is List
            ? List<String>.from(parsedJson['gallery'])
            : null,
      );
}
