import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/ContentViews/ViewPersonDetails.dart';
import 'package:podsquad/ContentViews/ViewPodDetails.dart';
import 'package:podsquad/ListRowViews/PersonOrPodListRow.dart';

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

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    super.dispose();
    _customScrollViewController.removeListener(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _customScrollViewController,
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(navBarTitle(viewMode: viewMode)),
            stretch: true,
          ),

          // collapsible search bar
          if (_searchBarShowing)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: CupertinoSearchTextField(
                  controller: _searchTextController,
                  placeholder: "Search",
                ),
              ),
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
                              this._selectedIndex =
                                  this._displayedListOfPeople.indexWhere((element) => element == person);
                            });
                            // navigate to view the person's details
                            Navigator.of(context, rootNavigator: true).push(
                                CupertinoPageRoute(builder: (context) => ViewPersonDetails(personID: person.userID)));
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
                      SafeArea(child: Text(
                        isSearching ? "No results found" : "Nobody to display",
                        style: TextStyle(color: CupertinoColors.inactiveGray),
                      )),

                    if(isPodMode && this._displayedListOfPods.isEmpty)
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
