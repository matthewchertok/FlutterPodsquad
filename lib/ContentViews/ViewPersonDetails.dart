import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendDataclasses/NotificationTypes.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/BackendFunctions/PushNotificationSender.dart';
import 'package:podsquad/BackendFunctions/ReportedPeopleBackendFunctions.dart';
import 'package:podsquad/BackendFunctions/TimeAndDateFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/AlertDialogs.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/MessagingView.dart';
import 'package:podsquad/ContentViews/ViewFullImage.dart';
import 'package:podsquad/DatabasePaths/PodsDatabasePaths.dart';
import 'package:podsquad/OtherSpecialViews/DecoratedImage.dart';
import 'package:podsquad/OtherSpecialViews/MultiImagePageViewer.dart';
import 'package:podsquad/OtherSpecialViews/TutorialSheets.dart';
import 'package:podsquad/OtherSpecialViews/ViewPersonDetailsDrawer.dart';
import 'package:podsquad/UIBackendClasses/MainListDisplayBackend.dart';
import 'package:podsquad/UIBackendClasses/MessagesDictionary.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'package:uuid/uuid.dart';

class ViewPersonDetails extends StatefulWidget {
  const ViewPersonDetails({Key? key, required this.personID, this.messagingEnabled = true}) : super(key: key);
  final String personID;
  final bool messagingEnabled;

  @override
  _ViewPersonDetailsState createState() =>
      _ViewPersonDetailsState(personID: this.personID, messagingEnabled: this.messagingEnabled);
}

//TODO: Get the person's pod memberships and display them; also enable adding a person to a pod

class _ViewPersonDetailsState extends State<ViewPersonDetails> {
  _ViewPersonDetailsState({required this.personID, required this.messagingEnabled});

  final String personID;
  final bool messagingEnabled;

  bool didLikeUser = false;
  bool didFriendUser = false;
  bool didBlockUser = false;
  bool didReportUser = false;

  /// Determine whether the other person blocked me, and disable features accordingly.
  bool _wasBlockedByUser = false;

  /// A list of every pod that the user is in
  List<PodData> _personsPodMemberships = [];

  /// A list of all stream subscriptions (so they can be cancelled)
  List<StreamSubscription> _streamSubsList = [];

  /// This will store the user's profile data. It gets updated inside initState.
  ProfileData personData = ProfileData.blank;

  /// Get the person's profile data from Firestore
  Future _getProfileData() async {
    final completer = Completer();
    MyProfileTabBackendFunctions.shared.getPersonsProfileData(
        userID: personID,
        onCompletion: (profileData) {
          setState(() {
            this.personData = profileData;
          });
          completer.complete();
        });
    return completer.future;
  }

  /// Get the person's pod memberships
  void _getPodMemberships() {
    // If I'm looking at my own profile, there is no need to download anything extra: just read in my pod memberships
    if (personID == myFirebaseUserId) {
      this._personsPodMemberships = ShowMyPodsBackendFunctions.shared.sortedListOfPods.value;
      ShowMyPodsBackendFunctions.shared.sortedListOfPods.addListener(() {
        final myPods = ShowMyPodsBackendFunctions.shared.sortedListOfPods.value;
        // No need to sort here since MainListDisplay view will sort the list alphabetically
        if (mounted) setState(() {
          this._personsPodMemberships = myPods;
        });
      });
    } else {
      final listener = firestoreDatabase
          .collectionGroup("members")
          .where("userID", isEqualTo: personID)
          .snapshots()
          .listen((snapshot) {
        snapshot.docChanges.forEach((diff) {
          final podID = diff.doc.reference.parent.parent?.id;
          if (podID != null) {
            if (diff.type == DocumentChangeType.added) {
              _getDataForPod(podID: podID);
            } else if (diff.type == DocumentChangeType.removed) {
              this._personsPodMemberships.removeWhere((pod) => pod.podID == podID);
            }
          }
        });
      });
      _streamSubsList.add(listener);
    }
  }

  /// Downloads data for a specified pod and adds it to the list of pods the user is in
  void _getDataForPod({required String podID}) {
    /// Use a stream subscription (not single get() call) to enable reading form the cache to improve offline
    /// performance and reduce reads.
    final listener = PodsDatabasePaths(podID: podID).podDataStream(onCompletion: (PodData podData) {
      this._personsPodMemberships.add(podData);
    });
    _streamSubsList.add(listener);
  }

