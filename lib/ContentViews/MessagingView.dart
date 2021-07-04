import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/ChatMessageDataclasses.dart';
import 'package:podsquad/BackendDataclasses/PodMessageDataclasses.dart';
import 'package:podsquad/UIBackendClasses/MessagesDictionary.dart';


class MessagingView extends StatefulWidget {
  const MessagingView(
      {Key? key, required this.chatPartnerOrPodID, required this.chatPartnerOrPodName, required this.isPodMode})
      : super(key: key);

  /// Pass in the chat partner ID (if it's a DM) or pod ID (if it's a pod message)
  final String chatPartnerOrPodID;

  /// Pass in the chat partner name (if it's a DM) or pod name (if it's a pod message)
  final String chatPartnerOrPodName;

  /// Set to true if this is a pod message
  final bool isPodMode;

  @override
  _MessagingViewState createState() => _MessagingViewState(
      chatPartnerOrPodID: chatPartnerOrPodID, chatPartnerOrPodName: chatPartnerOrPodName, isPodMode: isPodMode);
}

class _MessagingViewState extends State<MessagingView> {
  _MessagingViewState({required this.chatPartnerOrPodID, required this.chatPartnerOrPodName, required this.isPodMode});

  final typingMessageController = TextEditingController();

  final String chatPartnerOrPodID;
  final String chatPartnerOrPodName;
  final bool isPodMode;

  /// Displays the chat log for a DM conversation
  List<ChatMessage> directMessageChatLog = [];

  /// Displays the chat log for a pod conversation
  List<PodMessage> podMessageChatLog = [];

  @override
  void initState() {
    super.initState();

    var dms = MessagesDictionary.shared.directMessagesDict.value[chatPartnerOrPodID] ?? [];
    var podMessages = MessagesDictionary.shared.podMessageDict.value[chatPartnerOrPodID] ?? [];
    dms.sort((a, b) => a.timeStamp.compareTo(b.timeStamp)); // sort in order
    podMessages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
    directMessageChatLog = dms.toSet().toList(); // removes duplicates
    podMessageChatLog = podMessages.toSet().toList(); // removes duplicates

    // Update in real time when the chat log changes (for direct messages)
    MessagesDictionary.shared.directMessagesDict.addListener(() {
      setState(() {
        print("New message received! ${directMessageChatLog.last}");
        var dms = MessagesDictionary.shared.directMessagesDict.value[chatPartnerOrPodID] ?? [];
        dms.sort((a, b) => a.timeStamp.compareTo(b.timeStamp)); // sort in order
        directMessageChatLog = dms.toSet().toList(); // removes duplicates
      });
    });

    // Update in real time when the chat log changes (for pod messages)
    MessagesDictionary.shared.podMessageDict.addListener(() {
      setState(() {
        var podMessages = MessagesDictionary.shared.podMessageDict.value[chatPartnerOrPodID] ?? [];
        podMessages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
        podMessageChatLog = podMessages.toSet().toList(); // removes duplicates
      });
    });
  }

  @override
  void dispose() {
    MessagesDictionary.shared.directMessagesDict.removeListener(() { });
    MessagesDictionary.shared.podMessageDict.removeListener(() { });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Message $chatPartnerOrPodName"),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
                child: ListView.builder(
                    itemCount: isPodMode ? podMessageChatLog.length : directMessageChatLog.length,
                    itemBuilder: (context, index) {
                      // index both a direct message and a pod message to ensure the list is interchangeable for both
                      // types. Must make sure the list index remains within range
                      final directMessage = directMessageChatLog.length > index ? directMessageChatLog[index] : null;
                      final podMessage = podMessageChatLog.length > index ? podMessageChatLog[index] : null;
                      return Text(isPodMode ? (podMessage?.text ?? "NO MESSAGE") : (directMessage?.text ?? "NO "
                          "MESSAGE"));
                    })),
            CupertinoTextField(
              maxLines: null,
              controller: typingMessageController,
              placeholder: "Message ${isPodMode ? chatPartnerOrPodName : chatPartnerOrPodName.split(" ").first}",
            )
          ],
        ),
      ),
    );
  }
}
