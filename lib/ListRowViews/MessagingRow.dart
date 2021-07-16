import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/ViewFullImage.dart';
import 'package:podsquad/ContentViews/ViewPersonDetails.dart';
import 'package:podsquad/OtherSpecialViews/AudioPlayer.dart';
import 'package:podsquad/OtherSpecialViews/DecoratedImage.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

/// Leave recipientId and chatPartnerName blank if it's a pod message. Leave podID and podName blank if it's a direct
/// message.
class MessagingRow extends StatelessWidget {
  const MessagingRow(
      {Key? key,
      required this.messageId,
      required this.messageText,
      required this.senderId,
      required this.senderThumbnailURL,
      this.chatPartnerOrPodID = "",
      this.chatPartnerOrPodName = "",
      this.messageImageURL,
      this.messageAudioURL,
      required this.timeStamp,
      this.isPodMode = false,
      this.podMembers})
      : super(key: key);
  final String messageId;
  final String chatPartnerOrPodName;
  final String messageText;
  final String senderId;
  final String senderThumbnailURL;

  /// Leave this empty if it's a pod messages
  final String chatPartnerOrPodID;
  final String? messageImageURL;
  final String? messageAudioURL;
  final double timeStamp;

  String get myName => MyProfileTabBackendFunctions.shared.myProfileData.value.name;

  /// determine whether this is showing a pod message, in which case the user's name must be displayed above the message
  final bool isPodMode;

  /// Leave this empty if it's a direct message
  final List<ProfileData>? podMembers;

  @override
  Widget build(BuildContext context) {
    return senderId == myFirebaseUserId
        ? SentMessageRow(
            messageText: messageText,
            timeStamp: timeStamp,
            isPodMode: isPodMode,
            messageImageURL: this.messageImageURL,
            messageAudioURL: this.messageAudioURL,
            chatPartnerOrPodID: chatPartnerOrPodID,
            chatPartnerOrPodName: chatPartnerOrPodName,
          )
        : ReceivedMessageRow(
            messageText: messageText,
            timeStamp: timeStamp,
            isPodMode: isPodMode,
            chatPartnerOrPodName: chatPartnerOrPodName,
            chatPartnerOrPodID: chatPartnerOrPodID,
            messageSenderThumbnailURL: senderThumbnailURL,
            messageImageURL: this.messageImageURL,
            messageAudioURL: this.messageAudioURL,
          );
  }
}

/// Displays a message if I sent it (text on the left, profile image on the right)
class SentMessageRow extends StatelessWidget {
  const SentMessageRow(
      {Key? key,
      required this.messageText,
      required this.timeStamp,
      required this.isPodMode,
      this.messageImageURL,
      this.messageAudioURL,
      this.chatPartnerOrPodName,
      this.chatPartnerOrPodID})
      : super(key: key);

  String get myName => MyProfileTabBackendFunctions.shared.myProfileData.value.name;

  String get myThumbnailURL => MyProfileTabBackendFunctions.shared.myProfileData.value.thumbnailURL;
  final String? chatPartnerOrPodID;
  final String? chatPartnerOrPodName;
  final String messageText;
  final double timeStamp;
  final bool isPodMode;

  /// Pass in a value if the message has an image
  final String? messageImageURL;
  final String? messageAudioURL;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 10, 5, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Spacer(), // sent messages appear on the right

