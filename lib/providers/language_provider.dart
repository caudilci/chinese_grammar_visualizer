import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _useTraditionalKey = 'use_traditional_characters';
  
  bool _useTraditionalCharacters = false;
  bool _isInitialized = false;

  // Getters
  bool get useTraditionalCharacters => _useTraditionalCharacters;
  bool get isInitialized => _isInitialized;

  // Initialize and load preferences
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _useTraditionalCharacters = prefs.getBool(_useTraditionalKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing language preferences: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Toggle between traditional and simplified characters
  Future<void> toggleCharacterType() async {
    _useTraditionalCharacters = !_useTraditionalCharacters;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useTraditionalKey, _useTraditionalCharacters);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  // Set specific character type (true for traditional, false for simplified)
  Future<void> setCharacterType(bool useTraditional) async {
    if (_useTraditionalCharacters == useTraditional) return;
    
    _useTraditionalCharacters = useTraditional;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useTraditionalKey, _useTraditionalCharacters);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }
}