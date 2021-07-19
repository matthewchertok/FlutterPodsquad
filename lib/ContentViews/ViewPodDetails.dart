import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendDataHolders/PodMembersDictionary.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/BackendDataclasses/PodMemberInfoDict.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/CreateAPodView.dart';
import 'package:podsquad/ContentViews/MainListDisplayView.dart';
import 'package:podsquad/ContentViews/MessagingView.dart';
import 'package:podsquad/ContentViews/ViewFullImage.dart';
import 'package:podsquad/DatabasePaths/PodsDatabasePaths.dart';
import 'package:podsquad/DatabasePaths/ProfileDatabasePaths.dart';
import 'package:podsquad/OtherSpecialViews/DecoratedImage.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

class ViewPodDetails extends StatefulWidget {
  const ViewPodDetails({Key? key, required this.podID, required this.showChatButton}) : super(key: key);
  final String podID;
  final bool showChatButton;

  @override
  _ViewPodDetailsState createState() => _ViewPodDetailsState(podID: this.podID, showChatButton: showChatButton);
}

class _ViewPodDetailsState extends State<ViewPodDetails> {
  _ViewPodDetailsState({required this.podID, required this.showChatButton});

  final String podID;
  final bool showChatButton;
  int _numberOfMembers = 0;
  bool _amMemberOfPod = false;
  bool _amBlockedFromPod = false;
  List<StreamSubscription> _streamSubs = [];

  /// A list containing data for all members in the pod
  List<ProfileData> _podMembersList = [];

  /// A list containing data for all blocked users in the pod
  List<ProfileData> _podBlockedUsersList = [];

  PodData podData = PodData(
      name: "",
      dateCreated: 0,
      description: "",
      anyoneCanJoin: false,
      podID: "",
      podCreatorID: "",
      thumbnailURL: "",
      thumbnailPath: "",
      fullPhotoURL: "",
      fullPhotoPath: "",
      podScore: 0);

  /// Get the pod data
  void _getPodData() {
    PodsDatabasePaths(podID: podID).getPodData(onCompletion: (podData) {
      setState(() {
        this.podData = podData;
      });
    });
  }

