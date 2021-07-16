import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';

/// Contains an image with decoration designed to hold a person's profile photo or thumbnail. If width and height are
/// left empty, the image can be wrapped in an Expanded widget to fill the container.
class DecoratedImage extends StatelessWidget {
  const DecoratedImage(
      {Key? key,
      required this.imageURL, this.width, this.height, this.shadowColor = accentColor,
      this.shadowRadius = 3, this.shadowOpacity = 0.5})
      : super(key: key);
  final String imageURL;
  final double? width;
  final double? height;
  final Color shadowColor;
  final int shadowRadius;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: CupertinoColors.white, width: 3),
            boxShadow: [BoxShadow(color: shadowColor.withOpacity(shadowOpacity), blurRadius: 3)]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: imageURL,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Icon(CupertinoIcons.exclamationmark_triangle_fill),
              progressIndicatorBuilder: (context, url, progress) => CupertinoActivityIndicator(),
            )));
  }
}
