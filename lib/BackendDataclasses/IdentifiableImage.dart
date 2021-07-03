import 'package:uuid/uuid.dart';

///Allows a user's (up to 5) extra images to be identified and sorted by position.
class IdentifiableImage {
  var _uuid = Uuid();

  late String id;
  String imageURL;
  String? caption;
  int position;

  IdentifiableImage({String? id, required this.imageURL, this.caption, required this.position}){
    //If no ID is passed in (id is null), then use a randomly generated ID. However, if a value is passed in for id, then use that as the image ID.
    this.id = id == null ? this._uuid.v1() : id;
  }

  // Declare that two objects are the same if and only if they have the same ID.
  @override
  bool operator ==(Object otherInstance) =>
      otherInstance is IdentifiableImage && id == otherInstance.id;

  @override
  int get hashCode => id.hashCode;
}