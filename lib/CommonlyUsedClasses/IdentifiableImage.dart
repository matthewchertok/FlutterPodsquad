import 'package:uuid/uuid.dart';

///Allows a user's (up to 5) extra images to be identified and sorted by position.
class IdentifiableImage {
  var id = Uuid();
  var imageURL;
  var position;

  IdentifiableImage({Uuid? id, required String imageURL, required int position}){
    //If no ID is passed in (id is null), then use a randomly generated ID. However, if a value is passed in for id, then use that as the image ID.
    this.id = id == null ? this.id : id;
    this.imageURL = imageURL;
    this.position = position;
  }
}