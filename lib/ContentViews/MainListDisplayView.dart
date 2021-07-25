import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:podsquad/BackendDataHolders/PodMembersDictionary.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/BackendDataclasses/PodMemberInfoDict.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/BackendFunctions/PodDataDownloaders.dart';
import 'package:podsquad/BackendFunctions/PronounFormatter.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/CreateAPodView.dart';
import 'package:podsquad/ContentViews/ViewPersonDetails.dart';
import 'package:podsquad/ContentViews/ViewPodDetails.dart';
import 'package:podsquad/DatabasePaths/PodsDatabasePaths.dart';
import 'package:podsquad/ListRowViews/PersonOrPodListRow.dart';
import 'package:podsquad/OtherSpecialViews/SearchTextField.dart';
import 'package:podsquad/TabLayoutViews/WelcomeView.dart';
import 'package:podsquad/UIBackendClasses/MainListDisplayBackend.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

class MainListDisplayView extends StatefulWidget {
  const MainListDisplayView(
      {Key? key,
      required this.viewMode,
      this.showingSentDataNotReceivedData = true,
      this.personData,
      this.personId,
      this.podData,
      this.personName,
      this.podMembers,
      this.podMemberships})
      : super(key: key);
  final String viewMode;
  final bool showingSentDataNotReceivedData;

  /// Used only if displaying a pod's members or blocked users.
  final PodData? podData;

  /// Used only if displaying a person's pod memberships.
  final String? personName;

  /// Used only if displaying a person's pod memberships (to determine if I'm looking at my own pods
  final String? personId;

  /// Used only if the viewMode is addPersonToPod
  final ProfileData? personData;

  /// Only needed if viewMode is equal to MainListDisplayViewModes.podMembers. Contains the members of a pod
  final List<ProfileData>? podMembers;

  /// Only needed if viewMode is equal to MainListDisplayViewModes.podMemberships. Contains a user's pod memberships.
  final List<PodData>? podMemberships;

  @override
  _MainListDisplayViewState createState() => _MainListDisplayViewState(
      viewMode: this.viewMode,
      showingSentDataNotReceivedData: this.showingSentDataNotReceivedData,
      personData: personData,
      personId: personId,
      podData: podData,
      personName: this.personName,
      podMembers: podMembers,
      podMemberships: podMemberships);
}

class _MainListDisplayViewState extends State<MainListDisplayView> {
  final String viewMode;
  final bool showingSentDataNotReceivedData;
  final PodData? podData;
  final String? personName;
  final String? personId;
  final ProfileData? personData;

  /// Only relevant if the view mode is podMembers. Shows the members of a pod.
  final List<ProfileData>? podMembers;

  /// Only relevant if the view mode is podMemberships. Shows a persons' pod memberships.
  final List<PodData>? podMemberships;

  final _searchTextController = TextEditingController();
  final _customScrollViewController = ScrollController();

  _MainListDisplayViewState(
      {required this.viewMode,
      required this.showingSentDataNotReceivedData,
      this.personData,
      this.personId,
      this.podData,
      this.personName,
      this.podMembers,
      this.podMemberships}) {
    this.isPodMode = viewMode == MainListDisplayViewModes.searchPods ||
        viewMode == MainListDisplayViewModes.myPods ||
        viewMode == MainListDisplayViewModes.podMemberships ||
        viewMode == MainListDisplayViewModes.addPersonToPod;
    this.interactingWithPodMembers =
        viewMode == MainListDisplayViewModes.podMembers || viewMode == MainListDisplayViewModes.podBlockedUsers;
  }

  /// Stores a list of people to display. Use this property if displaying people
  List<ProfileData> _listOfPeople = [];

