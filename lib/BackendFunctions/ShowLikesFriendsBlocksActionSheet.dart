import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/MainListDisplayView.dart';
import 'package:podsquad/TabLayoutViews/LikesFriendsBlocksTabView.dart';

/// Show an action sheet to allow the user to navigate to view their likes,
/// friends, and people they blocked.
void showLikesFriendsBlocksActionSheet({required BuildContext context}) {
  final sheet = CupertinoActionSheet(
    title: Text("Podsquad Options"),
    message: Text("Search for someone by name, or "
        "view people you've liked, friended, or blocked."),
    actions: [
      // Navigate to search users by name
      CupertinoActionSheetAction(
        child: Text("Search Users by Name"),
        onPressed: () {
          dismissAlert(context: context);
          Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
              builder: (context) => MainListDisplayView(viewMode: MainListDisplayViewModes.searchUsers)));
        },
      ),

      // Navigate to view likes
      CupertinoActionSheetAction(
        child: Text("View Likes"),
        onPressed: () {
          // navigate to view likes
          dismissAlert(context: context);
          Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
              builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.likes)));
        },
      ),

      // Navigate to view friends
      CupertinoActionSheetAction(
        child: Text("View Friends"),
        onPressed: () {
          dismissAlert(context: context);
          Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
              builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.friends)));
        },
      ),

      // Navigate to view blocks
      CupertinoActionSheetAction(
        child: Text("Blocked People"),
        onPressed: () {
          dismissAlert(context: context);
          Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
              builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.blocked)));
        },
      ),

      // cancel button
      CupertinoActionSheetAction(
        onPressed: () {
          dismissAlert(context: context);
        },
        child: Text("Cancel"),
        isDefaultAction: true,
      )
    ],
  );
  showCupertinoModalPopup(context: context, builder: (context) => sheet);
}
