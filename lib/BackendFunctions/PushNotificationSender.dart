import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

class PushNotificationSender {
  static final shared = PushNotificationSender();

  ///Sends a push notification to another user by calling a cloud function. For the notificationType string
  ///parameter, pass in a static constant from the
  ///NotificationTypes class.
  void sendPushNotification(
      {required String recipientID,
      required String title,
      required String body,
      String? senderName,
      String? senderID,
      String? podID,
      String? podName,
      required String notificationType}) {
    final nonOptionalSenderID = senderID == null ? myFirebaseUserId : senderID; // if no value is passed in for
    // senderID, default to myFirebaseUserID. Otherwise, use the passed-in value.
    final nonOptionalSenderName =
        senderName == null ? MyProfileTabBackendFunctions.shared.myProfileData.value.name : senderName;
    final nonOptionalPodID = podID == null ? "nil" : podID;
    final nonOptionalPodName = podName == null ? "nil" : podName;

    // call the cloud function, which will send the push notification from a secure server environment
    firebaseFunctions.httpsCallable("sendPushNotification").call({
      "recipientID": recipientID,
      "title": title,
      "body": body,
      "clickAction": notificationType, // this is required so that the Android app launches on
      // notification tap. Might need to replace with "FLUTTER_NOTIFICATION_CLICK"
      "senderID": nonOptionalSenderID,
      "senderName": nonOptionalSenderName,
      "notificationType": notificationType,
      "podID": nonOptionalPodID,
      "podName": nonOptionalPodName
    });
  }
}
