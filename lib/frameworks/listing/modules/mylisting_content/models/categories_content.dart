import 'content_item.dart';
import 'term_item.dart';

class CategoriesContent extends ContentItem {
  const CategoriesContent({
    this.categories,
    super.title,
    super.type = ContentItemType.categories,
    super.icon,
  });

  final List<TermItem>? categories;

  factory CategoriesContent.fromJson(Map parsedJson) => CategoriesContent(
        title: parsedJson['title'],
        icon: parsedJson['icon'],
        categories:
            parsedJson['categories'] != null && parsedJson['categories'] is List
                ? List.from(parsedJson['categories'])
                    .map<TermItem>((e) => TermItem.fromJson(e))
                    .toList()
                : [],
      );
}
