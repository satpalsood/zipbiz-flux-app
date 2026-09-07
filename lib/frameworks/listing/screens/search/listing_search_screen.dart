import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import '../../../../app.dart';
import '../../../../common/constants.dart';
import '../../../../models/index.dart';
import '../../../../routes/flux_navigate.dart';
import '../../../../screens/common/app_bar_mixin.dart';
import '../../../../widgets/common/zipbiz_header.dart';
import '../../widgets/category_horizon.dart';
import '../../widgets/recent_list.dart';
import '../map/map_screen.dart';

/// Search Screen
class ListingSearchScreen extends StatefulWidget {
  @override
  ListingSearchScreenState createState() => ListingSearchScreenState();
}

class ListingSearchScreenState extends State<ListingSearchScreen>
    with
        AutomaticKeepAliveClientMixin,
        SingleTickerProviderStateMixin,
        AppBarMixin {
  TextEditingController? textController;
  FocusNode? _focus;
  String? searchText;
  String _selectedFilter = 'all';
  String _selectedRegion = 'Mohali / Chandigarh';

  late Animation<double> animation;
  late AnimationController controller;

  Future<bool> requestLocation() async {
    var location = Location();

    bool serviceEnabled;
    // PermissionStatus _permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    var allow = await location.hasPermission();
    if (allow == PermissionStatus.denied) {
      allow = await location.requestPermission();
      if (allow != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    textController = TextEditingController();
    animation = Tween<double>(begin: 0, end: 50).animate(controller);
    animation.addListener(_animationListener);
    // focus change
    _focus = FocusNode();
    _focus!.addListener(_onFocusChange);
  }

  void _animationListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFocusChange() {
    if (_focus!.hasFocus && animation.value == 0) {
      controller.forward();
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    animation.removeListener(_animationListener);
    controller.dispose();
    textController!.dispose();
    super.dispose();
  }

  AppBar? renderAppBar() {
    if (Navigator.canPop(context)) {
      return AppBar(
        elevation: 0.1,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          S.of(context).search,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        leading: Navigator.of(context).canPop()
            ? Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios,
                  ),
                ),
              )
            : const SizedBox(),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final search = Provider.of<SearchModel>(context);

    return renderScaffold(
      routeName: RouteList.search,
      disableSafeArea: true,
      secondAppBar: null,
      floatingActionButton: FloatingActionButton(
        heroTag: 'location',
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () async {
          var grantPermission = await requestLocation();

          if (grantPermission) {
            await FluxNavigate.push(
              MaterialPageRoute(
                builder: (BuildContext context) => isMacOS ||
                        isWindow ||
                        isFuchsia
                    ? Scaffold(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        body: const Center(
                          child: Text('This platform is not support'),
                        ),
                      )
                    : MapScreen(),
              ),
              context: context,
            );
          }
        },
        child: const Icon(Icons.location_on, color: Colors.white),
      ),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            ZipBizTopHeader(showBackButton: Navigator.canPop(context)),
            Expanded(
              child: ListenableProvider<SearchModel>.value(
            value: search,
            child: Consumer<SearchModel>(
              builder: (context, value, child) {
                return LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints viewportConstraints) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      children: <Widget>[
                        // 1. Region Selector Capsule
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.my_location, size: 18, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Service Area',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                      Text(
                                        _selectedRegion,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B4EA4).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2E7D32),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Active Pros',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6B4EA4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. Search Input & Search Action Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(App.fluxStoreNavigatorKey.currentContext!)
                                          .pushNamed(RouteList.homeSearch);
                                    },
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(
                                          Icons.search,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Search Electrician, Plumber, Cleaner...',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.mic_none,
                                          size: 18,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(App.fluxStoreNavigatorKey.currentContext!)
                                        .pushNamed(RouteList.homeSearch);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text(
                                    'Search',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 3. Filter Category Pills
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                          child: Row(
                            children: [
                              _buildPill('All Services', 'all', Icons.grid_view),
                              const SizedBox(width: 8),
                              _buildPill('Most Booked', 'booked', Icons.local_fire_department),
                              const SizedBox(width: 8),
                              _buildPill('Quickest 15m', 'quick', Icons.bolt),
                              const SizedBox(width: 8),
                              _buildPill('Emergency', 'emergency', Icons.emergency_outlined),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        Expanded(
                          child: renderDefault(context, viewportConstraints),
                        ),
                      ],
                    ),
                  );
                });
              },
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String label, String key, IconData icon) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B4EA4) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B4EA4) : Theme.of(context).dividerColor.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget renderDefault(context, viewportConstraints) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          CategoryHorizontal(viewportConstraints),
          const SizedBox(
            height: 15.0,
          ),
          RecentList(),
        ],
      ),
    );
  }
}
