import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/entities/index.dart';
import 'listing_booking_model.dart';
import 'thumbnail.dart';
import 'widgets/booking_summary_widget.dart';
import 'widgets/extra_service_widget.dart';
import 'widgets/guest_widget.dart';
import 'widgets/pick_date_time_widget.dart';

class ServiceBooking extends StatelessWidget {
  final Product? product;
  final User? user;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessenger;

  const ServiceBooking({this.product, this.user, this.scaffoldMessenger});

  @override
  Widget build(BuildContext context) {
    return Consumer<ListingBookingModel>(
      builder: (context, model, _) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Thumbnail(product: product),
            BookingSummaryWidget(product: product),
            const SizedBox(height: 20),
            PickDateTimeWidget(product: product),
            ExtraServiceWidget(product: product),
            GuestWidget(
              product: product,
              user: user,
              scaffoldMessenger: scaffoldMessenger,
            ),
            const SizedBox(height: 40)
          ],
        ),
      ),
    );
  }
}
