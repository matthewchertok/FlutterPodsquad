import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/ChatMessageDataclasses.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/DatabasePaths/PodsDatabasePaths.dart';
import 'package:podsquad/UIBackendClasses/MessagingTabFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

///Downloads and saves messages in the backend so they can be pulled into MessagingView
class MessagesDictionary {
  static final shared = MessagesDictionary();

  ///Maps userID to the corresponding list of downloaded chat messages like this: {userID: List<ChatMessage>}
  ValueNotifier<Map<String, List<ChatMessage>>> directMessagesDict = ValueNotifier({});

  ///Maps {chatPartnerID: conversationID} and is needed to remove all listeners when reset() is called
  var directMessageConversationIDsDict = Map<String, String>();

  ///Maps {podID: List<PodMessage>}
  ValueNotifier<Map<String, List<ChatMessage>>> podMessageDict = ValueNotifier({});

  ///Maps podID or chatPartnerID to the oldest message that has been downloaded. This allows swipe-to-refresh
  ///capability - i.e. a user could load the 10 newest messages in a conversation, and this dictionary would keep track
  /// of the oldest of those 10 messages so that if the user wants to load the next 10 messages, the new query would
  /// fetch the 20th-newest through the 11th-newest messages and won't re-grab messages that we already have.
  var endBeforeDictionary = Map<String, DocumentSnapshot>();

  ///Maps podID or chatPartnerID to either true or false. True means that the user has swiped up enough to load every
  /// message in the conversation, meaning we should not attempt to load older messages anymore.
  var hasLoadedEveryMessageInConversationDictionary = Map<String, bool>();

  ///Maps podID or chatPartnerID to either true or false to determine whether messages are loading as a result of the
  /// user having swiped up to load more messages.
  ValueNotifier<Map<String, bool>> areMoreMessagesLoadingDict = ValueNotifier({});

  ///Maps podID or chatPartnerID to either true or false to determine whether the chat log should scroll to the
  ///bottom. It should scroll if a new message is added, but it should not scroll when older messages are loaded in
  ///after the user scrolls up.
  var shouldChatLogScroll = Map<String, bool>();

  ///Keep track of all the pods I've hidden
  set _podsIveHiddenDict(Map<String, bool> newValue) {
    _podsIveHiddenDict = newValue;
    List<String> newListOfPodsIveHidden = [];
    _podsIveHiddenDict.forEach((pod, bool) {
      newListOfPodsIveHidden.add(pod);
    });
    listOfPodChatsIveHidden.value = newListOfPodsIveHidden;
  }

  ///Keep track of all the pods I've hidden
  Map<String, bool> get _podsIveHiddenDict => _podsIveHiddenDict;

  ///Keep track of all the DM conversations I've hidden
  set _dmsIveHiddenDict(Map<String, bool> newValue) {
    _dmsIveHiddenDict = newValue;
    List<String> newListOfDmsIveHidden = [];
    _dmsIveHiddenDict.forEach((conversation, bool) {
      newListOfDmsIveHidden.add(conversation);
    });
    listOfDMConversationsIveHidden.value = newListOfDmsIveHidden;
  }

  ///Keep track of all the DM conversations I've hidden
  Map<String, bool> get _dmsIveHiddenDict => _dmsIveHiddenDict;

  ///Contains a list of all pod IDs where I've hidden the chat
  set listOfPodChatsIveHidden(ValueNotifier<List<String>> newValue) {
    listOfPodChatsIveHidden = newValue;

    ///The list of IDs for all my pod conversations
    final podChatIDsList =
        LatestPodMessagesDictionary.shared.sortedLatestMessageList.value.map((e) => e.podID).toList();

    //If every conversation is hidden (or I don't have any conversations), say that I have no messages to display.
    if (podChatIDsList.isEmpty || podChatIDsList.difference(betweenOtherList: listOfPodChatsIveHidden.value).isEmpty)
      LatestPodMessagesDictionary.shared.isShowingNoMessages.value = true;
    else
      LatestPodMessagesDictionary.shared.isShowingNoMessages.value = false;
  }

  ///Contains a list of all pod IDs where I've hidden the chat
  ValueNotifier<List<String>> get listOfPodChatsIveHidden => listOfPodChatsIveHidden;

