import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:podsquad/BackendDataclasses/ChatMessageDataclasses.dart';
import 'package:podsquad/CommonlyUsedClasses/AlertDialogs.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/MessagingView.dart';
import 'package:podsquad/DatabasePaths/MessagingDatabasePaths.dart';
import 'package:podsquad/DatabasePaths/PodsDatabasePaths.dart';
import 'package:podsquad/ListRowViews/LatestMessageRow.dart';
import 'package:podsquad/BackendFunctions/ShowLikesFriendsBlocksActionSheet.dart';
import 'package:podsquad/OtherSpecialViews/PodModeButton.dart';
import 'package:podsquad/OtherSpecialViews/SearchTextField.dart';
import 'package:podsquad/UIBackendClasses/MessagesDictionary.dart';
import 'package:podsquad/UIBackendClasses/MessagingTabFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

class MessagingTab extends StatefulWidget {
  const MessagingTab({Key? key, this.showingHiddenChats = false}) : super(key: key);
  final showingHiddenChats;

  @override
  _MessagingTabState createState() => _MessagingTabState(showingHiddenChats: showingHiddenChats);
}

class _MessagingTabState extends State<MessagingTab> {
  _MessagingTabState({required this.showingHiddenChats});
  final showingHiddenChats;
  final _customScrollViewController = ScrollController();
  final _searchTextController = TextEditingController();

  /// The list of messaging conversation previews to show in the messaging tab. Don't set this directly; instead set
  /// displayedMessagesDict. Responds to changes in search text to return only results where a part of the chat partner
  /// name or
  /// message text matches the search text. Also, don't display conversations that are hidden.d
  List<ChatMessage> get _displayedMessagesList {
    final List<ChatMessage> combinedList = _podMessagesList + _directMessagesList;

    // sort such that the newest messages appear first
    combinedList.sort((b, a) => a.timeStamp.compareTo(b.timeStamp));

    if (!isSearching) // return all conversations that aren't hidden
      return combinedList.where((element) =>
          !_listOfIDsForDMConversationsIveHidden.contains(element.chatPartnerId) &&
          !_listOfIDsForPodChatsIveHidden.contains(element.podID))
          .toList();
    else
      return combinedList
          .where((element) =>
              (element.chatPartnerName.toLowerCase().contains(_searchTextController.text.trim().toLowerCase()) ||
                  element.text.toLowerCase().contains(_searchTextController.text.trim().toLowerCase())) &&
              !_listOfIDsForDMConversationsIveHidden.contains(element.chatPartnerId) &&
              !_listOfIDsForPodChatsIveHidden.contains(element.podID))
          .toList();
  }

  /// The list of hidden chats (only displayed if showingHiddenChats is true)
  List<ChatMessage> get _hiddenMessagesList {
    final List<ChatMessage> combinedList = _podMessagesList + _directMessagesList;

    // sort such that the newest messages appear first
    combinedList.sort((b, a) => a.timeStamp.compareTo(b.timeStamp));

    if (!isSearching) // return all conversations that are hidden
      return combinedList.where((element) =>
      _listOfIDsForDMConversationsIveHidden.contains(element.chatPartnerId) ||
          _listOfIDsForPodChatsIveHidden.contains(element.podID))
          .toList();
    else
      return combinedList
          .where((element) =>
      (element.chatPartnerName.toLowerCase().contains(_searchTextController.text.trim().toLowerCase()) ||
          element.text.toLowerCase().contains(_searchTextController.text.trim().toLowerCase())) &&
          (_listOfIDsForDMConversationsIveHidden.contains(element.chatPartnerId) ||
          _listOfIDsForPodChatsIveHidden.contains(element.podID)))
          .toList();
  }

  List<ChatMessage> _podMessagesList = [];
  List<ChatMessage> _directMessagesList = [];

  List<String> _listOfIDsForPodChatsIveHidden = [];
  List<String> _listOfIDsForDMConversationsIveHidden = [];

  /// Use this for highlighting list items on tap
  int? _selectedIndex;

  /// Determine whether to show the search bar below the navigation bar
  var _searchBarShowing = false;

  /// Set to true if I am typing something into the search bar
  var isSearching = false;

