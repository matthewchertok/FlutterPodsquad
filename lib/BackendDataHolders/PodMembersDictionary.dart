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
  set dictionary(ValueNotifier<Map<String, List<ProfileData>>> newValue) {
    dictionary = newValue; // update the value of the dictionary

    //Also update the strings-only observable dictionary so that it contains the user IDs for each member of the pod.
    newValue.value.forEach((podID, listOfMembers) {
      PodDataDownloaders.sharedInstance.podMembersDict.value[podID] = listOfMembers.memberIDs();
    });
  }

  ValueNotifier<Map<String, List<ProfileData>>> get dictionary => dictionary;


  ///Used when the full profile data for users blocked from a pod is needed. Maps like this: {podID:
  ///{blockedUser1ProfileData,
  ///blockedUser2ProfileData}}. Every time this value changes, also update a {String: String} map of {podID:
  ///{podMember1ID, podMember2ID}}, which is used in cases where only the user ID is needed.
  set blockedDictionary(ValueNotifier<Map<String, List<ProfileData>>> newValue) {
    blockedDictionary = newValue; // update the value of the dictionary

    //Also update the strings-only observable dictionary so that it contains the user IDs for each member of the pod.
    newValue.value.forEach((podID, listOfMembers) {
      PodDataDownloaders.sharedInstance.blockedMembersDict.value[podID] = listOfMembers.memberIDs();
    });
  }
  ValueNotifier<Map<String, List<ProfileData>>> get blockedDictionary => blockedDictionary;

}