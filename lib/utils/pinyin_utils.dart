/// Utility functions for working with pinyin
class PinyinUtils {
  /// Removes tone marks from pinyin string
  /// Example: "nǐ hǎo" becomes "ni hao"
  static String removeToneMarks(String pinyin) {
    // Map of tone marked vowels to their base vowels
    final Map<String, String> toneMarks = {
      // First tone (macron)
      'ā': 'a', 'ē': 'e', 'ī': 'i', 'ō': 'o', 'ū': 'u', 'ǖ': 'ü',
      // Second tone (acute accent)
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ǘ': 'ü',
      // Third tone (caron/háček)
      'ǎ': 'a', 'ě': 'e', 'ǐ': 'i', 'ǒ': 'o', 'ǔ': 'u', 'ǚ': 'ü',
      // Fourth tone (grave accent)
      'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u', 'ǜ': 'ü',
      // Neutral tone (for completeness, though no diacritic)
      'a': 'a', 'e': 'e', 'i': 'i', 'o': 'o', 'u': 'u', 'ü': 'ü',
      // Capital letters (for completeness)
      'Ā': 'A', 'Ē': 'E', 'Ī': 'I', 'Ō': 'O', 'Ū': 'U', 'Ǖ': 'Ü',
      'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ǘ': 'Ü',
      'Ǎ': 'A', 'Ě': 'E', 'Ǐ': 'I', 'Ǒ': 'O', 'Ǔ': 'U', 'Ǚ': 'Ü',
      'À': 'A', 'È': 'E', 'Ì': 'I', 'Ò': 'O', 'Ù': 'U', 'Ǜ': 'Ü',
    };

    String result = pinyin;
    toneMarks.forEach((toneMarkedVowel, baseVowel) {
      result = result.replaceAll(toneMarkedVowel, baseVowel);
    });
    
    return result;
  }

  /// Checks if a string contains pinyin with tone marks
  static bool containsToneMarks(String text) {
    // Regex that matches any character with tone marks used in pinyin
    final RegExp toneMarkRegex = RegExp(
      r'[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜĀÁǍÀĒÉĚÈĪÍǏÌŌÓǑÒŪÚǓÙǕǗǙǛ]'
    );
    return toneMarkRegex.hasMatch(text);
  }

  /// Returns true if the normalized version of searchTerm (without tone marks)
  /// is found within the normalized version of text (without tone marks)
  static bool matchesWithoutTones(String text, String searchTerm) {
    final String normalizedText = removeToneMarks(text).toLowerCase();
    final String normalizedSearchTerm = removeToneMarks(searchTerm).toLowerCase();
    
    return normalizedText.contains(normalizedSearchTerm);
  }
}