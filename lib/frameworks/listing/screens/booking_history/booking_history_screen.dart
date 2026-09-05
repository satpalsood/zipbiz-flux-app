import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../common/config.dart';
import '../../../../common/constants.dart';
import '../../../../models/entities/listing_booking.dart';
import '../../../../models/index.dart';
import '../../../../routes/flux_navigate.dart';
import '../../../../screens/search/widgets/search_empty_result.dart';
import 'booking_history_model.dart';
import 'widgets/booking_detail.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _selectedTab = 'ongoing'; // 'ongoing', 'completed', 'cancelled', 'all'

  List<ListingBooking> _filterBookings(List<ListingBooking> bookings) {
    if (_selectedTab == 'all') return bookings;
    return bookings.where((b) {
      final status = (b.status ?? '').toLowerCase();
      if (_selectedTab == 'ongoing') {
        return status.contains('confirm') ||
            status.contains('wait') ||
            status.contains('pend') ||
            status.contains('progress') ||
            status.contains('paid') ||
            status.isEmpty;
      }
      if (_selectedTab == 'completed') {
        return status.contains('complete') || status.contains('finish');
      }
      if (_selectedTab == 'cancelled') {
        return status.contains('cancel') || status.contains('reject');
      }
      return true;
    }).toList();
  }

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _selectedTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context).user;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFBF9F8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1B1C1C)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'My Bookings',
            style: TextStyle(
              color: Color(0xFF1B1C1C),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    size: 40,
                    color: Color(0xFFFF6B00),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Manage Your Appointments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1C1C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to track ongoing services, reschedule appointments, and view booking receipts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF1B1C1C).withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    FluxNavigate.pushNamed(
                      RouteList.login,
                      forceRootNavigator: true,
                      context: context,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign In to ZipBiz',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userId = user.id;
    return ChangeNotifierProvider<BookingHistoryModel>(
      create: (_) => BookingHistoryModel(userId),
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF9F8),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1B1C1C)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Bookings',
                style: TextStyle(
                  color: Color(0xFF1B1C1C),
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              Text(
                'Track services, manage appointments & reviews',
                style: TextStyle(
                  color: const Color(0xFF1B1C1C).withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Segmented Filter Bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildFilterChip('Ongoing', 'ongoing'),
                  _buildFilterChip('Completed', 'completed'),
                  _buildFilterChip('Cancelled', 'cancelled'),
                  _buildFilterChip('All', 'all'),
                ],
              ),
            ),
            // Bookings List (100% dynamic from WordPress REST API)
            Expanded(
              child: Consumer<BookingHistoryModel>(
                builder: (context, model, _) {
                  if (model.state == BookingHistoryState.loading) {
                    return kLoadingWidget(context);
                  }

                  final filteredBookings = _filterBookings(model.bookings);

                  if (filteredBookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No ${_selectedTab == 'all' ? '' : _selectedTab} bookings found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your scheduled services on ZipBiz will appear here',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SmartRefresher(
                    enablePullDown: true,
                    enablePullUp: true,
                    header: const WaterDropHeader(),
                    footer: CustomFooter(
                      builder: (BuildContext context, LoadStatus? mode) {
                        Widget body = const SizedBox();
                        if (model.state == BookingHistoryState.isLoadingMore) {
                          body = const CupertinoActivityIndicator();
                        }
                        if (model.state == BookingHistoryState.noMore) {
                          body = Text(
                            S.of(context).noData,
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        if (model.state == BookingHistoryState.loaded) {
                          body = Text(
                            S.of(context).pullToLoadMore,
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return SizedBox(
                          height: 55.0,
                          child: Center(child: body),
                        );
                      },
                    ),
                    controller: model.refreshController,
                    onRefresh: () => model.loadBooking(userId),
                    onLoading: () => model.loadMore(userId),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      itemBuilder: (context, index) {
                        return BookingDetail(
                          booking: filteredBookings[index],
                        );
                      },
                      itemCount: filteredBookings.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
