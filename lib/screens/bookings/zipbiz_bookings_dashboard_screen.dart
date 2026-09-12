import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../core/api/zipbiz_api_service.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../models/entities/listing_booking.dart';
import '../../models/user_model.dart';
import '../../routes/flux_navigate.dart';
import '../../services/index.dart';
import '../../widgets/common/zipbiz_badge.dart';
import '../../widgets/common/zipbiz_button.dart';
import '../../widgets/common/zipbiz_card.dart';
import '../../widgets/common/zipbiz_header.dart';

class ZipBizBookingsDashboardScreen extends StatefulWidget {
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);

  const ZipBizBookingsDashboardScreen({super.key});

  @override
  State<ZipBizBookingsDashboardScreen> createState() =>
      _ZipBizBookingsDashboardScreenState();
}

class _ZipBizBookingsDashboardScreenState
    extends State<ZipBizBookingsDashboardScreen> {
  String _activeTab = 'upcoming'; // 'upcoming', 'completed', 'cancelled'
  bool _isLoading = false;
  List<ListingBooking> _allBookings = [];
  final RefreshController _refreshController = RefreshController();
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    ZipBizBookingsDashboardScreen.refreshNotifier.addListener(_loadBookings);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  @override
  void dispose() {
    ZipBizBookingsDashboardScreen.refreshNotifier.removeListener(_loadBookings);
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserModel>(context).user;
    if (user != null && (user.id != _lastUserId || (_allBookings.isEmpty && !_isLoading))) {
      _lastUserId = user.id;
      _loadBookings();
    }
  }

  Future<void> _loadBookings() async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final results = await Services().api.getBooking(userId: user.id, page: 1, perPage: 50);
      if (mounted) {
        setState(() {
          _allBookings = results ?? [];
          _isLoading = false;
        });
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _refreshController.refreshFailed();
      }
    }
  }

  List<ListingBooking> get _filteredBookings {
    return _allBookings.where((b) {
      final status = (b.status ?? '').toLowerCase();
      if (_activeTab == 'upcoming') {
        return status.contains('confirm') ||
            status.contains('wait') ||
            status.contains('pend') ||
            status.contains('progress') ||
            status.contains('paid') ||
            status.contains('schedule') ||
            status.isEmpty;
      }
      if (_activeTab == 'completed') {
        return status.contains('complete') || status.contains('finish');
      }
      if (_activeTab == 'cancelled') {
        return status.contains('cancel') || status.contains('reject');
      }
      return true;
    }).toList();
  }

  int _countFor(String tab) {
    return _allBookings.where((b) {
      final status = (b.status ?? '').toLowerCase();
      if (tab == 'upcoming') {
        return status.contains('confirm') ||
            status.contains('wait') ||
            status.contains('pend') ||
            status.contains('progress') ||
            status.contains('paid') ||
            status.contains('schedule') ||
            status.isEmpty;
      }
      if (tab == 'completed') {
        return status.contains('complete') || status.contains('finish');
      }
      if (tab == 'cancelled') {
        return status.contains('cancel') || status.contains('reject');
      }
      return false;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context).user;

    if (user != null && _allBookings.isEmpty && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _allBookings.isEmpty && !_isLoading) {
          _loadBookings();
        }
      });
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: ZipBizColors.surface,
        appBar: const ZipBizTopHeader(showBackButton: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month, size: 64, color: ZipBizColors.primaryContainer),
                const SizedBox(height: 16),
                Text('Track Your Bookings', style: ZipBizTypography.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Please sign in to view your scheduled services, track live technicians, and download receipts.',
                  textAlign: TextAlign.center,
                  style: ZipBizTypography.bodySmall,
                ),
                const SizedBox(height: 24),
                ZipBizButton(
                  text: 'Sign In to ZipBiz',
                  onPressed: () => FluxNavigate.pushNamed(RouteList.login, context: context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bookings = _filteredBookings;

    return Scaffold(
      backgroundColor: ZipBizColors.surface,
      appBar: const ZipBizTopHeader(showBackButton: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Bookings', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text('Track services, manage appointments & review pros', style: ZipBizTypography.bodySmall.copyWith(fontSize: 12)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: ZipBizColors.onSurface),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Segmented Filter Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ZipBizColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildSegmentButton('Upcoming', 'upcoming', _countFor('upcoming')),
                _buildSegmentButton('Completed', 'completed', _countFor('completed')),
                _buildSegmentButton('Cancelled', 'cancelled', _countFor('cancelled')),
              ],
            ),
          ),

          // Bookings List
          Expanded(
            child: SmartRefresher(
              controller: _refreshController,
              onRefresh: _loadBookings,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: ZipBizColors.primaryContainer))
                  : (bookings.isEmpty)
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: bookings.length,
                          itemBuilder: (context, idx) => _buildBookingCard(bookings[idx]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, String key, int count) {
    final isSelected = (_activeTab == key);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? ZipBizColors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: ZipBizColors.primaryContainer.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$label ($count)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : ZipBizColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(ListingBooking booking) {
    final status = (booking.status ?? 'waiting').toUpperCase();
    final isConfirmed = status.contains('CONFIRM') || status.contains('PAID') || status.contains('APPROV');
    final isWaiting = status.contains('WAIT') || status.contains('PEND');
    final isInProgress = status.contains('PROGRESS');
    final isCompleted = status.contains('COMPLET');
    final isCancelled = status.contains('CANCEL') || status.contains('REJECT');

    String statusLabel = 'Pending Approval';
    Color statusColor = const Color(0xFFF59E0B);
    Color statusBg = const Color(0xFFFEF3C7);
    IconData statusIcon = Icons.hourglass_top_rounded;

    if (isConfirmed) {
      statusLabel = 'Confirmed';
      statusColor = const Color(0xFF10B981);
      statusBg = const Color(0xFFD1FAE5);
      statusIcon = Icons.check_circle_rounded;
    } else if (isInProgress) {
      statusLabel = 'In Progress';
      statusColor = const Color(0xFF3B82F6);
      statusBg = const Color(0xFFDBEAFE);
      statusIcon = Icons.timelapse_rounded;
    } else if (isCompleted) {
      statusLabel = 'Completed';
      statusColor = const Color(0xFF10B981);
      statusBg = const Color(0xFFD1FAE5);
      statusIcon = Icons.task_alt_rounded;
    } else if (isCancelled) {
      statusLabel = 'Cancelled';
      statusColor = const Color(0xFFEF4444);
      statusBg = const Color(0xFFFEE2E2);
      statusIcon = Icons.cancel_rounded;
    }

    return InkWell(
      onTap: () => _showBookingDetailsDialog(booking),
      borderRadius: BorderRadius.circular(12),
      child: ZipBizCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Status badge & Booking ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 13,
                        color: statusColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text('#ZB-${booking.id ?? booking.orderId ?? ""}', style: ZipBizTypography.labelSmall.copyWith(letterSpacing: 1.1)),
              ],
            ),
            const SizedBox(height: 10),

            // Service Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: ZipBizColors.surfaceContainer,
                    child: (booking.featuredImage != null && booking.featuredImage!.isNotEmpty)
                        ? Image.network(booking.featuredImage!, fit: BoxFit.cover)
                        : const Icon(Icons.handyman, color: ZipBizColors.primaryContainer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.title ?? 'Home Service Appointment', style: ZipBizTypography.labelLarge.copyWith(fontSize: 15)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text('₹${booking.price ?? '499'}', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 16, color: ZipBizColors.primary, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) {
                              final isPaid = (booking.paymentMethod?.toLowerCase() == 'razorpay' &&
                                  (booking.orderStatus == 'completed' ||
                                      booking.orderStatus == 'processing' ||
                                      status.contains('PAID') ||
                                      status.contains('CONFIRM')));
                              final paymentText = isPaid ? 'Paid Online' : 'Payment Pending';
                              final paymentColor = isPaid ? ZipBizColors.statusOpen : const Color(0xFFF59E0B);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: paymentColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  paymentText,
                                  style: TextStyle(fontSize: 10, color: paymentColor, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Schedule Date & Location
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(booking.bookingDate ?? booking.createdDate ?? 'Scheduled Slot', style: ZipBizTypography.bodySmall.copyWith(fontSize: 12)),
                const Spacer(),
                const Icon(Icons.location_on, size: 14, color: ZipBizColors.primaryContainer),
                const SizedBox(width: 4),
                Text(
                  (booking.address != null && (booking.address!['city'] != null || booking.address!['area'] != null))
                      ? '${booking.address!['area'] ?? booking.address!['city'] ?? "Mohali"}'
                      : 'Mohali / Chandigarh',
                  style: ZipBizTypography.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons: View OTP & Details, Cancel / Modify
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.key, size: 15),
                    label: const Text('View OTP & Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZipBizColors.primaryContainer,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showBookingDetailsDialog(booking),
                  ),
                ),
                if (!isCancelled) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _showCancelConfirm(booking);
                      },
                      child: const Text('Cancel / Modify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetailsDialog(ListingBooking booking) {
    final bId = int.tryParse(booking.id?.toString() ?? booking.orderId?.toString() ?? '') ?? 1000;
    final startOtp = (booking.startOtp != null && booking.startOtp!.trim().isNotEmpty)
        ? booking.startOtp!.trim()
        : ((bId * 31 + 1729) % 9000 + 1000).toString();
    final finishOtp = (booking.finishOtp != null && booking.finishOtp!.trim().isNotEmpty)
        ? booking.finishOtp!.trim()
        : ((bId * 47 + 2468) % 9000 + 1000).toString();

    final status = (booking.status ?? 'waiting').toUpperCase();
    final isPaid = (booking.paymentMethod?.toLowerCase() == 'razorpay' &&
        (booking.orderStatus == 'completed' ||
            booking.orderStatus == 'processing' ||
            status.contains('PAID') ||
            status.contains('CONFIRM')));

    // Address extraction
    String addressStr = 'Mohali / Chandigarh';
    if (booking.address != null && booking.address!.isNotEmpty) {
      final addr = booking.address!;
      final parts = <String>[];
      if (addr['house_no'] != null && addr['house_no'].toString().isNotEmpty) parts.add(addr['house_no'].toString());
      if (addr['street'] != null && addr['street'].toString().isNotEmpty) parts.add(addr['street'].toString());
      if (addr['area'] != null && addr['area'].toString().isNotEmpty) parts.add(addr['area'].toString());
      if (addr['city'] != null && addr['city'].toString().isNotEmpty) parts.add(addr['city'].toString());
      if (addr['pincode'] != null && addr['pincode'].toString().isNotEmpty) parts.add(addr['pincode'].toString());
      if (parts.isNotEmpty) {
        addressStr = parts.join(', ');
      } else if (addr['address'] != null) {
        addressStr = addr['address'].toString();
      }
    }

    final timingStr = booking.timeSlot ?? 'Scheduled Slot';
    final dateStr = booking.bookingDate ?? booking.createdDate ?? 'Scheduled Date';
    final hoursStr = booking.hours ?? '2 Hours';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title and Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('#ZB-${booking.id ?? booking.orderId ?? ""}', style: ZipBizTypography.labelSmall.copyWith(color: Colors.grey.shade600, letterSpacing: 1.1)),
                          const SizedBox(height: 2),
                          Text(booking.title ?? 'Service Appointment', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 18)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // OTP Verification Box (Prominent)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ZipBizColors.primaryContainer.withOpacity(0.08), ZipBizColors.primary.withOpacity(0.04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ZipBizColors.primaryContainer.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.shield_outlined, size: 18, color: ZipBizColors.primaryContainer),
                          SizedBox(width: 6),
                          Text('Service Security OTPs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ZipBizColors.primaryContainer)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade100),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.play_circle_fill, size: 14, color: Colors.blue),
                                      SizedBox(width: 4),
                                      Text('Start OTP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    startOtp,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3, color: Color(0xFF1E3A8A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Share to start service', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.shade100),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                                      SizedBox(width: 4),
                                      Text('Finish OTP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    finishOtp,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3, color: Color(0xFF065F46)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Share when completed', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Appointment & Schedule Section
                Text('APPOINTMENT DETAILS', style: ZipBizTypography.labelSmall.copyWith(letterSpacing: 1.1, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.calendar_today, 'Date', dateStr),
                _buildDetailRow(Icons.access_time, 'Timing', timingStr),
                _buildDetailRow(Icons.hourglass_bottom, 'Duration / Hours', hoursStr),
                _buildDetailRow(Icons.location_on_outlined, 'Service Address', addressStr),
                const Divider(height: 24),

                // Services Breakdown
                if (booking.services.isNotEmpty) ...[
                  Text('SERVICES SELECTED', style: ZipBizTypography.labelSmall.copyWith(letterSpacing: 1.1, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  ...booking.services.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(s['name'] ?? '', style: ZipBizTypography.bodySmall)),
                        if ((s['price'] ?? '').isNotEmpty)
                          Text('₹${s['price']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  )),
                  const Divider(height: 24),
                ],

                // Payment & Price Section
                Text('PAYMENT SUMMARY', style: ZipBizTypography.labelSmall.copyWith(letterSpacing: 1.1, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.payment,
                  'Payment Method',
                  (booking.paymentMethod?.toLowerCase() == 'razorpay') ? 'Razorpay Online' : 'Cash on Delivery (COD)',
                ),
                _buildDetailRow(
                  Icons.verified_outlined,
                  'Payment Status',
                  isPaid ? 'Paid Online' : 'Payment Pending',
                  valueColor: isPaid ? ZipBizColors.statusOpen : const Color(0xFFF59E0B),
                ),
                _buildDetailRow(
                  Icons.currency_rupee,
                  'Total Amount',
                  '₹${booking.price ?? '499'}',
                  isBold: true,
                  valueColor: ZipBizColors.primary,
                ),
                const SizedBox(height: 20),

                // Close & Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ),
                    if (!status.contains('CANCEL') && !status.contains('REJECT')) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showCancelConfirm(booking);
                          },
                          child: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: ZipBizColors.primaryContainer),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? ZipBizColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirm(ListingBooking booking) {
    // 1-hour cancellation check
    DateTime? serviceDateTime;
    try {
      if (booking.bookingDate != null && booking.bookingDate!.isNotEmpty) {
        serviceDateTime = DateTime.tryParse(booking.bookingDate!);
      }
    } catch (_) {}

    if (serviceDateTime != null) {
      final difference = serviceDateTime.difference(DateTime.now());
      if (difference.inMinutes < 60) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Cannot Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Appointments can only be cancelled at least 1 hour before the scheduled service time. '
              'Since your appointment is scheduled soon, please reach out directly to customer support for emergency assistance.',
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Center(child: Text('Close')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZipBizColors.primaryContainer,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.headset_mic_outlined, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Contact Support', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Tools.launchURL('https://wa.me/917009218289?text=${Uri.encodeComponent("Hello ZipBiz Support, I need assistance cancelling booking #ZB-${booking.id ?? booking.orderId ?? ""}")}');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment?'),
        content: Text('Are you sure you want to cancel booking #ZB-${booking.id ?? booking.orderId ?? ""}? Cancellation is allowed up to 1 hour before scheduled time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Booking')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = Provider.of<UserModel>(context, listen: false).user;
              final bId = booking.id ?? booking.orderId;
              if (user != null && bId != null) {
                try {
                  await ZipBizApiService().cancelBooking(int.tryParse(bId) ?? 0, user);
                  _loadBookings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking cancelled successfully'), backgroundColor: Colors.orange),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Confirm Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'No upcoming bookings';
    if (_activeTab == 'completed') {
      message = 'No completed bookings yet';
    } else if (_activeTab == 'cancelled') {
      message = 'No cancelled bookings';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: ZipBizColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(message, style: ZipBizTypography.headlineSmall.copyWith(fontSize: 18, color: Colors.grey.shade800)),
            const SizedBox(height: 8),
            Text(
              'Book trusted home services on ZipBiz with instant confirmation',
              textAlign: TextAlign.center,
              style: ZipBizTypography.bodySmall.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ZipBizColors.primaryContainer,
                    side: const BorderSide(color: ZipBizColors.primaryContainer),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _loadBookings,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Book a Service', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZipBizColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    FluxNavigate.pushNamed(RouteList.category, context: context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
