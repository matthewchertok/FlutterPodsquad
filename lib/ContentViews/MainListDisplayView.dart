import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:podsquad/BackendFunctions/ShowLikesFriendsBlocksActionSheet.dart';
import 'package:podsquad/OtherSpecialViews/PodModeButton.dart';
import 'package:podsquad/OtherSpecialViews/SearchTextField.dart';
import 'package:podsquad/UIBackendClasses/MainListDisplayBackend.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

class MainListDisplayView extends StatefulWidget {
  const MainListDisplayView({Key? key,
    required this.viewMode,
    this.showingSentDataNotReceivedData = true,
    this.personData,
    this.personId,
    this.podName,
    this.personName,
    this.podMembers,
    this.podMemberships})
      : super(key: key);
  final String viewMode;
  final bool showingSentDataNotReceivedData;

  /// Used only if displaying a pod's members.
  final String? podName;

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
  _MainListDisplayViewState createState() =>
      _MainListDisplayViewState(
          viewMode: this.viewMode,
          showingSentDataNotReceivedData: this.showingSentDataNotReceivedData,
          personData: personData,
          personId: personId,
          podName: this.podName,
          personName: this.personName,
          podMembers: podMembers,
          podMemberships: podMemberships);
}

class _MainListDisplayViewState extends State<MainListDisplayView> {
  final String viewMode;
  final bool showingSentDataNotReceivedData;
  final String? podName;
  final String? personName;
  final String? personId;
  final ProfileData? personData;

  /// Only relevant if the view mode is podMembers. Shows the members of a pod.
  final List<ProfileData>? podMembers;

  /// Only relevant if the view mode is podMemberships. Shows a persons' pod memberships.
  final List<PodData>? podMemberships;

  final _searchTextController = TextEditingController();
  final _customScrollViewController = ScrollController();

  _MainListDisplayViewState({required this.viewMode,
    required this.showingSentDataNotReceivedData,
    this.personData,
    this.personId,
    this.podName,
    this.personName,
    this.podMembers,
    this.podMemberships}) {
    this.isPodMode = viewMode == MainListDisplayViewModes.searchPods ||
        viewMode == MainListDisplayViewModes.myPods ||
        viewMode == MainListDisplayViewModes.podMemberships ||
        viewMode == MainListDisplayViewModes.addPersonToPod;
  }

  /// Stores a list of people to display. Use this property if displaying people
  List<ProfileData> _listOfPeople = [];

