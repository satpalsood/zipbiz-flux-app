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
  int _activeTab = 0; // 0: Overview, 1: Job Requests, 2: Wallet, 3: Listings, 4: Stats, 5: Coupons, 6: Reviews
  bool _isLoading = true;
  bool _isOnline = true;

  // Data
  Map<String, dynamic> _dashboardStats = {};
  List<dynamic> _vendorListings = [];
  List<dynamic> _jobRequests = [];
  List<dynamic> _customerBookings = [];
  List<dynamic> _conversations = [];
  Map<String, dynamic> _walletData = {};
  List<dynamic> _reviews = [];
  Map<String, dynamic> _bookmarks = {};
  List<dynamic> _coupons = [];

  final List<String> _tabNames = [
    'Overview',
    'Job Requests',
    'Wallet',
    'Listings',
    'Stats',
    'Coupons',
    'Reviews',
  ];

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
    _loadAllVendorData();
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
      final convsFuture = ZipBizApiService().getConversations(user).catchError((_) => <dynamic>[]);
      final walletFuture = ZipBizApiService().getVendorWallet(user).catchError((_) => <String, dynamic>{});
      final reviewsFuture = ZipBizApiService().getVendorReviews(user).catchError((_) => <dynamic>[]);
      final bookmarksFuture = ZipBizApiService().getVendorBookmarks(user).catchError((_) => <String, dynamic>{});
      final couponsFuture = ZipBizApiService().getVendorCoupons(user).catchError((_) => <dynamic>[]);

      final results = await Future.wait([
        statsFuture,
        bookingsFuture,
        myListingsFuture,
        custBookingsFuture,
        convsFuture,
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
          _vendorListings = results[2] as List;
          _customerBookings = results[3] as List;
          _conversations = results[4] as List;
          _walletData = results[5] as Map<String, dynamic>;
          _reviews = results[6] as List;
          _bookmarks = results[7] as Map<String, dynamic>;
          _coupons = results[8] as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateJobRequest(int bookingId, String action) async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;

    try {
      await ZipBizApiService().updateVendorBookingStatus(
        user: user,
        bookingId: bookingId,
        action: action,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job request #$bookingId ${action}ed!'),
          backgroundColor: action == 'accept' ? ZipBizColors.statusOpen : Colors.orange,
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
                    onChanged: (val) => setState(() => _isOnline = val),
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
                label: 'Active Listings',
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
                title: 'New Listing',
                icon: Icons.add_business,
                color: ZipBizColors.primaryContainer,
                onTap: _openAddListing,
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
  // TAB 2: MESSAGES (Customer <-> Vendor Chat)
  // -------------------------------------------------------------
  Widget _buildMessagesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer Messages', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text('Chat directly with clients about their service requests', style: ZipBizTypography.bodySmall),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: ZipBizColors.primaryContainer),
              onPressed: _loadAllVendorData,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_conversations.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.forum_outlined, size: 54, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No customer inquiries yet.', style: ZipBizTypography.bodyMedium),
                  const SizedBox(height: 4),
                  Text('When clients message you from your listings, chats will appear here.', style: ZipBizTypography.bodySmall),
                ],
              ),
            ),
          )
        else
          ..._conversations.map((c) {
            final pid = int.tryParse('${c["user_id"] ?? c["id"]}') ?? 0;
            final name = c['name'] ?? 'ZipBiz Customer';
            final avatar = c['avatar']?.toString();
            final lastMsg = c['last_message'] ?? 'No message yet';
            final time = c['time'] ?? '';
            final unread = int.tryParse('${c["unread"]}') ?? 0;
            final service = c['service'] ?? '';

            return ZipBizCard(
              margin: const EdgeInsets.only(bottom: 10),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ZipBizChatDetailScreen(
                      recipientId: pid,
                      recipientName: name,
                      recipientAvatar: avatar,
                      listingTitle: service,
                    ),
                  ),
                ).then((_) => _loadAllVendorData());
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ZipBizColors.primaryContainer.withOpacity(0.15),
                    backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
                    child: (avatar == null || avatar.isEmpty)
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'C', style: const TextStyle(color: ZipBizColors.primaryContainer, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name, style: ZipBizTypography.labelLarge.copyWith(fontSize: 15)),
                            if (time.isNotEmpty)
                              Text(time.contains(' ') ? time.split(' ')[0] : time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        if (service.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(service, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: ZipBizColors.secondary, fontWeight: FontWeight.bold)),
                        ],
                        const SizedBox(height: 4),
                        Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: ZipBizTypography.bodySmall),
                      ],
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: JOB REQUESTS (Vendor receives requests & can Accept/Reject)
  // -------------------------------------------------------------
  Widget _buildJobRequestsTab() {
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
                Text('Accept or reject service requests for your listings', style: ZipBizTypography.bodySmall),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text('${_jobRequests.length} requests', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_jobRequests.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: const [
                  Icon(Icons.assignment_outlined, size: 54, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No job requests currently pending.'),
                ],
              ),
            ),
          )
        else
          ..._jobRequests.map((job) => _buildJobRequestCard(job)),
      ],
    );
  }

  Widget _buildJobRequestCard(dynamic job) {
    final id = job['id'] ?? 0;
    final customer = job['customer'] ?? {};
    final custName = customer['name'] ?? 'Customer';
    final custPhone = customer['phone'] ?? '';
    final custAddress = customer['address'] ?? '';
    final date = job['date'] ?? '';
    final time = job['time_slot'] ?? '';
    final status = job['status'] ?? 'waiting';
    final price = job['price'] ?? '0';
    final services = (job['services'] as List?) ?? [];

    final isWaiting = (status == 'waiting' || status == 'pending');

    return ZipBizCard(
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
          Text(custName, style: ZipBizTypography.labelLarge.copyWith(fontSize: 16)),
          if (custAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text(custAddress, style: ZipBizTypography.bodySmall)),
              ],
            ),
          ],
          if (custPhone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(custPhone, style: ZipBizTypography.bodySmall),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: ZipBizColors.secondary),
              const SizedBox(width: 4),
              Text('$date at $time', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ZipBizColors.secondary)),
              const Spacer(),
              Text('₹$price', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 16, color: ZipBizColors.primary)),
            ],
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
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    onPressed: () => _updateJobRequest(id, 'reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZipBizColors.statusOpen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    onPressed: () => _updateJobRequest(id, 'accept'),
                  ),
                ),
              ],
            ),
          ] else if (status == 'confirmed') ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ZipBizColors.primaryContainer,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Start Service'),
              onPressed: () => _updateJobRequest(id, 'start'),
            ),
          ] else if (status == 'in_progress') ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Mark Complete'),
              onPressed: () => _updateJobRequest(id, 'complete'),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: WALLET & EARNINGS
  // -------------------------------------------------------------
  Widget _buildWalletTab() {
    final gross = _walletData['gross_earnings'] ?? '0';
    final commission = _walletData['platform_commission'] ?? '0';
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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: ZipBizColors.primaryContainer),
                icon: const Icon(Icons.arrow_upward, size: 16),
                label: const Text('Request Payout / Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _openWithdrawDialog,
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
              _buildWalletRow('Platform Commission (10%)', '-₹$commission', true),
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
            return ZipBizCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payout via ${w["method"] ?? "UPI"}', style: ZipBizTypography.labelMedium),
                      Text('${w["date"] ?? "Recent"}', style: ZipBizTypography.bodySmall),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${w["amount"]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${w["status"] ?? "completed"}', style: const TextStyle(color: ZipBizColors.statusOpen, fontSize: 11, fontWeight: FontWeight.bold)),
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
                Text('My Listings', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text('Manage your business presence on ZipBiz marketplace', style: ZipBizTypography.bodySmall),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: ZipBizColors.primaryContainer, foregroundColor: Colors.white),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Listing'),
              onPressed: _openAddListing,
            ),
          ],
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
                  Text('No listings published yet.', style: ZipBizTypography.bodyMedium),
                  const SizedBox(height: 12),
                  ZipBizButton(text: 'Publish Your First Listing', onPressed: _openAddListing),
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
            final visitFee = item['visiting_fee'] ?? '149';

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
                            const SizedBox(height: 4),
                            Text('Visiting Fee: ₹$visitFee', style: ZipBizTypography.bodySmall),
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
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: ZipBizColors.primaryContainer, foregroundColor: Colors.white),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        onPressed: () => _openEditListing(Map<String, dynamic>.from(item)),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: ZipBizColors.primaryContainer, foregroundColor: Colors.white),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Coupon'),
              onPressed: _openCreateCouponDialog,
            ),
          ],
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
            final code = c['code'] ?? 'COUPON';
            final amount = c['amount'] ?? '0';
            final type = c['discount_type'] ?? 'percent';

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
        Text('Listings Breakdown', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 17)),
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
        Text('Saved Listings Breakdown', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 17)),
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