  /// The actually-displayed list of people. Includes code to filter the list of people to include only the
  /// results where a part of the name or bio matches the search text.
  List<ProfileData> get _displayedListOfPeople {
    if (_searchTextController.text.trim().isEmpty)
      return _listOfPeople;
    else {
      final searchText = _searchTextController.text.trim();
      final filteredList = _listOfPeople
          .where((person) =>
              person.name.toLowerCase().contains(searchText.toLowerCase()) ||
              person.bio.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
      return filteredList;
    }
  }

  /// Stores a list of pods to display. Use this property if displaying pods
  List<PodData> _listOfPods = [];

  /// The actually-displayed list of pods. Includes code to filter the list of pods to include only the results
  /// where a part of the name or bio matches the search text.
  List<PodData> get _displayedListOfPods {
    if (_searchTextController.text.trim().isEmpty)
      return _listOfPods;
    else {
      final searchText = _searchTextController.text.trim();
      final filteredList = _listOfPods
          .where((pod) =>
              pod.name.toLowerCase().contains(searchText.toLowerCase()) ||
              pod.description.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
      return filteredList;
    }
  }

  /// This will be immediately initialized and changed if needed. Set to true if displaying pods.
  var isPodMode = false;

  /// Determine if we are displaying either pod members or blocked users from a pod. Will be immediately set when the
  /// class is initialized.
  var interactingWithPodMembers = false;

  /// Return either a standard PersonListRow or whether to include a Slidable for interacting with pod
  /// members.
  Widget _personListRow({required ProfileData person}) {
    // if we're just displaying a list of people with no interaction needed, return a PersonOrPodListRow object.
    // Also, even if we are displaying pod members, I can't block myself.
    if (!interactingWithPodMembers || person.userID == myFirebaseUserId) {
      if (viewMode != MainListDisplayViewModes.peopleIMet)
        return Card(
          color: _selectedIndex == _listOfPeople.indexWhere((element) => element == person)
              ? Colors.white60
              : CupertinoColors.systemBackground,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: PersonOrPodListRow(
              personOrPodID: person.userID,
              personOrPodName: person.name,
              personOrPodThumbnailURL: person.thumbnailURL,
              personOrPodBio: person.bio,
              timeIMetThePerson: person.timeIMetThePerson,
            ),
          ),
        );

      // if viewMode is peopleIMet, then make a Slidable with the option to un-meet someone
      else {
        return Slidable(
          child: Card(
            color: _selectedIndex == _listOfPeople.indexWhere((element) => element == person)
                ? Colors.white60
                : CupertinoColors.systemBackground,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: PersonOrPodListRow(
                personOrPodID: person.userID,
                personOrPodName: person.name,
                personOrPodThumbnailURL: person.thumbnailURL,
                personOrPodBio: person.bio,
                timeIMetThePerson: person.timeIMetThePerson,
              ),
            ),
          ),
          actionPane: SlidableDrawerActionPane(),
          actions: [
            // un-meet the person
            IconSlideAction(
              caption: "Un-Meet",
              color: CupertinoColors.destructiveRed,
              icon: CupertinoIcons.person_badge_minus,
              onTap: () {
                final unMeetPersonAlert = CupertinoAlertDialog(
                  title: Text("Un-Meet ${person.name}?"),
                  content: Text("You and ${person.name.firstName()} will no longer "
                      "appear in each other's People I Met lists."),
                  actions: [
                    CupertinoButton(
                        child: Text("No"),
                        onPressed: () {
                          dismissAlert(context: context);
                        }),
                    CupertinoButton(
                        child: Text(
                          "Yes",
                          style: TextStyle(color: CupertinoColors.destructiveRed),
                        ),
                        onPressed: () {
                          dismissAlert(context: context);
                          // find the one document that contains data for our meeting, and delete it.
                          // To find the document, we must use the fact that person1 is the lower ID alphabetically, and
                          // person 2 is the higher ID alphabetically.
                          final person1ID = myFirebaseUserId < person.userID ? myFirebaseUserId : person.userID;
                          final person2ID = myFirebaseUserId < person.userID ? person.userID : myFirebaseUserId;

                          firestoreDatabase
                              .collection("nearby-people")
                              .where("person1.userID", isEqualTo: person1ID)
                              .where("person2.userID", isEqualTo: person2ID)
                              .get()
                              .then((snapshot) {
                            // there should only be one document. Delete it.
                            snapshot.docs.forEach((document) {
                              document.reference.delete();
                            });
                          }).catchError((error) {
                            print("An error occurred while trying to un-meet someone: $error");
                          });
                        })
                  ],
                );
                showCupertinoDialog(context: context, builder: (context) => unMeetPersonAlert);
              },
            )
          ],
        );
      }
    } else {
      // If we're viewing pod members, then we must show the option to block or remove them. I'll arbitrarily put the
      // Remove button on the left and Block button on the right.
      if (viewMode == MainListDisplayViewModes.podMembers)
        return Slidable(
          child: Card(
            color: _selectedIndex == _listOfPeople.indexWhere((element) => element == person)
                ? Colors.white60
                : CupertinoColors.systemBackground,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: PersonOrPodListRow(
                personOrPodID: person.userID,
                personOrPodName: person.name,
                personOrPodThumbnailURL: person.thumbnailURL,
                personOrPodBio: person.bio,
                timeIMetThePerson: person.timeIMetThePerson,
              ),
            ),
          ),
          actionPane: SlidableDrawerActionPane(),
          actions: [
            // remove them from the pod if they aren't the pod creator
            IconSlideAction(
              caption: "Remove",
              color: CupertinoColors.systemBlue,
              icon: CupertinoIcons.person_badge_minus,
              onTap: () {
                final podID = podData?.podID;
                final podCreatorID = podData?.podCreatorID;
                if (podID != null && podCreatorID != null) {
                  // You can't remove the pod creator
                  if (person.userID != podCreatorID) {
                    final removeMemberAlert = CupertinoAlertDialog(
                      title: Text("Remove ${person.name}?"),
                      content: Text("Are you sure you want to proceed?"),
                      actions: [
                        CupertinoButton(
                            child: Text("No"),
                            onPressed: () {
                              dismissAlert(context: context);
                            }),
                        CupertinoButton(
                            child: Text(
                              "Yes",
                              style: TextStyle(color: CupertinoColors.destructiveRed),
                            ),
                            onPressed: () {
                              dismissAlert(context: context);
                              PodsDatabasePaths(podID: podID, userID: person.userID).leavePod(
                                  podName: podData?.name ?? "Pod",
                                  personName: person.name,
                                  onSuccess: () {
                                    final successAlert = CupertinoAlertDialog(
                                      title: Text("${person.name} Removed From ${podData?.name ?? "Pod"}"),
                                      actions: [
                                        CupertinoButton(
                                            child: Text("OK"),
                                            onPressed: () {
                                              // remove the person from the list
                                              setState(() {
                                                _listOfPeople.removeWhere((element) => element.userID == person.userID);
                                              });

                                              dismissAlert(context: context);
                                            })
                                      ],
                                    );
                                    showCupertinoDialog(context: context, builder: (context) => successAlert);
                                  });
                            })
                      ],
                    );
                    showCupertinoDialog(context: context, builder: (context) => removeMemberAlert);
                  }

                  // show a warning saying that you can't remove the pod creator
                  else {
                    final cantRemoveCreatorAlert = CupertinoAlertDialog(
                      title: Text("Cannot Remove ${person.name} "
                          "From ${podData?.name ?? "Pod"}"),
                      content: Text("The pod creator cannot be "
                          "removed."),
                      actions: [
                        CupertinoButton(
                            child: Text("OK"),
                            onPressed: () {
                              dismissAlert(context: context);
                            })
                      ],
                    );
                    showCupertinoDialog(context: context, builder: (context) => cantRemoveCreatorAlert);
                  }
                }
              },
            )
          ],
          secondaryActions: [
            // block them from the pod if they aren't the pod creator
            IconSlideAction(
              caption: "Block",
              color: CupertinoColors.destructiveRed,
              icon: CupertinoIcons.person_crop_circle_badge_xmark,
              onTap: () {
                final podID = podData?.podID;
                final podCreatorID = podData?.podCreatorID;
                if (podID != null && podCreatorID != null) {
                  // You can't block the pod creator
                  if (person.userID != podCreatorID) {
                    final blockAlert = CupertinoAlertDialog(
                      title: Text("Block ${person.name}"),
                      content: Text("Are "
                          "you sure you want to proceed?"),
                      actions: [
                        CupertinoButton(
                            child: Text("No"),
                            onPressed: () {
                              dismissAlert(context: context);
                            }),
                        CupertinoButton(
                            child: Text(
                              "Yes",
                              style: TextStyle(color: CupertinoColors.destructiveRed),
                            ),
                            onPressed: () {
                              dismissAlert(context: context);
                              PodsDatabasePaths(podID: podID, userID: person.userID).blockFromPod(
                                  podName: podData?.name ?? "Pod",
                                  personName: person.name,
                                  onSuccess: () {
                                    final successAlert = CupertinoAlertDialog(
                                      title: Text("${person.name} Blocked From ${podData?.name ?? "Pod"}"),
                                      actions: [
                                        CupertinoButton(
                                            child: Text("OK"),
                                            onPressed: () {
                                              // remove the person from the list
                                              setState(() {
                                                _listOfPeople.removeWhere((element) => element.userID == person.userID);
                                              });
                                              dismissAlert(context: context);
                                            })
                                      ],
                                    );
                                    showCupertinoDialog(context: context, builder: (context) => successAlert);
                                  });
                            })
                      ],
                    );
                    showCupertinoDialog(context: context, builder: (context) => blockAlert);
                  }

                  // show a warning saying that you can't block the pod creator
                  else {
                    final cantRemoveCreatorAlert = CupertinoAlertDialog(
                      title: Text("Cannot Block ${person.name} "
                          "From ${podData?.name ?? "Pod"}"),
                      content: Text("The pod creator cannot be "
                          "blocked."),
                      actions: [
                        CupertinoButton(
                            child: Text("OK"),
                            onPressed: () {
                              dismissAlert(context: context);
                            })
                      ],
                    );
                    showCupertinoDialog(context: context, builder: (context) => cantRemoveCreatorAlert);
                  }
                }
              },
            )
          ],
        );

      // If we're viewing pod blocked users, then we must show the option to unblock them. I'll put that button on
      // the right.
      else {
        return Slidable(
          child: Card(
            color: _selectedIndex == _listOfPeople.indexWhere((element) => element == person)
                ? Colors.white60
                : CupertinoColors.systemBackground,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: PersonOrPodListRow(
                personOrPodID: person.userID,
                personOrPodName: person.name,
                personOrPodThumbnailURL: person.thumbnailURL,
                personOrPodBio: person.bio,
                timeIMetThePerson: person.timeIMetThePerson,
              ),
            ),
          ),
          actionPane: SlidableDrawerActionPane(),
          secondaryActions: [
            // block them from the pod if they aren't the pod creator
            IconSlideAction(
              caption: "Unblock",
              color: CupertinoColors.activeGreen,
              icon: CupertinoIcons.lock_open,
              onTap: () {
                final podID = podData?.podID;
                if (podID != null) {
                  // unblock the user
                  final unblockAlert = CupertinoAlertDialog(
                    title: Text("Unblock ${person.name}"),
                    content: Text(
                        "Are you sure you want to proceed? ${person.name.firstName()} will become a member again."),
                    actions: [
                      CupertinoButton(
                          child: Text("No"),
                          onPressed: () {
                            dismissAlert(context: context);
                          }),
                      CupertinoButton(
                          child: Text("Yes"),
                          onPressed: () {
                            dismissAlert(context: context);
                            PodsDatabasePaths(podID: podID, userID: person.userID).unBlockFromPod(
                                personName: person.name,
                                onSuccess: () {
                                  final successAlert = CupertinoAlertDialog(
                                    title: Text("${person.name} Unblocked From ${podData?.name ?? "Pod"}"),
                                    actions: [
                                      CupertinoButton(
                                          child: Text("OK"),
                                          onPressed: () {
                                            // remove the person from the list
                                            setState(() {
                                              _listOfPeople.removeWhere((element) => element.userID == person.userID);
                                            });

                                            dismissAlert(context: context);
                                          })
                                    ],
                                  );
                                  showCupertinoDialog(context: context, builder: (context) => successAlert);
                                });
                          })
                    ],
                  );
                  showCupertinoDialog(context: context, builder: (context) => unblockAlert);
                }
              },
            )
          ],
        );
      }
    }
  }

  /// Determine which text to show in the navigation bar
  String navBarTitle({required String viewMode}) {
    switch (viewMode) {
      case MainListDisplayViewModes.myPods:
        {
          return "My Pods";
        }
      case MainListDisplayViewModes.peopleIMet:
        {
          return "People I Met";
        }

      case MainListDisplayViewModes.likes:
        {
          return "Likes";
        }
      case MainListDisplayViewModes.friends:
        {
          return "Friends";
        }
      case MainListDisplayViewModes.blocked:
        {
          return "Blocked Users";
        }
      case MainListDisplayViewModes.podMembers:
        {
          return "${podData?.name ?? "Pod"} Members";
        }
      case MainListDisplayViewModes.podBlockedUsers:
        {
          return "Blocked from ${podData?.name ?? "Pod"}";
        }
      case MainListDisplayViewModes.podMemberships:
        {
          return personId == myFirebaseUserId ? "My Pods" : "${personName ?? "User"}'s Pods";
        }
      case MainListDisplayViewModes.addPersonToPod:
        {
          return "Add ${personData?.name.firstName() ?? "User"} To Pod";
        }

      case MainListDisplayViewModes.searchUsers:
        {
          return "Search Users";
        }

      case MainListDisplayViewModes.searchPods:
        {
          return "Search Pods";
        }
      default:
        {
          return "Podsquad";
        }
    }
  }

  /// Use this for highlighting list items on tap
  int? _selectedIndex;

  /// Determine whether to show the search bar below the navigation bar
  var _searchBarShowing = false;

  /// Set to true if I am typing something into the search bar
  var isSearching = false;

  /// Set to true if I'm searching for a user or pod by name and the list is loading
  var isLoadingList = false;

  /// Assuming that the viewMode is addPersonToPod, then check if a person is already a member of a pod, and if not,
  /// give me the option to add them to the pod
  void _addPersonToPod({required ProfileData personData, required PodData podData}) async {
    if (viewMode != MainListDisplayViewModes.addPersonToPod) return;
    final isBlockedFromPod = await _checkIfPersonIsBlockedFromPod(podID: podData.podID, personID: personData.userID);
    final isMemberOfPod = await _checkIfPersonIsInPod(podID: podData.podID, personID: personData.userID);

    // if the person is blocked, show an alert saying why they can't be added
    if (isBlockedFromPod) {
      // unable to add [PERSON] to [POD]. They are blocked from [POD].
      final blockedAlert = CupertinoAlertDialog(
        title: Text("Unable to add $personName to ${podData.name}"),
        content: Text(
            "${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HeSheThey, shouldBeCapitalized: true)} ${PronounFormatter.isOrAre(pronoun: personData.preferredPronoun, shouldBeCapitalized: false)} blocked "
            "from ${podData.name}"),
        actions: [
          CupertinoButton(
              child: Text("OK"),
              onPressed: () {
                this._selectedIndex = null; // clear the selected index to remove the list highlight
                dismissAlert(context: context);
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => blockedAlert);
    }

    // if the person is in the pod, show an alert saying they're already in there.
    else if (isMemberOfPod) {
      final alreadyMemberAlert = CupertinoAlertDialog(
        title: Text("Cannot add ${personData.name} to ${podData.name}"),
        content: Text(
            "${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HeSheThey, shouldBeCapitalized: true)} ${PronounFormatter.isOrAre(pronoun: personData.preferredPronoun, shouldBeCapitalized: false)} already a member of ${podData.name}"),
        actions: [
          CupertinoButton(
              child: Text("OK"),
              onPressed: () {
                this._selectedIndex = null; // clear the selected index to remove the list highlight
                dismissAlert(context: context);
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => alreadyMemberAlert);
    }

    // if the person is neither blocked nor already a member, then add them
    else {
      final addMemberAlert = CupertinoAlertDialog(
        title: Text("Add ${personData.name} to ${podData.name}?"),
        content: Text("Are you sure you want to proceed?"),
        actions: [
          // Cancel button
          CupertinoButton(
            child: Text("No"),
            onPressed: () {
              this._selectedIndex = null; // clear the selected index to remove the list highlight
              dismissAlert(context: context);
            },
          ),

          // add them button
          CupertinoButton(
              child: Text("Yes"),
              onPressed: () {
                this._selectedIndex = null; // clear the selected index to remove the list highlight
                dismissAlert(context: context);
                final timeSinceEpochInSeconds = DateTime.now().millisecondsSinceEpoch * 0.001;
                final infoDict = PodMemberInfoDict(
                    userID: personData.userID,
                    bio: personData.bio,
                    birthday: personData.birthday,
                    joinedAt: timeSinceEpochInSeconds,
                    name: personData.name,
                    thumbnailURL: personData.thumbnailURL, fcmTokens: personData.fcmTokens);
                PodsDatabasePaths(podID: podData.podID, userID: personData.userID).joinPod(
                    personData: infoDict,
                    onSuccess: () {
                      final podMembers = PodMembersDictionary.sharedInstance.dictionary.value[podData.podID] ?? [];
                      if (!podMembers.contains(personData)) {
                        if (PodMembersDictionary.sharedInstance.dictionary.value[podData.podID] == null)
                          PodMembersDictionary.sharedInstance.dictionary.value[podData.podID] =
                              []; // initialize a list if necessary
                        PodMembersDictionary.sharedInstance.dictionary.value[podData.podID]?.add(personData);
                        PodMembersDictionary.sharedInstance.dictionary.notifyListeners();
                        PodMembersDictionary.sharedInstance.updateTheOtherDictionaries();
                      }

                      final successAlert = CupertinoAlertDialog(
                        title: Text("${personData.name} added to ${podData.name}"),
                        actions: [
                          CupertinoButton(
                              child: Text("OK"),
                              onPressed: () {
                                // no need to clear the selected index here; it was already cleared when the Yes button
                                // was tapped.
                                dismissAlert(context: context);
                              })
                        ],
                      );
                      showCupertinoDialog(context: context, builder: (context) => successAlert);
                    },
                    onError: (error) {
                      print("An error occurred while joining or adding someone to a pod :$error");
                    });
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => addMemberAlert);
    }
  }

  /// Assuming that the viewMode is addPersonToPod, then check if a person is blocked from a pod
  Future<bool> _checkIfPersonIsBlockedFromPod({required String podID, required String personID}) async {
    final task = PodDataDownloaders.sharedInstance.getPodBlockedUsers(podID: podID);
    final blockedUsers = await task;
    return blockedUsers.contains(personID);
  }

  /// Assuming that the viewMode is addPersonToPod, then check if a person is a member of a pod
  Future<bool> _checkIfPersonIsInPod({required String podID, required String personID}) async {
    final task = PodDataDownloaders.sharedInstance.getPodMembers(podID: podID);
    final members = await task;
    return members.contains(personID);
  }

  @override
  void initState() {
    super.initState();

    // show the search bar if the view mode is to search users or pods
    setState(() {
      if (viewMode == MainListDisplayViewModes.searchUsers || viewMode == MainListDisplayViewModes.searchPods)
        _searchBarShowing = true;
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

    // Determine when I'm searching for a person or pod
    _searchTextController.addListener(() {
      final text = _searchTextController.text;
      setState(() {
        this.isSearching = text.trim().isNotEmpty;
      });
    });

    // If the viewMode is podMembers, populate the list with the passed-in value (sorted alphabetically)
    if (viewMode == MainListDisplayViewModes.podMembers || viewMode == MainListDisplayViewModes.podBlockedUsers) {
      if (podMembers != null) {
        var sortedPodMembers = podMembers ?? [];
        sortedPodMembers.sort((a, b) => a.name.compareTo(b.name));
        this._listOfPeople = sortedPodMembers;
      }
    }

    // If the viewMode is podMemberships (the pods that a person is in), populate the list with the passed-in value
    // (sorted alphabetically)
    else if (viewMode == MainListDisplayViewModes.podMemberships) {
      if (podMemberships != null) {
        var sortedPodMemberships = podMemberships ?? [];
        sortedPodMemberships.sort((a, b) => a.name.compareTo(b.name));
        this._listOfPods = sortedPodMemberships;
      }
    }

    // If the viewMode is addPersonToPod or myPods, display the list of pods I'm in
    else if (viewMode == MainListDisplayViewModes.myPods || viewMode == MainListDisplayViewModes.addPersonToPod) {
      final myPods = ShowMyPodsBackendFunctions.shared.sortedListOfPods.value;
      this._listOfPods = myPods;

      // also continuously listen in case I join or leave a pod
      ShowMyPodsBackendFunctions.shared.sortedListOfPods.addListener(() {
        final myPods = ShowMyPodsBackendFunctions.shared.sortedListOfPods.value;
        setState(() {
          this._listOfPods = myPods;
        });
      });
    }

    // If the viewMode is Likes, then display the list of people I like or the list of people who like me
    else if (viewMode == MainListDisplayViewModes.likes) {
      if (showingSentDataNotReceivedData) {
        final sentLikes = SentLikesBackendFunctions.shared.sortedListOfPeople.value;
        this._listOfPeople = sentLikes;

        // also continuously listen in case I like someone while the view is open
        SentLikesBackendFunctions.shared.sortedListOfPeople.addListener(() {
          final sentLikes = SentLikesBackendFunctions.shared.sortedListOfPeople.value;
          setState(() {
            this._listOfPeople = sentLikes;
          });
        });
      } else {
        final receivedLikes = ReceivedLikesBackendFunctions.shared.sortedListOfPeople.value;
        this._listOfPeople = receivedLikes;

        // also continuously listen in case someone likes me while the view is open
        ReceivedLikesBackendFunctions.shared.sortedListOfPeople.addListener(() {
          final receivedLikes = ReceivedLikesBackendFunctions.shared.sortedListOfPeople.value;
          setState(() {
            this._listOfPeople = receivedLikes;
          });
        });
      }
    }

    // If the viewMode is Friends, then display the list of people I friended or the list of people who friended me
    else if (viewMode == MainListDisplayViewModes.friends) {
      if (showingSentDataNotReceivedData) {
        final sentFriends = SentFriendsBackendFunctions.shared.sortedListOfPeople.value;
        this._listOfPeople = sentFriends;

        // also continuously listen in case I friend someone while the view is open
        SentFriendsBackendFunctions.shared.sortedListOfPeople.addListener(() {
          final sentFriends = SentFriendsBackendFunctions.shared.sortedListOfPeople.value;
          setState(() {
            this._listOfPeople = sentFriends;
          });
        });
      } else {
        final receivedFriends = ReceivedFriendsBackendFunctions.shared.sortedListOfPeople.value;
        this._listOfPeople = receivedFriends;

        // also continuously listen in case someone friends me while the view is open
        ReceivedFriendsBackendFunctions.shared.sortedListOfPeople.addListener(() {
          final receivedFriends = ReceivedFriendsBackendFunctions.shared.sortedListOfPeople.value;
          setState(() {
            this._listOfPeople = receivedFriends;
          });
        });
      }
    }

    // If the viewMode is Blocked, then display the list of people I blocked or the list of people who blocked me
    else if (viewMode == MainListDisplayViewModes.blocked) {
      if (showingSentDataNotReceivedData) {
        final sentBlocks = SentBlocksBackendFunctions.shared.sortedListOfPeople.value;
        this._listOfPeople = sentBlocks;

        // also continuously listen in case I block someone while the view is open
        SentBlocksBackendFunctions.shared.sortedListOfPeople.addListener(() {
          final sentBlocks = SentBlocksBackendFunctions.shared.sortedListOfPeople.value;
          setState(() {
            this._listOfPeople = sentBlocks;
          });
        });
      } else {
        final receivedBlocks = ReceivedBlocksBackendFunctions.shared.sortedListOfPeople.value;
        this._listOfPeople = receivedBlocks;

        // also continuously listen in case someone blocks me while the view is open
        ReceivedBlocksBackendFunctions.shared.sortedListOfPeople.addListener(() {
          final receivedBlocks = ReceivedBlocksBackendFunctions.shared.sortedListOfPeople.value;
          setState(() {
            this._listOfPeople = receivedBlocks;
          });
        });
      }
    }

    // If the viewMode is peopleIMet, then display the list of people I met
    else if (viewMode == MainListDisplayViewModes.peopleIMet) {
      final peopleIMet = PeopleIMetBackendFunctions.shared.sortedListOfPeople.value;
      this._listOfPeople = peopleIMet;

      // also continuously listen in case I meet someone while the view is open
      PeopleIMetBackendFunctions.shared.sortedListOfPeople.addListener(() {
        final peopleIMet = PeopleIMetBackendFunctions.shared.sortedListOfPeople.value;
        setState(() {
          this._listOfPeople = peopleIMet;
        });
      });
    }
  }

  /// Search for a user or pod by name, depending on the view mode
  Future<void> searchForUserOrPodByName({required String matching}) async {
    List<ProfileData> listOfPeopleResults = [];
    List<PodData> listOfPodResults = [];
    final searchText = matching.trim();

    /// This is the private use code point that is not assigned to any character. When an endBefore query is added
    /// with this as the value, it ensures that only the intended results get queried.
    final endBeforeText = searchText + "\u{F8FF}";

    if (searchText.isEmpty) return; // don't query if the search text is empty
    // do the query. It will either search the Users collection or the Pods collection, depending on which mode the
    // view is displaying
    final query = viewMode == MainListDisplayViewModes.searchUsers
        ? await firestoreDatabase
            .collection("users")
            .where("profileData.name", isGreaterThanOrEqualTo: searchText)
            .where("profileData.name", isLessThan: endBeforeText)
            .orderBy("profileData.name")
            .get()
        : await firestoreDatabase
            .collection("pods")
            .where("profileData.name", isGreaterThanOrEqualTo: searchText)
            .where("profileData.name", isLessThan: endBeforeText)
            .orderBy("profileData.name")
            .get();

    // show an alert saying no results found
    if (query.docs.length == 0) {
      final alert = CupertinoAlertDialog(
        title: Text("No Results Found"),
        content: Text("Searches are case-sensitive. Check your spelling and capitalization and try again"),
        actions: [
          CupertinoButton(
              child: Text("OK"),
              onPressed: () {
                dismissAlert(context: context);
              })
        ],
      );
      showCupertinoDialog(context: context, builder: (context) => alert);
      if (isPodMode)
        this._listOfPods = [];
      else
        this._listOfPeople = [];
      return; // no need to continue if no results are found
    }

    // otherwise, get the data for each person
    else if (viewMode == MainListDisplayViewModes.searchUsers) {
      query.docs.forEach((document) {
        final String userID = document.id;
        final profileDataRaw = document.get("profileData");
        final docData = document.data();
        final tokensRaw = docData["fcmTokens"] as List<dynamic>? ?? [];
        final tokens = List<String>.from(tokensRaw);
        final profileData = _extractPersonData(profileData: profileDataRaw, userID: userID, fcmTokens: tokens);
        if (!listOfPeopleResults.contains(profileData)) listOfPeopleResults.add(profileData);
      });
    }

    // otherwise, get the data for each pod
    else if (viewMode == MainListDisplayViewModes.searchPods) {
      query.docs.forEach((document) {
        final String podID = document.id;
        final data = document.get("profileData"); // this isn't a typo - pod data is titled "profileData" in the
        // database because it's the profile data for the pod.
        final podData = _extractPodData(podData: data, podID: podID);
        if (!listOfPodResults.contains(podData)) listOfPodResults.add(podData);
      });
    }

    if (isPodMode)
      listOfPodResults.sort((a, b) => a.name.compareTo(b.name)); // sort alphabetically
    else
      listOfPeopleResults.sort((a, b) => a.name.compareTo(b.name)); // sort alphabetically

    // finally, update the displayed list
    setState(() {
      if (isPodMode)
        _listOfPods = listOfPodResults;
      else
        _listOfPeople = listOfPeopleResults;
    });
  }

  /// Get a person's data given a map of type <String, dynamic>
  ProfileData _extractPersonData({required Map profileData, required List<String> fcmTokens, required String userID}) {
    final String thumbnailURL = profileData["photoThumbnailURL"];
    final String fullPhotoURL = profileData["fullPhotoURL"];
    final String name = profileData["name"];
    final String? preferredPronoun = profileData["preferredPronouns"];
    final String? preferredRelationshipType = profileData["lookingFor"];
    final num birthdayRaw = profileData["birthday"];
    final birthday = birthdayRaw.toDouble();
    final String school = profileData["school"];
    final String? bio = profileData["bio"];
    final num? podScoreRaw = profileData["podScore"] as num;
    final int? podScore = podScoreRaw?.toInt();

    final personData = ProfileData(
        userID: userID,
        name: name,
        preferredPronoun: preferredPronoun ?? UsefulValues.nonbinaryPronouns,
        preferredRelationshipType: preferredRelationshipType ?? UsefulValues.lookingForFriends,
        birthday: birthday,
        school: school,
        bio: bio ?? "",
        podScore: podScore ?? 0,
        thumbnailURL: thumbnailURL,
        fullPhotoURL: fullPhotoURL, fcmTokens: fcmTokens);
    return personData;
  }

  /// Get a pod's data given a map of type <String, dynamic>
  PodData _extractPodData({required Map podData, required String podID}) {
    final String thumbnailURL = podData["thumbnailURL"];
    final String thumbnailPath = podData["thumbnailPath"];
    final String fullPhotoURL = podData["fullPhotoURL"];
    final String fullPhotoPath = podData["fullPhotoPath"];
    final String podName = podData["name"];
    final num dateCreatedRaw = podData["dateCreated"];
    final double dateCreated = dateCreatedRaw.toDouble();
    final String description = podData["description"];
    final bool anyoneCanJoin = podData["anyoneCanJoin"];
    final String podCreatorID = podData["podCreatorID"];
    final num podScoreRaw = podData["podScore"];
    final int podScore = podScoreRaw.toInt();

    final data = PodData(
        name: podName,
        dateCreated: dateCreated,
        description: description,
        anyoneCanJoin: anyoneCanJoin,
        podID: podID,
        podCreatorID: podCreatorID,
        thumbnailURL: thumbnailURL,
        thumbnailPath: thumbnailPath,
        fullPhotoURL: fullPhotoURL,
        fullPhotoPath: fullPhotoPath,
        podScore: podScore);
    return data;
  }

  /// Creates the trailing widget on the navigation bar, depending on the view mode
  Widget navBarTrailing() {
    if (viewMode == MainListDisplayViewModes.addPersonToPod)
      return CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.plus),
          onPressed: () {
            // Navigate to create a pod
            Navigator.of(context, rootNavigator: true)
                .push(CupertinoPageRoute(builder: (context) => CreateAPodView(isCreatingNewPod: true)))
                .then((value) {
              setState(() {
                this._selectedIndex = null;
              });
            });
          });
    else
      return Container(width: 0, height: 0);
  }

  /// Show a back button if I should be allowed to go back. If the view is people I met (in the main tab view), then
  /// show the button to open the action sheet to view likes/friends/blocks
  Widget backButton() {
    if (viewMode != MainListDisplayViewModes.peopleIMet && viewMode != MainListDisplayViewModes.myPods)
      return CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.chevron_back,
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          });
    else
      return CupertinoButton(
        child: Icon(CupertinoIcons.line_horizontal_3),
        onPressed: () {
          drawerKey.currentState?.openDrawer(); // open the likes/friends/blocks drawer;
        },
        padding: EdgeInsets.zero,
      );
  }

  @override
  void dispose() {
    super.dispose();
    _customScrollViewController.removeListener(() {});
    if (viewMode == MainListDisplayViewModes.myPods)
      ShowMyPodsBackendFunctions.shared.sortedListOfPods.removeListener(() {});
    else if (viewMode == MainListDisplayViewModes.likes && showingSentDataNotReceivedData)
      SentLikesBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    else if (viewMode == MainListDisplayViewModes.likes && !showingSentDataNotReceivedData)
      ReceivedLikesBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    else if (viewMode == MainListDisplayViewModes.friends && showingSentDataNotReceivedData)
      SentFriendsBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    else if (viewMode == MainListDisplayViewModes.friends && !showingSentDataNotReceivedData)
      ReceivedFriendsBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    else if (viewMode == MainListDisplayViewModes.blocked && showingSentDataNotReceivedData)
      SentBlocksBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    else if (viewMode == MainListDisplayViewModes.blocked && !showingSentDataNotReceivedData)
      ReceivedBlocksBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    else if (viewMode == MainListDisplayViewModes.peopleIMet)
      PeopleIMetBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    _selectedIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: CustomScrollView(
          controller: _customScrollViewController,
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverNavigationBar(
              padding: viewMode != MainListDisplayViewModes.peopleIMet
                  ? EdgeInsetsDirectional.zero
                  : EdgeInsetsDirectional.all(5),
              largeTitle: Text(navBarTitle(viewMode: viewMode)),
              leading: backButton(),
              trailing: navBarTrailing(),
              stretch: true,
            ),
            SliverList(
                delegate: SliverChildListDelegate([
              // will contain content
              Column(
                children: [
                  // Collapsible search bar. The reason I must use CupertinoTextField instead of
                  // CupertinoSearchTextField (the
                  // themed search bar) is that CupertinoSearchTextField does not have a text auto-capitalization property,
                  // meaning that by default, letters are always lower-cased. This might cause confusion for users, as they
                  // would have to manually capitalize their searches every time. It's much easier for them if the text field
                  // auto-capitalizes for them, which is why I'm using a regular CupertinoTextField for now.
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
                                onSubmitted: (searchText) {
                                  if (viewMode == MainListDisplayViewModes.searchUsers ||
                                      viewMode == MainListDisplayViewModes.searchPods)
                                    this.searchForUserOrPodByName(matching: searchText);
                                },
                                onClearButtonPressed: () {
                                  // clear the search results if the "x" is tapped
                                  if (viewMode == MainListDisplayViewModes.searchUsers)
                                    setState(() {
                                      _listOfPeople.clear();
                                    });
                                  if (viewMode == MainListDisplayViewModes.searchPods)
                                    setState(() {
                                      _listOfPods.clear();
                                    });
                                },
                              ))
                          : Container()),

                  // show a list of people
                  if (!isPodMode)
                    for (var person in _displayedListOfPeople)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            // highlight the row
                            this._selectedIndex = this._listOfPeople.indexWhere((element) => element == person);
                          });
                          // navigate to view the person's details
                          Navigator.of(context, rootNavigator: true)
                              .push(
                                  CupertinoPageRoute(builder: (context) => ViewPersonDetails(personID: person.userID)))
                              .then((value) {
                            setState(() {
                              this._selectedIndex = null; // clear the selected index to remove row highlighting
                            });
                          });
                        },
                        child: _personListRow(person: person),
                      ),

                  // show a list of pods
                  if (isPodMode)
                    for (var pod in _displayedListOfPods)
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              // highlight the row
                              this._selectedIndex = this._listOfPods.indexWhere((element) => element == pod);
                            });

                            // navigate to view pod details
                            if (viewMode != MainListDisplayViewModes.addPersonToPod)
                              Navigator.of(context, rootNavigator: true)
                                  .push(CupertinoPageRoute(
                                      builder: (context) => ViewPodDetails(
                                            podID: pod.podID,
                                            showChatButton: true,
                                          )))
                                  .then((value) {
                                setState(() {
                                  this._selectedIndex = null; // clear the selected index to remove row highlighting
                                });
                              });

                            // show a dialog allowing me to add the person to a pod
                            else {
                              final personData = this.personData;
                              if (personData != null) this._addPersonToPod(personData: personData, podData: pod);
                            }

                            // add the person to the pod
                          },
                          child: Card(
                            color: _selectedIndex == _listOfPods.indexWhere((element) => element == pod)
                                ? Colors.white60
                                : CupertinoColors.systemBackground,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: PersonOrPodListRow(
                                  personOrPodID: pod.podID,
                                  personOrPodName: pod.name,
                                  personOrPodThumbnailURL: pod.thumbnailURL,
                                  personOrPodBio: pod.description),
                            ),
                          )),

                  if (!isPodMode && this._displayedListOfPeople.isEmpty)
                    Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          isSearching ? "No results found" : "Nobody to display",
                          style: TextStyle(color: CupertinoColors.inactiveGray),
                        )),

                  if (isPodMode && this._displayedListOfPods.isEmpty)
                    Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          isSearching ? "No results found" : "No pods to display",
                          style: TextStyle(color: CupertinoColors.inactiveGray),
                        )),
                ],
              ),
            ]))
          ],
        ),
      ),
    );
  }
}
