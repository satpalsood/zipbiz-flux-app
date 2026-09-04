import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';

import '../../../../../common/config.dart';
import '../../../../../widgets/common/expansion_info.dart';
import '../models/text_content.dart';

class TextContentView extends StatelessWidget {
  final TextContent? content;

  const TextContentView({this.content});

  @override
  Widget build(BuildContext context) {
    return ExpansionInfo(
      expand: kProductDetail.expandDescription,
      title: content?.title ?? '',
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: HtmlWidget(
            content?.text ?? '',
            textStyle: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
