import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/DatabasePaths/MessagingDatabasePaths.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

class BlockedUsersDatabasePaths {
  ///Blocks another user, which involves adding them to the blocked-users collection and unfriending, unliking, and
  ///deleting any DM conversations with them.
  static void blockUser({required String otherPersonsUserID, Function? onCompletion}) {
    String myId = myFirebaseUserId;

    ///Blocked users are identified as blockerID+blockeeID
    String documentID = myId + otherPersonsUserID;

    //first, we must get the other person's data
    final dataGetter = MyProfileTabBackendFunctions();
    dataGetter.getPersonsProfileData(
        userID: otherPersonsUserID,
        onCompletion: (otherPersonsProfileData) {
          final myData = MyProfileTabBackendFunctions.shared.myDataToIncludeWhenLikingFriendingBlockingOrMeetingSomeone
              .toDatabaseFormat();
          final theirData = otherPersonsProfileData.toDatabaseFormat();
          final Map<String, dynamic> blockDictionary = {
            "blocker": myData,
            "blockee": theirData,
            "time": DateTime.now().millisecondsSinceEpoch * 0.001
          }; // must multiply milliseconds by 0.001 since values in the database are
          // stored in seconds since epoch.

          //now we can properly block them
          firestoreDatabase.collection("blocked-users").doc(documentID).set(blockDictionary).then((value) => () {
                if (onCompletion != null) onCompletion(); // execute the completion handler if there is one

                // remove friendship if I block someone
                final theirDocID = otherPersonsUserID + myFirebaseUserId;
                firestoreDatabase.collection("friends").doc(documentID).delete();
                firestoreDatabase.collection("friends").doc(theirDocID).delete();

                // remove likes if I block someone
                firestoreDatabase.collection("likes").doc(documentID).delete();
                firestoreDatabase.collection("likes").doc(theirDocID).delete();

                // un-meet someone if I block them
                // nearby-people documents are identified as an alphabetical combination of user IDs, so we need to find the
                // ID of the document corresponding to me and the other user.
                final alphabeticalID = otherPersonsUserID < myFirebaseUserId
                    ? otherPersonsUserID + myFirebaseUserId
                    : myFirebaseUserId + otherPersonsUserID;
                firestoreDatabase.collection("nearby-people").doc(alphabeticalID).delete();

                // Delete the messaging conversation using a cloud function if I block someone
                MessagingDatabasePaths(userID: myFirebaseUserId, interactingWithUserWithID: otherPersonsUserID)
                    .deleteConversation(conversationID: alphabeticalID);
              });
        });
  }

  ///Unblocks a user by removing them from the blocked-users collection
  static void unBlockUser({required String otherPersonsUserID, Function? onCompletion}) {
    final documentID = myFirebaseUserId + otherPersonsUserID;
    firestoreDatabase.collection("blocked-users").doc(documentID).delete().then((value) => {
          if (onCompletion != null) {onCompletion()}
        });
  }
}
