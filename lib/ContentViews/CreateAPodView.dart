import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';
import 'package:podsquad/BackendFunctions/ResizeAndUploadImage.dart';
import 'package:podsquad/CommonlyUsedClasses/AlertDialogs.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/ViewPodDetails.dart';
import 'package:podsquad/DatabasePaths/PodsDatabasePaths.dart';
import 'package:podsquad/OtherSpecialViews/DecoratedImage.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';
import 'dart:io';
import 'package:focus_detector/focus_detector.dart';
import 'package:uuid/uuid.dart';

// TODO: Delete the pod profile image if I leave the screen without creating a pod
/// Create a new pod (set isCreatingNewPod to true) or edit an existing pod (set isCreatingNewPod to false and pass
/// in the podID). If creating a new pod, leave podID equal to null. If editing a pod, I must pass in the podID.
class CreateAPodView extends StatefulWidget {
  const CreateAPodView({Key? key, required this.isCreatingNewPod, this.podID}) : super(key: key);
  final bool isCreatingNewPod;

  /// Only required if isCreatingNewPod is false.
  final String? podID;

  @override
  _CreateAPodViewState createState() => _CreateAPodViewState(isCreatingNewPod: isCreatingNewPod, podID: podID);
}

class _CreateAPodViewState extends State<CreateAPodView> {
  _CreateAPodViewState({required this.isCreatingNewPod, this.podID});

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool isCreatingNewPod;
  String? podID;

  /// Contains the pod's data. Initialize with a placeholder object. Ignore this object if isCreatingNewPod is true.
  PodData _podData = PodData(
      name: "",
      dateCreated: -1,
      description: "",
      anyoneCanJoin: false,
      podID: "",
      podCreatorID: "",
      thumbnailURL: "",
      thumbnailPath: "",
      fullPhotoURL: "",
      fullPhotoPath: "",
      podScore: -1);

  /// Used to pick an image
  final _imagePicker = ImagePicker();

  /// The image that gets picked from the photo library
  File? _imageFile;

  /// Link to the anyoneCanJoin switch
  bool _anyoneCanJoin = false;

  /// Pick an image from the gallery
  void _pickImage({required ImageSource source}) async {
    final pickedImage = await _imagePicker.pickImage(source: source);
    if (pickedImage == null) return;
    await _cropImage(sourcePath: pickedImage.path);

    // Upload to the database
    if (this._imageFile != null && this.podID != null) {
      final task = ResizeAndUploadImage.sharedInstance.uploadPodImage(image: this._imageFile!, podID: this.podID!);
      final result = await task;
      final thumbnailURL = result?[0];
      final thumbnailPath = result?[1];
      final fullPhotoURL = result?[2];
      final fullPhotoPath = result?[3];
      if (thumbnailURL != null && fullPhotoURL != null && thumbnailPath != null && fullPhotoPath != null)
        setState(() {
          _podData.thumbnailURL = thumbnailURL;
          _podData.thumbnailPath = thumbnailPath;
          _podData.fullPhotoURL = fullPhotoURL;
          _podData.fullPhotoPath = fullPhotoPath;
        });
    }
  }

  /// Allow the user to select a square crop from their image
  Future _cropImage({required String sourcePath}) async {
    File? croppedImage = await ImageCropper.cropImage(
        sourcePath: sourcePath,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: "Crop Image", initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
        iosUiSettings: IOSUiSettings(minimumAspectRatio: 1.0, title: "Crop Image"));
    setState(() {
      this._imageFile = croppedImage;
    });
  }

