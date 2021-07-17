import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/BackendFunctions/PronounFormatter.dart';
import 'package:podsquad/BackendFunctions/ReportedPeopleBackendFunctions.dart';
import 'package:podsquad/BackendFunctions/TimeAndDateFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/MainListDisplayView.dart';
import 'package:podsquad/ContentViews/MessagingView.dart';
import 'package:podsquad/ContentViews/ViewFullImage.dart';
import 'package:podsquad/DatabasePaths/BlockedUsersDatabasePaths.dart';
import 'package:podsquad/DatabasePaths/FriendsDatabasePaths.dart';
import 'package:podsquad/DatabasePaths/LikesDatabasePaths.dart';
import 'package:podsquad/DatabasePaths/ReportUsersDatabasePaths.dart';
import 'package:podsquad/OtherSpecialViews/DecoratedImage.dart';
import 'package:podsquad/OtherSpecialViews/MultiImagePageViewer.dart';
import 'package:podsquad/UIBackendClasses/MainListDisplayBackend.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

class ViewPersonDetails extends StatefulWidget {
  const ViewPersonDetails({Key? key, required this.personID, this.messagingEnabled = true}) : super(key: key);
  final String personID;
  final bool messagingEnabled;

  @override
  _ViewPersonDetailsState createState() =>
      _ViewPersonDetailsState(personID: this.personID, messagingEnabled: this.messagingEnabled);
}

//TODO: Get the person's pod memberships and display them; also enable adding a person to a pod

class _ViewPersonDetailsState extends State<ViewPersonDetails> {
  _ViewPersonDetailsState({required this.personID, required this.messagingEnabled});

  final String personID;
  final bool messagingEnabled;

  bool didLikeUser = false;
  bool didFriendUser = false;
  bool didBlockUser = false;
  bool didReportUser = false;

  /// A list of every pod that the user is in
  List<PodData> _personsPodMemberships = [];

  /// This will store the user's profile data. It gets updated inside initState.
  ProfileData personData = ProfileData(
      userID: "userID",
      name: "Name N/A",
      preferredPronoun: UsefulValues.nonbinaryPronouns,
      preferredRelationshipType: UsefulValues.lookingForFriends,
      birthday: 0,
      school: "School N/A",
      bio: "",
      podScore: 0,
      thumbnailURL: "thumbnailURL",
      fullPhotoURL: "fullPhotoURL");

  /// Get the person's profile data from Firestore
  void _getProfileData() {
    MyProfileTabBackendFunctions.shared.getPersonsProfileData(
        userID: personID,
        onCompletion: (profileData) {
          setState(() {
            this.personData = profileData;
          });
        });
  }

  /// Get the person's pod memberships
  void _getPodMemberships() {
    // If I'm looking at my own profile, there is no need to download anything extra: just read in my pod memberships
    if (personID == myFirebaseUserId) {
      this._personsPodMemberships = ShowMyPodsBackendFunctions.shared.sortedListOfPods.value;
      ShowMyPodsBackendFunctions.shared.sortedListOfPods.addListener(() {
        final myPods = ShowMyPodsBackendFunctions.shared.sortedListOfPods.value;
        // No need to sort here since MainListDisplay view will sort the list alphabetically
        setState(() {
          this._personsPodMemberships = myPods;
        });
      });
    }
  }

  /// Convert the user's preferred relationship type into a user-friendly string
  String _preferredRelationshipTypeText({required String lookingFor}) {
    if (lookingFor == UsefulValues.lookingForFriends)
      return "Looking for friends!";
    else if (lookingFor == UsefulValues.lookingForGirlfriend)
      return "Looking for a girlfriend!";
    else if (lookingFor == UsefulValues.lookingForBoyfriend)
      return "Looking for a boyfriend!";
    else if (lookingFor == UsefulValues.lookingForAnyGenderDate)
      return "Looking for a date!";
    else
      return "Preferred relationship type unknown";
  }

