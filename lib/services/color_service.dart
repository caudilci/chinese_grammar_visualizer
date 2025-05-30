import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ColorService {
  // Singleton pattern
  static final ColorService _instance = ColorService._internal();
  factory ColorService() => _instance;
  ColorService._internal();
  
  // Cached colors map - will be updated with new context
  Map<String, Color>? _colorsMap;
  BuildContext? _lastContext;
  
  // Load colors from Dart constants, using context if available
  Future<Map<String, Color>> loadColors([BuildContext? context]) async {
    // If we have a new context or no map yet, regenerate
    if (context != null && (context != _lastContext || _colorsMap == null)) {
      _colorsMap = PartOfSpeechColors.asMap(context);
      _lastContext = context;
      return _colorsMap!;
    }
    
    // If we have a cached map, return it
    if (_colorsMap != null) {
      return _colorsMap!;
    }
    
    // Generate map from our color constants without context (fallback)
    _colorsMap = PartOfSpeechColors.asMap();
    return _colorsMap!;
  }
  
  // Get color for a part of speech or grammar function
  Future<Color> getColor(String term, [BuildContext? context]) async {
    // Use the static method from PartOfSpeechColors directly
    return PartOfSpeechColors.getColor(term, context);
  }
  
  // Alias for backward compatibility
  Future<Color> getPartOfSpeechColor(String partOfSpeech, [BuildContext? context]) async {
    return PartOfSpeechColors.getColor(partOfSpeech, context);
  }
  
  // Alias for backward compatibility
  Future<Color> getGrammarFunctionColor(String grammarFunction, [BuildContext? context]) async {
    return PartOfSpeechColors.getColor(grammarFunction, context);
  }
  
  // Get all colors as a map
  Future<Map<String, Color>> getAllColors([BuildContext? context]) async {
    return loadColors(context);
  }
  
  // Aliases for backward compatibility
  Future<Map<String, Color>> getAllPartOfSpeechColors([BuildContext? context]) async {
    return loadColors(context);
  }
  
  Future<Map<String, Color>> getAllGrammarFunctionColors([BuildContext? context]) async {
    return loadColors(context);
  }
  
  Future<Map<String, Color>> getAllStructureElementColors([BuildContext? context]) async {
    return loadColors(context);
  }
}