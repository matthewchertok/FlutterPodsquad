import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:podsquad/BackendDataHolders/PodMembersDictionary.dart';
import 'package:podsquad/BackendDataclasses/NotificationTypes.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/BackendFunctions/PronounFormatter.dart';
import 'package:podsquad/BackendFunctions/PushNotificationSender.dart';
import 'package:podsquad/BackendDataclasses/PodMemberInfoDict.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'ProfileDatabasePaths.dart';

class PodsDatabasePaths {
  late final String userID;
  late final String podID;
  late final String imageName;

  PodsDatabasePaths({String? userID, required String podID, String imageName = "nil"}) {
    this.userID = userID ?? myFirebaseUserId; // will take whatever is passed in as userID, but will default to
    // myFirebaseUserID if userID is null
    this.podID = podID;
    this.imageName = imageName;
  }

  ///Stores the pod name
  var podName = "Some Pod";

  ///Stores the pod description
  var podDescription = "Some Description";

  ///Points to the document at /pods/podID
  DocumentReference get podDocument => firestoreDatabase.collection("pods").doc(podID);

  ///A list of the IDs for all pod members, used for sending out push notifications when a message is sent.
  var _podMembersIDsList = <String>[];

  ///A list of the IDs for members who have hidden the chat. Used for sending out push notifications when a message is
  /// sent
  var podInactiveMembersIDsList = <String>[];

  ///References the number of times the pod has been reported. Call inside the completion handler of getReportCount.
  var reportCount = 0;

  ///Used to send push notifications
  final _sender = PushNotificationSender();

  //Begin storage references
  ///References /pods/podID/imageName in Firebase Storage.
  Reference get podImageRef => firebaseStorage.ref().child("pods").child(podID).child(imageName);

  ///Points to /pods/podID/pod_messaging/myFirebaseUserID
  Reference get podMessagingImagesRef =>
      firebaseStorage.ref().child("pods").child(podID).child("messaging-images").child(myFirebaseUserId);

  ///Adds a user with id equal to userID to /pods/podID/members
  void _addMemberToPod({required PodMemberInfoDict personData, Function? onSuccess}) {
    podDocument.collection("members").doc(personData.userID).set(personData.toDatabaseFormat()).then((value) {
      if (onSuccess != null) onSuccess();
    });
  }

  ///Blocks a user with ID equal to userID by setting "blocked" equal to true.
  void _addUserIDToBlockedMembers({Function? onSuccess}) {
    podDocument.collection("members").doc(userID).update({"blocked": true}).then((value) {
      if (onSuccess != null) onSuccess();
    });
  }

  ///Unblocks a user with ID equal to userID by setting "blocked" equal to false
  void _removeUserIDFromBlockedMembers({Function? onSuccess}) {
    podDocument.collection("members").doc(userID).update({"blocked": false}).then((value) {
      if (onSuccess != null) onSuccess();
    });
  }

  ///Join a pod. Make sure that when initializing a POdsDatabasePaths object to call this method on, you use the ID
  ///of the person who was just added to the pod as the userID parameter in the constructor.
  void joinPod({required PodMemberInfoDict personData, Function? onSuccess}) {
    _addMemberToPod(
        personData: personData,
        onSuccess: () {
          if (this.userID != myFirebaseUserId) {}

          //once the member is added to the pod, get their data and add the person to the observable pod members dictionary
          final value = personData.toDatabaseFormat();
          var profileData =
              ProfileDatabasePaths.extractProfileDataFromSnapshot(userID: this.userID, snapshotValue: value);
          final podMembers = PodMembersDictionary.sharedInstance.dictionary.value[this.podID];
          if (podMembers != null) {
            if (!podMembers.contains(profileData))
              PodMembersDictionary.sharedInstance.dictionary.value[this.podID]?.add(profileData);
          }

          //Send a push notification to inform someone they got added to a pod (don't send one to myself though)
          if (this.userID != myFirebaseUserId) {
            final myName = MyProfileTabBackendFunctions.shared.myProfileData.value.name;
            this.getPodNameAndDescription(completion: () {
              this._sender.sendPushNotification(
                  recipientID: this.userID,
                  title: "$myName Added You To $podName",
                  podID: this.podID,
                  podName: this.podName,
                  body: this.podDescription,
                  notificationType: NotificationTypes.podDetails);
            });
          }
        });
  }

