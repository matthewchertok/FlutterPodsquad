import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/BackendFunctions/NearbyScanner.dart';
import 'package:podsquad/BackendFunctions/NearbyScanner2.dart';
import 'package:podsquad/CommonlyUsedClasses/AlertDialogs.dart';
import 'package:podsquad/ContentViews/MyProfileTab.dart';
import 'package:podsquad/ContentViews/MainListDisplayView.dart';
import 'package:podsquad/ContentViews/MessagingTab.dart';
import 'package:podsquad/OtherSpecialViews/LikesFriendsBlocksDrawer.dart';
import 'package:podsquad/OtherSpecialViews/TutorialSheets.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({Key? key}) : super(key: key);

  @override
  _WelcomeViewState createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  final _tabController = CupertinoTabController();

  @override
  void initState() {
    super.initState();
    showWelcomeTutorialIfNecessary(context: context);

    // Listen to check if my profile is complete. If it isn't, switch the tab to My Profile to make me fill one out.
    MyProfileTabBackendFunctions.shared.isProfileComplete.addListener(() {
      final isComplete = MyProfileTabBackendFunctions.shared.isProfileComplete.value;
      setState(() {
        if (!isComplete) this._tabController.index = 3;
      });
      if (isComplete) NearbyScanner.shared.publishAndSubscribe();
      else NearbyScanner.shared.publishAndSubscribe();
    });

    // Listen to when I switch the tab. If my profile isn't complete, don't let me switch tabs, and show an alert.
    this._tabController.addListener(() {
      final index = _tabController.index;
      final profileComplete = MyProfileTabBackendFunctions.shared.isProfileComplete.value;
      if (!profileComplete && index != 3) {
        setState(() {
          _tabController.index = 3; // force me back to the My Profile tab
        });
        showSingleButtonAlert(
            context: context,
            title: "Profile Not Complete",
            content:
                "Complete a profile to begin using Podsquad! Not sure what's missing? Scroll down and tap Create Profile.",
            dismissButtonLabel: "OK");
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    MyProfileTabBackendFunctions.shared.isProfileComplete.removeListener(() {});
    this._tabController.removeListener(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Localizations(locale: Locale('en', 'US'), delegates: [
      DefaultWidgetsLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
      DefaultCupertinoLocalizations.delegate
    ], child: Scaffold(key: drawerKey, drawer: likesFriendsBlocksDrawer(context: context),body: CupertinoTabScaffold(
        controller: _tabController,
        tabBar: CupertinoTabBar(items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_3), label: "People I Met"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.bubble_left_bubble_right), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_2_square_stack), label: "My Pods"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: "My Profile")
        ]),
        tabBuilder: (context, index) {
          return CupertinoTabView(builder: (context) {
            switch (_tabController.index) {
              case 0:
                {
                  return MainListDisplayView(key: ValueKey<int>(0),viewMode: MainListDisplayViewModes.peopleIMet);
                }
              case 1:
                {
                  return MessagingTab(key: ValueKey<int>(1));
                }
              case 2:
                {
                  return MainListDisplayView(key: ValueKey<int>(2),viewMode: MainListDisplayViewModes.myPods);
                }
              case 3:
                {
                  return MyProfileTab(key: ValueKey<int>(3));
                }
              default:
                {
                  return MyProfileTab();
                }
            }
          });
        }),),);
  }
}

/// A global variable key that can be used to control the drawer
final drawerKey = GlobalKey<ScaffoldState>();
