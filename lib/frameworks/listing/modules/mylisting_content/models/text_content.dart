import 'content_item.dart';

class TextContent extends ContentItem {
  const TextContent({
    this.text,
    super.title,
    super.type = ContentItemType.text,
    super.icon,
  });

  final String? text;

  factory TextContent.fromJson(Map parsedJson) => TextContent(
        title: parsedJson['title'],
        icon: parsedJson['icon'],
        text: parsedJson['text'],
      );
}
