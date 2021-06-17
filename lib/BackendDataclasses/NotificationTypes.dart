///A class that stores the types of push notifications a user might send (i.e. message notification, like
///notification, friend notification, person met notification).
///1. "like" takes the user to the "People I Like/People Who Like Me" view
///2. "friend" takes the user to the "People I Friended/People Who Friended Me" view
///3. "message" takes the user to the appropriate DM messaging view
///4. "podMessage" takes the user to the appropriate group chat view
///"personDetails" takes the user to view the other person's profile
class NotificationTypes {
  static const like = "like";
  static const friend = "friend";
  static const message = "message";
  static const personDetails = "person_details";
  static const podMessage = "pod_message";
  static const podDetails = "pod_details";
  static const none = "none";
}
