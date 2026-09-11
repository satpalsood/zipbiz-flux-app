import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:provider/provider.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../data/boxes.dart';
import '../../models/entities/address.dart';
import '../../models/entities/listing_booking.dart';
import '../../models/user_model.dart';
import '../../routes/flux_navigate.dart';
import '../../services/index.dart';
import '../../vendor/dashboard/zipbiz_vendor_dashboard_screen.dart';
import '../../widgets/common/zipbiz_badge.dart';
import '../../widgets/common/zipbiz_button.dart';
import '../../widgets/common/zipbiz_card.dart';
import '../../widgets/common/zipbiz_header.dart';
import 'zipbiz_bookmarks_screen.dart';
import 'zipbiz_edit_profile_screen.dart';

class ZipBizProfileScreen extends StatefulWidget {
  const ZipBizProfileScreen({super.key});

  @override
  State<ZipBizProfileScreen> createState() => _ZipBizProfileScreenState();
}

class _ZipBizProfileScreenState extends State<ZipBizProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    final user = userModel.user;
    final isLoggedIn = (user != null);
    final isVendor = isLoggedIn && (user.isVender || (user.role ?? '').toLowerCase() == 'owner');
    final addresses = UserBox().addresses;

    return Scaffold(
      backgroundColor: ZipBizColors.surface,
      appBar: const ZipBizTopHeader(showBackButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Profile Card
            ZipBizCard(
              child: isLoggedIn
                  ? InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ZipBizEditProfileScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: ZipBizColors.primaryContainer,
                                backgroundImage: (user.picture != null && user.picture!.isNotEmpty)
                                    ? NetworkImage(user.picture!)
                                    : null,
                                child: (user.picture == null || user.picture!.isEmpty)
                                    ? const Icon(Icons.person, size: 36, color: Colors.white)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: ZipBizColors.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, size: 12, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user.fullName.isNotEmpty ? user.fullName : (user.username ?? 'ZipBiz User'),
                                        style: ZipBizTypography.headlineMedium.copyWith(fontSize: 18),
                                      ),
                                    ),
                                    const Icon(Icons.verified, size: 18, color: ZipBizColors.statusOpen),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  user.phoneNumber?.isNotEmpty == true ? user.phoneNumber! : '+91 98765 43210',
                                  style: ZipBizTypography.bodySmall,
                                ),
                                Text(
                                  user.email ?? 'user@zipbiz.in',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ZipBizTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        const Icon(Icons.account_circle, size: 60, color: ZipBizColors.primaryContainer),
                        const SizedBox(height: 8),
                        Text('Welcome to ZipBiz', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('Sign in to manage bookings, view partner portal, and save addresses', textAlign: TextAlign.center, style: ZipBizTypography.bodySmall),
                        const SizedBox(height: 14),
                        ZipBizButton(
                          text: 'Sign In / Register',
                          onPressed: () => FluxNavigate.pushNamed(RouteList.login, context: context),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),

            // Partner Portal / Vendor Mode Switch (Strictly for Vendors)
            if (isVendor) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ZipBizColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ZipBizColors.primaryContainer, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: ZipBizColors.primaryContainer.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ZipBizColors.primaryFixed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront, color: ZipBizColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Service Partner Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ZipBizColors.onSurface)),
                          const SizedBox(height: 2),
                          Text('Manage appointments, accept jobs & track earnings', style: ZipBizTypography.bodySmall.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    ZipBizButton(
                      text: 'Dashboard',
                      height: 36,
                      borderRadius: 8,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ZipBizVendorDashboardScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 20),

            // My Activity Section
            Text('MY ACTIVITY', style: ZipBizTypography.labelSmall.copyWith(letterSpacing: 1.2, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            ZipBizCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (isLoggedIn) ...[
                    _buildListTile(
                      Icons.person_outline,
                      'My Profile',
                      'Manage name, phone, email & change password',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ZipBizEditProfileScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  _buildListTile(
                    Icons.bookmark_border,
                    'My Bookmarks',
                    'Saved services & favorite businesses',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ZipBizBookmarksScreen()),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    Icons.receipt_long,
                    'My Bookings & Orders',
                    'Track live technician & past invoices',
                    onTap: () => FluxNavigate.pushNamed(RouteList.bookingHistory, context: context),
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    Icons.location_on_outlined,
                    'Saved Addresses',
                    '${addresses.length} saved location${addresses.length == 1 ? '' : 's'} • Manage & add address',
                    onTap: () => _showSavedAddressesSheet(context),
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    Icons.rate_review_outlined,
                    'My Reviews & Ratings',
                    'View feedback given to technicians',
                    onTap: () => _showReviewsSheet(context, user),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preferences & Settings
            Text('PREFERENCES', style: ZipBizTypography.labelSmall.copyWith(letterSpacing: 1.2, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            ZipBizCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildListTile(
                    Icons.notifications_outlined,
                    'Push Notifications',
                    'Booking alerts, dispatch updates & offers',
                    onTap: () => FluxNavigate.pushNamed(RouteList.notify, context: context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Support & Legal
            Text('SUPPORT & LEGAL', style: ZipBizTypography.labelSmall.copyWith(letterSpacing: 1.2, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            ZipBizCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildListTile(
                    Icons.headset_mic_outlined,
                    'Customer Support & WhatsApp',
                    'Instant help on WhatsApp or Call +91 70092 18289',
                    onTap: _openWhatsAppSupport,
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    Icons.shield_outlined,
                    'Privacy Policy',
                    'Read ZipBiz privacy policy online',
                    onTap: () => Tools.launchURL('https://zipbiz.in/privacy-policy/'),
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    Icons.gavel_outlined,
                    'Terms & Conditions',
                    'Read ZipBiz marketplace terms of service',
                    onTap: () => Tools.launchURL('https://zipbiz.in/terms-and-conditions/'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sign Out / Delete Account
            if (isLoggedIn)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                  label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await userModel.logout();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }


  void _openWhatsAppSupport() {
    Tools.launchURL('https://wa.me/917009218289?text=${Uri.encodeComponent("Hello ZipBiz Support, I need assistance with my service booking.")}');
  }

  void _showSavedAddressesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomSheetContext, setModalState) {
            final list = UserBox().addresses;
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saved Addresses (${list.length})', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text('No Saved Addresses', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 16, color: Colors.grey.shade700)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Add your home or workplace address for seamless booking',
                                    textAlign: TextAlign.center,
                                    style: ZipBizTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final addr = list[idx];
                              final title = (addr.firstName != null && addr.firstName!.isNotEmpty) ? addr.firstName! : 'Address ${idx + 1}';
                              final addressLines = [
                                addr.street,
                                addr.block,
                                addr.city,
                                addr.zipCode,
                              ].where((s) => s != null && s.isNotEmpty).join(', ');

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ZipBizColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: ZipBizColors.primaryFixed,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.location_on, color: ZipBizColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 3),
                                          Text(
                                            addressLines.isNotEmpty ? addressLines : 'Mohali / Chandigarh',
                                            style: ZipBizTypography.bodySmall.copyWith(fontSize: 12),
                                          ),
                                          if (addr.phoneNumber != null && addr.phoneNumber!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Phone: ${addr.phoneNumber}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () {
                                        final updated = List<Address>.from(UserBox().addresses);
                                        updated.removeAt(idx);
                                        UserBox().addresses = updated;
                                        setModalState(() {});
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2)),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('+ Add Another Address', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ZipBizColors.primaryContainer,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          _showAddAddressDialog(context, () {
                            setModalState(() {});
                            setState(() {});
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddAddressDialog(BuildContext context, VoidCallback onSaved) {
    final nameController = TextEditingController();
    final streetController = TextEditingController();
    final cityController = TextEditingController(text: 'Mohali');
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Address Label / Name *',
                  hintText: 'e.g. Home, Office, Aman',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: streetController,
                decoration: const InputDecoration(
                  labelText: 'House / Flat / Street / Society *',
                  hintText: 'e.g. Flat 302, Phase 7',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City / Area *',
                  hintText: 'Mohali, Chandigarh, Panchkula',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone Number',
                  hintText: 'e.g. 9876543210',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ZipBizColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (streetController.text.trim().isEmpty) return;
              final newAddr = Address(
                firstName: nameController.text.trim().isNotEmpty ? nameController.text.trim() : 'Saved Address',
                street: streetController.text.trim(),
                city: cityController.text.trim().isNotEmpty ? cityController.text.trim() : 'Mohali',
                phoneNumber: phoneController.text.trim(),
                country: 'India',
              );
              final current = List<Address>.from(UserBox().addresses);
              current.add(newAddr);
              UserBox().addresses = current;
              Navigator.pop(ctx);
              onSaved();
            },
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }

  void _showReviewsSheet(BuildContext context, dynamic user) {
    if (user == null) {
      FluxNavigate.pushNamed(RouteList.login, context: context);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Reviews & Ratings', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 18)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<ListingBooking>?>(
                  future: Services().api.getBooking(userId: user.id, page: 1, perPage: 20),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: ZipBizColors.primaryContainer));
                    }
                    final bookings = snapshot.data ?? [];
                    final completed = bookings.where((b) => (b.status ?? '').toLowerCase().contains('complete')).toList();

                    if (completed.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  color: ZipBizColors.surfaceContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.rate_review_outlined, size: 44, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text('No Reviews Yet', style: ZipBizTypography.headlineSmall.copyWith(fontSize: 17, color: Colors.grey.shade800)),
                              const SizedBox(height: 6),
                              Text(
                                'You haven\'t rated any completed services yet. Once your home services are completed, you can rate and review your providers here.',
                                textAlign: TextAlign.center,
                                style: ZipBizTypography.bodySmall.copyWith(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ZipBizColors.primaryContainer,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  FluxNavigate.pushNamed(RouteList.category, context: context);
                                },
                                child: const Text('Explore Services'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: completed.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final booking = completed[idx];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: ZipBizColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(booking.title ?? 'Service Appointment', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: ZipBizColors.statusOpen.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Completed', style: TextStyle(fontSize: 10, color: ZipBizColors.statusOpen, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => const Icon(Icons.star, size: 16, color: Colors.amber),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Service successfully verified & completed on ZipBiz.', style: ZipBizTypography.bodySmall.copyWith(fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle, {String? trailingBadge, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ZipBizColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ZipBizColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingBadge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: ZipBizColors.primaryFixed, borderRadius: BorderRadius.circular(10)),
              child: Text(trailingBadge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ZipBizColors.onPrimaryFixedVariant)),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
