import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:podsquad/BackendDataclasses/MatchSurveyData.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/BackendDataclasses/BasicProfileInfoDict.dart';
import 'package:podsquad/BackendDataclasses/IdentifiableImage.dart';
import 'package:podsquad/BackendDataclasses/PodMemberInfoDict.dart';
import 'package:podsquad/BackendFunctions/TimeAndDateFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/DatabasePaths/ProfileDatabasePaths.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

class MyProfileTabBackendFunctions {
  static final shared = MyProfileTabBackendFunctions();

  /// Access this property on the shared instance of the class to determine whether my profile is complete.
  ValueNotifier<bool> isProfileComplete = ValueNotifier(true); // default to true, but set to false immediately if it
  // turns
  // out
  // profile is
  // not
  // complete.

  ///Stores my profile data. ONLY ACCESS THIS ON THE .shared INSTANCE! (Otherwise it'll be empty). Listen using a ValueListenerBuilder widget.
  ValueNotifier<ProfileData> myProfileData = ValueNotifier(ProfileData(
      userID: (myFirebaseUserId),
      name: "",
      preferredPronoun: "",
      preferredRelationshipType: "",
      birthday: -42069,
      // put in a dummy value so we know if this hasn't been set yet
      school: "",
      bio: "",
      podScore: 0,
      thumbnailURL: "",
      fullPhotoURL: "",
      fcmTokens: []));

  ///Stores my match survey data
  ValueNotifier<MatchSurveyData> myMatchSurveyData = ValueNotifier(MatchSurveyData(
      age: 21,
      career: 1,
      goOutFreq: 1,
      exerciseInterest: 1,
      dineOutInterest: 1,
      artInterest: 1,
      gamingInterest: 1,
      clubbingInterest: 1,
      readingInterest: 1,
      tvShowsInterest: 1,
      musicInterest: 1,
      shoppingInterest: 1,
      importanceOfAttraction: 1,
      rawImportanceOfAttractiveness: 1,
      importanceOfSincerity: 1,
      rawImportanceOfSincerity: 1,
      importanceOfIntelligence: 1,
      rawImportanceOfIntelligence: 1,
      importanceOfFun: 1,
      rawImportanceOfFun: 1,
      importanceOfAmbition: 1,
      rawImportanceOfAmbition: 1,
      importanceOfSharedInterests: 1,
      rawImportanceOfSharedInterests: 1,
      attractiveness: 1,
      sincerity: 1,
      intelligence: 1,
      fun: 1,
      ambition: 1));

  ///Determines whether to show the loading spinner when loading my profile thumbnail.
  ValueNotifier<bool> isLoadingProfileImage = ValueNotifier(false);

  set _myExtraImagesList(List<IdentifiableImage> myExtraImagesList) {
    myExtraImagesList
        .sort((image1, image2) => image1.position.compareTo(image2.position)); // now sort the images by position
    mySortedExtraImagesList.value =
        myExtraImagesList; // assign the sorted list to be equal to the sorted list of images
  }

  ///Stores my (max 5) additional profile images, sorted by position
  ValueNotifier<List<IdentifiableImage>> mySortedExtraImagesList = ValueNotifier([]);

  ///A map containing the entire contents of my profile data document (profile data, extra images, and match survey data)
  Map<String, dynamic>? myProfileDocument;

  ///Access this property for the required data to join a pod
  PodMemberInfoDict get myDataToIncludeWhenJoiningAPod => PodMemberInfoDict(
      userID: myProfileData.value.userID,
      bio: myProfileData.value.bio,
      birthday: myProfileData.value.birthday,
      joinedAt: DateTime.now().millisecondsSinceEpoch * 0.001,
      name: myProfileData.value.name,
      thumbnailURL: myProfileData.value.thumbnailURL,
      fcmTokens: myProfileData.value.fcmTokens);

  ///Access this property for the required data to like, friend, block, or meet someone
  BasicProfileInfoDict get myDataToIncludeWhenLikingFriendingBlockingOrMeetingSomeone => BasicProfileInfoDict(
      userID: myProfileData.value.userID,
      name: myProfileData.value.name,
      birthday: myProfileData.value.birthday,
      bio: myProfileData.value.bio,
      thumbnailURL: myProfileData.value.thumbnailURL,
      fcmTokens: myProfileData.value.fcmTokens);

  ///Keep track of all stream subscriptions (realtime listeners) so I can remove them later
  List<StreamSubscription> listenerRegistrations = [];

