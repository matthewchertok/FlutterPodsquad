import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/CreateAPodView.dart';
import 'package:podsquad/ContentViews/MainListDisplayView.dart';
import 'package:podsquad/OtherSpecialViews/TutorialSheets.dart';
import 'package:podsquad/TabLayoutViews/LikesFriendsBlocksTabView.dart';

/// The drawer that opens from the left side of the screen to allow the user to navigate to view their
/// likes/friends/blocks
Widget likesFriendsBlocksDrawer({required BuildContext context}) => Drawer(
        child: SafeArea(child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: accentColor, image: DecorationImage(image: AssetImage("assets/podsquad_logo_simple.png"),
                  fit: BoxFit.cover),
              ),
              child: Text('Options', style: TextStyle(color: CupertinoColors.white),),
            ),

            // Navigate to search users by name
            ListTile(
              title: Text("Search Users By Name"), leading: Icon(CupertinoIcons.search_circle),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                    builder: (context) => MainListDisplayView(viewMode: MainListDisplayViewModes.searchUsers)));
              },
            ),

            // Search for a pod by name
            ListTile(
              onTap: () {
                Navigator.of(context, rootNavigator: true)
                    .push(CupertinoPageRoute(
                    builder: (context) => MainListDisplayView(viewMode: MainListDisplayViewModes.searchPods)))
                    .then((value) {
                });
              },
              title: Text("Search Pods By Name"), leading: Icon(CupertinoIcons.search),),

            ListTile(
              onTap: () {
                Navigator.of(context, rootNavigator: true)
                    .push(CupertinoPageRoute(builder: (context) => CreateAPodView(isCreatingNewPod: true)));
              },
              title: Text("Create Pod"), leading: Icon(CupertinoIcons.plus),),

            // Navigate to view likes
            ListTile(
              title: Text("View Likes"), leading: Icon(CupertinoIcons.heart),
              onTap: () {
                // navigate to view likes
                Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                    builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.likes)));
              },
            ),

            // Navigate to view friends
            ListTile(
              title: Text("View Friends"), leading: Icon(CupertinoIcons.person_3),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                    builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.friends)));
              },
            ),

            // Navigate to view blocks
            ListTile(
              title: Text("Blocked People"), leading: Icon(CupertinoIcons.person_crop_circle_badge_xmark),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                    builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.blocked)));
              },
            ),

            // show the help sheet
            ListTile(title: Text("Help"), leading: Icon(CupertinoIcons.question_circle), onTap: (){
              showWelcomeTutorialIfNecessary(context: context, userPressedHelp: true);
            },)
          ],
        )));
