import 'content_item.dart';
import 'row_item.dart';

class AccordionContent extends ContentItem {
  const AccordionContent({
    this.rows,
    super.title,
    super.type = ContentItemType.accordion,
    super.icon,
  });

  final List<RowItem>? rows;

  factory AccordionContent.fromJson(Map parsedJson) => AccordionContent(
        title: parsedJson['title'],
        icon: parsedJson['icon'],
        rows: parsedJson['rows'] != null && parsedJson['rows'] is List
            ? List.from(parsedJson['rows'])
                .map<RowItem>((e) => RowItem.fromJson(e))
                .toList()
            : [],
      );
}
