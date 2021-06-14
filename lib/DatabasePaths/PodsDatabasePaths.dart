import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:podsquad/BackendDataHolders/PodMembersDictionary.dart';
import 'package:podsquad/CommonlyUsedClasses/PodMemberInfoDict.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

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

  ///A list of the IDs for all users who are blocked from the pod. Must call inside the completion handler of a
  ///function that gets all blocked members.
  var _podBlockedMembersIDsList = <String>[];

  //TODO: final sender = PushNotificationSender()

  ///References the number of times the pod has been reported. Call inside the completion handler of getReportCount.
  var reportCount = 0;

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

  ///Removes a user with id equal to userID from /pods/podID/members.
  void _removeMemberFromPod({Function? onSuccess}) {
    podDocument.collection("members").doc(userID).delete().then((value) {
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

  //TODO: implement remaining methods starting with joinPod()
  void joinPod({required PodMemberInfoDict personData, Function? onSuccess}) {
    _addMemberToPod(
        personData: personData,
        onSuccess: () {
          //TODO: message the pod members automatically telling them that I added someone or joined the pod

          //once the member is added to the pod, get their data and add the person to the observable pod members dictionary
          final value = personData.toDatabaseFormat();
          var profileData =
              ProfileDatabasePaths.extractProfileDataFromSnapshot(userID: this.userID, snapshotValue: value);
          final podMembers = PodMembersDictionary.sharedInstance.dictionary.value[this.podID];
          if (podMembers != null) {
            if (!podMembers.contains(profileData))
              PodMembersDictionary.sharedInstance.dictionary.value[this.podID]?.add(profileData);
          }

          if(this.userID != myFirebaseUserId){
            final myName = MyProfileTabBackendFunctions.shared.myProfileData.value.name;
            final myPronouns = MyProfileTabBackendFunctions.shared.myProfileData.value.preferredPronoun;
            //TODO: get the pod name and description and send a push notification to inform the other user that I
            // added them to a pod
          }
        });
  }
}
