import 'content_item.dart';
import 'term_item.dart';

class TagsContent extends ContentItem {
  const TagsContent({
    this.tags,
    super.title,
    super.type = ContentItemType.tags,
    super.icon,
  });

  final List<TermItem>? tags;

  factory TagsContent.fromJson(Map parsedJson) => TagsContent(
        title: parsedJson['title'],
        icon: parsedJson['icon'],
        tags: parsedJson['tags'] != null && parsedJson['tags'] is List
            ? List.from(parsedJson['tags'])
                .map<TermItem>((e) => TermItem.fromJson(e))
                .toList()
            : [],
      );
}
