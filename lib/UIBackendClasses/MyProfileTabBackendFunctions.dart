import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:podsquad/BackendDataclasses/MatchSurveyData.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/BackendDataclasses/BasicProfileInfoDict.dart';
import 'package:podsquad/BackendDataclasses/IdentifiableImage.dart';
import 'package:podsquad/BackendDataclasses/PodMemberInfoDict.dart';
import 'package:podsquad/CommonlyUsedClasses/TimeAndDateFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/DatabasePaths/ProfileDatabasePaths.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

class MyProfileTabBackendFunctions {
  static final shared = MyProfileTabBackendFunctions();

  ///Stores my profile data. ONLY ACCESS THIS ON THE .shared INSTANCE! (Otherwise it'll be empty). Listen using a ValueListenerBuilder widget.
  ValueNotifier<ProfileData> myProfileData = ValueNotifier(ProfileData(
      userID: (myFirebaseUserId),
      name: "name",
      preferredPronoun: "preferredPronoun",
      preferredRelationshipType: "preferredRelationshipType",
      birthday: 0,
      school: "school",
      bio: "bio",
      podScore: 0,
      thumbnailURL: "thumbnailURL",
      fullPhotoURL: "fullPhotoURL"));

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
    this._myExtraImagesList = myExtraImagesList; // assign the value to the new value (unsorted)
    myExtraImagesList.sort((image1, image2) => image1.position < image2.position); // now sort the images by position
    mySortedExtraImagesList =
        ValueNotifier(myExtraImagesList); // assign the sorted list to be equal to the sorted list of images
  }

  ///Stores my (max 5) additional profile images, sorted by position
  ValueNotifier<List<IdentifiableImage>> mySortedExtraImagesList = ValueNotifier([]);

  ///A map containing the entire contents of my profile data document (profile data, extra images, and match survey data)
  Map<String, dynamic>? myProfileDocument;

  ///Access this property for the required data to join a pod
  PodMemberInfoDict get myDataToIncludeWhenJoiningAPod =>
      PodMemberInfoDict(
          userID: myProfileData.value.userID,
          bio: myProfileData.value.bio,
          birthday: myProfileData.value.birthday,
          joinedAt: DateTime
              .now()
              .millisecondsSinceEpoch * 0.001,
          name: myProfileData.value.name,
          thumbnailURL: myProfileData.value.thumbnailURL);

  ///Access this property for the required data to like, friend, block, or meet somone
  BasicProfileInfoDict get myDataToIncludeWhenLikingFriendingBlockingOrMeetingSomeone =>
      BasicProfileInfoDict(
          userID: myProfileData.value.userID,
          name: myProfileData.value.name,
          birthday: myProfileData.value.birthday,
          bio: myProfileData.value.bio,
          thumbnailURL: myProfileData.value.thumbnailURL);

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
        fullPhotoURL: "fullPhotoURL"));
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
  void getMyProfileData() {
    _myExtraImagesList = []; // reset this list when the function is called to ensure I don't get duplicate items
    final profileDataDocumentListener =
    ProfileDatabasePaths(userID: myFirebaseUserId).userDataRef.snapshots().listen((docSnapshot) {
      if (docSnapshot.exists) {
        myProfileDocument = docSnapshot.data() as Map<String, dynamic>?;

        final value = docSnapshot.get("profileData") as Map<String, dynamic>;
        double myBirthday = value["birthday"] as double;
        String myName = value["name"] as String;
        String mySchool = value["school"] as String;
        String myPreferredPronouns = value["preferredPronouns"] as String;
        String myPreferredRelationshipType = value["lookingFor"] as String;
        String myBio = value["bio"] as String;
        double myPodScoreFromDatabase =
        value["podScore"] as double; // podscore might be stored as a double in the database if I change the formula
        int myPodScore = myPodScoreFromDatabase.toInt(); // truncate to an integer to make it nicer for display

        if (myBio.isEmpty) myBio = "Bio";

        String myThumbnailURL = value["photoThumbnailURL"] as String;
        String myFullPhotoURL = value["fullPhotoURL"] as String;

        //Update the value of myProfileData now that all the data is available
        myProfileData.value = ProfileData(
            userID: myFirebaseUserId,
            name: myName,
            preferredPronoun: myPreferredPronouns,
            preferredRelationshipType: myPreferredRelationshipType,
            birthday: myBirthday,
            school: mySchool,
            bio: myBio,
            podScore: myPodScore,
            thumbnailURL: myThumbnailURL,
            fullPhotoURL: myFullPhotoURL);

        //Now add in my extra images
        ///Maps like this: {imageID: {caption: "someCaption", imageURL: "someURLString", position: 0}}
        final myImagesDict = docSnapshot.get("extraImages") as Map<String, Map<String, dynamic>>;
        myImagesDict.forEach((imageID, imageData) {
          final imageURLString = imageData["imageURL"] as String;
          final position = imageData["position"] as int;
          final identifiableImage = IdentifiableImage(imageURL: imageURLString, position: position);

          //Now let's add each image to my extra images list.
          var imagesList = mySortedExtraImagesList.value; // first, read in all the images I currently have
          imagesList.add(identifiableImage); // now add the most recent image to the list
          _myExtraImagesList =
              imagesList; // changing this set-only variable will automatically sort all images by position and update mySortedExtraImagesList accordingly.
        });

        //remove any images that no longer exist in the database
        final imageIDsInDatabase = myImagesDict.keys;
        mySortedExtraImagesList.value.forEach((imageOnDevice) {
          final imageIDonDevice = imageOnDevice.id.toString();
          if (!imageIDsInDatabase.contains(imageIDonDevice)) {
            var imageList = mySortedExtraImagesList.value; // read in the current images list
            imageList.removeWhere((element) => element.id == imageOnDevice.id); // remove the image from the
            // device if it doesn't exist in the database as well
            _myExtraImagesList = imageList; // update the set-only variable, which will then update
            // mySortedExtraImagesList.value with the new value
          }
        });

        final surveyData = docSnapshot.get("matchSurvey") as Map<String, dynamic>;
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
    });

    //Add the listener to my list of listeners so that it can be removed later if needed.
    listenerRegistrations.add(profileDataDocumentListener);
  }

  ///Store the profile data for any user. Only access this inside the getProfileData completion handler, never
  ///anywhere else. NEVER ACCESS THIS ON THE .shared INSTANCE (it will be empty)!
  var profileData = ProfileData(
      userID: "userID",
      name: "name",
      preferredPronoun: "preferredPronoun",
      preferredRelationshipType: "preferredRelationshipType",
      birthday: 0,
      school: "school",
      bio: "bio",
      podScore: 0,
      thumbnailURL: "thumbnailURL",
      fullPhotoURL: "fullPhotoURL");

  ///This listener serves only one purpose: use Firestore's realtime capabilities to fetch profile data from the
  ///database (or cache if available, which is much faster and is the reason why I'm using a realtime listener instead
  ///of a single getDocument() call. Once the listener gets the data, immediately remove it to reduce the number of
  ///realtime connections. This has the advantage of using a realtime listener to access cached data, leading to
  ///significantly faster loading times and reduced reads.
  StreamSubscription? _dataListenerForSomoneElsesProfile;

  ///Never call this on the .shared instance of the class. Get any user's profile data and match survey answers. This
  /// function is useful to download a user's data when navigating to view their profile. Access the profileData
  /// property of the myProfileTabBackendFunctions object inside the function completion handler.
  void getPersonsProfileData({required String userID, required Function onCompletion}) {
    _dataListenerForSomoneElsesProfile =
        ProfileDatabasePaths(userID: userID).userDataRef.snapshots().listen((docSnapshot) {
          if (docSnapshot.exists) {

            // get their profile data
            final personProfileData = docSnapshot.get("profileData") as Map<String, dynamic>;
            final personBirthday = personProfileData["birthday"] as double;
            final personName = personProfileData["name"] as String;
            final personSchool = personProfileData["school"] as String;
            final personPreferredPronouns = personProfileData["preferredPronouns"] as String;
            final personPreferredRelationshipType = personProfileData["lookingFor"] as String;
            var personBio = personProfileData["bio"] as String;
            final personPodScoreInDatabase = personProfileData["podScore"] as double; //podScore might be a double in the
            // database if I change the formula later
            final personPodScore = personPodScoreInDatabase
                .toInt(); // convert to an integer to make it nicer for display

            if (personBio.isEmpty) personBio = "Bio";

            final personThumbnailURL = personProfileData["photoThumbnailURL"] as String;
            final personFullPhotoURL = personProfileData["fullPhotoURL"] as String;

            this.profileData = ProfileData(userID: userID,
                name: personName,
                preferredPronoun: personPreferredPronouns,
                preferredRelationshipType: personPreferredRelationshipType,
                birthday: personBirthday,
                school: personSchool,
                bio: personBio,
                podScore: personPodScore,
                thumbnailURL: personThumbnailURL,
                fullPhotoURL: personFullPhotoURL);

            // get their match survey data
            final surveyData = docSnapshot.get("matchSurvey") as Map<String, dynamic>;
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
            this.profileData.matchSurveyData = MatchSurveyData(
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

            // Call the completion handler if everything succeeds so I can access the profile data and match survey data
            onCompletion();
          }

          _dataListenerForSomoneElsesProfile?.cancel(); // cancel the listener once I'm done getting the data
        });
  }

}
