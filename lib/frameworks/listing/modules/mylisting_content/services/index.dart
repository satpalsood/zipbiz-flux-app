import 'dart:convert' as convert;

import 'package:quiver/strings.dart';

import '../../../../../common/constants.dart';
import '../../../../../services/services.dart';
import '../models/accordion_content.dart';
import '../models/author_content.dart';
import '../models/categories_content.dart';
import '../models/content_item.dart';
import '../models/gallery_content.dart';
import '../models/location_content.dart';
import '../models/table_content.dart';
import '../models/tags_content.dart';
import '../models/text_content.dart';
import '../models/video_content.dart';

class MyListingServices {
  final domain = Services().api.domain;

  Future<List<ContentItem>> getListingContents(String listingId) async {
    try {
      var list = <ContentItem>[];
      var response = await httpGet(
          Uri.parse('$domain/wp-json/wp/v2/job_listing/$listingId/contents'));
      var jsonDecode = convert.jsonDecode(response.body);
      if (jsonDecode is Map && isNotBlank(jsonDecode['message'])) {
        throw Exception(jsonDecode['message']);
      } else {
        for (var item in jsonDecode) {
          switch (ContentItemType.initFrom(item['type'])) {
            case ContentItemType.text:
              list.add(TextContent.fromJson(item));
            case ContentItemType.gallery:
              list.add(GalleryContent.fromJson(item));
            case ContentItemType.table:
              list.add(TableContent.fromJson(item));
            case ContentItemType.tags:
              list.add(TagsContent.fromJson(item));
            case ContentItemType.categories:
              list.add(CategoriesContent.fromJson(item));
            case ContentItemType.author:
              list.add(AuthorContent.fromJson(item));
            case ContentItemType.accordion:
              list.add(AccordionContent.fromJson(item));
            case ContentItemType.video:
              list.add(VideoContent.fromJson(item));
            case ContentItemType.location:
              list.add(LocationContent.fromJson(item));
            default:
          }
        }
        return list;
      }
    } catch (e, trace) {
      printError(e, trace);
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://support.inspireui.com/help-center/
      rethrow;
    }
  }
}
