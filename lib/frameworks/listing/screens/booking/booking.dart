import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../../../../common/tools/navigate_tools.dart';
import '../../../../models/index.dart';
import '../../../../routes/flux_navigate.dart';
import '../../../../screens/base_screen.dart';
import 'event_booking.dart';
import 'listing_booking_model.dart';
import 'rental_booking.dart';
import 'service_booking.dart';

class BookingScreen extends StatefulWidget {
  final Product? product;

  const BookingScreen({this.product});

  @override
  BaseScreen<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends BaseScreen<BookingScreen> {
  User? user;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void afterFirstLayout(BuildContext context) {
    if (mounted) {
      setState(() {
        user = Provider.of<UserModel>(context, listen: false).user;
      });
    }
  }

  Widget renderLayout() {
    switch (widget.product?.type ?? 'service') {
      case 'rental':
        return ChangeNotifierProvider<ListingBookingModel>(
          create: (_) => ListingBookingModel(widget.product),
          child: RentalBooking(
            product: widget.product,
            user: user,
            scaffoldMessenger: _scaffoldMessengerKey,
          ),
        );
      case 'event':
        return ChangeNotifierProvider<ListingBookingModel>(
          create: (_) => ListingBookingModel(widget.product),
          child: EventBooking(
            product: widget.product,
            user: user,
            scaffoldMessenger: _scaffoldMessengerKey,
          ),
        );
      case 'service':
      default:
        return ChangeNotifierProvider<ListingBookingModel>(
          create: (_) => ListingBookingModel(widget.product),
          child: ServiceBooking(
            product: widget.product,
            user: user,
            scaffoldMessenger: _scaffoldMessengerKey,
          ),
        );
    }
  }

  Widget _buildStepper() {
    return Container(
      color: const Color(0xFFFBF9F8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Step 1: Services (Completed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 15, color: Colors.white),
              ),
              const SizedBox(width: 6),
              const Text(
                'Services',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B1C1C),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Step 2: Schedule (Active)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B00),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B00),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E2E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Step 3: Confirm
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFE4E2E1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A4136),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Confirm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5A4136),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF9F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFBF9F8),
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1B1C1C)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Image.network(
                'https://zipbiz.in/wp-content/uploads/2025/06/zipbizlogo.png',
                height: 28,
                errorBuilder: (_, __, ___) => const Text(
                  'ZipBiz',
                  style: TextStyle(
                    color: Color(0xFFFF6B00),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Service Details',
                style: TextStyle(
                  color: Color(0xFF1B1C1C),
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none, color: Color(0xFF5A4136)),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: Color(0xFFFF6B00),
                    ),
                  ),
                ],
              ),
              onPressed: () =>
                  FluxNavigate.pushNamed(RouteList.notify, context: context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            _buildStepper(),
            const Divider(height: 1, color: Color(0xFFE4E2E1)),
            Expanded(
              child: user != null
                  ? renderLayout()
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 48,
                                color: Color(0xFFFF6B00),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Sign in to Schedule Service',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B1C1C),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please sign in to select your appointment slot and confirm your booking with verified ZipBiz partners.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5A4136),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      NavigateTools.navigateToLogin(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B00),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Login to Proceed',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
