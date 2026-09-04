import 'package:flutter/material.dart';
import 'package:inspireui/inspireui.dart';

import '../../../../../common/config.dart';
import '../../../../../widgets/common/expansion_info.dart';
import '../models/categories_content.dart';

class CategoriesContentView extends StatelessWidget {
  const CategoriesContentView({
    super.key,
    required this.content,
  });
  final CategoriesContent content;
  @override
  Widget build(BuildContext context) {
    return ExpansionInfo(
      expand: kProductDetail.expandDescription,
      title: content.title ?? '',
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    ...?content.categories?.map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Theme.of(context)
                              .primaryColorLight
                              .withValueOpacity(0.5),
                        ),
                        child: Text(
                          item.name ?? '',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