  /// Set the pod data in the database
  Future<void> _setPodData() async {
    final podName = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final timeSinceEpochInSeconds = DateTime.now().millisecondsSinceEpoch * 0.001;

    // make warning alerts if any field is blank
    if (podName.isEmpty)
      showSingleButtonAlert(
          context: context,
          title: "Name Required",
          content: "You must name your"
              " pod something, otherwise people won't be able to find it!",
          dismissButtonLabel: "OK");
    else if (description.isEmpty)
      showSingleButtonAlert(
          context: context,
          title: "Description Required",
          content: "Please "
              "provide a brief description of your pod, such as a summary of ideal members' hobbies and interests.",
          dismissButtonLabel: "OK");
    else if (_podData.thumbnailURL.isEmpty || _podData.thumbnailPath.isEmpty)
      showSingleButtonAlert(
          context: context,
          title: "Image Required",
          content: "Your pod must include an image. Tap the camera or gallery icon to select one!",
          dismissButtonLabel: "OK");
    else if (_podData.fullPhotoURL.isEmpty || _podData.fullPhotoPath.isEmpty)
      showSingleButtonAlert(
          context: context,
          title: "Image Uploading",
          content: "Please wait a moment for your image to upload, then try again.",
          dismissButtonLabel: "OK");

    if (podName.isEmpty ||
        description.isEmpty ||
        _podData.thumbnailURL.isEmpty ||
        _podData.fullPhotoURL.isEmpty ||
        _podData.thumbnailPath.isEmpty ||
        _podData.fullPhotoPath.isEmpty) return;

    // update _podData to fill in the missing data
    // create the dictionary to upload to Firestore
    setState(() {
      // The other fields have already been set
      this._podData.name = podName;
      if (isCreatingNewPod) this._podData.dateCreated = timeSinceEpochInSeconds;
      this._podData.description = description;
      this._podData.anyoneCanJoin = _anyoneCanJoin;
      if (isCreatingNewPod) this._podData.podScore = 0;
    });

    // Set this in Firestore
    final podDictionary = {
      "name": _podData.name,
      "dateCreated": _podData.dateCreated,
      "description": _podData.description,
      "anyoneCanJoin": _podData.anyoneCanJoin,
      "podID": _podData.podID,
      "podCreatorID": _podData.podCreatorID,
      "thumbnailURL": _podData.thumbnailURL,
      "thumbnailPath": _podData.thumbnailPath,
      "fullPhotoURL": _podData.fullPhotoURL,
      "fullPhotoPath": _podData.fullPhotoPath,
      "podScore": _podData.podScore
    };

    final task = PodsDatabasePaths(podID: _podData.podID)
        .podDocument
        .set({"profileData": podDictionary}, SetOptions(merge: true));
    await task;
    showSingleButtonAlert(
        context: context, title: isCreatingNewPod ? "Pod Created!" : "Pod Updated!", dismissButtonLabel: "OK");

    // Be sure to join the pod I just created
    if (isCreatingNewPod)
      PodsDatabasePaths(podID: _podData.podID, userID: myFirebaseUserId)
          .joinPod(personData: MyProfileTabBackendFunctions.shared.myDataToIncludeWhenJoiningAPod);

    // Regardless of whether joining the pod succeeds (it should though), the pod has been created. Thus, I should
    // set isCreatingNewPod to false (if necessary)
    if (isCreatingNewPod)
      setState(() {
        this.isCreatingNewPod = false;
      });

    return;
  }

  /// Get the pod data when the view appears (if editing, not creating a pod)
  void _getPodData({required String podID}) {
    PodsDatabasePaths(podID: podID).getPodData(onCompletion: (podData) {
      setState(() {
        this._podData = podData;
        this._nameController.text = podData.name;
        this._descriptionController.text = podData.description;
        this._anyoneCanJoin = podData.anyoneCanJoin;
      });
    });
  }

  /// If the user exits (either pressed the Back button or closes the app) without hitting "Create Pod", then delete
  /// the pod from the database and remove its photos from Storage.
  Future<void> _cleanUpDataIfPodCreationCancelled() async {
    if (!isCreatingNewPod) return; // don't execute the function if I'm editing an existing pod
    final deleteDoc = PodsDatabasePaths(podID: _podData.podID).podDocument.delete(); // delete the pod document in
    // Firestore
    final deleteThumbnail = PodsDatabasePaths(podID: _podData.podID, imageName: "thumbnail").podImageRef.delete(); //
    // delete thumbnail (Storage)
    final deleteFullImage = PodsDatabasePaths(podID: _podData.podID, imageName: "full_image").podImageRef.delete(); //
    // delete full image

    await deleteDoc;
    await deleteThumbnail;
    await deleteFullImage;

    // we also must clear the name, description, anyoneCanJoin, and podData fields so there isn't a disconnect
    // between what the user sees and what's in the database
    setState(() {
      _imageFile = null;

      // Reset the thumbnail and full photo data, since those get deleted from the database if I close out of the
      // screen before creating the pod
      final dateCreated = DateTime.now().millisecondsSinceEpoch * 0.001;
      this._podData = PodData(
          name: "",
          dateCreated: dateCreated,
          description: _descriptionController.text,
          anyoneCanJoin: false,
          podID: podID ?? Uuid().v1(),
          podCreatorID: myFirebaseUserId,
          thumbnailURL: "",
          thumbnailPath: "",
          fullPhotoURL: "",
          fullPhotoPath: "",
          podScore: 0);
      isCreatingNewPod = true;
    });
  }

