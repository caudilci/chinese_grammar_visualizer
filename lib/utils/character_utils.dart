import 'package:flutter/widgets.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

/// Utility class for handling Chinese character display based on user preferences
class CharacterUtils {
  /// Gets the appropriate Chinese text based on user preferences
  /// If traditional is preferred and traditional text is available, returns traditional
  /// Otherwise falls back to simplified
  static String getChineseText(BuildContext context, String simplified, String? traditional) {
    if (traditional == null) return simplified;
    
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return languageProvider.useTraditionalCharacters ? traditional : simplified;
  }
  
  /// Extension method to get appropriate text for a given Chinese string
  static String getAppropriateText(BuildContext context, String simplified, String? traditional) {
    return getChineseText(context, simplified, traditional);
  }
  
  /// Returns true if the app is set to display traditional characters
  static bool useTraditionalCharacters(BuildContext context) {
    return Provider.of<LanguageProvider>(context, listen: false).useTraditionalCharacters;
  }
}

/// Extension method on String to easily get the appropriate character variant
extension ChineseTextExtension on String {
  String toAppropriateCharacters(BuildContext context, String? traditional) {
    return CharacterUtils.getChineseText(context, this, traditional);
  }
}