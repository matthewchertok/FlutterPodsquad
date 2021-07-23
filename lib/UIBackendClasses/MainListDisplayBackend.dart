import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/BackendFunctions/GetPeopleIMetLikesFriendsBlockedData.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';

///Backend functions for MainListDisplayView. For the showingSentDataNotReceivedData parameter, be sure to use a
///static instance of the MainListDisplayViewModes class.
abstract class MainListDisplayBackend {
  ///Determine whether we're displaying likes, friends, people I met, etc.
  final String viewMode;

  ///pass in true if showing a list of either likes I sent, friends I sent, or blocks I sent. Pass in false is
  ///showing a list of likes I received, friends I received, or blocks I received.
  final bool showingSentDataNotReceivedData;

  // Class constructor
  MainListDisplayBackend({required this.viewMode, required this.showingSentDataNotReceivedData});

  ///If viewing blocked members for a pod, change the image from locked to unlocked for a person if I tap it, then
  ///back to locked if I choose not to unblocked the person. Maps {userID: lock_image}.
  var _lockIconDictionary = Map<String?, Image>();

  //Important variable!
  ///The list of people to be displayed in the specified view.
  ValueNotifier<List<ProfileData>> sortedListOfPeople = ValueNotifier([]);

  /// Use this essentially as a setter for sortedListOfPeople. Update this value, and sortedListOfPeople will
  /// automatically return the sorted results.
  List<ProfileData> listOfPeople = [];

  //Important variable!
  ///The list of pods to be displayed in the specified view, if the view type is myPods.
  ValueNotifier<List<PodData>> sortedListOfPods  = ValueNotifier([]);

  /// Use this essentially as a setter for sortedListOfPods. Update this value, and sortedListOfPods will
  /// automatically return the sorted results.
  List<PodData> listOfPods = [];

  /// Use this to convert listOfPods into sortedListOfPods
  void sortListOfPods(){
    // For a custom list, there is no need to sort it (although this case isn't used yet so don't worry about it)
    if (this.viewMode == MainListDisplayViewModes.customList)
      sortedListOfPods.value = listOfPods;

    // When viewing the members of a pod or viewing the list of pods I'm in, sort the list alphabetically by name.
    else {
      listOfPods.sort((a, b) => a.name.compareTo(b.name));
      sortedListOfPods.value = listOfPods;
    }
  }

  ///Shows "you haven't friended/blocked/liked anybody yet" when set to true
  ValueNotifier<bool> isShowingNobodyFound = ValueNotifier(false);

  ///Determine whether I've downloaded the data for the specified list. Set to true once the data is downloaded to
  ///hide the loading bar.
  ValueNotifier<bool> didGetData = ValueNotifier(false);

  ///A list of every stream subscription I registered. Use this list to remove all subscriptions when reset() is called.
  List<StreamSubscription> _listenerRegistrations = [];

  /// Take listOfPeople and sort it in order to make sortedListOfPeople
  void sortListOfPeople() {
    // For a custom list, there is no need to sort it (although this case isn't used yet so don't worry about it)
    if (this.viewMode == MainListDisplayViewModes.customList)
      sortedListOfPeople.value = listOfPeople;

    // When viewing the members of a pod or viewing the list of pods I'm in, sort the list alphabetically by name.
    else if (this.viewMode == MainListDisplayViewModes.podMembers || this.viewMode == MainListDisplayViewModes.myPods) {
      listOfPeople.sort((a, b) => a.name.compareTo(b.name));
      sortedListOfPeople.value = listOfPeople;
    }

    // For all other cases, sort the list in descending order based on the time I met the person.
    else {
      listOfPeople.sort((b, a) => (a.timeIMetThePerson ?? 0).compareTo(b.timeIMetThePerson ?? 0));
      sortedListOfPeople.value = listOfPeople;
    }
  }

  ///Resets the shared instance when the user signs out
  void reset() {
    _listenerRegistrations.forEach((streamSubscription) {
      streamSubscription.cancel();
    });
    _listenerRegistrations.clear();

    _lockIconDictionary.clear();
    listOfPeople.clear();
    isShowingNobodyFound.value = false;
    didGetData.value = false;
  }

