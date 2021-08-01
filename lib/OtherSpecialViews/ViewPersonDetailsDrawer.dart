import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/BackendFunctions/PronounFormatter.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'package:podsquad/ContentViews/MainListDisplayView.dart';
import 'package:podsquad/DatabasePaths/BlockedUsersDatabasePaths.dart';
import 'package:podsquad/DatabasePaths/FriendsDatabasePaths.dart';
import 'package:podsquad/DatabasePaths/LikesDatabasePaths.dart';
import 'package:podsquad/DatabasePaths/ReportUsersDatabasePaths.dart';
import 'package:podsquad/OtherSpecialViews/TutorialSheets.dart';

import 'MultiImagePageViewer.dart';

/// The drawer that opens from the right of the screen to allow the user to interact with others
Widget viewPersonDetailsDrawer(
        {required BuildContext context,
        required bool didLikeUser,
        required bool didFriendUser,
        required bool didBlockUser,
        required bool didReportUser,
        required ProfileData personData,
        required List<PodData> personsPodMemberships}) =>
    Drawer(
        child: Container(color: isDarkMode ? CupertinoColors.black : CupertinoColors.white,
          child: SafeArea(
              child: ListView(
      padding: EdgeInsets.zero,
      children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: accentColor,
              image: DecorationImage(image: NetworkImage(personData.fullPhotoURL), fit: BoxFit.cover),
            ),
            child: Container(),
          ),

          ListTile(
            title: Text('Interact with ${personData.name}!', style: TextStyle(color: isDarkMode ? CupertinoColors.white :
            CupertinoColors.darkBackgroundGray)),
            subtitle: Text("${personData.name.firstName()}'s "
                "podscore: ${personData.podScore}", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
            CupertinoColors.inactiveGray)),
          ),

          // view their extra images, if they have any
          if (personData.extraImagesList?.isNotEmpty ?? false)
            ListTile(
              title: Text("${personData.name.firstName()}'s Photos", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.photo, color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                    builder: (context) => MultiImagePageViewer(
                        imagesList: personData.extraImagesList ?? [],
                        personId: personData.userID,
                        personName: personData.name)));
              },
            ),

          // view their pods button
          ListTile(
            title: Text(personData.userID == myFirebaseUserId ? "My Pods" : "${personData.name.firstName()}'s Pods", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
            CupertinoColors.darkBackgroundGray)),
            leading: Icon(CupertinoIcons.person_2_square_stack, color: isDarkMode ? CupertinoColors.white :
            CupertinoColors.darkBackgroundGray),
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                  builder: (context) => MainListDisplayView(
                        viewMode: MainListDisplayViewModes.podMemberships,
                        podMemberships: personsPodMemberships,
                        personId: personData.userID,
                        personName: personData.name,
                      )));
            },
          ),

          // add them to a pod (as long as I'm not viewing my own profile). Disable this option if I blocked the user,
          // to prevent a possible situation where someone might block someone else and then add them to pods they
          // don't want to be added to.
          if (!didBlockUser)
          if (personData.userID != myFirebaseUserId)
            ListTile(
              title: Text("Add ${personData.name.firstName()} to a pod", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.plus, color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                    builder: (context) =>
                        MainListDisplayView(viewMode: MainListDisplayViewModes.addPersonToPod, personData: personData)));
              },
            ),

          // like or unlike button
          if (!didLikeUser)
            ListTile(
              title: Text("Like ${personData.name.firstName()}", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.heart, color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray),
              onTap: () {
                // "Are you sure you want to like [NAME]?"
                final likeAlert = CupertinoAlertDialog(
                  title: Text("Like ${personData.name.firstName()}?"),
                  content: Text(didBlockUser ? "Are you sure you want to send ${personData.name.firstName()} a like? "
                      "This will unblock ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun,
                      pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)}!":
                  (didFriendUser
                      ? "Are you sure you want to send ${personData.name.firstName()} a like? This will "
                          "remove ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)} from "
                          "the list of people you friended."
                      : "Are you sure you want to send ${PronounFormatter.makePronoun(preferredPronouns: personData
                      .preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)} a like?")),
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
            ),

          if (didLikeUser)
            ListTile(
              title: Text("Un-like ${personData.name.firstName()}", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.heart_slash, color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray),
              onTap: () {
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
            ),

          // friend or unfriend button
          if (!didFriendUser)
            ListTile(
              title: Text("Friend ${personData.name.firstName()}", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.person_badge_plus, color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray),
              onTap: () {
                // "Are you sure you want to friend [NAME]?"
                final friendAlert = CupertinoAlertDialog(
                  title: Text("Friend ${personData.name.firstName()}?"),
                  content: Text(didBlockUser ? "Are you sure you want to add ${personData.name.firstName()} to your "
                      "list of friends? This will unblock${PronounFormatter.makePronoun(preferredPronouns: personData
                      .preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)}!":
                  (didLikeUser
                      ? "Are you sure you want to add "
                          "${personData.name.firstName()} to your "
                          "friends? This will remove ${PronounFormatter.makePronoun(preferredPronouns: personData.preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)} from the list "
                          "of people you liked."
                      : "Are you sure you want to add ${PronounFormatter.makePronoun(preferredPronouns: personData
                      .preferredPronoun, pronounTense: PronounTenses.HimHerThem, shouldBeCapitalized: false)} to your friends?")),
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
            ),

          if (didFriendUser)
            ListTile(
              title: Text("Unfriend ${personData.name.firstName()}", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.person_badge_minus, color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray),
              onTap: () {
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
                                content: Text("You removed ${personData.name.firstName()} from your friends."),
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
            ),

          // block or unblock button
          if (!didBlockUser)
            ListTile(
              title: Text("Block ${personData.name.firstName()}", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.hand_raised, color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray),
              onTap: () {
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
            ),
          if (didBlockUser)
            ListTile(
              title: Text("Unblock ${personData.name.firstName()}", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.hand_raised_slash, color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray),
              onTap: () {
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
            ),

          // report or unreport button
          if (!didReportUser)
            ListTile(
              title: Text("Report ${personData.name.firstName()}", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.exclamationmark_shield, color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray),
              onTap: () {
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
                                content: Text("Thank you for reporting ${personData.name.firstName()} for inappropriate "
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
            ),
          if (didReportUser)
            ListTile(
              title: Text("Un-report ${personData.name.firstName()}", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.shield_slash, color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray),
              onTap: () {
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
            ),

          //Help tile
          ListTile(
              title: Text("Help", style: TextStyle(color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray)),
              leading: Icon(CupertinoIcons.question_circle, color: isDarkMode ? CupertinoColors.white :
              CupertinoColors.darkBackgroundGray),
              onTap: () {
                showViewPersonDetailsTutorialIfNecessary(context: context, personData: personData, userPressedHelp: true);
              })
      ],
    )),
        ));
