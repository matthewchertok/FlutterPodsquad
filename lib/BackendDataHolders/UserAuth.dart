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
  void logOut({Function? onCompletion}) {
    firebaseAuth.signOut().then((value) {
      this.isLoggedIn.value = false;
      if (onCompletion != null) onCompletion();
    }).catchError((error) {
      print("An error occurred while trying to sign out: $error");
    });
  }
}