  /// The actually-displayed list of people. Includes code to filter the list of people to include only the
  /// results where a part of the name or bio matches the search text.
  List<ProfileData> get _displayedListOfPeople {
    if (_searchTextController.text
        .trim()
        .isEmpty)
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
    if (_searchTextController.text
        .trim()
        .isEmpty)
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
          return "$podName Members";
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
        title: Text("Unable to add $personName to $podName"),
        content: Text(
            "${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun,
                pronounTense: PronounTenses.HeSheThey,
                shouldBeCapitalized: true)} ${PronounFormatter.isOrAre(
                pronoun: personData.preferredPronoun, shouldBeCapitalized: false)} blocked "
                "from $podName"),
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
            "${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun,
                pronounTense: PronounTenses.HeSheThey,
                shouldBeCapitalized: true)} ${PronounFormatter.isOrAre(
                pronoun: personData.preferredPronoun, shouldBeCapitalized: false)} already a member of ${podData
                .name}"),
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
                final timeSinceEpochInSeconds = DateTime
                    .now()
                    .millisecondsSinceEpoch * 0.001;
                final infoDict = PodMemberInfoDict(
                    userID: personData.userID,
                    bio: personData.bio,
                    birthday: personData.birthday,
                    joinedAt: timeSinceEpochInSeconds,
                    name: personData.name,
                    thumbnailURL: personData.thumbnailURL);
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
        this.isSearching = text
            .trim()
            .isNotEmpty;
      });
    });

    // If the viewMode is podMembers, populate the list with the passed-in value (sorted alphabetically)
    if (viewMode == MainListDisplayViewModes.podMembers) {
      if (podMembers != null) {
        var sortedPodMembers = podMembers ?? [];
        sortedPodMembers.sort((a, b) => a.name.compareTo(b.name));
        this._listOfPeople = sortedPodMembers;
      }
    }

    // If the viewMode is podMemberships (the pods that a person is in), populate the list with the passed-in value
    // (sorted alphabetically)
    if (viewMode == MainListDisplayViewModes.podMemberships) {
      if (podMemberships != null) {
        var sortedPodMemberships = podMemberships ?? [];
        sortedPodMemberships.sort((a, b) => a.name.compareTo(b.name));
        this._listOfPods = sortedPodMemberships;
      }
    }

    // If the viewMode is addPersonToPod or yPods, display the list of pods I'm in
    if (viewMode == MainListDisplayViewModes.myPods || viewMode == MainListDisplayViewModes.addPersonToPod) {
      var myPods = ShowMyPodsBackendFunctions.shared.sortedListOfPods.value;
      myPods.sort((a, b) => a.name.compareTo(b.name)); // sort alphabetically
      this._listOfPods = myPods;

      // also continuously listen in case I join or leave a pod
      ShowMyPodsBackendFunctions.shared.sortedListOfPods.addListener(() {
        var myPods = ShowMyPodsBackendFunctions.shared.sortedListOfPods.value;
        myPods.sort((a, b) => a.name.compareTo(b.name)); // sort alphabetically
        this._listOfPods = myPods;
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
        final data = document.get("profileData");
        final profileData = _extractPersonData(profileData: data, userID: userID);
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
  ProfileData _extractPersonData({required Map profileData, required String userID}) {
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
        fullPhotoURL: fullPhotoURL);
    return personData;
  }

  /// Get a pod's data given a map of type <String, dynamic>
  PodData _extractPodData({required Map podData, required String podID}) {
    final String thumbnailURL = podData["thumbnailURL"];
    final String fullPhotoURL = podData["fullPhotoURL"];
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
        fullPhotoURL: fullPhotoURL,
        podScore: podScore);
    return data;
  }

  /// Creates the trailing widget on the navigation bar, depending on the view mode
  Widget navBarTrailing() {
    if (viewMode == MainListDisplayViewModes.peopleIMet)
      return podModeButton(context: context);
    else if (viewMode == MainListDisplayViewModes.myPods)
      return CupertinoButton(padding: EdgeInsets.zero, child: Icon
        (CupertinoIcons
          .line_horizontal_3), onPressed: () {
        final sheet = CupertinoActionSheet(title: Text("Pod Options"), message: Text("Create a new pod or search for "
            "one by name"), actions: [

          // Create pod
          CupertinoActionSheetAction(onPressed: () {
            dismissAlert(context: context);
            Navigator.of(context, rootNavigator: true).push(
                CupertinoPageRoute(builder: (context) => CreateAPodView(isCreatingNewPod: true)));
          }, child: Text("Create Pod")),

          // Search for a pod by name
          CupertinoActionSheetAction(onPressed: () {
            dismissAlert(context: context);
            Navigator
                .of(context, rootNavigator: true)
                .push(CupertinoPageRoute(
                builder: (context) => MainListDisplayView(viewMode: MainListDisplayViewModes.searchPods)));
                }, child: Text("Search Pods By Name")),

          // Help button
          CupertinoActionSheetAction(onPressed: (){
            dismissAlert(context: context);
            //TODO: create the Help sheet
          }, child: Text("Help")),

          // Cancel button
          CupertinoActionSheetAction(onPressed: (){
            dismissAlert(context: context);
          }, child: Text("Cancel"), isDefaultAction: true,)
        ],);
        showCupertinoModalPopup(context: context, builder: (context) => sheet);
      });
    else
      return Container(width: 0, height: 0);
  }

  /// Show a back button if I should be allowed to go back. If the view is people I met (in the main tab view), then
  /// show the button to open the action sheet to view likes/friends/blocks
  Widget backButton() {
    if (viewMode != MainListDisplayViewModes.peopleIMet)
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
          showLikesFriendsBlocksActionSheet(context: context);
        },
        padding: EdgeInsets.zero,
      );
  }

  @override
  void dispose() {
    super.dispose();
    _customScrollViewController.removeListener(() {});
    ShowMyPodsBackendFunctions.shared.sortedListOfPods.removeListener(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
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
                                .push(CupertinoPageRoute(builder: (context) =>
                                ViewPersonDetails(personID: person.userID)));
                          },
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
                                Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                                    builder: (context) =>
                                        ViewPodDetails(
                                          podID: pod.podID,
                                          showChatButton: true,
                                        )));

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
                      SafeArea(
                          child: Text(
                            isSearching ? "No results found" : "Nobody to display",
                            style: TextStyle(color: CupertinoColors.inactiveGray),
                          )),

                    if (isPodMode && this._displayedListOfPods.isEmpty)
                      SafeArea(
                          child: Text(
                            isSearching ? "No results found" : "No pods to display",
                            style: TextStyle(color: CupertinoColors.inactiveGray),
                          )),
                  ],
                ),
              ]))
        ],
      ),
    );
  }
}