  @override
  void initState() {
    super.initState();

    // generate a pod ID if I'm creating a new pod
    if (isCreatingNewPod) this.podID = firestoreDatabase.collection("pods").doc().id;
    this._podData.podID = this.podID!;
    this._podData.podCreatorID = myFirebaseUserId;
    if (!isCreatingNewPod) this._getPodData(podID: podID!);
  }

  @override
  void dispose() {
    super.dispose();
    _cleanUpDataIfPodCreationCancelled();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: FocusDetector(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(isCreatingNewPod ? "Create Pod" : "Edit Pod"),
                stretch: true,
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  SafeArea(
                      child: Column(
                    children: [
                      // profile image
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: CupertinoButton(
                          child: _podData.thumbnailURL.isNotEmpty
                              ? DecoratedImage(
                                  imageURL: _podData.thumbnailURL,
                                  width: 125.scaledForScreenSize(context: context),
                                  height: 125.scaledForScreenSize(context: context),
                                )
                              : Icon(CupertinoIcons.photo_on_rectangle),
                          onPressed: () {
                            // navigate to ViewPodDetails as long as the pod exists (i.e. not creating a new pod)
                            if (!isCreatingNewPod && podID != null)
                              Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
                                  builder: (context) => ViewPodDetails(podID: podID!, showChatButton: true)));
                            else
                              _pickImage(source: ImageSource.gallery); // otherwise, let the user pick an image
                          },
                        ),
                      ),

                      // Pick photo section
                      CupertinoFormSection(children: [
                        // Take photo button
                        CupertinoButton(
                          onPressed: () {
                            this._pickImage(source: ImageSource.camera);
                          },
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.camera),
                              Padding(padding: EdgeInsets.only(left: 10), child: Text("Take photo"))
                            ],
                          ),
                        ),

                        // Choose photo button
                        CupertinoButton(
                          onPressed: () {
                            this._pickImage(source: ImageSource.gallery);
                          },
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.photo),
                              Padding(padding: EdgeInsets.only(left: 10), child: Text("Choose from gallery"))
                            ],
                          ),
                        ),
                      ]),

                      // Pod info section
                      CupertinoFormSection(header: Text("Pod Info"), children: [
                        // Anyone can join switch
                        CupertinoFormRow(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(_anyoneCanJoin ? "Anyone can join (open)" : "Invite only (closed)"),
                            Spacer(),
                            CupertinoSwitch(
                              value: _anyoneCanJoin,
                              onChanged: (anyoneCanJoin) {
                                setState(() {
                                  this._anyoneCanJoin = anyoneCanJoin;
                                });
                              },
                              activeColor: accentColor,
                            )
                          ],
                        )),

                        // Pod name
                        CupertinoTextFormFieldRow(
                          textCapitalization: TextCapitalization.words,
                          controller: _nameController,
                          placeholder: "Choose a pod name",
                        ),

                        // Pod description
                        CupertinoTextFormFieldRow(
                            textCapitalization: TextCapitalization.sentences,
                            controller: _descriptionController,
                            placeholder: "Describe this"
                                " pod", maxLines: null,),

                        // create or update pod button
                        CupertinoButton(
                            child: Text(isCreatingNewPod ? "Create Pod" : "Update Pod"), onPressed: _setPodData)
                      ])
                    ],
                  ))
                ]),
              )
            ],
          ),

          // Contains the image upload progress spinner
          Center(
            child: ValueListenableBuilder(
                valueListenable: ResizeAndUploadImage.sharedInstance.isUploadInProgress,
                builder: (context, bool inProgress, widget) {
                  if (inProgress) {
                    return Stack(
                      children: [
                        BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                            child: Container(color: CupertinoColors.black.withOpacity(0.1))),
                        Center(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(radius: 15),
                            Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  "Uploading Image...",
                                  style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                                ))
                          ],
                        ))
                      ],
                    );
                  } else
                    return Container(); // return an empty widget if there's no image loading
                }),
          )
        ],
      ), onForegroundLost: _cleanUpDataIfPodCreationCancelled,
    ));
  }
}
