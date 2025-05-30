import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/catppuccin_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';
  static const String _flavorKey = 'theme_flavor';
  
  bool _isDarkMode = false;
  bool _isInitialized = false;
  String _currentFlavor = CatppuccinTheme.latte;
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  String get currentFlavor => _currentFlavor;
  List<String> get availableFlavors => CatppuccinTheme.flavors;
  
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _currentFlavor = prefs.getString(_flavorKey) ?? 
        (_isDarkMode ? CatppuccinTheme.mocha : CatppuccinTheme.latte);
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    
    // Set theme flavor based on dark/light mode
    _currentFlavor = _isDarkMode ? CatppuccinTheme.mocha : CatppuccinTheme.latte;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    await prefs.setString(_flavorKey, _currentFlavor);
    
    notifyListeners();
  }
  
  // This method is kept for backward compatibility,
  // but now only supports Latte (light) and Mocha (dark)
  Future<void> setThemeFlavor(String flavor) async {
    if (!CatppuccinTheme.flavors.contains(flavor)) return;
    
    _currentFlavor = flavor;
    // Update dark mode based on flavor - now it's a simple light/dark toggle
    _isDarkMode = flavor == CatppuccinTheme.mocha;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_flavorKey, _currentFlavor);
    await prefs.setBool(_darkModeKey, _isDarkMode);
    
    notifyListeners();
  }
  
  ThemeData get lightTheme => CatppuccinTheme.getLightTheme();
  ThemeData get darkTheme => CatppuccinTheme.getDarkTheme();
  
  // Get theme by current flavor
  ThemeData get currentTheme => CatppuccinTheme.getThemeByFlavor(_currentFlavor);
}