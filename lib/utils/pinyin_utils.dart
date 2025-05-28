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

  /// Removes tone numbers from numerical pinyin
  /// Example: "ni3 hao3" becomes "ni hao"
  static String removeToneNumbers(String pinyin) {
    // Regular expression to remove tone numbers (digits 1-5 after letters)
    return pinyin.replaceAll(RegExp(r'([a-zA-Z:üÜ]+)([1-5])'), r'$1');
  }
  
  /// Converts pinyin with tone numbers to plain pinyin (without tones)
  /// Uses a direct character replacement approach for maximum reliability
  static String pinyinToPlain(String pinyin) {
    if (pinyin.isEmpty) return '';
    
    // Split the input by spaces to handle syllables
    List<String> syllables = pinyin.split(' ');
    List<String> result = [];
    
    for (String syllable in syllables) {
      // Handle each syllable
      String processed = syllable;
      
      // Remove tone number at the end of syllable if present
      if (processed.isNotEmpty && RegExp(r'[1-5]$').hasMatch(processed)) {
        processed = processed.substring(0, processed.length - 1);
      } else {
        // Remove tone numbers after vowels
        for (String vowel in ['a', 'e', 'i', 'o', 'u', 'ü', 'v']) {
          for (int tone = 1; tone <= 5; tone++) {
            if (processed.contains('$vowel$tone')) {
              processed = processed.replaceAll('$vowel$tone', vowel);
            }
          }
        }
      }
      
      // Convert v to ü if needed
      processed = processed.replaceAll('v', 'ü');
      
      result.add(processed.toLowerCase());
    }
    
    String finalResult = result.join(' ');
    return finalResult;
  }
  
  /// Normalize pinyin for comparison regardless of format
  /// Converts to lowercase, removes tones, standardizes 'v' to 'ü', and handles spaces
  static String normalizePinyin(String pinyin) {
    String normalized = pinyin.toLowerCase();
    
    // Replace 'v' with 'ü' (common keyboard input)
    normalized = normalized.replaceAll('v', 'ü');
    
    // Remove tone marks and numbers
    if (containsToneMarks(normalized)) {
      normalized = removeToneMarks(normalized);
    } else if (containsToneNumbers(normalized)) {
      normalized = removeToneNumbers(normalized);
    }
    
    // Standardize spaces (trim and collapse multiple spaces)
    normalized = normalized.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Handle other common substitutions (u: for ü, etc)
    normalized = normalized.replaceAll('u:', 'ü');
    
    return normalized;
  }

  /// Checks if a string contains pinyin with tone marks
  static bool containsToneMarks(String text) {
    // Regex that matches any character with tone marks used in pinyin
    final RegExp toneMarkRegex = RegExp(
      r'[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜĀÁǍÀĒÉĚÈĪÍǏÌŌÓǑÒŪÚǓÙǕǗǙǛ]',
    );
    return toneMarkRegex.hasMatch(text);
  }

  /// Checks if a string contains numerical pinyin notation (with tone numbers)
  static bool containsToneNumbers(String text) {
    // Regex that matches pinyin with tone numbers (1-5)
    final RegExp toneNumberRegex = RegExp(r'[a-zA-Z:üÜ]+[1-5]');
    return toneNumberRegex.hasMatch(text);
  }

  /// Returns true if the normalized version of searchTerm (without tone marks)
  /// is found within the normalized version of text (without tone marks)
  static bool matchesWithoutTones(String text, String searchTerm) {
    final String normalizedText = removeToneMarks(text).toLowerCase();
    final String normalizedSearchTerm = removeToneMarks(
      searchTerm,
    ).toLowerCase();

    return normalizedText.contains(normalizedSearchTerm);
  }

  /// Converts pinyin with tone marks to numerical pinyin
  /// Example: "nǐ hǎo" becomes "ni3 hao3"
  static String toNumericalPinyin(String pinyin) {
    if (!containsToneMarks(pinyin)) {
      // Add tone 5 to each syllable without tone marks
      final words = pinyin.split(' ');
      return words.map((w) => w.isEmpty ? '' : '${w}5').join(' ');
    }

    // Define the vowels with tone marks and their numeric equivalents
    final Map<String, String> toneMarks = {
      // First tone (macron)
      'ā': 'a1', 'ē': 'e1', 'ī': 'i1', 'ō': 'o1', 'ū': 'u1', 'ǖ': 'ü1',
      // Second tone (acute accent)
      'á': 'a2', 'é': 'e2', 'í': 'i2', 'ó': 'o2', 'ú': 'u2', 'ǘ': 'ü2',
      // Third tone (caron/háček)
      'ǎ': 'a3', 'ě': 'e3', 'ǐ': 'i3', 'ǒ': 'o3', 'ǔ': 'u3', 'ǚ': 'ü3',
      // Fourth tone (grave accent)
      'à': 'a4', 'è': 'e4', 'ì': 'i4', 'ò': 'o4', 'ù': 'u4', 'ǜ': 'ü4',
      // Upper case (for completeness)
      'Ā': 'A1', 'Ē': 'E1', 'Ī': 'I1', 'Ō': 'O1', 'Ū': 'U1', 'Ǖ': 'Ü1',
      'Á': 'A2', 'É': 'E2', 'Í': 'I2', 'Ó': 'O2', 'Ú': 'U2', 'Ǘ': 'Ü2',
      'Ǎ': 'A3', 'Ě': 'E3', 'Ǐ': 'I3', 'Ǒ': 'O3', 'Ǔ': 'U3', 'Ǚ': 'Ü3',
      'À': 'A4', 'È': 'E4', 'Ì': 'I4', 'Ò': 'O4', 'Ù': 'U4', 'Ǜ': 'Ü4',
    };

    // Split by spaces to process each syllable separately
    final List<String> syllables = pinyin.split(' ');
    final List<String> result = [];

    for (String syllable in syllables) {
      String processed = syllable;
      int? toneNumber;

      // Find the tone mark and replace it with its base vowel
      for (var entry in toneMarks.entries) {
        if (syllable.contains(entry.key)) {
          // Get the tone number from the mapping value (second character)
          toneNumber = int.parse(entry.value[1]);
          // Replace the tone-marked vowel with its base vowel
          processed = processed.replaceAll(entry.key, entry.value[0]);
          break;
        }
      }

      // Add the tone number at the end if found, otherwise use tone 5 (neutral)
      if (processed.isNotEmpty) {
        processed += toneNumber?.toString() ?? '5';
      }

      result.add(processed);
    }

    return result.join(' ');
  }

  /// Converts numerical pinyin to pinyin with tone marks
  /// Example: "ni3 hao3" becomes "nǐ hǎo"
  static String toDiacriticPinyin(String pinyin) {
    if (!containsToneNumbers(pinyin)) {
      return pinyin; // Return as is if no tone numbers found
    }

    // Mapping for tone number to diacritic application
    final Map<String, Map<String, String>> toneToVowelMap = {
      '1': {
        'a': 'ā',
        'e': 'ē',
        'i': 'ī',
        'o': 'ō',
        'u': 'ū',
        'ü': 'ǖ',
        'v': 'ǖ',
      },
      '2': {
        'a': 'á',
        'e': 'é',
        'i': 'í',
        'o': 'ó',
        'u': 'ú',
        'ü': 'ǘ',
        'v': 'ǘ',
      },
      '3': {
        'a': 'ǎ',
        'e': 'ě',
        'i': 'ǐ',
        'o': 'ǒ',
        'u': 'ǔ',
        'ü': 'ǚ',
        'v': 'ǚ',
      },
      '4': {
        'a': 'à',
        'e': 'è',
        'i': 'ì',
        'o': 'ò',
        'u': 'ù',
        'ü': 'ǜ',
        'v': 'ǜ',
      },
    };

    // Regular expression to match syllables with tone numbers
    final RegExp syllableRegex = RegExp(r'([a-zA-Z:üÜv]+)([1-5])');

    // Special rule for compound words like "Zhong1guo2"
    // First find all individual syllables with their tone numbers
    final List<RegExpMatch> matches = syllableRegex.allMatches(pinyin).toList();
    String result = pinyin;

    // Process from right to left to avoid index problems
    for (int i = matches.length - 1; i >= 0; i--) {
      final match = matches[i];
      final String syllable = match.group(1) ?? '';
      final String toneNumber = match.group(2) ?? '5';

      // Tone 5 (neutral) has no diacritic
      if (toneNumber == '5') {
        result = result.replaceRange(match.start, match.end, syllable);
        continue;
      }

      // Replace 'v' with 'ü' first (common for typing on keyboards)
      String processedSyllable = syllable.replaceAll('v', 'ü');

      // Order of precedence for applying tone mark: a, o, e, i, u, ü
      final vowelOrder = ['a', 'o', 'e', 'i', 'u', 'ü'];
      bool replaced = false;

      for (final vowel in vowelOrder) {
        if (processedSyllable.contains(vowel)) {
          final replacementVowel = toneToVowelMap[toneNumber]?[vowel];
          if (replacementVowel != null) {
            processedSyllable = processedSyllable.replaceFirst(
              vowel,
              replacementVowel,
            );
            replaced = true;
            break;
          }
        }
      }

      if (!replaced) {
        // If no vowel was found to apply tone mark (shouldn't happen in proper pinyin)
        processedSyllable = syllable;
      }

      result = result.replaceRange(match.start, match.end, processedSyllable);
    }

    return result;
  }

  /// Checks if a string is potentially a pinyin string
  /// This is a heuristic check, not a comprehensive validator
  static bool isPotentialPinyin(String text) {
    // Check if it already has tone marks or numbers
    if (containsToneMarks(text) || containsToneNumbers(text)) {
      return true;
    }
    
    // Simple heuristic: pinyin only consists of letters, numbers, spaces, and 'ü'
    final RegExp pinyinRegex = RegExp(r'^[a-zA-Z0-9üÜ:,\s]+$');
    if (!pinyinRegex.hasMatch(text)) {
      return false;
    }
    
    // For very short inputs (1-2 characters), we'll be more lenient
    if (text.length <= 2) {
      // Only accept if it's a valid pinyin initial or final
      final RegExp validInitialOrFinal = RegExp(
        r'^[bpmfdtnlgkhjqxzcsryw]$|^[aeiouü]$|^(ai|ei|ui|ao|ou|iu|ie|ue|er|an|en|in|un|ang|eng|ing|ong)$',
        caseSensitive: false
      );
      return validInitialOrFinal.hasMatch(text);
    }
    
    // Additional check: look for common pinyin syllables
    final RegExp commonSyllables = RegExp(
      r'\b(zi|ci|si|zhi|chi|shi|ri|yi|wu|yu|ye|yue|yuan|yin|yun|ying)\b|'
      r'\b(bo|po|mo|fo|de|te|ne|le|ge|ke|he|re|me|ne)\b|'
      r'\b(ba|pa|ma|fa|da|ta|na|la|ga|ka|ha|sha|zha|cha|za|ca|sa)\b|'
      r'\b(ai|ei|ui|ao|ou|iu|ie|ue|er|an|en|in|un|ang|eng|ing|ong)\b|'
      r'\b(a|e|i|o|u|ü)\b|'
      r'\b(zhong|guo|ren|shang|xia|dong|xi|nan|bei|tian|di|ri|yue|nian)\b',
      caseSensitive: false
    );
    
    return commonSyllables.hasMatch(text);
  }
  
  /// Checks if a string contains Chinese characters
  static bool containsChineseCharacters(String text) {
    // Regex for Chinese characters (CJK Unified Ideographs)
    final RegExp chineseRegExp = RegExp(r'[\u4e00-\u9fff]');
    return chineseRegExp.hasMatch(text);
  }
  
  /// Get the plain pinyin representation (without tone numbers)
  /// of a string that may have tone numbers or tone marks
  static String getPlainPinyin(String text) {
    // If empty, return empty
    if (text.isEmpty) return '';
    
    String result = text;
    
    // Handle diacritic tone marks if present
    bool hasToneMarks = containsToneMarks(result);
    
    if (hasToneMarks) {
      result = removeToneMarks(result);
    }
    
    // Always process for tone numbers to be safe
    // This will handle cases where tone number detection might not be reliable
    result = pinyinToPlain(result);
    
    return result.toLowerCase();
  }
  
  /// Gets the first letter of each syllable in a pinyin string
  /// Example: "ni hao" becomes "nh"
  static String getFirstLettersFromPinyin(String pinyin) {
    // Normalize and split into syllables
    final normalized = normalizePinyin(pinyin);
    final syllables = normalized.split(' ');
    
    // Extract first letter of each syllable
    return syllables
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .join('');
  }
  
  /// Compares two pinyin strings for matching without tones
  /// More sophisticated than simple contains() - handles partial syllable matching
  static bool pinyinMatches(String entryPinyin, String queryPinyin) {
    // Normalize both strings
    final normalizedEntry = normalizePinyin(entryPinyin);
    final normalizedQuery = normalizePinyin(queryPinyin);
    
    // Direct match check
    if (normalizedEntry.contains(normalizedQuery)) {
      return true;
    }
    
    // Split into syllables
    final entrySyllables = normalizedEntry.split(' ');
    final querySyllables = normalizedQuery.split(' ');
    
    // Check if all query syllables appear in order somewhere in entry syllables
    if (querySyllables.length > 1) {
      for (int i = 0; i <= entrySyllables.length - querySyllables.length; i++) {
        bool allMatch = true;
        for (int j = 0; j < querySyllables.length; j++) {
          if (!entrySyllables[i + j].startsWith(querySyllables[j])) {
            allMatch = false;
            break;
          }
        }
        if (allMatch) return true;
      }
    }
    
    // Check for partial syllable matches (user types beginning of syllables)
    if (querySyllables.length == entrySyllables.length) {
      bool allStartWith = true;
      for (int i = 0; i < querySyllables.length; i++) {
        if (!entrySyllables[i].startsWith(querySyllables[i])) {
          allStartWith = false;
          break;
        }
      }
      if (allStartWith) return true;
    }
    
    // First letter matching (for acronym-style searches like "nh" for "ni hao")
    final entryFirstLetters = getFirstLettersFromPinyin(entryPinyin);
    final queryFirstLetters = getFirstLettersFromPinyin(queryPinyin);
    
    if (queryFirstLetters.length >= 2 && entryFirstLetters.startsWith(queryFirstLetters)) {
      return true;
    }
    
    return false;
  }
}
