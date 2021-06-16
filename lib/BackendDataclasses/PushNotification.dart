///A class that stores data included in a push notification
class PushNotification {
  PushNotification(
      {this.title,
      this.body,
      this.senderID,
      this.senderName,
      this.notificationType,
      this.podID,
      this.podName});

  String? title;
  String? body;
  String? senderID;
  String? senderName;
  String? notificationType;
  String? podID;
  String? podName;
}