  /// Get the number of members in the pod and check if I'm a member
  void _getMembersInPod() {
    final membersListener = PodsDatabasePaths(podID: podID)
        .podDocument
        .collection("members")
        .where("blocked", isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _podMembersList.clear(); // clear the list, then rebuild it in the next step
      snapshot.docs.forEach((document) {
        final memberID = document.id;
        final memberData = document.data();
        final personData =
            ProfileDatabasePaths.extractProfileDataFromSnapshot(userID: memberID, snapshotValue: memberData);
        if (!_podMembersList.contains(personData)) _podMembersList.add(personData);
      });

      // Updates the shared object so that if I can read from it if I want to view the pod members. I decided
      // to do it this way rather than directly passing the pod members into a MainListDisplayView object.
      // Either way works; it doesn't really matter.
      PodMembersDictionary.sharedInstance.dictionary.value[podID] = _podMembersList;

      setState(() {
        this._numberOfMembers = snapshot.docs.length;
        this._amMemberOfPod = _podMembersList.map((person) => person.userID).contains(myFirebaseUserId);
      });
    });
    _streamSubs.add(membersListener);
  }

  /// Get the pod blocked users and check if I'm blocked
  void _getBlockedUsers() {
    final blockedListener = PodsDatabasePaths(podID: podID)
        .podDocument
        .collection("members")
        .where("blocked", isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _podBlockedUsersList.clear(); // clear the list, then rebuild it in the next step
      snapshot.docs.forEach((document) {
        final blockedUserID = document.id;
        final blockedUserData = document.data();
        final personData =
            ProfileDatabasePaths.extractProfileDataFromSnapshot(userID: blockedUserID, snapshotValue: blockedUserData);
        if (!_podBlockedUsersList.contains(personData)) _podBlockedUsersList.add(personData);
      });

      // Updates the shared object so that if I can read from it if I want to view the pod members. I decided
      // to do it this way rather than directly passing the pod members into a MainListDisplayView object.
      // Either way works; it doesn't really matter.
      PodMembersDictionary.sharedInstance.blockedDictionary.value[podID] = _podBlockedUsersList;

      setState(() {
        this._amBlockedFromPod = _podBlockedUsersList.map((person) => person.userID).contains(myFirebaseUserId);
      });
    });
    _streamSubs.add(blockedListener);
  }

  /// Show a confirmation alert and join a pod
  void _joinPod() {
    if (_podMembersList.length == 0) return; // don't allow joining a deleted pod. Otherwise there would be
    // problems.
    final confirmationAlert = CupertinoAlertDialog(
      title: Text("Join Pod"),
      content: Text("Are you sure you want to "
          "join ${podData.name}?"),
      actions: [
        // cancel button
        CupertinoButton(
            child: Text("No"),
            onPressed: () {
              dismissAlert(context: context);
            }),

        // join button
        CupertinoButton(
            child: Text("Yes"),
            onPressed: () {
              dismissAlert(context: context);

              // join the pod
              final myProfile = MyProfileTabBackendFunctions.shared.myProfileData.value;
              final joinedTimeInSeconds = DateTime.now().millisecondsSinceEpoch * 0.001;
              final myJoinData = PodMemberInfoDict(
                  userID: myProfile.userID,
                  bio: myProfile.bio,
                  birthday: myProfile.birthday,
                  joinedAt: joinedTimeInSeconds,
                  name: myProfile.name,
                  thumbnailURL: myProfile.thumbnailURL);
              PodsDatabasePaths(podID: podID).joinPod(
                  personData: myJoinData,
                  onSuccess: () {
                    final successAlert = CupertinoAlertDialog(
                      title: Text("You Joined ${podData.name}"),
                      actions: [
                        CupertinoButton(
                            child: Text("OK"),
                            onPressed: () {
                              dismissAlert(context: context);
                            })
                      ],
                    );
                    showCupertinoDialog(context: context, builder: (context) => successAlert);
                  });
            })
      ],
    );
    showCupertinoDialog(context: context, builder: (context) => confirmationAlert);
  }

  /// Show a confirmation alert to leave a pod
  void _leavePod() {
    final alertContent = _podMembersList.length > 1
        ? "Are you sure you want to leave ${podData.name}"
        : "You are the"
            " last member of ${podData.name}. Leaving will delete the pod.";
    final leavePodAlert = CupertinoAlertDialog(
      title: Text("Leave Pod"),
      content: Text(alertContent),
      actions: [
        // cancel button
        CupertinoButton(
            child: Text("No"),
            onPressed: () {
              dismissAlert(context: context);
            }),

        // leave button
        CupertinoButton(
            child: Text(
              "Yes",
              style: TextStyle(
                  color: _podMembersList.length > 1 ? CupertinoColors.systemBlue : CupertinoColors.destructiveRed),
            ),
            onPressed: () {
              dismissAlert(context: context);
              final myName = MyProfileTabBackendFunctions.shared.myProfileData.value.name;

              // If I'm not the last person, then send a message in the chat saying that I left
              PodsDatabasePaths(podID: podID, userID: myFirebaseUserId).leavePod(
                  podName: podData.name,
                  personName: myName,
                  shouldTextPodMembers: _podMembersList.length > 1,
                  onSuccess: () {
                    final successAlert = CupertinoAlertDialog(
                      title: Text(_podMembersList.length > 0 ? "You left ${podData.name}" : "Pod Deleted"),
                      content: _podMembersList.length > 0
                          ? null
                          : Text("You were the last person to leave ${podData.name}, causing it to be deleted"),
                      actions: [
                        CupertinoButton(
                            child: Text("OK"),
                            onPressed: () {
                              // pop twice if the pod is deleted to dismiss the alert and go back a screen
                              if (_podMembersList.length > 0)
                                dismissAlert(context: context);
                              else {
                                int popCount = 0;
                                Navigator.of(context, rootNavigator: true).popUntil((_) => popCount++ >= 2);
                              }
                            })
                      ],
                    );
                    showCupertinoDialog(context: context, builder: (context) => successAlert);
                  });
            })
      ],
    );
    showCupertinoDialog(context: context, builder: (context) => leavePodAlert);
  }

  /// Show a confirmation alert to delete a pod
  void _deletePod() {
    final deletePodAlert = CupertinoAlertDialog(
      title: Text("Delete Pod"),
      content: Text("Are you sure you want to "
          "delete ${podData.name}? You cannot undo this action."),
      actions: [
        // cancel button
        CupertinoButton(
            child: Text("No"),
            onPressed: () {
              dismissAlert(context: context);
            }),

        // delete button
        CupertinoButton(
            child: Text("Yes", style: TextStyle(color: CupertinoColors.destructiveRed)),
            onPressed: () {
              dismissAlert(context: context);
              PodsDatabasePaths(podID: podID).deletePod(
                  podName: podData.name,
                  onCompletion: () {
                    final deletedAlert = CupertinoAlertDialog(
                      title: Text("${podData.name} Deleted"),
                      actions: [
                        CupertinoButton(
                            child: Text("OK"),
                            onPressed: () {
                              // pop twice if the pod is deleted to dismiss the alert and go back a screen
                              int popCount = 0;
                              Navigator.of(context, rootNavigator: true).popUntil((_) => popCount++ >= 2);
                            })
                      ],
                    );
                    showCupertinoDialog(context: context, builder: (context) => deletedAlert);
                  });
            })
      ],
    );
    showCupertinoDialog(context: context, builder: (context) => deletePodAlert);
  }

  /// Create the trailing widget on the navigation bar with the option to view members, blocked users, leave pod,
  /// edit pod (if I'm the creator), or delete pod (if I'm the creator)
  CupertinoButton _navBarTrailingButton() => CupertinoButton(
      child: Icon(CupertinoIcons.line_horizontal_3),
      onPressed: () {
        final sheet = CupertinoActionSheet(
          title: Text("Pod Options"),
          actions: [
            // For convenience, also show a Join Pod option if I'm not a member. THe difference between the other
            // button below the pod photo is that this button will show even if I'm blocked or if the pod doesn't
            // allow anyone to join. This button will warn me why I can't join. Unless there's nobody in the pod (if
            // it was deleted). Then just don't show the button.
            if (!_amMemberOfPod && _podMembersList.length > 0)
              CupertinoActionSheetAction(
                  onPressed: () {
                    dismissAlert(context: context);

                    // You Are Blocked alert
                    if (_amBlockedFromPod) {
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
                      _joinPod();
                    }
                  },
                  child: Text("Join Pod")),

            // Navigate to view the members (redundant capability in case users don't realize they can see the members by
            // tapping on the member count (anyone can see the pod members to help them decide if they want to join)
            CupertinoActionSheetAction(
                onPressed: () {
                  dismissAlert(context: context);
                  Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                      builder: (context) => MainListDisplayView(
                            viewMode: MainListDisplayViewModes.podMembers,
                            podMembers: _podMembersList,
                            podData: podData,
                          )));
                },
                child: Text("Pod Members")),

            // Navigate to view the blocked users (only show this option if I'm a member, for privacy reasons)
            if (_amMemberOfPod)
              CupertinoActionSheetAction(
                  onPressed: () {
                    dismissAlert(context: context);
                    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                        builder: (context) => MainListDisplayView(
                              viewMode: MainListDisplayViewModes.podBlockedUsers,
                              podMembers: _podBlockedUsersList,
                              podData: podData,
                            )));
                  },
                  child: Text("Blocked Users")),

            // Edit the pod, if I'm the creator and a member
            if (_amMemberOfPod && podData.podCreatorID == myFirebaseUserId)
              CupertinoActionSheetAction(
                  onPressed: () {
                    dismissAlert(context: context);
                    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                        builder: (context) => CreateAPodView(
                              isCreatingNewPod: false,
                              podID: podID,
                            )));
                  },
                  child: Text("Edit Pod")),

            // Leave the pod, if I'm a member
            if (_amMemberOfPod)
              CupertinoActionSheetAction(
                  onPressed: () {
                    dismissAlert(context: context);
                    _leavePod();
                  },
                  child: Text("Leave Pod")),

            // Delete the pod, if I'm the creator and a member
            if (_amMemberOfPod && podData.podCreatorID == myFirebaseUserId)
              CupertinoActionSheetAction(
                  onPressed: () {
                    dismissAlert(context: context);
                    _deletePod();
                  },
                  child: Text(
                    "Delete Pod",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  )),

            // Help button
            CupertinoActionSheetAction(
                onPressed: () {
                  dismissAlert(context: context);
                  //TODO: create the Help sheet
                },
                child: Text("Help")),

            // Cancel button
            CupertinoActionSheetAction(
              onPressed: () {
                dismissAlert(context: context);
              },
              child: Text("Cancel"),
              isDefaultAction: true,
            )

            // If I'm the pod creator
          ],
        );
        showCupertinoModalPopup(context: context, builder: (context) => sheet);
      },
      padding: EdgeInsets.zero);

  @override
  void initState() {
    super.initState();
    this._getPodData();
    this._getMembersInPod();
    this._getBlockedUsers();
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubs.forEach((subscription) {
      subscription.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          padding: EdgeInsetsDirectional.all(5),
          middle: Text(podData.name),
          trailing: _navBarTrailingButton(),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Pod profile photo. Tap it to view the full photo
                  // Not a typo. The image should be a square with both dimensions equal to the screen width. This
                  // ensures that the image will fill the proper space even when loading.
                  GestureDetector(
                    child: DecoratedImage(
                      imageURL: podData.fullPhotoURL,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width,
                    ),
                    onTap: () {
                      // Navigate to view the full photo as a zoomable image
                      Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                          builder: (context) => ViewFullImage(
                              urlForImageToView: podData.fullPhotoURL,
                              imageID: "doesn't matter",
                              navigationBarTitle: podData.name,
                              canWriteCaption: false)));
                    },
                  ),
                  SizedBox(
                    height: 10,
                  ),

                  // Pod name, members, and chat button at the top. Description below that.
                  Card(
                      child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pod name, members, and chat button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // pod name with number of members below it
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CupertinoButton(
                                  alignment: Alignment.topCenter,
                                  minSize: 35,
                                  child: Text(podData.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                                  onPressed: () {
                                    final podScoreSheet = CupertinoActionSheet(
                                      title: Text(podData.name),
                                      message: Text("Team Podscore: ${podData.podScore}"),
                                      actions: [
                                        CupertinoActionSheetAction(
                                            onPressed: () {
                                              dismissAlert(context: context);
                                            },
                                            child: Text("OK"))
                                      ],
                                    );
                                    showCupertinoModalPopup(context: context, builder: (context) => podScoreSheet);
                                  },
                                  padding: EdgeInsets.zero,
                                ),

                                // Tap on the number of members to navigate to view the members
                                CupertinoButton(
                                  alignment: Alignment.topCenter,
                                  child: Text(
                                      _numberOfMembers == 1 ? "$_numberOfMembers member" : "$_numberOfMembers members",
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: isDarkMode ? CupertinoColors.white : CupertinoColors.black)),
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                                        builder: (context) => MainListDisplayView(
                                              viewMode: MainListDisplayViewModes.podMembers,
                                              podMembers: _podMembersList,
                                              podData: podData,
                                            )));
                                  },
                                  padding: EdgeInsets.zero,
                                  minSize: 35,
                                ),
                              ],
                            ),
                            Spacer(),

                            // If I'm a member and the navigation stack permits it, then show the Chat button
                            if (showChatButton && _amMemberOfPod)
                              CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.topCenter,
                                  child: Row(
                                    children: [
                                      Text("Chat"),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Icon(CupertinoIcons.paperplane)
                                    ],
                                  ),
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                                        builder: (context) => MessagingView(
                                            chatPartnerOrPodID: podData.podID,
                                            chatPartnerOrPodName: podData.name,
                                            isPodMode: true)));
                                  }),

                            // If the pod allows anyone to join (or I created the pod) and I'm not a member (and am
                            // also not blocked), show the
                            // Join button. You also can't join a pod that has no members, as that pod would've been
                            // deleted.
                            if (!_amMemberOfPod &&
                                !_amBlockedFromPod &&
                                (podData.anyoneCanJoin || podData.podCreatorID == myFirebaseUserId) &&
                                _podMembersList.length > 0)
                              CupertinoButton(
                                child: Row(
                                  children: [
                                    Icon(CupertinoIcons.plus),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text("Join"),
                                  ],
                                ),
                                onPressed: _joinPod,
                                padding: EdgeInsets.zero,
                                alignment: Alignment.topCenter,
                              ),
                          ],
                        ),

                        // pod description
                        Text(
                          podData.description,
                          style: TextStyle(fontSize: 15),
                        )
                      ],
                    ),
                  ))
                ],
              ),
            ),
          ),
        ));
  }
}
