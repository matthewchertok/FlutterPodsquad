import 'package:podsquad/BackendDataclasses/NotificationTypes.dart';
import 'package:podsquad/BackendFunctions/PronounFormatter.dart';
import 'package:podsquad/BackendFunctions/PushNotificationSender.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

class FriendsDatabasePaths {
  ///Adds someone to my list of people I friended. Also unblocks them and unlikes them, in case either of those apply.
  static void friendUser({required String otherPersonsUserID, Function? onCompletion}) {
    //stores the document ID for me friending someone else
    final documentID = myFirebaseUserId + otherPersonsUserID;

    //first we must get the other person's data
    final dataGetter = MyProfileTabBackendFunctions();
    dataGetter.getPersonsProfileData(
        userID: otherPersonsUserID,
        onCompletion: (otherPersonsProfileData) {
          final myData = MyProfileTabBackendFunctions.shared.myDataToIncludeWhenLikingFriendingBlockingOrMeetingSomeone
              .toDatabaseFormat();
          final theirData = otherPersonsProfileData.toDatabaseFormat();
          final Map<String, dynamic> friendDictionary = {
            "friender": myData,
            "friendee": theirData,
            "time": DateTime.now().millisecondsSinceEpoch * 0.001
          }; // divide milliseconds by 1000 since the database stores epoch in seconds

          // now we can properly friend the other person
          firestoreDatabase.collection("friends").doc(documentID).set(friendDictionary).then((value) {
            if (onCompletion != null) onCompletion();

            //unblock a user if they are friended
            firestoreDatabase.collection("blocked-users").doc(documentID).delete();

            //unlike a user if they are friended (can't like and friend someone simultaneously)
            firestoreDatabase.collection("likes").doc(documentID).delete();

            // send them a push notification saying I friended them
            final sender = PushNotificationSender();
            sender.sendPushNotification(recipientDeviceTokens: otherPersonsProfileData.fcmTokens,
                title: "${MyProfileTabBackendFunctions.shared.myProfileData.value.name} "
                "friended you", body: "${PronounFormatter.makePronoun(preferredPronouns:
                MyProfileTabBackendFunctions.shared.myProfileData.value.preferredPronoun, pronounTense: PronounTenses
                    .HeSheThey,
                    shouldBeCapitalized:
                true)} probably found your bio interesting!", notificationType: NotificationTypes.friend);
          }).catchError((error) {
            print("An error occurred when friending someone: $error");
          });
        });
  }

  ///Removes someone from my list of people I friended.
  static void unFriendUser({required String otherPersonsUserID, Function? onCompletion}){
    //stores the document ID for me friending someone else
    final documentID = myFirebaseUserId + otherPersonsUserID;

    firestoreDatabase.collection("friends").doc(documentID).delete().then((value) {
      if(onCompletion != null) onCompletion(); // call the completion handler
    });
  }
}
