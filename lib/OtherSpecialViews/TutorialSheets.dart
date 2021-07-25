import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:podsquad/BackendFunctions/SettingsStoredOnDevice.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

/// Show the login tutorial (explaining how to get started) if the user hasn't yet seen it
Future<void> showLoginTutorialIfNecessary({required BuildContext context}) async {
  final completer = Completer();
  final sheet = Scaffold(
      body: FocusDetector(
    child: CustomScrollView(
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: Text("Let's Get Started"),
          trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerRight,
              child: Icon(CupertinoIcons.check_mark),
              onPressed: () {
                dismissAlert(context: context);
              }),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 10,
          ),
        ),
        SliverList(
            delegate: SliverChildListDelegate([
          ListTile(
            title: Text("What Is Podsquad?"),
            subtitle: Text("Podsquad is an app designed to help you meet "
                "people"),
            leading: Icon(CupertinoIcons.hand_point_right),
          ),
          ListTile(
            title: Text("How Does It Work?"),
            subtitle: Text("Podsquad uses Bluetooth to detect nearby users and "
                "does not required your location."),
            leading: Icon(CupertinoIcons.hand_point_right),
          ),
          ListTile(
            title: Text("Get Started"),
            subtitle: Text("Sign up with a valid university email address to begin!"),
            leading: Icon(CupertinoIcons.hand_point_right),
          )
        ]))
      ],
    ),
    onFocusLost: () async {
      // mark the tutorial as read when dismissed
      await SettingsStoredOnDevice.shared
          .saveValueForKey(key: SettingsStoredOnDevice.didReadLoginTutorial, value: true);
      completer.complete();
    },
  ));
  final didReadTutorial =
      await SettingsStoredOnDevice.shared.readValueForKey(key: SettingsStoredOnDevice.didReadLoginTutorial) as bool? ??
          false;

  // show the tutorial sheet, and complete the future once that sheet is dismissed
  if (!didReadTutorial)
    showCupertinoModalBottomSheet(context: context, builder: (context) => sheet, useRootNavigator: true);
  else
    return; // return without showing the sheet if I've already seen it
  return completer.future;
}

