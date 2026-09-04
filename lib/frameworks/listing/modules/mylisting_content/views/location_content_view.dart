import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';

import '../../../../../common/config.dart';
import '../../../../../common/constants.dart';
import '../../../../../screens/common/google_map_mixin.dart';
import '../../../../../widgets/common/expansion_info.dart';
import '../models/location_content.dart';

class LocationContentView extends StatefulWidget {
  final LocationContent? content;

  const LocationContentView({this.content});

  @override
  State<LocationContentView> createState() => _LocationContentViewState();
}

class _LocationContentViewState extends State<LocationContentView>
    with GoogleMapMixin {
  @override
  Widget build(BuildContext context) {
    return ExpansionInfo(
      expand: kProductDetail.expandDescription,
      title: widget.content?.title ?? '',
      children: <Widget>[
        ...?widget.content?.locations
            ?.map((e) => _renderLocationItem(context, e)),
      ],
    );
  }

  Widget _renderLocationItem(BuildContext context, LocationItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width / 2 + 20,
          child: FluxImage(
            imageUrl: _buildUrl(item).toString(),
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.cover,
            errorWidget: Center(
              child: Text(
                S.of(context).viewOnGoogleMaps,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: Text(
            item.address ?? '',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        )
      ],
    );
  }

  Uri _buildUrl(LocationItem item) {
    var defaultLocation = <String, String>{
      'latitude': '${item.lat}',
      'longitude': '${item.lng}'
    };

    // this should change to your own Google API key
    var googleMapsApiKey;
    if (isIos) {
      googleMapsApiKey = kGoogleApiKey.ios;
    } else if (isAndroid) {
      googleMapsApiKey = kGoogleApiKey.android;
    } else {
      googleMapsApiKey = kGoogleApiKey.web;
    }

    var mapURL = Uri(
        scheme: 'https',
        host: 'maps.googleapis.com',
        port: 443,
        path: '/maps/api/staticmap',
        queryParameters: {
          'size': '800x600',
          'center':
              '${defaultLocation['latitude']},${defaultLocation['longitude']}',
          'zoom': '13',
          'maptype': 'roadmap',
          'markers': 'color:red|label:C|${item.lat},${item.lng}',
          'key': '$googleMapsApiKey',
          'style': getMapStyleParams(),
        });

    return mapURL;
  }
}
