import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/CreateAPodView.dart';
import 'package:podsquad/ContentViews/MainListDisplayView.dart';
import 'package:podsquad/OtherSpecialViews/TutorialSheets.dart';

Widget viewPodDetailsDrawer(
        {required BuildContext context,
        required bool amMemberOfPod,
        required bool amBlockedFromPod,
        required List<ProfileData> podMembersList,
        required List<ProfileData> podBlockedUsersList,
        required PodData podData,
        required Function joinPodFunction,
        required Function leavePodFunction,
        required Function deletePodFunction}) =>
    Drawer(
      child: Container(
        color: isDarkMode ? CupertinoColors.black : CupertinoColors.white,
        child: SafeArea(
            child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: accentColor,
                image: DecorationImage(image: NetworkImage(podData.fullPhotoURL), fit: BoxFit.cover),
              ),
              child: Container(),
            ),

            ListTile(
              title: Text('${podData.name}',
                  style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.darkBackgroundGray)),
              subtitle: Text("Team podscore : ${podData.podScore}",
                  style: TextStyle(color: CupertinoColors.inactiveGray)),
            ),

            // For convenience, also show a Join Pod option if I'm not a member. THe difference between the other

            // button below the pod photo is that this button will show even if I'm blocked or if the pod doesn't

            // allow anyone to join. This button will warn me why I can't join. Unless there's nobody in the pod (if

            // it was deleted). Then just don't show the button.

            if (!amMemberOfPod && podMembersList.length > 0)
              ListTile(
                title: Text("Join Pod",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.darkBackgroundGray)),
                leading: Icon(CupertinoIcons.plus, color: CupertinoColors.inactiveGray),
                onTap: () {
                  // You Are Blocked alert

                  if (amBlockedFromPod) {
                    final blockedAlert = CupertinoAlertDialog(
                      title: Text("Unable To Join Pod"),
                      content: Text("You are blocked from ${podData.name}."),
                      actions: [
                        CupertinoButton(
                            child: Text("OK"),
                            onPressed: () {
                              dismissAlert(context: context);
                            })
                      ],
                    );

                    showCupertinoDialog(context: context, builder: (context) => blockedAlert);
                  }

                  // Only Members Can Add Members alert (except if I created the pod, then I can join it again)

                  else if (!podData.anyoneCanJoin && podData.podCreatorID != myFirebaseUserId) {
                    final permissionAlert = CupertinoAlertDialog(
                      title: Text("Unable To Join Pod"),
                      content: Text(
                          "${podData.name} is a closed group, meaning that only current members can add new members. "
                          "Try messaging someone in ${podData.name} and ask to be added."),
                      actions: [
                        CupertinoButton(
                            child: Text("OK"),
                            onPressed: () {
                              dismissAlert(context: context);
                            })
                      ],
                    );

                    showCupertinoDialog(context: context, builder: (context) => permissionAlert);
                  }

                  // If I'm not blocked and the pod allows anyone to join, then join the pod

                  else {
                    joinPodFunction();
                  }
                },
              ),

            // Navigate to view the members (redundant capability in case users don't realize they can see the members by

            // tapping on the member count (anyone can see the pod members to help them decide if they want to join)

            ListTile(
              title: Text("Pod Members",
                  style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.person_3, color: CupertinoColors.inactiveGray),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                    builder: (context) => MainListDisplayView(
                          viewMode: MainListDisplayViewModes.podMembers,
                          podMembers: podMembersList,
                          podData: podData,
                        )));
              },
            ),

            // Navigate to view the blocked users (only show this option if I'm a member, for privacy reasons)

            if (amMemberOfPod)
              ListTile(
                title: Text("Blocked Users",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.darkBackgroundGray)),
                leading: Icon(CupertinoIcons.person_crop_circle_badge_xmark, color: CupertinoColors.inactiveGray),
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                      builder: (context) => MainListDisplayView(
                            viewMode: MainListDisplayViewModes.podBlockedUsers,
                            podMembers: podBlockedUsersList,
                            podData: podData,
                          )));
                },
              ),

            // Edit the pod, if I'm the creator and a member

            if (amMemberOfPod && podData.podCreatorID == myFirebaseUserId)
              ListTile(
                title: Text("Edit Pod",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.darkBackgroundGray)),
                leading: Icon(CupertinoIcons.pencil, color: CupertinoColors.inactiveGray),
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                      builder: (context) => CreateAPodView(
                            isCreatingNewPod: false,
                            podID: podData.podID,
                          )));
                },
              ),

            // Leave the pod, if I'm a member

            if (amMemberOfPod)
              ListTile(
                title: Text("Leave Pod",
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.darkBackgroundGray)),
                leading: Icon(CupertinoIcons.hand_raised, color: CupertinoColors.inactiveGray),
                onTap: () {
                  leavePodFunction();
                },
              ),

            // Delete the pod, if I'm the creator and a member

            if (amMemberOfPod && podData.podCreatorID == myFirebaseUserId)
              ListTile(
                title: Text(
                  "Delete Pod",
                  style: TextStyle(color: CupertinoColors.destructiveRed),
                ),
                leading: Icon(
                  CupertinoIcons.trash,
                  color: CupertinoColors.destructiveRed,
                ),
                onTap: () {
                  deletePodFunction();
                },
              ),

            //Help tile

            ListTile(
              title: Text("Help",
                  style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.question_circle, color: CupertinoColors.inactiveGray),
              onTap: () {
                showViewPodDetailsTutorialIfNecessary(
                    context: context,
                    podData: podData,
                    userPressedHelp: true,
                    amMember: podMembersList.map((member) => member.userID).contains(myFirebaseUserId));
              },
            )

            // If I'm the pod creator
          ],
        )),
      ),
    );
