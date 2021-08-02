import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:podsquad/BackendDataclasses/ChatMessageDataclasses.dart';
import 'package:podsquad/BackendDataclasses/NotificationTypes.dart';
import 'package:podsquad/BackendDataclasses/PodMemberIDNameAndTypingStatus.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/BackendFunctions/PushNotificationSender.dart';
import 'package:podsquad/BackendFunctions/ResizeAndUploadImage.dart';
import 'package:podsquad/BackendFunctions/UploadAudio.dart';
import 'package:podsquad/BackendFunctions/TimeAndDateFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/AlertDialogs.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/ViewPodDetails.dart';
import 'package:podsquad/DatabasePaths/BlockedUsersDatabasePaths.dart';
import 'package:podsquad/DatabasePaths/PodsDatabasePaths.dart';
import 'package:podsquad/ListRowViews/MessagingRow.dart';
import 'package:podsquad/OtherSpecialViews/AudioRecorder.dart';
import 'package:podsquad/UIBackendClasses/MainListDisplayBackend.dart';
import 'package:podsquad/UIBackendClasses/MessagesDictionary.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';
import 'dart:io';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:uuid/uuid.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class MessagingView extends StatefulWidget {
  const MessagingView(
      {Key? key,
      required this.chatPartnerOrPodID,
      required this.chatPartnerOrPodName,
      required this.isPodMode,
      this.chatPartnerThumbnailURL})
      : super(key: key);

  /// Pass in the chat partner ID (if it's a DM) or pod ID (if it's a pod message)
  final String chatPartnerOrPodID;

  /// Pass in the chat partner name (if it's a DM) or pod name (if it's a pod message)
  final String chatPartnerOrPodName;

  /// Pass in the chat partner thumbnail URL (ignore if it's a pod message)
  final String? chatPartnerThumbnailURL;

  /// Set to true if this is a pod message
  final bool isPodMode;

  @override
  _MessagingViewState createState() => _MessagingViewState(
      chatPartnerOrPodID: chatPartnerOrPodID,
      chatPartnerOrPodName: chatPartnerOrPodName,
      chatPartnerThumbnailURL: chatPartnerThumbnailURL,
      isPodMode: isPodMode);
}

class _MessagingViewState extends State<MessagingView> {
  _MessagingViewState(
      {required this.chatPartnerOrPodID,
      required this.chatPartnerOrPodName,
      this.chatPartnerThumbnailURL,
      required this.isPodMode});

  final _typingMessageController = TextEditingController();
  final _chatLogScrollController = ScrollController();
  final _imageAndAudioScrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _refreshController = RefreshController();
  final _keyboardVisibilityController = KeyboardVisibilityController();

  /// Determine whether the keyboard is visible so I know if I need to hide it when scrolling
  bool _keyboardVisible = false;

  /// The image that gets picked from the photo library
  File? imageFile;

  /// Determine whether to show the audio recorder
  bool isRecordingAudio = false;

  final String chatPartnerOrPodID;
  final String chatPartnerOrPodName;
  final String? chatPartnerThumbnailURL;
  final bool isPodMode;

  /// Get the chat partner's profile data (if in DM mode) so I can access their device tokens to send them a push
  /// notification
  ProfileData? _chatPartnerProfileData;

  /// Displays the chat log for a DM conversation
  List<ChatMessage> displayedChatLog = [];

  /// Allows us to show the time at which a message was sent by mapping {messageID: true}
  Map<String, bool> showingMessageTimeStamp = {};

  /// Check whether I'm blocked by either my chat partner (if sending a DM) or by the pod (if it's pod messaging).
  bool _amIBlocked = false;

  /// Check whether I blocked the other user
  bool _didIBlockThem = false;

  /// Check whether I am a member of the pod (if pod mode)
  bool _amMemberOfPod = true;

  /// Use this to track whether I hid the conversation from my messaging tab
  bool didIHideTheConversation = false;

  /// Use this to track whether my chat partner hid the conversation from their messaging tab. Ignore if pod
  /// messaging.
  bool didChatPartnerHideTheConversation = false;

  /// Use this to determine when a message is sending to disable the Send button to avoid double-sending.
  bool _sendingInProgress = false;

  /// Allows us to control the animated list
  final _listKey = GlobalKey<SliverAnimatedListState>();

  /// Track all my stream subscriptions
  List<StreamSubscription> _streamSubscriptions = [];

  /// Keep track of all the pod active members and their FCM tokens (for push notifications) and update in real time
  Map<String, List<String>> _podActiveMemberIDsMap = {};

  /// Track whether the chat log is up to date (no more messages to load)
  bool _noMoreMessagesToLoad = false;

  /// If this is DM mode, get the conversation ID as an alphabetical combination of my user ID and my chat partner's
  /// user ID
  String get conversationID => chatPartnerOrPodID < myFirebaseUserId
      ? chatPartnerOrPodID + myFirebaseUserId
      : myFirebaseUserId + chatPartnerOrPodID;

  /// If displaying a DM conversation, this variable determines whether the chat partner is typing
  bool _chatPartnerTyping = false;

  /// If displaying a pod conversation, this map contains an object for each pod member that determines their name
  /// and whether they are typing a message. Maps {memberID, PodMemberIDNameAndTypingStatus}
  Map<String, PodMemberIDNameAndTypingStatus> _podMemberTypingMessageDictionary = {};

  /// Hide the read receipts if I scroll up to see older messages, and re-show them if I scroll back down to the bottom
  bool _didScrollToHideReadReceipts = false;

  /// Get the chat partner's profile data if in DM mode
  Future _getChatPartnerProfileData() async {
    if (isPodMode) return;
    MyProfileTabBackendFunctions().getPersonsProfileData(userID: chatPartnerOrPodID, onCompletion: (profileData){
      setState(() {
        this._chatPartnerProfileData = profileData;
      });
    });
  }

  /// Make the text to display when someone else is typing
  Widget someoneTypingText() {
    if (isPodMode) {
      final typingMembersCount = _podMemberTypingMessageDictionary.values.where((member) => member.isTyping).length;
      // if only one member is typing, just say "NAME is typing"
      if (typingMembersCount == 1) {
        final typingMemberName = _podMemberTypingMessageDictionary.values.first.name;
        return Padding(
          padding: EdgeInsets.all(5),
          child: Text(
            "${typingMemberName.firstName()} is typing...",
            style: TextStyle(fontSize: 12, color: CupertinoColors.inactiveGray),
          ),
        );
      }

      // if multiple members are typing, say "NAME and [x] others are typing"
      else if (typingMembersCount > 1) {
        var typingMembers = _podMemberTypingMessageDictionary.values.where((member) => member.isTyping).toList();
        typingMembers.sort((a, b) => a.name.compareTo(b.name)); // sort alphabetically
        final firstTypingMember = typingMembers.first.name;
        return Padding(
          padding: EdgeInsets.all(5),
          child: CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.bottomLeft,
              child: Text(
                "${firstTypingMember.firstName()} and "
                "${typingMembersCount - 1} ${typingMembersCount - 1 == 1 ? "other is" : "others are"} typing...",
                style: TextStyle(fontSize: 12, color: CupertinoColors.inactiveGray),
              ),
              onPressed: () {
                final infoSheet = CupertinoActionSheet(
                  title: Text("Currently typing:"),
                  actions: [
                    for (var typingMember in typingMembers)
                      Padding(
                        padding: EdgeInsets.all(5),
                        child: Text(
                          "${typingMember.name}",
                          style: TextStyle(color: CupertinoColors.inactiveGray),
                        ),
                      ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        dismissAlert(context: context);
                      },
                      child: Text("OK"),
                      isDefaultAction: true,
                    )
                  ],
                );
                showCupertinoModalPopup(context: context, builder: (context) => infoSheet);
              }),
        );
      }

