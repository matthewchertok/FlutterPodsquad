import 'package:podsquad/BackendDataclasses/MatchSurveyData.dart';
import 'package:podsquad/CommonlyUsedClasses/TimeAndDateFunctions.dart';

class ProfileData {
  String name;
  String preferredPronoun;
  String preferredRelationshipType;

  ///The person's birthday, expressed as seconds since January 1, 1970.
  double birthday;

  int get age {
    return TimeAndDateFunctions.getAgeFromBirthday(birthday: birthday);
  }

  String school;
  String bio;
  int podScore;
  String thumbnailURL;
  String fullPhotoURL;
  String userID;
  double? timeIMetThePerson;
  DateTime? dateIMetThePerson;

  MatchSurveyData? matchSurveyData;

  ProfileData(
      {required this.userID,
      required this.name,
      required this.preferredPronoun,
      required this.preferredRelationshipType,
      required this.birthday,
      required this.school,
      required this.bio,
      required this.podScore,
      required this.thumbnailURL,
      required this.fullPhotoURL,
      this.timeIMetThePerson,
      this.dateIMetThePerson,
      this.matchSurveyData});

  ///Convert the object into a dictionary that can be set to Firestore. Format is {"bio: "...", "birthday: 123, name: "...", thumbnailURL: "...", userID: "..."}
  Map<String, dynamic> toDatabaseFormat() {
    return {
      "bio": bio,
      "birthday": birthday,
      "name": name,
      "thumbnailURL": thumbnailURL,
      "userID": userID
    };
  }

  // Declare that two ProfileData objects are the same if and only if they have the same ID.
  @override
  bool operator ==(Object otherInstance) =>
      otherInstance is ProfileData && userID == otherInstance.userID;

  @override
  int get hashCode => userID.hashCode;
}
