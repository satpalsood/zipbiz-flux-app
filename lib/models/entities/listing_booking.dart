import 'dart:convert';

import '../../common/constants.dart';

class ListingBooking {
  String? id;
  String? title;
  String? featuredImage;
  String? status;
  String? price;
  String? createdDate;
  String? orderId;
  String? orderStatus;
  Map<String, String?> adults = {};
  List<Map<String, String>> services = [];
  ListingBooking(
      this.title,
      this.featuredImage,
      this.status,
      this.price,
      this.createdDate,
      this.adults,
      this.services,
      this.orderId,
      this.orderStatus,
      {this.id});

  ListingBooking.fromJson(Map json) {
    id = json['id']?.toString() ?? json['order_id']?.toString();
    title = json['title']?.toString();
    if (json['featured_image'] is String) {
      featuredImage = json['featured_image'];
    } else {
      featuredImage = kDefaultImage;
    }

    status = json['status']?.toString();
    price = json['price']?.toString();
    createdDate = json['created']?.toString();
    orderId = json['order_id']?.toString();
    orderStatus = json['order_status']?.toString();
    Map commentJson = {};
    if (json['comment'] != null) {
      if (json['comment'] is String && (json['comment'] as String).trim().isNotEmpty) {
        try {
          final parsed = jsonDecode(json['comment']);
          if (parsed is Map) {
            commentJson = parsed;
          }
        } catch (_) {}
      } else if (json['comment'] is Map) {
        commentJson = json['comment'];
      }
    }

    if (commentJson['adults'] != null) {
      adults['adults'] = commentJson['adults']?.toString();
    }
    if (commentJson['tickets'] != null) {
      adults['tickets'] = commentJson['tickets']?.toString();
    }
    final svcList = commentJson['service'];
    if (svcList is List) {
      for (var item in svcList) {
        if (item is Map) {
          final sName = item['service'] is Map
              ? item['service']['name']?.toString()
              : item['name']?.toString();
          final sPrice = item['service'] is Map
              ? item['service']['price']?.toString()
              : item['price']?.toString();
          services.add({
            'name': sName ?? '',
            'price': sPrice ?? '',
          });
        }
      }
    }
  }
}

