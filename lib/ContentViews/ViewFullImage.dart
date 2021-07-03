import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ViewFullImage extends StatefulWidget {
  const ViewFullImage(
      {Key? key,
      required this.urlForImageToView,
      required this.imageID,
      required this.navigationBarTitle,
      required this.canWriteCaption})
      : super(key: key);
  final String urlForImageToView;
  final String imageID;
  final String navigationBarTitle;
  final bool canWriteCaption;

  @override
  _ViewFullImageState createState() => _ViewFullImageState(
      urlForImageToView: urlForImageToView,
      imageID: imageID,
      navigationBarTitle: navigationBarTitle,
      canWriteCaption: canWriteCaption);
}

class _ViewFullImageState extends State<ViewFullImage> {
  _ViewFullImageState(
      {required this.urlForImageToView,
      required this.imageID,
      required this.navigationBarTitle,
      required this.canWriteCaption});

  final String urlForImageToView;
  final String imageID;
  final String navigationBarTitle;
  final bool canWriteCaption;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(navigationBarTitle),
        ),
        child: Center(
          child: CachedNetworkImage(
            imageUrl: urlForImageToView,
            fit: BoxFit.contain,
          ),
        ));
  }
}
