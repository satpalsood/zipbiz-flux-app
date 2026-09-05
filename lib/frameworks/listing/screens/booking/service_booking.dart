import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants.dart';
import '../../../../common/tools.dart';
import '../../../../common/tools/price_tools.dart';
import '../../../../models/entities/index.dart';
import '../../../../routes/flux_navigate.dart';
import '../booking_history/booking_history_screen.dart';
import 'listing_booking_model.dart';

class ServiceBooking extends StatefulWidget {
  final Product? product;
  final User? user;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessenger;

  const ServiceBooking({
    super.key,
    this.product,
    this.user,
    this.scaffoldMessenger,
  });

  @override
  State<ServiceBooking> createState() => _ServiceBookingState();
}

class _ServiceBookingState extends State<ServiceBooking> {
  int _selectedDateIndex = 0;
  int _selectedSlotIndex = 0;
  final Set<String> _selectedPreferences = {'Call before arrival'};

  final List<Map<String, dynamic>> _slots = [
    {
      'time': '09:00 AM - 12:00 PM',
      'label': 'Popular • 5 slots available',
      'tag': 'RECOMMENDED',
      'period': 'Morning',
    },
    {
      'time': '12:00 PM - 03:00 PM',
      'label': '3 slots remaining',
      'tag': 'Afternoon',
      'period': 'Noon',
    },
    {
      'time': '03:00 PM - 06:00 PM',
      'label': 'Fast filling • 1 slot left',
      'tag': 'Evening',
      'period': 'Evening',
    },
  ];

  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(7, (index) => now.add(Duration(days: index)));
  }

  void _onSelectDate(int index, ListingBookingModel model) {
    setState(() {
      _selectedDateIndex = index;
    });
    model.setDate(_dates[index]);
  }

  void _onSelectSlot(int index, ListingBookingModel model) {
    setState(() {
      _selectedSlotIndex = index;
    });
    final selectedDate = _dates[_selectedDateIndex];
    model.updateListTimeSlot(_slots[index]['time'], selectedDate.weekday, index + 1);
  }

  void _onTogglePreference(String pref) {
    setState(() {
      if (_selectedPreferences.contains(pref)) {
        _selectedPreferences.remove(pref);
      } else {
        _selectedPreferences.add(pref);
      }
    });
  }

  Future<void> _handleConfirmBooking(ListingBookingModel model) async {
    if (widget.user == null) {
      Navigator.of(context).pushNamed(RouteList.login);
      return;
    }

    final selectedDate = _dates[_selectedDateIndex];
    if (model.listTimeSlot.isEmpty) {
      model.updateListTimeSlot(
        _slots[_selectedSlotIndex]['time'],
        selectedDate.weekday,
        _selectedSlotIndex + 1,
      );
    }

    final status = await model.requestBooking(widget.user, context);

    if (!mounted) return;

    if (status == BookStatus.error || status == BookStatus.unavailable) {
      Tools.showSnackBar(
        widget.scaffoldMessenger?.currentState,
        'Slot currently unavailable. Please pick another time slot.',
      );
      return;
    }

    final confirmed = await context.showFluxDialogText(
      title: 'Booking Confirmed!',
      body:
          'Your appointment for ${widget.product?.name ?? "Service"} is scheduled for ${DateFormat('EEE, dd MMM yyyy').format(selectedDate)} (${_slots[_selectedSlotIndex]['time']}).',
      primaryAction: 'View Bookings',
      secondaryAction: 'OK',
      directionButton: Axis.horizontal,
    );

    if (confirmed && mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BookingHistoryScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final user = widget.user;

    return Consumer<ListingBookingModel>(
      builder: (context, model, _) {
        final rawPrice = double.tryParse(product?.price ?? product?.regularPrice ?? '0') ?? 0.0;
        final basePrice = rawPrice > 0 ? rawPrice : 5000.0;
        final discount = 150.0;
        final kitFee = 49.0;
        final finalPrice = (basePrice - discount + kitFee).clamp(0.0, 999999.0);

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Service Summary Card
                  _buildServiceSummaryCard(product, basePrice),
                  const SizedBox(height: 16),

                  // Date Picker Section
                  _buildDatePickerSection(model),
                  const SizedBox(height: 16),

                  // Time Slot Section
                  _buildTimeSlotSection(model),
                  const SizedBox(height: 16),

                  // Service Address Section
                  _buildServiceAddressSection(user),
                  const SizedBox(height: 16),

                  // Preferences / Note to Pro
                  _buildPreferencesSection(),
                  const SizedBox(height: 16),

                  // Promo Code Banner
                  _buildPromoBanner(),
                  const SizedBox(height: 16),

                  // Payment Summary
                  _buildPaymentSummaryCard(basePrice, discount, kitFee, finalPrice),
                  const SizedBox(height: 16),

                  // Trust Guarantee Badges
                  _buildTrustBadges(),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Sticky Bottom Checkout Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildStickyBottomBar(finalPrice, model),
            ),
          ],
        );
      },
    );
  }

  Widget _buildServiceSummaryCard(Product? product, double basePrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FluxImage(
                  imageUrl: product?.imageFeature ?? '',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product?.name ?? 'ZipBiz Service',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B1C1C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 16, color: Color(0xFF2E7D32)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEADDFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Top Rated Partner',
                            style: TextStyle(
                              color: Color(0xFF25005A),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Color(0xFFFF6B00)),
                            const SizedBox(width: 2),
                            Text(
                              '${product?.averageRating != null && product!.averageRating! > 0 ? product.averageRating!.toStringAsFixed(1) : "4.9"} (1.2k)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5A4136),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B00),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product?.name ?? 'Standard Service Package',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1B1C1C),
                      ),
                    ),
                  ],
                ),
                Text(
                  PriceTools.getCurrencyFormatted(basePrice.toString(), null) ?? '₹$basePrice',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1C1C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerSection(ListingBookingModel model) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Color(0xFFFF6B00)),
                  SizedBox(width: 8),
                  Text(
                    'Select Service Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1C1C),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '5 slots left today',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = _dates[index];
                final isSelected = _selectedDateIndex == index;
                String dayLabel;
                if (index == 0) {
                  dayLabel = 'TODAY';
                } else if (index == 1) {
                  dayLabel = 'TOMORROW';
                } else {
                  dayLabel = DateFormat('EEE', 'en').format(date).toUpperCase();
                }

                return GestureDetector(
                  onTap: () => _onSelectDate(index, model),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF6B00) : const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF6B00).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF5A4136),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('d', 'en').format(date),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : const Color(0xFF1B1C1C),
                          ),
                        ),
                        Text(
                          DateFormat('MMM', 'en').format(date),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white.withOpacity(0.9) : const Color(0xFF5A4136),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotSection(ListingBookingModel model) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, size: 18, color: Color(0xFF6B4EA4)),
              SizedBox(width: 8),
              Text(
                'Select Time Slot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(_slots.length, (index) {
              final slot = _slots[index];
              final isSelected = _selectedSlotIndex == index;

              return GestureDetector(
                onTap: () => _onSelectSlot(index, model),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFDBCC).withOpacity(0.5)
                        : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF6B00) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF6B00) : const Color(0xFFE4E2E1),
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot['time'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B1C1C),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              slot['label'],
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? const Color(0xFFFF6B00)
                                    : const Color(0xFF5A4136),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (slot['tag'] == 'RECOMMENDED')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B00).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              color: Color(0xFFFF6B00),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          slot['tag'],
                          style: const TextStyle(
                            color: Color(0xFF5A4136),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          // Partner arrival notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEADDFF).withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user, size: 18, color: Color(0xFF6B4EA4)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ZipBiz verified service partner will arrive within your chosen 3-hour arrival window.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF52358A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceAddressSection(User? user) {
    final addressText = user?.billing?.address1?.isNotEmpty ?? false
        ? user!.billing!.address1!
        : 'House #412, Sector Phase 7, Mohali, Punjab 160062';
    final phoneText = user?.billing?.phone?.isNotEmpty ?? false
        ? user!.billing!.phone!
        : '+91 98881 23456';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Color(0xFFFF6B00)),
                  SizedBox(width: 8),
                  Text(
                    'Service Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1C1C),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () =>
                    FluxNavigate.pushNamed(RouteList.selectAddress, context: context),
                icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF6B00)),
                label: const Text(
                  'Add New',
                  style: TextStyle(
                    color: Color(0xFFFF6B00),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEADDFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEADDFF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6B4EA4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 13, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B1C1C),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EDED),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5A4136),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        addressText,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5A4136)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: $phoneText',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B4EA4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    final options = ['Ring bell twice', 'Pet in household', 'Call before arrival'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Preferences / Note to Pro',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1C1C),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = _selectedPreferences.contains(opt);
            return GestureDetector(
              onTap: () => _onTogglePreference(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFDBCC) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF6B00) : const Color(0xFFE4E2E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check, size: 14, color: Color(0xFF7A3000)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      opt,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF7A3000) : const Color(0xFF1B1C1C),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_offer, color: Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ZIPFEST Applied',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B1C1C),
                      ),
                    ),
                    SizedBox(width: 6),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF2E7D32),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        child: Text(
                          'SAVED ₹150',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'Visiting charges ₹99 also waived off',
                  style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
          const Text(
            'Applied',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(
    double basePrice,
    double discount,
    double kitFee,
    double finalPrice,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1C1C),
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Items Total', '₹${basePrice.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Visiting & Inspection Fee',
                style: TextStyle(fontSize: 13, color: Color(0xFF5A4136)),
              ),
              Row(
                children: [
                  Text(
                    '₹99',
                    style: TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'FREE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            'Festival Coupon (ZIPFEST)',
            '-₹${discount.toStringAsFixed(0)}',
            valueColor: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 8),
          _buildPriceRow('Safety & Sanitation Gear Kit', '₹${kitFee.toStringAsFixed(0)}'),
          const Divider(height: 20, color: Color(0xFFE4E2E1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1C1C),
                ),
              ),
              Text(
                '₹${finalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF6B00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, size: 16, color: Color(0xFF6B4EA4)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ZipBiz Safe Assured: Pay now via UPI/Cards or cash upon full satisfaction.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF5A4136)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String title, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF5A4136))),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1B1C1C),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadges() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFFFDBCC),
                  child: Icon(Icons.verified_user, size: 14, color: Color(0xFFFF6B00)),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '30-Day Guarantee',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Free revisit if unhappy',
                        style: TextStyle(fontSize: 10, color: Color(0xFF5A4136)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFEADDFF),
                  child: Icon(Icons.support_agent, size: 14, color: Color(0xFF6B4EA4)),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ZipBiz Care 24/7',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Fast resolution manager',
                        style: TextStyle(fontSize: 10, color: Color(0xFF5A4136)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar(double finalPrice, ListingBookingModel model) {
    final isLoading = model.state == ListingBookingModelState.loading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${finalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1C1C),
                  ),
                ),
                const Text(
                  'Total Savings: ₹249',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _handleConfirmBooking(model),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: isLoading
                    ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Confirm Booking',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

