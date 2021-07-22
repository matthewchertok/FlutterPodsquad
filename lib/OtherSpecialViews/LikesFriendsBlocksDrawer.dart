import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/CreateAPodView.dart';
import 'package:podsquad/ContentViews/MainListDisplayView.dart';
import 'package:podsquad/TabLayoutViews/LikesFriendsBlocksTabView.dart';
import 'package:podsquad/TabLayoutViews/WelcomeView.dart';

/// The drawer that opens from the left side of the screen to allow the user to navigate to view their
/// likes/friends/blocks
Widget likesFriendsBlocksDrawer({required BuildContext context}) => SafeArea(
        child: Scaffold(
      body: ListView(
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
            title: Text("Search Users by Name"),
            onTap: () {
              drawerKey.currentState?.toggle(); // hide the drawer before navigating
              Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                  builder: (context) => MainListDisplayView(viewMode: MainListDisplayViewModes.searchUsers)));
            },
          ),

          // Search for a pod by name
          ListTile(
              onTap: () {
                drawerKey.currentState?.toggle(); // hide the drawer before navigating
                Navigator.of(context, rootNavigator: true)
                    .push(CupertinoPageRoute(
                    builder: (context) => MainListDisplayView(viewMode: MainListDisplayViewModes.searchPods)))
                    .then((value) {
                });
              },
              title: Text("Search Pods By Name")),

          ListTile(
              onTap: () {
                drawerKey.currentState?.toggle(); // hide the drawer before navigating
                Navigator.of(context, rootNavigator: true)
                    .push(CupertinoPageRoute(builder: (context) => CreateAPodView(isCreatingNewPod: true)))
                    .then((value) {;
                });
              },
              title: Text("Create Pod")),

          // Navigate to view likes
          ListTile(
            title: Text("View Likes"),
            onTap: () {
              drawerKey.currentState?.toggle(); // hide the drawer before navigating
          // navigate to view likes
              Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                  builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.likes)));
            },
          ),

          // Navigate to view friends
          ListTile(
            title: Text("View Friends"),
            onTap: () {
              drawerKey.currentState?.toggle(); // hide the drawer before navigating
              Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                  builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.friends)));
            },
          ),

          // Navigate to view blocks
          ListTile(
            title: Text("Blocked People"),
            onTap: () {
              drawerKey.currentState?.toggle(); // hide the drawer before navigating
              Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                  builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.blocked)));
            },
          ),
        ],
      ),
    ));
