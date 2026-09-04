import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:quiver/strings.dart';

import '../../../common/config.dart';
import '../../../common/tools.dart';
import '../../../models/entities/index.dart';
import '../../../widgets/common/expansion_info.dart';

class ProductMenu extends StatelessWidget {
  final Product? product;

  const ProductMenu({this.product});

  @override
  Widget build(BuildContext context) {
    final prices = product!.listingMenu!;
    return ExpansionInfo(
      expand: kProductDetail.expandListingMenu,
      title: S.of(context).menus,
      children: <Widget>[
        Column(
          children: List.generate(prices.length, (i) {
            var showTitle =
                prices[i].title != null && prices[i].title.isNotEmpty;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (showTitle) ...[
                    const SizedBox(height: 10),
                    Text(
                      prices[i].title,
                      style: TextStyle(
                        fontSize: 22,
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValueOpacity(0.5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shrinkWrap: true,
                    itemCount: prices[i].menu.length,
                    itemBuilder: (BuildContext context, int index) {
                      final menuItem = prices[i].menu[index];

                      return Row(
                        children: [
                          if (isNotBlank(menuItem.thumb)) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: FluxImage(
                                imageUrl: menuItem.thumb,
                                height: 50,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isNotBlank(menuItem.name))
                                    Text(
                                      menuItem.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  if (isNotBlank(menuItem.description)) ...[
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      menuItem.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ]),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            menuItem.price == '0'
                                ? S.of(context).free
                                : PriceTools.getCurrencyFormatted(
                                    menuItem.price, null)!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.lightGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                  )
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
