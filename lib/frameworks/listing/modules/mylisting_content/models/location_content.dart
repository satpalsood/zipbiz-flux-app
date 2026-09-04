import 'content_item.dart';

class LocationContent extends ContentItem {
  const LocationContent({
    this.locations,
    super.title,
    super.type = ContentItemType.location,
    super.icon,
  });

  final List<LocationItem>? locations;

  factory LocationContent.fromJson(Map parsedJson) => LocationContent(
        title: parsedJson['title'],
        icon: parsedJson['icon'],
        locations:
            parsedJson['locations'] != null && parsedJson['locations'] is List
                ? List.from(parsedJson['locations'])
                    .map((e) => LocationItem.fromJson(e))
                    .toList()
                : null,
      );
}

class LocationItem {
  const LocationItem({
    this.address,
    this.lat,
    this.lng,
  });

  final String? address;
  final String? lat;
  final String? lng;

  factory LocationItem.fromJson(Map parsedJson) => LocationItem(
        address: parsedJson['address'],
        lat: parsedJson['lat'],
        lng: parsedJson['lng'],
      );
}
