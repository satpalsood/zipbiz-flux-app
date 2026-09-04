import 'content_item.dart';

class VideoContent extends ContentItem {
  const VideoContent({
    this.video,
    super.title,
    super.type = ContentItemType.video,
    super.icon,
  });

  final VideoInfo? video;

  factory VideoContent.fromJson(Map parsedJson) => VideoContent(
        title: parsedJson['title'],
        icon: parsedJson['icon'],
        video: parsedJson['video'] != null && parsedJson['video'] is Map
            ? VideoInfo.fromJson(parsedJson['video'])
            : null,
      );
}

class VideoInfo {
  const VideoInfo({
    this.url,
    this.type,
    this.service,
    this.videoId,
  });

  final String? url;
  final String? type;
  final String? service;
  final String? videoId;

  factory VideoInfo.fromJson(Map parsedJson) => VideoInfo(
        url: parsedJson['url'],
        type: parsedJson['type'],
        service: parsedJson['service'],
        videoId: parsedJson['video_id'],
      );
}
