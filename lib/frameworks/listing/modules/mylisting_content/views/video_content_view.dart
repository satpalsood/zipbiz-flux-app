import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';

import '../../../../../common/config.dart';
import '../../../../../screens/detail/widgets/video_feature.dart';
import '../../../../../widgets/common/expansion_info.dart';
import '../models/video_content.dart';

class VideoContentView extends StatelessWidget {
  final VideoContent? content;

  const VideoContentView({this.content});

  @override
  Widget build(BuildContext context) {
    return ExpansionInfo(
      expand: kProductDetail.expandDescription,
      title: (content?.title?.isNotEmpty ?? false)
          ? content!.title!
          : S.of(context).video,
      children: <Widget>[
        FeatureVideoPlayer(
          content?.video?.url ?? '',
          autoPlay: false,
          holdToPlayPause: false,
          tapToPlayPause: true,
        ),
      ],
    );
  }
}
