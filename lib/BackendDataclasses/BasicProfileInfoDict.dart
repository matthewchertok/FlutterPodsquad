///A class containing all the required fields to properly set a document when liking, friending, blocking, or meeting someone.
class BasicProfileInfoDict {
  String userID;
  String name;
  double birthday;
  String bio;
  String thumbnailURL;
  List<String> fcmTokens;

  BasicProfileInfoDict({required this.userID,
    required this.name,
    required this.birthday,
    required this.bio,
    required this.thumbnailURL, required this.fcmTokens});

  ///Convert the object into a dictionary that can be uploaded to a Firestore document.
  Map<String, dynamic> toDatabaseFormat() =>
      {
        "bio": this.bio,
        "birthday": this.birthday,
        "name": this.name,
        "thumbnailURL": this.thumbnailURL,
        "userID": this.userID,
        "fcmTokens": this.fcmTokens
      };
}