  ///Resets the shared instance when the user signs out
  void reset() {
    listenerRegistrations.forEach((listener) {
      listener.cancel();
    });
    listenerRegistrations = [];
    _myExtraImagesList = [];
    isLoadingProfileImage.value = false;
    myProfileData = ValueNotifier(ProfileData(
        userID: "userID",
        name: "name",
        preferredPronoun: "preferredPronoun",
        preferredRelationshipType: "preferredRelationshipType",
        birthday: 0,
        school: "school",
        bio: "bio",
        podScore: 0,
        thumbnailURL: "thumbnailURL",
        fullPhotoURL: "fullPhotoURL",
        fcmTokens: []));
    myMatchSurveyData = ValueNotifier(MatchSurveyData(
        age: 1,
        career: 1,
        goOutFreq: 1,
        exerciseInterest: 1,
        dineOutInterest: 1,
        artInterest: 1,
        gamingInterest: 1,
        clubbingInterest: 1,
        readingInterest: 1,
        tvShowsInterest: 1,
        musicInterest: 1,
        shoppingInterest: 1,
        importanceOfAttraction: 1,
        rawImportanceOfAttractiveness: 1,
        importanceOfSincerity: 1,
        rawImportanceOfSincerity: 1,
        importanceOfIntelligence: 1,
        rawImportanceOfIntelligence: 1,
        importanceOfFun: 1,
        rawImportanceOfFun: 1,
        importanceOfAmbition: 1,
        rawImportanceOfAmbition: 1,
        importanceOfSharedInterests: 1,
        rawImportanceOfSharedInterests: 1,
        attractiveness: 1,
        sincerity: 1,
        intelligence: 1,
        fun: 1,
        ambition: 1));
  }

