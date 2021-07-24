/// A simple object containing a pod member ID and their name. Used only to create "MEMBER NAME" is typing... in
/// MessagingView
class PodMemberIDNameAndTypingStatus {
  PodMemberIDNameAndTypingStatus({required this.memberID, required this.name, required this.isTyping});
  final String memberID;
  final String name;
  final bool isTyping;

  // Declare that two PodMemberIDAndName objects are the same if and only if they have the same ID.
  @override
  bool operator ==(Object otherInstance) =>
      otherInstance is PodMemberIDNameAndTypingStatus && memberID == otherInstance.memberID;

  @override
  int get hashCode => memberID.hashCode;
}