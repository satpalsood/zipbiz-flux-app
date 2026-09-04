import '../../../../../models/entities/index.dart';
import 'content_item.dart';

class AuthorContent extends ContentItem {
  const AuthorContent({
    this.user,
    super.title,
    super.type = ContentItemType.author,
    super.icon,
  });

  final User? user;

  factory AuthorContent.fromJson(Map parsedJson) => AuthorContent(
        title: parsedJson['title'],
        icon: parsedJson['icon'],
        user: parsedJson['author'] != null && parsedJson['author'] is Map
            ? User.fromJson(parsedJson['author'])
            : null,
      );
}