  //TODO: start translating code from line 91 - addDataToListView()
  ///Checks if there is any data to display in the list and get the data, if applicable. If not, show a message that
  ///no users were found.
  void addDataToListView() {
    _getDataBasedOnListType(viewMode: viewMode);
  }

  ///This is the important function that gets data to fill the list that will be displayed. Pass in a static member
  ///of MainListDisplayViewModes for the viewMode parameter.
  void _getDataBasedOnListType({required String viewMode}) {
    // clear the lists of people to avoid duplicates (to be safe)
    listOfPeople.clear();
    switch (viewMode) {
      case MainListDisplayViewModes.likes:
        {
          if (showingSentDataNotReceivedData)
            _getTheData(collectionName: "likes", fieldEqualToMyID: "liker.userID");
          else
            _getTheData(collectionName: "likes", fieldEqualToMyID: "likee.userID");
          break;
        }
      case MainListDisplayViewModes.friends:
        {
          if (showingSentDataNotReceivedData)
            _getTheData(collectionName: "friends", fieldEqualToMyID: "friender.userID");
          else
            _getTheData(collectionName: "friends", fieldEqualToMyID: "friendee.userID");
          break;
        }
      case MainListDisplayViewModes.blocked:
        {
          if (showingSentDataNotReceivedData)
            _getTheData(collectionName: "blocked-users", fieldEqualToMyID: "blocker.userID");
          else
            _getTheData(collectionName: "blocked-users", fieldEqualToMyID: "blockee.userID");
          break;
        }
      case MainListDisplayViewModes.peopleIMet:
        {
          _getTheData(collectionName: "nearby-people", fieldEqualToMyID: "people");
          break;
        }
      case MainListDisplayViewModes.myPods:
        {
          _getTheData(collectionName: "pods", fieldEqualToMyID: "userID");
        }
    }
  }

  ///Calls the correct query on getData.getListData to handle adding data to a list. The function uses the query
  ///firestoreDatabase.collection(collectionName).where(fieldEqualToMyID, isEqualTo: myFirebaseUserId)... to get the
  ///data. For example, to get a list of everyone that I liked, pass in "likes" for collectionName and "liker.userID"
  /// for fieldEqualToMyID. Pass in "pods" to query the list of pods I"m in.
  void _getTheData({required String collectionName, required String fieldEqualToMyID}) {
    Query? query;
    // if querying for people I met
    if (collectionName == "nearby-people")
      query = firestoreDatabase.collection("nearby-people").where("people", arrayContains: myFirebaseUserId);

    // if querying for pods I'm in (be sure to call doc.parent.parent)
    else if (collectionName == "pods")
      query = firestoreDatabase.collectionGroup("members").where("userID", isEqualTo: myFirebaseUserId);

    // if querying for anything else (i.e. likes, friends, blocks)
    else
      query = firestoreDatabase.collection(collectionName).where(fieldEqualToMyID, isEqualTo: myFirebaseUserId);

    // Get the data based on the query.
    if (collectionName != "pods") {
      final getData = GetPeopleIMetLikesFriendsBlockedData();

      getData.getListDataForPeopleILikedFriendedBlockedOrMet(
          query: query,
          dataType: viewMode,
          isGettingDataForPeopleIMetList: collectionName == "nearby-people",
          onChildAdded: () {
            // add the person to the displayed list
            if (!listOfPeople.contains(getData.profileData)) {
              listOfPeople.add(getData.profileData);
              this.sortListOfPeople();
              sortedListOfPeople.notifyListeners(); // notify the views that data has changed
            }
          },
          onChildChanged: () {
            // remove the old entry and replace it with the new one
            listOfPeople.removeWhere((person) => person.userID == getData.changedChildID);
            if (!listOfPeople.contains(getData.profileData)) {
              listOfPeople.add(getData.profileData);
              this.sortListOfPeople();
              sortedListOfPeople.notifyListeners(); // notify the views that data has changed
            }
          },
          onChildRemoved: () {
            // remove the person from the list
            listOfPeople.removeWhere((person) => person.userID == getData.removedChildID);
            this.sortListOfPeople();
            sortedListOfPeople.notifyListeners(); // notify the views that data has changed
          },
          onValueChanged: () {
            // if there is no data to show, display "you haven't met anyone yet" (or whatever the message should be for
            // the view type)
            if (getData.numberOfDocumentsInQuery == 0)
              isShowingNobodyFound.value = true;
            else
              isShowingNobodyFound.value = false;

            // update my podScore with the formula: score = 10*(logBase2(peopleIMet+1))^1.2 if viewing people I met
            if (viewMode == MainListDisplayViewModes.peopleIMet) {
              final int numberOfPeopleIMet = getData.numberOfDocumentsInQuery ?? 0;
              final myPodScore = 10 * pow(logWithBase(base: 1.2, x: (numberOfPeopleIMet + 1).toDouble()), 1.2);
              firestoreDatabase.collection("users").doc(myFirebaseUserId).set({
                "profileData": {"podScore": myPodScore}
              }, SetOptions(merge: true));
            }
          });
    } else {
      final getData = GetPeopleIMetLikesFriendsBlockedData();
      getData.getListDataForPodsImIn(
          query: query,
          onChildAdded: () {
            if (!listOfPods.contains(getData.podData)) {
              listOfPods.add(getData.podData);
              sortListOfPods();
            }
          },
          onChildChanged: () {
            // remove the old entry and replace it with the new one
            listOfPods.removeWhere((pod) => pod.podID == getData.changedChildID);
            if (!listOfPods.contains(getData.podData)) {
              listOfPods.add(getData.podData);
              sortListOfPods();
            }
          },
          onChildRemoved: () {
            listOfPods.removeWhere((pod) => pod.podID == getData.removedChildID);
            sortListOfPods();
          },
          onValueChanged: () {
            // if there is no data to show, display "you aren't in any pods yet"
            if (getData.numberOfDocumentsInQuery == 0)
              isShowingNobodyFound.value = true;
            else
              isShowingNobodyFound.value = false;
          });
    }
  }
}

