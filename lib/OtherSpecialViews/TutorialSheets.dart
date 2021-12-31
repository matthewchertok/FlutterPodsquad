import 'dart:async';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/BackendFunctions/PronounFormatter.dart';
import 'package:podsquad/BackendFunctions/SettingsStoredOnDevice.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

/// Show the login tutorial (explaining how to get started) if the user hasn't yet seen it
Future<void> showLoginTutorialIfNecessary({required BuildContext context}) async {
  final completer = Completer();
  final sheet = Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
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
                title: Text(
                  "What Is Podsquad?",
                  style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                ),
                subtitle: Text(
                    "Podsquad is an app designed to help you meet "
                    "people",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.hand_point_right, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("How Does It Work?",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "Podsquad uses Bluetooth to detect nearby users and "
                    "does not require your location.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.hand_point_right, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("Get Started",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text("Sign up with a valid university email address to begin!",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.hand_point_right, color: CupertinoColors.inactiveGray),
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
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
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
                title: Text("Code of Conduct",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "Individuals agree to use Podsquad to make friends "
                    "rather than to harass people. This means that any publicly visible images should not contain offensive "
                    "or pornographic content, and no communication made through the app should seek to threaten or harm anyone "
                    "else. Additionally, users must be at least 17 years of age. Violation of any of the terms listed on this "
                    "page may result in account suspension.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.exclamationmark_octagon, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("Data Collection",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "Podsquad collects information such as name, age, and "
                    "university affiliation in order to improve user experience. When providing this information, users agree "
                    "to represent themselves accurately (no false names or misleading profile details). We value your privacy, "
                    "so this data will not be shared with or sold to third parties."
                    "",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.lock, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("Content Liability",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "While we strive to maintain a positive community on "
                    "Podsquad, we cannot guarantee that the app will be completely free of all inappropriate content. We shall "
                    "not be held liable for user-generated content on the app, through we encourage users to "
                    "report offensive content should they find any.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.shield, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("License",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "The developers of Podsquad own all intellectual property "
                    "rights to the application. Users agree not to sell, modify, distribute, or attempt to copy or reverse "
                    "engineer the app. Violation of this policy may result in legal action.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.doc_text, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("Agreement To Terms",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "By continuing to use Podsquad, users agree to all "
                    "terms listed on this page. Individuals who do not agree with these terms should uninstall the application"
                    ".",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.person_crop_circle_badge_checkmark, color: CupertinoColors.inactiveGray),
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
                    "Disagree",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onPressed: () {
                    dismissAlert(context: context); // dismiss the alert
                    showEULAIfNecessary(context: context); // show the terms and conditions again until the user agrees
                  }),
              CupertinoButton(
                  child: Text("Agree"),
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
      backgroundColor: isDarkMode ? CupertinoColors.black : CupertinoColors.white,
      body: FocusDetector(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text("Features"),
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
                  title: Text("Create Profile",
                      style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                  subtitle: Text("Create a profile to get started!",
                      style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                  leading: Icon(CupertinoIcons.person, color: CupertinoColors.inactiveGray),
                ),
              ListTile(
                title: Text("Discover Nearby",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "While open, Podsquad automatically "
                    "listens for users within approximately 30 feet. You'll be able to see people you meet in real time.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.bluetooth, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("Messaging",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "You can message anyone on Podsquad. Messages will appear in "
                    "the Messages tab.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.bubble_left_bubble_right, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("Create Pods",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "Pods are groups you can make with your friends. Create one"
                    " by opening the drawer on the left hand side of the screen and tapping Create Pod.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.person_2_square_stack, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("Search By Name",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "You can search for users and pods by opening the drawer"
                    " on the left hand side of the screen and tapping Search Users By Name or Search Pods By Name.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.search, color: CupertinoColors.inactiveGray),
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

/// Show the ViewPodDetails tutorial sheet if the user hasn't seen it yet or if the user pressed Help
Future<void> showViewPodDetailsTutorialIfNecessary(
    {required BuildContext context, userPressedHelp = false, required PodData podData, required bool amMember}) async {
  final completer = Completer();
  final sheet = Scaffold(
      backgroundColor: isDarkMode ? CupertinoColors.black : CupertinoColors.white,
      body: FocusDetector(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text("Pod Options"),
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
              if (!amMember)
                ListTile(
                  title: Text("Join ${podData.name}",
                      style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                  subtitle: Text(
                      "If the Join button isn't visible, tap the icon in the top right corner, then "
                      "tap Join Pod for more information.",
                      style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                  leading: Icon(CupertinoIcons.line_horizontal_3, color: CupertinoColors.inactiveGray),
                ),
              if (amMember)
                ListTile(
                  title: Text("Leave ${podData.name}",
                      style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                  subtitle: Text("Tap the icon in the top right corner, then tap Leave Pod.",
                      style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                  leading: Icon(CupertinoIcons.hand_raised, color: CupertinoColors.inactiveGray),
                ),
              ListTile(
                title: Text("Message ${podData.name}",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    amMember
                        ? "Message other members through the pod chat!"
                        : "Pod members can message each "
                            "other through the pod chat. Join ${podData.name} to unlock this feature!",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.paperplane, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("View Members",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "Tap on the number of members below the pod name to view members of ${podData.name}. Any "
                    "member can remove or block another member (besides the pod creator) from that screen.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.person_3, color: CupertinoColors.inactiveGray),
              ),
              if (amMember)
                ListTile(
                  title: Text("Blocked Users",
                      style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                  subtitle: Text(
                      "Tap the icon in the top right corner, then Blocked Users to unblock someone from the pod.",
                      style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                  leading: Icon(CupertinoIcons.person_crop_circle_badge_xmark, color: CupertinoColors.inactiveGray),
                ),
            ]))
          ],
        ),
        onFocusLost: () async {
          // mark the tutorial as read when dismissed
          await SettingsStoredOnDevice.shared
              .saveValueForKey(key: SettingsStoredOnDevice.didReadViewPodDetailsTutorial, value: true);
          completer.complete();
        },
      ));
  final didReadTutorial = await SettingsStoredOnDevice.shared
          .readValueForKey(key: SettingsStoredOnDevice.didReadViewPodDetailsTutorial) as bool? ??
      false;

  // show the tutorial sheet, and complete the future once that sheet is dismissed
  if (!didReadTutorial || userPressedHelp)
    showCupertinoModalBottomSheet(context: context, builder: (context) => sheet, useRootNavigator: true);
  else
    return; // return without showing the sheet if I've already seen it
  return completer.future;
}

/// Show the ViewPersonDetails tutorial sheet if the user hasn't seen it yet or if the user pressed Help
Future<void> showViewPersonDetailsTutorialIfNecessary(
    {required BuildContext context, userPressedHelp = false, required ProfileData personData}) async {
  final completer = Completer();
  final sheet = Scaffold(
      backgroundColor: isDarkMode ? CupertinoColors.black : CupertinoColors.white,
      body: FocusDetector(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text("User Options"),
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
                title: Text("Interact with ${personData.name}",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text("Tap the icon in the top right corner for options!",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.line_horizontal_3, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("Message ${personData.name}",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "Send ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)} a message! Alternatively, you can tap the Say "
                    "Hi button and Podsquad will send an automatic introduction for you.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.paperplane, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("Like ${personData.name}",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "Choose this if ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HeSheThey, shouldBeCapitalized: false)} ${PronounFormatter.isOrAre(pronoun: personData.preferredPronoun, shouldBeCapitalized: false)} attractive!",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.heart, color: CupertinoColors.inactiveGray),
              ),
              ListTile(
                title: Text("Friend ${personData.name}",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "Choose this if ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HeSheThey, shouldBeCapitalized: false)} ${PronounFormatter.isOrAre(pronoun: personData.preferredPronoun, shouldBeCapitalized: false)} cool.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.person_badge_plus,
                    color: isDarkMode ? CupertinoColors.white : CupertinoColors.darkBackgroundGray),
              ),
              ListTile(
                title: Text("Likes And Friends Are Exclusive",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "Just like in real life, you cannot Like and Friend ${personData.name.firstName()} "
                    "simultaneously. You must pick one!",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.hand_point_right,
                    color: isDarkMode ? CupertinoColors.white : CupertinoColors.darkBackgroundGray),
              ),
              ListTile(
                title: Text("View ${personData.name.firstName()}'s Pods",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "Select this option to view the pods ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HeSheThey, shouldBeCapitalized: false)} "
                    "${PronounFormatter.isOrAre(pronoun: personData.preferredPronoun, shouldBeCapitalized: false)} in.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.person_2_square_stack,
                    color: isDarkMode ? CupertinoColors.white : CupertinoColors.darkBackgroundGray),
              ),
              ListTile(
                title: Text("Add ${personData.name.firstName()} To Pod",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                subtitle: Text(
                    "Additionally, you may add ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)}"
                    " to a pod that you are in.",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                leading: Icon(CupertinoIcons.plus,
                    color: isDarkMode ? CupertinoColors.white : CupertinoColors.darkBackgroundGray),
              ),
            ]))
          ],
        ),
        onFocusLost: () async {
          // mark the tutorial as read when dismissed
          await SettingsStoredOnDevice.shared
              .saveValueForKey(key: SettingsStoredOnDevice.didReadViewPersonDetailsTutorial, value: true);
          completer.complete();
        },
      ));
  final didReadTutorial = await SettingsStoredOnDevice.shared
          .readValueForKey(key: SettingsStoredOnDevice.didReadViewPersonDetailsTutorial) as bool? ??
      false;

  // show the tutorial sheet, and complete the future once that sheet is dismissed
  if (!didReadTutorial || userPressedHelp)
    showCupertinoModalBottomSheet(context: context, builder: (context) => sheet, useRootNavigator: true);
  else
    return; // return without showing the sheet if I've already seen it
  return completer.future;
}