  ///Make a person (or myself) leave a pod. Pass in the person's user ID into the constructor when creating a
  ///PodsDatabasePaths class upon which this method is called.
  void leavePod(
      {required String podName, required String personName, bool shouldTextPodMembers = true, Function? onSuccess}) {
    //first, we need to check if we're the last person left in the pod. If we are, delete the pod.
    podDocument.collection("members").get().then((membersSnapshot) {
      final memberCount = membersSnapshot.docs.length;
      // if I"m the last person in the pod, delete it
      if (memberCount == 1)
        deletePod(podName: podName, onCompletion: onSuccess);
      else {
        this.removeMemberFromPod(onCompletion: () {
          // if requested, send a message to the pod saying that I left
          if (shouldTextPodMembers)
            this.sendJoinLeavePodMessage(action: _AddedRemovedBlockedUnblocked.removed, personName: personName);

          // Remove the person from the observable pod members dictionary
          PodMembersDictionary.sharedInstance.dictionary.value[this.podID]
              ?.removePersonFromList(personUserID: this.userID);

          // Send the other person a push notification saying they were removed from a pod (don't send myself a push
          // notification if I leave a pod though)
          if (this.userID != myFirebaseUserId) {
            final myName = MyProfileTabBackendFunctions.shared.myProfileData.value.name;
            this.getPodNameAndDescription(completion: () {
              this._sender.sendPushNotification(
                  recipientID: this.userID,
                  title: "Sorry To Tell You...",
                  body: "$myName removed you from $podName",
                  podID: this.podID,
                  podName: this.podName,
                  notificationType: NotificationTypes.podDetails);
            });
          }

          // call the completion handler
          if (onSuccess != null) onSuccess();
        });
      }
    });
  }

  ///Removes a user's document from /pods/podID/members. Be sure to specify the user when initializing the
  ///PodsDatabasePaths object on which this method is called.
  void removeMemberFromPod({Function? onCompletion}) {
    podDocument.collection("members").doc(this.userID).delete().then((value) {
      if (onCompletion != null) onCompletion();
    });
  }

  void deletePod({required String podName, Function? onCompletion}) {
    this._getPodMemberIDs(onCompletion: () {
      final myName = MyProfileTabBackendFunctions.shared.myProfileData.value.name;
      final myPronouns = MyProfileTabBackendFunctions.shared.myProfileData.value.preferredPronoun;
      firebaseFunctions.httpsCallable("deletePod").call({"podID": this.podID}).then((value) {
        // notify all pod members (except myself) that the pod was deleted
        for (final memberID in this._podMembersIDsList) {
          if (memberID != myFirebaseUserId) {
            this._sender.sendPushNotification(
                recipientID: memberID,
                title: "$podName Was Deleted",
                body: "$myName "
                    "decided it wasn't fun anymore, so ${PronounFormatter.makePronoun(preferredPronouns: myPronouns, pronounTense: PronounTenses.HeSheThey, shouldBeCapitalized: false)} decided to delete the pod.",
                podID: this.podID,
                podName: this.podName,
                notificationType: NotificationTypes.personDetails); // direct the recipient to open the profile of
            // the person who deleted the pod
          }

          // clear the local dictionary values for this pod to save a small amount of memory
          PodMembersDictionary.sharedInstance.dictionary.value[this.podID]?.clear();
          PodMembersDictionary.sharedInstance.blockedDictionary.value[this.podID]?.clear();
          if (onCompletion != null) onCompletion();
        }
      }).catchError((error) {
        print("An error occurred whiled deleting a pod: $error");
      });
    });
  }

  /// Send a message in the chat notifying the members that I added, removed, or blocked someone.
  void sendJoinLeavePodMessage({required _AddedRemovedBlockedUnblocked action, required String personName}) {
    var messageText = "I added, removed, or blocked someone";
    final myName = MyProfileTabBackendFunctions.shared.myProfileData.value.name;
    switch (action) {
      case _AddedRemovedBlockedUnblocked.added:
        messageText = this.userID == myFirebaseUserId ? "I joined the pod. Hi guys!" : "I added $personName";
        break;
      case _AddedRemovedBlockedUnblocked.removed:
        messageText = this.userID == myFirebaseUserId ? "I left the pod. Bye guys!" : "I removed $personName";
        break;
      case _AddedRemovedBlockedUnblocked.blocked:
        messageText = "I blocked $personName";
        break;
      case _AddedRemovedBlockedUnblocked.unblocked:
        messageText = "I unblocked $personName";
        break;
    }

    final myThumbnailURL = MyProfileTabBackendFunctions.shared.myProfileData.value.thumbnailURL;

    final messageRef = podDocument.collection("messages").doc();
    final messageId = messageRef.id;
    final systemTime = DateTime.now().millisecondsSinceEpoch * 0.001; // convert to seconds since that's what I
    // originally used because of how Swift handles time
    final Map<String, dynamic> messageDictionary = {
      "id": messageId,
      "senderId": myFirebaseUserId,
      "senderName": myName,
      "systemTime": systemTime,
      "text": messageText,
      "senderThumbnailURL": myThumbnailURL,
      "readBy": [myFirebaseUserId],
      "readTime": {myFirebaseUserId: systemTime},
      "readName": {myFirebaseUserId: myName}
    };
    messageRef.set(messageDictionary); // upload the message to the conversation
  }