/// Backend functions for people I like
class SentLikesBackendFunctions extends MainListDisplayBackend {
  SentLikesBackendFunctions() : super(viewMode: MainListDisplayViewModes.likes, showingSentDataNotReceivedData: true);
  static final shared = SentLikesBackendFunctions();
}

/// Backend functions for people who like me
class ReceivedLikesBackendFunctions extends MainListDisplayBackend {
  ReceivedLikesBackendFunctions()
      : super(viewMode: MainListDisplayViewModes.likes, showingSentDataNotReceivedData: false);
  static final shared = ReceivedLikesBackendFunctions();
}

/// Backend functions for people I friended
class SentFriendsBackendFunctions extends MainListDisplayBackend {
  SentFriendsBackendFunctions()
      : super(viewMode: MainListDisplayViewModes.friends, showingSentDataNotReceivedData: true);
  static final shared = SentFriendsBackendFunctions();
}

/// Backend functions for people who friended me
class ReceivedFriendsBackendFunctions extends MainListDisplayBackend {
  ReceivedFriendsBackendFunctions()
      : super(viewMode: MainListDisplayViewModes.friends, showingSentDataNotReceivedData: false);
  static final shared = ReceivedFriendsBackendFunctions();
}

/// Backend functions for people I blocked
class SentBlocksBackendFunctions extends MainListDisplayBackend {
  SentBlocksBackendFunctions()
      : super(viewMode: MainListDisplayViewModes.blocked, showingSentDataNotReceivedData: true);
  static final shared = SentBlocksBackendFunctions();
}

/// Backend functions for people who blocked me
class ReceivedBlocksBackendFunctions extends MainListDisplayBackend {
  ReceivedBlocksBackendFunctions()
      : super(viewMode: MainListDisplayViewModes.blocked, showingSentDataNotReceivedData: false);
  static final shared = ReceivedBlocksBackendFunctions();
}

/// Backend functions for people I met
class PeopleIMetBackendFunctions extends MainListDisplayBackend {
  PeopleIMetBackendFunctions()
      : super(viewMode: MainListDisplayViewModes.peopleIMet, showingSentDataNotReceivedData: true);
  static final shared = PeopleIMetBackendFunctions();
}

/// Backend functions for getting the list of pods I'm in
class ShowMyPodsBackendFunctions extends MainListDisplayBackend {
  ShowMyPodsBackendFunctions() : super(viewMode: MainListDisplayViewModes.myPods, showingSentDataNotReceivedData: true);
  static final shared = ShowMyPodsBackendFunctions();
}
