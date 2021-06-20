///Maps {userID or podID: messageText} in order to let the user navigate away from a conversation without losing
///their pending text (as long as the app stays open).
class PendingMessageText {
  static final shared = PendingMessageText();

  ///When a widget disappears, save the value of the pending message text like this: PendingMessageText.shared
///.pendingMessageDictionary[userID or podID] = some_message_text
  var pendingMessageDictionary = Map<String, String>();
}