  ///Deletes a message and the associated image from a pod chat.
  void deletePodMessage({required String messageID, String? imageURL, String? audioURL}) {
    this._getPodInactiveMemberIDs(onCompletion: () {
      podDocument.collection("messages").where("id", isEqualTo: messageID).get().then((docSnapshot) {
        final docToDelete = docSnapshot.docs.first; // the query should only contain one result since message IDs are
        // unique

        // if the message has an image and/or audio, delete the image and/or audio
        if (imageURL != null) firebaseStorage.refFromURL(imageURL).delete();
        if (audioURL != null) firebaseStorage.refFromURL(audioURL).delete();

        docToDelete.reference.delete().catchError((error) {
          print("An error occurred while attempting to delete a pod message: $error");
        });
      });
    });
  }

  ///Call a cloud function to delete an entire pod messaging conversation and associated images and audio. The
  ///function will get all pod member IDs itself.
  void deletePodConversation({required String podName, Function? onCompletion}) {
    final myName = MyProfileTabBackendFunctions.shared.myProfileData.value.name;
    this._getPodInactiveMemberIDs(onCompletion: () {
      this._getPodMemberIDs(onCompletion: () {
        firebaseFunctions.httpsCallable("deletePodConversationMessages").call({"podID": this.podID}).then((value) {
          // send a push notification to everyone active in the pod letting them know that the chat was deleted
          this._podMembersIDsList.forEach((personID) {
            if (personID != myFirebaseUserId && !podInactiveMembersIDsList.contains(personID))
              this._sender.sendPushNotification(
                  recipientID: personID,
                  title: "Pod Chat Deleted",
                  body: "$myName deleted the "
                      "$podName chat",
                  notificationType: NotificationTypes.podDetails);
          });
        }).catchError((error) {
          print("Failed to delete a pod chat: $error");
        });
      });
    });
  }

  ///Adds my name to a pod's list of inactive members so that I don't receive notifications from it and the
  ///conversation remains hidden.
  void hidePodConversation({Function? onCompletion}) {
    podDocument.collection("members").doc(myFirebaseUserId).update({"active": false}).then((value) {
      if (onCompletion != null) onCompletion();
    }).catchError((error) {
      print("An error occurred while hiding a pod conversation: $error");
    });
  }

  ///Removes my name from a pod's list of inactive members so that I can receive notifications again.
  void unHidePodConversation({Function? onCompletion}) {
    podDocument.collection("members").doc(myFirebaseUserId).update({"active": true}).then((value) {
      if (onCompletion != null) onCompletion();
    }).catchError((error) {
      print("An error occurred while un-hiding a pod conversation: $error");
    });
  }

  ///Don't send a push notification if I blocked someone. People should not know who blocked them.
  void blockFromPod({required String podName, required String personName, Function? onSuccess}) {
    this._addUserIDToBlockedMembers(onSuccess: () {
      this.sendJoinLeavePodMessage(action: _AddedRemovedBlockedUnblocked.blocked, personName: personName); // notify
      // the pod members that I
      // blocked someone

      // remove the person from the observable pod members dictionary
      PodMembersDictionary.sharedInstance.dictionary.value[this.podID]?.removePersonFromList(personUserID: this.userID);
      if (onSuccess != null) onSuccess(); // call the completion handler
    });
  }

  void unBlockFromPod({required String personName, Function? onSuccess}) {
    this._removeUserIDFromBlockedMembers(onSuccess: () {
      this.sendJoinLeavePodMessage(action: _AddedRemovedBlockedUnblocked.unblocked, personName: personName);
      PodMembersDictionary.sharedInstance.blockedDictionary.value[this.podID]
          ?.removePersonFromList(personUserID: this.userID);
      if (onSuccess != null) onSuccess();
    });
  }

  ///Gets the pod name and description and assigns the podName and podDescription properties of the class to the pod
  ///name and description. The new values are available inside the completion handler.
  void getPodNameAndDescription({Function? completion}) {
    podDocument.get().then((docSnapshot) {
      final podProfileData = docSnapshot.get("profileData") as Map<String, dynamic>;
      final name = podProfileData["name"] as String;
      final description = podProfileData["description"] as String;
      this.podName = name;
      this.podDescription = description;
      if (completion != null) completion();
    });
  }

  ///Get a list of the IDs of all inactive pod members
  void _getPodInactiveMemberIDs({Function? onCompletion}) {
    this.podInactiveMembersIDsList = [];
    podDocument
        .collection("members")
        .where("active", isEqualTo: false)
        .where("blocked", isEqualTo: false)
        .get()
        .then((docSnapshot) {
      for (final document in docSnapshot.docs) {
        final personID = document.get("userID") as String;
        if (!this.podInactiveMembersIDsList.contains(personID)) this.podInactiveMembersIDsList.add(personID);
      }
    });
  }