  ///Contains a list of all direct message chat partner IDs where I've hidden the chat
  set listOfDMConversationsIveHidden(ValueNotifier<List<String>> newValue) {
    final dmChatIDsList =
        LatestDirectMessagesDictionary.shared.sortedLatestMessageList.value.map((e) => e.chatPartnerId).toList();

    // If every conversation is hidden (or I don't have any conversations), say that I have no messages to display.
    if (dmChatIDsList.isEmpty ||
        dmChatIDsList.difference(betweenOtherList: listOfDMConversationsIveHidden.value).isEmpty)
      LatestDirectMessagesDictionary.shared.isShowingNoMessages.value = true;
    else
      LatestDirectMessagesDictionary.shared.isShowingNoMessages.value = false;
  }

  ///Contains a list of all direct message chat partner IDs where I've hidden the chat
  ValueNotifier<List<String>> get listOfDMConversationsIveHidden => listOfDMConversationsIveHidden;

  ///Tracks all stream subscriptions so I can remove them if I need to. Map {chatPartnerOrPodID: StreamSubscription}
  var _listenerRegistrationsDict = Map<String, StreamSubscription>();

  ///Resets the shared instance when the user signs out.
  void reset() {
    // cancel all stream subscriptions to stop listening for data changes
    _listenerRegistrationsDict.forEach((key, value) {
      value.cancel();
    });

    _listenerRegistrationsDict.clear();
    directMessagesDict.value.clear();
    podMessageDict.value.clear();
    _podsIveHiddenDict.clear();
    _dmsIveHiddenDict.clear();
    directMessageConversationIDsDict.clear();
  }

  ///Prepares the messages for all conversations in the background so that each chat is ready to go when it's opened
  void preLoadAllDirectMessageConversations() {
    // ignore: cancel_subscriptions
    final dmMessagePreloadingListener = firestoreDatabase
        .collection("dm-conversations")
        .where("participants", arrayContains: myFirebaseUserId)
        .snapshots()
        .listen((docSnapshot) {
      docSnapshot.docChanges.forEach((diff) {
        final participants = diff.doc.get("participants") as List<dynamic>;
        final chatPartnerID = participants.first == myFirebaseUserId ? participants.last : participants.first;
        final conversationID = diff.doc.id;

        if (diff.type == DocumentChangeType.added) {
          this.directMessageConversationIDsDict[chatPartnerID] = conversationID;
          this._listenForDirectMessageAddedOrRemoved(
              chatPartnerID: chatPartnerID,
              conversationID: conversationID,
              onCompletion: () {
                this.loadOlderDMMessagesIfNecessary(
                    chatPartnerID: chatPartnerID, conversationID: conversationID, limitToLast: 10);
              });
        } else if (diff.type == DocumentChangeType.removed)
          _stopListeningToDirectMessageConversation(chatPartnerID: chatPartnerID, conversationID: conversationID);
      });
    });
    _listenerRegistrationsDict["directMessagePreloadListener"] = dmMessagePreloadingListener; // key can be anything
    // as long as it isn't someone's ID
  }

  ///Cancel the stream subscription and remove the conversation from memory
  void _stopListeningToDirectMessageConversation({required String chatPartnerID, required String conversationID}) {
    _listenerRegistrationsDict[chatPartnerID]?.cancel();
    directMessagesDict.value.removeWhere((key, value) => key == chatPartnerID);
  }

  ///Gets a list of all direct messaging conversations where I've hidden the chat, to make sure that the chat doesn't
  /// get displayed
  void preLoadListOfDMsImInactiveFrom() {
    // ignore: cancel_subscriptions
    final dmHiddenMessagePreloadingListener = firestoreDatabase
        .collection("dm-conversations")
        .where("participants", arrayContains: myFirebaseUserId)
        .where("$myFirebaseUserId.didHideChat", isEqualTo: true)
        .snapshots()
        .listen((docSnapshot) {
      docSnapshot.docChanges.forEach((diff) {
        final participants = diff.doc.get("participants") as List<String>;
        final chatPartnerID = participants.first == myFirebaseUserId ? participants.last : participants.first;
        if (diff.type == DocumentChangeType.added) {
          var dmsIveHidden = _dmsIveHiddenDict; // copy the variable
          dmsIveHidden[chatPartnerID] = true; // modify the variable
          this._dmsIveHiddenDict = dmsIveHidden; // use the setter
        } else if (diff.type == DocumentChangeType.removed) {
          var dmsIveHidden = _dmsIveHiddenDict; // copy the variable
          dmsIveHidden.removeWhere((key, value) => key == chatPartnerID); // modify the variable
          this._dmsIveHiddenDict = dmsIveHidden; // use the setter
        }
      });
    });
    _listenerRegistrationsDict["hiddenPreload"] = dmHiddenMessagePreloadingListener; // key can be anything as long
    // as it isn't someone's ID
  }