  /// Show an alert and if the user agrees, send an auto-generated message
  Future<void> _sendAutoGeneratedMessage() async {
    final completer = Completer();
    final alert = CupertinoAlertDialog(
      title: Text("Start Conversation"),
      content: Text("Nervous about reaching out? "
          "Tap Send and we'll take care of that for you!"),
      actions: [
        CupertinoButton(
            child: Text("Cancel"),
            onPressed: () {
              dismissAlert(context: context);
            }),
        CupertinoButton(
            child: Text("Send"),
            onPressed: () async {
              dismissAlert(context: context);
              if (this._wasBlockedByUser)
                showSingleButtonAlert(
                    context: context,
                    title: "Unable To Start Conversation",
                    content: "${personData.name} blocked you.",
                    dismissButtonLabel: "OK");
              else if (this.didBlockUser)
                showSingleButtonAlert(
                    context: context,
                    title: "Unable To Start "
                        "Conversation",
                    content: "You blocked ${personData.name}",
                    dismissButtonLabel: "OK");
              else {
                // the conversation ID is an alphabetical combination of our user IDs.
                final conversationID = personData.userID < myFirebaseUserId
                    ? personData.userID + myFirebaseUserId
                    : myFirebaseUserId + personData.userID;
                final user1ID = personData.userID < myFirebaseUserId ? personData.userID : myFirebaseUserId; // lower
                // alphabetically
                final user2ID = personData.userID < myFirebaseUserId ? myFirebaseUserId : personData.userID; // higher
                // alphabetically

                await firestoreDatabase.collection("dm-conversations").doc(conversationID).set({
                  user1ID: {"didHideChat": false},
                  user2ID: {"didHideChat": false},
                  "participants": [user1ID, user2ID]
                }, SetOptions(merge: true));

                // now create a random message ID
                final randomID = Uuid().v1();
                final timestamp = DateTime.now().millisecondsSinceEpoch * 0.001;
                Map<String, dynamic> dmMessageDictionary = {
                  "id": randomID,
                  "recipientId": personData.userID,
                  "senderId": myFirebaseUserId,
                  "systemTime": timestamp,
                  "text": "Hi ${personData.name.firstName()}!"
                };
                dmMessageDictionary["readBy"] = [myFirebaseUserId];
                dmMessageDictionary["readTime"] = {myFirebaseUserId: timestamp};
                dmMessageDictionary["readName"] = {
                  myFirebaseUserId: MyProfileTabBackendFunctions.shared.myProfileData.value.name
                };
                dmMessageDictionary["senderName"] = MyProfileTabBackendFunctions.shared.myProfileData.value.name;
                dmMessageDictionary["recipientName"] = personData.name;
                dmMessageDictionary["senderThumbnailURL"] =
                    MyProfileTabBackendFunctions.shared.myProfileData.value.thumbnailURL;
                dmMessageDictionary["recipientThumbnailURL"] = personData.thumbnailURL;

                await firestoreDatabase
                    .collection("dm-conversations")
                    .doc(conversationID)
                    .collection("messages")
                    .doc(randomID)
                    .set(dmMessageDictionary);
                showSingleButtonAlert(context: context, title: "Message Sent!", dismissButtonLabel: "OK");

                // send a push notification
                final sender = PushNotificationSender();
                sender.sendPushNotification(recipientDeviceTokens: personData.fcmTokens, title: "New Message", body:
                "from ${MyProfileTabBackendFunctions.shared.myProfileData.value.name}", notificationType:
                NotificationTypes.message);
                completer.complete();
              }
            })
      ],
    );
    await showCupertinoDialog(context: context, builder: (context) => alert);
    return completer.future;
  }

  /// Continuously listen to whether the other person blocked me
  void _checkIfTheOtherPersonBlockedMe() {
    final listener = firestoreDatabase
        .collection("blocked-users")
        .where("blocker.userID", isEqualTo: personData.userID)
        .where("blockee.userID", isEqualTo: myFirebaseUserId)
        .snapshots()
        .listen((event) {
      final didTheyBlockMe = event.docs.length > 0; // they blocked me if the document exists
      setState(() {
        this._wasBlockedByUser = didTheyBlockMe;
      });

      // if I'm blocked, then take me away from the user's profile
      if (didTheyBlockMe) {
        showSingleButtonAlert(
                context: context,
                title: "Permission Denied",
                content: "${personData.name} blocked "
                    "you.",
                dismissButtonLabel: "OK")
            .then((_) {
          Navigator.of(context, rootNavigator: true).pop();
        });
      }
    });
    _streamSubsList.add(listener);
  }

