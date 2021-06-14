class PodData {
  String name;
  double dateCreated;
  String description;
  bool anyoneCanJoin;
  String podID;
  String podCreatorID;
  String thumbnailURL;
  String fullPhotoURL;
  int podScore;

  PodData(
      {required this.name,
      required this.dateCreated,
      required this.description,
      required this.anyoneCanJoin,
      required this.podID,
      required this.podCreatorID,
      required this.thumbnailURL,
      required this.fullPhotoURL,
      required this.podScore});


  // Declare that two PodData objects are the same if and only if they have the same ID.
  @override
  bool operator ==(Object otherInstance) =>
      otherInstance is PodData && podID == otherInstance.podID;

  @override
  int get hashCode => podID.hashCode;
}