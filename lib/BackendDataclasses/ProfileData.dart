import 'package:podsquad/BackendDataclasses/IdentifiableImage.dart';
import 'package:podsquad/BackendDataclasses/MatchSurveyData.dart';
import 'package:podsquad/BackendFunctions/TimeAndDateFunctions.dart';

class ProfileData {

  /// A blank ProfileData object with all fields empty and the birthday equal to the number of seconds since January
  /// 1, 1970 on this day 21 years ago.
  static final blank = ProfileData(userID: "", name: "", preferredPronoun: "", preferredRelationshipType: "",
  birthday: (DateTime.now().millisecondsSinceEpoch - 662709600 * 1000)*0.001, school: "", bio: "", podScore:
  0, thumbnailURL:
  "", fullPhotoURL: "");

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
  List<IdentifiableImage>? extraImagesList;

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
      this.matchSurveyData, this.extraImagesList});

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
