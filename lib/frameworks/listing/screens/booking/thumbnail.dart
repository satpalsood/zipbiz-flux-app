import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:inspireui/extensions/color_extension.dart';
import '../../../../models/entities/index.dart';
import '../../../../widgets/common/star_rating.dart';

class Thumbnail extends StatelessWidget {
  final Product? product;

  const Thumbnail({this.product});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: <Widget>[
        FluxImage(
          imageUrl: product?.imageFeature ?? '',
          width: size.width,
          height: size.height / 5,
          fit: BoxFit.cover,
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: size.width,
            height: 70,
            decoration: const BoxDecoration(boxShadow: [
              BoxShadow(
                color: Colors.black54,
                spreadRadius: 20,
                blurRadius: 50,
              )
            ]),
            child: const SizedBox(),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 10,
          right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                product?.name ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              SmoothStarRating(
                allowHalfRating: true,
                starCount: 5,
                rating: product?.averageRating,
                size: 13.0,
                color: Theme.of(context).primaryColor,
                borderColor: Theme.of(context).primaryColor,
                spacing: 0.0,
                label: (product?.totalReview ?? 0) > 0
                    ? Text(
                        '${product?.averageRating?.toStringAsFixed(1)} (${product?.totalReview})',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValueOpacity(0.8)))
                    : null,
              ),
              const SizedBox(height: 2),
              Text(
                product?.tagLine ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
