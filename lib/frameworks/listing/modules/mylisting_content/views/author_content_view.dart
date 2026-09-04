import 'package:flutter/material.dart';

import '../../../../../common/config.dart';
import '../../../../../common/constants.dart';
import '../../../../../widgets/common/expansion_info.dart';
import '../models/author_content.dart';

class AuthorContentView extends StatelessWidget {
  final AuthorContent? content;

  const AuthorContentView({this.content});

  @override
  Widget build(BuildContext context) {
    return ExpansionInfo(
      expand: kProductDetail.expandDescription,
      title: content?.title ?? '',
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(content?.user?.picture ?? ''),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (content?.user?.name ?? '').upperCaseFirstChar(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
