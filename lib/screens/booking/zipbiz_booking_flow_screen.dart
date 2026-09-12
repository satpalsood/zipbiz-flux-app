import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../common/config.dart';
import '../../common/constants.dart';
import '../../core/api/zipbiz_api_service.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../models/entities/listing_slots.dart';
import '../../models/entities/product.dart';
import '../../models/user_model.dart';
import '../../routes/flux_navigate.dart';
import '../../widgets/common/zipbiz_badge.dart';
import '../../widgets/common/zipbiz_button.dart';
import '../../widgets/common/zipbiz_card.dart';
import '../../widgets/common/zipbiz_header.dart';

class ZipBizBookingFlowScreen extends StatefulWidget {
  final Product product;
  final List<Map<String, dynamic>> selectedPackages;
  final double totalPrice;

  const ZipBizBookingFlowScreen({
    super.key,
    required this.product,
    required this.selectedPackages,
    required this.totalPrice,
  });

  @override
  State<ZipBizBookingFlowScreen> createState() => _ZipBizBookingFlowScreenState();
}

class _ZipBizBookingFlowScreenState extends State<ZipBizBookingFlowScreen> {
  int _currentStep = 2; // Step 2: Schedule, Step 3: Confirm & Pay
  late DateTime _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoadingSlots = false;
  bool _isProcessingBooking = false;
  String _paymentMethod = 'razorpay'; // 'razorpay' or 'cod'

  // Address Controllers
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Razorpay? _razorpay;
  int? _pendingBookingId;
  List<Map<String, dynamic>> _availableSlots = [];

  int get _slotInterval {
    try {
      for (var item in widget.product.metaData) {
        if (item['key'] == '_slot_interval') {
          return int.tryParse(item['value']?.toString() ?? '3') ?? 3;
        }
      }
    } catch (_) {}
    return 3;
  }

