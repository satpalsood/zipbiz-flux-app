import 'package:flutter/material.dart';

import '../../../../common/config.dart';
import '../../../../models/entities/index.dart';
import 'models/accordion_content.dart';
import 'models/author_content.dart';
import 'models/categories_content.dart';
import 'models/content_item.dart';
import 'models/gallery_content.dart';
import 'models/table_content.dart';
import 'models/tags_content.dart';
import 'models/text_content.dart';
import 'models/video_content.dart';
import 'services/index.dart';
import 'views/accordion_content_view.dart';
import 'views/author_content_view.dart';
import 'views/categories_content_view.dart';
import 'views/gallery_content_view.dart';
import 'views/table_content_view.dart';
import 'views/tags_content_view.dart';
import 'views/text_content_view.dart';
import 'views/video_content_view.dart';

class MyListingContents extends StatefulWidget {
  const MyListingContents({
    super.key,
    required this.product,
  });
  final Product product;

  @override
  State<MyListingContents> createState() => _MyListingContentsState();
}

class _MyListingContentsState extends State<MyListingContents> {
  final _services = MyListingServices();

  List<ContentItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      _services.getListingContents(widget.product.id).then((items) {
        setState(() {
          _isLoading = false;
          _items = items;
        });
      }).catchError((e) {
        setState(() {
          _isLoading = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading == true) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        child: kLoadingWidget(),
      );
    }
    return Column(
      children: [
        ..._items.map((ContentItem item) {
          switch (item.runtimeType) {
            case const (GalleryContent):
              return GalleryContentView(content: item as GalleryContent);
            case const (TextContent):
              return TextContentView(content: item as TextContent);
            case const (AccordionContent):
              return AccordionContentView(content: item as AccordionContent);
            case const (AuthorContent):
              return AuthorContentView(content: item as AuthorContent);
            case const (CategoriesContent):
              return CategoriesContentView(content: item as CategoriesContent);
            case const (TableContent):
              return TableContentView(content: item as TableContent);
            case const (TagsContent):
              return TagsContentView(content: item as TagsContent);
            case const (VideoContent):
              return VideoContentView(content: item as VideoContent);
            //ProductMap is supported.
            // case const (LocationContent):
            //   return LocationContentView(content: item as LocationContent);
            default:
              return const SizedBox();
          }
        })
      ],
    );
  }
}
