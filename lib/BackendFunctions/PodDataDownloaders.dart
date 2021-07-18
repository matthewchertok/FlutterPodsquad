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
  Future<List<String>> getPodMembers({required String podID}) async {
    PodDataDownloaders.sharedInstance.podMembersDict.value[podID] = []; // clear the list, then rebuild it in the
    // next step
    final task =
        firestoreDatabase.collection("pods").doc(podID).collection("members").where("blocked", isEqualTo: false).get();

    final docSnapshot = await task;
    docSnapshot.docs.forEach((document) {
      final memberID = document.id;
      final podMembers = PodDataDownloaders.sharedInstance.podMembersDict.value[podID] ?? [];
      if (!podMembers.contains(memberID)) {
        if (PodDataDownloaders.sharedInstance.podMembersDict.value[podID] == null) PodDataDownloaders.sharedInstance
            .podMembersDict.value[podID] = []; // initialize a list if necessary
        PodDataDownloaders.sharedInstance.podMembersDict.value[podID]?.add(memberID);
        PodDataDownloaders.sharedInstance.podMembersDict.notifyListeners();
      }
    });
    print("Successfully got pod members: ${PodDataDownloaders.sharedInstance.podMembersDict.value[podID]}");

    task.catchError((error) {
      print("An error occurred while trying to get pod members: $error");
    });

    return PodDataDownloaders.sharedInstance.podMembersDict.value[podID] ?? [];
  }

  ///Find out which users are blocked from a pod
  Future<List<String>> getPodBlockedUsers({required String podID}) async {
    PodDataDownloaders.sharedInstance.blockedMembersDict.value[podID] = []; //clear the list, then rebuild it in the
    // next step
    final task =
        firestoreDatabase.collection("pods").doc(podID).collection("members").where("blocked", isEqualTo: true).get();

    final docSnapshot = await task;
    docSnapshot.docs.forEach((document) {
      final blockedUserID = document.id;
      final blockedUsers = PodDataDownloaders.sharedInstance.blockedMembersDict.value[podID] ?? [];
      //initialize list
      if (!blockedUsers.contains(blockedUserID)) {
        if (PodDataDownloaders.sharedInstance.blockedMembersDict.value[podID] == null) PodDataDownloaders
            .sharedInstance.blockedMembersDict.value[podID] = []; // initialize a list if necessary
        PodDataDownloaders.sharedInstance.blockedMembersDict.value[podID]?.add(blockedUserID);
        PodDataDownloaders.sharedInstance.blockedMembersDict.notifyListeners();
      }
    });
    print("Successfully got pod blocked users: ${PodDataDownloaders.sharedInstance.blockedMembersDict.value[podID]}");
    return PodDataDownloaders.sharedInstance.blockedMembersDict.value[podID] ?? [];
  }
}
