import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'package:podsquad/UIBackendClasses/MainListDisplayBackend.dart';

///Contains methods that get data for the people I met, liked, friended, and blocked
class GetPeopleIMetLikesFriendsBlockedData {
  static final shared = GetPeopleIMetLikesFriendsBlockedData();

  ///Use this to track all the pod documents I'm listening to, so that if I leave a pod I can also stop listening to
  ///changes on the parent document.
  Map<String, StreamSubscription> streamSubscriptionRegistrations = {};

  var profileData = ProfileData(
      userID: "userID",
      name: "name",
      preferredPronoun: "preferredPronoun",
      preferredRelationshipType: "preferredRelationshipType",
      birthday: 0,
      school: "school",
      bio: "bio",
      podScore: 0,
      thumbnailURL: "thumbnailURL",
      fullPhotoURL: "fullPhotoURL");

  var podData = PodData(
      name: "name",
      dateCreated: 0,
      description: "description",
      anyoneCanJoin: false,
      podID: "podID",
      podCreatorID: "podCreatorID",
      thumbnailURL: "thumbnailURL", thumbnailPath: "",
      fullPhotoURL: "fullPhotoURL", fullPhotoPath: "",
      podScore: 0);

  ///When a child is removed, this is set and can be referenced
  var removedChildID = "";
  var changedChildID = "";

  ///Determines how many documents are in the query. The value can be accessed inside either the onChildAdded,
  ///onChildChanged, or onChildRemoved completion handlers in getListData.
  int? numberOfDocumentsInQuery;

  ///Gets data for the specified list. For dataType, pass in a static property of MainListDisplayViewModes.
  ///onChildAdded is called when a document is added to a query, onChildChanged is called when a query document
  ///changes, onChildRemoved is called when a query document is removed, and onValueChanged is called whenever either
  /// onChildAdded, onChildChanged, or onChildRemoved is called. onValueChanged is most useful for determining
  /// how many documents are returned by a query, which is useful for telling the user "you haven't met anyone yet",
  /// for example.
  void getListDataForPeopleILikedFriendedBlockedOrMet(
      {required Query query,
      required String dataType,
      required bool isGettingDataForPeopleIMetList,
      required Function onChildAdded,
      required Function onChildChanged,
      required Function onChildRemoved,
      required Function onValueChanged}) {
    query.snapshots().listen((snapshot) {
      numberOfDocumentsInQuery = snapshot.docs.length; // this will update every time the snapshot changes
      onValueChanged(); // called every time the snapshot changes (if a doc is added, changed, or removed). Also,
      // Firestore is smart enough not to call this every time a document is added when getting data for the first
      // time (i.e. it will only be called once, then will be called every time the list changes after the initial
      // snapshot).

      snapshot.docChanges.forEach((diff) {
        // depending on whether I'm looking at friends, likes, nearby-people, blocked-users, or
        // inappropriate-content-reports, I'll need a different key to access data in the map of type {key:
        // {someProfileDataFieldKey: someProfileDataFieldValue}}
        var profileDataKeys = Map<String, String>();
        if (dataType == MainListDisplayViewModes.likes)
          profileDataKeys = {"likee": "liker"};
        else if (dataType == MainListDisplayViewModes.friends)
          profileDataKeys = {"friendee": "friender"};
        else if (dataType == MainListDisplayViewModes.blocked)
          profileDataKeys = {"blockee": "blocker"};
        else if (dataType == MainListDisplayViewModes.reported)
          profileDataKeys = {"reportee": "reporter"};
        else if (dataType == MainListDisplayViewModes.peopleIMet) profileDataKeys = {"person1": "person2"};

        // now use the appropriate profileDataKey to get the other person's data. First, I need to figure out which
        // person is the other person. Notice that in the maps above, the recipient (likee, friendee, blockee...) is
        // the key, and the sender (liker, friender, blocker...) is the value

        final recipientKey = profileDataKeys.keys.first;
        final senderKey = profileDataKeys.values.first;
        final recipientData = diff.doc.get(recipientKey) as Map<String, dynamic>;
        final senderData = diff.doc.get(senderKey) as Map<String, dynamic>;
        final otherPersonsData = senderData["userID"] as String == myFirebaseUserId ? recipientData : senderData;
        final timestampRaw = diff.doc.get("time") as num;
        final timestamp = timestampRaw.toDouble();

        if (diff.type == DocumentChangeType.added || diff.type == DocumentChangeType.modified) {
          this._extractDataForUser(
              value: otherPersonsData,
              timestamp: timestamp, isGettingDataForPeopleIMet: isGettingDataForPeopleIMetList,
              onProfileDataReady: () {
                if(diff.type == DocumentChangeType.modified) changedChildID = otherPersonsData["userID"];
                diff.type == DocumentChangeType.added ? onChildAdded() : onChildChanged();
              });
        } else if (diff.type == DocumentChangeType.removed) {
          final otherPersonsID = otherPersonsData["userID"];
          this.removedChildID = otherPersonsID;
          onChildRemoved();
        }
      });
    });
  }

