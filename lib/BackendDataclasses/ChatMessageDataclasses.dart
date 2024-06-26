import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

///Stores a message as it is being uploaded to the database (no images)
class ChatMessage {
  String id;
  String? imageURL;
  String? audioURL;

  ///The path to the storage location, which can be used to delete the object using a cloud function
  String? imagePath;
  String? audioPath;
  String recipientId;
  String recipientName;
  String senderId;
  String senderName;
  double timeStamp;
  String text;

  ///Only required if the message is sent to a pod
  String? podID;

  ///Only required if the message is sent to a pod
  String? podName;

  ///Pass in the message sender's profile thumbnail URL when downloading a message from the database
  String senderThumbnailURL;

  ///Pass in the recipient's thumbnail URL when downloading a direct message from the database
  String recipientThumbnailURL;

  /// Pass in the pod thumbnail URL when downlaoding a pod message from the database
  String? podThumbnailURL;

  ///Automatically determines the chat partner thumbnail URL given a sender ID and recipient ID. If the message is a
  ///pod message and has no recipient, then the chatPartnerThumbnailURL will be the sender's thumbnail URL.
  String get chatPartnerThumbnailURL {
    if (recipientThumbnailURL.isNotEmpty) {
      if (podID == null) return senderId == myFirebaseUserId ? recipientThumbnailURL : senderThumbnailURL;
      else return podThumbnailURL ?? senderThumbnailURL; // if it's a pod message, return the pod thumbnail URL
    } else
      return podThumbnailURL ?? senderThumbnailURL; // if recipientThumbnail is empty, it must be a pod message
  }

  ///Automatically determines the chat partner ID given a sender ID and recipient ID. If the message is a pod message
  /// and has no recipient ID, return the pod ID. If the recipient ID is blank and the pod ID is null, return the
  /// String "null".
  String get chatPartnerId {
    if (recipientId.isNotEmpty)
      return senderId == myFirebaseUserId ? recipientId : senderId;
    else
      return senderId; // if this is a pod message (no recipientId), then display the sender ID
  }

  ///Automatically determines the chat partner name given a sender name and recipient name. If the message is a pod
  ///message and has no recipient name, return the pod name. If the recipient name is blank and the pod name is null,
  /// return the String "null".
  String get chatPartnerName {
    if (recipientName.isNotEmpty)
      return senderId == myFirebaseUserId ? recipientName : senderName;
    else
      return senderName; // if this is a pod message (no recipientId), then display the sender name
  }

  ///Pass in a list of people who read the message so I can determine whether to make the font bold
  List<String>? readBy;

  /// Pass in a map of {personID: timeTheyReadTheMessage} that stores when each person read the message
  Map<String, num>? readTimes;

  /// Pass in a map of {personID: personName} that stores the name of each person who read the message
  Map<String, String>? readNames;

  ChatMessage(
      {required this.id,
      this.imageURL,
      this.audioURL,
      this.imagePath,
      this.audioPath,
      required this.recipientId,
      required this.recipientName,
      required this.senderId,
      required this.senderName,
      required this.timeStamp,
      required this.text,
      this.podID,
      this.podName,
      required this.senderThumbnailURL,
      required this.recipientThumbnailURL,
      this.podThumbnailURL,
      this.readBy, this.readTimes, this.readNames});

  ///Marks a message as read in the database. If it's a DM, pass in the alphabetical combination of chat partner IDs.
  /// If it's a pod message, pass in the pod ID for conversationID.
  void markMessageRead({required ChatMessage message, required List<String> listOfPeopleWhoReadTheMessage, required
  String
  conversationID}) {
    String messageID = message.id;
    if (!listOfPeopleWhoReadTheMessage.contains(myFirebaseUserId)) {
      bool isPodMessage =
          conversationID.length <= 20; //pod IDs are 20 characters long, but DM conversation IDs are 40 characters long

      // Now actually update the message in the database
      if (isPodMessage) {
        firestoreDatabase.collection("pods").doc(conversationID).collection("messages").doc(messageID).set({
          "readBy": FieldValue.arrayUnion([myFirebaseUserId]),
          // Indicate that I read the message
          "readTime": {myFirebaseUserId: DateTime.now().millisecondsSinceEpoch * 0.001},
          // Indicate the time I read the message. Must divide by 1000 because
          // Swift (and the database) stores time in seconds since January 1, 1970.
          "readName": {myFirebaseUserId: MyProfileTabBackendFunctions.shared.myProfileData.value.name}
        }, SetOptions(merge: true)); // there's no merge: true option in Dart, so I have to use the update method (which
        // should
        // work exactly the same way).
      } else {
        firestoreDatabase
            .collection("dm-conversations")
            .doc(conversationID)
            .collection("messages")
            .doc(messageID)
            .set({
          "readBy": FieldValue.arrayUnion([myFirebaseUserId]),
          "readTime": {myFirebaseUserId: DateTime.now().millisecondsSinceEpoch * 0.001},
          "readName": {myFirebaseUserId: MyProfileTabBackendFunctions.shared.myProfileData.value.name}
        }, SetOptions(merge: true)).catchError((error){
          print("Error marking message read: $error");
        });
      }
    }
  }

  // Declare that two PodMessage objects are the same if and only if they have the same ID.
  @override
  bool operator ==(Object otherInstance) => otherInstance is ChatMessage && id == otherInstance.id;

  @override
  int get hashCode => id.hashCode;
}

//No need for a DownloadedChatMessage class, because I can simply use the CachedNetworkImage widget to automatically
//render and cache images given just the URL.
