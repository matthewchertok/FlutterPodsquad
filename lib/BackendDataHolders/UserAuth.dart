import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class UserAuth {
  static final shared = UserAuth();
  User? currentUser;
  late ValueNotifier<bool> isLoggedIn;

  UserAuth(){
    this.currentUser = FirebaseAuth.instance.currentUser;
    this.isLoggedIn.value = currentUser != null; // I'm logged in if the value of currentUser is not null.
  }

  void login(){
    this.isLoggedIn.value = true;
  }

  void logOut(){
    this.isLoggedIn.value = false;
  }
}