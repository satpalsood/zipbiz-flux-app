import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';

import '../../../common/config.dart';
import '../../../models/entities/index.dart';
import '../../../widgets/common/expansion_info.dart';

class ProductDescription extends StatelessWidget {
  final Product? product;

  const ProductDescription({this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 15),
        ExpansionInfo(
          expand: kProductDetail.expandDescription,
          title: S.of(context).description,
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              child: HtmlWidget(
                product!.description ?? '',
                textStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