  ///Pass in firestoreDatabase.collectionGroup("members").where("blocked", isEqualTo: false) as the query.
  void getListDataForPodsImIn(
      {required Query query,
      required Function onChildAdded,
      required Function onChildChanged,
      required Function onChildRemoved,
      required Function onValueChanged}) {
    // Query listens to the "members" subcollection of each pod
    query.snapshots().listen((snapshot) {
      numberOfDocumentsInQuery = snapshot.docs.length; // this will update every time the snapshot changes
      onValueChanged(); // called every time the snapshot changes (if a doc is added, changed, or removed). Also,

      snapshot.docChanges.forEach((diff) {
        final podDocument = diff.doc.reference.parent.parent;
        if (podDocument != null) {
          final podID = podDocument.id;
          // ignore: cancel_subscriptions
          final podDocListener = podDocument.snapshots().listen((podDocSnapshot) {
            final podData = podDocSnapshot.get("profileData");

            if (diff.type == DocumentChangeType.added || diff.type == DocumentChangeType.modified) {
              this._extractDataForPod(
                  value: podData,
                  onPodDataReady: () {
                    if(diff.type == DocumentChangeType.modified) changedChildID = podID;
                    diff.type == DocumentChangeType.added ? onChildAdded() : onChildChanged();
                  });
            } else if (diff.type == DocumentChangeType.removed) {
              this.removedChildID = podID;
              streamSubscriptionRegistrations[podID]?.cancel(); // stop listening to changes to the pod if I leave
              onChildRemoved();
            }
          });
          streamSubscriptionRegistrations[podID] = podDocListener;
        }
      });
    });
  }

  /// If isGettingDataForPeopleIMet is set to true, then check if I met the person more than 21 days ago. If so,
  /// delete them from the database both to save space and ensure relevance for users
  void _extractDataForUser(
      {required Map<String, dynamic> value, required double timestamp, required Function onProfileDataReady, bool
      isGettingDataForPeopleIMet = false}) {
    final userID = value["userID"] as String;
    final name = value["name"] as String;
    final birthday = value["birthday"] as num;
    final bio = value["bio"] as String?;
    final thumbnailURL = value["thumbnailURL"] as String;

    // Preferred pronouns, preferred relationship type, school, podScore, and fullPhotoURL will be unknown here since
    // that data is not stored in user interaction documents. That doesn't matter because that data is only needed if
    // I go to view someone's full profile, in which case that data will be downloaded separately anyway.
    this.profileData = ProfileData(
        userID: userID,
        name: name,
        preferredPronoun: UsefulValues.nonbinaryPronouns,
        preferredRelationshipType: UsefulValues.lookingForFriends,
        birthday: birthday.toDouble(),
        school: "school",
        bio: bio ?? "",
        podScore: 0,
        thumbnailURL: thumbnailURL,
        fullPhotoURL: "fullPhotoURL", timeIMetThePerson: timestamp);
    onProfileDataReady();

    // delete the person if I met them more than 21 days ago. This is to save space in the database, reduce reads,
    // and improve relevance for users.
    if (isGettingDataForPeopleIMet) {
      final timeIMetThePerson = DateTime.fromMillisecondsSinceEpoch((timestamp*1000).toInt());
      final now = DateTime.now();
      final timeSinceIMetThePerson = now.difference(timeIMetThePerson).inDays;
      if (timeSinceIMetThePerson > 21) {
        // document ID is an alphabetical combination of user IDs
        final docId = myFirebaseUserId < userID ? myFirebaseUserId + userID : userID + myFirebaseUserId;
        firestoreDatabase.collection("nearby-people").doc(docId).delete().then((value) {

          // Delete the person from the displayed list on the device (might be redundant since Firestore listeners
          // could handle it also, but this is just to be safe)
          PeopleIMetBackendFunctions.shared.listOfPeople.removeWhere((person) => person.userID == userID);
          PeopleIMetBackendFunctions.shared.sortListOfPeople();
          PeopleIMetBackendFunctions.shared.sortedListOfPeople.notifyListeners();
        });
      }
    }
  }

  void _extractDataForPod({required Map<String, dynamic> value, required Function onPodDataReady}) {
    final podID = value["podID"] as String;
    final podName = value["name"] as String;
    final podCreatorID = value["podCreatorID"] as String;
    final anyoneCanJoin = value["anyoneCanJoin"] as bool;
    final dateCreatedRaw = value["dateCreated"] as num;
    final dateCreated = dateCreatedRaw.toDouble();
    final description = value["description"] as String;
    final fullPhotoURL = value["fullPhotoURL"] as String;
    final fullPhotoPath = value["fullPhotoPath"] as String;
    final thumbnailURL = value["thumbnailURL"] as String;
    final thumbnailPath = value["thumbnailPath"] as String;
    final podScoreRaw = value["podScore"] as num;
    final podScore = podScoreRaw.toInt();

    this.podData = PodData(
        name: podName,
        dateCreated: dateCreated,
        description: description,
        anyoneCanJoin: anyoneCanJoin,
        podID: podID,
        podCreatorID: podCreatorID,
        thumbnailURL: thumbnailURL, thumbnailPath: thumbnailPath,
        fullPhotoURL: fullPhotoURL, fullPhotoPath: fullPhotoPath,
        podScore: podScore);
    onPodDataReady();
  }
}
