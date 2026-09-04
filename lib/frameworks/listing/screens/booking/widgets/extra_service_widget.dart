import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../../../../../common/constants.dart';
import '../../../../../common/tools/price_tools.dart';
import '../../../../../models/entities/menu_price.dart';
import '../../../../../models/entities/product.dart';
import '../listing_booking_model.dart';

class ExtraServiceWidget extends StatelessWidget {
  final Product? product;
  const ExtraServiceWidget({this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listingBookingModel = context.read<ListingBookingModel>();
    final listingMenu = product?.listingMenu ?? <ListingMenu>[];

    if (listingMenu.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).extraServices,
          style: theme.textTheme.titleLarge!
              .copyWith(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        for (var menuSection in listingMenu)
          if (menuSection.menu.isNotEmpty) ...[
            if (menuSection.title?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Text(menuSection.title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    )),
              ),
            Wrap(
              children: [
                for (var menuItem in menuSection.menu)
                  if (menuItem.bookable)
                    _buildMenuItem(
                        context, theme, listingBookingModel, menuItem),
              ],
            ),
          ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, ThemeData theme,
      ListingBookingModel listingBookingModel, dynamic menuItem) {
    final isSelected = listingBookingModel.listServices.contains(menuItem.name);
    final color = isSelected ? theme.primaryColor : theme.primaryColorLight;

    final textColor = isSelected
        ? theme.primaryColor.getColorBasedOnBackground
        : theme.primaryColorLight.getColorBasedOnBackground;

    return InkWell(
      onTap: menuItem.bookable
          ? () => listingBookingModel.updateListServices(menuItem.name)
          : null,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
          color: color,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                menuItem.name ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor),
              ),
            ),
            Text(
              menuItem.price == '0'
                  ? S.of(context).free
                  : PriceTools.getCurrencyFormatted(menuItem.price, null)!,
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
