import 'package:shared_preferences/shared_preferences.dart';

class HelperFunction {
  static String sharedPreferenceUserMessageLength = "USERMESSAGELENGTHKEY";

  static Future<bool> saveMessageStatusSharedPreference(
      String messageLength) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
//print('My name is save khan: $userName');
    return await prefs.setString(
        sharedPreferenceUserMessageLength, messageLength);
  }

  static Future getMessageStatusSharedPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
//print('My name is get khan: ${prefs.getString(sharedPreferenceUserNameKey)}');
    return prefs.getString(sharedPreferenceUserMessageLength);
  }

  static Future isSharedPreferenceContainKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
//print('My name is get khan: ${prefs.getString(sharedPreferenceUserNameKey)}');
    return prefs.containsKey(sharedPreferenceUserMessageLength);
  }

  static Future clearSharedPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
}
