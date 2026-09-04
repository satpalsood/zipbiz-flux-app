import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../../../../common/config.dart';
import '../../../../common/theme/colors.dart';
import '../../../../common/tools.dart';
import '../../../../models/entities/product.dart';
import '../../../../models/product_wish_list_model.dart';

mixin ListingOptionMixin {
  void showOptions(
    BuildContext context, {
    required Product product,
  }) {
    final wishlistModel = context.read<ProductWishListModel>();
    final isExist = wishlistModel.isWishList(product);
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bottomSheetContext) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                  title: Text(
                      isExist
                          ? S.of(context).removeFromWishList
                          : S.of(context).saveToWishList,
                      textAlign: TextAlign.center),
                  onTap: () {
                    wishlistModel.toggleWishlist(product);

                    Navigator.of(bottomSheetContext).pop();
                  }),
              if (dynamicLinkConfig.allowShareLink) ...[
                ListTile(
                  title: Text(S.of(context).share, textAlign: TextAlign.center),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    context.shareLink(product.permalink);
                  },
                ),
                Container(
                  height: 1,
                  decoration: const BoxDecoration(color: kGrey200),
                ),
              ],
              ListTile(
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                },
                title: Text(
                  S.of(context).cancel,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        });
  }
}
