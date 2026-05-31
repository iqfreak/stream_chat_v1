import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isAuthenticated = false;
  String _locale = 'en';

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isAuthenticated => _isAuthenticated;
  String get locale => _locale;

  /// Loads persisted theme and locale. Call once at startup before runApp
  /// finishes building, or in the splash screen.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('sc_theme_mode');
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    }
    _locale = prefs.getString('sc_locale') ?? 'en';
    notifyListeners();
  }

  Future<void> _persistTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'sc_theme_mode',
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _persistTheme();
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    _persistTheme();
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
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('sc_locale', locale),
    );
  }
}