  ///Call this method to attach a listener to the newest message in a conversation to listen for additional messages
  ///added (or added then removed). Inside the completion handler,
  /// call listenForDirectMessageAddedOrRemove and limit to the last 9 messages to complete the preload of the 10
  /// most recent messages in a conversation.
  void _listenForDirectMessageAddedOrRemoved(
      {required String chatPartnerID, required String conversationID, required Function onCompletion}) {
    directMessagesDict.value[chatPartnerID]?.clear(); // initialize an empty list to store the messages in the
    // conversation
    _listenerRegistrationsDict[chatPartnerID]?.cancel(); // remove the stream subscription to avoid duplication (to
    // be safe)

    ///First, get the last message in the conversation. Then, listen for new messages starting with that one. I'm
    ///using a stream subscription to allow reading from the cache to save reads.
    StreamSubscription? dmMessageAddedListener;
    dmMessageAddedListener = firestoreDatabase
        .collection("dm-conversations")
        .doc(conversationID)
        .collection("messages")
        .orderBy("systemTime")
        .limitToLast(1)
        .snapshots()
        .listen((snapshot) {
      dmMessageAddedListener?.cancel(); //immediately cancel the subscription once I get the last message

      hasLoadedEveryMessageInConversationDictionary[chatPartnerID] = snapshot.docs.length == 0; // if there are no
      // messages in the conversation, then I don't need to load any earlier ones.

      final lastDocument = snapshot.docs.last; // the query will return only one document anyway

      ///Limit the listener to messages where systemTime is greater than or equal to this cutoff to avoid duplicating
      /// messages and using extra reads. Optional double because the last document might not exist if a conversation
      /// has 0 documents.
      final timeCutoff = lastDocument.get("systemTime") as double?;

      // track the oldest document we downloaded so that future queries know to stop there and not re-fetch documents
      // we already got
      endBeforeDictionary[chatPartnerID] = lastDocument;
      onCompletion(); // now that we have the last document, we can call the completion handler to then listen to
      // changes to the previous 9 documents without having to double-read those documents.

      final collectionRef = firestoreDatabase
          .collection("dm-conversations")
          .doc(conversationID)
          .collection("messages")
          .orderBy("systemTime");
      // Depending on whether the conversation exists, either subscribe to the entire conversation (if it doesn't
      // exist yet), or start subscribing to the newest message.
      final query = timeCutoff == null ? collectionRef : collectionRef.startAt([timeCutoff]);

      //Now, start an unlimited listener beginning with the last document that will handle it when new messages are
      // added or deleted.
      // ignore: cancel_subscriptions
      final dmAddedOrRemovedListener = query.snapshots().listen((snapshot) {
        snapshot.docChanges.forEach((diff) {
          if (diff.type == DocumentChangeType.added) {
            shouldChatLogScroll[chatPartnerID] = true; // scroll to the bottom when a new message is added
            final data = diff.doc.data();
            final systemTime = diff.doc.get("systemTime") as double;
            final id = diff.doc.get("id") as String;
            final imageURL = data?["imageURL"] as String?;
            final imagePath = data?["imagePath"] as String?;
            final audioURL = data?["audioURL"] as String?;
            final audioPath = data?["audioPath"] as String?;
            final recipientId = diff.doc.get("recipientId") as String;
            final recipientName = diff.doc.get("recipientName") as String;
            final senderId = diff.doc.get("senderId") as String;
            final senderName = diff.doc.get("senderName") as String;
            final senderThumbnailURL = diff.doc.get("senderThumbnailURL") as String;
            final recipientThumbnailURL = diff.doc.get("recipientThumbnailURL") as String;
            final text = diff.doc.get("text") as String;

            final chatMessage = ChatMessage(
                id: id,
                recipientId: recipientId,
                recipientName: recipientName,
                senderId: senderId,
                senderName: senderName,
                timeStamp: systemTime,
                text: text,
                senderThumbnailURL: senderThumbnailURL,
                recipientThumbnailURL: recipientThumbnailURL,
                imagePath: imagePath,
                imageURL: imageURL,
                audioPath: audioPath,
                audioURL: audioURL);

            //Add the message to the associated chat partner ID in the dictionary
            if (chatMessage.text.trim().isNotEmpty) {
              // initialize a list if it's null
              if (directMessagesDict.value[chatPartnerID] == null) directMessagesDict.value[chatPartnerID] = [];
              if (directMessagesDict.value[chatPartnerID] != null) {
                if (!directMessagesDict.value[chatPartnerID]!.contains(chatMessage)) {
                  directMessagesDict.value[chatPartnerID]!.add(chatMessage);
                  directMessagesDict.notifyListeners(); // it's required here because otherwise Dart doesn't know to
                  // update listeners.
                  print("BIDEN: just added a DM with text ${chatMessage.text}");
                }
              }
            }
          } else if (diff.type == DocumentChangeType.removed) {
            final messageID = diff.doc.get("id") as String;
            directMessagesDict.value[chatPartnerID]?.removeWhere((message) => message.id == messageID);
            directMessagesDict.notifyListeners(); // it's required here because otherwise Dart doesn't know to
            // update listeners.
          }
        });
      });
      _listenerRegistrationsDict[chatPartnerID] = dmAddedOrRemovedListener; // register the stream subscription so I
      // can remove it later
    });
  }

