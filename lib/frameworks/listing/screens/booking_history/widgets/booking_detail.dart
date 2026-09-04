import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../../../../../common/constants.dart';
import '../../../../../common/tools/price_tools.dart';
import '../../../../../models/app_model.dart';
import '../../../../../models/entities/listing_booking.dart';
import '../../../../../models/user_model.dart';
import '../../booking_payment/booking_payment_model.dart';
import '../../booking_payment/booking_payment_screen.dart';
import '../booking_history_model.dart';

class BookingDetail extends StatefulWidget {
  final ListingBooking? booking;

  const BookingDetail({super.key, this.booking});

  @override
  State<BookingDetail> createState() => _BookingDetailState();
}

class _BookingDetailState extends State<BookingDetail> {
  bool isExpanded = false;
  String _menuServiceItems(Map<String, String> service) {
    final name = service['name'].toString();
    final price = service['price'];
    final formattedPrice = price == '0'
        ? S.of(context).free
        : PriceTools.getCurrencyFormatted(price, null).toString();
    return S.of(context).menuServiceItems(name, formattedPrice);
  }

  @override
  Widget build(BuildContext context) {
    final bookingHistoryModel = context.read<BookingHistoryModel>();
    final appModel = context.read<AppModel>();

    final langCode = appModel.langCode;
    final booking = widget.booking;
    if (booking == null) {
      return const SizedBox();
    }

    return Container(
      width: MediaQuery.sizeOf(context).width,
      margin: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
      padding: const EdgeInsets.only(top: 20, left: 5, right: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValueOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: CachedNetworkImage(
                      imageUrl: booking.featuredImage ?? '',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.title ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        '${S.of(context).total}: ${PriceTools.getCurrencyFormatted(
                          booking.price,
                          null,
                        )}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${S.of(context).on} ${booking.createdDate}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    _getStatusText(booking),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        )
                        .apply(fontSizeFactor: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.fastOutSlowIn,
                width: MediaQuery.sizeOf(context).width,
                height: isExpanded ? 210 : 44,
                decoration: BoxDecoration(
                  color: isExpanded
                      ? Theme.of(context).primaryColor.withValueOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (isExpanded) ...[
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(S.of(context).yourBookingDetail,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                      ),
                      Flexible(
                          child: booking.adults['adults'] != null
                              ? Text(
                                  '${S.of(context).adults}: ${booking.adults['adults']}',
                                  style: Theme.of(context).textTheme.titleLarge)
                              : Text(
                                  '${S.of(context).tickets}: ${booking.adults['tickets']}',
                                  style:
                                      Theme.of(context).textTheme.titleLarge)),
                      Flexible(
                          child: Text('${S.of(context).additionalServices}:',
                              style: Theme.of(context).textTheme.titleLarge)),
                      if (booking.services.isEmpty)
                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValueOpacity(0.2),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Center(
                              child: Text(S.of(context).none.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ),
                          ),
                        ),
                      if (booking.services.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) => Container(
                              margin: const EdgeInsets.all(5.0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: kColorRed,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Center(
                                child: Text(
                                  //'Cheddar Burger: 20.00',
                                  _menuServiceItems(booking.services[index]),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            itemCount: booking.services.length,
                          ),
                        ),
                    ],
                    Icon(
                      isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      size: 44,
                      color: Theme.of(context).primaryColor,
                    )
                  ],
                )),
          ),
          const SizedBox(height: 10),
          if (booking.status?.toLowerCase() == 'confirmed' &&
              booking.orderStatus?.toLowerCase() == 'pending')
            InkWell(
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) {
                final user =
                    Provider.of<UserModel>(context, listen: false).user;
                return ChangeNotifierProvider<BookingPaymentModel>(
                    create: (_) => BookingPaymentModel(
                          user: user,
                          booking: booking,
                          langCode: langCode,
                        ),
                    child: BookingPaymentScreen(
                      callback: () => bookingHistoryModel.loadBooking(user?.id),
                    ));
              })),
              child: Container(
                height: 55,
                margin: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 10.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(
                  child: Text(
                    S.of(context).payNow,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .copyWith(
                            color: Theme.of(context)
                                .primaryColor
                                .getColorBasedOnBackground,
                            fontWeight: FontWeight.w700)
                        .apply(fontSizeFactor: 1.2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText(ListingBooking booking) {
    if (booking.orderStatus?.toLowerCase() == 'processing' &&
        booking.status?.toLowerCase() == 'confirmed') {
      return S.of(context).orderStatusProcessing.toUpperCase();
    } else {
      switch (booking.status?.toLowerCase()) {
        case 'confirmed':
          return S.of(context).bookingConfirm.toUpperCase();
        case 'paid':
          return S.of(context).paid.toUpperCase();
        case 'waiting':
          return S.of(context).waiting.toUpperCase();
        default:
          return '';
      }
    }
  }
}
