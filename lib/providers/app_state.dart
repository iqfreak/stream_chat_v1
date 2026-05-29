import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isAuthenticated = false;
  String _locale = 'en';

  // 🛠️ الجديد: متغيرات لحفظ حالة أزرار الإشعارات
  bool _pushNotificationsEnabled = true;
  bool _mentionsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isAuthenticated => _isAuthenticated;
  String get locale => _locale;

  // 🛠️ الجديد: Getters لقراءة حالة الأزرار
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get mentionsEnabled => _mentionsEnabled;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void signIn() {
    _isAuthenticated = true;
    notifyListeners();
  }

  void signOut() {
    _isAuthenticated = false;
    notifyListeners();
  }

  void setLocale(String locale) {
    _locale = locale;
    notifyListeners();
  }

  // 🛠️ الجديد: ميثود تحديث إشعارات التطبيق
  void setPushNotifications(bool value) {
    _pushNotificationsEnabled = value;
    notifyListeners();
  }

  // 🛠️ الجديد: ميثود تحديث إشعارات الإشارات (Mentions)
  void setMentions(bool value) {
    _mentionsEnabled = value;
    notifyListeners();
  }
}
