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
      secondAppBar: renderAppBar(),
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
        child: SafeArea(
          child: ListenableProvider<SearchModel>.value(
            value: search,
            child: Consumer<SearchModel>(
              builder: (context, value, child) {
                return LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints viewportConstraints) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Column(
                      children: <Widget>[
                        Row(children: [
                          /// SearchBar
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20)),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              margin: const EdgeInsets.all(10.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(App.fluxStoreNavigatorKey
                                          .currentContext!)
                                      .pushNamed(RouteList.homeSearch);
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.search,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: textController,
                                        focusNode: _focus,
                                        enabled: false,
                                        decoration: InputDecoration(
                                          fillColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          border: InputBorder.none,
                                          hintText:
                                              S.of(context).searchForItems,
                                          focusColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 5,
                          )
                        ]),
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
