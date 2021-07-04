import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendDataclasses/ChatMessageDataclasses.dart';
import 'package:podsquad/ContentViews/MessagingView.dart';
import 'package:podsquad/ListRowViews/LatestMessageRow.dart';
import 'package:podsquad/UIBackendClasses/MessagingTabFunctions.dart';

class MessagingTab extends StatefulWidget {
  const MessagingTab({Key? key}) : super(key: key);

  @override
  _MessagingTabState createState() => _MessagingTabState();
}

class _MessagingTabState extends State<MessagingTab> {
  /// The list of messaging conversation previews to show in the messaging tab. Don't set this directly; instead set
  /// displayedMessagesDict.
  List<ChatMessage> get _displayedMessagesList {
    final List<ChatMessage> combinedList = _podMessagesList + _directMessagesList;

    // sort such that the newest messages appear first
    combinedList.sort((b, a) => a.timeStamp.compareTo(b.timeStamp));
    return combinedList;
  }

  List<ChatMessage> _podMessagesList = [];
  List<ChatMessage> _directMessagesList = [];

  /// Use this for highlighting list items on tap
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    print("BIDEN: VIEW APPEARED");

    // Unlike in SwiftUI, the listeners don't seem to be called automatically when the widget appears. So first I
    // have to assign values to my variables, then attach listeners to listen for variable changes.
    this._directMessagesList = LatestDirectMessagesDictionary.shared.sortedLatestMessageList.value;
    this._podMessagesList = LatestPodMessagesDictionary.shared.sortedLatestMessageList.value;

    // Listen for all my DM conversations and get the latest message preview
    LatestDirectMessagesDictionary.shared.sortedLatestMessageList.addListener(() {
      print("JOE BIDEN");
      final messages = LatestDirectMessagesDictionary.shared.sortedLatestMessageList.value;
      setState(() {
        this._directMessagesList = messages;
        print("BIDEN: so I just received this value: ${messages.first.text}, but I could only get this from it: "
            "${_directMessagesList.first.text}");
      });
    });

    // Listen for all my pod message conversations and get the latest message preview
    LatestPodMessagesDictionary.shared.sortedLatestMessageList.addListener(() {
      final messages = LatestPodMessagesDictionary.shared.sortedLatestMessageList.value;
      setState(() {
        this._podMessagesList = messages;
      });
    });

    // reset the selected index so no rows are highlighted initially
    this._selectedIndex = null;
  }

  @override
  void dispose() {
    super.dispose();
    LatestDirectMessagesDictionary.shared.sortedLatestMessageList.removeListener(() {});
    LatestPodMessagesDictionary.shared.sortedLatestMessageList.removeListener(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text("Messages"),
          ),
          SliverList(
              delegate: SliverChildListDelegate(
            [
              SafeArea(
                  child: Stack(
                children: [
                  Column(children: [
                    for (var message in _displayedMessagesList)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            this._selectedIndex = _displayedMessagesList.indexWhere((element) => element == message);
                          });
                          Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) => MessagingView(
                                    chatPartnerOrPodID:
                                    message.podID != null ? message.podID! : message.chatPartnerId,
                                    chatPartnerOrPodName:
                                    message.podName != null ? message.podName! : message.chatPartnerName,
                                    isPodMode: message.podID != null,
                                  ))).then((value) {
                            setState(() {
                              this._selectedIndex = null; // clear the selected index to remove row highlighting
                            });
                          });
                        },
                        child: Card(
                          color: _selectedIndex == _displayedMessagesList.indexWhere((element) => element==message) ? Colors.white60 : CupertinoColors
                              .systemBackground,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: LatestMessageRow(
                              chatPartnerOrPodName: message.podID != null ? message.podName! : message.chatPartnerName,
                              chatPartnerOrPodThumbnailURL: message.chatPartnerThumbnailURL,
                              content: message.text,
                              timeStamp: message.timeStamp,
                            ),
                          ),
                        ),
                      ),
                  ],),
                  if (this._displayedMessagesList.isEmpty)
                    Center(
                      child: Text(
                        "You don't have any messages",
                        style: TextStyle(color: CupertinoColors.inactiveGray),
                      ),
                    )
                ],
              ))
            ],
          ))
        ],
      ),
    );
  }
}