/// Show the EULA if the user hasn't seen it yet
Future<void> showEULAIfNecessary({required BuildContext context}) async {
  final completer = Completer();
  final sheet = Scaffold(
      body: FocusDetector(
    child: CustomScrollView(
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: Text("Terms & Conditions"),
          trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerRight,
              child: Icon(CupertinoIcons.check_mark),
              onPressed: () {
                dismissAlert(context: context);
              }),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 10,
          ),
        ),
        SliverList(
            delegate: SliverChildListDelegate([
          ListTile(
            title: Text("Code of Conduct"),
            subtitle: Text("Individuals agree to use Podsquad to make friends "
                "rather than to harass people. This means that any publicly visible images should not contain offensive "
                "or pornographic content, and no communication made through the app should seek to threaten or harm anyone "
                "else. Additionally, users must be at least 17 years of age. Violation of any of the terms listed on this "
                "page may result in account suspension."),
            leading: Icon(CupertinoIcons.exclamationmark_octagon),
          ),
          ListTile(
            title: Text("Data Collection"),
            subtitle: Text("Podsquad collects information such as name, age, and "
                "university affiliation in order to improve user experience. When providing this information, users agree "
                "to represent themselves accurately (no false names or misleading profile details). We value your privacy, "
                "so this data will not be shared with or sold to third parties."
                ""),
            leading: Icon(CupertinoIcons.lock),
          ),
          ListTile(
            title: Text("Content Liability"),
            subtitle: Text("While we strive to maintain a positive community on "
                "Podsquad, we cannot guarantee that the app will be completely free of all inappropriate content. We shall "
                "not be held liable for user-generated content on the app, through we encourage users to "
                "report offensive content should they find any."),
            leading: Icon(CupertinoIcons.shield),
          ),
          ListTile(
            title: Text("License"),
            subtitle: Text("The developers of Podsquad own all intellectual property "
                "rights to the application. Users agree not to sell, modify, distribute, or attempt to copy or reverse "
                "engineer the app. Violation of this policy may result in legal action."),
            leading: Icon(CupertinoIcons.doc_text),
          ),
          ListTile(
            title: Text("Agreement To Terms"),
            subtitle: Text("By continuing to use Podsquad, users agree to all "
                "terms listed on this page. Individuals who do not agree with these terms should uninstall the application"
                "."),
            leading: Icon(CupertinoIcons.person_crop_circle_badge_checkmark),
          )
        ]))
      ],
    ),
    onFocusLost: () {
      // mark the tutorial as read when dismissed
      final agreeAlert = CupertinoAlertDialog(
        title: Text("Acknowledgement Of Terms"),
        content: Text("Please confirm "
            "that you have read and agree to the terms and conditions."),
        actions: [
          CupertinoButton(
              child: Text(
                "I Don't Agree",
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
              onPressed: () {
                dismissAlert(context: context); // dismiss the alert
                showEULAIfNecessary(context: context); // show the terms and conditions again until the user agrees
              }),
          CupertinoButton(
              child: Text("I Agree"),
              onPressed: () async {
                dismissAlert(context: context);
                await SettingsStoredOnDevice.shared
                    .saveValueForKey(key: SettingsStoredOnDevice.didReadEULA, value: true);
                completer.complete();
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => agreeAlert);
    },
  ));
  final didReadEULA =
      await SettingsStoredOnDevice.shared.readValueForKey(key: SettingsStoredOnDevice.didReadEULA) as bool? ?? false;

  // show the tutorial sheet, and complete the future once that sheet is dismissed
  if (!didReadEULA)
    showCupertinoModalBottomSheet(context: context, builder: (context) => sheet, useRootNavigator: true);
  else
    return; // return without showing the sheet if I've already seen it
  return completer.future;
}

/// Show the Welcome view tutorial sheet if the user hasn't seen it yet or if the user pressed Help
Future<void> showWelcomeTutorialIfNecessary({required BuildContext context, userPressedHelp = false}) async {
  final completer = Completer();
  final sheet = Scaffold(
      body: FocusDetector(
    child: CustomScrollView(
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle:
              Text("Features"),
          trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerRight,
              child: Icon(CupertinoIcons.check_mark),
              onPressed: () {
                dismissAlert(context: context);
              }),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 10,
          ),
        ),
        SliverList(
            delegate: SliverChildListDelegate([
          if (MyProfileTabBackendFunctions.shared.isProfileComplete.value == false)
            ListTile(
              title: Text("Create Profile"),
              subtitle: Text("Create a profile to get started!"),
              leading: Icon(CupertinoIcons.person),
            ),
          ListTile(
            title: Text("Discover Nearby"),
            subtitle: Text("While open, Podsquad automatically "
                "listens for users within approximately 30 feet. You'll be able to see people you meet in real time."),
            leading: Icon(CupertinoIcons.bluetooth),
          ),
          ListTile(
            title: Text("Messaging"),
            subtitle: Text("You can message anyone on Podsquad. Messages will appear in "
                "the Messages tab."),
            leading: Icon(CupertinoIcons.bubble_left_bubble_right),
          ),
          ListTile(
            title: Text("Create Pods"),
            subtitle: Text("Pods are groups you can make with your friends. Create one"
                " by opening the drawer on the left hand side of the screen and tapping Create Pod."),
            leading: Icon(CupertinoIcons.person_2_square_stack),
          ),
          ListTile(
            title: Text("Search By Name"),
            subtitle: Text("You can search for users and pods by opening the drawer"
                " on the left hand side of the screen and tapping Search Users By Name or Search Pods By Name."),
            leading: Icon(CupertinoIcons.search),
          ),
        ]))
      ],
    ),
    onFocusLost: () async {
      // mark the tutorial as read when dismissed
      await SettingsStoredOnDevice.shared
          .saveValueForKey(key: SettingsStoredOnDevice.didReadWelcomeTutorial, value: true);
      completer.complete();
    },
  ));
  final didReadTutorial = await SettingsStoredOnDevice.shared
          .readValueForKey(key: SettingsStoredOnDevice.didReadWelcomeTutorial) as bool? ??
      false;

  // show the tutorial sheet, and complete the future once that sheet is dismissed
  if (!didReadTutorial || userPressedHelp)
    showCupertinoModalBottomSheet(context: context, builder: (context) => sheet, useRootNavigator: true);
  else
    return; // return without showing the sheet if I've already seen it
  return completer.future;
}
