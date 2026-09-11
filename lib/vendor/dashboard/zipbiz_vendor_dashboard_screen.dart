import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../core/api/zipbiz_api_service.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../models/user_model.dart';
import '../../screens/services/zipbiz_services_directory_screen.dart';
import '../../widgets/common/zipbiz_badge.dart';
import '../../widgets/common/zipbiz_button.dart';
import '../../widgets/common/zipbiz_card.dart';
import '../../widgets/common/zipbiz_header.dart';
import '../listings/zipbiz_add_edit_listing_screen.dart';

class ZipBizVendorDashboardScreen extends StatefulWidget {
  final int initialTabIndex;

  const ZipBizVendorDashboardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ZipBizVendorDashboardScreen> createState() =>
      _ZipBizVendorDashboardScreenState();
}

class _ZipBizVendorDashboardScreenState
    extends State<ZipBizVendorDashboardScreen> {
  int _activeTab = 0;
  int _jobSubTab = 0; // 0: Pending, 1: Accepted, 2: Completed, 3: Cancelled // 0: Overview, 1: Job Requests, 2: Wallet, 3: Listings, 4: Stats, 5: Coupons, 6: Reviews
  bool _isLoading = true;
  bool _isOnline = true;

  // Live Timer for In-Progress Services
  final Map<int, DateTime> _serviceStartTimes = {};
  final Map<int, String> _elapsedDurations = {};
  Timer? _liveJobTimer;

  // Data
  Map<String, dynamic> _dashboardStats = {};
  List<dynamic> _vendorListings = [];
  List<dynamic> _jobRequests = [];
  List<dynamic> _customerBookings = [];
  Map<String, dynamic> _walletData = {};
  List<dynamic> _reviews = [];
  Map<String, dynamic> _bookmarks = {};
  List<dynamic> _coupons = [];

  final List<String> _tabNames = [
    'Overview',
    'Job Requests',
    'Wallet',
    'Businesses',
    'Stats',
    'Coupons',
    'Reviews',
  ];

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
    _isOnline = ZipBizBookingAvailability.isAcceptingNotifier.value;
    _loadAllVendorData();
    _liveJobTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_serviceStartTimes.isNotEmpty && mounted) {
        setState(() {
          final now = DateTime.now();
          _serviceStartTimes.forEach((jobId, startTime) {
            final diff = now.difference(startTime);
            final hours = diff.inHours.toString().padLeft(2, '0');
            final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
            final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
            _elapsedDurations[jobId] = '$hours:$mins:$secs';
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _liveJobTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllVendorData() async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final statsFuture = ZipBizApiService().getVendorDashboard(user).catchError((_) => <String, dynamic>{});
      final bookingsFuture = ZipBizApiService().getVendorBookings(user: user, page: 1, perPage: 30).catchError((_) => <String, dynamic>{'items': []});
      final myListingsFuture = ZipBizApiService().getVendorListings(user: user).catchError((_) => <dynamic>[]);
      final custBookingsFuture = ZipBizApiService().getCustomerBookings(user: user).catchError((_) => <dynamic>[]);
      final walletFuture = ZipBizApiService().getVendorWallet(user).catchError((_) => <String, dynamic>{});
      final reviewsFuture = ZipBizApiService().getVendorReviews(user).catchError((_) => <dynamic>[]);
      final bookmarksFuture = ZipBizApiService().getVendorBookmarks(user).catchError((_) => <String, dynamic>{});
      final couponsFuture = ZipBizApiService().getVendorCoupons(user).catchError((_) => <dynamic>[]);

      final results = await Future.wait([
        statsFuture,
        bookingsFuture,
        myListingsFuture,
        custBookingsFuture,
        walletFuture,
        reviewsFuture,
        bookmarksFuture,
        couponsFuture,
      ]);

      if (mounted) {
        setState(() {
          _dashboardStats = results[0] as Map<String, dynamic>;
          final bData = results[1] as Map<String, dynamic>;
          _jobRequests = (bData['items'] as List?) ?? [];
          for (var j in _jobRequests) {
            final jId = j['id'];
            final jStatus = (j['status'] ?? '').toString();
            if (jId is int && jStatus == 'in_progress') {
              _serviceStartTimes[jId] ??= DateTime.now();
            }
          }
          _vendorListings = results[2] as List;
          _customerBookings = results[3] as List;
          _walletData = results[4] as Map<String, dynamic>;
          _reviews = results[5] as List;
          _bookmarks = results[6] as Map<String, dynamic>;
          _coupons = results[7] as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateJobRequest(int bookingId, String action, {String? otp}) async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;

    try {
      await ZipBizApiService().updateVendorBookingStatus(
        user: user,
        bookingId: bookingId,
        action: action,
        otp: otp,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job request #$bookingId ${action}ed!'),
          backgroundColor: (action == 'accept' || action == 'start' || action == 'complete')
              ? ZipBizColors.statusOpen
              : Colors.orange,
        ),
      );
      _loadAllVendorData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _openAddListing() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ZipBizAddEditListingScreen()),
    );
    if (res == true) {
      _loadAllVendorData();
    }
  }

  void _openEditListing(Map<String, dynamic> item) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ZipBizAddEditListingScreen(initialListing: item)),
    );
    if (res == true) {
      _loadAllVendorData();
    }
  }

  void _deleteListing(int id) async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to remove this listing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ZipBizApiService().deleteVendorListing(user: user, id: id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing moved to trash.'), backgroundColor: Colors.orange),
        );
        _loadAllVendorData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openWithdrawDialog() {
    final amountCtrl = TextEditingController();
    final upiCtrl = TextEditingController();
    String method = 'UPI';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Available Balance: ₹${_walletData["available_balance"] ?? _walletData["net_earnings"] ?? "0"}',
                  style: const TextStyle(color: ZipBizColors.primaryContainer, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Withdrawal Amount (₹) *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(labelText: 'Payout Method', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'UPI', child: Text('UPI / VPA')),
                    DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer (NEFT/IMPS)')),
                  ],
                  onChanged: (v) => setDState(() => method = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: upiCtrl,
                  decoration: InputDecoration(
                    labelText: method == 'UPI' ? 'UPI ID (e.g. mobile@upi)' : 'Account No & IFSC',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ZipBizColors.primaryContainer, foregroundColor: Colors.white),
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amt > 0 && upiCtrl.text.trim().isNotEmpty) {
                  final user = Provider.of<UserModel>(context, listen: false).user;
                  if (user == null) return;
                  Navigator.pop(ctx);
                  try {
                    await ZipBizApiService().requestVendorWithdrawal(
                      user: user,
                      amount: amt,
                      method: method,
                      details: {'account': upiCtrl.text.trim()},
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payout request submitted successfully!'), backgroundColor: ZipBizColors.statusOpen),
                    );
                    _loadAllVendorData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Withdrawal error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateCouponDialog() {
    final codeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'percent';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create Discount Coupon', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Coupon Code *', hintText: 'e.g. FESTIVE20', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Discount Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'percent', child: Text('Percentage (%)')),
                    DropdownMenuItem(value: 'fixed_cart', child: Text('Fixed Amount (₹)')),
                  ],
                  onChanged: (v) => setDState(() => type = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: type == 'percent' ? 'Discount Percentage (%) *' : 'Discount Amount (₹) *',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ZipBizColors.primaryContainer, foregroundColor: Colors.white),
              onPressed: () async {
                if (codeCtrl.text.trim().isNotEmpty && amountCtrl.text.trim().isNotEmpty) {
                  final user = Provider.of<UserModel>(context, listen: false).user;
                  if (user == null) return;
                  Navigator.pop(ctx);
                  try {
                    await ZipBizApiService().createVendorCoupon(
                      user: user,
                      data: {
                        'code': codeCtrl.text.trim(),
                        'discount_type': type,
                        'amount': amountCtrl.text.trim(),
                      },
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coupon created successfully!'), backgroundColor: ZipBizColors.statusOpen),
                    );
                    _loadAllVendorData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context).user;

    return Scaffold(
      backgroundColor: ZipBizColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B1C1E), size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
        ),
        title: const Text(
          'Vendor Dashboard',
          style: TextStyle(
            color: Color(0xFF1B1C1E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5A4136), size: 22),
            onPressed: _loadAllVendorData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllVendorData,
        color: ZipBizColors.primaryContainer,
        child: Column(
          children: [
            // Top Vendor Identity & Online Toggle
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: ZipBizColors.primaryContainer.withOpacity(0.12),
                    child: const Icon(Icons.storefront, color: ZipBizColors.primaryContainer, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'ZipBiz Partner',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ZipBizTypography.labelLarge.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isOnline ? ZipBizColors.statusOpen : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isOnline ? 'Online & Taking Bookings' : 'Paused / Offline',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isOnline ? ZipBizColors.statusOpen : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnline,
                    activeColor: ZipBizColors.statusOpen,
                    onChanged: (val) {
                      setState(() => _isOnline = val);
                      ZipBizBookingAvailability.isAcceptingNotifier.value = val;
                    },
                  ),
                ],
              ),
            ),

            // Horizontal Tab Filter Strip
            Container(
              height: 48,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: _tabNames.length,
                itemBuilder: (context, idx) {
                  final isSelected = _activeTab == idx;
                  final title = _tabNames[idx];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(title),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : ZipBizColors.onSurfaceVariant,
                      ),
                      backgroundColor: ZipBizColors.surfaceContainer,
                      selectedColor: ZipBizColors.primaryContainer,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (_) => setState(() => _activeTab = idx),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // Main Tab View Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: ZipBizColors.primaryContainer))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildCurrentTab(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_activeTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildJobRequestsTab();
      case 2:
        return _buildWalletTab();
      case 3:
        return _buildListingsTab();
      case 4:
        return _buildStatsTab();
      case 5:
        return _buildCouponsTab();
      case 6:
        return _buildReviewsTab();
      default:
        return _buildOverviewTab();
    }
  }

  // -------------------------------------------------------------
  // TAB 0: OVERVIEW (Stats + Quick Actions)
  // -------------------------------------------------------------
  Widget _buildOverviewTab() {
    final activeListings = _dashboardStats['active_listings'] ?? _vendorListings.length;
    final totalViews = _dashboardStats['total_views'] ?? 0;
    final totalReviews = _dashboardStats['total_reviews'] ?? _reviews.length;
    final totalBookmarks = _dashboardStats['total_bookmarks'] ?? _bookmarks['total'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 Primary KPI Stats (Exact User Requirement)
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                label: 'Active Businesses',
                value: '$activeListings',
                icon: Icons.list_alt,
                color: const Color(0xFF2563EB),
                onTap: () => setState(() => _activeTab = 3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                label: 'Total Views',
                value: '$totalViews',
                icon: Icons.visibility,
                color: const Color(0xFF059669),
                onTap: () => setState(() => _activeTab = 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                label: 'Reviews',
                value: '$totalReviews',
                icon: Icons.star,
                color: const Color(0xFFD97706),
                onTap: () => setState(() => _activeTab = 6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                label: 'Total Bookmarks',
                value: '$totalBookmarks',
                icon: Icons.bookmark,
                color: const Color(0xFF7C3AED),
                onTap: () => setState(() => _activeTab = 4),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Quick Shortcuts Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Operations', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 17)),
            TextButton.icon(
              icon: const Icon(Icons.add_circle, size: 18),
              label: const Text('Add Listing'),
              onPressed: _openAddListing,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionShortcut(
                title: 'View Businesses',
                icon: Icons.storefront,
                color: ZipBizColors.primaryContainer,
                onTap: () => setState(() => _activeTab = 3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionShortcut(
                title: 'Payout',
                icon: Icons.account_balance_wallet,
                color: Colors.teal,
                onTap: _openWithdrawDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionShortcut(
                title: 'New Coupon',
                icon: Icons.local_offer,
                color: Colors.purple,
                onTap: _openCreateCouponDialog,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Recent Job Requests Preview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Customer Requests', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 17)),
            TextButton(
              onPressed: () => setState(() => _activeTab = 1),
              child: const Text('View All'),
            ),
          ],
        ),
        if (_jobRequests.isEmpty)
          ZipBizCard(
            child: Row(
              children: const [
                Icon(Icons.inbox, color: Colors.grey, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Text('No pending booking requests from customers.'),
                ),
              ],
            ),
          )
        else
          ..._jobRequests.take(3).map((job) => _buildJobRequestCard(job)),
      ],
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0EDED)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: ZipBizTypography.headlineMedium.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: ZipBizTypography.bodySmall.copyWith(color: ZipBizColors.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionShortcut({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0EDED)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: MY BOOKINGS (Vendor as Customer)
  // -------------------------------------------------------------
  Widget _buildMyBookingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Bookings', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text('Bookings you placed with other ZipBiz vendors', style: ZipBizTypography.bodySmall),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: ZipBizColors.primaryFixed.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Text('${_customerBookings.length} total', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ZipBizColors.primaryContainer)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_customerBookings.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 54, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No bookings found as a customer.', style: ZipBizTypography.bodyMedium),
                  const SizedBox(height: 4),
                  Text('When you order services from other pros, they will appear here.', style: ZipBizTypography.bodySmall),
                ],
              ),
            ),
          )
        else
          ..._customerBookings.map((b) {
            final id = b['id'] ?? b['booking_id'] ?? 0;
            final title = b['listing_title'] ?? b['title'] ?? 'Home Service';
            final date = b['date'] ?? b['date_start'] ?? '';
            final time = b['time_slot'] ?? '';
            final status = b['status'] ?? 'waiting';
            final price = b['price'] ?? '0';

            return ZipBizCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('#ZB-$id', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      _buildStatusChip(status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(title, style: ZipBizTypography.labelLarge.copyWith(fontSize: 16)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.event, size: 15, color: ZipBizColors.primaryContainer),
                      const SizedBox(width: 4),
                      Text('$date $time', style: ZipBizTypography.bodySmall),
                      const Spacer(),
                      Text('₹$price', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 16, color: ZipBizColors.primary)),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB: JOB REQUESTS (Vendor receives requests & can Accept/Reject)
  // -------------------------------------------------------------
  Widget _buildJobRequestsTab() {
    final pendingJobs = _jobRequests.where((j) {
      final s = (j['status'] ?? 'waiting').toString().toLowerCase();
      return s == 'waiting' || s == 'pending';
    }).toList();

    final acceptedJobs = _jobRequests.where((j) {
      final s = (j['status'] ?? '').toString().toLowerCase();
      return s == 'confirmed' || s == 'in_progress' || s == 'accepted';
    }).toList();

    final completedJobs = _jobRequests.where((j) {
      final s = (j['status'] ?? '').toString().toLowerCase();
      return s == 'completed' || s == 'finished';
    }).toList();

    final cancelledJobs = _jobRequests.where((j) {
      final s = (j['status'] ?? '').toString().toLowerCase();
      return s == 'cancelled' || s == 'rejected' || s == 'expired';
    }).toList();

    List<dynamic> currentList;
    String emptyMessage;
    if (_jobSubTab == 0) {
      currentList = pendingJobs;
      emptyMessage = 'No pending job requests.';
    } else if (_jobSubTab == 1) {
      currentList = acceptedJobs;
      emptyMessage = 'No accepted jobs currently.';
    } else if (_jobSubTab == 2) {
      currentList = completedJobs;
      emptyMessage = 'No completed jobs yet.';
    } else {
      currentList = cancelledJobs;
      emptyMessage = 'No cancelled jobs.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer Booking Requests', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text('Accept or reject service requests for your businesses', style: ZipBizTypography.bodySmall),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text('${_jobRequests.length} total', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 4 Sub-Tabs: Pending, Accepted, Completed, Cancelled
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildJobSubTabButton(0, 'Pending', pendingJobs.length, Colors.orange),
              _buildJobSubTabButton(1, 'Accepted', acceptedJobs.length, ZipBizColors.primaryContainer),
              _buildJobSubTabButton(2, 'Completed', completedJobs.length, Colors.green),
              _buildJobSubTabButton(3, 'Cancelled', cancelledJobs.length, Colors.red),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (currentList.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.assignment_outlined, size: 54, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(emptyMessage, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
          )
        else
          ...currentList.map((job) => _buildJobRequestCard(job)),
      ],
    );
  }

  Widget _buildJobSubTabButton(int index, String label, int count, Color activeColor) {
    final isSelected = _jobSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _jobSubTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withOpacity(0.15) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? activeColor : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskAddress(String fullAddress, bool isAccepted) {
    if (fullAddress.trim().isEmpty) return 'Address not provided';
    if (isAccepted) return fullAddress;

    final parts = fullAddress.split(',');
    if (parts.length > 1) {
      const maskedFirst = '**** (Flat/House # hidden until accepted)';
      return [maskedFirst, ...parts.sublist(1).map((s) => s.trim())].join(', ');
    }
    return '**** (Flat/House # hidden until accepted), $fullAddress';
  }

  Widget _buildJobRequestCard(dynamic job) {
    final rawId = job['booking_id'] ?? job['id'] ?? 0;
    final id = int.tryParse(rawId.toString()) ?? 0;
    final customer = job['customer'] ?? {};
    final custName = job['customer_name'] ?? customer['name'] ?? 'Customer';
    final custPhone = job['customer_phone'] ?? customer['phone'] ?? '';
    final custAddress = job['customer_address'] ?? customer['address'] ?? job['address'] ?? '';
    final date = job['date'] ?? job['date_start'] ?? '';
    final time = job['time_slot'] ?? job['slot'] ?? '';
    final status = (job['status'] ?? 'waiting').toString().toLowerCase();
    final price = job['price'] ?? '0';
    final services = (job['services'] as List?) ?? [];
    final businessTitle = job['listing_title'] ?? 'Service Business';
    final instructions = job['special_instructions'] ?? job['customer_notes'] ?? job['notes'] ?? '';

    final isWaiting = (status == 'waiting' || status == 'pending');
    final isAccepted = !isWaiting && status != 'cancelled' && status != 'rejected' && status != 'expired';

    final displayAddress = _maskAddress(custAddress.toString(), isAccepted);

    return InkWell(
      onTap: () => _showJobDetailsDialog(job),
      borderRadius: BorderRadius.circular(12),
      child: ZipBizCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Job #ZB-$id', style: const TextStyle(fontWeight: FontWeight.bold, color: ZipBizColors.primaryContainer)),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: ZipBizColors.primaryContainer),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    custName.toString(),
                    style: ZipBizTypography.labelLarge.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.storefront, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Business: $businessTitle',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            if (custAddress.toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayAddress, style: ZipBizTypography.bodySmall),
                        if (isWaiting)
                          Text(
                            '(Flat/House # hidden until accepted)',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            // Customer phone hidden while waiting/pending
            if (isWaiting)
              Row(
                children: [
                  const Icon(Icons.phone_locked, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Phone unlocks upon acceptance', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                ],
              )
            else if (custPhone.toString().isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: ZipBizColors.primaryContainer),
                  const SizedBox(width: 6),
                  Text(custPhone.toString(), style: ZipBizTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Tools.launchURL('tel:$custPhone'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: ZipBizColors.primaryContainer.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Call', style: TextStyle(fontSize: 10, color: ZipBizColors.primaryContainer, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: ZipBizColors.secondary),
                const SizedBox(width: 6),
                Text('$date at $time', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ZipBizColors.secondary)),
                const Spacer(),
                Text('₹$price', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 16, color: ZipBizColors.primary)),
              ],
            ),
            if (instructions.toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Note: $instructions', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              ),
            ],
            if (status == 'in_progress')
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    const Text('Service Stopwatch: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                    Text(_elapsedDurations[id] ?? '00:00:00', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                  ],
                ),
              ),
            if (services.isNotEmpty) ...[
              const Divider(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: services.map((s) {
                  final sName = s is Map ? s['name'] : s.toString();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: ZipBizColors.surfaceSubtle, borderRadius: BorderRadius.circular(6)),
                    child: Text('$sName', style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ),
            ],
            if (isWaiting) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                      ),
                      onPressed: () => _updateJobRequest(id, 'reject'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 16),
                          SizedBox(width: 6),
                          Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZipBizColors.statusOpen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                      ),
                      onPressed: () => _updateJobRequest(id, 'accept'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 16),
                          SizedBox(width: 6),
                          Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'confirmed' || status == 'accepted') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZipBizColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                  ),
                  onPressed: () => _handleStartService(job),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, size: 18),
                      SizedBox(width: 8),
                      Text('Start Service (Enter OTP)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ] else if (status == 'in_progress') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                  ),
                  onPressed: () => _handleCompleteService(job),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done_all, size: 18),
                      SizedBox(width: 8),
                      Text('Complete Service (Enter OTP)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleStartService(dynamic job) {
    final rawId = job['booking_id'] ?? job['id'] ?? 0;
    final bId = int.tryParse(rawId.toString()) ?? 1000;
    final expectedStartOtp = job['start_otp']?.toString().trim().isNotEmpty == true
        ? job['start_otp'].toString().trim()
        : ((bId * 31 + 1729) % 9000 + 1000).toString();
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock, color: ZipBizColors.primaryContainer),
            SizedBox(width: 8),
            Text('Start Service OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ask the customer for their 4-digit Start Service OTP to verify arrival and begin the service.',
              style: TextStyle(fontSize: 13, color: ZipBizColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '••••',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: ZipBizColors.primaryContainer, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ZipBizColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
            ),
            onPressed: () async {
              final enteredOtp = otpController.text.trim();
              if (enteredOtp != expectedStartOtp) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid Start OTP! Please ask customer for correct 4-digit OTP.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              _serviceStartTimes[bId] = DateTime.now();
              await _updateJobRequest(bId, 'start', otp: enteredOtp);
            },
            child: const Text('Verify & Start', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleCompleteService(dynamic job) {
    final rawId = job['booking_id'] ?? job['id'] ?? 0;
    final bId = int.tryParse(rawId.toString()) ?? 1000;
    final expectedFinishOtp = job['finish_otp']?.toString().trim().isNotEmpty == true
        ? job['finish_otp'].toString().trim()
        : ((bId * 47 + 2468) % 9000 + 1000).toString();
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Colors.green),
            SizedBox(width: 8),
            Text('Finish Service OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ask the customer for their 4-digit Finish Service OTP to verify completion and close this job.',
              style: TextStyle(fontSize: 13, color: ZipBizColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '••••',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
            ),
            onPressed: () async {
              final enteredOtp = otpController.text.trim();
              if (enteredOtp != expectedFinishOtp) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid Finish OTP! Please ask customer for correct 4-digit OTP.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);

              // Check payment method & show COD / Online confirmation
              final isOnline = (job['payment_method']?.toString().toLowerCase() == 'razorpay' ||
                                job['payment_method']?.toString().toLowerCase() == 'online' ||
                                job['is_paid'] == true);
              final price = job['price'] ?? '0';

              _showPaymentConfirmationDialog(
                jobId: bId,
                isOnline: isOnline,
                price: price.toString(),
                otp: enteredOtp,
              );
            },
            child: const Text('Verify & Complete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPaymentConfirmationDialog({
    required int jobId,
    required bool isOnline,
    required String price,
    required String otp,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (pCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isOnline ? Icons.verified : Icons.payments,
                 color: isOnline ? Colors.green : Colors.orange),
            const SizedBox(width: 8),
            Text(isOnline ? 'Online Payment Verified' : 'Cash Collection Confirmation',
                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOnline) ...[
              const Text(
                'This service was booked with Cash on Delivery (COD).',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cash to collect:'),
                    Text('₹$price', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text('Please confirm that you have collected the cash from the customer.'),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✓ Paid Online for hours booked. Collect cash for extra time if hourly booking.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isOnline ? Colors.green : ZipBizColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(pCtx);
              _serviceStartTimes.remove(jobId);
              _elapsedDurations.remove(jobId);
              await _updateJobRequest(jobId, 'complete', otp: otp);
            },
            child: Text(
              isOnline ? 'Confirm & Close Job' : 'Confirm Cash Collected (₹$price)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showJobDetailsDialog(dynamic job) {
    final rawId = job['booking_id'] ?? job['id'] ?? 0;
    final id = int.tryParse(rawId.toString()) ?? 0;
    final customer = job['customer'] ?? {};
    final custName = job['customer_name'] ?? customer['name'] ?? 'Customer';
    final custPhone = job['customer_phone'] ?? customer['phone'] ?? '';
    final custAddress = job['customer_address'] ?? customer['address'] ?? job['address'] ?? '';
    final date = job['date'] ?? job['date_start'] ?? '';
    final time = job['time_slot'] ?? job['slot'] ?? '';
    final status = (job['status'] ?? 'waiting').toString().toLowerCase();
    final price = job['price'] ?? '0';
    final services = (job['services'] as List?) ?? [];
    final businessTitle = job['listing_title'] ?? 'Service Business';
    final instructions = job['special_instructions'] ?? job['customer_notes'] ?? job['notes'] ?? '';

    final isWaiting = (status == 'waiting' || status == 'pending');
    final isAccepted = !isWaiting && status != 'cancelled' && status != 'rejected' && status != 'expired';
    final displayAddress = _maskAddress(custAddress.toString(), isAccepted);

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Job #ZB-$id Details', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 18)),
                    _buildStatusChip(status),
                  ],
                ),
                const SizedBox(height: 16),
                _buildJobDetailRow(Icons.person, 'Customer', custName.toString()),
                _buildJobDetailRow(Icons.storefront, 'Business', businessTitle.toString()),
                if (isWaiting)
                  _buildJobDetailRow(Icons.phone_locked, 'Phone', 'Hidden until accepted', isItalic: true)
                else if (custPhone.toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.phone, size: 15, color: ZipBizColors.primaryContainer),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: Text('Phone', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(custPhone.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => Tools.launchURL('tel:$custPhone'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: ZipBizColors.primaryContainer.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Call', style: TextStyle(fontSize: 10, color: ZipBizColors.primaryContainer, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (custAddress.toString().isNotEmpty)
                  _buildJobDetailRow(
                    Icons.location_on,
                    'Address',
                    isWaiting ? '$displayAddress (Flat # hidden)' : displayAddress,
                  ),
                _buildJobDetailRow(Icons.calendar_today, 'Date & Time', '$date at $time'),
                _buildJobDetailRow(Icons.currency_rupee, 'Total Price', '₹$price', isBold: true, valueColor: ZipBizColors.primary),
                if (instructions.toString().isNotEmpty)
                  _buildJobDetailRow(Icons.note_alt_outlined, 'Instructions', instructions.toString(), isItalic: true),
                if (status == 'in_progress') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text('Active Elapsed Time: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                        Text(_elapsedDurations[id] ?? '00:00:00', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
                      ],
                    ),
                  ),
                ],
                if (services.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('SERVICES REQUESTED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ...services.map((s) {
                    final sName = s is Map ? s['name'] : s.toString();
                    final sPrice = s is Map ? s['price'] : null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('$sName', style: const TextStyle(fontSize: 13))),
                          if (sPrice != null)
                            Text('₹$sPrice', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ),
                    if (isWaiting) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ZipBizColors.statusOpen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateJobRequest(id, 'accept');
                          },
                          child: const Text('Accept Job', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else if (status == 'confirmed' || status == 'accepted') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ZipBizColors.primaryContainer,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _handleStartService(job);
                          },
                          child: const Text('Start Service', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else if (status == 'in_progress') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _handleCompleteService(job);
                          },
                          child: const Text('Complete Service', style: TextStyle(fontWeight: FontWeight.bold)),
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


  Widget _buildJobDetailRow(IconData icon, String label, String value, {bool isBold = false, bool isItalic = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: ZipBizColors.primaryContainer),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? ZipBizColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: WALLET & EARNINGS
  // -------------------------------------------------------------
  Widget _buildWalletTab() {
    final gross = _walletData['gross_earnings'] ?? '0';
    final commissionRate = _walletData['commission_rate'] ?? 20;
    final commission = _walletData['platform_commission'] ?? _walletData['commission'] ?? '0';
    final net = _walletData['net_earnings'] ?? '0';
    final available = _walletData['available_balance'] ?? net;
    final payouts = (_walletData['withdrawals'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vendor Wallet & Earnings', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 2),
        Text('Real-time ledger of gross booking revenues and payout withdrawals', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),

        // Available Balance Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ZipBizColors.primaryContainer, Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: ZipBizColors.primaryContainer.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Available Payout Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text('₹$available', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ZipBizColors.primaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                  ),
                  onPressed: _openWithdrawDialog,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward, size: 18),
                      SizedBox(width: 8),
                      Text('Request Payout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Breakdown Table
        ZipBizCard(
          child: Column(
            children: [
              _buildWalletRow('Gross Booking Earnings', '₹$gross', false),
              const Divider(),
              _buildWalletRow('Platform Commission ($commissionRate%)', '-₹$commission', true),
              const Divider(),
              _buildWalletRow('Net Realized Earnings', '₹$net', false, isBold: true),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text('Withdrawal History', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 17)),
        const SizedBox(height: 8),
        if (payouts.isEmpty)
          ZipBizCard(
            child: Row(
              children: const [
                Icon(Icons.history, color: Colors.grey),
                SizedBox(width: 10),
                Text('No payout withdrawals requested yet.'),
              ],
            ),
          )
        else
          ...payouts.map((w) {
            final wStatus = (w["status"] ?? "pending").toString().toLowerCase();
            final isPaid = wStatus == 'paid' || wStatus == 'completed';
            final statusLabel = isPaid ? 'Paid' : 'Pending Approval';
            final statusColor = isPaid ? ZipBizColors.statusOpen : Colors.orange;

            return ZipBizCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payout via ${w["payout_details"] ?? w["method"] ?? "UPI / Bank"}', style: ZipBizTypography.labelMedium),
                      Text('${w["created_at"] ?? w["date"] ?? "Recent"}', style: ZipBizTypography.bodySmall),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${w["amount"]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildWalletRow(String label, String value, bool isRed, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isRed ? Colors.red : (isBold ? ZipBizColors.primary : ZipBizColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 5: LISTINGS (Add/Edit/Delete)
  // -------------------------------------------------------------
  Widget _buildListingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Businesses', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text('Manage your business presence on ZipBiz marketplace', style: ZipBizTypography.bodySmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Center(
          child: SizedBox(
            width: 220,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ZipBizColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
              ),
              onPressed: _openAddListing,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Add Business', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_vendorListings.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.store_mall_directory_outlined, size: 54, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No businesses published yet.', style: ZipBizTypography.bodyMedium),
                  const SizedBox(height: 12),
                  ZipBizButton(text: 'Publish Your First Business', onPressed: _openAddListing),
                ],
              ),
            ),
          )
        else
          ..._vendorListings.map((item) {
            final id = item['id'] as int;
            final title = item['title'] ?? 'Listing';
            final status = item['status'] ?? 'publish';
            final views = item['views'] ?? 0;
            final rating = item['rating'] ?? 5.0;
            final img = item['featured_image']?.toString();
            // Visiting fee removed as requested

            return ZipBizCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: ZipBizColors.surfaceContainer,
                          child: (img != null && img.isNotEmpty)
                              ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.business))
                              : const Icon(Icons.business, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: ZipBizTypography.labelLarge.copyWith(fontSize: 16)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: status == 'publish' ? ZipBizColors.statusOpen.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status == 'publish' ? 'Active' : 'Pending',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: status == 'publish' ? ZipBizColors.statusOpen : Colors.orange,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.visibility, size: 13, color: Colors.grey),
                                const SizedBox(width: 3),
                                Text('$views views', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(width: 8),
                                const Icon(Icons.star, size: 13, color: Colors.amber),
                                const SizedBox(width: 3),
                                Text('$rating', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () => _deleteListing(id),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ZipBizColors.primaryContainer,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                        ),
                        onPressed: () => _openEditListing(Map<String, dynamic>.from(item)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 6),
                            Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 6: REVIEWS
  // -------------------------------------------------------------
  Widget _buildReviewsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Customer Reviews', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 2),
        Text('Ratings and feedback submitted by clients on your listings', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),
        if (_reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: const [
                  Icon(Icons.star_outline, size: 54, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No customer reviews yet.'),
                ],
              ),
            ),
          )
        else
          ..._reviews.map((r) {
            final author = r['author'] ?? 'Customer';
            final comment = r['comment'] ?? '';
            final rating = r['rating'] ?? 5;
            final listing = r['listing_title'] ?? '';
            final date = r['date'] ?? '';

            return ZipBizCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(author, style: ZipBizTypography.labelLarge),
                      Row(
                        children: List.generate(
                          5,
                          (idx) => Icon(Icons.star, size: 15, color: idx < rating ? Colors.amber : Colors.grey[300]),
                        ),
                      ),
                    ],
                  ),
                  if (listing.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('On: $listing', style: const TextStyle(fontSize: 11, color: ZipBizColors.secondary, fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 6),
                  Text(comment, style: ZipBizTypography.bodySmall),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 7: COUPONS
  // -------------------------------------------------------------
  Widget _buildCouponsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Promotional Coupons', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text('Create special discounts to attract more bookings', style: ZipBizTypography.bodySmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Center(
          child: SizedBox(
            width: 220,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ZipBizColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
              ),
              onPressed: _openCreateCouponDialog,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, size: 18),
                  SizedBox(width: 8),
                  Text('New Coupon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_coupons.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.local_offer_outlined, size: 54, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No active coupons created yet.', style: ZipBizTypography.bodyMedium),
                  const SizedBox(height: 12),
                  ZipBizButton(text: 'Create Your First Coupon', onPressed: _openCreateCouponDialog),
                ],
              ),
            ),
          )
        else
          ..._coupons.map((c) {
            final code = c['code']?.toString() ?? 'COUPON';
            final amount = c['amount']?.toString() ?? c['discount']?.toString() ?? '0';
            final type = c['discount_type']?.toString() ?? c['type']?.toString() ?? 'percent';

            return ZipBizCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type == 'percent' ? '$amount% Discount' : '₹$amount Flat Off',
                          style: ZipBizTypography.labelLarge,
                        ),
                        const Text('Valid on all your services', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: ZipBizColors.statusOpen, size: 20),
                ],
              ),
            );
          }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 8: STATS
  // -------------------------------------------------------------
  Widget _buildStatsTab() {
    final totalViews = _dashboardStats['total_views'] ?? 0;
    final totalBookings = _jobRequests.length;
    final conversion = totalViews > 0 ? ((totalBookings / totalViews) * 100).toStringAsFixed(1) : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance Analytics', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 2),
        Text('Visitor impressions, conversion rate, and engagement trends', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                label: 'Marketplace Views',
                value: '$totalViews',
                icon: Icons.trending_up,
                color: Colors.green,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                label: 'Conversion Rate',
                value: '$conversion%',
                icon: Icons.percent,
                color: Colors.indigo,
                onTap: () {},
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        Text('Businesses Breakdown', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 17)),
        const SizedBox(height: 8),
        ..._vendorListings.map((item) {
          final title = item['title'] ?? 'Listing';
          final views = item['views'] ?? 0;

          return ZipBizCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: ZipBizTypography.labelMedium)),
                Text('$views views', style: const TextStyle(fontWeight: FontWeight.bold, color: ZipBizColors.primaryContainer)),
              ],
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 9: BOOKMARKS
  // -------------------------------------------------------------
  Widget _buildBookmarksTab() {
    final total = _bookmarks['total'] ?? _dashboardStats['total_bookmarks'] ?? 0;
    final items = (_bookmarks['items'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Listing Bookmarks', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 2),
        Text('Number of times customers saved your listings to their favorites', style: ZipBizTypography.bodySmall),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.purple.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bookmark, color: Colors.purple, size: 40),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$total Total Saves', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
                  const Text('Customer bookmark interest', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Text('Saved Businesses Breakdown', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 17)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          ZipBizCard(
            child: Row(
              children: const [
                Icon(Icons.bookmark_border, color: Colors.grey),
                SizedBox(width: 10),
                Text('No specific bookmarks data recorded yet.'),
              ],
            ),
          )
        else
          ...items.map((b) {
            final title = b['title'] ?? 'Listing';
            final count = b['count'] ?? 0;

            return ZipBizCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, style: ZipBizTypography.labelMedium)),
                  Text('$count saves', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = Colors.grey.withOpacity(0.15);
    Color fg = Colors.grey;
    String label = status.toUpperCase();

    if (status == 'confirmed' || status == 'approved' || status == 'completed') {
      bg = ZipBizColors.statusOpen.withOpacity(0.15);
      fg = ZipBizColors.statusOpen;
    } else if (status == 'waiting' || status == 'pending') {
      bg = Colors.orange.withOpacity(0.15);
      fg = Colors.orange;
    } else if (status == 'in_progress') {
      bg = Colors.blue.withOpacity(0.15);
      fg = Colors.blue;
    } else if (status == 'cancelled' || status == 'rejected') {
      bg = Colors.red.withOpacity(0.15);
      fg = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
