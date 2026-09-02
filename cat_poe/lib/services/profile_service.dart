import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _profileImageKeyPrefix = 'profile_image_';
  static const String _skipProfileSetupKeyPrefix = 'skip_profile_setup_';

  /// Save the local path of the profile image for a specific user
  static Future<void> saveProfileImagePath(String userId, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_profileImageKeyPrefix$userId', path);
  }

  /// Get the local path of the profile image for a specific user
  static Future<String?> getProfileImagePath(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_profileImageKeyPrefix$userId');
  }

  /// Remove the profile image path (e.g., on logout or image deletion)
  static Future<void> removeProfileImage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_profileImageKeyPrefix$userId');
  }

  /// Mark profile setup as skipped/completed for this user so we don't show it again
  static Future<void> setProfileSetupCompleted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_skipProfileSetupKeyPrefix$userId', true);
  }

  /// Check if profile setup has been completed or skipped
  static Future<bool> isProfileSetupCompleted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_skipProfileSetupKeyPrefix$userId') ?? false;
  }
}


