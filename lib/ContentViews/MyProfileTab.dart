import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:podsquad/BackendDataHolders/UserAuth.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/BackendFunctions/NearbyScanner.dart';
import 'package:podsquad/BackendFunctions/PushNotificationStatus.dart';
import 'package:podsquad/BackendFunctions/ResizeAndUploadImage.dart';
import 'package:podsquad/CommonlyUsedClasses/AlertDialogs.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/ViewPersonDetails.dart';
import 'package:podsquad/OtherSpecialViews/DecoratedImage.dart';
import 'package:podsquad/OtherSpecialViews/MultiImageUploader.dart';
import 'package:podsquad/OtherSpecialViews/TutorialSheets.dart';
import 'package:podsquad/TabLayoutViews/WelcomeView.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

class MyProfileTab extends StatefulWidget {
  const MyProfileTab({Key? key}) : super(key: key);

  @override
  _MyProfileTabState createState() => _MyProfileTabState();
}

class _MyProfileTabState extends State<MyProfileTab> {
  final _nameTextController = TextEditingController();
  final _schoolTextController = TextEditingController();
  final _bioTextController = TextEditingController();
  final _imagePicker = ImagePicker();

  /// Determine whether to show the Multi Image Uploader to add extra images
  var _showingMultiImageUploader = false;

  // The image that gets picked from the photo library
  File? imageFile;

  /// The profile image thumbnail URL
  String? _profileThumbnailURL;

  /// The preferred pronouns
  String? _preferredPronouns;

  /// The preferred relationship type
  String? _preferredRelationshipType;

  /// The birthday, as the number of SECONDS since midnight on January 1, 1970
  double? _birthday;

