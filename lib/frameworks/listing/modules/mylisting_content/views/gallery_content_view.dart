import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import '../../../../../common/config.dart';
import '../../../../../common/constants.dart';
import '../../../../../common/tools/image_resize.dart';
import '../../../../../widgets/common/expansion_info.dart';
import '../models/gallery_content.dart';

class GalleryContentView extends StatefulWidget {
  final GalleryContent? content;

  const GalleryContentView({this.content});

  @override
  State<GalleryContentView> createState() => _GalleryContentViewState();
}

class _GalleryContentViewState extends State<GalleryContentView> {
  int _selectedIndex = 0;

  void _handleImageTap(BuildContext context,
      {int index = 0, bool fullScreen = false}) {
    if (!fullScreen) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content?.gallery?.isEmpty ?? true) {
      return const SizedBox();
    }
    return ExpansionInfo(
      expand: kProductDetail.expandDescription,
      title: widget.content?.title ?? '',
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraint) {
            final dimension = constraint.maxWidth * 0.35;
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(5),
                  child: ExtendedImage.network(
                    widget.content?.gallery![_selectedIndex] ?? '',
                    width: constraint.maxWidth,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(
                  height: dimension,
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 5),
                    child: Row(
                      children: [
                        for (var i = 0;
                            i < (widget.content?.gallery?.length ?? 0);
                            i++)
                          GestureDetector(
                            onTap: () => _handleImageTap(context, index: i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(left: 5),
                              child: ImageResize(
                                url: widget.content?.gallery?[i],
                                height: dimension * (kIsWeb ? 1.2 : 1),
                                isResize: true,
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        )
      ],
    );
  }
}
