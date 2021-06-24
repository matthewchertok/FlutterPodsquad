import 'package:flutter/cupertino.dart';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';

String get myFirebaseUserId => (FirebaseAuth.instance.currentUser?.uid ?? "null");

///A reference to the Firestore database object used throughout the app
FirebaseFirestore firestoreDatabase = FirebaseFirestore.instance;

///A reference to the Firebase Storage object used throughout the app
FirebaseStorage firebaseStorage = FirebaseStorage.instance;

///A reference to a Firebase Functions object used throughout the app
FirebaseFunctions firebaseFunctions = FirebaseFunctions.instance;

class UsefulValues {
  ///Equal to "he/him/his"
  static final malePronouns = "he/him/his";

  ///Equal to "she/her/hers"
  static final femalePronouns = "she/her/hers";

  ///Equal to "they/them/theirs"
  static final nonbinaryPronouns = "they/them/theirs";

  ///Equal to "friends" - indicates that the user is looking to meet friends
  static final lookingForFriends = "friends";

  ///Equal to "boyfriend" - indicates that the user is looking to meet a boyfriend
  static final lookingForBoyfriend = "boyfriend";

  ///Equal to "girlfriend" - indicates that the user is looking to meet a girlfriend
  static final lookingForGirlfriend = "girlfriend";

   ///Equal to "date" - indicates that the user is looking for a relationship but the partner's gender doesn't matter.
  static final lookingForAnyGenderDate = "date";
}

///Calculates a logarithm with a specified base using the change of base formula
double logWithBase({required double base, required double x}){
  return log(x)/log(base);
}

///Identifies an image in the assets folder. Pass in the name of the image only. For example, if the image was named
///"Podsquad.png", then to use that image, call image(named: "Podsquad.png").
Image image({required String named}){
  return Image.asset('assets/$named');
}