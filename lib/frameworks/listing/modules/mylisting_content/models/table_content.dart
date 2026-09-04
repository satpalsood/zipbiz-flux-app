import 'content_item.dart';
import 'row_item.dart';

class TableContent extends ContentItem {
  const TableContent({
    this.rows,
    super.title,
    super.type = ContentItemType.table,
    super.icon,
  });

  final List<RowItem>? rows;

  factory TableContent.fromJson(Map parsedJson) => TableContent(
        title: parsedJson['title'],
        icon: parsedJson['icon'],
        rows: parsedJson['rows'] != null && parsedJson['rows'] is List
            ? List.from(parsedJson['rows'])
                .map<RowItem>((e) => RowItem.fromJson(e))
                .toList()
            : [],
      );
}
