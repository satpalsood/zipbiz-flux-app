import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:quiver/strings.dart';

import '../../../../common/config.dart';
import '../../../../models/index.dart';
import '../../../../screens/detail/widgets/recent_product.dart';
import '../../../../services/index.dart';
import '../../../../widgets/common/expansion_info.dart';
import '../../../../widgets/product/widgets/heart_button.dart';
import '../../modules/mylisting_content/index.dart';
import '../airbnb_slider.dart';
import '../product_description.dart';
import '../product_map.dart';
import '../product_menu.dart';
import '../product_opening_time.dart';
import '../product_related.dart';
import '../product_taxonomies.dart';
import '../product_title.dart';
import '../review.dart';
import 'listing_option_mixin.dart';

class ListingSimpleLayout extends StatefulWidget {
  final Product product;
  final ScrollController? scrollController;

  const ListingSimpleLayout({
    required this.product,
    this.scrollController,
  });

  @override
  State<ListingSimpleLayout> createState() => _ListingSimpleLayoutState();
}

class _ListingSimpleLayoutState extends State<ListingSimpleLayout>
    with SingleTickerProviderStateMixin, ListingOptionMixin {
  final services = Services();
  late final _scrollController = widget.scrollController ?? ScrollController();

  Product get product => widget.product;

  GoogleMapController? pageController;

  int quantity = 1;
  String size = '';
  String color = '';

  var top = 0.0;

  @override
  void initState() {
    // if (kAdConfig['enable']) Ads().adInit();
    super.initState();
  }

  @override
  void dispose() {
    // if (kAdConfig['enable']) {
    //   Ads.hideBanner();
    //   Ads.hideInterstitialAd();
    // }
    super.dispose();
  }

//  _onShowGallery(context, [index = 0]) {
//    showDialog<void>(
//        context: context,
//        builder: (BuildContext context) {
//          return ImageGalery(images: product.images, index: index);
//        });
//  }

  List<Widget> getReviews() {
    return [
      ExpansionInfo(
        expand: kProductDetail.expandReviews,
        title: S.of(context).readReviews,
        children: <Widget>[
          const SizedBox(height: 10),
          Reviews(widget.product.id),
          const SizedBox(height: 10),
        ],
      ),
    ];
  }

  List<Widget> getListingContent(context) {
    return [
      ProductTitle(product: product),
      const SizedBox(height: 10),
      if (ServerConfig().isMyListingType) MyListingContents(product: product),
      if (!ServerConfig().isMyListingType && isNotBlank(product.description))
        ProductDescription(
          product: product,
        ),
      ProductTaxonomies(
        product: product,
        title: S.of(context).features,
        type: DataMapping().kTaxonomies['features'],
      ),
      if (product.listingMenu?.isNotEmpty ?? false)
        ProductMenu(
          product: product,
        ),
      if (product.listingHour?.isShowOpeningStatus ?? false)
        ProductOpeningTime(
          product: product,
          title: S.of(context).openingHours,
        ),
      ProductMap(
        product: product,
      ),
      if (kProductDetail.enableReview) ...getReviews(),
      if (kProductDetail.showRelatedProduct)
        ProductRelated(
          product: product,
        ),
      if (kProductDetail.showRecentProduct)
        RecentProducts(excludeProduct: product),
      SizedBox(
        height: kAdConfig['enable'] ? 100 : 50,
      ),
    ];
  }

  List<Widget> getGoogleSheet(context) {
    return [
      ProductTitle(
        product: product,
      ),
      ProductDescription(
        product: product,
      ),
      ProductMap(
        product: product,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> getThemeContent(value) {
      // if (ServerConfig().isMyListingType) {
      //   return [MyListingContents(product: product)];
      // }
      switch (ServerConfig().typeName) {
        case 'google-sheet':
          return getGoogleSheet(context);
        default:
          return getListingContent(context);
      }
    }

    return Consumer2<AppModel, UserModel>(
        builder: (context, valueApp, valueUser, child) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            resizeToAvoidBottomInset: false,
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                    backgroundColor: Colors.black87,
                    elevation: 1.0,
                    expandedHeight: MediaQuery.of(context).size.height *
                        kProductDetail.height,
                    pinned: true,
                    floating: false,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    actions: <Widget>[
                      HeartButton(
                        product: product,
                        size: 20.0,
                        color: Colors.white,
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        color: Colors.white,
                        onPressed: () => showOptions(context, product: product),
                      ),
                    ],
                    flexibleSpace: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        return FlexibleSpaceBar(
                          background: AirbnbSlider(
                            images: product.images,
                            height: MediaQuery.of(context).size.height *
                                kProductDetail.height,
                          ),
                        );
                      },
                    )),
                SliverList(
                  delegate: SliverChildListDelegate(
                    <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: getThemeContent(valueUser),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
