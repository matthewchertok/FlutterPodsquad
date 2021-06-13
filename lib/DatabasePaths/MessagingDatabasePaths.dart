import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';

class MessagingDatabasePaths {
  late final String senderId;
  late final String recipientId;

  ///Points to /dm-presence/userID. When using this, make sure to pass in a value for userID when initializing a
  ///MessagingDatabasePaths object.
  late final DocumentReference isSenderTypingMessageRef;

  MessagingDatabasePaths({String userID = "doesNotMatter", String interactingWithUserWithID = "doesNotMatter"}) {
    this.senderId = userID;
    this.recipientId = interactingWithUserWithID;
    this.isSenderTypingMessageRef = firestoreDatabase.collection("dm-presence").doc(userID);
  }

  void deleteConversation({required String conversationID, Function? onCompletion}) {
    //simply delete the document at /dm-conversations/{conversationDoc}. A cloud function will handle the deletion of
    // individual messages and storage items (images and audio files).
    firestoreDatabase
        .collection("dm-conversations")
        .doc(conversationID)
        .delete()
        .then((value) => () {
              //TODO: send a push notification to the other user
              if (onCompletion != null) onCompletion(); // call the completion handler
            })
        .catchError((error) {
      print("An error occurred while deleting a DM conversation: $error");
    });
  }
}
