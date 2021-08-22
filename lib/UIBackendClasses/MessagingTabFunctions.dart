import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/ChatMessageDataclasses.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';

class MessagingTabFunctions {
  late final bool isPodMode;

  MessagingTabFunctions({required bool isPodMode}) {
    this.isPodMode = isPodMode;
  }

  ///Tracks the latest message in each conversation. Every time this dictionary changes, the displayed list is
  ///automatically updated as well.
  Map<String, ChatMessage> latestMessagesDict = {};

  ///Stores an ordered list of the latest message in all messaging conversations.
  List<ChatMessage> _latestMessageList = [];

  /// IMPORTANT: The sorted latest messages list, which is displayed in the messaging tab.
  ValueNotifier<List<ChatMessage>> sortedLatestMessageList = ValueNotifier([]);

  ///Determines when to display "No messages found"
  ValueNotifier<bool> isShowingNoMessages = ValueNotifier(false);

  ///Store a dictionary of the latest message stream subscription for each pod like this: {podID: StreamSubscription}
  var _latestMessageListenersDict = Map<String, StreamSubscription>();

  ///Store a dictionary of stream subscriptions used for monitoring pod name changes. Maps like this: {podID:
  ///StreamSubscription}
  var _podNameListenersDict = Map<String, StreamSubscription>();

  ///Determines whether I have the messaging data and can hide the loading bar
  ValueNotifier<bool> didGetData = ValueNotifier(false);

  ///Resets the shared instance when the user signs out
  void reset() {
    //remove all realtime listeners
    _podNameListenersDict.forEach((key, value) {
      value.cancel();
    });
    _podNameListenersDict.clear();

    //stop listening for the latest message in each direct message conversation
    _latestMessageListenersDict.forEach((chatPartnerID, streamSubscription) {
      latestMessagesDict.removeWhere((key, value) => key == chatPartnerID);
      streamSubscription.cancel();
    });
    _latestMessageListenersDict.clear();
    latestMessagesDict.clear();
    _latestMessageList.clear();
    isShowingNoMessages.value = false;
    didGetData.value = false;
  }

  ///When latestMessageDict changes, ensure those changes are reflected in latestMessageList.
  void refreshLatestMessagesList({required Map<String, ChatMessage> newDict}) {
    // build a new copy of the messages list before updating the display (to minimize flickering)
    List<ChatMessage> latestMessageList = [];
    newDict.values.forEach((message) {
      if (!latestMessageList.contains(message)) {
        latestMessageList.add(message);
      }
    });

    // update the displayed lists with the new value
    _latestMessageList = latestMessageList;

    // Now update the sorted latest messages list
    if (_latestMessageList.isNotEmpty) {
      //sorts from newest message to oldest message
      _latestMessageList.sort((b, a) => a.timeStamp.compareTo(b.timeStamp));
/*
          //Say that I don't have any messages if either 1) the list is empty OR 2) all conversations are hidden
          final messageIDsList = isPodMode
              ? _latestMessageList.map((message) => message.podID).toList()
              : _latestMessageList.map((message) => message.chatPartnerId).toList();
          final areAllConversationsHidden = isPodMode
              ? messageIDsList.difference(betweenOtherList: MessagesDictionary.shared.listOfPodChatsIveHidden.value).isEmpty
              : messageIDsList
              .difference(betweenOtherList: MessagesDictionary.shared.listOfDMConversationsIveHidden.value)
              .isEmpty;

          if (_latestMessageList.isEmpty || areAllConversationsHidden)
            isShowingNoMessages.value = true;
          else
            isShowingNoMessages.value = false;
*/
    }
    /// Update the displayed list
    sortedLatestMessageList.value = _latestMessageList;
    sortedLatestMessageList.notifyListeners();
  }

