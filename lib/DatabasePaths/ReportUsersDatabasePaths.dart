import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

class ReportUserPaths {
  static final _reportsCollection = firestoreDatabase.collection("inappropriate-content-reports");

  ///References a query of all people I reported in the /reports collection
  static Query allMyPeopleIReportedRef() => _reportsCollection.where("reporter.userID", isEqualTo: myFirebaseUserId);

  ///References a query of all people who reported me in the /reports collection
  static Query allMyPeopleWhoReportedMeRef() => _reportsCollection.where("reportee.userID", isEqualTo: myFirebaseUserId);

  ///Use this function to report another person
  static void reportUser({required String otherPersonsUserID, Function? onCompletion}){
    final docID = myFirebaseUserId+otherPersonsUserID;

    //first we must get the other person's data.
    final dataGetter = MyProfileTabBackendFunctions();
    dataGetter.getPersonsProfileData(userID: otherPersonsUserID, onCompletion: () {
      final myData = MyProfileTabBackendFunctions.shared.myDataToIncludeWhenLikingFriendingBlockingOrMeetingSomeone
          .toDatabaseFormat();
      final theirData = dataGetter.profileData.toDatabaseFormat();
      final Map<String, dynamic> reportDictionary = {"reporter": myData, "reportee": theirData, "time": DateTime.now
        ().millisecondsSinceEpoch*0.001}; // divide by 1000 since database stores time in seconds since epoch

      // now we can report them
      _reportsCollection.doc(docID).set(reportDictionary).then((value) {
        if(onCompletion != null) onCompletion();
      }).catchError((error) {
        print("An error occurred while reporting someone: $error");
      });
    });
  }

  ///Use this function to unreport another person
  static void unReportUser({required String otherPersonsUserID, Function? onCompletion}){
    final docID = myFirebaseUserId+otherPersonsUserID;
    _reportsCollection.doc(docID).delete().then((value) {
      if(onCompletion != null) onCompletion();
    });
  }
}