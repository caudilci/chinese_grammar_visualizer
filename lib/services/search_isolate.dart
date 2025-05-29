import 'dart:async';
import 'dart:isolate';

import '../models/dictionary_entry.dart';
import '../utils/pinyin_utils.dart';

/// Message sent to the isolate to perform a search
class SearchMessage {
  final List<DictionaryEntry> entries;
  final String query;
  final SearchMode searchMode;
  final SendPort responsePort;

  SearchMessage({
    required this.entries,
    required this.query,
    required this.searchMode,
    required this.responsePort,
  });
}

/// Message received from the isolate with search results
class SearchResult {
  final List<DictionaryEntry> results;
  final String query;
  final SearchMode searchMode;
  final String error;

  SearchResult({
    required this.results,
    required this.query,
    required this.searchMode,
    this.error = '',
  });
}

/// Enum representing different search modes
enum SearchMode {
  auto,      // Automatically detect search type
  chinese,   // Search Chinese characters
  pinyin,    // Search pinyin
  english,   // Search English definitions
}

/// Main entry point for the search isolate
void searchIsolateEntryPoint(SendPort sendPort) {
  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((dynamic message) {
    if (message is SearchMessage) {
      try {
        final results = _performSearch(
          message.entries,
          message.query,
          message.searchMode,
        );
        
        message.responsePort.send(SearchResult(
          results: results,
          query: message.query,
          searchMode: message.searchMode,
        ));
      } catch (e) {
        message.responsePort.send(SearchResult(
          results: [],
          query: message.query,
          searchMode: message.searchMode,
          error: e.toString(),
        ));
      }
    }
  });
}

/// The main search function that runs in the isolate
List<DictionaryEntry> _performSearch(
  List<DictionaryEntry> entries,
  String query,
  SearchMode searchMode,
) {
  if (query.isEmpty) return [];
  
  final String trimmedQuery = query.trim();
  
  switch (searchMode) {
    case SearchMode.auto:
      return _autoSearch(entries, trimmedQuery);
    case SearchMode.chinese:
      return _chineseSearch(entries, trimmedQuery);
    case SearchMode.pinyin:
      return _pinyinSearch(entries, trimmedQuery);
    case SearchMode.english:
      return _englishSearch(entries, trimmedQuery);
  }
}

/// Search automatically detecting the query type
List<DictionaryEntry> _autoSearch(List<DictionaryEntry> entries, String query) {
  if (_containsChineseCharacters(query)) {
    return _chineseSearch(entries, query);
  } else if (PinyinUtils.isPotentialPinyin(query)) {
    return _pinyinSearch(entries, query);
  } else {
    return _englishSearch(entries, query);
  }
}

/// Search Chinese characters
List<DictionaryEntry> _chineseSearch(List<DictionaryEntry> entries, String query) {
  // Try exact matches first
  var exactMatches = entries.where((entry) =>
      entry.simplified == query ||
      entry.traditional == query
  ).toList();

  if (exactMatches.isNotEmpty) {
    return exactMatches;
  }

  // If no exact matches, look for partial matches
  var results = entries.where((entry) =>
      entry.simplified.contains(query) ||
      entry.traditional.contains(query)
  ).toSet().toList();

  // Sort by length to prioritize shorter matches which are likely more relevant
  results.sort((a, b) {
    // Compare by character length
    final aLength = a.simplified.length;
    final bLength = b.simplified.length;
    return aLength.compareTo(bLength);
  });

  return results.take(100).toList();
}

/// Search pinyin
List<DictionaryEntry> _pinyinSearch(List<DictionaryEntry> entries, String query) {
  final bool hasToneMarks = PinyinUtils.containsToneMarks(query);
  final bool hasToneNumbers = PinyinUtils.containsToneNumbers(query);
  
  List<DictionaryEntry> results = [];
  
  if (hasToneMarks || hasToneNumbers) {
    // Search with tone markers - use exact pinyin matching
    results = entries.where((entry) => 
      entry.pinyin.toLowerCase().contains(query.toLowerCase())
    ).toList();
  } else {
    // For no-tone searches, use the plainPinyin field
    results = entries.where((entry) {
      // Generate plain pinyin by removing tone numbers
      String plainPinyin = PinyinUtils.getPlainPinyin(entry.pinyin);
      return plainPinyin.contains(query.toLowerCase());
    }).toList();
  }
  
  // If no results found and query is short, try first-letter search as a fallback
  if (results.isEmpty && query.length >= 2 && !query.contains(' ')) {
    // Try as initial letters search (e.g., "nh" for "ni hao")
    results = entries.where((entry) {
      final entrySyllables = PinyinUtils.getPlainPinyin(entry.pinyin).split(' ');
      final entryFirstLetters = entrySyllables
          .map((s) => s.isNotEmpty ? s[0] : '')
          .join('');
      return entryFirstLetters.contains(query.toLowerCase());
    }).toList();
  }
  
  // Sort by more precise matches first
  results.sort((a, b) {
    // Exact matches
    final aExactMatch = a.pinyin.toLowerCase() == query.toLowerCase();
    final bExactMatch = b.pinyin.toLowerCase() == query.toLowerCase();
    
    if (aExactMatch && !bExactMatch) return -1;
    if (!aExactMatch && bExactMatch) return 1;
    
    // Then starts with
    final aStartsWith = a.pinyin.toLowerCase().startsWith(query.toLowerCase());
    final bStartsWith = b.pinyin.toLowerCase().startsWith(query.toLowerCase());
    
    if (aStartsWith && !bStartsWith) return -1;
    if (!aStartsWith && bStartsWith) return 1;
    
    return 0;
  });
  
  return results.take(100).toList();
}

