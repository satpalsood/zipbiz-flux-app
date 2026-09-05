import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:provider/provider.dart';
import 'package:quiver/strings.dart';
import 'package:share_plus/share_plus.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/tools.dart';
import '../../../models/entities/index.dart';
import '../../../models/index.dart' show ProductWishListModel;
import '../../../models/user_model.dart';
import '../../../widgets/common/star_rating.dart';
import 'booking/booking.dart';
import 'product_categories.dart';

class ProductTitle extends StatelessWidget {
  final Product? product;

  const ProductTitle({this.product});

  void _bookNow(context) {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) {
      Navigator.of(context).pushNamed(RouteList.login);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingScreen(
            product: product,
          ),
        ),
      );
    }
  }

  List<Widget> getPricing(context) {
    final theme = Theme.of(context);
    return [
      if ((product!.price != null && product!.regularPrice == null) ||
          (product!.price == null && product!.regularPrice != null))
        Row(
          children: <Widget>[
            Text(
                PriceTools.getCurrencyFormatted(
                    product!.price ?? product!.regularPrice ?? '0', null)!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF6B00),
                ))
          ],
        ),
      if (product!.price != null && product!.regularPrice != null)
        Row(
          children: <Widget>[
            Text(PriceTools.getCurrencyFormatted(product!.regularPrice, null)!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                  decoration: TextDecoration.lineThrough,
                )),
            const SizedBox(width: 8),
            Text(PriceTools.getCurrencyFormatted(product!.price, null)!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF6B00),
                ))
          ],
        ),
      const SizedBox(height: 2),
      if (product!.averageRating != null && product!.averageRating != 0.0)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SmoothStarRating(
                allowHalfRating: true,
                starCount: 5,
                rating: product?.averageRating,
                size: 16.0,
                color: const Color(0xFFF59E0B),
                borderColor: const Color(0xFFF59E0B),
                spacing: 2.0,
                label: (product?.totalReview ?? 0) > 0
                    ? Text(
                        '  ${product?.averageRating?.toStringAsFixed(1)} (${product?.totalReview} reviews)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5A4136),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
    ];
  }

  Widget getPricingButton(context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Starts at',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF5A4136),
                  fontWeight: FontWeight.w500,
                ),
              ),
              ...getPricing(context),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: () => _bookNow(context),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(
              S.of(context).bookingNow,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var list = <Widget>[];
    var supportBooking = product?.listingBookingStatus ?? false;

    if (isNotBlank(product!.location)) {
      list.add(InfoItem(
        icon: Icons.location_on,
        title: product!.location,
      ));
    }
    if (isNotBlank(product!.phone)) {
      list.add(InfoItem(
        icon: Icons.phone,
        title: product!.phone,
        onTap: () async {
          await Tools.launchURL('tel:${product!.phone!}');
        },
      ));
    }
    if (isNotBlank(product!.email)) {
      list.add(InfoItem(
        icon: Icons.email,
        title: product!.email,
        onTap: () async {
          await Tools.launchURL('mailto:${product!.email!}');
        },
      ));
    }
    if (isNotBlank(product!.website)) {
      list.add(InfoItem(
        icon: Icons.language,
        title: product!.website,
        onTap: () async {
          await Tools.launchURL(product!.website);
        },
      ));
    }
    if (kProductDetail.showSocialLinks) {
      list.add(Wrap(
        children: <Widget>[
          if (isNotBlank(product!.whatsapp))
            SocialItem(
              color: Colors.green,
              title: 'WhatsApp',
              icon: 'assets/icons/brands/whatsapp.svg',
              onTap: () async {
                await Tools.launchURL(
                    product!.whatsapp?.contains('http') ?? false
                        ? product!.whatsapp
                        : 'https://wa.me/${product!.whatsapp}');
              },
            ),
          if (isNotBlank(product!.skype))
            SocialItem(
              color: Colors.blueAccent,
              title: 'Skype',
              icon: 'assets/icons/brands/skype.svg',
              onTap: () async {
                await Tools.launchURL('skype:${product!.skype}?chat');
              },
            ),
          if (isNotBlank(product!.facebook))
            SocialItem(
              color: Colors.blue,
              title: 'Facebook',
              icon: 'assets/icons/brands/facebook.svg',
              onTap: () async {
                await Tools.launchURL(product!.facebook);
              },
            ),
          if (isNotBlank(product!.youtube))
            SocialItem(
              color: Colors.red,
              title: 'YouTube',
              icon: 'assets/icons/brands/youtube.svg',
              onTap: () async {
                await Tools.launchURL(product!.youtube);
              },
            ),
          if (isNotBlank(product!.twitter))
            SocialItem(
              color: Colors.blueAccent,
              title: 'Twitter',
              icon: 'assets/icons/brands/twitter.svg',
              onTap: () async {
                await Tools.launchURL(product!.twitter);
              },
            ),
          if (isNotBlank(product!.instagram))
            SocialItem(
              color: Colors.redAccent,
              title: 'Instagram',
              icon: 'assets/icons/brands/instagram.svg',
              onTap: () async {
                await Tools.launchURL(product!.instagram);
              },
            ),
          if (isNotBlank(product!.linkedin))
            SocialItem(
              color: const Color(0xFF0077B5),
              title: 'LinkedIn',
              icon: 'assets/icons/brands/linkedin.svg',
              onTap: () async {
                await Tools.launchURL(product!.linkedin);
              },
            ),
          if (isNotBlank(product!.telegram))
            SocialItem(
              color: Colors.blue,
              title: 'Telegram',
              icon: 'assets/icons/brands/telegram.svg',
              onTap: () async {
                await Tools.launchURL(product!.telegram);
              },
            ),
          if (isNotBlank(product!.tiktok))
            SocialItem(
              border: Border.all(color: Colors.white, width: 0.5),
              color: Colors.black,
              title: 'Tiktok',
              icon: 'assets/icons/brands/tiktok.svg',
              onTap: () async {
                await Tools.launchURL(product!.tiktok);
              },
            ),
        ],
      ));
    }

    return Container(
      color: const Color(0xFFFBF9F8),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Badges row: Open Now + Tricity Verified Partner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Open Now • 9 AM - 6 PM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE4E2E1)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 12, color: Color(0xFFFF6B00)),
                    SizedBox(width: 3),
                    Text(
                      'Tricity Verified Partner',
                      style: TextStyle(
                        color: Color(0xFF1B1C1C),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (kProductDetail.showListCategoriesInTitle) ...[
            ProductCategories(
                product: product, type: DataMapping().kTaxonomies['category']),
            const SizedBox(height: 5),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  product!.name!,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color(0xFF1B1C1C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (product!.verified ?? false) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF0062A1),
                  size: 22,
                ),
              ],
            ],
          ),

          if (isNotBlank(product!.location)) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 15, color: Color(0xFFFF6B00)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    product!.location!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5A4136),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Rating score box + metrics
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '5.0 ★',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Based on ${product?.totalReview ?? 6} verified reviews',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5A4136),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMetricPill('Service', '5.0 ★'),
                    const SizedBox(width: 6),
                    _buildMetricPill('Value', '5.0 ★'),
                    const SizedBox(width: 6),
                    _buildMetricPill('Staff Skills', '5.0 ★'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Quick-Bar: Bookmark, Share, Call Pro
          Row(
            children: [
              Consumer<ProductWishListModel>(
                builder: (context, wishListModel, _) {
                  final isWishlist = wishListModel.isWishList(product!);
                  return Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => wishListModel.toggleWishlist(product!),
                      icon: Icon(
                        isWishlist ? Icons.bookmark : Icons.bookmark_border,
                        size: 18,
                        color: isWishlist ? const Color(0xFFFF6B00) : const Color(0xFF5A4136),
                      ),
                      label: Text(
                        isWishlist ? 'Saved' : 'Bookmark',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isWishlist ? const Color(0xFFFF6B00) : const Color(0xFF1B1C1C),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE4E2E1)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Share.share(
                      '${product!.name} on ZipBiz - Tricity Local Directory: https://zipbiz.in',
                    );
                  },
                  icon: const Icon(Icons.share, size: 18, color: Color(0xFF5A4136)),
                  label: const Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1C1C),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE4E2E1)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final phone = isNotBlank(product!.phone) ? product!.phone! : '+917009218289';
                    Tools.launchURL('tel:$phone');
                  },
                  icon: const Icon(Icons.call, size: 18, color: Colors.white),
                  label: const Text(
                    'Call Pro',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Special Offer Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B00), Color(0xFFA04100)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.redeem, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'SPECIAL OFFER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              child: Text(
                                'SAVE ₹49',
                                style: TextStyle(
                                  color: Color(0xFFFF6B00),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Visiting charges waived on orders above ₹999',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FREEVISIT',
                    style: TextStyle(
                      color: Color(0xFFFF6B00),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Why Choose ZipBiz Guarantees Grid
          const Text(
            'Why Choose ZipBiz Partner',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1C1C),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: const [
              _GuaranteeCard(
                icon: Icons.verified_user,
                iconColor: Color(0xFF2E7D32),
                title: '100% ID Verified',
                subtitle: 'Police checked crew',
              ),
              _GuaranteeCard(
                icon: Icons.pin_drop,
                iconColor: Color(0xFF6B4EA4),
                title: 'Address Verified',
                subtitle: 'Registered facility',
              ),
              _GuaranteeCard(
                icon: Icons.bolt,
                iconColor: Color(0xFFFF6B00),
                title: 'Instant Booking',
                subtitle: 'Real-time schedule',
              ),
              _GuaranteeCard(
                icon: Icons.shield,
                iconColor: Color(0xFF0062A1),
                title: 'Service Warranty',
                subtitle: 'Free rework if unhappy',
              ),
              _GuaranteeCard(
                icon: Icons.eco,
                iconColor: Color(0xFF2E7D32),
                title: 'Eco & Pet Safe',
                subtitle: 'Non-toxic chemicals',
              ),
              _GuaranteeCard(
                icon: Icons.cleaning_services,
                iconColor: Color(0xFF6B4EA4),
                title: 'Full Equipment',
                subtitle: 'Industrial tools',
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (supportBooking)
            getPricingButton(context)
          else
            ...getPricing(context),

          if (list.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...list,
          ],
        ],
      ),
    );
  }

  static Widget _buildMetricPill(String label, String rating) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EDED),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF5A4136)),
            ),
            const SizedBox(height: 2),
            Text(
              rating,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B1C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuaranteeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _GuaranteeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1C1C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF5A4136)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final VoidCallback? onTap;

  const InfoItem({this.title, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: const Color(0xFFFF6B00),
            ),
            const SizedBox(
              width: 12.0,
            ),
            Expanded(
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1B1C1C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialItem extends StatelessWidget {
  final Color? color;
  final String? icon;
  final String? title;
  final VoidCallback? onTap;
  final BoxBorder? border;

  const SocialItem(
      {this.color, this.title, this.icon, this.onTap, this.border});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 10, right: 5),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              icon ?? '',
              width: 15.0,
              height: 15.0,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(
              width: 5,
            ),
            Text(
              title!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }
}
