import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

class LikesDatabasePaths {
  static void sendLike({required String otherPersonsUserID, Function? onCompletion}){
    final documentID = myFirebaseUserId+otherPersonsUserID; // document ID representing that I liked the other person

    // first we must get the other person's data
    final dataGetter = MyProfileTabBackendFunctions();
    dataGetter.getPersonsProfileData(userID: otherPersonsUserID, onCompletion: (otherPersonsProfileData) {
      final myData = MyProfileTabBackendFunctions.shared.myDataToIncludeWhenLikingFriendingBlockingOrMeetingSomeone
          .toDatabaseFormat();
      final theirData = otherPersonsProfileData.toDatabaseFormat();
      final Map<String, dynamic> likeDictionary = {"liker": myData, "likee": theirData, "time": DateTime.now()
          .millisecondsSinceEpoch*0.001}; // Divide by 1000 since the database stores time in seconds since epoch

      // Now we can friend them
      firestoreDatabase.collection("likes").doc(documentID).set(likeDictionary).then((value) {
        // unblocks a user if they are liked
        firestoreDatabase.collection("blocked-users").doc(documentID).delete();

        //unfriend a user if they are liked (can't both like and friend someone simultaneously)
        firestoreDatabase.collection("friends").doc(documentID).delete();

        if(onCompletion != null) onCompletion(); // call the completion handler if there is one
      });
    });
  }

  static void removeLike({required String otherPersonsUserID, Function? onCompletion}){
    final documentID = myFirebaseUserId+otherPersonsUserID;
    firestoreDatabase.collection("likes").doc(documentID).delete().then((value) {
      if(onCompletion != null) onCompletion();
    });
  }
}