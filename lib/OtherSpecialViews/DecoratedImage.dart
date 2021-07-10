import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

/// Contains an image with decoration designed to hold a person's profile photo or thumbnail
class DecoratedImage extends StatelessWidget {
  const DecoratedImage(
      {Key? key,
      required this.imageURL,
      required this.width,
      required this.height, this.shadowColor = accentColor,
      this.shadowRadius = 3})
      : super(key: key);
  final String imageURL;
  final double width;
  final double height;
  final Color shadowColor;
  final int shadowRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: CupertinoColors.white, width: 3),
            boxShadow: [BoxShadow(color: shadowColor, blurRadius: 3)]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ValueListenableBuilder(
                valueListenable: MyProfileTabBackendFunctions.shared.myProfileData,
                builder: (context, ProfileData profileData, widget) {
                  return profileData.thumbnailURL.isEmpty
                      ? Icon(CupertinoIcons.person)
                      : CachedNetworkImage(
                          imageUrl: profileData.thumbnailURL,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Icon(CupertinoIcons.exclamationmark_triangle_fill),
                          progressIndicatorBuilder: (context, url, progress) => CupertinoActivityIndicator(),
                        );
                })));
  }
}
