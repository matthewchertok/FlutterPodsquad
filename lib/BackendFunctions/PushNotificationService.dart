import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'package:podsquad/BackendDataclasses/PushNotification.dart';

///I'm not using this class. Keeping the file around for reference on how to parse a push notification (see
///FirebaseMessaging.onMessage.listen()).
class PushNotificationService {
  final FirebaseMessaging _fcm;

  PushNotificationService(this._fcm);

  Future initialise() async {
    if (Platform.isIOS) {
      _fcm.requestPermission();
    }

    // If you want to test the push notification locally,
    // you need to get the token and input to the Firebase console
    // https://console.firebase.google.com/project/YOUR_PROJECT_ID/notification/compose
    String? token = await _fcm.getToken();
    print("FirebaseMessaging token: $token");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
          senderID: message.data["senderID"],
          senderName: message.data["senderName"],
          notificationType: message.data["notificationType"],
          podID: message.data["podID"],
          podName: message.data["podName"]);
    });
  }
}