  ///Use this function to load older messages in a conversation using pagination.
  void loadOlderDMMessagesIfNecessary(
      {required String chatPartnerID, required String conversationID, int limitToLast = 10}) {
    final numberOfMessages = limitToLast; // renamed for clarity inside the function body
    shouldChatLogScroll[chatPartnerID] = false; // don't scroll the chat log to the bottom when loading older messages

    // if the user has scrolled up to load every message in the conversation already, don't attempt to load any more.
    final hasLoadedEveryMessageInConversation = hasLoadedEveryMessageInConversationDictionary[chatPartnerID];
    if (hasLoadedEveryMessageInConversation != null) {
      if (hasLoadedEveryMessageInConversation) return;
    }

    // Make sure not to load any messages newer than this, as they have already been loaded.
    final endDocument = endBeforeDictionary[chatPartnerID];
    if (endDocument != null) {
      areMoreMessagesLoadingDict.value[chatPartnerID] = true; // indicate that more messages are loading
      // ignore: cancel_subscriptions
      final olderDMsListener = firestoreDatabase
          .collection("dm-conversations")
          .doc(conversationID)
          .collection("messages")
          .orderBy("systemTime")
          .endBeforeDocument(endDocument)
          .limitToLast(numberOfMessages)
          .snapshots()
          .listen((snapshot) {
        // if the query returns fewer results than requested, we know that we've loaded every message in the
        // conversation and should not attempt to load any older messages
        hasLoadedEveryMessageInConversationDictionary[chatPartnerID] = snapshot.docs.length < numberOfMessages;

        // track the oldest document we downloaded so that future queries know to stop there and not re-fetch
        // documents we already got
        endBeforeDictionary[chatPartnerID] = snapshot.docs.first;

        snapshot.docChanges.forEach((diff) {
          if (diff.type == DocumentChangeType.added) {
            final data = diff.doc.data();
            final systemTime = diff.doc.get("systemTime") as double;
            final id = diff.doc.get("id") as String;
            final imageURL = data?["imageURL"] as String?;
            final imagePath = data?["imagePath"] as String?;
            final audioURL = data?["audioURL"] as String?;
            final audioPath = data?["audioPath"] as String?;
            final recipientId = diff.doc.get("recipientId") as String;
            final recipientName = diff.doc.get("recipientName") as String;
            final senderId = diff.doc.get("senderId") as String;
            final senderName = diff.doc.get("senderName") as String;
            final senderThumbnailURL = diff.doc.get("senderThumbnailURL") as String;
            final recipientThumbnailURL = diff.doc.get("recipientThumbnailURL") as String;
            final text = diff.doc.get("text") as String;

            final chatMessage = ChatMessage(
                id: id,
                recipientId: recipientId,
                recipientName: recipientName,
                senderId: senderId,
                senderName: senderName,
                timeStamp: systemTime,
                text: text,
                senderThumbnailURL: senderThumbnailURL,
                recipientThumbnailURL: recipientThumbnailURL,
                imagePath: imagePath,
                imageURL: imageURL,
                audioPath: audioPath,
                audioURL: audioURL);

            //Add the message to the associated chat partner ID in the dictionary
            if (chatMessage.text.trim().isNotEmpty) {
              // initialize a list if it's null
              if (directMessagesDict.value[chatPartnerID] == null) directMessagesDict.value[chatPartnerID] = [];
              if (directMessagesDict.value[chatPartnerID] != null) {
                if (!directMessagesDict.value[chatPartnerID]!.contains(chatMessage))
                  directMessagesDict.value[chatPartnerID]!.add(chatMessage);
                directMessagesDict.notifyListeners();
              }
            }
          }

          // listen for messages removed from the conversation
          else if (diff.type == DocumentChangeType.removed) {
            final messageID = diff.doc.get("id") as String;
            directMessagesDict.value[chatPartnerID]?.removeWhere((message) => message.id == messageID);
            directMessagesDict.notifyListeners();
          }
        });
        print("Loaded in ${snapshot.docs.length} new messages! The total conversation is ${directMessagesDict
            .value[chatPartnerID]?.length ?? 0} messages long!");
      });

      // give a unique registration to the listener so that it can be tracked and removed if needed
      final random = Random();

      ///random.nextInt(1000) will return a random integer between 0 and 999 (inclusive)
      final randomListenerID =
          random.nextInt(1000) + random.nextInt(1000) + random.nextInt(1000) + random.nextInt(1000);
      _listenerRegistrationsDict[chatPartnerID + "$randomListenerID"] = olderDMsListener;
    }
  }