  ///Get a list of the IDs of all the pod members
  void _getPodMemberIDs({Function? onCompletion}) {
    this._podMembersIDsList = [];
    podDocument
        .collection("members")
        .where("active", isEqualTo: true)
        .where("blocked", isEqualTo: false)
        .get()
        .then((docSnapshot) {
      final documents = docSnapshot.docs;
      for (final document in documents) {
        final personID = document.get("userID") as String;
        if (!this._podMembersIDsList.contains(personID)) this._podMembersIDsList.add(personID);
      }
    });
  }

  ///Adds my name to the list of users who reported the pod for inappropriate content
  void reportPod({Function? onCompletion}) {
    podDocument.set({
      "reportedBy": FieldValue.arrayUnion([myFirebaseUserId])
    }, SetOptions(merge: true)).then((value) {
      if (onCompletion != null) onCompletion();
    });
  }

  ///Removes my name from the list of users who reported the pod for inappropriate content
  void unReportPod({Function? onCompletion}) {
    podDocument.set({
      "reportedBy": FieldValue.arrayRemove([myFirebaseUserId])
    }, SetOptions(merge: true)).then((value) {
      if (onCompletion != null) onCompletion();
    });
  }

  ///Gets all required profile data for a pod (single event snapshot).
  void getPodData({required Function(PodData) onCompletion}) {
    podDocument.get().then((docSnapshot) {
      final profileInfo = docSnapshot.get("profileData") as Map<String, dynamic>;
      final name = profileInfo["name"] as String;
      final dateCreatedRaw = profileInfo["dateCreated"] as num;
      final dateCreated = dateCreatedRaw.toDouble();
      final description = profileInfo["description"] as String;
      final anyoneCanJoin = profileInfo["anyoneCanJoin"] as bool;
      final podID = profileInfo["podID"] as String;
      final podCreatorID = profileInfo["podCreatorID"] as String;
      final thumbnailURL = profileInfo["thumbnailURL"] as String;
      final fullPhotoURL = profileInfo["fullPhotoURL"] as String;
      final podScoreRaw = profileInfo["podScore"] as num? ?? 0; // pod score for pods is stored as an integer, not a
      // double
      final podScore = podScoreRaw.toInt();

      ///Check how many times the pod was reported
      final docData = docSnapshot.data() as Map;
      final reportInfo = docData["reportedBy"] as List<String>? ?? [];
      this.reportCount = reportInfo.length;

      ///Update the podData object
      final podData = PodData(
          name: name,
          dateCreated: dateCreated,
          description: description,
          anyoneCanJoin: anyoneCanJoin,
          podID: podID,
          podCreatorID: podCreatorID,
          thumbnailURL: thumbnailURL,
          fullPhotoURL: fullPhotoURL,
          podScore: podScore);

      onCompletion(podData);
    });
  }

  /// Gets all the required profile data for a pod (continuous listener)
  StreamSubscription podDataStream({required Function(PodData) onCompletion}){
    return podDocument.snapshots().listen((docSnapshot) {
      final profileInfo = docSnapshot.get("profileData") as Map<String, dynamic>;
      final name = profileInfo["name"] as String;
      final dateCreatedRaw = profileInfo["dateCreated"] as num;
      final dateCreated = dateCreatedRaw.toDouble();
      final description = profileInfo["description"] as String;
      final anyoneCanJoin = profileInfo["anyoneCanJoin"] as bool;
      final podID = profileInfo["podID"] as String;
      final podCreatorID = profileInfo["podCreatorID"] as String;
      final thumbnailURL = profileInfo["thumbnailURL"] as String;
      final fullPhotoURL = profileInfo["fullPhotoURL"] as String;
      final podScoreRaw = profileInfo["podScore"] as num? ?? 0; // pod score for pods is stored as an integer, not a
      // double
      final podScore = podScoreRaw.toInt();

      ///Check how many times the pod was reported
      final docData = docSnapshot.data() as Map;
      final reportInfo = docData["reportedBy"] as List<String>? ?? [];
      this.reportCount = reportInfo.length;

      ///Update the podData object
      final podData = PodData(
          name: name,
          dateCreated: dateCreated,
          description: description,
          anyoneCanJoin: anyoneCanJoin,
          podID: podID,
          podCreatorID: podCreatorID,
          thumbnailURL: thumbnailURL,
          fullPhotoURL: fullPhotoURL,
          podScore: podScore);

      onCompletion(podData);
    });
  }
}

enum _AddedRemovedBlockedUnblocked { added, removed, blocked, unblocked }
