import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/constants.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../models/user_model.dart';
import '../../routes/flux_navigate.dart';
import '../../widgets/common/zipbiz_button.dart';
import '../../widgets/common/zipbiz_card.dart';
import '../../widgets/common/zipbiz_header.dart';

class ZipBizChatScreen extends StatefulWidget {
  const ZipBizChatScreen({super.key});

  @override
  State<ZipBizChatScreen> createState() => _ZipBizChatScreenState();
}

class _ZipBizChatScreenState extends State<ZipBizChatScreen> {
  String _selectedFilter = 'all'; // 'all', 'pros', 'support'
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _conversations = [
    {
      'id': '1',
      'name': 'Rajesh Electrician',
      'service': 'Fan & Switch Repair',
      'location': 'Phase 7, Mohali',
      'lastMessage': 'I am on my way, will reach in 15 mins.',
      'time': '2 mins ago',
      'unread': 1,
      'isPro': true,
      'isOnline': true,
      'icon': Icons.bolt,
    },
    {
      'id': '2',
      'name': 'ZipBiz Support Team',
      'service': 'Booking #ZB-4912 Assistance',
      'location': 'Support Desk',
      'lastMessage': 'Your refund has been initiated and will reflect in 24 hours.',
      'time': '1 hour ago',
      'unread': 0,
      'isPro': false,
      'isOnline': true,
      'icon': Icons.support_agent,
    },
    {
      'id': '3',
      'name': 'Karan Deep Cleaners',
      'service': '2 BHK Full House Sanitization',
      'location': 'Sector 34, Chandigarh',
      'lastMessage': 'Thank you for choosing ZipBiz! Please rate our service.',
      'time': 'Yesterday',
      'unread': 0,
      'isPro': true,
      'isOnline': false,
      'icon': Icons.cleaning_services,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context).user;

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
                const Icon(Icons.chat_bubble_outline, size: 64, color: ZipBizColors.primaryContainer),
                const SizedBox(height: 16),
                Text('Messages & Support', style: ZipBizTypography.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Sign in to chat directly with your assigned technicians and ZipBiz support desk.',
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

    final filtered = _conversations.where((c) {
      if (_selectedFilter == 'pros') return c['isPro'] == true;
      if (_selectedFilter == 'support') return c['isPro'] == false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: ZipBizColors.surface,
      appBar: const ZipBizTopHeader(showBackButton: true),
      body: CustomScrollView(
        slivers: [
          // Sub-Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Messages & Support', style: ZipBizTypography.headlineMedium.copyWith(fontSize: 22)),
                      const SizedBox(height: 2),
                      Text('Stay connected with your active service pros', style: ZipBizTypography.bodySmall.copyWith(fontSize: 12)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: ZipBizColors.onSurface),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: ZipBizColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, size: 20, color: ZipBizColors.outline),
                    hintText: 'Search pros, bookings, or messages...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),

          // Filter Pills
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  _buildFilterPill('All Messages', 'all', icon: Icons.all_inbox, count: 2),
                  _buildFilterPill('Service Pros', 'pros', icon: Icons.handyman),
                  _buildFilterPill('ZipBiz Support', 'support', icon: Icons.verified_user),
                ],
              ),
            ),
          ),

          // 24/7 AI Fast Support Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ZipBizColors.secondary, Color(0xFF8B6ABF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: ZipBizColors.secondary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Need Instant Help?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: ZipBizColors.primaryContainer, borderRadius: BorderRadius.circular(10)),
                                child: const Text('24/7 AI', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text('Instant reschedule or billing resolutions', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ZipBizColors.secondary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _openChatModal('ZipBiz AI Assistant', isAi: true);
                      },
                      child: const Text('Start Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Conversations List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, idx) {
                  final conv = filtered[idx];
                  return ZipBizCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    onTap: () => _openChatModal(conv['name']),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: (conv['isPro'] as bool) ? ZipBizColors.primaryFixed : ZipBizColors.secondaryFixed,
                              child: Icon(conv['icon'] as IconData, color: (conv['isPro'] as bool) ? ZipBizColors.primary : ZipBizColors.secondary),
                            ),
                            if (conv['isOnline'] == true)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: ZipBizColors.statusOpen,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
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
                                mainAxisAlignment: MainAxisAlignment.between,
                                children: [
                                  Row(
                                    children: [
                                      Text(conv['name'], style: ZipBizTypography.labelLarge.copyWith(fontSize: 14)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified, size: 14, color: ZipBizColors.tertiary),
                                    ],
                                  ),
                                  Text(conv['time'], style: ZipBizTypography.labelSmall.copyWith(color: ZipBizColors.primary, fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: ZipBizColors.primaryFixed.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(conv['service'], style: TextStyle(fontSize: 10, color: ZipBizColors.onPrimaryFixedVariant, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text('• ${conv['location']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      conv['lastMessage'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: (conv['unread'] > 0) ? ZipBizColors.onSurface : Colors.grey.shade600,
                                        fontWeight: (conv['unread'] > 0) ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (conv['unread'] > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: const BoxDecoration(
                                        color: ZipBizColors.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text('${conv['unread']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, String key, {IconData? icon, int? count}) {
    final isSelected = (_selectedFilter == key);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : ZipBizColors.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(label),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : ZipBizColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? ZipBizColors.secondary : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : ZipBizColors.onSurfaceVariant,
        ),
        backgroundColor: ZipBizColors.surfaceContainer,
        selectedColor: ZipBizColors.secondary,
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (val) => setState(() => _selectedFilter = key),
      ),
    );
  }

  void _openChatModal(String title, {bool isAi = false}) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SizedBox(
          height: 450,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0EDED))),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isAi ? ZipBizColors.secondary : ZipBizColors.primaryContainer,
                      child: Icon(isAi ? Icons.smart_toy : Icons.person, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: ZipBizTypography.labelLarge),
                        Text(isAi ? 'Instant Bot' : 'Online', style: const TextStyle(fontSize: 10, color: ZipBizColors.statusOpen)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ZipBizColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isAi
                              ? 'Hello! I am your ZipBiz Assistant. How can I help you today with your booking or technician?'
                              : 'Hello! I am on my way to your location in Mohali.',
                          style: ZipBizTypography.bodySmall.copyWith(color: ZipBizColors.onSurface),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF0EDED))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: ZipBizColors.primaryContainer),
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          controller.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