  ///Prepares the messages for all pod conversations in the background so that each chat is ready to go when opened
  void preLoadAllPodMessageConversations() {
    //query all "members" subcollections that contain my document. Access the pod's messages collection by going up
    // to the parent document and then down into the messages collection.
    // ignore: cancel_subscriptions
    final podMessageListeners = firestoreDatabase
        .collectionGroup("members")
        .where("userID", isEqualTo: myFirebaseUserId)
        .where("blocked", isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      snapshot.docChanges.forEach((diff) {
        final podID = diff.doc.reference.parent.parent?.id;
        if (podID != null) {
          // add listeners to preload the last 10 messages in the pod
          if (diff.type == DocumentChangeType.added)
            this._listenForPodMessageAddedChangedRemoved(
                podID: podID,
                onCompletion: () {
                  this.loadOlderPodMessagesIfNecessary(podID: podID, limitToLast: 9);
                });
          else if (diff.type == DocumentChangeType.removed) this._stopListeningToPodConversation(podID: podID);
        }
      });
    });
    _listenerRegistrationsDict["podListener"] = podMessageListeners;
  }

  ///Stop listening for messages from a pod if I'm removed or leave that pod
  void _stopListeningToPodConversation({required String podID}) {
    _listenerRegistrationsDict[podID]?.cancel();
    podMessageDict.value.removeWhere((key, value) => key == podID);
  }

  ///Gets a list of all pods where I've hidden the chat (to make sure that the chat doesn't get displayed when it
  ///shouldn't
  void preLoadListOfPodsImInactiveFrom() {
    // ignore: cancel_subscriptions
    final inactivePodsListener = firestoreDatabase
        .collectionGroup("members")
        .where("userID", isEqualTo: myFirebaseUserId)
        .where("active", isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      snapshot.docChanges.forEach((diff) {
        final podID = diff.doc.reference.parent.parent?.id;
        if (podID != null) {
          // if I hide a pod, add it to my hidden pods dictionary
          if (diff.type == DocumentChangeType.added) {
            var podsIveHidden = _podsIveHiddenDict; // copy the variable
            podsIveHidden[podID] = true; // modify it
            this._podsIveHiddenDict = podsIveHidden; // use the setter
          }
          // if I un-hide a pod, remove it from my hidden pods dictionary
          else if (diff.type == DocumentChangeType.removed) {
            var podsIveHidden = _podsIveHiddenDict; // copy the variable
            podsIveHidden.removeWhere((key, value) => key == podID); // modify it
            this._podsIveHiddenDict = podsIveHidden; // use the setter
          }
        }
      });
    });
    _listenerRegistrationsDict["podInactiveListener"] = inactivePodsListener;
  }

  ///First, get the last message in the conversation. Then add a listener to listen for new messages starting with
  ///that message. If a conversation is empty, simply add a listener to handle all messages in the conversation.
  void _listenForPodMessageAddedChangedRemoved({required String podID, required Function onCompletion}) {
    podMessageDict.value[podID]?.clear(); // clear all current messages from that pod prior to fetching new ones
    _listenerRegistrationsDict[podID]?.cancel(); // cancel the existing listener, if any (to be safe)

    ///First, get the last message in the conversation. Then, listen for new messages starting with that one. I'm
    ///using a stream subscription to allow reading from the cache to save reads.
    StreamSubscription? podMessageAddedListener;
    podMessageAddedListener = PodsDatabasePaths(podID: podID)
        .podDocument
        .collection("messages")
        .orderBy("systemTime")
        .limitToLast(1)
        .snapshots()
        .listen((snapshot) {
      podMessageAddedListener?.cancel(); //immediately cancel the subscription once I get the last message

      hasLoadedEveryMessageInConversationDictionary[podID] = snapshot.docs.length == 0; // if there are no
      // messages in the conversation, then I don't need to load any earlier ones.

      final lastDocument = snapshot.docs.last; // the query will return only one document anyway

      ///Limit the listener to messages where systemTime is greater than or equal to this cutoff to avoid duplicating
      /// messages and using extra reads. Optional double because the last document might not exist if a conversation
      /// has 0 documents.
      final timeCutoff = lastDocument.get("systemTime") as double?;

      // track the oldest document we downloaded so that future queries know to stop there and not re-fetch documents
      // we already got
      endBeforeDictionary[podID] = lastDocument;
      onCompletion(); // now that we have the last document, we can call the completion handler to then listen to
      // changes to the previous 9 documents without having to double-read those documents.

      final collectionRef = PodsDatabasePaths(podID: podID).podDocument.collection("messages").orderBy("systemTime");
      // Depending on whether the conversation exists, either subscribe to the entire conversation (if it doesn't
      // exist yet), or start subscribing to the newest message.
      final query = timeCutoff == null ? collectionRef : collectionRef.startAt([timeCutoff]);

      //Now, start an unlimited listener beginning with the last document that will handle it when new messages are
      // added or deleted.
      // ignore: cancel_subscriptions
      final messageAddedModifiedRemovedListener = query.snapshots().listen((snapshot) {
        snapshot.docChanges.forEach((diff) {
          if (diff.type == DocumentChangeType.added) {
            shouldChatLogScroll[podID] = true; // scroll to the bottom when a new message is added
            final data = diff.doc.data();
            final systemTime = diff.doc.get("systemTime") as double;
            final id = diff.doc.get("id") as String;
            final imageURL = data?["imageURL"] as String?;
            final imagePath = data?["imagePath"] as String?;
            final audioURL = data?["audioURL"] as String?;
            final audioPath = data?["audioPath"] as String?;
            final senderId = diff.doc.get("senderId") as String;
            final senderName = diff.doc.get("senderName") as String;
            final senderThumbnailURL = diff.doc.get("senderThumbnailURL") as String;
            final text = diff.doc.get("text") as String;

            final podMessage = ChatMessage(id: id, recipientId: "", recipientName: "", senderId: senderId,
                senderName: senderName, timeStamp: systemTime, text: text, senderThumbnailURL: senderThumbnailURL,
              recipientThumbnailURL: "", imageURL: imageURL, audioURL: audioURL, imagePath: imagePath, audioPath:
                audioPath, podID: podID);

            //Add the message to the associated chat partner ID in the dictionary
            if (podMessage.text.trim().isNotEmpty) {
              if (podMessageDict.value[podID] != null) {
                if (!podMessageDict.value[podID]!.contains(podMessage)) podMessageDict.value[podID]?.add(podMessage);
              }
            }
          } else if (diff.type == DocumentChangeType.modified) {
            final messageID = diff.doc.get("id") as String;
            final senderName = diff.doc.get("senderName") as String;
            final senderThumbnailURL = diff.doc.get("senderThumbnailURL") as String;
            podMessageDict.value[podID]?.changeSenderNameAndOrThumbnailURL(
                forMessageWithID: messageID, toNewName: senderName, toNewThumbnailURL: senderThumbnailURL);
          } else if (diff.type == DocumentChangeType.removed) {
            final messageID = diff.doc.get("id") as String;
            podMessageDict.value[podID]?.removeWhere((message) => message.id == messageID);
          }
        });
      });
      _listenerRegistrationsDict[podID] = messageAddedModifiedRemovedListener; // register the stream subscription so I
      // can remove it later
    });
  }

  ///Loads older pod messages if a user requests them and if the user hasn't already loaded the entire conversation.
  ///Uses a snapshot listener to enable reading from the cache if available.
  void loadOlderPodMessagesIfNecessary({required String podID, int limitToLast = 10}) {
    final numberOfMessages = limitToLast; // renaming for clarity inside the function body
    shouldChatLogScroll[podID] = false; // don't scroll the chat log to the bottom when loading older messages

    // if the user has scrolled up to load every message in the conversation already, don't attempt to load any more.
    final hasLoadedEveryMessageInConversation = hasLoadedEveryMessageInConversationDictionary[podID];
    if (hasLoadedEveryMessageInConversation != null) {
      if (hasLoadedEveryMessageInConversation) return;
    }

    // Make sure not to load any messages newer than this, as they have already been loaded.
    final endDocument = endBeforeDictionary[podID];
    if (endDocument != null) {
      areMoreMessagesLoadingDict.value[podID] = true; // indicate that more messages are loading
      // ignore: cancel_subscriptions
      final olderPodMessagesListener = PodsDatabasePaths(podID: podID)
          .podDocument
          .collection("messages")
          .orderBy("systemTime")
          .endBeforeDocument(endDocument)
          .limitToLast(numberOfMessages)
          .snapshots()
          .listen((snapshot) {
        // if the query returns fewer results than requested, we know that we've loaded every message in the
        // conversation and should not attempt to load any older messages
        hasLoadedEveryMessageInConversationDictionary[podID] = snapshot.docs.length < numberOfMessages;

        // track the oldest document we downloaded so that future queries know to stop there and not re-fetch
        // documents we already got
        endBeforeDictionary[podID] = snapshot.docs.first;

        snapshot.docChanges.forEach((diff) {
          final messageID = diff.doc.get("id") as String;
          final senderName = diff.doc.get("senderName") as String;
          final senderThumbnailURL = diff.doc.get("senderThumbnailURL") as String;

          if (diff.type == DocumentChangeType.added) {
            final systemTime = diff.doc.get("systemTime") as double;
            final imageURL = diff.doc.get("imageURL") as String;
            final imagePath = diff.doc.get("imagePath") as String;
            final audioURL = diff.doc.get("audioURL") as String;
            final audioPath = diff.doc.get("audioPath") as String;
            final senderId = diff.doc.get("senderId") as String;
            final text = diff.doc.get("text") as String;

            final podMessage = ChatMessage(id: messageID, recipientId: "", recipientName: "", senderId: senderId,
                senderName: senderName, timeStamp: systemTime, text: text, senderThumbnailURL: senderThumbnailURL,
                recipientThumbnailURL: "", imageURL: imageURL, audioURL: audioURL, imagePath: imagePath, audioPath:
                audioPath, podID: podID);

            //Add the message to the associated chat partner ID in the dictionary
            if (podMessage.text.trim().isNotEmpty) {
              if (podMessageDict.value[podID] != null) {
                if (!podMessageDict.value[podID]!.contains(podMessage)) podMessageDict.value[podID]?.add(podMessage);
              }
            }
          }

          // listen for messages removed from the conversation
          else if (diff.type == DocumentChangeType.modified) {
            podMessageDict.value[podID]?.changeSenderNameAndOrThumbnailURL(
                forMessageWithID: messageID, toNewName: senderName, toNewThumbnailURL: senderThumbnailURL);
          } else if (diff.type == DocumentChangeType.removed)
            podMessageDict.value[podID]?.removeWhere((message) => message.id == messageID);
        });
      });

      // give a unique registration to the listener so that it can be tracked and removed if needed
      final random = Random();

      ///random.nextInt(1000) will return a random integer between 0 and 999 (inclusive)
      final randomListenerID =
          random.nextInt(1000) + random.nextInt(1000) + random.nextInt(1000) + random.nextInt(1000);
      _listenerRegistrationsDict[podID + "$randomListenerID"] = olderPodMessagesListener;
    }
  }
}
