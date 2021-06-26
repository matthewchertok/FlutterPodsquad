import 'package:flutter/cupertino.dart';
import 'package:flutter_nearby_messages_api/flutter_nearby_messages_api.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'dart:io';

///Discovers users nearby
class NearbyScanner {
  static final shared = NearbyScanner();

  // initialize the API
  FlutterNearbyMessagesApi nearbyMessagesApi = FlutterNearbyMessagesApi();

  ///Begin searching for nearby users over Bluetooth
  Future<void> publishAndSubscribe() async {
    // config for iOS
    await nearbyMessagesApi.setAPIKey("AIzaSyAFdNMfNpASvuVViGHB7lL4dMtgwLKWip4");

    // Request permissions if on iOS
    if (Platform.isIOS) {
      nearbyMessagesApi.setPermissionAlert('Allow Bluetooth Permission?',
          'Podsquad requires Bluetooth permission to discover nearby users.', 'Deny', 'Grant');
    }

    // Publish my ID for other users to discover
    await nearbyMessagesApi.publish(myFirebaseUserId);

    // allow subscribing in the background
    await nearbyMessagesApi.backgroundSubscribe();

    // Enable debug mode
    await nearbyMessagesApi.enableDebugMode();

    // This callback gets the message when an a nearby device sends one
    nearbyMessagesApi.onFound = (message) {
      print('Discovered user with ID : $message');
    };

    // Listen status when publish and subscribe
    // enum GNSOperationStatus { inactive, starting, active }
    nearbyMessagesApi.statusHandler = (status) {
      print('~~~statusHandler : $status');
      // notify the UI of status changes
      if (status == GNSOperationStatus.active)
        ScanningStatus.shared.inProgress.value = true;
      else
        ScanningStatus.shared.inProgress.value = false;
    };
  }

  ///Stop searching for nearby users over Bluetooth
  void stopPublishAndSubscribe() async {
    await nearbyMessagesApi.unPublish();
    await nearbyMessagesApi.backgroundUnsubscribe();
  }
}

/// Track whether Bluetooth scanning is in progress so the UI can update accordingly
class ScanningStatus {
  static final shared = ScanningStatus();

  /// Animate the Podsquad logo when scanning is in progress. Access this as a property of the shared instance only.
  ValueNotifier<bool> inProgress = ValueNotifier(false);
}