            // On the left will be a column containing the message text, with the image and audio below, if there is any
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isPodMode)
                  Text(
                    myName,
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                  ),

                // the message text
                Bubble(
                  color: accentColor.withOpacity(0.9),
                  margin: BubbleEdges.only(right: 5, bottom: 10),
                  nip: BubbleNip.rightTop,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 180),
                    child: Text(
                      messageText,
                      style: TextStyle(color: CupertinoColors.white),
                      maxLines: null,
                    ),
                  ),
                ),

                // The audio and image, if applicable
                if (messageImageURL != null || messageAudioURL != null)
                  Row(
                    children: [
                      if (messageAudioURL != null)
                        Container(
                          width: 120,
                          height: 80,
                          child: AudioPlayer(
                            audioURL: messageAudioURL!,
                          ),
                        ),
                      if (messageImageURL != null)
                        Container(
                          width: 120,
                          height: 120,
                          child: CupertinoButton(
                            child: CachedNetworkImage(
                              imageUrl: messageImageURL!,
                              fit: BoxFit.contain,
                            ),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) => ViewFullImage(
                                          urlForImageToView: messageImageURL!,
                                          imageID: "",
                                          navigationBarTitle: "Image from $chatPartnerOrPodName",
                                          canWriteCaption: false)));
                            },
                          ),
                        )
                    ],
                  )
              ],
            ),

            // My profile thumbnail. Tap to navigate to my profile
            CupertinoButton(
              padding: EdgeInsets.zero,
                child: DecoratedImage(
                  imageURL: myThumbnailURL,
                  width: 60,
                  height: 60,
                  shadowColor: accentColor.withOpacity(0.6),
                ),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true)
                      .push(CupertinoPageRoute(builder: (context) => ViewPersonDetails(personID: myFirebaseUserId,
                      messagingEnabled: false,)));
                })

            // On the right is my profile photo
          ],
        ),
      ),
    );
  }
}

/// Displays a message if I sent it (text on the left, profile image on the right)
class ReceivedMessageRow extends StatelessWidget {
  const ReceivedMessageRow(
      {Key? key,
      required this.messageText,
      required this.timeStamp,
      required this.isPodMode,
      this.messageImageURL,
      this.messageAudioURL,
      required this.chatPartnerOrPodName,
      required this.chatPartnerOrPodID,
      required this.messageSenderThumbnailURL})
      : super(key: key);

  String get myName => MyProfileTabBackendFunctions.shared.myProfileData.value.name;

  final String messageSenderThumbnailURL;
  final String chatPartnerOrPodID;
  final String chatPartnerOrPodName;
  final String messageText;
  final double timeStamp;
  final bool isPodMode;

  /// Pass in a value if the message has an image
  final String? messageImageURL;
  final String? messageAudioURL;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsets.fromLTRB(5, 10, 0, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // On the left is the other person's profile image. Tap it to navigate to their profile.
            CupertinoButton(
              padding: EdgeInsets.zero,
                child: DecoratedImage(
                  imageURL: messageSenderThumbnailURL,
                  width: 60,
                  height: 60,
                  shadowColor: receivedMessageBubbleColor.withOpacity(0.6),
                ),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true)
                      .push(CupertinoPageRoute(builder: (context) => ViewPersonDetails(personID: chatPartnerOrPodID,
                    messagingEnabled: false, // ensure that the user can't dig themselves infinitely deep in the
                    // stack by navigating to MessagingView, then ViewPersonDetails, then back to MessagingView, etc.
                  )));
                }),
            // On the left will be a column containing the message text, with the image and audio below, if there is any
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPodMode)
                  Text(
                    chatPartnerOrPodName,
                    style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                  ),

                // the message text
                Bubble(
                  color: receivedMessageBubbleColor.withOpacity(0.9),
                  margin: BubbleEdges.only(left: 5, bottom: 10),
                  nip: BubbleNip.leftTop,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 180),
                    child: Text(
                      messageText,
                      style: TextStyle(color: CupertinoColors.white),
                      maxLines: null,
                    ),
                  ),
                ),

                // The audio and image, if applicable
                if (messageImageURL != null || messageAudioURL != null)
                  Row(
                    children: [
                      if (messageImageURL != null)
                        Container(
                          width: 120,
                          height: 120,
                          child: CupertinoButton(
                            child: CachedNetworkImage(
                              imageUrl: messageImageURL!,
                              fit: BoxFit.contain,
                            ),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) => ViewFullImage(
                                          urlForImageToView: messageImageURL!,
                                          imageID: "",
                                          navigationBarTitle: "Image from $chatPartnerOrPodName",
                                          canWriteCaption: false)));
                            },
                          ),
                        ),
                      if (messageAudioURL != null)
                        Container(
                          width: 120,
                          height: 80,
                          child: AudioPlayer(
                            audioURL: messageAudioURL!,
                          ),
                        )
                    ],
                  )
              ],
            ),

            Spacer(), // sent messages appear on the left
          ],
        ),
      ),
    );
  }
}
