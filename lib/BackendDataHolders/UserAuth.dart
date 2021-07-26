import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';

class UserAuth {
  static final shared = UserAuth();
  User? currentUser = firebaseAuth.currentUser;
  ValueNotifier<bool> isLoggedIn = ValueNotifier(firebaseAuth.currentUser != null);

  ///Changes isLoggedIn to true to update the UI. Does not handle Firebase stuff; that must be done separately.
  void updateUIToLoggedInView() {
    this.isLoggedIn.value = true;
  }

  ///Handles sign out logic and updates the UI.
  Future<void> logOut({Function? onCompletion}) async {
    final myPreviousID = myFirebaseUserId; // save the value before I sign out
    await firebaseAuth.signOut().catchError((error) {
      print("An error occurred while trying to sign out: $error");
    });

    /// Delete a messaging token from the database when a user signs out, so that they don't receive notifications on
    /// devices where they aren't signed in
    final fcmToken = await firebaseMessaging.getToken();
    if (fcmToken != null){
      await firestoreDatabase.collection("users").doc(myPreviousID).set({
        // remember, this must be an array because a user can be
        // signed in (and therefore receive notifications) on multiple devices
        "fcmTokens": FieldValue.arrayRemove([fcmToken])
      }, SetOptions(merge: true));
      this.isLoggedIn.value = false;
      if (onCompletion != null) onCompletion();
    }
  }
}
