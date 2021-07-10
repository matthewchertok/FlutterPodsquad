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
import 'package:podsquad/CommonlyUsedClasses/TimeAndDateFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/DatabasePaths/PodsDatabasePaths.dart';
import 'package:podsquad/ListRowViews/MessagingRow.dart';
import 'package:podsquad/OtherSpecialViews/AudioRecorder.dart';
import 'package:podsquad/UIBackendClasses/MessagesDictionary.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';
import 'dart:io';

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
  final _listKey = GlobalKey<AnimatedListState>();

  /// Using a single instance in the entire class ensures that I can access the recording URL and file path so I can
  /// upload it to
  /// the database.
  final _audioRecorder = AudioRecorder();

  /// Insert or remove items with animation
  void _updateAnimatedList({required List<ChatMessage> newList}) {
    // Compute the difference between the new list and the old list and insert the new items into the animated
    // list.
    final dynamicDifferences = newList.difference(betweenOtherList: displayedChatLog);

    var differences = List<ChatMessage>.from(dynamicDifferences);
    print("BIDEN: these are the differences $differences");

    // Only scroll to the bottom if the new list is longer than the previous one (i.e. message added)
    final shouldScrollToBottom = newList.length > displayedChatLog.length;

    // For each differences, insert or remove items
    differences.forEach((difference) {
      final bool newMessageAdded = newList.contains(difference) && !displayedChatLog.contains(difference);
      final bool newMessageRemoved = !newList.contains(difference) && displayedChatLog.contains(difference);

      // if a new message was added, insert it at the end
      if (newMessageAdded) {
        print("BIDEN: new message added: ${difference.text}. Scrolling!");

        // insert at position 0, because the list is reversed so position 0 is at the bottom
        displayedChatLog = newList;
        if (_listKey.currentState != null) _listKey.currentState?.insertItem(0);
      }

      if (newMessageRemoved) {
        print("BIDEN: new message removed: ${difference.text}.");
        final indexToRemove = displayedChatLog.indexWhere((element) => element == difference);
        displayedChatLog = newList;
        _listKey.currentState?.removeItem(
            indexToRemove,
            (context, animation) => MessagingRow(
                messageId: difference.id,
                messageText: difference.text,
                senderId: difference.senderId,
                senderThumbnailURL: difference.senderThumbnailURL,
                timeStamp: difference.timeStamp));
      }
    });

    if (shouldScrollToBottom)
      _scrollController.animateTo(0.0, duration: Duration(milliseconds: 250), curve: Curves.ease);
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
                // The document's name is equal to the alphabetical combination of my ID and the chat partner ID
                final conversationDocumentName = chatPartnerOrPodID < myFirebaseUserId
                    ? chatPartnerOrPodID + myFirebaseUserId
                    : myFirebaseUserId + chatPartnerOrPodID;
                final conversationDocumentReference =
                    firestoreDatabase.collection("dm-conversations").doc(conversationDocumentName);
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

      /// A message has an image if the user has picked one
      final messageHasImage = imageFile != null;
      if (messageHasImage) {
        // Wait for the image to upload, then get a list of [downloadURL, imagePathInStorage]
        final List<String>? messageImageURLAndPath = await ResizeAndUploadImage.sharedInstance
            .uploadMessagingImage(image: this.imageFile!, chatPartnerOrPodID: chatPartnerOrPodID, isPodMessage: !isDM);
        print("BIDEN THE AWAITING IMAGE");
        if (messageImageURLAndPath != null) {
          message.imageURL = messageImageURLAndPath.first;
          message.imagePath = messageImageURLAndPath.last;
          print("BIDEN THE IMAGE URL IS ${message.imageURL}");
        }
      }

      //TODO: if (messageHasAudio)...
      print("BIDEN THE MESSAGE HAS AN IMAGE WITH URL ${message.imageURL}");

      // For now, just for testing purposes, call uploadMessage() right away.
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

      //TODO: write an async function to upload a messaging image to the database. Then write another async function
      // to upload message audio to the database.
    }
  }

  /// Uploads a message to the database. Called as part of sendMessage().
  void _uploadMessage({required ChatMessage message, required CollectionReference conversationRef}) {
    final isDM = message.podID == null;

    // upload a direct message to the database and send the chat partner a push notification
    if (isDM) {
      final documentID = chatPartnerOrPodID < myFirebaseUserId
          ? chatPartnerOrPodID + myFirebaseUserId
          : myFirebaseUserId + chatPartnerOrPodID;
      Map<String, dynamic> dmMessageDictionary = {
        "id": message.id,
        "recipientId": message.recipientId,
        "senderId": message.senderId,
        "systemTime": message.timeStamp,
        "text": message.text
      };
      dmMessageDictionary["readBy"] = [myFirebaseUserId];
      dmMessageDictionary["readTime"] = {myFirebaseUserId: message.timeStamp};
      dmMessageDictionary["readName"] = {
        myFirebaseUserId: MyProfileTabBackendFunctions.shared.myProfileData.value.name
      };
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

        // Un-hide the conversation for both me and my chat partner when a new message is sent
        if (didIHideTheConversation || didChatPartnerHideTheConversation)
          firestoreDatabase
              .collection("dm-conversations")
              .doc(documentID)
              .update({"$myFirebaseUserId.didHideChat": false, "$chatPartnerOrPodID.didHideChat": false});

        // Send the other person a push notification
        final pushSender = PushNotificationSender();
        final myName = MyProfileTabBackendFunctions.shared.myProfileData.value.name;
        pushSender.sendPushNotification(
            recipientID: chatPartnerOrPodID,
            title: "New message from $myName",
            body: message.text,
            notificationType: NotificationTypes.message);
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
  void _recordAudio(){
    setState(() {
      this.isRecordingAudio = true;
    });
  }

  @override
  void initState() {
    super.initState();

    var dms = MessagesDictionary.shared.directMessagesDict.value[chatPartnerOrPodID] ?? [];
    var podMessages = MessagesDictionary.shared.podMessageDict.value[chatPartnerOrPodID] ?? [];
    var combined = dms + podMessages;
    combined = combined.toSet().toList(); // remove duplicates
    combined.sort((b, a) => a.timeStamp.compareTo(b.timeStamp)); // sort in descending order, since the list is reversed
    // (newest messages will appear at the beginning, which is at the bottom of the screen in a reversed list)

    setState(() {
      displayedChatLog = combined;
    });

    // Update in real time when the chat log changes (for direct messages)
    MessagesDictionary.shared.directMessagesDict.addListener(() {
      if (!this.mounted) return; // avoid setting state if the widget is disposed
      setState(() {
        var dms = MessagesDictionary.shared.directMessagesDict.value[chatPartnerOrPodID] ?? [];
        var podMessages = MessagesDictionary.shared.podMessageDict.value[chatPartnerOrPodID] ?? [];
        var combined = dms + podMessages;
        combined = combined.toSet().toList(); // remove duplicates
        combined
            .sort((b, a) => a.timeStamp.compareTo(b.timeStamp)); // sort in descending order, since the list is reversed
        // (newest messages will appear at the beginning, which is at the bottom of the screen in a reversed list)

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
        combined
            .sort((b, a) => a.timeStamp.compareTo(b.timeStamp)); // sort in descending order, since the list is reversed
        // (newest messages will appear at the beginning, which is at the bottom of the screen in a reversed list)
        _updateAnimatedList(newList: combined);
      });
    });
  }

  @override
  void dispose() {
    MessagesDictionary.shared.directMessagesDict.removeListener(() {});
    MessagesDictionary.shared.podMessageDict.removeListener(() {});
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
                  AnimatedList(
                      key: _listKey,
                      controller: _scrollController,
                      reverse: true,
                      physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      initialItemCount: displayedChatLog.length,
                      itemBuilder: (context, index, animation) {
                        // index both a direct message and a pod message to ensure the list is interchangeable for both
                        // types. Must make sure the list index remains within range
                        final message = displayedChatLog.length > index ? displayedChatLog[index] : null;
                        if (message == null) return Container(); // empty container if message is null

                        Center(
                          child: Text("Start a conversation with "
                              "$chatPartnerOrPodName!"),
                        );
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
                  if (imageFile != null || isRecordingAudio)
                    BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                        child: Container(color: CupertinoColors.black.withOpacity(0.1))),

                  // Image preview and audio recorder
                  Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.end,
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
                    if (isRecordingAudio) Padding(padding: EdgeInsets.all(10), child: Column(mainAxisAlignment:
                    MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [

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
                      Card(child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 250), child: this
                          ._audioRecorder,),),)
                    ],),)
                  ],)
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
                    final documentID = chatPartnerOrPodID < myFirebaseUserId
                        ? chatPartnerOrPodID + myFirebaseUserId
                        : myFirebaseUserId + chatPartnerOrPodID;
                    final randomID = firestoreDatabase
                        .collection("dm-conversations")
                        .doc(documentID)
                        .collection("messages")
                        .doc()
                        .id;
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
