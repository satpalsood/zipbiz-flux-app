import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/entities/index.dart';
import 'listing_booking_model.dart';
import 'thumbnail.dart';
import 'widgets/booking_summary_widget.dart';
import 'widgets/extra_service_widget.dart';
import 'widgets/guest_widget.dart';

class EventBooking extends StatelessWidget {
  final Product? product;
  final User? user;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessenger;

  const EventBooking({
    this.product,
    this.user,
    this.scaffoldMessenger,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ListingBookingModel>(
      builder: (context, model, _) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Thumbnail(product: product),
            BookingSummaryWidget(product: product),
            const SizedBox(height: 20),
            ExtraServiceWidget(product: product),
            const SizedBox(height: 30),
            GuestWidget(
              product: product,
              user: user,
              scaffoldMessenger: scaffoldMessenger,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
