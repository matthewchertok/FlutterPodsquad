import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:podsquad/BackendDataclasses/ChatMessageDataclasses.dart';
import 'package:podsquad/BackendDataclasses/NotificationTypes.dart';
import 'package:podsquad/BackendFunctions/PushNotificationSender.dart';
import 'package:podsquad/BackendFunctions/ResizeAndUploadImage.dart';
import 'package:podsquad/BackendFunctions/UploadAudio.dart';
import 'package:podsquad/CommonlyUsedClasses/TimeAndDateFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/DatabasePaths/PodsDatabasePaths.dart';
import 'package:podsquad/ListRowViews/MessagingRow.dart';
import 'package:podsquad/OtherSpecialViews/AudioRecorder.dart';
import 'package:podsquad/UIBackendClasses/MessagesDictionary.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';
import 'dart:io';

import 'package:uuid/uuid.dart';

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
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  /// The image that gets picked from the photo library
  File? imageFile;

  /// Determine whether to show the audio recorder
  bool isRecordingAudio = false;

  final String chatPartnerOrPodID;
  final String chatPartnerOrPodName;
  final String? chatPartnerThumbnailURL;
  final bool isPodMode;

  /// Displays the chat log for a DM conversation
  List<ChatMessage> displayedChatLog = [];

  /// Allows us to show the time at which a message was sent by mapping {messageID: true}
  Map<String, bool> showingMessageTimeStamp = {};

  /// Check whether I'm blocked by either my chat partner (if sending a DM) or by the pod (if it's pod messaging).
  bool _amIBlocked = false;

  /// Check whether I blocked the other user
  bool _didIBlockThem = false;

  /// Use this to track whether I hid the conversation from my messaging tab
  bool didIHideTheConversation = false;

  /// Use this to track whether my chat partner hid the conversation from their messaging tab. Ignore if pod
  /// messaging.
  bool didChatPartnerHideTheConversation = false;

  /// Allows us to control the animated list
  final _listKey = GlobalKey<SliverAnimatedListState>();

  /// If this is DM mode, listen to whether my chat partner or I hid the conversation
  StreamSubscription? _conversationHiddenListener;

  /// If this is pod mode, listen for the active pod members so I can send them a push notification if I send a message
  StreamSubscription? _podActiveMembersListener;

  /// Keep track of all the pod active members and update in real time
  List<String> _podActiveMemberIDsList = [];

  /// If this is DM mode, get the conversation ID as an alphabetical combination of my user ID and my chat partner's
  /// user ID
  String get conversationID => chatPartnerOrPodID < myFirebaseUserId
      ? chatPartnerOrPodID + myFirebaseUserId
      : myFirebaseUserId + chatPartnerOrPodID;

  /// Insert or remove items with animation
  void _updateAnimatedList({required List<ChatMessage> newList}) {
    // Compute the difference between the new list and the old list and insert the new items into the animated
    // list.
    final dynamicDifferences = newList.difference(betweenOtherList: displayedChatLog);

    var differences = List<ChatMessage>.from(dynamicDifferences);
    // That way, we can loop through the list and add each message sequentially, and it will work out that the oldest
    // message we be at the start of the list.

    // Only scroll to the bottom if a new message is added.
    final shouldScrollToBottom = newList.last.timeStamp > displayedChatLog.last.timeStamp;

    // For each differences, insert or remove items
    differences.forEach((difference) {
      final bool newMessageAdded = newList.contains(difference) && !displayedChatLog.contains(difference);
      final bool newMessageRemoved = !newList.contains(difference) && displayedChatLog.contains(difference);

      // if a new message was added, insert it at the end
      if (newMessageAdded) {
        displayedChatLog.insert(0, difference);
        displayedChatLog.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
        _listKey.currentState?.insertItem(0);
      }

      if (newMessageRemoved) {
        displayedChatLog.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
        final index = displayedChatLog.indexWhere((element) => element == difference);
        _listKey.currentState?.removeItem(
            index,
            (context, animation) => MessagingRow(
                messageId: difference.id,
                messageText: difference.text,
                senderId: difference.senderId,
                senderThumbnailURL: difference.senderThumbnailURL,
                timeStamp: difference.timeStamp));
        displayedChatLog.removeWhere((element) => element == difference);
        Slidable.of(context)?.dismiss(); // dismiss Slidable objects; otherwise I'll run into the issue of opening
        // another message's slidable after the current message is deleted.
      }
    });

    if (shouldScrollToBottom) _scrollChatLogToBottom();
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
    var message = messageToSend; // make a copy of the input so it can be modified with an image or audio URL, if
    // necessary
    var messageText = message.text.trim();
    if (messageText.isEmpty && imageFile != null && message.audioURL != null)
      messageText = "Image and Voice "
          "Message";
    else if (messageText.isEmpty && imageFile != null)
      messageText = "Image";
    else if (messageText.isEmpty && message.audioURL != null) messageText = "Voice Message";
    final canSendMessage = messageText.isNotEmpty && !_amIBlocked && !_didIBlockThem;
    if (!canSendMessage) return; // don't proceed if the message is empty or if I blocked the other person or they
    // blocked me
    final isDM = message.podID == null; // determine whether this is a direct message or pod message
    if (isDM) {
      final documentID = chatPartnerOrPodID < myFirebaseUserId
          ? chatPartnerOrPodID + myFirebaseUserId
          : myFirebaseUserId + chatPartnerOrPodID;
      final conversationRef = firestoreDatabase.collection("dm-conversations").doc(documentID).collection("messages");

      // If I'm starting a new conversation, I will need to create a document with the following structure: {user1ID:
      // {didHideChat: false}, user2ID: {didHideChat: false}, participants: {user1ID, user2ID}}
      final user1ID = chatPartnerOrPodID < myFirebaseUserId ? chatPartnerOrPodID : myFirebaseUserId;
      final user2ID = chatPartnerOrPodID < myFirebaseUserId ? myFirebaseUserId : chatPartnerOrPodID;
      final messagesList = MessagesDictionary.shared.directMessagesDict.value[chatPartnerOrPodID] ?? [];
      if (messagesList.isEmpty)
        firestoreDatabase.collection("dm-conversations").doc(documentID).set({
          user1ID: {"didHideChat": false},
          user2ID: {"didHideChat": false},
          "participants": [user1ID, user2ID]
        });

      // A message has an image if the user has picked one
      final messageHasImage = imageFile != null;
      if (messageHasImage) {
        // Wait for the image to upload, then get a list of [downloadURL, imagePathInStorage]
        final List<String>? messageImageURLAndPath = await ResizeAndUploadImage.sharedInstance
            .uploadMessagingImage(image: this.imageFile!, chatPartnerOrPodID: chatPartnerOrPodID, isPodMessage: !isDM);
        if (messageImageURLAndPath != null) {
          message.imageURL = messageImageURLAndPath.first;
          message.imagePath = messageImageURLAndPath.last;
        }
      }

      // message has audio if the recorder is open
      final messageHasAudio = this.isRecordingAudio;
      if (messageHasAudio) {
        final recordingFile = AudioRecording.shared.recordingFile;
        if (recordingFile != null) {
          final List<String>? messageAudioURLAndPath = await UploadAudio.shared.uploadRecordingToDatabase(
              recordingFile: recordingFile, chatPartnerOrPodID: chatPartnerOrPodID, isPodMessage: !isDM);
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
          audioPath: message.audioPath);
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
    dmMessageDictionary["recipientThumbnailURL"] = message.recipientThumbnailURL;

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

        pushSender.sendPushNotification(
            recipientID: chatPartnerOrPodID,
            title: "New message from $myName",
            body: message.text,
            notificationType: NotificationTypes.message);
      }

      // Send every active member a push notification if I just sent a pod message
      else {
        _podActiveMemberIDsList.forEach((memberID) {
          pushSender.sendPushNotification(
              recipientID: memberID,
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
    });
  }

  /// Pick an image from the gallery
  void _pickImage({required ImageSource source}) async {
    final pickedImage = await _imagePicker.getImage(source: source);
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
    this._conversationHiddenListener =
        firestoreDatabase.collection("dm-conversations").doc(conversationID).snapshots().listen((docSnapshot) {
      final theirConversationHiddenValue = docSnapshot.get(chatPartnerOrPodID);
      final didTheyHideTheChat = theirConversationHiddenValue["didHideChat"] as bool;
      this.didChatPartnerHideTheConversation = didTheyHideTheChat;

      final myConversationHiddenValue = docSnapshot.get(myFirebaseUserId);
      final didIHideTheConversation = myConversationHiddenValue["didHideChat"] as bool;
      this.didIHideTheConversation = didIHideTheConversation;
    });
  }

  /// If this is displaying a pod messaging conversation, then get the IDs for active pod members so I can send them
  /// a push notification when I sent a new message
  void _getActivePodMemberIDs() {
    if (!isPodMode) return; // don't execute if this isn't showing a pod message conversation
    this._podActiveMembersListener = PodsDatabasePaths(podID: chatPartnerOrPodID)
        .podDocument
        .collection("members")
        .where("blocked", isEqualTo: false)
        .where("active", isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final List<String> activeMemberIDsList = [];
      snapshot.docs.forEach((member) {
        final memberID = member.get("userID") as String;
        if (!activeMemberIDsList.contains(memberID)) activeMemberIDsList.add(memberID);
      });
      this._podActiveMemberIDsList = activeMemberIDsList;
    });
  }

  /// Load in older messages if the user pulls to refresh
  Future<void> _loadOlderMessages() async {
    if (!isPodMode)
      MessagesDictionary.shared
          .loadOlderDMMessagesIfNecessary(chatPartnerID: chatPartnerOrPodID, conversationID: conversationID);
    else
      MessagesDictionary.shared.loadOlderPodMessagesIfNecessary(podID: chatPartnerOrPodID);
  }

  /// Scroll the chat log to teh bottom after a short delay (to allow the new message time to appear). Set overScroll
  /// to true if calling inside initState to ensure the chat log scrolls all the way to the bottom of the last message.
  void _scrollChatLogToBottom({int millisecondDelay = 250, bool overScroll = false}){
    Future.delayed(Duration(milliseconds: 250), () {
      final extraMargin = overScroll ? 100 : 0;
      // scroll a little past max extents to ensure the bottom message comes fully into view
      _scrollController.animateTo(_scrollController.position.maxScrollExtent + extraMargin,
          duration: Duration(milliseconds: millisecondDelay), curve: Curves.ease);
    });
  }

  @override
  void initState() {
    super.initState();

    var dms = MessagesDictionary.shared.directMessagesDict.value[chatPartnerOrPodID] ?? [];
    var podMessages = MessagesDictionary.shared.podMessageDict.value[chatPartnerOrPodID] ?? [];
    var combined = dms + podMessages;
    combined = combined.toSet().toList(); // remove duplicates
    combined.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));

    if (isPodMode)
      this._getActivePodMemberIDs();
    else
      this._observeWhetherWeHidTheConversation();

    setState(() {
      displayedChatLog = combined;
    });

    _scrollChatLogToBottom(overScroll: true);

    // Update in real time when the chat log changes (for direct messages)
    MessagesDictionary.shared.directMessagesDict.addListener(() {
      if (!this.mounted) return; // avoid setting state if the widget is disposed
      setState(() {
        var dms = MessagesDictionary.shared.directMessagesDict.value[chatPartnerOrPodID] ?? [];
        var podMessages = MessagesDictionary.shared.podMessageDict.value[chatPartnerOrPodID] ?? [];
        var combined = dms + podMessages;
        combined = combined.toSet().toList(); // remove duplicates
        combined.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));

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
        combined.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
        _updateAnimatedList(newList: combined);
      });
    });
  }

  @override
  void dispose() {
    MessagesDictionary.shared.directMessagesDict.removeListener(() {});
    MessagesDictionary.shared.podMessageDict.removeListener(() {});
    _podActiveMembersListener?.cancel();
    _conversationHiddenListener?.cancel();
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
            // Stack allows drawing an image preview over the chat log if an image is attached
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Show a message in the center if the conversation is empty
                  if (displayedChatLog.isEmpty)
                    Center(
                      child: Text("Start a conversation with "
                          "$chatPartnerOrPodName!", style: TextStyle(color: CupertinoColors.inactiveGray),),
                    ),

                  // Chat log
                  CustomScrollView(
                    controller: _scrollController,
                    physics: AlwaysScrollableScrollPhysics(),
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: _loadOlderMessages,
                      ),
                      SliverAnimatedList(
                          key: _listKey,
                          initialItemCount: displayedChatLog.length,
                          itemBuilder: (context, index, animation) {
                            // index both a direct message and a pod message to ensure the list is interchangeable for both
                            // types. Must make sure the list index remains within range
                            final message = displayedChatLog.length > index ? displayedChatLog[index] : null;
                            if (message == null) return Container(); // empty container if message is null
                            final timeStamp = message.timeStamp;

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
                                ),

                                // Actions appear on the left. Use them for received messages
                                actions: [
                                  if (message.senderId != myFirebaseUserId)
                                    // delete the message
                                    CupertinoButton(
                                      child: Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
                                      onPressed: () {
                                        _deleteMessage(message: message);
                                      },
                                      padding: EdgeInsets.zero,
                                    ),

                                  // copy the message
                                  if (message.senderId != myFirebaseUserId)
                                    CupertinoButton(
                                      child: Icon(CupertinoIcons.doc_on_clipboard),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: message.text));
                                      },
                                      padding: EdgeInsets.zero,
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
                                    CupertinoButton(
                                      child: Icon(CupertinoIcons.doc_on_clipboard),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: message.text));
                                      },
                                      padding: EdgeInsets.zero,
                                    ),

                                  if (message.senderId == myFirebaseUserId)
                                    // delete the message
                                    CupertinoButton(
                                      child: Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
                                      onPressed: () {
                                        _deleteMessage(message: message);
                                      },
                                      padding: EdgeInsets.zero,
                                    ),
                                ],
                              ),
                            );
                          }),
                    ],
                  ),
                  if (imageFile != null || isRecordingAudio)
                    BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                        child: Container(color: CupertinoColors.black.withOpacity(0.1))),

                  // Image preview and audio recorder
                  Column(
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
                  )
                ],
              ),
            ),
            CupertinoTextField(
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              controller: _typingMessageController,
              placeholder: "Message ${isPodMode ? chatPartnerOrPodName : chatPartnerOrPodName.split(" ").first}",
              prefix: Row(
                children: [
                  // take photo with camera
                  CupertinoButton(
                      child: Icon(CupertinoIcons.camera),
                      onPressed: () {
                        this._pickImage(source: ImageSource.camera);
                      }),

                  // pick photo from gallery
                  CupertinoButton(
                      child: Icon(CupertinoIcons.photo),
                      onPressed: () {
                        this._pickImage(source: ImageSource.gallery);
                      }),

                  // record audio
                  CupertinoButton(child: Icon(CupertinoIcons.mic), onPressed: _recordAudio)
                ],
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
                        recipientThumbnailURL: chatPartnerThumbnailURL ?? "");
                    _sendMessage(messageToSend: messageToSend);
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
