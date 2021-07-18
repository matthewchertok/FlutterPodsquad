import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';

class ProfileDatabasePaths {
  ///Points to the collection /users
  final CollectionReference usersNodeRef =
  firestoreDatabase.collection("users");

  ///Points to the document /users/userID
  late final DocumentReference userDataRef;

  ///Points to the collection /nearby-people
  final CollectionReference listOfPeopleIMetRef =
  firestoreDatabase.collection("nearby-people");

  ///Points to the /user path in Firebase Storage.
  final Reference _storageRootRef = firebaseStorage.ref().child("user");

  ///Points to the /user/userID path in Firebase Storage.
  late final Reference storageUserRef;

  ///Points to /user/userID/thumbnail in Firebase Storage
  late final Reference profileImageThumbnailRef;

  ///Points to /user/userID/full image in Firebase Storage
  late final Reference profileImageFullImageRef;

  ///Points to /user/userID/extra images in Firebase Storage
  late final Reference extraImagesStorageRef;

  ///Points to /messaging-images in Firebase Storage
  final Reference messagingImagesStorageRef =
  firebaseStorage.ref().child("messaging-images");

  ProfileDatabasePaths({String userID = "doesNotMatter"}) {
    this.userDataRef = usersNodeRef.doc(userID);
    this.storageUserRef = _storageRootRef.child(userID);
    this.profileImageThumbnailRef = storageUserRef.child("thumbnail");
    this.profileImageFullImageRef = storageUserRef.child("full image");
    this.extraImagesStorageRef = storageUserRef.child("extra images");
  }

  ///Returns a ProfileData object from a database snapshot of a user's profile data. First, say profileData = extractProfileDataFromSnapshot,
  ///then download the profile photo using profileData.thumbnailURL. Inside the completion handler of the download function,
  ///add profileData.thumbnail = theImageThatJustDownloaded
  static ProfileData extractProfileDataFromSnapshot(
      {required String userID, required Map<String,
          dynamic> snapshotValue, double? timeIMetThePerson, DateTime? dateIMetThePerson}) {
    String name = snapshotValue["name"] ?? "Name N/A";
    String preferredPronoun = snapshotValue["preferredPronouns"] ?? UsefulValues.nonbinaryPronouns;
    String preferredRelationshipType = snapshotValue["lookingFor"] ?? UsefulValues.lookingForFriends;
    num? birthdayRaw = snapshotValue["birthday"];
    double birthday = birthdayRaw?.toDouble() ?? 0;
    String school = snapshotValue["school"] ?? "School N/A";
    String bio = snapshotValue["bio"] ?? "";
    String thumbnailURLString = snapshotValue["thumbnailURL"] ?? "";
    String fullPhotoURLString = snapshotValue["fullPhotoURL"] ?? "";
    num? podScoreRaw = snapshotValue["podScore"];
    int podScore = podScoreRaw?.toInt() ?? 0;

    return ProfileData(userID: userID,
        name: name,
        preferredPronoun: preferredPronoun,
        preferredRelationshipType: preferredRelationshipType,
        birthday: birthday,
        school: school,
        bio: bio,
        thumbnailURL: thumbnailURLString,
        fullPhotoURL: fullPhotoURLString,
        podScore: podScore);
  }
}
