import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';

/// Handles subscribing and un-subscribing from push notifications
class PushNotificationStatus {
  static final shared = PushNotificationStatus();

  /// Set to true to receive push notifications; set to false otherwise
  var enabled = true;

  /// Subscribe to receive push notifications
  void subscribe() {
    firebaseMessaging.subscribeToTopic(myFirebaseUserId).then((value) {
      this.enabled = true;
    }).catchError((error) {
      print("An error occurred while subscribing to push notifications: $error");
    });
  }

  /// Unsubscribe from push notifications
  void unsubscribe() {
    firebaseMessaging.unsubscribeFromTopic(myFirebaseUserId).then((value) {
      this.enabled = false;
    }).catchError((error) {
      print("An error occurred while un-subscribing from push notifications: $error");
    });
  }
}
