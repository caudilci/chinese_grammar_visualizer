import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ColorService {
  // Singleton pattern
  static final ColorService _instance = ColorService._internal();
  factory ColorService() => _instance;
  ColorService._internal();
  
  // Cached colors map
  Map<String, Color>? _colorsMap;
  
  // Load colors from Dart constants
  Future<Map<String, Color>> loadColors() async {
    if (_colorsMap != null) {
      return _colorsMap!;
    }
    
    // Generate map from our color constants
    _colorsMap = PartOfSpeechColors.asMap();
    return _colorsMap!;
  }
  
  // Get color for a part of speech or grammar function
  Future<Color> getColor(String term) async {
    // Use the static method from PartOfSpeechColors directly
    return PartOfSpeechColors.getColor(term);
  }
  
  // Alias for backward compatibility
  Future<Color> getPartOfSpeechColor(String partOfSpeech) async {
    return PartOfSpeechColors.getColor(partOfSpeech);
  }
  
  // Alias for backward compatibility
  Future<Color> getGrammarFunctionColor(String grammarFunction) async {
    return PartOfSpeechColors.getColor(grammarFunction);
  }
  
  // Get all colors as a map
  Future<Map<String, Color>> getAllColors() async {
    return loadColors();
  }
  
  // Aliases for backward compatibility
  Future<Map<String, Color>> getAllPartOfSpeechColors() async {
    return loadColors();
  }
  
  Future<Map<String, Color>> getAllGrammarFunctionColors() async {
    return loadColors();
  }
  
  Future<Map<String, Color>> getAllStructureElementColors() async {
    return loadColors();
  }
}