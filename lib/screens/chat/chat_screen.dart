import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../frameworks/listing/screens/booking_history/booking_history_model.dart';
import '../../models/entities/listing_booking.dart';
import '../../models/user_model.dart';
import '../../routes/flux_navigate.dart';
import '../../services/services.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _selectedFilter = 'all'; // 'all', 'pros', 'support'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userModel = Provider.of<UserModel>(context);
    final user = userModel.user;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0.5,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              errorBuilder: (_, __, ___) => const Icon(Icons.business),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ZipBiz',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                    letterSpacing: 0.8,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 13,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Mohali / Chandigarh',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () => FluxNavigate.pushNamed(RouteList.notify, context: context),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: theme.primaryColor.withOpacity(0.15),
                child: Text(
                  (user.name?.isNotEmpty ?? false) ? user.name![0].toUpperCase() : 'U',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.primaryColor),
                ),
              ),
            ),
        ],
      ),
      body: user == null
          ? _buildUnauthenticatedView(context, theme)
          : ChangeNotifierProvider<BookingHistoryModel>(
              create: (_) => BookingHistoryModel(user.id),
              child: Consumer<BookingHistoryModel>(
                builder: (context, bookingModel, _) {
                  return RefreshIndicator(
                    onRefresh: () => bookingModel.getBooking(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Context
                          Row(
                            mainAxisAlignment: MainAxisAlignment.between,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Messages & Support',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Stay connected with your active service pros',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Search Box
                          Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                              decoration: InputDecoration(
                                hintText: 'Search pros, bookings, or messages...',
                                hintStyle: TextStyle(fontSize: 13, color: theme.hintColor),
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Filter Pills
                          _buildFilterPills(theme, bookingModel.bookings),
                          const SizedBox(height: 14),

                          // AI Instant Help Banner Card
                          _buildAiHelpBanner(context, theme),
                          const SizedBox(height: 16),

                          // Live Conversations / Bookings List
                          _buildConversationsList(context, theme, bookingModel),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildFilterPills(ThemeData theme, List<ListingBooking> bookings) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill(
            label: 'All Messages',
            key: 'all',
            count: bookings.length + 1, // Includes Support
            icon: Icons.all_inbox,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildPill(
            label: 'Service Pros',
            key: 'pros',
            count: bookings.length,
            icon: Icons.build_circle_outlined,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildPill(
            label: 'ZipBiz Support',
            key: 'support',
            count: 1,
            icon: Icons.verified_user_outlined,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required String key,
    required int count,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : theme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiHelpBanner(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4EA4), Color(0xFF52358A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EA4).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Need Instant Help?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '24/7 AI',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Chat with ZipBiz Bot for prompt reschedule or billing queries',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              await Tools.launchURL('https://zipbiz.in/contact/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6B4EA4),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Start Chat',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(
    BuildContext context,
    ThemeData theme,
    BookingHistoryModel bookingModel,
  ) {
    if (bookingModel.state == BookingHistoryModelState.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    var bookings = bookingModel.bookings;

    if (_searchQuery.isNotEmpty) {
      bookings = bookings.where((b) {
        final title = (b.title ?? '').toLowerCase();
        final id = (b.id ?? '').toLowerCase();
        final status = (b.status ?? '').toLowerCase();
        return title.contains(_searchQuery) || id.contains(_searchQuery) || status.contains(_searchQuery);
      }).toList();
    }

    final showPros = _selectedFilter == 'all' || _selectedFilter == 'pros';
    final showSupport = _selectedFilter == 'all' || _selectedFilter == 'support';

    return Column(
      children: [
        // ZipBiz Support Team Conversation Card
        if (showSupport)
          _buildSupportCard(context, theme),

        // Service Pro Booking Conversations
        if (showPros) ...[
          if (bookings.isEmpty && _selectedFilter == 'pros')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: Center(
                child: Text(
                  'No active service appointments found',
                  style: TextStyle(color: theme.hintColor, fontSize: 13),
                ),
              ),
            )
          else
            for (final booking in bookings)
              _buildBookingConversationCard(context, theme, booking),
        ],
      ],
    );
  }

  Widget _buildSupportCard(BuildContext context, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.primaryColor.withOpacity(0.15),
              child: Icon(Icons.support_agent, color: theme.primaryColor, size: 24),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'ZipBiz Support Team',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.verified, size: 15, color: theme.primaryColor),
            const SizedBox(width: 6),
            const Text(
              'Online',
              style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Text(
            'Official concierge for service guarantee, refunds & queries',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.chat_bubble_outline, color: theme.primaryColor),
          onPressed: () async {
            await Tools.launchURL('https://zipbiz.in/contact/');
          },
        ),
        onTap: () async {
          await Tools.launchURL('https://zipbiz.in/contact/');
        },
      ),
    );
  }

  Widget _buildBookingConversationCard(
    BuildContext context,
    ThemeData theme,
    ListingBooking booking,
  ) {
    final status = (booking.status ?? '').toLowerCase();
    Color statusColor = Colors.orange;
    if (status.contains('confirm') || status.contains('paid') || status.contains('complete')) {
      statusColor = const Color(0xFF2E7D32);
    } else if (status.contains('cancel') || status.contains('reject')) {
      statusColor = const Color(0xFFD32F2F);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.primaryColor.withOpacity(0.12),
                      child: Icon(Icons.handyman_outlined, color: theme.primaryColor, size: 22),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.title?.isNotEmpty ?? false
                                  ? booking.title!
                                  : 'Service Booking #${booking.id}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (booking.status ?? 'Active').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 12, color: theme.colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            booking.created ?? 'Recent appointment',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.secondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Booking #${booking.id} • Connect with technician regarding schedule or service details',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await Tools.launchURL('https://zipbiz.in/contact/');
                  },
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Help', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.secondary),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Tools.launchURL('https://zipbiz.in');
                  },
                  icon: const Icon(Icons.chat, size: 15),
                  label: const Text('Message Pro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sign In to View Messages',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect directly with verified service professionals, discuss project requirements, and track active bookings in real-time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  NavigateTools.navigateToLogin(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Log In to Continue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
