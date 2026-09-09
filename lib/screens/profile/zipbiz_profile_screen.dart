import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../common/constants.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../models/user_model.dart';
import '../../routes/flux_navigate.dart';
import '../../vendor/dashboard/zipbiz_vendor_dashboard_screen.dart';
import '../../widgets/common/zipbiz_badge.dart';
import '../../widgets/common/zipbiz_button.dart';
import '../../widgets/common/zipbiz_card.dart';
import '../../widgets/common/zipbiz_header.dart';

class ZipBizProfileScreen extends StatelessWidget {
  const ZipBizProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    final user = userModel.user;
    final isLoggedIn = (user != null);

    final isVendor = isLoggedIn && (user.isVender || (user.role ?? '').toLowerCase() == 'owner');

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
                  ? Row(
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
                      ],
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
            const SizedBox(height: 12),

            // ZipBiz Plus Membership Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF25005A), ZipBizColors.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: ZipBizColors.secondary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: ZipBizColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('ZipBiz Plus Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: ZipBizColors.primaryContainer, borderRadius: BorderRadius.circular(10)),
                              child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text('₹150 Wallet • Free Inspections', style: TextStyle(color: ZipBizColors.secondaryFixed, fontSize: 11)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ZipBizColors.secondary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {},
                    child: const Text('Perks', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stats Row (4 metrics)
            Row(
              children: [
                _buildStatBox('6', 'Bookings', ZipBizColors.primaryContainer),
                const SizedBox(width: 8),
                _buildStatBox('4', 'Reviews', ZipBizColors.secondary),
                const SizedBox(width: 8),
                _buildStatBox('3', 'Saved', ZipBizColors.tertiary),
                const SizedBox(width: 8),
                _buildStatBox('5', 'Wishlist', ZipBizColors.primary),
              ],
            ),
            const SizedBox(height: 14),

            // Partner Portal / Vendor Mode Switch (Crucial Feature!)
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
            ] else ...[
              // Partner recruitment banner for customers
              ZipBizCard(
                color: ZipBizColors.surfaceContainerLowest,
                onTap: () {},
                child: Row(
                  children: [
                    const Icon(Icons.handyman, color: ZipBizColors.secondary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Partner With ZipBiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Are you a technician? List your services & grow your business', style: ZipBizTypography.bodySmall.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Referral Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ZipBizColors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.campaign, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Earn ₹150 for every friend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Invite code: ZIPAMAN99', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ZipBizColors.primaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Share.share('Use my code ZIPAMAN99 on ZipBiz to get ₹150 off on home services! Download: https://zipbiz.in');
                    },
                    child: const Text('Share', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // My Activity Section
            Text('MY ACTIVITY', style: ZipBizTypography.labelSmall.copyWith(letterSpacing: 1.2, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            ZipBizCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildListTile(
                    Icons.receipt_long,
                    'My Bookings & Orders',
                    'Track live technician & past invoices',
                    trailingBadge: 'Active',
                    onTap: () => FluxNavigate.pushNamed(RouteList.bookingHistory, context: context),
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    Icons.location_on_outlined,
                    'Saved Addresses',
                    'Manage home, office & clinic service locations',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    Icons.rate_review_outlined,
                    'My Reviews & Ratings',
                    'View feedback given to technicians',
                    onTap: () {},
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
                  const Divider(height: 1),
                  _buildListTile(
                    Icons.language,
                    'Region & Language',
                    'Tricity (Mohali, Chandigarh, Panchkula) • English',
                    onTap: () {},
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
                    Icons.help_outline,
                    'Help Center & FAQs',
                    'Instant answers to booking & payment queries',
                    onTap: () => FluxNavigate.pushNamed(RouteList.chat, context: context),
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    Icons.shield_outlined,
                    'Privacy Policy & Terms',
                    'Read ZipBiz terms of service and compliance',
                    onTap: () {},
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
                  label: const Text('Sign Out from ZipBiz', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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

  Widget _buildStatBox(String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: ZipBizColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: ZipBizColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
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
