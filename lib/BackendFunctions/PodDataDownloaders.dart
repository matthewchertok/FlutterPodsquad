import 'package:flutter/cupertino.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';

///Includes some useful functions related to pods, such as getting pod data. ALso contains the most up-to-date
///dictionary of pod member IDs and blocked user IDs for each pod
class PodDataDownloaders {
  static final sharedInstance = PodDataDownloaders();

  ///Stores a list that refers to all the members in a pod. Maps {podID: [pod members]}.
  ValueNotifier<Map<String, List<String>>> podMembersDict = ValueNotifier({});

  ///Stores a list that refers to all blocked members in a pod. Maps {podID: [blocked users]}.
  ValueNotifier<Map<String, List<String>>> blockedMembersDict = ValueNotifier({});

  ///Find out which members are in a pod
  void getPodMembers({required String podID, Function? onAllMembersDownloaded}) {
    PodDataDownloaders.sharedInstance.podMembersDict.value[podID] = []; // clear the list, then rebuild it in the
    // next step
    firestoreDatabase
        .collection("pods")
        .doc(podID)
        .collection("members")
        .where("blocked", isEqualTo: false)
        .get()
        .then((docSnapshot) {
      docSnapshot.docs.forEach((document) {
        final memberID = document.id;
        final podMembers = PodDataDownloaders.sharedInstance.podMembersDict.value[podID];
        if (podMembers != null) {
          if (!podMembers.contains(memberID))
            PodDataDownloaders.sharedInstance.podMembersDict.value[podID]?.add(memberID);
        }
      });
      print("Successfully got pod members: ${PodDataDownloaders.sharedInstance.podMembersDict.value[podID]}");
      if (onAllMembersDownloaded != null) onAllMembersDownloaded();
    }).catchError((error) {
      print("An error occurred while trying to get pod members: $error");
    });
  }

  ///Find out which users are blocked from a pod
  void getPodBlockedUsers({required String podID, Function? onAllMembersDownloaded}) {
    PodDataDownloaders.sharedInstance.blockedMembersDict.value[podID] = []; //clear the list, then rebuild it in the
    // next step
    firestoreDatabase
        .collection("pods")
        .doc(podID)
        .collection("members")
        .where("blocked", isEqualTo: true)
        .get()
        .then((docSnapshot) {
      docSnapshot.docs.forEach((document) {
        final blockedUserID = document.id;
        final blockedUsers = PodDataDownloaders.sharedInstance.blockedMembersDict.value[podID];
        if (blockedUsers != null) {
          if (!blockedUsers.contains(blockedUserID))
            PodDataDownloaders.sharedInstance.blockedMembersDict.value[podID]?.add(blockedUserID);
        }
      });
      print("Successfully got pod blocked users: ${PodDataDownloaders.sharedInstance.blockedMembersDict.value[podID]}");
      if (onAllMembersDownloaded != null) onAllMembersDownloaded();
    });
  }
}
