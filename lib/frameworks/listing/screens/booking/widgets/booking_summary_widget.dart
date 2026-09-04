import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../common/tools/price_tools.dart';
import '../../../../../models/entities/product.dart';
import '../listing_booking_model.dart';

class BookingSummaryWidget extends StatelessWidget {
  final Product? product;

  const BookingSummaryWidget({this.product});

  @override
  Widget build(BuildContext context) {
    final listingBookingModel =
        Provider.of<ListingBookingModel>(context, listen: false);
    final listingType = product?.type;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _renderRow(
            listingType == 'service'
                ? S.of(context).date
                : S.of(context).dateStart,
            DateFormat('yyyy-MM-dd').format(listingType == 'service'
                ? listingBookingModel.date
                : listingBookingModel.dateStart),
          ),
          if (listingType == 'rental') ...[
            _renderRow(
              S.of(context).dateEnd,
              DateFormat('yyyy-MM-dd').format(listingBookingModel.dateEnd),
            ),
          ],
          if (listingType == 'service') ...[
            _renderRow(
              S.of(context).time,
              listingBookingModel.time.format(context),
            ),
          ],
          _renderRow(
            (listingType == 'event')
                ? S.of(context).tickets
                : S.of(context).guests,
            '${listingBookingModel.adults}',
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 15),
            child: Divider(height: 1),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(S.of(context).total,
                    style: const TextStyle(fontSize: 20)),
              ),
              Text(
                  PriceTools.getCurrencyFormatted(
                      listingBookingModel.price.toString(), null)!,
                  style: const TextStyle(fontSize: 20))
            ],
          ),
        ],
      ),
    );
  }
}

Widget _renderRow(String label, String value,
    {TextStyle style = const TextStyle(fontSize: 16)}) {
  return Column(
    children: [
      Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
      const SizedBox(height: 10),
    ],
  );
}
