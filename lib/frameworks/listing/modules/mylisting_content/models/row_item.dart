class RowItem {
  const RowItem({
    this.title,
    this.icon,
    this.content,
  });

  final String? title;
  final String? icon;
  final String? content;

  factory RowItem.fromJson(Map parsedJson) => RowItem(
        title: parsedJson['title'],
        icon: parsedJson['icon'],
        content: parsedJson['content'],
      );
}
