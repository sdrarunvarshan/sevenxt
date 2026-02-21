
import 'package:hive_flutter/hive_flutter.dart';

class UserHelper {
  static const String _boxName = 'user_settings';
  static const String _userTypeKey = 'user_type';
  static const String b2c = 'b2c';
  static const String b2b = 'b2b';

  static bool _isInitialized = false;

  // Initialize Hive (call this once in your app initialization)
  static Future<void> init() async {
    if (!_isInitialized) {
      await Hive.initFlutter();
      await Hive.openBox(_boxName);
      _isInitialized = true;
    }
  }

  // Get the user settings box
  static Box _getBox() {
    if (!_isInitialized) {
      throw StateError(
          'UserHelper must be initialized first. Call UserHelper.init()');
    }
    return Hive.box(_boxName);
  }

  // Get current user type (defaults to 'b2c')
  static Future<String> getUserType() async {
    await init(); // Ensure initialization
    final box = _getBox();
    return box.get(_userTypeKey, defaultValue: b2c) as String;
  }

  // Synchronous version for immediate access (use when you need value synchronously)
  static String getUserTypeSync() {
    final box = _getBox();
    return box.get(_userTypeKey, defaultValue: b2c) as String;
  }

  // Set user type
  static Future<void> setUserType(String userType) async {
    if (userType != b2c && userType != b2b) {
      throw ArgumentError('User type must be either "$b2c" or "$b2b"');
    }

    await init(); // Ensure initialization
    final box = _getBox();
    await box.put(_userTypeKey, userType);
  }

  // Check if user is B2B
  static Future<bool> isB2B() async {
    final userType = await getUserType();
    return userType == b2b;
  }

  // Synchronous version
  static bool isB2BSync() {
    final userType = getUserTypeSync();
    return userType == b2b;
  }

  // Check if user is B2C
  static Future<bool> isB2C() async {
    final userType = await getUserType();
    return userType == b2c;
  }

  // Synchronous version
  static bool isB2CSync() {
    final userType = getUserTypeSync();
    return userType == b2c;
  }

  // Toggle between B2C and B2B
  static Future<void> toggleUserType() async {
    final currentType = await getUserType();
    final newType = currentType == b2c ? b2b : b2c;
    await setUserType(newType);
  }

  // Clear user type (on logout)
  static Future<void> clearUserType() async {
    await init(); // Ensure initialization
    final box = _getBox();
    await box.delete(_userTypeKey);
  }

  // Close the Hive box (call when app closes)
  static Future<void> close() async {
    if (_isInitialized) {
      await Hive.box(_boxName).close();
      _isInitialized = false;
    }
  }

}