  @override
  void initState() {
    super.initState();
    this._getProfileData();
    this._getPodMemberships();

    // Determine if I already liked/friended/blocked/reported the user
    this.didLikeUser = SentLikesBackendFunctions.shared.sortedListOfPeople.value.memberIDs().contains(personID);
    this.didFriendUser = SentFriendsBackendFunctions.shared.sortedListOfPeople.value.memberIDs().contains(personID);
    this.didBlockUser = SentBlocksBackendFunctions.shared.sortedListOfPeople.value.memberIDs().contains(personID);
    this.didReportUser = ReportedPeopleBackendFunctions.shared.peopleIReportedList.value.contains(personID);

    // Add listeners that will update if I like/friend/block/report the user
    SentLikesBackendFunctions.shared.sortedListOfPeople.addListener(() {
      final didLikeUser = SentLikesBackendFunctions.shared.sortedListOfPeople.value.contains(personData);
      setState(() {
        this.didLikeUser = didLikeUser;
        print(
            "I liked someone! Here's that person: ${SentLikesBackendFunctions.shared.sortedListOfPeople.value.last.name}. Thus, didLikeUser is equal to $didLikeUser because the user's ID is ${SentLikesBackendFunctions.shared.sortedListOfPeople.value.last.userID}");
      });
    });

    SentFriendsBackendFunctions.shared.sortedListOfPeople.addListener(() {
      final didFriendUser = SentFriendsBackendFunctions.shared.sortedListOfPeople.value.contains(personData);
      setState(() {
        this.didFriendUser = didFriendUser;
      });
    });

    SentBlocksBackendFunctions.shared.sortedListOfPeople.addListener(() {
      final didBlockUser = SentBlocksBackendFunctions.shared.sortedListOfPeople.value.contains(personData);
      setState(() {
        this.didBlockUser = didBlockUser;
      });
    });

    ReportedPeopleBackendFunctions.shared.peopleIReportedList.addListener(() {
      final didReportUser = ReportedPeopleBackendFunctions.shared.peopleIReportedList.value.contains(personID);
      setState(() {
        this.didReportUser = didReportUser;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    SentLikesBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    SentFriendsBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    SentBlocksBackendFunctions.shared.sortedListOfPeople.removeListener(() {});
    ReportedPeopleBackendFunctions.shared.peopleIReportedList.removeListener(() {});
    ShowMyPodsBackendFunctions.shared.sortedListOfPods.removeListener(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          padding: EdgeInsetsDirectional.all(5),
          middle: Text(personID == myFirebaseUserId ? "My Profile" : "${personData.name.firstName()}'s Profile"),
          trailing: personID == myFirebaseUserId
              ? Container(width: 0, height: 0)
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(CupertinoIcons.line_horizontal_3),
                  onPressed: () {
                    // show the action sheet to like/friend/block/report/add to pod
                    final sheet = CupertinoActionSheet(
                      title: Text("Interact with ${personData.name.firstName()}!"),
                      actions: [
                        // like or unlike button
                        if (!didLikeUser)
                          CupertinoActionSheetAction(
                              onPressed: () {
                                // dismiss the action sheet
                                dismissAlert(context: context);
                                // "Are you sure you want to like [NAME]?"
                                final likeAlert = CupertinoAlertDialog(
                                  title: Text("Like ${personData.name.firstName()}?"),
                                  content: Text(didFriendUser
                                      ? "Are you sure you want to send ${personData.name.firstName()} a like? This will "
                                          "remove ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)} from "
                                          "the list of people you friended."
                                      : "Are you sure you want to send ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)} a like?"),
                                  actions: [
                                    // cancel button
                                    CupertinoButton(
                                        child: Text("No"),
                                        onPressed: () {
                                          dismissAlert(context: context);
                                        }),

                                    // send like button
                                    CupertinoButton(
                                      child: Text("Yes"),
                                      onPressed: () {
                                        dismissAlert(context: context);
                                        LikesDatabasePaths.sendLike(
                                            otherPersonsUserID: personData.userID,
                                            onCompletion: () {
                                              final successAlert = CupertinoAlertDialog(
                                                title: Text("${personData.name.firstName()} Liked"),
                                                content: Text("You liked ${personData.name.firstName()}!"),
                                                actions: [
                                                  CupertinoButton(
                                                      child: Text("OK"),
                                                      onPressed: () {
                                                        dismissAlert(context: context);
                                                      })
                                                ],
                                              );
                                              showCupertinoDialog(context: context, builder: (context) => successAlert);
                                            });
                                      },
                                    )
                                  ],
                                );
                                showCupertinoDialog(context: context, builder: (context) => likeAlert);
                              },
                              child: Text("Like ${personData.name.firstName()}")),
                        if (didLikeUser)
                          CupertinoActionSheetAction(
                              onPressed: () {
                                // dismiss the action sheet
                                dismissAlert(context: context);
                                // "Are you sure you want to un-like [NAME]?"
                                final unLikeAlert = CupertinoAlertDialog(
                                  title: Text("Remove Like?"),
                                  content: Text("Are you sure you want to un-like ${personData.name.firstName()}?"),
                                  actions: [
                                    // cancel button
                                    CupertinoButton(
                                        child: Text("No"),
                                        onPressed: () {
                                          dismissAlert(context: context);
                                        }),

                                    // remove like button
                                    CupertinoButton(
                                      child: Text("Yes"),
                                      onPressed: () {
                                        dismissAlert(context: context);
                                        LikesDatabasePaths.removeLike(
                                            otherPersonsUserID: personData.userID,
                                            onCompletion: () {
                                              final successAlert = CupertinoAlertDialog(
                                                title: Text("Like Unsent"),
                                                content: Text("You no longer like ${personData.name.firstName()}."),
                                                actions: [
                                                  CupertinoButton(
                                                      child: Text("OK"),
                                                      onPressed: () {
                                                        dismissAlert(context: context);
                                                      })
                                                ],
                                              );
                                              showCupertinoDialog(context: context, builder: (context) => successAlert);
                                            });
                                      },
                                    )
                                  ],
                                );
                                showCupertinoDialog(context: context, builder: (context) => unLikeAlert);
                              },
                              child: Text("Un-like ${personData.name.firstName()}")),

                        // friend or unfriend button
                        if (!didFriendUser)
                          CupertinoActionSheetAction(
                              onPressed: () {
                                // dismiss the action sheet
                                dismissAlert(context: context);
                                // "Are you sure you want to friend [NAME]?"
                                final friendAlert = CupertinoAlertDialog(
                                  title: Text("Friend ${personData.name.firstName()}?"),
                                  content: Text(didLikeUser
                                      ? "Are you sure you want to add "
                                          "${personData.name.firstName()} to your "
                                          "friends? This will remove ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)} from the list "
                                          "of people you liked."
                                      : "Are you sure you want to add ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)} to your friends?"),
                                  actions: [
                                    // cancel button
                                    CupertinoButton(
                                        child: Text("No"),
                                        onPressed: () {
                                          dismissAlert(context: context);
                                        }),

                                    // send friend button
                                    CupertinoButton(
                                      child: Text("Yes"),
                                      onPressed: () {
                                        dismissAlert(context: context);
                                        FriendsDatabasePaths.friendUser(
                                            otherPersonsUserID: personData.userID,
                                            onCompletion: () {
                                              final successAlert = CupertinoAlertDialog(
                                                title: Text("Friend Added"),
                                                content: Text("You friended ${personData.name.firstName()}!"),
                                                actions: [
                                                  CupertinoButton(
                                                      child: Text("OK"),
                                                      onPressed: () {
                                                        dismissAlert(context: context);
                                                      })
                                                ],
                                              );
                                              showCupertinoDialog(context: context, builder: (context) => successAlert);
                                            });
                                      },
                                    )
                                  ],
                                );
                                showCupertinoDialog(context: context, builder: (context) => friendAlert);
                              },
                              child: Text("Friend ${personData.name.firstName()}")),
                        if (didFriendUser)
                          CupertinoActionSheetAction(
                              onPressed: () {
                                // dismiss the action sheet
                                dismissAlert(context: context);
                                // "Are you sure you want to unfriend [NAME]?"
                                final unFriendAlert = CupertinoAlertDialog(
                                  title: Text("Remove Friend?"),
                                  content: Text("Are you sure you want to unfriend ${personData.name.firstName()}?"),
                                  actions: [
                                    // cancel button
                                    CupertinoButton(
                                        child: Text("No"),
                                        onPressed: () {
                                          dismissAlert(context: context);
                                        }),

                                    // remove friend button
                                    CupertinoButton(
                                      child: Text("Yes"),
                                      onPressed: () {
                                        dismissAlert(context: context);
                                        FriendsDatabasePaths.unFriendUser(
                                            otherPersonsUserID: personData.userID,
                                            onCompletion: () {
                                              final successAlert = CupertinoAlertDialog(
                                                title: Text("Friend Removed"),
                                                content: Text(
                                                    "You removed ${personData.name.firstName()} from your friends."),
                                                actions: [
                                                  CupertinoButton(
                                                      child: Text("OK"),
                                                      onPressed: () {
                                                        dismissAlert(context: context);
                                                      })
                                                ],
                                              );
                                              showCupertinoDialog(context: context, builder: (context) => successAlert);
                                            });
                                      },
                                    )
                                  ],
                                );
                                showCupertinoDialog(context: context, builder: (context) => unFriendAlert);
                              },
                              child: Text("Unfriend ${personData.name.firstName()}")),

                        // block or unblock button
                        if (!didBlockUser)
                          CupertinoActionSheetAction(
                              isDestructiveAction: true,
                              onPressed: () {
                                // dismiss the action sheet
                                dismissAlert(context: context);
                                // "Are you sure you want to block [NAME]?"
                                final blockAlert = CupertinoAlertDialog(
                                  title: Text("Block ${personData.name.firstName()}?"),
                                  content: Text(
                                      "Are you sure you want to block ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)}? ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HeSheThey, shouldBeCapitalized: true)} will "
                                      "no longer be able to interact with you."),
                                  actions: [
                                    // cancel button
                                    CupertinoButton(
                                        child: Text("No"),
                                        onPressed: () {
                                          dismissAlert(context: context);
                                        }),

                                    // block button
                                    CupertinoButton(
                                      child: Text(
                                        "Yes",
                                        style: TextStyle(color: CupertinoColors.destructiveRed),
                                      ),
                                      onPressed: () {
                                        dismissAlert(context: context);
                                        BlockedUsersDatabasePaths.blockUser(
                                            otherPersonsUserID: personData.userID,
                                            onCompletion: () {
                                              final successAlert = CupertinoAlertDialog(
                                                title: Text("Block Successful"),
                                                content: Text("You blocked ${personData.name.firstName()}."),
                                                actions: [
                                                  CupertinoButton(
                                                      child: Text("OK"),
                                                      onPressed: () {
                                                        dismissAlert(context: context);
                                                      })
                                                ],
                                              );
                                              showCupertinoDialog(context: context, builder: (context) => successAlert);
                                            });
                                      },
                                    )
                                  ],
                                );
                                showCupertinoDialog(context: context, builder: (context) => blockAlert);
                              },
                              child: Text("Block ${personData.name.firstName()}")),
                        if (didBlockUser)
                          CupertinoActionSheetAction(
                              onPressed: () {
                                // dismiss the action sheet
                                dismissAlert(context: context);
                                // "Are you sure you want to unblock [NAME]?"
                                final unBlockAlert = CupertinoAlertDialog(
                                  title: Text("Unblock ${personData.name.firstName()}?"),
                                  content: Text(
                                      "Are you sure you want to block ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)}? ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HeSheThey, shouldBeCapitalized: true)} will "
                                      "be able to interact with you again."),
                                  actions: [
                                    // cancel button
                                    CupertinoButton(
                                        child: Text("No"),
                                        onPressed: () {
                                          dismissAlert(context: context);
                                        }),

                                    // unblock button
                                    CupertinoButton(
                                      child: Text("Yes"),
                                      onPressed: () {
                                        dismissAlert(context: context);
                                        BlockedUsersDatabasePaths.unBlockUser(
                                            otherPersonsUserID: personData.userID,
                                            onCompletion: () {
                                              final successAlert = CupertinoAlertDialog(
                                                title: Text("Unblock Successful"),
                                                content: Text("You unblocked ${personData.name.firstName()}!"),
                                                actions: [
                                                  CupertinoButton(
                                                      child: Text("OK"),
                                                      onPressed: () {
                                                        dismissAlert(context: context);
                                                      })
                                                ],
                                              );
                                              showCupertinoDialog(context: context, builder: (context) => successAlert);
                                            });
                                      },
                                    )
                                  ],
                                );
                                showCupertinoDialog(context: context, builder: (context) => unBlockAlert);
                              },
                              child: Text("Unblock ${personData.name.firstName()}")),

                        // report or unreport button
                        if (!didReportUser)
                          CupertinoActionSheetAction(
                              isDestructiveAction: true,
                              onPressed: () {
                                // dismiss the action sheet
                                dismissAlert(context: context);
                                // "Are you sure you want to report [NAME]?"
                                final reportAlert = CupertinoAlertDialog(
                                  title: Text("Report ${personData.name.firstName()}?"),
                                  content: Text(
                                      "Are you sure you want to report ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)} for inappropriate content?"),
                                  actions: [
                                    // cancel button
                                    CupertinoButton(
                                        child: Text("No"),
                                        onPressed: () {
                                          dismissAlert(context: context);
                                        }),

                                    // report button
                                    CupertinoButton(
                                      child: Text(
                                        "Yes",
                                        style: TextStyle(color: CupertinoColors.destructiveRed),
                                      ),
                                      onPressed: () {
                                        dismissAlert(context: context);
                                        ReportUserPaths.reportUser(
                                            otherPersonsUserID: personData.userID,
                                            onCompletion: () {
                                              final successAlert = CupertinoAlertDialog(
                                                title: Text("Report Successful"),
                                                content: Text(
                                                    "Thank you for reporting ${personData.name.firstName()} for inappropriate "
                                                    "content."),
                                                actions: [
                                                  CupertinoButton(
                                                      child: Text("OK"),
                                                      onPressed: () {
                                                        dismissAlert(context: context);
                                                      })
                                                ],
                                              );
                                              showCupertinoDialog(context: context, builder: (context) => successAlert);
                                            });
                                      },
                                    )
                                  ],
                                );
                                showCupertinoDialog(context: context, builder: (context) => reportAlert);
                              },
                              child: Text("Report ${personData.name.firstName()}")),
                        if (didReportUser)
                          CupertinoActionSheetAction(
                              onPressed: () {
                                // dismiss the action sheet
                                dismissAlert(context: context);
                                // "Are you sure you want to report [NAME]?"
                                final reportAlert = CupertinoAlertDialog(
                                  title: Text("Un-report ${personData.name.firstName()}?"),
                                  content: Text(
                                      "Are you sure you want to un-report ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)}?"),
                                  actions: [
                                    // cancel button
                                    CupertinoButton(
                                        child: Text("No"),
                                        onPressed: () {
                                          dismissAlert(context: context);
                                        }),

                                    // un-report button
                                    CupertinoButton(
                                      child: Text(
                                        "Yes",
                                      ),
                                      onPressed: () {
                                        dismissAlert(context: context);
                                        ReportUserPaths.unReportUser(
                                            otherPersonsUserID: personData.userID,
                                            onCompletion: () {
                                              final successAlert = CupertinoAlertDialog(
                                                title: Text("${personData.name.firstName()} "
                                                    "Unreported"),
                                                content: Text(
                                                    "You successfully unreported ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)}"),
                                                actions: [
                                                  CupertinoButton(
                                                      child: Text("OK"),
                                                      onPressed: () {
                                                        dismissAlert(context: context);
                                                      })
                                                ],
                                              );
                                              showCupertinoDialog(context: context, builder: (context) => successAlert);
                                            });
                                      },
                                    )
                                  ],
                                );
                                showCupertinoDialog(context: context, builder: (context) => reportAlert);
                              },
                              child: Text("Un-report ${personData.name.firstName()}")),

                        // cancel button
                        CupertinoActionSheetAction(
                          onPressed: () {
                            dismissAlert(context: context);
                          },
                          child: Text("Cancel"),
                          isDefaultAction: true,
                        )
                      ],
                    );
                    showCupertinoModalPopup(context: context, builder: (context) => sheet);
                  },
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Swipe left on the profile photo to view the person's extra images. Tap it to view the person's
                  // profile image.
                  // Not a typo. The image should be a square with both dimensions equal to the screen width. This
                  // ensures that the image will fill the proper space even when loading.
                  GestureDetector(
                    child: DecoratedImage(
                      imageURL: personData.fullPhotoURL,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width,
                    ),
                    onTap: () {
                      // tap to view the person's full profile image
                      Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                          builder: (context) => ViewFullImage(
                              urlForImageToView: personData.fullPhotoURL,
                              imageID: "doesn't matter",
                              navigationBarTitle: personID == myFirebaseUserId ? "My Profile Image" : personData.name,
                              canWriteCaption: false)));
                    },
                    onPanUpdate: (swipe) {
                      // swipe left to view the person's extra images
                      if (swipe.delta.dx < 0)
                        Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                            builder: (context) => MultiImagePageViewer(
                                imagesList: personData.extraImagesList ?? [],
                                personId: personData.userID,
                                personName: personData.name)));
                    },
                  ),
                  SizedBox(
                    height: 10,
                  ),

                  // Name, age, school, relationship type, bio on the left, Message and Say Hi buttons on the right
                  Card(
                      child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contains name, age, school, lookingFor, Message button, and Say Hi button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // name, age, school, relationship type, and bio column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // The name field should be a button that opens an action sheet that will show the user's podScore
                                // and an option to view their pods
                                CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: Text(
                                      personData.name,
                                      style: TextStyle(
                                          fontSize: 18.scaledForScreenSize(context: context),
                                          color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                                    ),
                                    onPressed: () {
                                      // show the action sheet with their podScore and button to view pods
                                      final sheet = CupertinoActionSheet(
                                        message: Text("Podscore: ${personData.podScore}"),
                                        actions: [
                                          CupertinoActionSheetAction(
                                              onPressed: () {
                                                dismissAlert(context: context);
                                                Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                                                    builder: (context) => MainListDisplayView(
                                                          viewMode: MainListDisplayViewModes.podMemberships,
                                                          podMemberships: this._personsPodMemberships,
                                                          personName: personData.name,
                                                        )));
                                              },
                                              child: Text(personData.userID == myFirebaseUserId
                                                  ? "My Pods"
                                                  : "${personData.name.firstName()}'s Pods")),

                                          // cancel button
                                          CupertinoActionSheetAction(
                                            onPressed: () {
                                              dismissAlert(context: context);
                                            },
                                            child: Text("Cancel"),
                                            isDefaultAction: true,
                                          )
                                        ],
                                      );
                                      showCupertinoModalPopup(context: context, builder: (context) => sheet);
                                    }),
                                SizedBox(
                                  height: 5,
                                ),

                                // The person's age
                                Text(
                                  TimeAndDateFunctions.getAgeFromBirthday(birthday: personData.birthday).toString(),
                                  style: TextStyle(fontSize: 15.scaledForScreenSize(context: context)),
                                ),
                                SizedBox(
                                  height: 15,
                                ),

                                // The person's school
                                Text(
                                  personData.school,
                                  style: TextStyle(fontSize: 15.scaledForScreenSize(context: context)),
                                ),
                                SizedBox(
                                  height: 15,
                                ),

                                // Who they're looking for
                                Text(
                                  _preferredRelationshipTypeText(lookingFor: personData.preferredRelationshipType),
                                  style: TextStyle(fontSize: 15.scaledForScreenSize(context: context)),
                                ),
                              ],
                            ),
                            Spacer(),

                            // Message and "Say Hi" button (don't show if I'm viewing my own profile)
                            if (personID != myFirebaseUserId && messagingEnabled)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      child: Row(
                                        children: [
                                          Text("Message"),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Icon(CupertinoIcons.paperplane),
                                        ],
                                      ),
                                      onPressed: () {
                                        Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                                            builder: (context) => MessagingView(
                                                chatPartnerOrPodID: personData.userID,
                                                chatPartnerOrPodName: personData.name,
                                                isPodMode: false)));
                                      })
                                ],
                              )
                          ],
                        ),

                        // The person's bio
                        SizedBox(
                          height: 15,
                        ),

                        Text(
                          personData.bio.isNotEmpty
                              ? personData.bio
                              : "${personData.name.firstName()} has not "
                                  "written a bio!",
                          style: TextStyle(fontSize: 15.scaledForScreenSize(context: context)),
                        )
                      ],
                    ),
                  ))
                ],
              ),
            ),
          ),
        ));
  }
}
