import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_nearby_messages_api/flutter_nearby_messages_api.dart';
import 'package:podsquad/BackendDataclasses/NotificationTypes.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'dart:async';
import 'package:podsquad/DatabasePaths/ProfileDatabasePaths.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'package:permission_handler/permission_handler.dart';

import 'PushNotificationSender.dart';

///Discovers users nearby
class NearbyScanner {
  static final shared = NearbyScanner();
  final _pushSender = PushNotificationSender();

  // initialize the API
  FlutterNearbyMessagesApi nearbyMessagesApi = FlutterNearbyMessagesApi();

  /// Stores the user ID of everyone I met, along with the time that I met them. The time is needed because Flutter's
  /// version of Google Nearby continuously publishes and subscribes, meaning that I'll use up reads far too quickly
  /// by default. This map stores {userID: timeIMetThePerson}. Thus, I can use it to check if I met the person less
  /// than 10 minutes ago, and if that's the case, don't meet them again.
  Map<String, DateTime> _peopleIMetAndTimeMap = {};

  ///Begin searching for nearby users over Bluetooth
  Future<void> publishAndSubscribe() async {
    if (myFirebaseUserId.isEmpty) return; // don't proceed if I'm not signed in

    // config for iOS
    await nearbyMessagesApi.setAPIKey("AIzaSyAFdNMfNpASvuVViGHB7lL4dMtgwLKWip4");

    nearbyMessagesApi.setPermissionAlert('Allow Bluetooth Permission?',
        'Podsquad requires Bluetooth permission to discover nearby users.', 'Deny', 'Grant');
    await Permission.bluetooth.request();

    // first, get the list of people I already met (so that I don't create repeated notifications if I meet the same
    // person multiple times)
    this._peopleIMetAndTimeMap = await _getListOfPeopleIAlreadyMet();

    // Publish my ID for other users to discover
    await nearbyMessagesApi.publish(myFirebaseUserId);

    // allow subscribing in the background
    await nearbyMessagesApi.backgroundSubscribe();

    // Enable debug mode
    await nearbyMessagesApi.enableDebugMode();

    // This callback gets the message when an a nearby device sends one
    nearbyMessagesApi.onFound = (message) {
      print("MESSAGE FOUND $message");
      _meetSomeone(personID: message).then((otherPersonsProfileData) {
        if (otherPersonsProfileData != null) {
          final tokens = otherPersonsProfileData.fcmTokens;
          this._sendTheOtherPersonAPushNotificationIfWeHaveNotMetRecently(
              recipientID: otherPersonsProfileData.userID, toDeviceTokens: tokens);
        }
      }); // the message
      // contains the person's ID
    };

    nearbyMessagesApi.onLost = (message) {
      print("MESSAGE LOST: $message");
    };

    // Listen status when publish and subscribe
    // enum GNSOperationStatus { inactive, starting, active }
    nearbyMessagesApi.statusHandler = (status) {
      print('~~~statusHandler : $status');
      // notify the UI of status changes
      if (status == GNSOperationStatus.active)
        ScanningStatus.shared.inProgress.value = true;
      else
        ScanningStatus.shared.inProgress.value = false;
    };
  }

  ///Stop searching for nearby users over Bluetooth
  void stopPublishAndSubscribe() async {
    await nearbyMessagesApi.unPublish();
    await nearbyMessagesApi.backgroundUnsubscribe();
  }

  /// Get the list of user IDs for everyone I previously met in the last 21 days.
  Future<Map<String, DateTime>> _getListOfPeopleIAlreadyMet() async {
    /// Use a listener to allow reading from the cache, which will significantly reduce reads in cases where the app
    /// is opened multiple times in a short time span.
    final completer = Completer<Map<String, DateTime>>();
    StreamSubscription? listener;
    listener = ProfileDatabasePaths(userID: myFirebaseUserId)
        .listOfPeopleIMetRef
        .where("people", arrayContains: myFirebaseUserId)
        .snapshots()
        .listen((snapshot) {
      Map<String, DateTime> peopleIMetIDsAndTimesMap = {};
      snapshot.docs.forEach((personIAlreadyMetDocument) {
        final timeIMetThem = personIAlreadyMetDocument.get("time") as num; // this is time since epoch in SECONDS, not
        // milliseconds
        final peopleListRaw = personIAlreadyMetDocument.get("people") as List<dynamic>;
        final peopleList = List<String>.from(peopleListRaw); // convert the dynamic list to a String list
        if (peopleList.length >= 2) {
          final otherPersonsUserID = peopleList.first == myFirebaseUserId ? peopleList.last : peopleList.first;
          peopleIMetIDsAndTimesMap[otherPersonsUserID] =
              DateTime.fromMillisecondsSinceEpoch((timeIMetThem * 1000).toInt());
        }
      });
      listener?.cancel(); // cancel the listener since it's no longer needed
      completer.complete(peopleIMetIDsAndTimesMap);
    });
    return completer.future;
  }

