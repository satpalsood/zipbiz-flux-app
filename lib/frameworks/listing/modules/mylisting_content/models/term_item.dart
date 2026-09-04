class TermItem {
  const TermItem({
    this.termId,
    this.name,
    this.slug,
  });

  final int? termId;
  final String? name;
  final String? slug;

  factory TermItem.fromJson(Map parsedJson) => TermItem(
        termId: parsedJson['term_id'],
        name: parsedJson['name'],
        slug: parsedJson['slug'],
      );
}