  ///ONLY CALL THIS FUNCTION ON THE SHARED INSTANCE OF THE CLASS! Gets my profile and match survey data from the database.
  Future getMyProfileData() async {
    _myExtraImagesList = []; // reset this list when the function is called to ensure I don't get duplicate items
    final profileDataDocumentListener =
        ProfileDatabasePaths(userID: myFirebaseUserId).userDataRef.snapshots().listen((docSnapshot) {
      if (docSnapshot.exists) {
        this.myProfileDocument = docSnapshot.data() as Map<String, dynamic>?;

        final value = docSnapshot.get("profileData") as Map<String, dynamic>?;
        if (value != null) {
          num? myBirthdayRaw = value["birthday"];
          double? myBirthday = myBirthdayRaw?.toDouble();
          String? myName = value["name"];
          String? mySchool = value["school"];
          String? myPreferredPronouns = value["preferredPronouns"];
          String? myPreferredRelationshipType = value["lookingFor"];
          String? myBio = value["bio"];
          double? myPodScoreFromDatabase =
              value["podScore"]; // podScore might be stored as a double in the database if I change the formula
          int? myPodScore = myPodScoreFromDatabase?.toInt(); // truncate to an integer to make it nicer for display
          String? myThumbnailURL = value["photoThumbnailURL"];
          String? myFullPhotoURL = value["fullPhotoURL"];

          // get my FCM device tokens
          final docData = docSnapshot.data() as Map;
          final fcmTokensRaw = docData["fcmTokens"] as List<dynamic>? ?? [];
          final fcmTokens = List<String>.from(fcmTokensRaw);

          this.isProfileComplete.value = myName != null &&
              myBirthday != null &&
              myThumbnailURL != null &&
              myFullPhotoURL != null &&
              mySchool != null &&
              myPreferredPronouns != null &&
              myPreferredRelationshipType != null &&
              firebaseAuth.currentUser != null;

          //Update the value of myProfileData now that all the data is available. I need to clear my profile data
          // first to force a ValueNotifier change; this is because ProfileData is defined such that two objects are
          // different only if they have different userID properties. Thus, if I change only the thumbnailURL, the
          // ValueNotifier won't notify its listeners.
          this.myProfileData.value = ProfileData.blank;
          this.myProfileData.value = ProfileData(
              userID: myFirebaseUserId,
              name: myName ?? "",
              preferredPronoun: myPreferredPronouns ?? "",
              preferredRelationshipType: myPreferredRelationshipType ?? "",
              birthday: myBirthday ?? -42069,
              school: mySchool ?? "",
              bio: myBio ?? "",
              podScore: myPodScore ?? 0,
              thumbnailURL: myThumbnailURL ?? "",
              fullPhotoURL: myFullPhotoURL ?? "",
              fcmTokens: fcmTokens);

          //Now add in my extra images
          ///Maps like this: {imageID: {caption: "someCaption", imageURL: "someURLString", position: 0}}
          final myImagesDict = docData["extraImages"];
          mySortedExtraImagesList.value.clear(); // clear the value to force a state reset
          List<IdentifiableImage> imagesList = []; // first, read in all the images I currently have
          if (myImagesDict != null) {
            myImagesDict.forEach((imageID, imageData) {
              String? imageURLString = imageData["imageURL"];
              int? position = imageData["position"];
              String? caption = imageData["caption"];
              if (imageURLString != null && position != null) {
                final identifiableImage =
                    IdentifiableImage(imageURL: imageURLString, caption: caption, position: position, id: imageID);

                //Now let's add each image to my extra images list.
                imagesList.add(identifiableImage); // now add the most recent image to the list
              }
            });
            _myExtraImagesList =
                imagesList; // changing this set-only variable will automatically sort all images by position and
            // update mySortedExtraImagesList accordingly
            myProfileData.value.extraImagesList = imagesList; // this isn't currently being used, but I'm adding it
            // just for consistency

            //remove any images that no longer exist in the database
            final imageIDsInDatabase = myImagesDict.keys;
            var imageList = mySortedExtraImagesList.value; // read in the current images list
            mySortedExtraImagesList.value.forEach((imageOnDevice) {
              final imageIDonDevice = imageOnDevice.id;
              if (!imageIDsInDatabase.contains(imageIDonDevice)) {
                imageList.removeWhere((element) => element.id == imageOnDevice.id); // remove the image from the
                // device if it doesn't exist in the database as well
                // mySortedExtraImagesList.value with the new value
              }
            });
            _myExtraImagesList = imageList; // update the set-only variable, which will then update
          }

          final surveyData = docData["matchSurvey"] as Map?;
          if (surveyData != null) {
            final career = surveyData["career"] as int;
            final goOutFreq = surveyData["goOutFreq"] as int;
            final exerciseInterest = surveyData["exerciseInterest"] as int;
            final dineOutInterest = surveyData["dineOutInterest"] as int;
            final artInterest = surveyData["artInterest"] as int;
            final gamingInterest = surveyData["gamingInterest"] as int;
            final clubbingInterest = surveyData["clubbingInterest"] as int;
            final readingInterest = surveyData["readingInterest"] as int;
            final tvShowInterest = surveyData["tvShowInterest"] as int;
            final musicInterest = surveyData["musicInterest"] as int;
            final shoppingInterest = surveyData["shoppingInterest"] as int;
            final impAttractive = surveyData["attractivenessImportance"] as double;
            final rawImpAttractive = surveyData["attractivenessImportance_raw"] as int;
            final impSincere = surveyData["sincerityImportance"] as double;
            final rawImpSincere = surveyData["sincerityImportance_raw"] as int;
            final impIntelligence = surveyData["intelligenceImportance"] as double;
            final rawImpIntelligence = surveyData["intelligenceImportance_raw"] as int;
            final impFun = surveyData["funImportance"] as double;
            final rawImpFun = surveyData["funImportance_raw"] as int;
            final impAmbition = surveyData["ambitionImportance"] as double;
            final rawImpAmbition = surveyData["ambitionImportance_raw"] as int;
            final impSharedInterests = surveyData["sharedInterestsImportance"] as double;
            final rawImpSharedInterests = surveyData["sharedInterestsImportance_raw"] as int;
            final myAttractiveness = surveyData["myAttractiveness"] as int;
            final mySincerity = surveyData["mySincerity"] as int;
            final myIntelligence = surveyData["myIntelligence"] as int;
            final myFun = surveyData["myFun"] as int;
            final myAmbition = surveyData["myAmbition"] as int;

            //Round the values to the nearest hundredth place before feeding into the ML model, since the training data
            // was rounded to the nearest hundredth.
            final roundedImpAttractive = impAttractive.roundToDecimalPlace(2);
            final roundedImpSincere = impSincere.roundToDecimalPlace(2);
            final roundedImpIntelligence = impIntelligence.roundToDecimalPlace(2);
            final roundedImpFun = impFun.roundToDecimalPlace(2);
            final roundedImpAmbition = impAmbition.roundToDecimalPlace(2);
            final roundedImpSharedInterests = impSharedInterests.roundToDecimalPlace(2);
            if (myBirthday != null) {
              final myAge = TimeAndDateFunctions.getAgeFromBirthday(birthday: myBirthday);
              this.myMatchSurveyData.value = MatchSurveyData(
                  age: myAge,
                  career: career,
                  goOutFreq: goOutFreq,
                  exerciseInterest: exerciseInterest,
                  dineOutInterest: dineOutInterest,
                  artInterest: artInterest,
                  gamingInterest: gamingInterest,
                  clubbingInterest: clubbingInterest,
                  readingInterest: readingInterest,
                  tvShowsInterest: tvShowInterest,
                  musicInterest: musicInterest,
                  shoppingInterest: shoppingInterest,
                  importanceOfAttraction: roundedImpAttractive,
                  rawImportanceOfAttractiveness: rawImpAttractive,
                  importanceOfSincerity: roundedImpSincere,
                  rawImportanceOfSincerity: rawImpSincere,
                  importanceOfIntelligence: roundedImpIntelligence,
                  rawImportanceOfIntelligence: rawImpIntelligence,
                  importanceOfFun: roundedImpFun,
                  rawImportanceOfFun: rawImpFun,
                  importanceOfAmbition: roundedImpAmbition,
                  rawImportanceOfAmbition: rawImpAmbition,
                  importanceOfSharedInterests: roundedImpSharedInterests,
                  rawImportanceOfSharedInterests: rawImpSharedInterests,
                  attractiveness: myAttractiveness,
                  sincerity: mySincerity,
                  intelligence: myIntelligence,
                  fun: myFun,
                  ambition: myAmbition);
            }
          }
        }
      }
    });

    //Add the listener to my list of listeners so that it can be removed later if needed.
    listenerRegistrations.add(profileDataDocumentListener);
  }