  /// Hide a DM or pod conversation
  void _hideConversation({required ChatMessage message}) {
    // highlight the conversation
    setState(() {
      _selectedIndex = _displayedMessagesList.indexWhere((element) => element.id == message.id);
    });

    // hide a DM conversation
    if (message.podID == null) {
      final hideDMConversationAlert = CupertinoAlertDialog(
        title: Text("Hide Conversation"),
        content: Text("Are you "
            "sure you want to hide your conversation with ${message.chatPartnerName}? You will be able to view it again if you send or receive a message from ${message.chatPartnerName.firstName()}."),
        actions: [
          // cancel button
          CupertinoButton(
              child: Text("No"),
              onPressed: () {
                dismissAlert(context: context);
                setState(() {
                  this._selectedIndex = null; // clear the row highlighting
                });
              }),

          // hide button
          CupertinoButton(
              child: Text("Yes"),
              onPressed: () {
                dismissAlert(context: context);
                final documentId = message.chatPartnerId < myFirebaseUserId
                    ? message.chatPartnerId + myFirebaseUserId
                    : myFirebaseUserId + message.chatPartnerId;
                firestoreDatabase.collection("dm-conversations").doc(documentId).set({
                  myFirebaseUserId: {"didHideChat": true}
                }, SetOptions(merge: true)).then((value) {
                  setState(() {
                    this._selectedIndex = null; // clear the row highlighting
                  });
                });
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => hideDMConversationAlert);
    }

    // hide a pod conversation
    else {
      final hidePodConversationAlert = CupertinoAlertDialog(
        title: Text("Hide Conversation"),
        content: Text("Are you "
            "sure you want to hide the ${message.podName} chat? You will be able to view it again if you send a message"
            " to the pod. Additionally, you will not receive new message notifications from ${message.podName} while "
            "the chat is hidden"),
        actions: [
          // cancel button
          CupertinoButton(
              child: Text("No"),
              onPressed: () {
                dismissAlert(context: context);
                setState(() {
                  this._selectedIndex = null; // clear the row highlighting
                });
              }),

          // hide chat button
          CupertinoButton(
              child: Text("Yes"),
              onPressed: () {
                dismissAlert(context: context);
                PodsDatabasePaths(podID: message.podID!).hidePodConversation(onCompletion: () {
                  setState(() {
                    this._selectedIndex = null; // clear the row highlighting
                  });
                });
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => hidePodConversationAlert);
    }
  }

  /// Un-hide a DM or pod conversation. Don't show an alert here because we don't want to overwhelm the user with
  /// popup dialogs. Just go ahead and un-hide the conversation.
  void _unHideConversation({required ChatMessage message}) {
    // highlight the conversation
    setState(() {
      _selectedIndex = _displayedMessagesList.indexWhere((element) => element.id == message.id);
    });

    // un-hide a DM conversation
    if (message.podID == null) {
      final documentId = message.chatPartnerId < myFirebaseUserId
          ? message.chatPartnerId + myFirebaseUserId
          : myFirebaseUserId + message.chatPartnerId;
      firestoreDatabase.collection("dm-conversations").doc(documentId).set({
        myFirebaseUserId: {"didHideChat": false}
      }, SetOptions(merge: true)).then((value) {
        setState(() {
          this._selectedIndex = null; // clear the row highlighting
        });
      });
    }

    // un-hide a pod conversation
    else {
      PodsDatabasePaths(podID: message.podID!).unHidePodConversation(onCompletion: () {
        setState(() {
          this._selectedIndex = null; // clear the row highlighting
        });
      });
    }
  }

  /// Delete a DM or pod conversation
  void _deleteConversation({required ChatMessage message}) {
    // highlight the conversation
    setState(() {
      _selectedIndex = _displayedMessagesList.indexWhere((element) => element.id == message.id);
    });

    // delete a DM conversation
    if (message.podID == null) {
      final conversationID = message.chatPartnerId < myFirebaseUserId
          ? message.chatPartnerId + myFirebaseUserId
          : myFirebaseUserId + message.chatPartnerId;
      final deleteDMConversationAlert = CupertinoAlertDialog(
        title: Text("Are You Sure?"),
        content: Text("Are you "
            "sure you want to permanently delete your conversation with ${message.chatPartnerName}? This action cannot "
            "be undone."),
        actions: [
          CupertinoButton(
              child: Text("No"),
              onPressed: () {
                dismissAlert(context: context);
                setState(() {
                  this._selectedIndex = null;
                });
              }),
          CupertinoButton(
              child: Text("Yes", style: TextStyle(color: CupertinoColors.destructiveRed)),
              onPressed: () {
                dismissAlert(context: context);
                MessagingDatabasePaths(userID: message.chatPartnerId, interactingWithUserWithID: myFirebaseUserId)
                    .deleteConversation(
                        conversationID: conversationID,
                        onCompletion: () {
                          showSingleButtonAlert(
                              context: context,
                              title: "Deletion In Progress",
                              content: "Your conversation with ${message.chatPartnerName} will be deleted shortly.",
                              dismissButtonLabel: "OK");
                          setState(() {
                            this._selectedIndex = null;
                            _directMessagesList.removeWhere((element) => element == message);
                          });
                        });
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => deleteDMConversationAlert);
    }

    // delete a pod conversation
    else {
      final deletePodConversationAlert = CupertinoAlertDialog(
        title: Text("Are You Sure?"),
        content: Text("Are you "
            "sure you want to permanently delete the ${message.podName ?? "pod"} chat? This action cannot be undone."),
        actions: [
          CupertinoButton(
              child: Text("No"),
              onPressed: () {
                dismissAlert(context: context);
                setState(() {
                  this._selectedIndex = null;
                });
              }),
          CupertinoButton(
              child: Text(
                "Yes",
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
              onPressed: () {
                dismissAlert(context: context);
                PodsDatabasePaths(podID: message.podID!).deletePodConversation(
                    podName: message.podName ?? "this pod",
                    onCompletion: () {
                      showSingleButtonAlert(
                          context: context,
                          title: "Deletion In Progress",
                          content: "All messages in ${message.podName ?? "this pod"} will be deleted shortly.",
                          dismissButtonLabel: "OK");
                    });
                setState(() {
                  this._selectedIndex = null;
                  _podMessagesList.removeWhere((element) => element == message);
                });
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => deletePodConversationAlert);
    }
  }

  @override
  void initState() {
    super.initState();
    // Unlike in SwiftUI, the listeners don't seem to be called automatically when the widget appears. So first I
    // have to assign values to my variables, then attach listeners to listen for variable changes.
    this._directMessagesList = LatestDirectMessagesDictionary.shared.sortedLatestMessageList.value;
    this._podMessagesList = LatestPodMessagesDictionary.shared.sortedLatestMessageList.value;
    this._listOfIDsForDMConversationsIveHidden = MessagesDictionary.shared.listOfDMConversationsIveHidden.value;
    this._listOfIDsForPodChatsIveHidden = MessagesDictionary.shared.listOfPodChatsIveHidden.value;

    // Listen for all my DM conversations and get the latest message preview
    LatestDirectMessagesDictionary.shared.sortedLatestMessageList.addListener(() {
      final messages = LatestDirectMessagesDictionary.shared.sortedLatestMessageList.value;
      setState(() {
        this._directMessagesList = messages;
      });
    });

    // Listen for all my pod message conversations and get the latest message preview
    LatestPodMessagesDictionary.shared.sortedLatestMessageList.addListener(() {
      final messages = LatestPodMessagesDictionary.shared.sortedLatestMessageList.value;
      setState(() {
        this._podMessagesList = messages;
      });
    });

    // Listen for all DM conversations that I've hidden
    MessagesDictionary.shared.listOfDMConversationsIveHidden.addListener(() {
      final dmsIveHidden = MessagesDictionary.shared.listOfDMConversationsIveHidden.value;
      setState(() {
        this._listOfIDsForDMConversationsIveHidden = dmsIveHidden;
      });
    });

    // Listen for all pod conversations that I've hidden
    MessagesDictionary.shared.listOfPodChatsIveHidden.addListener(() {
      final podsIveHidden = MessagesDictionary.shared.listOfPodChatsIveHidden.value;
      setState(() {
        this._listOfIDsForPodChatsIveHidden = podsIveHidden;
      });
    });

    // Hide the search bar if the user swipes up, and show it if the user swipes down
    Future.delayed(Duration(milliseconds: 250), () {
      _customScrollViewController.addListener(() {
        final scrollDirection = _customScrollViewController.position.userScrollDirection;

        // scroll up to hide the search bar
        if (scrollDirection == ScrollDirection.reverse && _searchTextController.text.isEmpty)
          setState(() {
            _searchBarShowing = false;
            print("Scrolling up!");
          });

        // scroll down to show the search bar
        else if (scrollDirection == ScrollDirection.forward)
          setState(() {
            _searchBarShowing = true;
            print("Scrolling down!");
          });
      });
    });

    /// Determine when I'm searching for a conversation
    _searchTextController.addListener(() {
      final text = _searchTextController.text;
      setState(() {
        this.isSearching = text.trim().isNotEmpty;
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
    MessagesDictionary.shared.listOfDMConversationsIveHidden.removeListener(() {});
    MessagesDictionary.shared.listOfPodChatsIveHidden.removeListener(() {});
    _customScrollViewController.removeListener(() {});
    _searchTextController.removeListener(() {});
  }

  @override
  Widget build(BuildContext context) {
    final messagesList = this.showingHiddenChats ? _hiddenMessagesList : _displayedMessagesList;
    return CupertinoPageScaffold(
      child: SafeArea(child: CustomScrollView(
        controller: _customScrollViewController,
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            padding: EdgeInsetsDirectional.all(5),
            leading: this.showingHiddenChats ? null : CupertinoButton(
              child: Icon(CupertinoIcons.line_horizontal_3),
              onPressed: () {
                showLikesFriendsBlocksActionSheet(context: context);
              },
              padding: EdgeInsets.zero,
            ),
            trailing: this.showingHiddenChats ? null : Container(width: 120, child: Row(mainAxisAlignment:
            MainAxisAlignment.end, children: [
              // Navigate to see my hidden chats (so I can un-hide them)
              if (_hiddenMessagesList.length > 0)
                CupertinoButton(padding: EdgeInsets.zero, child: Icon(CupertinoIcons.eye_slash_fill), onPressed: (){
                  Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (context) => MessagingTab(showingHiddenChats: true,)));
                }),

              // the button to go to view my pods
              podModeButton(context: context)
            ],),),
            largeTitle: Text(this.showingHiddenChats ? "Hidden Chats" : "Messages"),
            stretch: true,
          ),
          SliverList(
              delegate: SliverChildListDelegate(
                [
                  Column(
                    children: [
                      // collapsible search bar                   ,
                      AnimatedSwitcher(
                          transitionBuilder: (child, animation) {
                            return SizeTransition(
                              sizeFactor: animation,
                              child: child,
                            );
                          },
                          duration: Duration(milliseconds: 250),
                          child: _searchBarShowing
                              ? Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: SearchTextField(
                              controller: _searchTextController,
                            ),
                          )
                              : Container()),

                      // Depending on the view type, show either hidden chats or non-hidden chats (defaults to non-hidden
                      // chats, obviously)
                      for (var message in messagesList)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              this._selectedIndex = messagesList.indexWhere((element) => element == message);
                            });
                            Navigator.of(context, rootNavigator: true)
                                .push(CupertinoPageRoute(
                                builder: (context) => MessagingView(
                                  chatPartnerOrPodID:
                                  message.podID != null ? message.podID! : message.chatPartnerId,
                                  chatPartnerOrPodName:
                                  message.podName != null ? message.podName! : message.chatPartnerName,
                                  chatPartnerThumbnailURL: message.chatPartnerThumbnailURL,
                                  isPodMode: message.podID != null,
                                )))
                                .then((value) {
                              setState(() {
                                this._selectedIndex = null; // clear the selected index to remove row highlighting
                              });
                            });
                          },
                          child: Slidable(
                            child: Card(
                              color: _selectedIndex == messagesList.indexWhere((element) => element == message)
                                  ? Colors.white60
                                  : CupertinoColors.systemBackground,
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
                            actionPane: SlidableDrawerActionPane(),

                            // The Hide button is on the left, and the Delete button is on the right
                            actions: [
                              // hide a conversation
                              if (!showingHiddenChats)
                                IconSlideAction(
                                    color: CupertinoColors.systemYellow,
                                    icon: CupertinoIcons.eye_slash_fill,
                                    caption: "Hide",
                                    onTap: () {
                                      this._hideConversation(message: message);
                                    })

                              else IconSlideAction(color: CupertinoColors.activeGreen, icon: CupertinoIcons.eye_fill, caption:
                              "Un-hide", onTap: (){
                                this._unHideConversation(message: message);
                              },)
                            ],
                            secondaryActions: [
                              // delete a conversation
                              IconSlideAction(
                                color: CupertinoColors.destructiveRed,
                                icon: CupertinoIcons.trash,
                                caption: "Delete",
                                onTap: () {
                                  this._deleteConversation(message: message);
                                },
                              )
                            ],
                          ),
                        ),
                      if (this.showingHiddenChats && this._hiddenMessagesList.isEmpty || !this.showingHiddenChats && this
                          ._displayedMessagesList.isEmpty)
                        Padding(padding: EdgeInsets.all(20), child: Text(
                            isSearching ? "No results found" : "You don't have any messages",
                            style: TextStyle(color: CupertinoColors.inactiveGray),
                          ),),

                    ],
                  ),
                ],
              ))
        ],
      ),),
    );
  }
}
