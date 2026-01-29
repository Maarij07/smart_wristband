import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _rememberMeKey = 'remember_me';
  static const String _isLoggedInKey = 'is_logged_in';

  static Future<void> saveRememberMe(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, value);
    } catch (e) {
      // Log the error or handle it appropriately
      // Error saving remember me: \$e
    }
  }

  static Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      // Error getting remember me: \$e
      return false; // Default to false if there's an error
    }
  }

  static Future<void> saveLoginStatus(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, isLoggedIn);
    } catch (e) {
      // Error saving login status: \$e
    }
  }

  static Future<bool> getLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      // Error getting login status: \$e
      return false; // Default to false if there's an error
    }
  }

  static Future<bool> shouldAutoLogin() async {
    try {
      final rememberMe = await getRememberMe();
      final isLoggedIn = await getLoginStatus();
      return rememberMe && isLoggedIn;
    } catch (e) {
      // Error checking auto login: \$e
      return false; // Default to false if there's an error
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
    } catch (e) {
      // Error logging out: \$e
    }
  }
}