  ///This listener serves only one purpose: use Firestore's realtime capabilities to fetch profile data from the
  ///database (or cache if available, which is much faster and is the reason why I'm using a realtime listener instead
  ///of a single getDocument() call. Once the listener gets the data, immediately remove it to reduce the number of
  ///realtime connections. This has the advantage of using a realtime listener to access cached data, leading to
  ///significantly faster loading times and reduced reads.
  StreamSubscription? _dataListenerForSomoneElsesProfile;

  ///Never call this on the .shared instance of the class. Get any user's profile data and match survey answers. This
  /// function is useful to download a user's data when navigating to view their profile. onCompletion must take a
  /// ProfileData object as the input.
  void getPersonsProfileData({required String userID, required Function(ProfileData) onCompletion}) {
    _dataListenerForSomoneElsesProfile =
        ProfileDatabasePaths(userID: userID).userDataRef.snapshots().listen((docSnapshot) {
      if (docSnapshot.exists) {
        // get their profile data
        final personProfileData = docSnapshot.get("profileData") as Map<String, dynamic>;
        final personBirthdayRaw = personProfileData["birthday"] as num? ?? 0;
        final personBirthday = personBirthdayRaw.toDouble();
        final personName = personProfileData["name"] as String? ?? "Name N/A";
        final personSchool = personProfileData["school"] as String? ?? "School N/A";
        final personPreferredPronouns =
            personProfileData["preferredPronouns"] as String? ?? UsefulValues.nonbinaryPronouns;
        final personPreferredRelationshipType =
            personProfileData["lookingFor"] as String? ?? UsefulValues.lookingForFriends;
        var personBio = personProfileData["bio"] as String? ?? "";
        final personPodScoreInDatabaseRaw = personProfileData["podScore"] as num; //podScore might be a double in the
        // database if I change the formula later
        final personPodScore = personPodScoreInDatabaseRaw.toInt(); // convert to an integer to make it nicer for
        // display

        // get their FCM device tokens
        final docData = docSnapshot.data() as Map;
        final fcmTokensRaw = docData["fcmTokens"] as List<dynamic>? ?? [];
        final fcmTokens = List<String>.from(fcmTokensRaw);

        if (personBio.isEmpty) personBio = "Bio";

        final personThumbnailURL = personProfileData["photoThumbnailURL"] as String? ?? "photoThumbnailURL";
        final personFullPhotoURL = personProfileData["fullPhotoURL"] as String? ?? "fullPhotoURL";

        var profileData = ProfileData(
            userID: userID,
            name: personName,
            preferredPronoun: personPreferredPronouns,
            preferredRelationshipType: personPreferredRelationshipType,
            birthday: personBirthday,
            school: personSchool,
            bio: personBio,
            podScore: personPodScore,
            thumbnailURL: personThumbnailURL,
            fullPhotoURL: personFullPhotoURL,
            fcmTokens: fcmTokens);

        // get their match survey data and extra images, if available
        final surveyData = docData["matchSurvey"] as Map?;
        if (surveyData != null) {
          final career = surveyData["career"] as int;
          final goOutFreq = surveyData["goOutFreq"] as int;
          final exerciseInterest = surveyData["exerciseInterest"] as int;
          final dineOutInterest = surveyData["dineOutInterest"] as int;
          final artInterest = surveyData["artInterest"] as int;
          final gamingInterest = surveyData["gamingInterest"] as int;
          final clubbingInterest = surveyData["clubbingInterest"] as int;
          final readingInterest = surveyData["readingInterest"] as int;
          final tvShowInterest = surveyData["tvShowInterest"] as int;
          final musicInterest = surveyData["musicInterest"] as int;
          final shoppingInterest = surveyData["shoppingInterest"] as int;
          final impAttractive = surveyData["attractivenessImportance"] as double;
          final rawImpAttractive = surveyData["attractivenessImportance_raw"] as int;
          final impSincere = surveyData["sincerityImportance"] as double;
          final rawImpSincere = surveyData["sincerityImportance_raw"] as int;
          final impIntelligence = surveyData["intelligenceImportance"] as double;
          final rawImpIntelligence = surveyData["intelligenceImportance_raw"] as int;
          final impFun = surveyData["funImportance"] as double;
          final rawImpFun = surveyData["funImportance_raw"] as int;
          final impAmbition = surveyData["ambitionImportance"] as double;
          final rawImpAmbition = surveyData["ambitionImportance_raw"] as int;
          final impSharedInterests = surveyData["sharedInterestsImportance"] as double;
          final rawImpSharedInterests = surveyData["sharedInterestsImportance_raw"] as int;
          final myAttractiveness = surveyData["myAttractiveness"] as int;
          final mySincerity = surveyData["mySincerity"] as int;
          final myIntelligence = surveyData["myIntelligence"] as int;
          final myFun = surveyData["myFun"] as int;
          final myAmbition = surveyData["myAmbition"] as int;

          //Round the values to the nearest hundredth place before feeding into the ML model, since the training data
          // was rounded to the nearest hundredth.
          final roundedImpAttractive = impAttractive.roundToDecimalPlace(2);
          final roundedImpSincere = impSincere.roundToDecimalPlace(2);
          final roundedImpIntelligence = impIntelligence.roundToDecimalPlace(2);
          final roundedImpFun = impFun.roundToDecimalPlace(2);
          final roundedImpAmbition = impAmbition.roundToDecimalPlace(2);
          final roundedImpSharedInterests = impSharedInterests.roundToDecimalPlace(2);

          final personAge = TimeAndDateFunctions.getAgeFromBirthday(birthday: personBirthday);
          final matchSurveyData = MatchSurveyData(
              age: personAge,
              career: career,
              goOutFreq: goOutFreq,
              exerciseInterest: exerciseInterest,
              dineOutInterest: dineOutInterest,
              artInterest: artInterest,
              gamingInterest: gamingInterest,
              clubbingInterest: clubbingInterest,
              readingInterest: readingInterest,
              tvShowsInterest: tvShowInterest,
              musicInterest: musicInterest,
              shoppingInterest: shoppingInterest,
              importanceOfAttraction: roundedImpAttractive,
              rawImportanceOfAttractiveness: rawImpAttractive,
              importanceOfSincerity: roundedImpSincere,
              rawImportanceOfSincerity: rawImpSincere,
              importanceOfIntelligence: roundedImpIntelligence,
              rawImportanceOfIntelligence: rawImpIntelligence,
              importanceOfFun: roundedImpFun,
              rawImportanceOfFun: rawImpFun,
              importanceOfAmbition: roundedImpAmbition,
              rawImportanceOfAmbition: rawImpAmbition,
              importanceOfSharedInterests: roundedImpSharedInterests,
              rawImportanceOfSharedInterests: rawImpSharedInterests,
              attractiveness: myAttractiveness,
              sincerity: mySincerity,
              intelligence: myIntelligence,
              fun: myFun,
              ambition: myAmbition);

          // add the matchSurveyData object to the profileData object
          profileData.matchSurveyData = matchSurveyData;
        }

        // get their extra images
        final extraImagesMap = docData["extraImages"] as Map?;
        if (extraImagesMap != null) {
          List<IdentifiableImage> extraImagesList = [];
          extraImagesMap.forEach((imageID, imageData) {
            final position = imageData["position"] as int;
            final imageURL = imageData["imageURL"] as String;
            final caption = imageData["caption"] as String?;
            final identifiableImage = IdentifiableImage(imageURL: imageURL, position: position, caption: caption);
            extraImagesList.add(identifiableImage);
          });
          profileData.extraImagesList = extraImagesList;
        }

        // Call the completion handler if everything succeeds so I can access the profile data and match survey data
        onCompletion(profileData);
      }

      _dataListenerForSomoneElsesProfile?.cancel(); // cancel the listener once I'm done getting the data
    });
  }
}
