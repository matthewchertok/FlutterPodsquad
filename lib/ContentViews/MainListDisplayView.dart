import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/ViewPersonDetails.dart';
import 'package:podsquad/ContentViews/ViewPodDetails.dart';
import 'package:podsquad/ListRowViews/PersonOrPodListRow.dart';
import 'package:podsquad/OtherSpecialViews/LikesFriendsBlocksDrawer.dart';
import 'package:podsquad/OtherSpecialViews/SearchTextField.dart';

class MainListDisplayView extends StatefulWidget {
  const MainListDisplayView(
      {Key? key, required this.viewMode, this.showingSentDataNotReceivedData = true, this.podName = "null"})
      : super(key: key);
  final String viewMode;
  final bool? showingSentDataNotReceivedData;
  final String? podName;

  @override
  _MainListDisplayViewState createState() => _MainListDisplayViewState(
      viewMode: this.viewMode,
      showingSentDataNotReceivedData: this.showingSentDataNotReceivedData,
      podName: this.podName);
}

class _MainListDisplayViewState extends State<MainListDisplayView> {
  final viewMode;
  final showingSentDataNotReceivedData;
  final podName;
  final _searchTextController = TextEditingController();
  final _customScrollViewController = ScrollController();

  _MainListDisplayViewState(
      {required this.viewMode, required this.showingSentDataNotReceivedData, required this.podName}) {
    this.isPodMode = viewMode == MainListDisplayViewModes.searchPods || viewMode == MainListDisplayViewModes.myPods;
  }

  /// Stores a list of people to display. Use this property if displaying people
  List<ProfileData> _displayedListOfPeople = [];

  /// Stores a list of pods to display. Use this property if displaying pods
  List<PodData> _displayedListOfPods = [];

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

    /// Determine when I'm searching for a person or pod
    _searchTextController.addListener(() {
      final text = _searchTextController.text;
      setState(() {
        this.isSearching = text.trim().isNotEmpty;
      });
    });
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
        this._displayedListOfPods = [];
      else
        this._displayedListOfPeople = [];
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
        _displayedListOfPods = listOfPodResults;
      else
        _displayedListOfPeople = listOfPeopleResults;
    });
  }

  /// Get a person's data given a map of type <String, dynamic>
  ProfileData _extractPersonData({required Map profileData, required String userID}) {
    final String thumbnailURL = profileData["photoThumbnailURL"];
    final String fullPhotoURL = profileData["fullPhotoURL"];
    final String name = profileData["name"];
    final String preferredPronoun = profileData["preferredPronouns"];
    final String preferredRelationshipType = profileData["lookingFor"];
    final num birthdayRaw = profileData["birthday"];
    final birthday = birthdayRaw.toDouble();
    final String school = profileData["school"];
    final String bio = profileData["bio"];
    final num podScoreRaw = profileData["podScore"] as num;
    final int podScore = podScoreRaw.toInt();

    final personData = ProfileData(
        userID: userID,
        name: name,
        preferredPronoun: preferredPronoun,
        preferredRelationshipType: preferredRelationshipType,
        birthday: birthday,
        school: school,
        bio: bio,
        podScore: podScore,
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
            stretch: true,
          ),

          // collapsible search bar THe reason I must use CupertinoTextField instead of CupertinoSearchTextField (the
          // themed search bar) is that CupertinoSearchTextField does not have a text auto-capitalization property,
          // meaning that by default, letters are always lower-cased. This might cause confusion for users, as they
          // would have to manually capitalize their searches every time. It's much easier for them if the text field
          // auto-capitalizes for them, which is why I'm using a regular CupertinoTextField for now.
          if (_searchBarShowing)
            SliverToBoxAdapter(
              child: Padding(
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
                          _displayedListOfPeople.clear();
                        });
                      if (viewMode == MainListDisplayViewModes.searchPods)
                        setState(() {
                          _displayedListOfPods.clear();
                        });
                    },
                  )),
            ),

          // person or pod list
          SliverList(
              delegate: SliverChildListDelegate([
            // will contain content
            Column(
              children: [
                // show a list of people
                if (!isPodMode)
                  for (var person in _displayedListOfPeople)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          // highlight the row
                          this._selectedIndex = this._displayedListOfPeople.indexWhere((element) => element == person);
                        });
                        // navigate to view the person's details
                        Navigator.of(context, rootNavigator: true)
                            .push(CupertinoPageRoute(builder: (context) => ViewPersonDetails(personID: person.userID)));
                      },
                      child: Card(
                        color: _selectedIndex == _displayedListOfPeople.indexWhere((element) => element == person)
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
                            this._selectedIndex = this._displayedListOfPods.indexWhere((element) => element == pod);
                          });

                          // navigate to view pod details
                          Navigator.of(context, rootNavigator: true)
                              .push(CupertinoPageRoute(builder: (context) => ViewPodDetails(podID: pod.podID)));
                        },
                        child: Card(
                          color: _selectedIndex == _displayedListOfPods.indexWhere((element) => element == pod)
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
                  Text(
                    isSearching ? "No results found" : "No pods to display",
                    style: TextStyle(color: CupertinoColors.inactiveGray),
                  ),
              ],
            ),
          ]))
        ],
      ),
    );
  }
}
