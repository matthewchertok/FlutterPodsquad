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
        child: Container(color: isDarkMode ? CupertinoColors.black : CupertinoColors.white,
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
                title: Text("Search Users By Name", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
                CupertinoColors.darkBackgroundGray)), leading: Icon(CupertinoIcons.search_circle, color: CupertinoColors.inactiveGray),
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
                title: Text("Search Pods By Name", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
                CupertinoColors.darkBackgroundGray)), leading: Icon(CupertinoIcons.search, color: CupertinoColors.inactiveGray),),

              ListTile(
                onTap: () {
                  Navigator.of(context, rootNavigator: true)
                      .push(CupertinoPageRoute(builder: (context) => CreateAPodView(isCreatingNewPod: true)));
                },
                title: Text("Create Pod", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
                CupertinoColors.darkBackgroundGray)), leading: Icon(CupertinoIcons.plus, color: CupertinoColors.inactiveGray),),

              // Navigate to view likes
              ListTile(
                title: Text("View Likes", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
                CupertinoColors.darkBackgroundGray)), leading: Icon(CupertinoIcons.heart, color: CupertinoColors.inactiveGray),
                onTap: () {
                  // navigate to view likes
                  Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                      builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.likes)));
                },
              ),

              // Navigate to view friends
              ListTile(
                title: Text("View Friends", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
                CupertinoColors.darkBackgroundGray)), leading: Icon(CupertinoIcons.person_3, color: CupertinoColors.inactiveGray),
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                      builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.friends)));
                },
              ),

              // Navigate to view blocks
              ListTile(
                title: Text("Blocked People", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
                CupertinoColors.darkBackgroundGray)), leading: Icon(CupertinoIcons.person_crop_circle_badge_xmark, color: CupertinoColors.inactiveGray),
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                      builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.blocked)));
                },
              ),

              // show the help sheet
              ListTile(title: Text("Help", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray)), leading: Icon(CupertinoIcons.question_circle, color: CupertinoColors.inactiveGray), onTap: (){
                showWelcomeTutorialIfNecessary(context: context, userPressedHelp: true);
              },)
            ],
          )),
        ));
