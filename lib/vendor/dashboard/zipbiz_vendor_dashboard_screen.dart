import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/constants.dart';
import '../../core/api/zipbiz_api_service.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../models/user_model.dart';
import '../../widgets/common/zipbiz_badge.dart';
import '../../widgets/common/zipbiz_button.dart';
import '../../widgets/common/zipbiz_card.dart';
import '../../widgets/common/zipbiz_header.dart';

class ZipBizVendorDashboardScreen extends StatefulWidget {
  const ZipBizVendorDashboardScreen({super.key});

  @override
  State<ZipBizVendorDashboardScreen> createState() =>
      _ZipBizVendorDashboardScreenState();
}

class _ZipBizVendorDashboardScreenState
    extends State<ZipBizVendorDashboardScreen> {
  bool _isLoading = true;
  bool _isOnline = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final statsData = await ZipBizApiService().getVendorDashboard(user);
      final bookingsData = await ZipBizApiService().getVendorBookings(user: user, page: 1, perPage: 20);

      if (mounted) {
        setState(() {
          _stats = statsData;
          _bookings = bookingsData['items'] as List? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateBookingAction(int bookingId, String action) async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;

    try {
      await ZipBizApiService().updateVendorBookingStatus(
        user: user,
        bookingId: bookingId,
        action: action,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking $action successful!'), backgroundColor: ZipBizColors.statusOpen),
      );
      _loadVendorData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayBookings = _stats['today_bookings'] ?? 0;
    final pendingBookings = _stats['pending_bookings'] ?? 0;
    final upcomingBookings = _stats['upcoming_bookings'] ?? 0;
    final netEarnings = _stats['net_earnings'] ?? 0;
    final rating = _stats['rating'] ?? 5.0;

    return Scaffold(
      backgroundColor: ZipBizColors.surface,
      appBar: const ZipBizTopHeader(showBackButton: true),
      body: RefreshIndicator(
        onRefresh: _loadVendorData,
        color: ZipBizColors.primaryContainer,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor Status Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF351000), ZipBizColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: ZipBizColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.handyman, color: ZipBizColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Service Partner Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            _isOnline ? 'Available for Bookings' : 'Offline / On Break',
                            style: TextStyle(color: _isOnline ? Colors.greenAccent : Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isOnline,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.greenAccent,
                      onChanged: (val) {
                        setState(() => _isOnline = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // KPI Metrics Grid
              Row(
                children: [
                  _buildKpiCard('Today Jobs', '$todayBookings', Icons.today, ZipBizColors.primaryContainer),
                  const SizedBox(width: 8),
                  _buildKpiCard('Pending', '$pendingBookings', Icons.pending_actions, ZipBizColors.secondary),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildKpiCard('Net Earnings', '₹$netEarnings', Icons.account_balance_wallet, ZipBizColors.statusOpen),
                  const SizedBox(width: 8),
                  _buildKpiCard('Partner Rating', '$rating ★', Icons.star, const Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Actions Row
              Text('QUICK ACTIONS', style: ZipBizTypography.labelSmall.copyWith(letterSpacing: 1.2, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildQuickAction('Availability', Icons.calendar_month, () {}),
                  const SizedBox(width: 8),
                  _buildQuickAction('Services', Icons.list_alt, () {}),
                  const SizedBox(width: 8),
                  _buildQuickAction('Payouts', Icons.payments_outlined, () {}),
                  const SizedBox(width: 8),
                  _buildQuickAction('Support', Icons.headset_mic_outlined, () {}),
                ],
              ),
              const SizedBox(height: 20),

              // Incoming / Active Bookings Section
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Text('Incoming Job Requests', style: ZipBizTypography.headlineSmall),
                  Text('${_bookings.length} Total', style: ZipBizTypography.labelSmall),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: ZipBizColors.primaryContainer)))
              else if (_bookings.isEmpty)
                ZipBizCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('No pending appointments', style: ZipBizTypography.labelLarge.copyWith(color: Colors.grey.shade700)),
                          const SizedBox(height: 4),
                          Text('New booking requests from customers will appear here in real-time', textAlign: TextAlign.center, style: ZipBizTypography.bodySmall),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ..._bookings.map((b) => _buildVendorBookingCard(b)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: ZipBizCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ZipBizTypography.labelSmall.copyWith(fontSize: 11)),
                  Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZipBizColors.onSurface)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: ZipBizColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: ZipBizColors.primaryContainer, size: 22),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ZipBizColors.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorBookingCard(dynamic booking) {
    final id = booking['booking_id'] as int? ?? 0;
    final title = booking['listing_title'] ?? 'Home Service Request';
    final customer = booking['customer_name'] ?? 'Customer';
    final phone = booking['customer_phone'] ?? '';
    final status = (booking['status'] ?? 'waiting').toString().toLowerCase();
    final price = booking['price'] ?? 499;
    final date = booking['date_start'] ?? 'Scheduled';

    return ZipBizCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: ZipBizColors.primaryFixed, borderRadius: BorderRadius.circular(10)),
                child: Text('#ZB-$id', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ZipBizColors.onPrimaryFixedVariant)),
              ),
              Text('₹$price', style: ZipBizTypography.headlineSmall.copyWith(color: ZipBizColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: ZipBizTypography.labelLarge.copyWith(fontSize: 15)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(customer, style: ZipBizTypography.bodySmall),
              if (phone.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                const Icon(Icons.phone, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(phone, style: ZipBizTypography.bodySmall),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(date, style: ZipBizTypography.bodySmall),
            ],
          ),
          const Divider(height: 16),

          // Action Buttons
          if (status == 'waiting' || status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateBookingAction(id, 'reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateBookingAction(id, 'accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZipBizColors.statusOpen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept Job'),
                  ),
                ),
              ],
            ),
          ] else if (status == 'confirmed') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Start Service Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZipBizColors.primaryContainer,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _updateBookingAction(id, 'start'),
              ),
            ),
          ] else if (status == 'in_progress') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Mark Service Completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZipBizColors.statusOpen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _updateBookingAction(id, 'complete'),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              child: Text(
                'Status: ${status.toUpperCase()}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
