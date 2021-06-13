///A class containing all the required fields to properly set a document containing pod member data
class PodMemberInfoDict {
  String userID;
  bool active;
  String bio;
  double birthday;
  bool blocked;
  double joinedAt;
  String name;
  String thumbnailURL;
  bool typing;

  PodMemberInfoDict(
      {required this.userID,
      this.active = true,
      required this.bio,
      required this.birthday,
      this.blocked = false,
      required this.joinedAt,
      required this.name,
      required this.thumbnailURL,
      this.typing = false});

  ///Convert the object into a dictionary that can be uploaded to a Firestore document.
  Map<String, dynamic> toDatabaseFormat() => {
        "active": this.active,
        "bio": this.bio,
        "birthday": this.birthday,
        "blocked": this.blocked,
        "joinedAt": this.joinedAt,
        "name": this.name,
        "thumbnailURL": this.thumbnailURL,
        "typing": this.typing,
        "userID": this.userID
      };
}