      // if nobody is typing, return an empty container
      else
        return Container(
          width: 0,
          height: 0,
        );
    } else {
      if (_chatPartnerTyping)
        return Padding(
          padding: EdgeInsets.all(5),
          child: Text(
            "${chatPartnerOrPodName.firstName()} is typing...",
            style: TextStyle(fontSize: 12, color: CupertinoColors.inactiveGray),
          ),
        );
      else
        return Container(
          width: 0,
          height: 0,
        );
    }
  }

  /// Make the text to display when someone read the message
  Widget messageReadText({required ChatMessage message}) {
    final readByMemberIDs = message.readBy ?? [];
    final readByMemberNames = message.readNames ?? {};
    final readAtTimes = message.readTimes ?? {};
    print("MESSAGE READ BY ${readByMemberIDs.length} people. They are $readByMemberIDs");

    if (isPodMode) {
      if (readByMemberIDs.length > 1) {
        // if only one other person read the message, just say "Read by NAME"
        if (readByMemberIDs.length == 2) {
          final idOfTheMemberWhoReadIt = readByMemberIDs.where((element) => element != myFirebaseUserId).first;
          final nameOfTheMemberWhoReadIt = readByMemberNames[idOfTheMemberWhoReadIt];
          final timeTheyReadIt = readAtTimes[idOfTheMemberWhoReadIt] ?? DateTime.now().millisecondsSinceEpoch * 0.001;
          return Padding(
            padding: EdgeInsets.all(5),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.bottomRight,
              child: Text(
                "Read by $nameOfTheMemberWhoReadIt",
                style: TextStyle(fontSize: 12, color: CupertinoColors.inactiveGray),
              ),
              onPressed: () {
                final infoSheet = CupertinoActionSheet(
                  title: Text("Read by:"),
                  actions: [
                    Padding(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        "$nameOfTheMemberWhoReadIt: ${TimeAndDateFunctions.timeStampText(timeTheyReadIt.toDouble(), capitalized: false, includeFillerWords: true)}",
                        style: TextStyle(color: CupertinoColors.inactiveGray),
                      ),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        dismissAlert(context: context);
                      },
                      child: Text("OK"),
                      isDefaultAction: true,
                    )
                  ],
                );
                showCupertinoModalPopup(context: context, builder: (context) => infoSheet);
              },
            ),
          );
        }

        // if multiple people read the message, say "Read by NAME and [x] others"
        else {
          // get the names of all members who read the message
          var memberNamesMap = readByMemberNames;
          memberNamesMap.removeWhere((key, value) => !readByMemberIDs.contains(key));
          var memberNames = memberNamesMap.values.toList();

          // sort in alphabetical order
          memberNames.sort((a, b) => a.compareTo(b));
          final firstMember = memberNames.length > 0 ? memberNames.first : "someone";
          return Padding(
            padding: EdgeInsets.all(5),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.bottomRight,
              child: Text(
                "Read by ${firstMember.firstName()} and ${readByMemberIDs.length - 2} ${readByMemberIDs.length - 2 == 1 ? "other" : "others"}",
                style: TextStyle(fontSize: 12, color: CupertinoColors.inactiveGray),
              ),
              onPressed: () {
                final infoSheet = CupertinoActionSheet(
                  title: Text("Read by:"),
                  actions: [
                    for (var memberID in readByMemberIDs)
                      if (memberID != myFirebaseUserId)
                        Padding(
                          padding: EdgeInsets.all(5),
                          child: Text(
                            "${readByMemberNames[memberID]}: ${TimeAndDateFunctions.timeStampText((readAtTimes[memberID] ?? 0).toDouble(), capitalized: false, includeFillerWords: true)}",
                            style: TextStyle(color: CupertinoColors.inactiveGray),
                          ),
                        ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        dismissAlert(context: context);
                      },
                      child: Text("OK"),
                      isDefaultAction: true,
                    )
                  ],
                );
                showCupertinoModalPopup(context: context, builder: (context) => infoSheet);
              },
            ),
          );
        }
      } else
        return Container(
          width: 0,
          height: 0,
        ); // if nobody read my message, return an empty container
    }

    // for DMs, also show the time the message was read
    else {
      if (readByMemberIDs.length > 1) {
        final timeTheyReadTheMessage = readAtTimes[chatPartnerOrPodID] ?? DateTime.now().millisecondsSinceEpoch * 0.001;
        final readAt = DateTime.fromMillisecondsSinceEpoch((timeTheyReadTheMessage * 1000).toInt());
        return Padding(
          padding: EdgeInsets.all(5),
          child: Text(
            TimeAndDateFunctions.readByMessage(readAt: readAt),
            style: TextStyle(fontSize: 12, color: CupertinoColors.inactiveGray),
          ),
        );
      } else
        return Container(
          width: 0,
          height: 0,
        );
    }
  }

  /// Equal to true if I'm actively typing a message (if the text field isn't blank)
  ValueNotifier<bool> _amCurrentlyTyping = ValueNotifier(false);

  /// Updates the database to tell others whether I am typing a message
  void _updateTypingStatusInDatabase() {
    if (isPodMode) {
      if (_amCurrentlyTyping.value == true) {
        firestoreDatabase
            .collection("pods")
            .doc(chatPartnerOrPodID)
            .collection("members")
            .doc(myFirebaseUserId)
            .update({"typing": true});
      } else
        firestoreDatabase
            .collection("pods")
            .doc(chatPartnerOrPodID)
            .collection("members")
            .doc(myFirebaseUserId)
            .update({"typing": false});
    } else {
      if (_amCurrentlyTyping.value == true) {
        firestoreDatabase.collection("dm-presence").doc(myFirebaseUserId).set({"typingMessageTo": chatPartnerOrPodID});
      } else {
        firestoreDatabase.collection("dm-presence").doc(myFirebaseUserId).set({"typingMessageTo": ""});
      }
    }
  }

  /// Insert or remove items with animation
  void _updateAnimatedList({required List<ChatMessage> newList}) {
    // Compute the difference between the new list and the old list and insert the new items into the animated
    // list.
    final dynamicDifferences = newList.difference(betweenOtherList: displayedChatLog);

    var differences = List<ChatMessage>.from(dynamicDifferences);
    // That way, we can loop through the list and add each message sequentially, and it will work out that the oldest
    // message we be at the start of the list.

    // For each differences, insert or remove items
    differences.forEach((difference) {
      final bool newMessageAdded = newList.contains(difference) && !displayedChatLog.contains(difference);
      final bool newMessageRemoved = !newList.contains(difference) && displayedChatLog.contains(difference);

      // if a new message was added, insert it at the end
      if (newMessageAdded) {
        displayedChatLog.insert(0, difference);
        displayedChatLog.sort((b, a) => a.timeStamp.compareTo(b.timeStamp));
        _listKey.currentState?.insertItem(0);
      }

      if (newMessageRemoved) {
        displayedChatLog.sort((b, a) => a.timeStamp.compareTo(b.timeStamp));
        final index = displayedChatLog.indexWhere((element) => element == difference);
        _listKey.currentState?.removeItem(
            index,
            (context, animation) => MessagingRow(
                  messageId: difference.id,
                  messageText: difference.text,
                  senderId: difference.senderId,
                  senderThumbnailURL: difference.senderThumbnailURL,
                  timeStamp: difference.timeStamp,
                  isPodMode: isPodMode,
                  chatPartnerOrPodName: difference.chatPartnerName,
                  chatPartnerOrPodID: difference.chatPartnerId,
                ));
        displayedChatLog.removeWhere((element) => element == difference);
        Slidable.of(context)?.dismiss(); // dismiss Slidable objects; otherwise I'll run into the issue of opening
        // another message's slidable after the current message is deleted.
      }
    });
  }

  /// Show an alert asking the user to confirm that they want to delete a message from the conversation
  void _deleteMessage({required ChatMessage message}) {
    final alert = CupertinoAlertDialog(
      title: Text("Delete Message"),
      content: Text(message.podID == null
          ? "Are you "
              "sure you want to delete this message? It will be removed for $chatPartnerOrPodName as well!"
          : "Are you "
              "sure you want to delete this message? It will be removed for all members of ${message.podName} as well!"),
      actions: [
        // cancel button
        CupertinoButton(
            child: Text("No"),
            onPressed: () {
              dismissAlert(context: context);
            }),

        // delete button
        CupertinoButton(
            child: Text(
              "Yes",
              style: TextStyle(color: CupertinoColors.destructiveRed),
            ),
            onPressed: () {
              dismissAlert(context: context);

              // the message is a pod message if the pod ID exists and is not empty
              final isPodMessage = message.podID != null && (message.podID?.isNotEmpty ?? false);

              // delete a DM
              if (!isPodMessage) {
                final conversationDocumentReference =
                    firestoreDatabase.collection("dm-conversations").doc(conversationID);
                conversationDocumentReference.collection("messages").doc(message.id).delete().then((value) {
                  // If the conversation has no messages, then also delete the parent document
                  final wasConversationDeleted =
                      MessagesDictionary.shared.directMessagesDict.value[chatPartnerOrPodID]?.isEmpty ?? false;
                  if (wasConversationDeleted) conversationDocumentReference.delete();
                });

                // also delete the message's associated image and audio, if applicable
                if (message.imageURL != null) firebaseStorage.refFromURL(message.imageURL!).delete();
                if (message.audioURL != null) firebaseStorage.refFromURL(message.audioURL!).delete();
              }

              // delete a pod message
              else {
                final podID = message.podID;
                if (podID == null) return;
                PodsDatabasePaths(podID: podID).podDocument.collection("messages").doc(message.id).delete();

                // also delete the message's associated image and audio, if applicable
                if (message.imageURL != null) firebaseStorage.refFromURL(message.imageURL!).delete();
                if (message.audioURL != null) firebaseStorage.refFromURL(message.audioURL!).delete();
              }
            })
      ],
    );
    showCupertinoDialog(context: context, builder: (context) => alert);
  }

  /// Send a message
  Future<void> _sendMessage({required ChatMessage messageToSend}) async {
    setState(() {
      this._sendingInProgress = true; // disable the Send button while uploading is in progress to ensure
      // double-sending doesn't happen
    });

    var message = messageToSend; // make a copy of the input so it can be modified with an image or audio URL, if
    // necessary
    final messageText = message.text.trim();
    if (messageText.isEmpty && imageFile != null && isRecordingAudio)
      message.text = "Image and Voice "
          "Message";
    else if (messageText.isEmpty && imageFile != null)
      message.text = "Image";
    else if (messageText.isEmpty && isRecordingAudio) message.text = "Voice Message";
    final meetsPodMembershipsRequirements = isPodMode && _amMemberOfPod || !isPodMode;
    final canSendMessage =
        message.text.isNotEmpty && !_amIBlocked && !_didIBlockThem && meetsPodMembershipsRequirements;

    // Show a warning if I'm blocked by the person or pod
    if (_amIBlocked) {
      final alert = CupertinoAlertDialog(
        title: Text("Sending Failed"),
        content: Text("$chatPartnerOrPodName "
            "blocked you."),
        actions: [
          CupertinoButton(
              child: Text("OK"),
              onPressed: () {
                dismissAlert(context: context);
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => alert);
    }

    // Show a warning if I blocked the other person (only applicable in DM mode)
    else if (_didIBlockThem) {
      final alert = CupertinoAlertDialog(
        title: Text("Sending Failed"),
        content: Text("You blocked "
            "$chatPartnerOrPodName."),
        actions: [
          CupertinoButton(
              child: Text("OK"),
              onPressed: () {
                dismissAlert(context: context);
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => alert);
    }

    // Show a warning if I'm not a member of the pod (only applicable in pod mode)
    else if (!meetsPodMembershipsRequirements)
      showSingleButtonAlert(
          context: context,
          title: "Sending Failed",
          content: "You must be a member of $chatPartnerOrPodName to send a message.",
          dismissButtonLabel: "OK");

    // don't proceed if the message is empty or if I blocked the other person or they blocked me
    if (!canSendMessage) {
      setState(() {
        _sendingInProgress = false; // sending is no longer in progress (the message is sent)
      });
      return;
    }

    final isDM = !isPodMode; // determine whether this is a direct message or pod message

    // A message has an image if the user has picked one
    final messageHasImage = imageFile != null;

    // message has audio if the recorder is open
    final messageHasAudio = this.isRecordingAudio;

    if (messageHasImage) {
      // Wait for the image to upload, then get a list of [downloadURL, imagePathInStorage]
      final List<String>? messageImageURLAndPath = await ResizeAndUploadImage.sharedInstance
          .uploadMessagingImage(image: this.imageFile!, chatPartnerOrPodID: chatPartnerOrPodID, isPodMessage: !isDM)
          .catchError((error) {
        print("Unable to upload message image: $error");
        setState(() {
          _sendingInProgress = false; // sending is no longer in progress (the message is sent)
        });
      });
      if (messageImageURLAndPath != null) {
        message.imageURL = messageImageURLAndPath.first;
        message.imagePath = messageImageURLAndPath.last;
      }
    }

    if (messageHasAudio) {
      final recordingFile = AudioRecording.shared.recordingFile;
      if (recordingFile != null) {
        final List<String>? messageAudioURLAndPath = await UploadAudio.shared
            .uploadRecordingToDatabase(
                recordingFile: recordingFile, chatPartnerOrPodID: chatPartnerOrPodID, isPodMessage: !isDM)
            .catchError((error) {
          print("Unable to upload message audio: $error");
          setState(() {
            _sendingInProgress = false; // sending is no longer in progress (the message is sent)
          });
        });
        if (messageAudioURLAndPath != null) {
          message.audioURL = messageAudioURLAndPath.first;
          message.audioPath = messageAudioURLAndPath.last;
        }
      }
    }

    final messageToUpload = ChatMessage(
        id: message.id,
        recipientId: message.recipientId,
        recipientName: message.recipientName,
        senderId: message.senderId,
        senderName: message.senderName,
        timeStamp: message.timeStamp,
        text: message.text,
        senderThumbnailURL: message.senderThumbnailURL,
        recipientThumbnailURL: message.recipientThumbnailURL,
        imageURL: message.imageURL,
        imagePath: message.imagePath,
        audioURL: message.audioURL,
        audioPath: message.audioPath,
        podID: isPodMode ? chatPartnerOrPodID : null);

    // If we're sending a direct message, upload it to the right place and put in the right settings
    if (isDM) {
      final conversationRef =
          firestoreDatabase.collection("dm-conversations").doc(conversationID).collection("messages");

      // If I'm starting a new conversation, I will need to create a document with the following structure: {user1ID:
      // {didHideChat: false}, user2ID: {didHideChat: false}, participants: {user1ID, user2ID}}
      final user1ID = chatPartnerOrPodID < myFirebaseUserId ? chatPartnerOrPodID : myFirebaseUserId;
      final user2ID = chatPartnerOrPodID < myFirebaseUserId ? myFirebaseUserId : chatPartnerOrPodID;
      final messagesList = MessagesDictionary.shared.directMessagesDict.value[chatPartnerOrPodID] ?? [];
      if (messagesList.isEmpty)
        firestoreDatabase.collection("dm-conversations").doc(conversationID).set({
          user1ID: {"didHideChat": false},
          user2ID: {"didHideChat": false},
          "participants": [user1ID, user2ID]
        });
      _uploadMessage(message: messageToUpload, conversationRef: conversationRef);
    }

    // If we're sending a pod message, upload it to the right place and put in the right settings
    else {
      final conversationRef = PodsDatabasePaths(podID: chatPartnerOrPodID).podDocument.collection("messages");
      _uploadMessage(message: messageToUpload, conversationRef: conversationRef);
    }
  }

  /// Uploads a message to the database. Called as part of sendMessage().
  void _uploadMessage({required ChatMessage message, required CollectionReference conversationRef}) {
    final isDM = message.podID == null;

    // upload a direct message to the database and send the chat partner a push notification
    Map<String, dynamic> dmMessageDictionary = {
      "id": message.id,
      "recipientId": message.recipientId,
      "senderId": message.senderId,
      "systemTime": message.timeStamp,
      "text": message.text
    };
    dmMessageDictionary["readBy"] = [myFirebaseUserId];
    dmMessageDictionary["readTime"] = {myFirebaseUserId: message.timeStamp};
    dmMessageDictionary["readName"] = {myFirebaseUserId: MyProfileTabBackendFunctions.shared.myProfileData.value.name};
    dmMessageDictionary["senderName"] = MyProfileTabBackendFunctions.shared.myProfileData.value.name;
    dmMessageDictionary["recipientName"] = chatPartnerOrPodName;
    dmMessageDictionary["senderThumbnailURL"] = MyProfileTabBackendFunctions.shared.myProfileData.value.thumbnailURL;
    dmMessageDictionary["recipientThumbnailURL"] = _chatPartnerProfileData?.thumbnailURL ?? chatPartnerThumbnailURL;

    if (message.audioURL != null) {
      dmMessageDictionary["audioURL"] = message.audioURL;
      dmMessageDictionary["audioPath"] = message.audioPath;
    }
    if (message.imageURL != null) {
      dmMessageDictionary["imageURL"] = message.imageURL;
      dmMessageDictionary["imagePath"] = message.imagePath;
    }

    conversationRef.doc(message.id).set(dmMessageDictionary).then((value) {
      // clear the text field, image, and audio (that might have been attached with the message)
      setState(() {
        _typingMessageController.clear();
        isRecordingAudio = false;
        imageFile = null;
        _sendingInProgress = false; // sending is no longer in progress (the message is sent)
      });

      // Use this to send a push notification
      final pushSender = PushNotificationSender();
      final myName = MyProfileTabBackendFunctions.shared.myProfileData.value.name;

      // Do the following if I just sent a direct message
      if (isDM) {
        final documentID = chatPartnerOrPodID < myFirebaseUserId
            ? chatPartnerOrPodID + myFirebaseUserId
            : myFirebaseUserId + chatPartnerOrPodID;

        // Un-hide the conversation for both me and my chat partner when a new message is sent
        if (didIHideTheConversation || didChatPartnerHideTheConversation)
          firestoreDatabase
              .collection("dm-conversations")
              .doc(documentID)
              .update({"$myFirebaseUserId.didHideChat": false, "$chatPartnerOrPodID.didHideChat": false});

        final tokens = _chatPartnerProfileData?.fcmTokens;
        if (tokens != null)
        pushSender.sendPushNotification(
            recipientDeviceTokens: tokens,
            title: "New message from $myName",
            body: message.text,
            notificationType: NotificationTypes.message);
      }

      // Send every active member a push notification if I just sent a pod message
      else {
        this._podActiveMemberIDsMap.forEach((memberID, memberTokens) {
          pushSender.sendPushNotification(
              recipientDeviceTokens: memberTokens,
              title: chatPartnerOrPodName,
              body: "$myName: "
                  "${message.text}",
              notificationType: NotificationTypes.podMessage,
              podID: chatPartnerOrPodID,
              podName: chatPartnerOrPodName);
        });
      }
    }).catchError((error) {
      final alert = CupertinoAlertDialog(
        title: Text("Sending Failed"),
        content: Text("Check your internet "
            "connection and try again."),
        actions: [
          CupertinoButton(
              child: Text("OK"),
              onPressed: () {
                dismissAlert(context: context);
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => alert);
      print("Message failed to send: $error");

      setState(() {
        _sendingInProgress = false; // sending is no longer in progress (the message is sent)
      });
    });
  }

  /// Pick an image from the gallery
  void _pickImage({required ImageSource source}) async {
    final pickedImage = await _imagePicker.pickImage(source: source);
    if (pickedImage == null) return;
    await _cropImage(sourcePath: pickedImage.path);
  }

  /// Allow the user to select a square crop from their image. Assigns the imageFile variable to the image that the
  /// user picked and cropped.
  Future _cropImage({required String sourcePath}) async {
    File? croppedImage = await ImageCropper.cropImage(
        sourcePath: sourcePath,
        aspectRatioPresets: [CropAspectRatioPreset.original, CropAspectRatioPreset.square],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: "Crop Image", initAspectRatio: CropAspectRatioPreset.original, lockAspectRatio: true),
        iosUiSettings: IOSUiSettings(minimumAspectRatio: 1.0, title: "Crop Image"));
    setState(() {
      this.imageFile = croppedImage;
    });
  }

  /// Record audio
  void _recordAudio() {
    setState(() {
      this.isRecordingAudio = true;
    });
  }

  /// If this is displaying a DM conversation, then continuously observe whether either myself or my chat partner hid
  /// the conversation so that I know to un-hide it if I send a message
  void _observeWhetherWeHidTheConversation() {
    if (isPodMode) return;
    final streamSubscription =
        firestoreDatabase.collection("dm-conversations").doc(conversationID).snapshots().listen((docSnapshot) {
      final theirConversationHiddenValue = docSnapshot.get(chatPartnerOrPodID);
      final didTheyHideTheChat = theirConversationHiddenValue["didHideChat"] as bool;
      this.didChatPartnerHideTheConversation = didTheyHideTheChat;

      final myConversationHiddenValue = docSnapshot.get(myFirebaseUserId);
      final didIHideTheConversation = myConversationHiddenValue["didHideChat"] as bool;
      this.didIHideTheConversation = didIHideTheConversation;
    });
    this._streamSubscriptions.add(streamSubscription);
  }

  /// If this is displaying a pod messaging conversation, then get the IDs for active pod members so I can send them
  /// a push notification when I sent a new message
  void _getActivePodMemberIDs() {
    if (!isPodMode) return; // don't execute if this isn't showing a pod message conversation
    final streamSubscription = PodsDatabasePaths(podID: chatPartnerOrPodID)
        .podDocument
        .collection("members")
        .where("blocked", isEqualTo: false)
        .where("active", isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final Map<String, List<String>> activeMemberIDsMap = {};
      snapshot.docs.forEach((member) {
        final memberData = member.data();
        final memberID = member.get("userID") as String;
        final memberTokensRaw = memberData["fcmTokens"] as List<dynamic>? ?? [];
        final memberTokens = List<String>.from(memberTokensRaw);
        if (!activeMemberIDsMap.keys.contains(memberID)) activeMemberIDsMap[memberID] = memberTokens;
      });
      this._podActiveMemberIDsMap = activeMemberIDsMap;
    });
    this._streamSubscriptions.add(streamSubscription);
  }

  /// If this is pod mode, then check which pod members are currently typing
  void _observeWhichPodMembersAreTyping() {
    if (!isPodMode) return; // ignore this function if not in pod mode
    final memberTypingListener = firestoreDatabase
        .collection("pods")
        .doc(chatPartnerOrPodID)
        .collection("members")
        .where("typing", isEqualTo: true)
        .where("userID", isNotEqualTo: myFirebaseUserId)
        .snapshots()
        .listen((event) {
      event.docChanges.forEach((diff) {
        final memberID = diff.doc.id;
        final memberName = diff.doc.get("name") as String;

        // declare that the person is typing
        if (diff.type == DocumentChangeType.added) {
          setState(() {
            this._podMemberTypingMessageDictionary[memberID] =
                PodMemberIDNameAndTypingStatus(memberID: memberID, name: memberName, isTyping: true);
          });
        }

        // declare that the person is not typing
        else if (diff.type == DocumentChangeType.removed) {
          setState(() {
            this._podMemberTypingMessageDictionary[memberID] =
                PodMemberIDNameAndTypingStatus(memberID: memberID, name: memberName, isTyping: false);
          });
        }
      });
    });
    _streamSubscriptions.add(memberTypingListener);
  }

  /// If this is a DM conversation, then check whether the chat partner is typing a message to me.
  void _checkIfMyChatPartnerIsTypingAMessage() {
    if (isPodMode) return; // no need to do this if in pod mode
    final chatPartnerTypingListener =
        firestoreDatabase.collection("dm-presence").doc(chatPartnerOrPodID).snapshots().listen((document) {
      if (document.exists) {
        final personTheyAreTypingAMessageTo = document.get("typingMessageTo") as String?;
        if (personTheyAreTypingAMessageTo != null) {
          final isTypingToMe = personTheyAreTypingAMessageTo == myFirebaseUserId;
          setState(() {
            this._chatPartnerTyping = isTypingToMe;
          });
        }
      }
    });
    _streamSubscriptions.add(chatPartnerTypingListener);
  }

  /// Determine whether to show the typing message and read receipts row
  bool get showReadReceiptsRow {
    if (displayedChatLog.length == 0 || _didScrollToHideReadReceipts) return false;
    // determines whether anyone besides myself read the newest message in the conversation
    final newestMessageWasSentByMeAndReadBySomeoneElse =
        (displayedChatLog.first.readBy?.length ?? 1) > 1 && displayedChatLog.first.senderId == myFirebaseUserId;

    // determines whether anyone is typing a message
    final someoneBesidesMyselfIsTyping =
        (isPodMode && _podMemberTypingMessageDictionary.values.where((member) => member.isTyping).length > 0) ||
            (!isPodMode && _chatPartnerTyping);

    // show the row if either someone is typing or the newest message in the chat log was read by someone other than
    // myself and I was the sender
    return newestMessageWasSentByMeAndReadBySomeoneElse || someoneBesidesMyselfIsTyping;
  }

  /// Load in older messages if the user pulls to refresh
  Future<void> _loadOlderMessages() async {
    int numMessagesLoaded = 0; // use this to determine whether to display that the chat log is up to date
    if (!isPodMode)
      numMessagesLoaded = await MessagesDictionary.shared
          .loadOlderDMMessagesIfNecessary(chatPartnerID: chatPartnerOrPodID, conversationID: conversationID);
    else
      numMessagesLoaded = await MessagesDictionary.shared.loadOlderPodMessagesIfNecessary(podID: chatPartnerOrPodID);
    _refreshController.loadComplete(); // mark the task as complete to hide the refresher
    setState(() {
      this._noMoreMessagesToLoad = numMessagesLoaded == 0; // there are no more messages to load if the latest refresh
      // returned
      // no older messages
    });
  }

  /// Scroll the chat log to the newest message
  void _scrollChatLogToBottom({int milliseconds = 250}) {
    // scroll a little past max extents to ensure the bottom message comes fully into view
    _chatLogScrollController.animateTo(0, duration: Duration(milliseconds: milliseconds), curve: Curves.ease);
  }

  /// Checks if I'm blocked, or if I blocked my chat partner (DM messaging only)
  void _checkIfIAmBlocked() {
    // check if I'm blocked from the pod
    if (isPodMode) {
      final subscription = firestoreDatabase
          .collection("pods")
          .doc(chatPartnerOrPodID)
          .collection("members")
          .where("userID", isEqualTo: myFirebaseUserId)
          .where("blocked", isEqualTo: true)
          .snapshots()
          .listen((event) {
        setState(() {
          this._amIBlocked = event.docs.length > 0; // I'm blocked from the pod if this query returns any documents
        });

        // don't show an alert if I'm blocked, because if I'm blocked then I'm also no longer a member, so I'll let
        // that alert take precedence. We don't want to get stuck showing two alerts by accident.
      });
      _streamSubscriptions.add(subscription);
    }

    // Check if my chat partner blocked me, or if I blocked them.
    else {
      /// Must directly read in the people I blocked, because listeners do not automatically get notified
      /// when a widget appears - a change must occur while the widget is open in order for it to get notified.
      final peopleIBlocked = SentBlocksBackendFunctions.shared.sortedListOfPeople.value;
      this._didIBlockThem = peopleIBlocked.memberIDs().contains(chatPartnerOrPodID);
      SentBlocksBackendFunctions.shared.sortedListOfPeople.addListener(() {
        final peopleIBlocked = SentBlocksBackendFunctions.shared.sortedListOfPeople.value;
        setState(() {
          this._didIBlockThem = peopleIBlocked.memberIDs().contains(chatPartnerOrPodID);
        });
      });

      /// Must directly read in the people who blocked me, because listeners do not automatically get
      /// notified when a widget appears - a change must occur while the widget is open in order for it to get
      /// notified.
      final peopleWhoBlockedMe = ReceivedBlocksBackendFunctions.shared.sortedListOfPeople.value;
      this._amIBlocked = peopleWhoBlockedMe.memberIDs().contains(chatPartnerOrPodID);
      ReceivedBlocksBackendFunctions.shared.sortedListOfPeople.addListener(() {
        final peopleWhoBlockedMe = ReceivedBlocksBackendFunctions.shared.sortedListOfPeople.value;
        setState(() {
          this._amIBlocked = peopleWhoBlockedMe.memberIDs().contains(chatPartnerOrPodID);
        });
        if (this._amIBlocked)
          showSingleButtonAlert(
              context: context,
              title: "Permission Denied",
              content: "$chatPartnerOrPodName "
                  "blocked you.",
              dismissButtonLabel: "OK")
              .then((value) {
            Navigator.of(context, rootNavigator: true).pop(); // go back
          });
      });
    }
  }

  /// Checks if I'm a member of the pod
  void _checkIfImAMemberOfThePod() {
    if (!isPodMode) return; // no need if not in pod mode
    final listener = PodsDatabasePaths(podID: chatPartnerOrPodID)
        .podDocument
        .collection("members")
        .where("userID", isEqualTo: myFirebaseUserId)
        .where("blocked", isEqualTo: false)
        .snapshots()
        .listen((event) {
      final amMemberOfPod = event.docs.length == 1; // I'm a member if there's a document with my ID, and I'm not
      // blocked
      setState(() {
        this._amMemberOfPod = amMemberOfPod;
      });

      if (!_amMemberOfPod)
        showSingleButtonAlert(
                context: context,
                title: "Permission Denied",
                content: "You must be a member of $chatPartnerOrPodName to send a message.",
                dismissButtonLabel: "OK")
            .then((value) {
          Navigator.of(context, rootNavigator: true).pop(); // go back
        });
    });
    _streamSubscriptions.add(listener);
  }

  /// Block or unblock the chat partner (only applicable in DM mode, not pod mode)
  void _blockOrUnblockChatPartner() {
    // if I haven't yet blocked them, show the option to block them
    if (!_didIBlockThem) {
      final blockThemAlert = CupertinoAlertDialog(
        title: Text("Block $chatPartnerOrPodName"),
        content: Text("Are you sure you "
            "want to proceed?"),
        actions: [
          // cancel button
          CupertinoButton(
              child: Text("No"),
              onPressed: () {
                dismissAlert(context: context);
              }),

          // block button
          CupertinoButton(
              child: Text(
                "Yes",
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
              onPressed: () {
                dismissAlert(context: context); // dismiss the first alert, then show a success alert
                BlockedUsersDatabasePaths.blockUser(
                    otherPersonsUserID: chatPartnerOrPodID,
                    onCompletion: () {
                      final success = CupertinoAlertDialog(
                        title: Text("$chatPartnerOrPodName Blocked"),
                        actions: [
                          CupertinoButton(
                              child: Text("OK"),
                              onPressed: () {
                                dismissAlert(context: context);
                              })
                        ],
                      );
                      showCupertinoDialog(context: context, builder: (context) => success); // show the success alert
                    });
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => blockThemAlert);
    }

    // if I've already blocked them, show the option to unblock them
    else {
      final unblockThemAlert = CupertinoAlertDialog(
        title: Text("Unblock $chatPartnerOrPodName"),
        content: Text("Are "
            "you sure you want to proceed?"),
        actions: [
          // cancel button
          CupertinoButton(
              child: Text("No"),
              onPressed: () {
                dismissAlert(context: context);
              }),

          // unblock button
          CupertinoButton(
              child: Text(
                "Yes",
              ),
              onPressed: () {
                dismissAlert(context: context); // dismiss the first alert, then show a success alert
                BlockedUsersDatabasePaths.unBlockUser(
                    otherPersonsUserID: chatPartnerOrPodID,
                    onCompletion: () {
                      final success = CupertinoAlertDialog(
                        title: Text("$chatPartnerOrPodName Unblocked"),
                        actions: [
                          CupertinoButton(
                              child: Text("OK"),
                              onPressed: () {
                                dismissAlert(context: context);
                              })
                        ],
                      );
                      showCupertinoDialog(context: context, builder: (context) => success); // show the success alert
                    });
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => unblockThemAlert);
    }
  }

  /// Mark a message as read if I haven't read it yet
  void _markMessageReadIfNecessary({required ChatMessage message}) {
    // if in doubt, assume that I have read the message to reduce database writes
    if (!(message.readBy?.contains(myFirebaseUserId) ?? true)) {
      message.markMessageRead(
          message: message,
          listOfPeopleWhoReadTheMessage: message.readBy ?? [],
          conversationID: isPodMode ? chatPartnerOrPodID : conversationID);
    }
  }

  @override
  void initState() {
    super.initState();

    var dms = MessagesDictionary.shared.directMessagesDict.value[chatPartnerOrPodID] ?? [];
    var podMessages = MessagesDictionary.shared.podMessageDict.value[chatPartnerOrPodID] ?? [];
    var combined = dms + podMessages;
    combined = combined.toSet().toList(); // remove duplicates
    combined.sort((b, a) => a.timeStamp.compareTo(b.timeStamp));

    if (isPodMode)
      this._getActivePodMemberIDs();
    else
      this._observeWhetherWeHidTheConversation();

    setState(() {
      displayedChatLog = combined;
    });

    _checkIfIAmBlocked();
    if (isPodMode) _checkIfImAMemberOfThePod();

    // Update in real time when the chat log changes (for direct messages)
    MessagesDictionary.shared.directMessagesDict.addListener(() {
      if (!this.mounted) return; // avoid setting state if the widget is disposed
      setState(() {
        var dms = MessagesDictionary.shared.directMessagesDict.value[chatPartnerOrPodID] ?? [];
        var podMessages = MessagesDictionary.shared.podMessageDict.value[chatPartnerOrPodID] ?? [];
        var combined = dms + podMessages;
        combined = combined.toSet().toList(); // remove duplicates
        combined.sort((b, a) => a.timeStamp.compareTo(b.timeStamp));

        _updateAnimatedList(newList: combined);
      });
    });

    // Update in real time when the chat log changes (for pod messages)
    MessagesDictionary.shared.podMessageDict.addListener(() {
      if (!this.mounted) return;
      setState(() {
        var dms = MessagesDictionary.shared.directMessagesDict.value[chatPartnerOrPodID] ?? [];
        var podMessages = MessagesDictionary.shared.podMessageDict.value[chatPartnerOrPodID] ?? [];
        var combined = dms + podMessages;
        combined = combined.toSet().toList(); // remove duplicates
        combined.sort((b, a) => a.timeStamp.compareTo(b.timeStamp));
        _updateAnimatedList(newList: combined);
      });
    });

    // handle the text field when the keyboard appears
    // Scroll the chat log to the bottom when the keyboard opens
    final keyboardVisibilityListener = this._keyboardVisibilityController.onChange.listen((bool visible) {
      if (visible) {
        this._scrollChatLogToBottom(); // scroll to the newest message when the chat log opens

        /// Ensure proper scrolling if the keyboard opens while recording audio and previewing an image
        if (imageFile != null && isRecordingAudio)
          _imageAndAudioScrollController.animateTo(200, duration: Duration(milliseconds: 250), curve: Curves.ease);
      }

      setState(() {
        this._keyboardVisible = visible;
      });
    });
    _streamSubscriptions.add(keyboardVisibilityListener);

    // Hide the keyboard if the user scrolls up to see older messages. Also hide the read receipts row (if it isn't
    // already hidden from previous scrolling)
    _chatLogScrollController.addListener(() {
      final isScrolling = _chatLogScrollController.position.isScrollingNotifier.value;
      final scrollDirection = _chatLogScrollController.position.userScrollDirection;
      if (isScrolling && scrollDirection == ScrollDirection.reverse) {
        if (_keyboardVisible) hideKeyboard(context: context);
        if (!this._didScrollToHideReadReceipts)
          setState(() {
            this._didScrollToHideReadReceipts = true;
          });
      }

      // if the user scrolls all the way back down to the bottom of the chat log, allow the read receipts row to
      // show again. Set extentBefore (not extentAfter) to 0 because the chat log CustomScrollView is reversed.
      if (_chatLogScrollController.position.extentBefore == 0) {
        setState(() {
          this._didScrollToHideReadReceipts = false;
        });
      }
    });

    // listen for which pod members are typing, if necessary
    if (isPodMode)
      this._observeWhichPodMembersAreTyping();

    // check whether my chat partner is typing a message, if necessary
    else
      this._checkIfMyChatPartnerIsTypingAMessage();

    // listen to whether I'm typing a message to update _amCurrentlyTyping
    _typingMessageController.addListener(() {
      final amTyping = _typingMessageController.text.trim().isNotEmpty;
      this._amCurrentlyTyping.value = amTyping;
    });

    // update the database with information on whether I'm typing a message so that typing presence works for others.
    // This will be called every time I go from typing to not typing (i.e. text field goes from blank to not blank or
    // vice verse)
    this._amCurrentlyTyping.addListener(() {
      this._updateTypingStatusInDatabase();
    });

    // Get the chat partner's data so I can have their tokens to send a push notification when I send a message
    if (!isPodMode) this._getChatPartnerProfileData();
  }

  @override
  void dispose() {
    MessagesDictionary.shared.directMessagesDict.removeListener(() {});
    MessagesDictionary.shared.podMessageDict.removeListener(() {});
    _chatLogScrollController.removeListener(() {});
    _streamSubscriptions.forEach((subscription) => subscription.cancel());

    SentBlocksBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    ReceivedBlocksBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    this._amCurrentlyTyping.removeListener(() {});
    this._typingMessageController.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        padding: EdgeInsetsDirectional.all(5),
        middle: Text("Message $chatPartnerOrPodName"),
        trailing: isPodMode
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.arrow_turn_up_right),
                onPressed: () {
                  // navigate to ViewPodDetails
                  Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                      builder: (context) => ViewPodDetails(
                            podID: chatPartnerOrPodID,
                            showChatButton: false,
                          ))); // if navigating from messaging, there is no need
                  // to show the Chat button, since that would allow the user to navigate into an infinite stack
                },
              )
            : CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.line_horizontal_3),
                onPressed: () {
                  // show an action sheet with the option to block or unblock the user. There will also be a help button once
                  // I create the tutorial sheets at the end
                  final sheet = CupertinoActionSheet(
                    actions: [
                      // block or unblock button. Button is destructive if the option is to block, meaning that if I haven't
                      // blocked them, the button should be red so I don't accidentally block them.
                      CupertinoActionSheetAction(
                        onPressed: () {
                          dismissAlert(context: context); // dismiss the action sheet
                          _blockOrUnblockChatPartner();
                        },
                        child: Text(_didIBlockThem
                            ? "Unblock "
                                "${chatPartnerOrPodName.split(" ").first}"
                            : "Block ${chatPartnerOrPodName.split(" ").first}"),
                        isDestructiveAction: !_didIBlockThem,
                      ),

                      // cancel button
                      CupertinoActionSheetAction(
                        onPressed: () {
                          dismissAlert(context: context);
                        },
                        child: Text("Cancel"),
                        isDefaultAction: true,
                      )
                    ],
                  );
                  showCupertinoModalPopup(context: context, builder: (context) => sheet);
                },
              ),
      ),
      child: KeyboardDismissOnTap(
          child: SafeArea(
        child: Column(
          children: [
            // Stack allows drawing an image preview over the chat log if an image is attached
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Show a message in the center if the conversation is empty
                  if (displayedChatLog.isEmpty)
                    Center(
                      child: Text(
                        "Start a conversation with "
                        "$chatPartnerOrPodName!",
                        style: TextStyle(color: CupertinoColors.inactiveGray),
                      ),
                    ),

                  // Chat log
                  Localizations(
                    locale: Locale('en', 'US'),
                    delegates: [DefaultWidgetsLocalizations.delegate, DefaultMaterialLocalizations.delegate],

                    // reverse the pull down/pull up since the list is reversed
                    child: SmartRefresher(
                      enablePullDown: false,
                      enablePullUp: true,

                      // if we have additional messages to load, use the classic footer. Otherwise, just display a
                      // message saying that all messages are loaded.
                      footer: _noMoreMessagesToLoad
                          ? CustomFooter(
                              builder: (BuildContext context, LoadStatus? mode) {
                                // Yes, I know this could all be simplified to just Container(width:0, height: 0). I'm
                                // keeping the code for future reference though in case I want to change it.
                                Widget body;
                                if (mode == LoadStatus.idle) {
                                  // when you over scroll but don't intend to load more messages
                                  body = Text("All Messages Loaded!",
                                      style: TextStyle(color: CupertinoColors.inactiveGray));
                                } else if (mode == LoadStatus.loading) {
                                  // when messages are actively loading
                                  body = Text("All Messages Loaded!",
                                      style: TextStyle(color: CupertinoColors.inactiveGray));
                                } else if (mode == LoadStatus.failed) {
                                  // if loading fails
                                  body = Text("All Messages Loaded!",
                                      style: TextStyle(color: CupertinoColors.inactiveGray));
                                } else if (mode == LoadStatus.canLoading) {
                                  // when you drag down to load more messages and are about to release to load them
                                  body = Text("All Messages Loaded!",
                                      style: TextStyle(color: CupertinoColors.inactiveGray));
                                } else {
                                  body = Text("All Messages Loaded!",
                                      style: TextStyle(color: CupertinoColors.inactiveGray));
                                }
                                return Container(
                                  height: 55.0,
                                  child: Center(child: body),
                                );
                              },
                            )
                          : ClassicFooter(),
                      controller: _refreshController,
                      onLoading: _noMoreMessagesToLoad
                          ? () {
                              _refreshController.loadComplete(); // if there's nothing to load, then mark loading as
                              // complete
                            }
                          : _loadOlderMessages,
                      child: CustomScrollView(
                        reverse: true,
                        controller: _chatLogScrollController,
                        physics: AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverAnimatedList(
                              key: _listKey,
                              initialItemCount: displayedChatLog.length,
                              itemBuilder: (context, index, animation) {
                                // index both a direct message and a pod message to ensure the list is interchangeable for both
                                // types. Must make sure the list index remains within range
                                final message = displayedChatLog.length > index ? displayedChatLog[index] : null;
                                if (message == null) return Container(); // empty container if message is null
                                final timeStamp = message.timeStamp;

                                // mark the message as read if I haven't read it yet
                                this._markMessageReadIfNecessary(message: message);

                                // Show/hide the time stamp when the row is tapped
                                return SizeTransition(
                                  sizeFactor: animation,
                                  child: Slidable(
                                    actionPane: SlidableDrawerActionPane(),
                                    actionExtentRatio: 0.17,
                                    child: MessagingRow(
                                      messageId: message.id,
                                      messageText: message.text,
                                      senderId: message.senderId,
                                      senderThumbnailURL: message.senderThumbnailURL,
                                      timeStamp: message.timeStamp,
                                      messageImageURL: message.imageURL,
                                      messageAudioURL: message.audioURL,
                                      chatPartnerOrPodID: message.chatPartnerId,
                                      chatPartnerOrPodName: message.chatPartnerName,
                                      isPodMode: isPodMode,
                                    ),

                                    // Actions appear on the left. Use them for received messages
                                    actions: [
                                      if (message.senderId != myFirebaseUserId)
                                        // delete the message
                                        IconSlideAction(
                                          caption: "Delete",
                                          color: CupertinoColors.destructiveRed,
                                          icon: CupertinoIcons.trash,
                                          onTap: () {
                                            _deleteMessage(message: message);
                                          },
                                        ),

                                      // copy the message
                                      if (message.senderId != myFirebaseUserId)
                                        IconSlideAction(
                                          icon: CupertinoIcons.doc_on_clipboard,
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: message.text));
                                          },
                                          caption: "Copy",
                                        ),

                                      // the message time stamp
                                      if (message.senderId != myFirebaseUserId)
                                        Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Text(
                                            TimeAndDateFunctions.timeStampText(timeStamp),
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                    ],

                                    // Secondary actions appear on the right. Use them for sent messages.
                                    secondaryActions: [
                                      // the message time stamp
                                      if (message.senderId == myFirebaseUserId)
                                        Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Text(
                                            TimeAndDateFunctions.timeStampText(timeStamp),
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),

                                      // copy the message
                                      if (message.senderId == myFirebaseUserId)
                                        IconSlideAction(
                                          icon: CupertinoIcons.doc_on_clipboard,
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: message.text));
                                          },
                                          caption: "Copy",
                                        ),

                                      if (message.senderId == myFirebaseUserId)
                                        // delete the message
                                        IconSlideAction(
                                          icon: CupertinoIcons.trash,
                                          onTap: () {
                                            _deleteMessage(message: message);
                                          },
                                          caption: "Delete",
                                          color: CupertinoColors.destructiveRed,
                                        ),
                                    ],
                                  ),
                                );
                              })
                        ],
                      ),
                    ),
                  ),

                  if (imageFile != null || isRecordingAudio)
                    BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                        child: Container(color: CupertinoColors.black.withOpacity(0.1))),

                  // Image preview and audio recorder
                  SingleChildScrollView(
                    controller: _imageAndAudioScrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // image preview
                        if (imageFile != null)
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // clear image button
                                CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: Icon(
                                      CupertinoIcons.xmark_circle_fill,
                                      color: CupertinoColors.darkBackgroundGray,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        this.imageFile = null;
                                      });
                                    }),

                                Padding(
                                  padding: EdgeInsets.only(right: 20),
                                  child: Image.file(
                                    imageFile!,
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              ],
                            ),
                          ),

                        // audio recorder
                        if (isRecordingAudio)
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // clear audio recorder button
                                CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: Icon(
                                      CupertinoIcons.xmark_circle_fill,
                                      color: CupertinoColors.darkBackgroundGray,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        this.isRecordingAudio = false;
                                      });
                                    }),

                                // audio recorder
                                Card(
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: 250),
                                      child: AudioRecorder(),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                      ],
                    ),
                  ),

                  // If the message has an image or audio, it may take a few seconds to send. In that case, show a toast informing
                  // the user that the message is sending, so that they don't think the app froze.
                  if ((imageFile != null || isRecordingAudio) && _sendingInProgress)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                            child: Container(color: CupertinoColors.white.withOpacity(0.5))),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(radius: 15),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Sending Message...",
                              style: TextStyle(color: CupertinoColors.inactiveGray),
                            )
                          ],
                        ),
                      ],
                    )
                ],
              ),
            ),

            // This row contains the "[PERSON] is typing..." and read receipts text
            AnimatedSwitcher(
              transitionBuilder: (child, animation) {
                return SizeTransition(sizeFactor: animation, child: child);
              },
              duration: Duration(milliseconds: 250),
              child: this.showReadReceiptsRow
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // the typing presence text ("someone is typing...")
                        AnimatedSwitcher(
                            duration: Duration(milliseconds: 250),
                            child: someoneTypingText() ==
                                    Container(
                                      width: 0,
                                      height: 0,
                                    )
                                ? Container(width: 0, height: 0)
                                : someoneTypingText()),
                        Spacer(),

                        // The message read text ("read by NAME"). Use the first message since the chat log is reversed.
                        AnimatedSwitcher(
                            duration: Duration(milliseconds: 250),
                            child: messageReadText(message: displayedChatLog.first) ==
                                    Container(
                                      width: 0,
                                      height: 0,
                                    )
                                ? Container(width: 0, height: 0)
                                : messageReadText(message: displayedChatLog.first)),
                      ],
                    )
                  : Container(
                      width: 0,
                      height: 0,
                    ),
            ),

            // Text field to type a message
            FocusDetector(
              child: CupertinoTextField(
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                controller: _typingMessageController,
                placeholder: "Message ${isPodMode ? chatPartnerOrPodName : chatPartnerOrPodName.split(" ").first}",
                prefix: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(CupertinoIcons.paperclip),
                  onPressed: () {
                    final attachmentSheet = CupertinoActionSheet(
                      title: Text("Attachment Options"),
                      actions: [
                        // take photo with camera
                        CupertinoActionSheetAction(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(CupertinoIcons.camera), SizedBox(width: 10), Text("Take Photo")],
                            ),
                            onPressed: () {
                              dismissAlert(context: context);
                              this._pickImage(source: ImageSource.camera);
                            }),

                        // pick photo from gallery
                        CupertinoActionSheetAction(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(CupertinoIcons.photo), SizedBox(width: 10), Text("Choose Photo")],
                            ),
                            onPressed: () {
                              dismissAlert(context: context);
                              this._pickImage(source: ImageSource.gallery);
                            }),

                        // record audio
                        CupertinoActionSheetAction(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(CupertinoIcons.mic), SizedBox(width: 10), Text("Voice Message")],
                            ),
                            onPressed: () {
                              dismissAlert(context: context);
                              this._recordAudio();
                            }),

                        // cancel
                        CupertinoActionSheetAction(
                          onPressed: () {
                            dismissAlert(context: context);
                          },
                          child: Text("Cancel"),
                          isDefaultAction: true,
                        )
                      ],
                    );
                    showCupertinoModalPopup(context: context, builder: (context) => attachmentSheet);
                  },
                ),
                suffix: CupertinoButton(
                    child: Icon(CupertinoIcons.paperplane),
                    onPressed: () {
                      final randomID = Uuid().v1();
                      final myName = MyProfileTabBackendFunctions.shared.myProfileData.value.name;
                      final myThumbnailURL = MyProfileTabBackendFunctions.shared.myProfileData.value.thumbnailURL;
                      final timeStamp = DateTime.now().millisecondsSinceEpoch * 0.001;
                      final text = _typingMessageController.text;
                      final messageToSend = ChatMessage(
                          id: randomID,
                          recipientId: chatPartnerOrPodID,
                          recipientName: chatPartnerOrPodName,
                          senderId: myFirebaseUserId,
                          senderName: myName,
                          timeStamp: timeStamp,
                          text: text,
                          senderThumbnailURL: myThumbnailURL,
                          recipientThumbnailURL: chatPartnerThumbnailURL ?? "",
                          podID: isPodMode ? chatPartnerOrPodID : null);
                      if (!_sendingInProgress) _sendMessage(messageToSend: messageToSend);
                    }),
              ),
            onFocusLost: (){
                // if the user stops typing (or if the app goes to the background), make sure to remove the user's
              // typing status
                this._amCurrentlyTyping.value = false;
            },),
          ],
        ),
      )),
    );
  }
}