  /// Convert the user's preferred relationship type into a user-friendly string
  String _preferredRelationshipTypeText({required String lookingFor}) {
    if (lookingFor == UsefulValues.lookingForFriends)
      return "Looking for friends!";
    else if (lookingFor == UsefulValues.lookingForGirlfriend)
      return "Looking for a girlfriend!";
    else if (lookingFor == UsefulValues.lookingForBoyfriend)
      return "Looking for a boyfriend!";
    else if (lookingFor == UsefulValues.lookingForAnyGenderDate)
      return "Looking for a date!";
    else
      return "Preferred relationship type unknown";
  }

  @override
  void initState() {
    super.initState();
    this._getProfileData().then((_) {
      this._checkIfTheOtherPersonBlockedMe();
      if (personID != myFirebaseUserId)
        showViewPersonDetailsTutorialIfNecessary(context: context, personData: personData);
    });
    this._getPodMemberships();

    // Determine if I already liked/friended/blocked/reported the user
    this.didLikeUser = SentLikesBackendFunctions.shared.sortedListOfPeople.value.memberIDs().contains(personID);
    this.didFriendUser = SentFriendsBackendFunctions.shared.sortedListOfPeople.value.memberIDs().contains(personID);
    this.didBlockUser = SentBlocksBackendFunctions.shared.sortedListOfPeople.value.memberIDs().contains(personID);
    this.didReportUser = ReportedPeopleBackendFunctions.shared.peopleIReportedList.value.contains(personID);

    // Add listeners that will update if I like/friend/block/report the user
    SentLikesBackendFunctions.shared.sortedListOfPeople.addListener(() {
      final didLikeUser = SentLikesBackendFunctions.shared.sortedListOfPeople.value.contains(personData);
      if (mounted) setState(() {
        this.didLikeUser = didLikeUser;
        print(
            "I liked someone! Here's that person: ${SentLikesBackendFunctions.shared.sortedListOfPeople.value.last.name}. Thus, didLikeUser is equal to $didLikeUser because the user's ID is ${SentLikesBackendFunctions.shared.sortedListOfPeople.value.last.userID}");
      });
    });

    SentFriendsBackendFunctions.shared.sortedListOfPeople.addListener(() {
      final didFriendUser = SentFriendsBackendFunctions.shared.sortedListOfPeople.value.contains(personData);
      if (mounted) setState(() {
        this.didFriendUser = didFriendUser;
      });
    });

    SentBlocksBackendFunctions.shared.sortedListOfPeople.addListener(() {
      final didBlockUser = SentBlocksBackendFunctions.shared.sortedListOfPeople.value.contains(personData);
      if (mounted)
        setState(() {
          this.didBlockUser = didBlockUser;
        });
    });

    ReportedPeopleBackendFunctions.shared.peopleIReportedList.addListener(() {
      final didReportUser = ReportedPeopleBackendFunctions.shared.peopleIReportedList.value.contains(personID);
      if (mounted) setState(() {
        this.didReportUser = didReportUser;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    SentLikesBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    SentFriendsBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    SentBlocksBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    ReportedPeopleBackendFunctions.shared.peopleIReportedList.removeListener(() {});
    ShowMyPodsBackendFunctions.shared.sortedListOfPods.removeListener(() {});
    _streamSubsList.forEach((stream) {
      stream.cancel();
    });
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: Locale('en', 'US'),
      delegates: [DefaultWidgetsLocalizations.delegate, DefaultMaterialLocalizations.delegate],
      child: Scaffold(
          backgroundColor: isDarkMode ? CupertinoColors.black : CupertinoColors.white,
          key: _scaffoldKey,
          appBar: CupertinoNavigationBar(
            padding: EdgeInsetsDirectional.all(5),
            middle: Text(personID == myFirebaseUserId ? "My Profile" : "${personData.name.firstName()}'s Profile"),
            trailing: personID == myFirebaseUserId || _wasBlockedByUser
                ? Container(width: 0, height: 0)
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.line_horizontal_3),
                    onPressed: () {
                      // show the action sheet to like/friend/block/report
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
          ),
          endDrawer: viewPersonDetailsDrawer(
              context: context,
              didLikeUser: didLikeUser,
              didFriendUser: didFriendUser,
              didBlockUser: didBlockUser,
              didReportUser: didReportUser,
              personData: personData,
              personsPodMemberships: this._personsPodMemberships),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Swipe left on the profile photo to view the person's extra images. Tap it to view the person's
                    // profile image.
                    // Not a typo. The image should be a square with both dimensions equal to the screen width. This
                    // ensures that the image will fill the proper space even when loading.
                    GestureDetector(
                      child: DecoratedImage(
                        imageURL: personData.fullPhotoURL,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width,
                      ),
                      onTap: () {
                        // tap to view the person's full profile image
                        Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                            builder: (context) => ViewFullImage(
                                urlForImageToView: personData.fullPhotoURL,
                                imageID: "doesn't matter",
                                navigationBarTitle: personID == myFirebaseUserId ? "My Profile Image" : personData.name,
                                canWriteCaption: false)));
                      },
                      onPanUpdate: (swipe) {
                        // swipe left to view the person's extra images
                        if (swipe.delta.dx < 0)
                          Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                              builder: (context) => MultiImagePageViewer(
                                  imagesList: personData.extraImagesList ?? [],
                                  personId: personData.userID,
                                  personName: personData.name)));
                      },
                    ),
                    SizedBox(
                      height: 10,
                    ),

                    // Name, age, school, relationship type, bio on the left, Message and Say Hi buttons on the right
                    Card(
                        color: isDarkMode ? CupertinoColors.black : CupertinoColors.white,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Contains name, age, school, lookingFor, Message button, and Say Hi button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // name, age, school, relationship type, and bio column
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // The name field should be a button that opens an action sheet that will show the user's podScore
                                      // and an option to view their pods
                                      Text(
                                        personData.name,
                                        style: TextStyle(
                                            fontSize: 18.scaledForScreenSize(context: context),
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                                      ),
                                      SizedBox(height: 15),

                                      // The person's age
                                      Text(
                                        TimeAndDateFunctions.getAgeFromBirthday(birthday: personData.birthday)
                                            .toString(),
                                        style: TextStyle(
                                            fontSize: 15.scaledForScreenSize(context: context),
                                            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                                      ),
                                      SizedBox(
                                        height: 15,
                                      ),

                                      // The person's school
                                      Text(
                                        personData.school,
                                        style: TextStyle(
                                            fontSize: 15.scaledForScreenSize(context: context),
                                            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                                      ),
                                      SizedBox(
                                        height: 15,
                                      ),

                                      // Who they're looking for
                                      Text(
                                        _preferredRelationshipTypeText(
                                            lookingFor: personData.preferredRelationshipType),
                                        style: TextStyle(
                                            fontSize: 15.scaledForScreenSize(context: context),
                                            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                                      ),
                                    ],
                                  ),
                                  Spacer(),

                                  // Message and "Say Hi" button (don't show if I'm viewing my own profile or if I am
                                  // blocked or if I navigated from Messaging and want the user to navigate back rather
                                  // than further into the stack)
                                  if (personID != myFirebaseUserId &&
                                      messagingEnabled &&
                                      !_wasBlockedByUser &&
                                      !didBlockUser)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        // Message button
                                        CupertinoButton(
                                            alignment: Alignment.topCenter,
                                            padding: EdgeInsets.zero,
                                            child: Row(
                                              children: [
                                                Text("Message"),
                                                SizedBox(
                                                  width: 5,
                                                ),
                                                Icon(CupertinoIcons.paperplane),
                                              ],
                                            ),
                                            onPressed: () {
                                              Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                                                  builder: (context) => MessagingView(
                                                      chatPartnerOrPodID: personData.userID,
                                                      chatPartnerOrPodName: personData.name,
                                                      chatPartnerThumbnailURL: personData.thumbnailURL,
                                                      isPodMode: false)));
                                            }),

                                        // Say Hi button (only show this button if I don't already have a conversation with
                                        // the user - meaning that the messages list is either empty or null)
                                        if ((MessagesDictionary
                                                .shared.directMessagesDict.value[personData.userID]?.isEmpty) ??
                                            true)
                                          CupertinoButton(
                                              alignment: Alignment.topCenter,
                                              padding: EdgeInsets.zero,
                                              child: Row(
                                                children: [
                                                  Text("Say Hi!"),
                                                  SizedBox(
                                                    width: 5,
                                                  ),
                                                  Icon(CupertinoIcons.hand_raised),
                                                ],
                                              ),
                                              onPressed: this._sendAutoGeneratedMessage)
                                      ],
                                    )
                                ],
                              ),

                              // The person's bio
                              SizedBox(
                                height: 15,
                              ),

                              Text(
                                personData.bio.isNotEmpty
                                    ? personData.bio
                                    : (personData.userID == myFirebaseUserId ? "You haven't written a bio yet!" : "${personData
                                    .name
                                    .firstName
                                  ()} hasn't "
                                        "written a bio yet!"),
                                style: TextStyle(
                                    fontSize: 15.scaledForScreenSize(context: context),
                                    color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                              )
                            ],
                          ),
                        ))
                  ],
                ),
              ),
            ),
          )),
    );
  }
}
