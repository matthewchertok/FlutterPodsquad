import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/BackendFunctions/TimeAndDateFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/MessagingView.dart';
import 'package:podsquad/OtherSpecialViews/DecoratedImage.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

class ViewPersonDetails extends StatefulWidget {
  const ViewPersonDetails({Key? key, required this.personID, this.messagingEnabled = true}) : super(key: key);
  final String personID;
  final bool messagingEnabled;

  @override
  _ViewPersonDetailsState createState() => _ViewPersonDetailsState(personID: this.personID, messagingEnabled: this.messagingEnabled);
}

class _ViewPersonDetailsState extends State<ViewPersonDetails> {
  _ViewPersonDetailsState({required this.personID, required this.messagingEnabled});

  final String personID;
  final bool messagingEnabled;

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
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(personID == myFirebaseUserId ? "My Profile" : "${personData.name.firstName()}'s Profile"),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DecoratedImage(imageURL: personData.fullPhotoURL),
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
                                                // TODO: Navigate to view the person's pods
                                              },
                                              child: Text(personData.userID == myFirebaseUserId
                                                  ? "My Pods"
                                                  : "${personData.name.firstName()}'s Pods'}")),

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
                                        children: [Text
                                          ("Message"),
                                          SizedBox(width: 5,),
                                          Icon(CupertinoIcons.paperplane),  ],
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