  List<String> get _computedSlots {
    if (_availableSlots.isNotEmpty) {
      return _availableSlots.map((s) => s['time']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }

    // Try parsing vendor's configured slots from listing metadata or listingSlots
    try {
      final weekdayIdx = _selectedDate.weekday % 7; // 0 for Sun or Listeo 0..6
      if (widget.product.listingSlots != null && widget.product.listingSlots!.timeSlots.isNotEmpty) {
        final allDays = widget.product.listingSlots!.timeSlots;
        if (weekdayIdx < allDays.length && allDays[weekdayIdx].isNotEmpty) {
          final daySlots = allDays[weekdayIdx].map((s) => s.toString().split('|')[0].trim()).toList();
          if (daySlots.isNotEmpty) return daySlots;
        } else if (allDays.isNotEmpty && allDays.first.isNotEmpty) {
          return allDays.first.map((s) => s.toString().split('|')[0].trim()).toList();
        }
      }

      for (var item in widget.product.metaData) {
        final k = item['key']?.toString();
        if (k == '_slots' || k == 'slots') {
          final raw = item['value'];
          final parsed = ListingSlots.fromJson(raw);
          if (parsed.timeSlots.isNotEmpty) {
            if (weekdayIdx < parsed.timeSlots.length && parsed.timeSlots[weekdayIdx].isNotEmpty) {
              return parsed.timeSlots[weekdayIdx].map((s) => s.toString().split('|')[0].trim()).toList();
            } else if (parsed.timeSlots.first.isNotEmpty) {
              return parsed.timeSlots.first.map((s) => s.toString().split('|')[0].trim()).toList();
            }
          }
        }
      }
    } catch (_) {}

    if (_slotInterval == 1) {
      return [
        '08:00 AM - 09:00 AM',
        '09:00 AM - 10:00 AM',
        '10:00 AM - 11:00 AM',
        '11:00 AM - 12:00 PM',
        '12:00 PM - 01:00 PM',
        '01:00 PM - 02:00 PM',
        '02:00 PM - 03:00 PM',
        '03:00 PM - 04:00 PM',
        '04:00 PM - 05:00 PM',
        '05:00 PM - 06:00 PM',
        '06:00 PM - 07:00 PM',
        '07:00 PM - 08:00 PM',
        '08:00 PM - 09:00 PM',
        '09:00 PM - 10:00 PM',
        '10:00 PM - 11:00 PM',
      ];
    }
    if (_slotInterval == 2) {
      return [
        '08:00 AM - 10:00 AM',
        '10:00 AM - 12:00 PM',
        '12:00 PM - 02:00 PM',
        '02:00 PM - 04:00 PM',
        '04:00 PM - 06:00 PM',
        '06:00 PM - 08:00 PM',
        '08:00 PM - 10:00 PM',
      ];
    }
    return [
      '08:00 AM - 11:00 AM',
      '11:00 AM - 02:00 PM',
      '02:00 PM - 05:00 PM',
      '05:00 PM - 08:00 PM',
      '08:00 PM - 11:00 PM',
    ];
  }

  bool _isSlotAvailable(String slot) {
    if (_availableSlots.isEmpty) return true;
    final match = _availableSlots.firstWhere(
      (s) => s['time'] == slot,
      orElse: () => {'available': true},
    );
    return match['available'] == true;
  }

  void _loadAvailability() async {
    final listingId = int.tryParse(widget.product.id ?? '0');
    if (listingId == null || listingId == 0) return;

    setState(() => _isLoadingSlots = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final slots = await ZipBizApiService().getSlotAvailability(listingId, dateStr, interval: _slotInterval);
      if (mounted) {
        setState(() {
          _availableSlots = slots;
          _isLoadingSlots = false;
          if (_computedSlots.isNotEmpty) {
            final firstAvail = _computedSlots.firstWhere(
              (s) => _isSlotAvailable(s),
              orElse: () => _computedSlots.first,
            );
            _selectedTimeSlot = firstAvail;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTimeSlot = _computedSlots.first;
    _initRazorpay();
    _prefillUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailability();
    });
  }

  void _prefillUser() {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user != null) {
      _phoneController.text = user.phoneNumber ?? user.billing?.phone ?? '';
      _houseController.text = user.billing?.address1 ?? '';
      _streetController.text = user.billing?.city ?? 'Mohali';
    }
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _houseController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null || _pendingBookingId == null) return;

    setState(() => _isProcessingBooking = true);
    try {
      // Cryptographic signature verification on WordPress backend
      await ZipBizApiService().verifyRazorpayPayment(
        user: user,
        bookingId: _pendingBookingId!,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment verification failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessingBooking = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessingBooking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Cancelled or Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  Future<void> _proceedToBooking() async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to complete your booking.')),
      );
      FluxNavigate.pushNamed(RouteList.login, context: context);
      return;
    }

    if (_houseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your house/flat address.')),
      );
      return;
    }

    setState(() => _isProcessingBooking = true);

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final listingId = int.tryParse(widget.product.id ?? '0') ?? 0;

      final addressMap = {
        'house': _houseController.text.trim(),
        'street': _streetController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': 'Mohali / Chandigarh',
      };

      // 1. Create booking on WordPress/Listeo backend
      final bookingResult = await ZipBizApiService().createBooking(
        user: user,
        listingId: listingId,
        date: formattedDate,
        timeSlot: _selectedTimeSlot ?? _computedSlots.first,
        services: widget.selectedPackages,
        address: addressMap,
        notes: _notesController.text.trim(),
        paymentMethod: _paymentMethod,
      );

      final bookingId = bookingResult['booking_id'] as int? ?? 0;
      _pendingBookingId = bookingId;

      // 2. Handle Payment
      if (_paymentMethod == 'razorpay') {
        // Create verified Razorpay order server-side
        final orderData = await ZipBizApiService().createRazorpayOrder(bookingId, user);
        final rzpOrderId = orderData['razorpay_order_id'] as String;
        final amountPaise = orderData['amount_paise'] as int;
        final keyId = orderData['key_id'] as String;

        final options = {
          'key': keyId,
          'amount': amountPaise,
          'name': 'ZipBiz Marketplace',
          'order_id': rzpOrderId,
          'description': widget.product.name ?? 'Home Service Booking',
          'prefill': {
            'contact': _phoneController.text,
            'email': user.email ?? '',
          },
          'theme': {
            'color': '#FF6B00',
          },
        };

        _razorpay!.open(options);
      } else {
        // COD / Pay on Service
        _showSuccessDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessingBooking = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: ZipBizColors.statusOpen, size: 64),
            const SizedBox(height: 16),
            Text('Request Sent!', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
            const SizedBox(height: 12),
            Text(
              'Booking request sent to vendor, wait for the confirmation.',
              textAlign: TextAlign.center,
              style: ZipBizTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: ZipBizColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scheduled for ${DateFormat('dd MMM yyyy').format(_selectedDate)} at $_selectedTimeSlot with ${widget.product.name}.',
              textAlign: TextAlign.center,
              style: ZipBizTypography.bodySmall.copyWith(color: ZipBizColors.outline),
            ),
            const SizedBox(height: 24),
            ZipBizButton(
              text: 'View My Bookings',
              width: double.infinity,
              onPressed: () {
                Navigator.pop(ctx); // pop dialog
                Navigator.pop(context); // pop booking screen
                FluxNavigate.pushNamed(RouteList.bookingHistory, context: context);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Back to Listing', style: TextStyle(color: ZipBizColors.secondary)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customFeeMeta = widget.product.metaData.firstWhere(
      (m) =>
          m['key'] == '_additional_fee_amount' ||
          m['key'] == 'additional_fee_amount' ||
          m['key'] == '_visiting_fee',
      orElse: () => {},
    );
    final customFeeLabelMeta = widget.product.metaData.firstWhere(
      (m) =>
          m['key'] == '_additional_fee_label' ||
          m['key'] == 'additional_fee_label',
      orElse: () => {},
    );
    final customFee =
        double.tryParse(customFeeMeta['value']?.toString() ?? '0') ?? 0.0;
    final customFeeLabel =
        customFeeLabelMeta['value']?.toString().isNotEmpty == true
            ? customFeeLabelMeta['value'].toString()
            : 'Service & Handling Fee';
    final grandTotal = widget.totalPrice + customFee;

    return Scaffold(
      backgroundColor: ZipBizColors.surface,
      appBar: const ZipBizTopHeader(showBackButton: true),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stepper Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: ZipBizColors.surface,
                  child: Row(
                    children: [
                      // Step 1
                      _buildStepItem(1, 'Services', isDone: true, isActive: false),
                      Expanded(child: Container(height: 2, color: ZipBizColors.primaryContainer)),
                      // Step 2
                      _buildStepItem(2, 'Schedule', isDone: false, isActive: (_currentStep == 2)),
                      Expanded(child: Container(height: 2, color: (_currentStep == 3) ? ZipBizColors.primaryContainer : Colors.grey.shade300)),
                      // Step 3
                      _buildStepItem(3, 'Confirm', isDone: false, isActive: (_currentStep == 3)),
                    ],
                  ),
                ),

                // Service Summary Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ZipBizCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 50,
                                height: 50,
                                color: ZipBizColors.surfaceContainer,
                                child: (widget.product.imageFeature != null && widget.product.imageFeature!.isNotEmpty)
                                    ? Image.network(widget.product.imageFeature!, fit: BoxFit.cover)
                                    : const Icon(Icons.cleaning_services, color: ZipBizColors.primaryContainer),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.product.name ?? 'Service', style: ZipBizTypography.labelLarge),
                                  const SizedBox(height: 2),
                                  Text(widget.product.location ?? 'Mohali / Chandigarh', style: ZipBizTypography.bodySmall.copyWith(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        ...widget.selectedPackages.map((pkg) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: ZipBizColors.primaryContainer),
                                  const SizedBox(width: 6),
                                  Text(pkg['name'] ?? 'Package', style: ZipBizTypography.bodySmall),
                                ],
                              ),
                              Text('₹${(pkg['price'] as double).toStringAsFixed(0)}', style: ZipBizTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),

                if (_currentStep == 2) ...[
                  // Date Picker Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Service Date', style: ZipBizTypography.headlineSmall),
                        Text('Available daily', style: ZipBizTypography.labelSmall.copyWith(color: ZipBizColors.statusOpen)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 14,
                      itemBuilder: (context, idx) {
                        final date = DateTime.now().add(Duration(days: idx));
                        final isSelected = (_selectedDate.year == date.year &&
                            _selectedDate.month == date.month &&
                            _selectedDate.day == date.day);

                        String dayLabel;
                        if (idx == 0) {
                          dayLabel = 'Today';
                        } else if (idx == 1) {
                          dayLabel = 'Tomorrow';
                        } else {
                          dayLabel = DateFormat('EEE').format(date);
                        }

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedDate = date);
                            _loadAvailability();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 68,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? ZipBizColors.primaryContainer : ZipBizColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? ZipBizColors.primaryContainer : ZipBizColors.surfaceContainer,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: ZipBizColors.primaryContainer.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : ZipBizColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : ZipBizColors.onSurface,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM').format(date),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? Colors.white : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Time Slots Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Time Slot', style: ZipBizTypography.headlineSmall),
                        if (_isLoadingSlots)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: ZipBizColors.primaryContainer),
                          )
                        else
                          Text('${_slotInterval}h intervals', style: ZipBizTypography.labelSmall),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: _computedSlots.map((slot) {
                        final isSelected = (_selectedTimeSlot == slot);
                        final isAvailable = _isSlotAvailable(slot);
                        return ZipBizCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected
                              ? ZipBizColors.primaryFixed.withOpacity(0.2)
                              : (isAvailable ? ZipBizColors.surfaceContainerLowest : Colors.grey.shade100),
                          border: Border.all(
                            color: isSelected ? ZipBizColors.primaryContainer : ZipBizColors.surfaceContainer,
                            width: isSelected ? 1.5 : 1,
                          ),
                          onTap: isAvailable ? () => setState(() => _selectedTimeSlot = slot) : null,
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected
                                    ? ZipBizColors.primaryContainer
                                    : (isAvailable ? Colors.grey : Colors.grey.shade300),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                slot,
                                style: ZipBizTypography.labelLarge.copyWith(
                                  fontSize: 14,
                                  color: isAvailable ? null : Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? ZipBizColors.statusOpen.withOpacity(0.1)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isAvailable ? 'Available' : 'Booked',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isAvailable ? ZipBizColors.statusOpen : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                if (_currentStep == 3) ...[
                  // Service Delivery Address Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text('Service Delivery Address', style: ZipBizTypography.headlineSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ZipBizCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _houseController,
                            minLines: 1,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Flat / House No. / Building Name *',
                              labelStyle: const TextStyle(fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _streetController,
                            minLines: 1,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Street / Area / Sector (e.g. Phase 7, Mohali) *',
                              labelStyle: const TextStyle(fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _landmarkController,
                            minLines: 1,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Landmark (Optional)',
                              labelStyle: const TextStyle(fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Contact Phone Number *',
                              labelStyle: const TextStyle(fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Special instructions for technician',
                              labelStyle: const TextStyle(fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Payment Mode Selection
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('Payment Method', style: ZipBizTypography.headlineSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ZipBizCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: (_paymentMethod == 'razorpay') ? ZipBizColors.primaryFixed.withOpacity(0.2) : Colors.white,
                          border: Border.all(
                            color: (_paymentMethod == 'razorpay') ? ZipBizColors.primaryContainer : ZipBizColors.surfaceContainer,
                          ),
                          onTap: () => setState(() => _paymentMethod = 'razorpay'),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'razorpay',
                                groupValue: _paymentMethod,
                                activeColor: ZipBizColors.primaryContainer,
                                onChanged: (val) => setState(() => _paymentMethod = val!),
                              ),
                              const Icon(Icons.credit_card, color: ZipBizColors.primaryContainer),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pay Online via Razorpay', style: ZipBizTypography.labelLarge),
                                  Text('UPI, Cards, Netbanking (100% Secure)', style: ZipBizTypography.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ZipBizCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: (_paymentMethod == 'cod') ? ZipBizColors.primaryFixed.withOpacity(0.2) : Colors.white,
                          border: Border.all(
                            color: (_paymentMethod == 'cod') ? ZipBizColors.primaryContainer : ZipBizColors.surfaceContainer,
                          ),
                          onTap: () => setState(() => _paymentMethod = 'cod'),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'cod',
                                groupValue: _paymentMethod,
                                activeColor: ZipBizColors.primaryContainer,
                                onChanged: (val) => setState(() => _paymentMethod = val!),
                              ),
                              const Icon(Icons.payments_outlined, color: ZipBizColors.secondary),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cash on Service', style: ZipBizTypography.labelLarge),
                                  Text('Pay after technician completes the job', style: ZipBizTypography.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bill Breakdown
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('Payment Summary', style: ZipBizTypography.headlineSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ZipBizCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Items Total', style: ZipBizTypography.bodySmall),
                              Text('₹${widget.totalPrice.toStringAsFixed(0)}', style: ZipBizTypography.labelLarge),
                            ],
                          ),
                          if (customFee > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(customFeeLabel, style: ZipBizTypography.bodySmall),
                                Text('₹${customFee.toStringAsFixed(0)}', style: ZipBizTypography.labelLarge),
                              ],
                            ),
                          ],
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Grand Total', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 16)),
                              Text('₹${grandTotal.toStringAsFixed(0)}', style: ZipBizTypography.headlineSmall.copyWith(color: ZipBizColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Action Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFF0EDED), width: 1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep == 3) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _currentStep = 2),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ZipBizButton(
                      height: 50,
                      text: (_currentStep == 2)
                          ? 'Continue to Address & Payment'
                          : (_paymentMethod == 'razorpay')
                              ? 'Pay ₹${grandTotal.toStringAsFixed(0)} Online'
                              : 'Confirm Booking (Pay on Service)',
                      isLoading: _isProcessingBooking,
                      onPressed: () {
                        if (_currentStep == 2) {
                          setState(() => _currentStep = 3);
                        } else {
                          _proceedToBooking();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepNum, String title, {required bool isDone, required bool isActive}) {
    Color circleBg = Colors.grey.shade300;
    Color circleFg = Colors.grey.shade700;
    if (isDone) {
      circleBg = ZipBizColors.statusOpen;
      circleFg = Colors.white;
    } else if (isActive) {
      circleBg = ZipBizColors.primaryContainer;
      circleFg = Colors.white;
    }

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('$stepNum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: circleFg)),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? ZipBizColors.primary : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
