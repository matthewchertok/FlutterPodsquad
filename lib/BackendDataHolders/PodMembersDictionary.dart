import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/BackendFunctions/PodDataDownloaders.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

///This dictionary will store a list of members of each pod ID
class PodMembersDictionary {
  static final sharedInstance = PodMembersDictionary();

  ///Used when the full profile data for pod members is needed. Maps like this: {podID: {podMember1ProfileData,
  ///podMember2ProfileData}}. Every time this value changes, also update a {String: String} map of {podID:
  ///{podMember1ID, podMember2ID}}, which is used in cases where only the user ID is needed.
  ValueNotifier<Map<String, List<ProfileData>>> dictionary = ValueNotifier({});

  /// Call this immediately after setting PodMembersDictionary.sharedInstance.dictionary or PodMembersDictionary
  /// .sharedInstance.blockedDictionary. The function updates the strings-only observable dictionaries so that it
  /// contains the user IDs for each member and blocked user in the pod.
  void updateTheOtherDictionaries(){
    //Also update the strings-only observable dictionary so that it contains the user IDs for each member of the pod.
    dictionary.value.forEach((podID, listOfMembers) {
      PodDataDownloaders.sharedInstance.podMembersDict.value[podID] = listOfMembers.memberIDs();
    });

    blockedDictionary.value.forEach((podID, listOfMembers) {
      PodDataDownloaders.sharedInstance.blockedMembersDict.value[podID] = listOfMembers.memberIDs();
    });
  }


  ///Used when the full profile data for users blocked from a pod is needed. Maps like this: {podID:
  ///{blockedUser1ProfileData,
  ///blockedUser2ProfileData}}. Every time this value changes, also update a {String: String} map of {podID:
  ///{podMember1ID, podMember2ID}}, which is used in cases where only the user ID is needed.
  ValueNotifier<Map<String, List<ProfileData>>> blockedDictionary = ValueNotifier({});

}