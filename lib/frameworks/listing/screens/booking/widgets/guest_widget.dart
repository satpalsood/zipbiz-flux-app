import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:provider/provider.dart';

import '../../../../../common/constants.dart';
import '../../../../../common/tools.dart';
import '../../../../../models/entities/product.dart';
import '../../../../../models/entities/user.dart';
import '../../booking_history/booking_history_screen.dart';
import '../listing_booking_model.dart';

class GuestWidget extends StatelessWidget {
  final Product? product;
  final User? user;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessenger;

  const GuestWidget({this.product, this.user, this.scaffoldMessenger});

  void showMessage(BuildContext context, BookStatus status,
      Availability availability) async {
    var message = '';
    if (availability == Availability.notEmpty) {
      message = S.of(context).thisDateIsNotAvailable;
      Tools.showSnackBar(scaffoldMessenger?.currentState, message);
      return;
    } else if (availability == Availability.error) {
      message = S.of(context).bookingError;
      Tools.showSnackBar(scaffoldMessenger?.currentState, message);
      return;
    } else {
      switch (status) {
        case BookStatus.booked:
          message = S.of(context).booked;
          break;
        case BookStatus.waiting:
          message = S.of(context).waitingForConfirmation;
          break;
        case BookStatus.confirmed:
          message = S.of(context).bookingConfirm;
          break;
        case BookStatus.cancelled:
          message = S.of(context).bookingCancelled;
          break;
        case BookStatus.unavailable:
          message = S.of(context).bookingUnavailable;
          break;
        default:
          message = S.of(context).bookingError;
          break;
      }

      if (status == BookStatus.error ||
          status == BookStatus.booked ||
          status == BookStatus.unavailable) {
        Tools.showSnackBar(scaffoldMessenger?.currentState, message);
        return;
      }
      final confirmed = await context.showFluxDialogText(
        title: message,
        primaryAction: S.of(context).bookingHistory,
        secondaryAction: S.of(context).ok,
        directionButton: Axis.horizontal,
      );
      if (confirmed) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BookingHistoryScreen(),
          ),
        );
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingBookingModel =
        Provider.of<ListingBookingModel>(context, listen: false);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (product?.type == 'event')
              ? S.of(context).tickets
              : S.of(context).guests,
          style: theme.textTheme.titleLarge!
              .copyWith(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: theme.primaryColorLight,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.remove_circle,
                  size: 25,
                  color: theme.primaryColor,
                ),
                onPressed: () => listingBookingModel.setGuest(false),
              ),
              const SizedBox(width: 20),
              Text(
                '${listingBookingModel.adults}',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: Icon(
                  Icons.add_circle_rounded,
                  size: 25,
                  color: theme.primaryColor,
                ),
                onPressed: () => listingBookingModel.setGuest(true),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: listingBookingModel.state == ListingBookingModelState.loading
              ? SpinKitFadingCircle(
                  color: theme.primaryColor,
                  size: 28.0,
                )
              : GestureDetector(
                  onTap: () async {
                    final status =
                        await listingBookingModel.requestBooking(user, context);
                    showMessage(
                        context, status, listingBookingModel.availability);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(3)),
                    child: Text(
                      S.of(context).requestBooking,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
