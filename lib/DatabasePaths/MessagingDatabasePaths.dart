import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

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

  ///Returns the path in Firebase storage containing my image message
  Reference get messageContentImagePath => firebaseStorage.ref().child("messaging-images").child(senderId).child
    (recipientId);

  ///References /messaging-audio/userID/interactingWithUserWithID
  Reference get messageAudioRecordingPath => firebaseStorage.ref().child("messaging-audio").child(senderId).child(recipientId);

  ///References /messaging-audio/userID. Pass in podID for userID.
  Reference get podMessageAudioRecordingPath => firebaseStorage.ref().child("messaging-audio").child(senderId);


  ///Delete a conversation by invoking a cloud function
  void deleteConversation({required String conversationID, Function? onCompletion}) {
    //simply delete the document at /dm-conversations/{conversationDoc}. A cloud function will handle the deletion of
    // individual messages and storage items (images and audio files).
    firestoreDatabase
        .collection("dm-conversations")
        .doc(conversationID)
        .delete()
        .then((value) {
              //TODO: send a push notification to the other user
              if (onCompletion != null) onCompletion(); // call the completion handler
            })
        .catchError((error) {
      print("An error occurred while deleting a DM conversation: $error");
    });
  }

  ///Deletes a direct message with another person. Currently, this does not send the other person a push notification
  /// because we want to be careful not to send too many push notifications.
  void deleteDirectMessage({required String conversationID, required String messageID, required String chatPartnerID,
    String? imageURLString, String? audioURLString, required bool
    isThisTheLastMessageInTheConversation}){
    //The document's name is equal to a combination of my ID and my chat partner's ID, in alphabetical order
    final conversationDocumentName = chatPartnerID < myFirebaseUserId ? chatPartnerID+myFirebaseUserId :
    myFirebaseUserId+chatPartnerID;
    final conversationDocumentReference = firestoreDatabase.collection("dm-conversations").doc(conversationDocumentName);
    conversationDocumentReference.collection("messages").doc(messageID).delete().then((value) {
      //If the last message in the conversation was deleted, then delete the conversation (obviously)
      if(isThisTheLastMessageInTheConversation) conversationDocumentReference.delete();

      //Delete the message's associated image and audio, if necessary
      if(imageURLString != null) firebaseStorage.refFromURL(imageURLString).delete();
      if(audioURLString != null) firebaseStorage.refFromURL(audioURLString).delete();
    });
  }
}