  /// Called as part of meetSomeone(). Checks to make sure neither of use blocked the other before allowing us to meet.
  /// Returns a boolean as a future. At least for now, this uses a single get() call instead of a listen() call
  /// because it's very important that the data is up-to-date. We don't want someone to be allowed to meet someone
  /// else because the cached data said they weren't blocked but in reality, they were blocked a couple minutes ago.
  Future<bool> _didEitherOfUsBlockTheOther({required String receivedUserID}) async {
    // find out if I blocked the user
    final didIBlockThemTask = firestoreDatabase
        .collection("blocked-users")
        .where("blocker.userID", isEqualTo: myFirebaseUserId)
        .where("blockee.userID", isEqualTo: receivedUserID)
        .get();
    final didIBlockThemResult = await didIBlockThemTask;
    final didIBlockThem = didIBlockThemResult.docs.length > 0; // I blocked them if a document exists

    final didTheyBlockMeTask = firestoreDatabase
        .collection("blocked-users")
        .where("blocker.userID", isEqualTo: receivedUserID)
        .where("blockee.userID", isEqualTo: myFirebaseUserId)
        .get();
    final didTheyBlockMeResult = await didTheyBlockMeTask;
    final didTheyBlockMe = didTheyBlockMeResult.docs.length > 0; // They blocked me if a document exists

    final didEitherOrUsBlockTheOther = didIBlockThem || didTheyBlockMe;
    return didEitherOrUsBlockTheOther;
  }

  /// Meet a person by preparing and uploading the document to Firestore. The breakInterval parameter defaults to 10
  /// and represent the number of minutes that must pass before it's worth updating the document in the database. For
  /// example, if I meet someone now, then don't update the database if I meet them again in less than 10 minutes.
  /// The purpose of this is to save reads and writes, as Flutter defaults to continuous subscribing (unlike iOS),
  /// which would quickly run up costs in database reads and writes. Returns the recipient's profile data so I can
  /// send them a push notification directly.
  Future<ProfileData?> _meetSomeone({required String personID, int breakInterval = 10}) async {
    print("I met a user with ID $personID");
    // If I never met the person before, pretend I met them long enough ago that the function can execute.
    if (this._peopleIMetAndTimeMap[personID] == null)
      this._peopleIMetAndTimeMap[personID] = DateTime.now().add(Duration(minutes: -breakInterval));

    // If I met the person less than the specified breakInterval number of minutes ago, then don't bother to update
    // the data - I met them too recently for anything to have changed, so there's no need to spend reads and writes.
    final minutesSinceILastMetThem = DateTime.now().difference(this._peopleIMetAndTimeMap[personID]!).inMinutes;
    if (minutesSinceILastMetThem < breakInterval) return null;

    this._peopleIMetAndTimeMap[personID] = DateTime.now(); // If I met them awhile ago, then update the time to now
    print('Discovered user with ID : $personID'); // for debugging

    final didEitherOfUseBlockTheOther = await _didEitherOfUsBlockTheOther(receivedUserID: personID);
    if (didEitherOfUseBlockTheOther) return null; // don't proceed if either of us blocked the other

    final myProfileData = MyProfileTabBackendFunctions.shared.myProfileData.value;

    // get the other person's profile data
    final completer = Completer<ProfileData?>(); // use this to mark when the function is complete
    final profileGetter = MyProfileTabBackendFunctions();
    profileGetter.getPersonsProfileData(
        userID: personID,
        onCompletion: (otherPersonsData) {
          final otherPersonsDataDict = {
            "bio": otherPersonsData.bio,
            "birthday": otherPersonsData.birthday,
            "name": otherPersonsData.name,
            "thumbnailURL": otherPersonsData.thumbnailURL,
            "userID": otherPersonsData.userID
          };

          final myDataDict = {
            "bio": myProfileData.bio,
            "birthday": myProfileData.birthday,
            "name": myProfileData.name,
            "thumbnailURL": myProfileData.thumbnailURL,
            "userID": myProfileData.userID
          };

          final secondsSinceEpoch = DateTime.now().millisecondsSinceEpoch * 0.001;

          // Depending on whose user ID comes first alphabetically, create the data dictionary with either myself or
          // the other person as person 1 (and the other as person 2).
          final documentData = otherPersonsData.userID < myProfileData.userID
              ? {
                  "people": [otherPersonsData.userID, myProfileData.userID],
                  "person1": otherPersonsDataDict,
                  "person2": myDataDict,
                  "time": secondsSinceEpoch
                }
              : {
                  "people": [myProfileData.userID, otherPersonsData.userID],
                  "person1": myDataDict,
                  "person2": otherPersonsDataDict,
                  "time": secondsSinceEpoch
                };

          // document ID is the alphabetical combination of our user IDs.
          final documentID = otherPersonsData.userID < myProfileData.userID
              ? otherPersonsData.userID + myProfileData.userID
              : myProfileData.userID + otherPersonsData.userID;

          // set the data in the database
          firestoreDatabase
              .collection("nearby-people")
              .doc(documentID)
              .set(documentData, SetOptions(merge: true))
              .then((_) => completer.complete(otherPersonsData));
        });
    return completer.future;
  }

  ///Send the other person a push notification indicating that they met me
  void _sendTheOtherPersonAPushNotificationIfWeHaveNotMetRecently(
      {required String recipientID, required List<String> toDeviceTokens}) {
    final recipientTokens = toDeviceTokens;

    // Don't send a push notification if we previously met (in the last 21 days).
    if (this._peopleIMetAndTimeMap.keys.contains(recipientID)) return;
    final myName = MyProfileTabBackendFunctions.shared.myProfileData.value.name;
    this._pushSender.sendPushNotification(
        recipientDeviceTokens: recipientTokens,
        title: "You Met Someone!",
        body: myName,
        notificationType: NotificationTypes.personDetails);
  }
}

/// Track whether Bluetooth scanning is in progress so the UI can update accordingly
class ScanningStatus {
  static final shared = ScanningStatus();

  /// Animate the Podsquad logo when scanning is in progress. Access this as a property of the shared instance only.
  ValueNotifier<bool> inProgress = ValueNotifier(false);
}