  ///Pre-load the IDs for all the pods I'm in and determine if any of those pods has messages
  void getListOfIDsForPodsImIn() {
    // ignore: cancel_subscriptions
    final podIDListenerRegistration = firestoreDatabase
        .collectionGroup("members")
        .where("userID", isEqualTo: myFirebaseUserId)
        .where("blocked", isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.length == 0) didGetData.value = true; // set to true if I have no data to get (if I'm not in
      // any pods)

      snapshot.docChanges.forEach((diff) {
        if (diff.type == DocumentChangeType.added) {
          final parentPodDataDocumentReference = diff.doc.reference.parent.parent; // references the pod containing
          // my membership
          if (parentPodDataDocumentReference != null) {
            final podID = parentPodDataDocumentReference.id;

            // use a stream subscription (not get) because that way I can take advantage of Firestore's offline
            // caching to greatly speed up perceived loading times
            // ignore: cancel_subscriptions
            final podDocumentForMembershipAddedListener = parentPodDataDocumentReference.snapshots().listen((document) {
              final podProfileData = document.get("profileData") as Map<String, dynamic>;
              final podID = podProfileData["podID"] as String;
              final podName = podProfileData["name"] as String;
              final podThumbnailURL = podProfileData["thumbnailURL"] as String;
              _getLatestPodMessage(podID: podID, podName: podName, podThumbnailURL: podThumbnailURL);
              _updatePodNameIfItChanges(podID: podID);
            });
            _latestMessageListenersDict[podID + "documentListener"] = podDocumentForMembershipAddedListener; // track
            // the listener so it can be removed later
          }
        } else if (diff.type == DocumentChangeType.removed) {
          final parentPodDataDocumentReference = diff.doc.reference.parent.parent;
          if (parentPodDataDocumentReference != null) {
            parentPodDataDocumentReference.get().then((docSnapshot) {
              final podProfileData = docSnapshot.get("profileData") as Map<String, dynamic>;

              // extract the pod ID and pod name
              final podID = podProfileData["podID"] as String;
              // cancel all stream subscriptions for the pod if I leave
              _latestMessageListenersDict.forEach((key, streamSubscription) {
                if (key.contains(podID)) streamSubscription.cancel();
              });

              // Remove the pod from my list of pod conversations
              latestMessagesDict.removeWhere((key, value) => key == podID);
              refreshLatestMessagesList(newDict: latestMessagesDict);
            });
          }
        }
      });
    });
    _latestMessageListenersDict["podLoader"] = podIDListenerRegistration;
  }

  ///Gets the latest message in all my pod conversations and observe changes as well. Only use this for pod mode.
  void _getLatestPodMessage({required String podID, required String podName, required String podThumbnailURL}) {
    //continuously update the latest message for each pod conversation by observing the last message in the conversation
    _latestMessageListenersDict[podID]?.cancel(); // remove the preexisting listener to be safe
    // ignore: cancel_subscriptions
    final podMessageListener = firestoreDatabase
        .collection("pods")
        .doc(podID)
        .collection("messages")
        .orderBy("systemTime")
        .limitToLast(1)
        .snapshots()
        .listen((snapshot) {
      didGetData.value = true; // set to true as soon as the first conversation is ready (this should fire even if
      // there are no messages)

      snapshot.docs.forEach((messageDoc) {
        final data = messageDoc.data();
        final messageID = messageDoc.get("id") as String;
        final imageURL = data["imageURL"] as String? ?? "";
        final audioURL = data["audioURL"] as String? ?? "";
        final imagePath = data["imagePath"] as String? ?? "";
        final audioPath = data["audioPath"] as String? ?? "";
        final senderID = messageDoc.get("senderId") as String;
        final senderName = messageDoc.get("senderName") as String;
        final senderThumbnailURL = messageDoc.get("senderThumbnailURL") as String;
        final systemTimeRaw = messageDoc.get("systemTime") as num;
        final systemTime = systemTimeRaw.toDouble();
        final text = messageDoc.get("text") as String;
        final readBy = data["readBy"] as List<dynamic>? ?? [];
        final readTimesMapRaw = data["readTime"] as Map<String, dynamic>? ?? {};
        final readTimesMap = Map<String, num>.from(readTimesMapRaw);
        final readNamesMapRaw = data["readName"] as Map<String, dynamic>? ?? {};
        final readNamesMap = Map<String, String>.from(readNamesMapRaw);

        final message = ChatMessage(
            id: messageID,
            recipientId: "",
            recipientName: "",
            senderId: senderID,
            senderName: senderName,
            timeStamp: systemTime,
            text: text,
            podID: podID,
            podName: podName,
            senderThumbnailURL: senderThumbnailURL,
            recipientThumbnailURL: "",
            podThumbnailURL: podThumbnailURL,
            imageURL: imageURL,
            audioURL: audioURL,
            imagePath: imagePath,
            audioPath: audioPath,
            readBy: List<String>.from(readBy),
            readNames: readNamesMap,
            readTimes: readTimesMap);

        latestMessagesDict[podID] = message; // update the latest message that gets displayed for the pod
        refreshLatestMessagesList(newDict: latestMessagesDict);
        // conversation in the Messaging tab
      });
    });
    _latestMessageListenersDict[podID] = podMessageListener; // track the listener in case I need to remove it later
  }

  /// Change the pod name in the Messaging tab in real time if the name changes.
  void _updatePodNameIfItChanges({required String podID}) {
    // ignore: cancel_subscriptions
    final listener = firestoreDatabase.collection("pods").doc(podID).snapshots().listen((docSnapshot) {
      final podProfileData = docSnapshot.get("profileData") as Map<String, dynamic>;
      final podName = podProfileData["name"] as String;
      latestMessagesDict[podID]?.podName = podName;
      refreshLatestMessagesList(newDict: latestMessagesDict);
    });
    _podNameListenersDict[podID] = listener; // track the listener so it can be removed later
  }

  ///Pre-load direct messaging conversations
  void loadLatestMessageForAllDirectMessageConversations() {
    latestMessagesDict.clear(); // clear the dictionary to be safe, then rebuild it.
    // get a list of all my direct message conversations
    // ignore: cancel_subscriptions
    final dmLoaderListener = firestoreDatabase
        .collection("dm-conversations")
        .where("participants", arrayContains: myFirebaseUserId)
        .snapshots()
        .listen((snapshot) {
      // track whether I have any messages
      if (snapshot.docs.length == 0) {
        didGetData.value = true; // set to true if I have no data to get
        isShowingNoMessages.value = true;
      } else
        isShowingNoMessages.value = false;

      snapshot.docChanges.forEach((diff) {
        // find out who the chat partner is in the list of either [myId, theirId] or [theirId, myId]
        final participantIDs = diff.doc.get("participants") as List<dynamic>;
        final String chatPartnerID =
            participantIDs.first == myFirebaseUserId ? participantIDs.last : participantIDs.first;

        if (diff.type == DocumentChangeType.added) {
          // the path where the messages in the conversation are stored
          final collectionRef = diff.doc.reference.collection("messages");
          _observeLatestMessageInConversation(collectionRef: collectionRef, chatPartnerID: chatPartnerID);
        } else if (diff.type == DocumentChangeType.removed) {
          // Remove the conversation from my list of conversations
          latestMessagesDict.remove(chatPartnerID);
          refreshLatestMessagesList(newDict: latestMessagesDict);
        }
      });
    });
    _latestMessageListenersDict["dmLoaders"] = dmLoaderListener;
  }

  ///Observe the latest message in a direct messaging conversation. Pass in the path to
  ///dm-conversations/conversationDocument/messages
  void _observeLatestMessageInConversation(
      {required CollectionReference collectionRef, required String chatPartnerID}) {
    //ignore: cancel_subscriptions
    final listener = collectionRef.orderBy("systemTime").limitToLast(1).snapshots().listen((snapshot) {
      final latestMessageDocuments = snapshot.docs;
      didGetData.value = true; // set to true as soon as the first conversation is ready to hide the loading bar
      if (latestMessageDocuments.length > 0)
        latestMessageDocuments.forEach((doc) {
          final data = doc.data() as Map;
          final id = data["id"] as String;
          final imageURL = data["imageURL"] as String?;
          final imagePath = data["imagePath"] as String?;
          final audioURL = data["audioURL"] as String?;
          final audioPath = data["audioPath"] as String?;
          final recipientId = data["recipientId"] as String;
          final recipientName = data["recipientName"] as String;
          final senderId = data["senderId"] as String;
          final senderName = data["senderName"] as String;
          final timeStamp = data["systemTime"] as double;
          final text = data["text"] as String;
          final senderThumbnailURL = data["senderThumbnailURL"] as String;
          final recipientThumbnailURL = data["recipientThumbnailURL"] as String;
          final readByDynamic = data["readBy"] as List<dynamic>;
          final readBy = List<String>.from(readByDynamic);
          final readTimesMapRaw = data["readTime"] as Map<String, dynamic>? ?? {};
          final readTimesMap = Map<String, num>.from(readTimesMapRaw);
          final readNamesMapRaw = data["readName"] as Map<String, dynamic>? ?? {};
          final readNamesMap = Map<String, String>.from(readNamesMapRaw);

          final chatMessage = ChatMessage(
              id: id,
              recipientId: recipientId,
              recipientName: recipientName,
              senderId: senderId,
              senderName: senderName,
              timeStamp: timeStamp,
              text: text,
              senderThumbnailURL: senderThumbnailURL,
              recipientThumbnailURL: recipientThumbnailURL,
              imagePath: imagePath,
              imageURL: imageURL,
              audioPath: audioPath,
              audioURL: audioURL,
              readBy: readBy,
              readNames: readNamesMap,
              readTimes: readTimesMap);
          //replace the value in the message dictionary with a value equal to the latest chat message.
          latestMessagesDict[chatPartnerID] = chatMessage;
          refreshLatestMessagesList(newDict: latestMessagesDict);
        });
      
      // if there are no messages in the conversation, remove the conversation from the Messaging tab
      else {
        latestMessagesDict.remove(chatPartnerID);
        print("CONVERSATION REMOVED. Now it is $latestMessagesDict");
        refreshLatestMessagesList(newDict: latestMessagesDict);
      }
    });
    _latestMessageListenersDict[chatPartnerID] = listener; // track the listener so it can be removed later if needed
  }
}

///Performs backend functions for the direct messaging tab displaying DM conversations.
class LatestDirectMessagesDictionary {
  static final shared = MessagingTabFunctions(isPodMode: false);
}

///Performs backend functions for the pod messaging tab displaying pod message conversations
class LatestPodMessagesDictionary {
  static final shared = MessagingTabFunctions(isPodMode: true);
}
