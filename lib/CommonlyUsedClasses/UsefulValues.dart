import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';

import 'package:flutter/scheduler.dart';

String get myFirebaseUserId => (FirebaseAuth.instance.currentUser?.uid ?? "");

///A reference to the Firestore database object used throughout the app
final FirebaseFirestore firestoreDatabase = FirebaseFirestore.instance;

///A reference to the Firebase Storage object used throughout the app
final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

///A reference to a Firebase Functions object used throughout the app
final FirebaseFunctions firebaseFunctions = FirebaseFunctions.instance;

/// A reference to a Firebase Auth object that is used throughout the app
final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

/// A reference to a FirebaseMessaging object used throughout the app
final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

class UsefulValues {
  ///Equal to "he/him/his"
  static const malePronouns = "he/him/his";

  ///Equal to "she/her/hers"
  static const femalePronouns = "she/her/hers";

  ///Equal to "they/them/theirs"
  static const nonbinaryPronouns = "they/them/theirs";

  ///Equal to "friends" - indicates that the user is looking to meet friends
  static const lookingForFriends = "friends";

  ///Equal to "boyfriend" - indicates that the user is looking to meet a boyfriend
  static const lookingForBoyfriend = "boyfriend";

  ///Equal to "girlfriend" - indicates that the user is looking to meet a girlfriend
  static const lookingForGirlfriend = "girlfriend";

  ///Equal to "date" - indicates that the user is looking for a relationship but the partner's gender doesn't matter.
  static const lookingForAnyGenderDate = "date";
}

///Calculates a logarithm with a specified base using the change of base formula
double logWithBase({required double base, required double x}) {
  return log(x) / log(base);
}

///Identifies an image in the assets folder. Pass in the name of the image only. For example, if the image was named
///"Podsquad.png", then to use that image, call image(named: "Podsquad.png").
Image image({required String named}) {
  return Image.asset('assets/$named');
}

/// The light mode accent color
const lightModeAccentColor = Color(0xff6258ff);

/// The dark mode accent color
const darkModeAccentColor = Color(0xff7e76ff);

/// A dynamic accent color that adjusts depending on whether the app is in light or dark mode.
const accentColor = CupertinoDynamicColor(
    color: lightModeAccentColor,
    darkColor: darkModeAccentColor,
    highContrastColor: lightModeAccentColor,
    darkHighContrastColor: darkModeAccentColor,
    elevatedColor: lightModeAccentColor,
    darkElevatedColor: darkModeAccentColor,
    highContrastElevatedColor: lightModeAccentColor,
    darkHighContrastElevatedColor: darkModeAccentColor);

/// The light mode accent color for a received message
const lightModeReceivedMessageColor = Color(0xfff86800);

/// The dark mode accent color for a received message
const darkModeReceivedMessageColor = Color(0xfff87215);

/// A dynamic accent color for received message bubbles that adjusts depending on whether the app is in light or dark
/// mode.
const receivedMessageBubbleColor = CupertinoDynamicColor(
    color: lightModeReceivedMessageColor,
    darkColor: darkModeReceivedMessageColor,
    highContrastColor: lightModeReceivedMessageColor,
    darkHighContrastColor: darkModeReceivedMessageColor,
    elevatedColor: lightModeReceivedMessageColor,
    darkElevatedColor: darkModeReceivedMessageColor,
    highContrastElevatedColor: lightModeReceivedMessageColor,
    darkHighContrastElevatedColor: darkModeReceivedMessageColor);

Brightness? get _brightness => SchedulerBinding.instance?.window.platformBrightness;

/// Determine whether the app is in dark mode
bool get isDarkMode => _brightness == Brightness.dark;

/// Dismiss an alert
void dismissAlert({required BuildContext context}) {
  Navigator.of(context, rootNavigator: true).pop();
  FocusScope.of(context).requestFocus(FocusNode()); // stop any text fields from becoming active inadvertently
}

/// Hide the keyboard
void hideKeyboard({required BuildContext context}){
  FocusScope.of(context).requestFocus(FocusNode());
}