  /// Returns the date 21 years ago, which is the default age for new users
  double _twentyOneYearsAgo() {
    final millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
    final millisecondsSinceEpoch21YearsAgo = millisecondsSinceEpoch - 662709600 * 1000;
    final date21YearsAgo = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch21YearsAgo);
    return date21YearsAgo.millisecondsSinceEpoch * 0.001; // return the time since epoch 21 years ago (in seconds)
  }

  /// Returns the date 120 years ago. Assume nobody on the app is older than that.
  DateTime _earliestAllowedBirthday() {
    final millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
    final millisecondsSinceEpoch120YearsAgo = millisecondsSinceEpoch - 3786912000 * 1000;
    final date120YearsAgo = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch120YearsAgo);
    return date120YearsAgo;
  }

  /// Returns the date 17 years ago. Podsquad users must be at least 17 years old.
  DateTime _latestAllowedBirthday() {
    final millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
    final millisecondsSinceEpoch17YearsAgo = millisecondsSinceEpoch - 536479200 * 1000;
    final date17YearsAgo = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch17YearsAgo);
    return date17YearsAgo;
  }

  /// Set my profile data in the database. Set shouldShowSuccessAlert to true if I want to show a dialog indicating
  /// that my profile was updated.
  void _setMyProfileData({bool shouldShowSuccessAlert = false}) {
    // trim leading and trailing whitespaces
    final name = _nameTextController.text.trim();
    final school = _schoolTextController.text.trim();
    final bio = _bioTextController.text.trim();

    // Convert data to a dictionary so that it can be uploaded to Firestore. Image thumbnails are set separately
    // (when the image is selected), so they don't need to be included here.
    final Map<String, dynamic> myProfileDataDict = {
      "name": name,
      "preferredPronouns": _preferredPronouns,
      "lookingFor": _preferredRelationshipType,
      "birthday": _birthday,
      "school": school,
      "bio": bio
    };

    /// Make sure all required fields exist
    if (name.isNotEmpty &&
        _profileThumbnailURL != null &&
        school.isNotEmpty &&
        _preferredPronouns != null &&
        _preferredRelationshipType != null) {
      firestoreDatabase
          .collection("users")
          .doc(myFirebaseUserId)
          .set({"profileData": myProfileDataDict}, SetOptions(merge: true)).then((value) {
        showSingleButtonAlert(
            context: context,
            title:
                MyProfileTabBackendFunctions.shared.isProfileComplete.value ? "Profile Changes Saved!" : "Profile Created!",
            dismissButtonLabel: "OK");
      }).catchError((error) {
        print("An error occurred while setting my profile data: $error");
      });
    }

    if (name.isEmpty)
      showSingleButtonAlert(
          context: context,
          title: "Name Required",
          content: "Please enter your name to continue.",
          dismissButtonLabel: "OK");
    else if (_preferredPronouns != UsefulValues.malePronouns &&
        _preferredPronouns != UsefulValues.femalePronouns &&
        _preferredPronouns != UsefulValues.nonbinaryPronouns)
      showSingleButtonAlert(
          context: context,
          title: "Invalid"
              " Pronouns",
          content: "Preferred pronouns must match either he/him/his, she/her/hers, or they/them/theirs.",
          dismissButtonLabel: "OK");
    else if (_preferredRelationshipType != UsefulValues.lookingForBoyfriend &&
        _preferredRelationshipType != UsefulValues.lookingForGirlfriend &&
        _preferredRelationshipType != UsefulValues.lookingForAnyGenderDate &&
        _preferredRelationshipType != UsefulValues.lookingForFriends)
      showSingleButtonAlert(
          context: context,
          title: "Who Are You Looking For?",
          content: "Please choose whether your are looking for friends or a relationship.",
          dismissButtonLabel: "OK");
    else if (_birthday == null || _birthday == -42069)
      showSingleButtonAlert(
          context: context,
          title: "Invalid Birthday",
          content:
              "Please enter your birthday. Your birthday will not be shown to others, but is required to determine your age.",
          dismissButtonLabel: "OK");
    else if (school.isEmpty)
      showSingleButtonAlert(
          context: context,
          title: "School Required",
          content: "You must be "
              "a current or recent college student to use Podsquad. Please enter the name of your college or university to "
              "continue.",
          dismissButtonLabel: "OK");
    else if (_profileThumbnailURL == null || (_profileThumbnailURL?.isEmpty ?? true))
      showSingleButtonAlert(
          context: context,
          title: "Profile Image Required",
          content: "Please take a picture or select one from the gallery to "
              "continue.",
          dismissButtonLabel: "OK");
  }

  /// Pick an image from the gallery
  void _pickImage({required ImageSource source}) async {
    final pickedImage = await _imagePicker.pickImage(source: source);
    if (pickedImage == null) return;
    await _cropImage(sourcePath: pickedImage.path);

    // If I want to pick my profile image
    if (this.imageFile != null)
      ResizeAndUploadImage.sharedInstance.uploadMyProfileImage(
          image: this.imageFile!,
          onUploadComplete: () {
            showSingleButtonAlert(context: context, title: "Profile Image Updated!", dismissButtonLabel: "OK");
          });
  }

  /// Allow the user to select a square crop from their image
  Future _cropImage({required String sourcePath}) async {
    File? croppedImage = await ImageCropper.cropImage(
        sourcePath: sourcePath,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: "Crop Image", initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
        iosUiSettings: IOSUiSettings(minimumAspectRatio: 1.0, title: "Crop Image"));
    setState(() {
      this.imageFile = croppedImage;
    });
  }

  /// Show a dialog asking the user if they want to sign out
  void showSignOutDialog() {
    final alert =
        CupertinoAlertDialog(title: Text("Sign Out"), content: Text("Are you sure you want to sign out?"), actions: [
      CupertinoButton(
          child: Text("No"),
          onPressed: () {
            dismissAlert(context: context);
          }),
      CupertinoButton(
          child: Text("Yes"),
          onPressed: () {
            dismissAlert(context: context);
            UserAuth.shared.logOut();
          })
    ]);
    showCupertinoDialog(context: context, builder: (context) => alert);
  }

  /// Show a dialog asking the user if they want to delete their account
  void _showDeleteAccountDialog() {
    final alert = CupertinoAlertDialog(
        title: Text("Delete Account"),
        content: Text("Are you sure you want to "
            "permanently delete your Podsquad account? You cannot undo this action."),
        actions: [
          // cancel button
          CupertinoButton(
              child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                dismissAlert(context: context);
              }),

          // delete button
          CupertinoButton(
              child: Text("Yes", style: TextStyle(color: CupertinoColors.destructiveRed)),
              onPressed: () {
                dismissAlert(context: context);
                _deleteAccount(); // delete my account
              })
        ]);
    showCupertinoDialog(context: context, builder: (context) => alert);
  }

  /// Delete the user's account by calling a cloud function
  void _deleteAccount() {
    NearbyScanner.shared.stopPublishAndSubscribe(); // stop listening for nearby users
    final userIDForDeletedUser = myFirebaseUserId; // save the value for the cloud function, because once I delete my
    // account, I won't have access to it
    PushNotificationStatus.shared.unsubscribe(); // unsubscribe from push notifications

    // now delete my account
    firebaseAuth.currentUser?.delete().then((value) {
      // account deleted. Now call a cloud function to erase my data.
      firebaseFunctions.httpsCallable("deleteUserData").call({"userID": userIDForDeletedUser}).catchError((error) {
        print("An error occurred while calling a cloud function to delete my data: $error");
      });

      final alert = CupertinoAlertDialog(
          title: Text("Bye Bye"),
          content: Text("You have successfully deleted your "
              "Podsquad account."),
          actions: [
            CupertinoButton(
                child: Text("OK"),
                onPressed: () {
                  dismissAlert(context: context);
                  UserAuth.shared.logOut();
                })
          ]);
      showCupertinoDialog(context: context, builder: (context) => alert);
    }).catchError((error) {
      // direct the user to sign out and then sign back in again to authenticate
      final alert = CupertinoAlertDialog(
          title: Text("Authentication Required"),
          content: Text("For security reasons,"
              " you must sign out, sign back in, and tap Delete Account again to delete your account."),
          actions: [
            CupertinoButton(
                child: Text("Cancel"),
                onPressed: () {
                  dismissAlert(context: context);
                }),
            CupertinoButton(
                child: Text("Sign Out"),
                onPressed: () {
                  dismissAlert(context: context);
                  UserAuth.shared.logOut(); // sign out
                })
          ]);
      showCupertinoDialog(context: context, builder: (context) => alert);
    });
  }

  @override
  void initState() {
    super.initState();
    // do not want any of these to be value listenable, because otherwise we'd lose pending changes every time the
    // keyboard opened, as the state would reset.
    this._nameTextController.text = MyProfileTabBackendFunctions.shared.myProfileData.value.name;
    this._preferredPronouns = MyProfileTabBackendFunctions.shared.myProfileData.value.preferredPronoun.isEmpty
        ? null
        : MyProfileTabBackendFunctions.shared.myProfileData.value.preferredPronoun;
    this._preferredRelationshipType =
        MyProfileTabBackendFunctions.shared.myProfileData.value.preferredRelationshipType.isEmpty
            ? null
            : MyProfileTabBackendFunctions.shared.myProfileData.value.preferredRelationshipType;

    /// Make sure to replace my birthday if it's equal to the placeholder value, which is -42069
    this._birthday = MyProfileTabBackendFunctions.shared.myProfileData.value.birthday == -42069
        ? _twentyOneYearsAgo()
        : MyProfileTabBackendFunctions.shared.myProfileData.value.birthday;

    this._schoolTextController.text = MyProfileTabBackendFunctions.shared.myProfileData.value.school;
    this._bioTextController.text = MyProfileTabBackendFunctions.shared.myProfileData.value.bio;
    this._profileThumbnailURL = MyProfileTabBackendFunctions.shared.myProfileData.value.thumbnailURL.isEmpty
        ? null
        : MyProfileTabBackendFunctions.shared.myProfileData.value.thumbnailURL;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: Stack(
      children: [
        // Contains the My Profile Tab widget with text fields, the navigation bar, and everything
        CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              padding: EdgeInsetsDirectional.all(5),
              leading: CupertinoButton(
                child: MyProfileTabBackendFunctions.shared.isProfileComplete.value ? Icon(CupertinoIcons
                  .line_horizontal_3) : Icon(CupertinoIcons.question_circle),
                onPressed: () {
                  MyProfileTabBackendFunctions.shared.isProfileComplete.value ? drawerKey.currentState?.openDrawer() :
                  showWelcomeTutorialIfNecessary(context: context, userPressedHelp: true); // open the 
                  // likes/friends/blocks drawer;
                },
                padding: EdgeInsets.zero,
              ),
              largeTitle: Text("My Profile"),
              stretch: true,
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                SafeArea(
                  // contains the view underneath, and a progress spinner if a new profile image is loading
                  child:
                      // contains my profile tab view
                      Column(
                    children: [
                      // Profile Image
                      Padding(
                          padding: EdgeInsets.all(20),
                          child: ValueListenableBuilder(
                              valueListenable: MyProfileTabBackendFunctions.shared.myProfileData,
                              builder: (context, ProfileData profileData, widget) {
                                return profileData.thumbnailURL.isEmpty
                                    ? Icon(CupertinoIcons.person)
                                    : CupertinoButton(padding: EdgeInsets.zero,
                                        child: DecoratedImage(
                                          imageURL: profileData.thumbnailURL,
                                          width: 125.scaledForScreenSize(context: context),
                                          height: 125.scaledForScreenSize(context: context),
                                        ),
                                        onPressed: () {
                                          // Navigate to view my profile (if it's complete)
                                          if (MyProfileTabBackendFunctions.shared.isProfileComplete.value)
                                          Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                                              builder: (context) => ViewPersonDetails(personID: myFirebaseUserId)));

                                          // otherwise, take a picture with the camera
                                          else _pickImage(source: ImageSource.camera);
                                        },
                                      );
                              })),
                      // Profile image and photo section
                      CupertinoFormSection(children: [
                        // Take photo button
                        CupertinoButton(
                          onPressed: () {
                            this._pickImage(source: ImageSource.camera);
                          },
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.camera),
                              Padding(padding: EdgeInsets.only(left: 10), child: Text("Take photo"))
                            ],
                          ),
                        ),

                        // Choose photo button
                        CupertinoButton(
                          onPressed: () {
                            this._pickImage(source: ImageSource.gallery);
                          },
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.photo),
                              Padding(padding: EdgeInsets.only(left: 10), child: Text("Choose from gallery"))
                            ],
                          ),
                        ),

                        // Add more photos button
                        CupertinoButton(
                          onPressed: () {
                            setState(() {
                              _showingMultiImageUploader = !_showingMultiImageUploader; // show or hide my extra images
                            });
                          },
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.photo_on_rectangle),
                              Padding(padding: EdgeInsets.only(left: 10), child: Text("Add more photos"))
                            ],
                          ),
                        ),

                        AnimatedSwitcher(
                            transitionBuilder: (child, animation) {
                              //  final offsetAnimation = Tween<Offset>(begin: Offset(0, -0.1), end: Offset(0, 0))
                              //  .animate(animation);

                              // Use a slide animation to reveal the images, and a size animation to hide them. This
                              // creates the neatest effect.
                              return SizeTransition(
                                sizeFactor: animation,
                                child: child,
                              );
                            },
                            duration: Duration(milliseconds: 250),
                            child: _showingMultiImageUploader ? MultiImageUploader() : Container())
                      ]),

                      // Name, pronouns, lookingFor, Birthday, school, bio, and Update Profile button
                      CupertinoFormSection(header: Text("Profile Info"), children: [
                        // name text field
                        CupertinoTextFormFieldRow(controller: _nameTextController, placeholder: "Name"),

                        // preferred pronouns menu - show an action sheet instead
                        CupertinoFormRow(
                            child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  final sheet = CupertinoActionSheet(
                                    title: Text("Pick Pronouns"),
                                    actions: [
                                      CupertinoActionSheetAction(
                                          child: Text(UsefulValues.malePronouns),
                                          onPressed: () {
                                            _preferredPronouns = UsefulValues.malePronouns;
                                            dismissAlert(context: context);
                                          }),
                                      CupertinoActionSheetAction(
                                          child: Text(UsefulValues.femalePronouns),
                                          onPressed: () {
                                            _preferredPronouns = UsefulValues.femalePronouns;
                                            dismissAlert(context: context);
                                          }),
                                      CupertinoActionSheetAction(
                                          child: Text(UsefulValues.nonbinaryPronouns),
                                          onPressed: () {
                                            _preferredPronouns = UsefulValues.nonbinaryPronouns;
                                            dismissAlert(context: context);
                                          }),

                                      // There is no cancel button because the user must pick a pronoun.
                                    ],
                                  );
                                  showCupertinoModalPopup(context: context, builder: (context) => sheet);
                                },
                                child: Padding(
                                    padding: EdgeInsets.only(left: 5),
                                    child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          _preferredPronouns ?? "Pick your pronouns",
                                          style: TextStyle(
                                              color: _preferredPronouns == null
                                                  ? CupertinoColors.inactiveGray
                                                  : isDarkMode
                                                      ? CupertinoColors.white
                                                      : CupertinoColors.black),
                                        ))))),

                        // preferred relationship type menu
                        CupertinoFormRow(
                            child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  final sheet = CupertinoActionSheet(
                                    title: Text("Pick Relationship Type"),
                                    actions: [
                                      CupertinoActionSheetAction(
                                          child: Text("I want to make friends!"),
                                          onPressed: () {
                                            setState(() {
                                              _preferredRelationshipType = UsefulValues.lookingForFriends;
                                            });
                                            dismissAlert(context: context);
                                          }),
                                      CupertinoActionSheetAction(
                                          child: Text("I want a relationship!"),
                                          onPressed: () {
                                            dismissAlert(
                                                context: context); // dismiss the previous alert and show a new one
                                            final chooseRelationshipTypeSheet =
                                                CupertinoActionSheet(title: Text("Relationship Type"), actions: [
                                              CupertinoActionSheetAction(
                                                  child: Text("I like guys!"),
                                                  onPressed: () {
                                                    setState(() {
                                                      _preferredRelationshipType = UsefulValues.lookingForBoyfriend;
                                                    });
                                                    dismissAlert(context: context);
                                                  }),
                                              CupertinoActionSheetAction(
                                                  child: Text("I like girls!"),
                                                  onPressed: () {
                                                    setState(() {
                                                      _preferredRelationshipType = UsefulValues.lookingForGirlfriend;
                                                    });
                                                    dismissAlert(context: context);
                                                  }),
                                              CupertinoActionSheetAction(
                                                  child: Text("I like all genders!"),
                                                  onPressed: () {
                                                    setState(() {
                                                      _preferredRelationshipType = UsefulValues.lookingForAnyGenderDate;
                                                    });
                                                    dismissAlert(context: context);
                                                  })
                                            ]);
                                            showCupertinoModalPopup(
                                                context: context, builder: (context) => chooseRelationshipTypeSheet);
                                          })
                                    ],
                                  );
                                  showCupertinoModalPopup(context: context, builder: (context) => sheet);
                                },
                                child: Padding(
                                    padding: EdgeInsets.only(left: 5),
                                    child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          _preferredRelationshipType?.formattedPronounForDisplay() ??
                                              "Select a relationship preference",
                                          style: TextStyle(
                                              color: _preferredRelationshipType == null
                                                  ? CupertinoColors.inactiveGray
                                                  : isDarkMode
                                                      ? CupertinoColors.white
                                                      : CupertinoColors.black),
                                        ))))),

                        // birthday picker
                        Align(
                            alignment: Alignment.centerLeft,
                            child: CupertinoButton(padding: EdgeInsets.only(left: 8),
                                child: Text(
                                      _birthday == -42069
                                          ? "Select "
                                              "your "
                                              "birthday"
                                          : "${DateTime.fromMillisecondsSinceEpoch((_birthday! * 1000).toInt()).month.toHumanReadableMonth()} "
                                              "${DateTime.fromMillisecondsSinceEpoch((_birthday! * 1000).toInt()).day}, ${DateTime.fromMillisecondsSinceEpoch((_birthday! * 1000).toInt()).year}",
                                      style: TextStyle(
                                          color: _birthday == -42069
                                              ? CupertinoColors.inactiveGray
                                              : isDarkMode
                                                  ? CupertinoColors.white
                                                  : CupertinoColors.black),
                                    ),
                                onPressed: () {
                                  // show a sheet where the user can pick their birthday
                                  showCupertinoModalPopup(
                                      context: context,
                                      builder: (context) {
                                        return Container(
                                          height: 200,
                                          child: CupertinoPageScaffold(
                                            child: Column(
                                              children: [
                                                Padding(
                                                    padding: EdgeInsets.all(10),
                                                    child: Text(
                                                      "Enter Birthday",
                                                      style: TextStyle(
                                                          color: isDarkMode
                                                              ? CupertinoColors.white
                                                              : CupertinoColors.black),
                                                    )),
                                                Expanded(
                                                    child: Padding(
                                                        padding: EdgeInsets.only(top: 20),
                                                        child: CupertinoDatePicker(
                                                            onDateTimeChanged: (DateTime selectedBirthday) {
                                                              setState(() {
                                                                this._birthday =
                                                                    selectedBirthday.millisecondsSinceEpoch *
                                                                        0.001; // divide by 1000 to convert to
                                                                // seconds, since that's how the native iOS app handles time.
                                                              });
                                                            },
                                                            initialDateTime: DateTime.fromMillisecondsSinceEpoch(
                                                                ((_birthday ?? _twentyOneYearsAgo()) * 1000).toInt()),
                                                            minimumDate: _earliestAllowedBirthday(),
                                                            maximumDate: _latestAllowedBirthday(),
                                                            mode: CupertinoDatePickerMode.date))),
                                                Padding(
                                                  padding: EdgeInsets.all(5),
                                                  child: CupertinoButton(
                                                    child: Text("Done"),
                                                    onPressed: () {
                                                      dismissAlert(context: context);
                                                    },
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      });
                                })),

                        // school text field
                        CupertinoTextFormFieldRow(controller: _schoolTextController, placeholder: "School"),

                        // bio text field
                        CupertinoTextFormFieldRow(controller: _bioTextController, placeholder: "Bio", maxLines: null),

                        // Set profile data button
                        Align(
                            alignment: Alignment.centerLeft,
                            child: CupertinoButton(
                                child: Center(
                                    child: Text(MyProfileTabBackendFunctions.shared.isProfileComplete.value
                                        ? "Update Profile"
                                        : "Create Profile")),
                                onPressed: _setMyProfileData)),
                      ]),

                      // Sign out and delete account section
                      CupertinoFormSection(header: Text("Other Options"), children: [
                        // sign out button
                        Align(
                            alignment: Alignment.centerLeft,
                            child: CupertinoButton(
                                child: Center(child: Text("Sign Out")),
                                onPressed: () {
                                  showSignOutDialog();
                                })),

                        // delete account button
                        Align(
                            alignment: Alignment.centerLeft,
                            child: CupertinoButton(
                                child: Center(
                                    child: Text("Delete Account",
                                        style: TextStyle(color: CupertinoColors.destructiveRed))),
                                onPressed: () {
                                  _showDeleteAccountDialog();
                                })),
                      ])
                    ],
                  ),
                )
              ]),
            )
          ],
        ),

        // Contains the image upload progress spinner
        Center(
          child: ValueListenableBuilder(
              valueListenable: ResizeAndUploadImage.sharedInstance.isUploadInProgress,
              builder: (context, bool inProgress, widget) {
                if (inProgress) {
                  return Stack(
                    children: [
                      BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Container(color: CupertinoColors.black.withOpacity(0.1))),
                      Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoActivityIndicator(radius: 15),
                          Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(
                                "Uploading Image...",
                                style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                              ))
                        ],
                      ))
                    ],
                  );
                } else
                  return Container(); // return an empty widget if there's no image loading
              }),
        )
      ],
    ));
  }
}
