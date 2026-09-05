import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../common/tools/navigate_tools.dart';
import '../../frameworks/listing/screens/booking_history/booking_history_model.dart';
import '../../models/index.dart';
import '../../routes/flux_navigate.dart';
import 'layouts/setting_builder_layout.dart';

class SettingScreen extends StatefulWidget {
  final List<dynamic>? settings;
  final Map? subGeneralSetting;
  final String? background;
  final Map? drawerIcon;
  final bool hideUser;
  final bool? showBackground;
  final String? cardStyle;
  final String? settingStyle;

  const SettingScreen({
    this.settings,
    this.subGeneralSetting,
    this.background,
    this.drawerIcon,
    this.hideUser = false,
    this.showBackground,
    this.cardStyle,
    this.settingStyle,
  });

  @override
  SettingScreenState createState() {
    return SettingScreenState();
  }
}

class SettingScreenState extends State<SettingScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<SettingScreen> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0.5,
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.network(
              'https://zipbiz.in/wp-content/uploads/2025/06/zipbizlogo.png',
              height: 32,
              errorBuilder: (_, __, ___) => const Text(
                'ZipBiz',
                style: TextStyle(
                  color: Color(0xFFFF6B00),
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE4E2E1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 14, color: Color(0xFFFF6B00)),
                  SizedBox(width: 4),
                  Text(
                    'Mohali / Chandigarh',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1C1C),
                    ),
                  ),
                  Icon(Icons.expand_more, size: 14, color: Color(0xFF5A4136)),
                ],
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
      body: Consumer<UserModel>(
        builder: (context, userModel, _) {
          final user = userModel.user;
          final isLoggedIn = userModel.loggedIn && user != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLoggedIn) ...[
                  _buildUserProfileCard(context, user),
                  const SizedBox(height: 16),
                  _buildStatGrid(context, user),
                  const SizedBox(height: 16),
                  _buildReferralCard(context, user),
                ] else ...[
                  _buildGuestGreetingCard(context),
                ],
                const SizedBox(height: 20),
                _buildActivitySection(context, isLoggedIn),
                const SizedBox(height: 20),
                _buildAccountPlacesSection(context, isLoggedIn),
                const SizedBox(height: 20),
                _buildPartnerCard(context),
                const SizedBox(height: 20),
                _buildSupportPreferencesSection(context),
                const SizedBox(height: 24),
                if (isLoggedIn) ...[
                  _buildLogoutButton(context, userModel),
                  const SizedBox(height: 16),
                ],
                Center(
                  child: Text(
                    'ZipBiz v2.4.1 • Made for Tricity with Love',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserProfileCard(BuildContext context, User user) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFF0EDED),
                    backgroundImage: (user.picture?.isNotEmpty ?? false)
                        ? NetworkImage(user.picture!)
                        : null,
                    child: (user.picture?.isEmpty ?? true)
                        ? Text(
                            (user.name?.isNotEmpty ?? false)
                                ? user.name![0].toUpperCase()
                                : 'Z',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B00),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: () => FluxNavigate.pushNamed(
                        RouteList.updateUser,
                        context: context,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, size: 12, color: Colors.white),
                      ),
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
                        Flexible(
                          child: Text(
                            user.name ?? user.username ?? 'ZipBiz Member',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B1C1C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 18, color: Color(0xFF2E7D32)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (user.billing?.phone?.isNotEmpty ?? false)
                      Text(
                        user.billing!.phone!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF5A4136)),
                      ),
                    if (user.email?.isNotEmpty ?? false)
                      Text(
                        user.email!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF5A4136)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.manage_accounts, color: Color(0xFF5A4136)),
                onPressed: () => FluxNavigate.pushNamed(
                  RouteList.updateUser,
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ZipBiz Plus Member banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25005A), Color(0xFF6B4EA4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B00),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ZipBiz Plus Member',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 6),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFFFF6B00),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹150 Wallet • 3 Free Inspections Left',
                        style: TextStyle(color: Color(0xFFEADDFF), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4F3287),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Perks',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, User user) {
    return ChangeNotifierProvider<BookingHistoryModel>(
      create: (_) => BookingHistoryModel(user.id),
      child: Consumer<BookingHistoryModel>(
        builder: (context, bookingModel, _) {
          final bookingsCount = bookingModel.bookings.length;
          final wishlistCount =
              Provider.of<ProductWishListModel>(context).products.length;

          return Container(
            padding: const EdgeInsets.all(12),
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
                _buildStatItem('Bookings Done', bookingsCount.toString(), const Color(0xFFFF6B00)),
                _buildStatItem('Reviews Given', '4', const Color(0xFF6B4EA4)),
                _buildStatItem('Saved Places', '3', const Color(0xFF0062A1)),
                _buildStatItem('Wishlist', wishlistCount.toString(), const Color(0xFFFF6B00)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3F2).withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A4136),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCard(BuildContext context, User user) {
    final inviteCode =
        'ZIP${(user.username?.isNotEmpty ?? false ? user.username! : 'BIZ').toUpperCase()}99';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B00),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Earn ₹150 for every friend',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Share invite code: $inviteCode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Share.share(
                'Use my invite code $inviteCode on ZipBiz to get ₹150 off on Tricity\'s best home services! Download: https://zipbiz.in',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFF6B00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              elevation: 0,
            ),
            child: const Text(
              'Share',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestGreetingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to ZipBiz',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B1C1C),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to manage bookings, track technicians, and earn rewards across Chandigarh, Mohali & Panchkula.',
            style: TextStyle(fontSize: 13, color: Color(0xFF5A4136)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => NavigateTools.navigateToLogin(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Login / Sign Up',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context, bool isLoggedIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'MY ACTIVITY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Color(0xFF5A4136),
            ),
          ),
        ),
        Container(
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
              _buildActionTile(
                icon: Icons.receipt_long,
                iconColor: const Color(0xFFFF6B00),
                title: 'My Bookings & Orders',
                subtitle: 'Track live technician, past orders, invoices',
                badgeText: 'Live',
                onTap: () {
                  if (isLoggedIn) {
                    FluxNavigate.pushNamed(RouteList.bookingHistory, context: context);
                  } else {
                    NavigateTools.navigateToLogin(context);
                  }
                },
              ),
              const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0EDED)),
              _buildActionTile(
                icon: Icons.favorite,
                iconColor: const Color(0xFF6B4EA4),
                title: 'My Wishlist',
                subtitle: 'Saved electricians, cleaners & packages',
                onTap: () =>
                    FluxNavigate.pushNamed(RouteList.wishlist, context: context),
              ),
              const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0EDED)),
              _buildActionTile(
                icon: Icons.rate_review,
                iconColor: const Color(0xFF0062A1),
                title: 'My Reviews & Ratings',
                subtitle: 'Feedback submitted for local providers',
                onTap: () =>
                    FluxNavigate.pushNamed(RouteList.myRating, context: context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountPlacesSection(BuildContext context, bool isLoggedIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ACCOUNT & PLACES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Color(0xFF5A4136),
            ),
          ),
        ),
        Container(
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
              _buildActionTile(
                icon: Icons.badge,
                iconColor: const Color(0xFFFF6B00),
                title: 'Profile Information',
                subtitle: 'Personal details, phone, email & address',
                onTap: () {
                  if (isLoggedIn) {
                    FluxNavigate.pushNamed(RouteList.updateUser, context: context);
                  } else {
                    NavigateTools.navigateToLogin(context);
                  }
                },
              ),
              const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0EDED)),
              _buildActionTile(
                icon: Icons.pin_drop,
                iconColor: const Color(0xFFFF6B00),
                title: 'Saved Addresses',
                subtitle: 'Mohali Phase 7, Sec-17 Chd, Panchkula',
                onTap: () =>
                    FluxNavigate.pushNamed(RouteList.selectAddress, context: context),
              ),
              const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0EDED)),
              _buildActionTile(
                icon: Icons.account_balance_wallet,
                iconColor: const Color(0xFF2E7D32),
                title: 'Payment Methods & Wallet',
                subtitle: 'UPI ID, cards & ₹150 ZipBiz Cash',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF6F3F2),
            const Color(0xFFEADDFF).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADDFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4EA4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PARTNER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Join as Professional',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF25005A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Grow your repair, plumbing, or salon business across Tricity.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5A4136)),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () =>
                      Tools.launchURL('https://zipbiz.in/add-listing/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EA4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('List Your Service', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://zipbiz.in/wp-content/uploads/2025/06/zipbizlogo.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.handyman, color: Color(0xFFFF6B00)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportPreferencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'SUPPORT & PREFERENCES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Color(0xFF5A4136),
            ),
          ),
        ),
        Container(
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
              _buildActionTile(
                icon: Icons.headset_mic,
                iconColor: const Color(0xFF0062A1),
                title: 'Help & Customer Support',
                subtitle: 'FAQs, Live Chat, Toll-Free: 7009218289',
                onTap: () => Tools.launchURL('tel:+917009218289'),
              ),
              const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0EDED)),
              _buildActionTile(
                icon: Icons.tune,
                iconColor: const Color(0xFF5A4136),
                title: 'Settings & Notifications',
                subtitle: 'Push notifications, privacy, sound',
                onTap: () =>
                    FluxNavigate.pushNamed(RouteList.notify, context: context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, UserModel userModel) {
    return OutlinedButton(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Log Out'),
            content: const Text('Are you sure you want to log out of ZipBiz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Log Out', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed ?? false) {
          userModel.logout();
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFBA1A1A),
        backgroundColor: const Color(0xFFFFDAD6).withOpacity(0.4),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, size: 20),
          SizedBox(width: 8),
          Text(
            'Log Out',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFEAE8E7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B1C1C),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF5A4136)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDBCC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Color(0xFF7A3000),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right, size: 20, color: Color(0xFF8E7164)),
        ],
      ),
    );
  }
}