/// Search English definitions
List<DictionaryEntry> _englishSearch(List<DictionaryEntry> entries, String query) {
  final String normalizedQuery = query.toLowerCase();
  
  // Split the query into words for more precise matching
  final List<String> queryWords = normalizedQuery.split(RegExp(r'\s+'))
      .where((word) => word.length > 1)  // Filter out single letters
      .toList();
  
  List<DictionaryEntry> results;
  
  // If the query has multiple words, try to match all of them
  if (queryWords.length > 1) {
    results = entries
        .where((entry) {
          // Check if all query words appear in any definition
          final allDefsText = entry.definitions.join(' ').toLowerCase();
          return queryWords.every((word) => allDefsText.contains(word));
        })
        .toList();
  } else {
    // Single word search
    results = entries
        .where((entry) => 
            entry.definitions.any((def) => 
                def.toLowerCase().contains(normalizedQuery)
            )
        )
        .toList();
  }
  
  // Sort by relevance
  _sortDefinitionResultsByRelevance(results, normalizedQuery);
  
  // Check for any exact matches first for cleaner results presentation
  final exactMatches = results.where((entry) => 
    entry.definitions.any((def) => def.toLowerCase() == normalizedQuery)
  ).toList();
  
  if (exactMatches.isNotEmpty) {
    // If we have exact matches, prioritize them at the top
    // but avoid duplicates
    final nonDuplicates = results.where((e) => !exactMatches.contains(e)).toList();
    results = [...exactMatches, ...nonDuplicates];
  }
  
  return results.take(100).toList();
}

/// Helper method to sort definition search results by relevance
void _sortDefinitionResultsByRelevance(List<DictionaryEntry> results, String query) {
  // Add word boundary markers for regex to ensure matching whole words
  final String wordBoundaryQuery = '\\b$query\\b';
  final RegExp exactWordRegExp = RegExp(wordBoundaryQuery, caseSensitive: false);
  
  results.sort((a, b) {
    // Calculate these values once for performance
    final List<String> aLowerDefs = a.definitions.map((def) => def.toLowerCase()).toList();
    final List<String> bLowerDefs = b.definitions.map((def) => def.toLowerCase()).toList();
    final String aDefinitions = aLowerDefs.join(' ');
    final String bDefinitions = bLowerDefs.join(' ');
    
    // 1. Prioritize entries where query is an exact match for the entire definition
    final aExactDefinition = aLowerDefs.any((def) => def == query);
    final bExactDefinition = bLowerDefs.any((def) => def == query);
    
    if (aExactDefinition && !bExactDefinition) return -1;
    if (!aExactDefinition && bExactDefinition) return 1;
    
    // 2. Prioritize entries with exact word matches (using word boundaries)
    // Count the number of exact word matches in each entry
    final aExactWordMatchCount = _countRegexMatches(aDefinitions, exactWordRegExp);
    final bExactWordMatchCount = _countRegexMatches(bDefinitions, exactWordRegExp);
    
    if (aExactWordMatchCount > bExactWordMatchCount) return -1;
    if (aExactWordMatchCount < bExactWordMatchCount) return 1;
    
    // 3. Prioritize entries where query appears at the beginning of a definition
    final aStartsWithMatch = aLowerDefs.any((def) => def.startsWith(query));
    final bStartsWithMatch = bLowerDefs.any((def) => def.startsWith(query));
    
    if (aStartsWithMatch && !bStartsWithMatch) return -1;
    if (!aStartsWithMatch && bStartsWithMatch) return 1;
    
    // 4. Count occurrences of the query term in all definitions
    final aOccurrences = _countOccurrences(aDefinitions, query);
    final bOccurrences = _countOccurrences(bDefinitions, query);
    
    if (aOccurrences > bOccurrences) return -1;
    if (aOccurrences < bOccurrences) return 1;
    
    // 5. Shorter definitions are likely more relevant
    final aLength = aDefinitions.length;
    final bLength = bDefinitions.length;
    
    return aLength.compareTo(bLength);
  });
}

/// Helper method to count occurrences of a substring in a string
int _countOccurrences(String text, String pattern) {
  if (text.isEmpty || pattern.isEmpty) return 0;
  
  int count = 0;
  int index = 0;
  
  while ((index = text.indexOf(pattern, index)) != -1) {
    count++;
    index += pattern.length;
  }
  
  return count;
}

/// Helper method to count regex matches in a string
int _countRegexMatches(String text, RegExp regex) {
  if (text.isEmpty) return 0;
  
  final matches = regex.allMatches(text);
  return matches.length;
}

/// Helper method to check if string contains Chinese characters
bool _containsChineseCharacters(String text) {
  // Regex for Chinese characters (CJK Unified Ideographs)
  final RegExp chineseRegExp = RegExp(r'[\u4e00-\u9fff]');
  return chineseRegExp.hasMatch(text);
}