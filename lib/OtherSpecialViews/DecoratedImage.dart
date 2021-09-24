import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';

/// Contains an image with decoration designed to hold a person's profile photo or thumbnail. If width and height are
/// left empty, the image can be wrapped in an Expanded widget to fill the container. To display a network image,
/// pass in a string for the imageURL property. To display a local image, pass in a File for the imageFile property.
class DecoratedImage extends StatelessWidget {
  const DecoratedImage(
      {Key? key, this.imageURL = "local_image", this.width, this.height, this.shadowColor = accentColor, this
          .borderRadius = 15, this
          .borderWidth = 3,
      this.shadowRadius = 3, this.shadowOpacity = 0.5, this.imageFile})
      : super(key: key);
  final String imageURL;
  final double? width;
  final double? height;
  final double borderRadius;
  final double borderWidth;
  final Color shadowColor;
  final double shadowRadius;
  final double shadowOpacity;
  final File? imageFile; // pass in a value to display a local image instead of loading from a URL

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: CupertinoColors.white, width: borderWidth),
            boxShadow: [BoxShadow(color: shadowColor.withOpacity(shadowOpacity), blurRadius: shadowRadius)]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius*2/3),
            child: imageFile == null ? CachedNetworkImage(
              imageUrl: imageURL,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Icon(CupertinoIcons.exclamationmark_triangle_fill),
              progressIndicatorBuilder: (context, url, progress) => CupertinoActivityIndicator(),
            ) : Image.file(imageFile!)));
  }
}
