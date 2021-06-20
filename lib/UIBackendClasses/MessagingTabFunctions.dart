import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/ChatMessageDataclasses.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/UIBackendClasses/MessagesDictionary.dart';

class MessagingTabFunctions {
  late final bool isPodMode;

  MessagingTabFunctions({required bool isPodMode}) {
    this.isPodMode = isPodMode;
  }

  ///Tracks the latest message in each conversation. Every time this dictionary changes, the displayed list is
  ///automatically updated as well.
  ValueNotifier<Map<String, ChatMessage>> get latestMessagesDict => latestMessagesDict;

  set latestMessagesDict(ValueNotifier<Map<String, ChatMessage>> newValue) {
    latestMessagesDict.value = newValue.value;
    _refreshLatestMessagesList(newDict: newValue.value);
  }

  ///Saves a copy of sortedLatestMessageList so that the list can be filtered and searched without losing the
  ///original data
  var savedLatestMessageList = <ChatMessage>[];

  ///Stores an ordered list of the latest message in all messaging conversations.
  ValueNotifier<List<ChatMessage>> get sortedLatestMessageList => sortedLatestMessageList;

  set sortedLatestMessageList(ValueNotifier<List<ChatMessage>> newMessagesList) {
    if (newMessagesList.value.isNotEmpty) {
      //sorts from newest message to oldest message
      newMessagesList.value.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
      sortedLatestMessageList.value = newMessagesList.value.reversed.toList(); // reverse the list so the newest
      // message appears at the top

      //Say that I don't have any messages if either 1) the list is empty OR 2) all conversations are hidden
      final messageIDsList = isPodMode
          ? sortedLatestMessageList.value.map((message) => message.podID).toList()
          : sortedLatestMessageList.value.map((message) => message.chatPartnerId).toList();
      final areAllConversationsHidden = isPodMode
          ? messageIDsList.difference(betweenOtherList: MessagesDictionary.shared.listOfPodChatsIveHidden.value).isEmpty
          : messageIDsList
              .difference(betweenOtherList: MessagesDictionary.shared.listOfDMConversationsIveHidden.value)
              .isEmpty;

      if (sortedLatestMessageList.value.isEmpty || areAllConversationsHidden)
        isShowingNoMessages.value = true;
      else
        isShowingNoMessages.value = false;
    } else
      sortedLatestMessageList.value = []; // don't bother to run the sort function if we want to clear the list
  }

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
      latestMessagesDict.value.removeWhere((key, value) => key == chatPartnerID);
      streamSubscription.cancel();
    });
    _latestMessageListenersDict.clear();
    latestMessagesDict.value.clear();
    sortedLatestMessageList.value.clear();
    savedLatestMessageList.clear();
    isShowingNoMessages.value = false;
    didGetData.value = false;
  }

  ///Reset the list of message conversations to the original, unfiltered list. Call this when navigating away from a
  ///widget.
  void resetSearch() => sortedLatestMessageList.value = savedLatestMessageList;

  ///When latestMessageDict changes, ensure those changes are reflected in latestMessageList.
  void _refreshLatestMessagesList({required Map<String, ChatMessage> newDict}) {
    // build a new copy of the messages list before updating the display (to minimize flickering)
    List<ChatMessage> latestMessageList = [];
    newDict.values.forEach((message) {
      if (!latestMessageList.contains(message)) {
        latestMessageList.add(message);
      }
    });

    // update the displayed lists with the new value
    sortedLatestMessageList.value = latestMessageList;
    savedLatestMessageList = latestMessageList;
  }

  ///Allow the user to search their message conversations
  void searchMessagesList({required String searchText}) {
    sortedLatestMessageList.value = savedLatestMessageList; // restores the original list so that while searching, I
    // can misspell something and hit backspace to get results instead of having to clear the search text entirely
    // and try again.
    if (searchText.isEmpty) return; // don't bother searching if the text is empty
    if (isPodMode) {
      // filter for messages where the pod name contains the search text
      final messagesMatchingSearchText = sortedLatestMessageList.value
          .where((message) => (message.podName ??
                  "search "
                      "term doesn't match")
              .toLowerCase()
              .contains(searchText.toLowerCase()))
          .toList();
      sortedLatestMessageList.value = messagesMatchingSearchText;
    } else {
      final messagesMatchingSearchText = sortedLatestMessageList.value
          .where((message) => message.chatPartnerName.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
      sortedLatestMessageList.value = messagesMatchingSearchText;
    }
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
              _getLatestPodMessage(podID: podID, podName: podName);
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
              latestMessagesDict.value.removeWhere((key, value) => key == podID);
            });
          }
        }
      });
    });
    _latestMessageListenersDict["podLoader"] = podIDListenerRegistration;
  }

  ///Gets the latest message in all my pod conversations and observe changes as well. Only use this for pod mode.
  void _getLatestPodMessage({required String podID, required String podName}) {
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

      // now make sure there are messages in the conversation
      if (snapshot.docs.length > 0) {
        snapshot.docs.forEach((messageDoc) {
          final messageID = messageDoc.get("id") as String;
          final imageURL = messageDoc.get("imageURL") as String;
          final audioURL = messageDoc.get("audioURL") as String;
          final imagePath = messageDoc.get("imagePath") as String;
          final audioPath = messageDoc.get("audioPath") as String;
          final senderID = messageDoc.get("senderId") as String;
          final senderName = messageDoc.get("senderName") as String;
          final senderThumbnailURL = messageDoc.get("senderThumbnailURL") as String;
          final systemTime = messageDoc.get("systemTime") as double;
          final text = messageDoc.get("text") as String;
          final readBy = messageDoc.get("readBy") as List<String>;

          final message = ChatMessage(
              id: messageID,
              recipientId: "null",
              recipientName: "null",
              senderId: senderID,
              senderName: senderName,
              timeStamp: systemTime,
              text: text,
              podID: podID,
              podName: podName,
              senderThumbnailURL: senderThumbnailURL,
              recipientThumbnailURL: "null",
              imageURL: imageURL,
              audioURL: audioURL,
              imagePath: imagePath,
              audioPath: audioPath,
              readBy: readBy);

          latestMessagesDict.value[podID] = message; // update the latest message that gets displayed for the pod
          // conversation in the Messaging tab
        });
      }

      // if the latest message in the conversation no longer exists, remove the message from memory
      else {
        _latestMessageListenersDict[podID]?.cancel(); // stop listening for new messages if the conversation is deleted
        latestMessagesDict.value.removeWhere((key, value) => key == podID);
      }
    });
    _latestMessageListenersDict[podID] = podMessageListener; // track the listener in case I need to remove it later
  }

  /// Change the pod name in the Messaging tab in real time if the name changes.
  void _updatePodNameIfItChanges({required String podID}) {
    // ignore: cancel_subscriptions
    final listener = firestoreDatabase.collection("pods").doc(podID).snapshots().listen((docSnapshot) {
      final podProfileData = docSnapshot.get("profileData") as Map<String, dynamic>;
      final podName = podProfileData["name"] as String;
      latestMessagesDict.value[podID]?.podName = podName;
    });
    _podNameListenersDict[podID] = listener; // track the listener so it can be removed later
  }

  ///Pre-load direct messaging conversations
  void loadLatestMessageForAllDirectMessageConversations() {
    latestMessagesDict.value.clear(); // clear the dictionary to be safe, then rebuild it.
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
        if (diff.type == DocumentChangeType.added) {
          // find out who the chat partner is in the list of either [myId, theirId] or [theirId, myId]
          final participantIDs = diff.doc.get("participants") as List<String>;
          final chatPartnerID = participantIDs.first == myFirebaseUserId ? participantIDs.last : participantIDs.first;

          // the path where the messages in the conversation are stored
          final collectionRef = diff.doc.reference.collection("messages");
          _observeLatestMessageInConversation(collectionRef: collectionRef, chatPartnerID: chatPartnerID);
        }
      });
    });
    _latestMessageListenersDict["dmLoaders"] = dmLoaderListener;
  }

  ///Observe the latest message in a direct messaging conversation. Pass in the path to
  ///dm-conversations/conversationDocument/messages
  void _observeLatestMessageInConversation(
      {required CollectionReference collectionRef, required String chatPartnerID}) {
    final listener = collectionRef.orderBy("systemTime").limitToLast(1).snapshots().listen((snapshot) {
      final latestMessageDocuments = snapshot.docs;
      didGetData.value = true; // set to true as soon as the first conversation is ready to hide the loading bar

      //Check to make sure there are still messages in the conversation
      if (latestMessageDocuments.length > 0) {
        latestMessageDocuments.forEach((doc) {
          final id = doc.get("id") as String;
          final imageURL = doc.get("imageURL") as String;
          final imagePath = doc.get("imagePath") as String;
          final audioURL = doc.get("audioURL") as String;
          final audioPath = doc.get("audioPath") as String;
          final recipientId = doc.get("recipientId") as String;
          final recipientName = doc.get("recipientName") as String;
          final senderId = doc.get("senderId") as String;
          final senderName = doc.get("senderName") as String;
          final timeStamp = doc.get("systemTime") as double;
          final text = doc.get("text") as String;
          final senderThumbnailURL = doc.get("senderThumbnailURL") as String;
          final recipientThumbnailURL = doc.get("recipientThumbnailURL") as String;
          final readBy = doc.get("readBy") as List<String>;

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
              readBy: readBy);

          //replace the value in the message dictionary with a value equal to the latest chat message
          latestMessagesDict.value[chatPartnerID] = chatMessage;
        });
      }

      // if the conversation was deleted, make sure to handle it
      else {
        _latestMessageListenersDict[chatPartnerID]?.cancel(); // cancel the stream subscription
        latestMessagesDict.value.removeWhere((key, value) => key == chatPartnerID);
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
