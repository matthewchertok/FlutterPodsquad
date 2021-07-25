import 'package:shared_preferences/shared_preferences.dart';

///Used for saving data to UserDefaults (iOS) or SharedPreferences (Android). Call SettingsStoredOnDevice.shared
///.saveValueForKey() to save a setting, and call SettingsStoredOnDevice.shared.readValueForKey() to read a setting.
class SettingsStoredOnDevice {
  static final shared = SettingsStoredOnDevice();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  ///Save an integer, boolean, double, string, or list of strings to UserDefaults (iOS) or SharedPreferences (Android).
  Future<void> saveValueForKey({required String key, required dynamic value}) async {
    final SharedPreferences prefs = await _prefs;

    // now set the value depending on the type that was passed in for value
    if(value is int) prefs.setInt(key, value);
    else if(value is bool) prefs.setBool(key, value);
    else if(value is double) prefs.setDouble(key, value);
    else if(value is String) prefs.setString(key, value);
    else if(value is List<String>) prefs.setStringList(key, value);
  }

  ///Read a value from UserDefaults (iOS) or SharedPreferences (Android)
  Future<dynamic> readValueForKey({required String key}) async {
    final SharedPreferences prefs = await _prefs;
    final value = prefs.get(key);
    return value;
  }

  ///The key to determine if I already read the Welcome tutorial
  static const didReadWelcomeTutorial = "Did I Read The Welcome Tutorial?";

  ///The key to determine if I already read the View Person Details tutorial
  static const didReadViewPersonDetailsTutorial = "Did I Read The View Person Details Tutorial?";

  ///The key to determine if I already read the View Pod Details tutorial
  static const didReadViewPodDetailsTutorial = "Did I Read The View Pod Details Tutorial?";

  ///The key to determine if I already read the Pod Mode tutorial
  static const didReadPodModeTutorial = "Did I Read The Pod Mode Tutorial?";

  ///The key to determine if I already read the messaging tutorial
  static const didReadMessagingTutorial = "Did I Read The Messaging Tutorial?";

  ///The key to determine if I already read the pod messaging tutorial
  static const didReadPodMessagingTutorial = "Did I Read The Pod Messaging Tutorial?";

  ///The key to determine if I already read the login tutorial
  static const didReadLoginTutorial = "Did I Read The Login Tutorial?";

  ///The key to determine if I already read the end user license agreement
  static const didReadEULA = "Did I Read The End User License Agreement?";

  ///The key to determine if I already read the scanner tutorial
  static const didReadScannerTutorial = "Did I Read The Scanner Tutorial?";

}