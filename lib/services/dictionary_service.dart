import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/dictionary_entry.dart';
import '../utils/pinyin_utils.dart';

class DictionaryService {
  static final DictionaryService _instance = DictionaryService._internal();
  factory DictionaryService() => _instance;
  DictionaryService._internal();

  final List<DictionaryEntry> _entries = [];
  bool _isLoaded = false;
  final Completer<void> _loadingCompleter = Completer<void>();

  // Getter for all entries
  List<DictionaryEntry> get entries => _entries;

  // Getter for loading status
  bool get isLoaded => _isLoaded;

  // Getter for loading completion future
  Future<void> get ready => _loadingCompleter.future;

  // Load the dictionary data from the JSON asset file
  Future<void> loadDictionary() async {
    if (_isLoaded) return;

    try {
      print('Starting to load dictionary from assets...');
      final String jsonData = await rootBundle.loadString('assets/data/cedict.json');
      print('Dictionary file loaded, size: ${jsonData.length} bytes');

      // Parse the JSON data
      final List<dynamic> entriesJson = json.decode(jsonData);
      print('Dictionary contains ${entriesJson.length} entries');

      // Process entries in batches to avoid UI freeze
      const int batchSize = 1000;
      int processedCount = 0;
      int validEntryCount = 0;

      for (int i = 0; i < entriesJson.length; i += batchSize) {
        final end = (i + batchSize < entriesJson.length) ? i + batchSize : entriesJson.length;
        final batch = entriesJson.sublist(i, end);

        for (var entryJson in batch) {
          try {
            final entry = DictionaryEntry.fromJson(entryJson);
            if (entry.isValid) {
              _entries.add(entry);
              validEntryCount++;
            }
          } catch (e) {
            print('Error parsing entry: $e');
          }
        }

        processedCount += batch.length;
        print('Processed ${processedCount}/${entriesJson.length} entries, valid: $validEntryCount');

        // Allow UI to update between batches
        await Future.delayed(Duration.zero);
      }

      _isLoaded = true;
      if (!_loadingCompleter.isCompleted) {
        _loadingCompleter.complete();
      }

      if (_entries.isEmpty) {
        print('WARNING: No valid entries were loaded from the dictionary file!');
        print('Attempting to load a sample entry for testing...');

        // Add a sample entry so the app can still function
        _entries.add(
          DictionaryEntry(
            traditional: '你好',
            simplified: '你好',
            pinyin: 'ni3 hao3',
            definitions: ['hello', 'hi', 'how are you?'],
          )
        );
      }

      print('Dictionary successfully loaded with ${_entries.length} valid entries');
    } catch (e) {
      print('Error loading dictionary: $e');
      if (!_loadingCompleter.isCompleted) {
        _loadingCompleter.completeError(e);
      }
      rethrow;
    }
  }

  // Search for entries by simplified Chinese
  List<DictionaryEntry> searchBySimplified(String query) {
    if (query.isEmpty) return [];
    return _entries
        .where((entry) => entry.simplified.contains(query))
        .toList();
  }

  // Search for entries by traditional Chinese
  List<DictionaryEntry> searchByTraditional(String query) {
    if (query.isEmpty) return [];
    return _entries
        .where((entry) => entry.traditional.contains(query))
        .toList();
  }

  // Search for entries by pinyin (with or without tone marks)
  List<DictionaryEntry> searchByPinyin(String query) {
    if (query.isEmpty) return [];

    final String queryLower = query.toLowerCase();
    final bool hasToneMarks = PinyinUtils.containsToneMarks(query);
    final bool hasToneNumbers = PinyinUtils.containsToneNumbers(query);

    print('Searching pinyin: "$query", hasToneMarks: $hasToneMarks, hasToneNumbers: $hasToneNumbers');

    var results = <DictionaryEntry>[];

    if (hasToneMarks || hasToneNumbers) {
      // Search with tone markers - use exact pinyin matching
      results = _entries.where((entry) =>
        entry.pinyin.toLowerCase().contains(queryLower)
      ).toList();
      // Search with tone markers completed
    } else {
      // For no-tone searches, regenerate plainPinyin on the fly to ensure correctness
      // Search without tone markers - use the plainPinyin field
      results = _entries.where((entry) {
        // Generate plain pinyin by removing tone numbers
        String plainPinyin = PinyinUtils.getPlainPinyin(entry.pinyin);
        return plainPinyin.contains(queryLower);
      }).toList();
      // Search without tone markers completed
    }

    // Sort results by relevance
    results.sort((a, b) {
      final String aCompare = hasToneMarks || hasToneNumbers ?
                            a.pinyin.toLowerCase() :
                            generatePlainPinyin(a.pinyin);
      final String bCompare = hasToneMarks || hasToneNumbers ?
                            b.pinyin.toLowerCase() :
                            generatePlainPinyin(b.pinyin);

      // Exact matches first
      bool aExactMatch = aCompare == queryLower;
      bool bExactMatch = bCompare == queryLower;

      if (aExactMatch && !bExactMatch) return -1;
      if (!aExactMatch && bExactMatch) return 1;

      // Then matches at the beginning of the pinyin
      bool aStartsWith = aCompare.startsWith(queryLower);
      bool bStartsWith = bCompare.startsWith(queryLower);

      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;

      // Default to keeping the existing order
      return 0;
    });

    return results;
  }

  // Helper method to generate plain pinyin (without tone numbers) from pinyin with tones
  // Uses the PinyinUtils functionality for consistency
  String generatePlainPinyin(String pinyin) {
    return PinyinUtils.getPlainPinyin(pinyin);
  }

  // Search for entries by English definition
  List<DictionaryEntry> searchByDefinition(String query) {
    if (query.isEmpty) return [];

    final String normalizedQuery = query.toLowerCase();

    // Split the query into words for more precise matching
    final List<String> queryWords = normalizedQuery.split(RegExp(r'\s+'))
        .where((word) => word.length > 1)  // Filter out single letters
        .toList();

    // If the query has multiple words, try to match all of them
    if (queryWords.length > 1) {
      final results = _entries
          .where((entry) {
            // Check if all query words appear in any definition
            final allDefsText = entry.definitions.join(' ').toLowerCase();
            return queryWords.every((word) => allDefsText.contains(word));
          })
          .toList();

      // Sort by relevance: exact phrase matches first, then partial matches
      _sortDefinitionResultsByRelevance(results, normalizedQuery);
      return results;
    } else {
      // Single word search
      final results = _entries
          .where((entry) =>
              entry.definitions.any((def) =>
                  def.toLowerCase().contains(normalizedQuery)
              )
          )
          .toList();

      // Sort by relevance: exact word matches first, then partial matches
      _sortDefinitionResultsByRelevance(results, normalizedQuery);
      return results;
    }
  }

  // Helper method to sort definition search results by relevance
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

  // Helper method to count occurrences of a substring in a string
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

  // Helper method to count regex matches in a string
  int _countRegexMatches(String text, RegExp regex) {
    if (text.isEmpty) return 0;

    final matches = regex.allMatches(text);
    return matches.length;
  }

  // Get entries for a specific Chinese character
  List<DictionaryEntry> getEntriesForCharacter(String character) {
    if (character.isEmpty) return [];

    return _entries
        .where((entry) =>
            entry.simplified == character ||
            entry.traditional == character
        )
        .toList();
  }

  // Debug method to check entry fields
  // Debug utility for development purposes
  void debugCheckEntryFields() {
    if (_entries.isEmpty) {
      return;
    }

    // Count entries with empty plainPinyin
    int emptyPlainPinyinCount = 0;
    for (var entry in _entries) {
      if (entry.plainPinyin.isEmpty && entry.pinyin.isNotEmpty) {
        emptyPlainPinyinCount++;
      }
    }
    print('Entries with empty plainPinyin: $emptyPlainPinyinCount');
  }

  // Search all fields
  List<DictionaryEntry> search(String query) {
    if (query.isEmpty) return [];

    final bool isChineseQuery = _containsChineseCharacters(query);
    final String trimmedQuery = query.trim();

    if (isChineseQuery) {
      // For Chinese characters, search both simplified and traditional
      var results = <DictionaryEntry>{};  // Use a Set to avoid duplicates

      // First try exact matches
      var exactMatches = _entries.where((entry) =>
          entry.simplified == trimmedQuery ||
          entry.traditional == trimmedQuery
      ).toList();

      if (exactMatches.isNotEmpty) {
        return exactMatches;
      }

      // If no exact matches, look for partial matches
      results.addAll(searchBySimplified(trimmedQuery));
      results.addAll(searchByTraditional(trimmedQuery));

      // Sort by length to prioritize shorter matches which are likely more relevant
      final resultsList = results.toList();
      resultsList.sort((a, b) {
        // Compare by character length
        final aLength = a.simplified.length;
        final bLength = b.simplified.length;
        return aLength.compareTo(bLength);
      });

      return resultsList;
    } else {
      // Attempt to detect if this is a pinyin query
      final bool isPinyinQuery = PinyinUtils.isPotentialPinyin(trimmedQuery);

      if (isPinyinQuery) {
        // Limit the number of results to prevent performance issues
        var results = searchByPinyin(trimmedQuery);
        print('Found ${results.length} results for pinyin query: $trimmedQuery');

        // If no results found and query is short, try first-letter search as a fallback
        if (results.isEmpty && trimmedQuery.length >= 2 && !trimmedQuery.contains(' ')) {
          // Try as initial letters search (e.g., "nh" for "ni hao")

          results = _entries.where((entry) {
            final entrySyllables = PinyinUtils.getPlainPinyin(entry.pinyin).split(' ');
            final entryFirstLetters = entrySyllables
                .map((s) => s.isNotEmpty ? s[0] : '')
                .join('');
            return entryFirstLetters.contains(trimmedQuery.toLowerCase());
          }).toList();
        }

        // Sort by more precise matches first
        results.sort((a, b) {
          // Exact matches
          final aExactMatch = a.pinyin.toLowerCase() == trimmedQuery.toLowerCase();
          final bExactMatch = b.pinyin.toLowerCase() == trimmedQuery.toLowerCase();

          if (aExactMatch && !bExactMatch) return -1;
          if (!aExactMatch && bExactMatch) return 1;

          return 0;
        });

        if (results.length > 100) {
          print('Limiting results to 100 entries');
          return results.sublist(0, 100);
        }
        return results;
      } else {
        // For English queries
        var results = searchByDefinition(trimmedQuery);
        print('Found ${results.length} results for definition query: $trimmedQuery');

        // Check for any exact matches first
        final exactMatches = results.where((entry) =>
          entry.definitions.any((def) => def.toLowerCase() == trimmedQuery.toLowerCase())
        ).toList();

        if (exactMatches.isNotEmpty) {
          print('Found ${exactMatches.length} exact matches');
          // If we have exact matches, prioritize them at the top
          results = [...exactMatches, ...results.where((e) => !exactMatches.contains(e))];
        }

        if (results.length > 100) {
          print('Limiting results to 100 entries');
          return results.sublist(0, 100);
        }
        return results;
      }
    }
  }

  // Helper method to check if string contains Chinese characters
  bool _containsChineseCharacters(String text) {
    // Regex for Chinese characters (CJK Unified Ideographs)
    final RegExp chineseRegExp = RegExp(r'[\u4e00-\u9fff]');
    return chineseRegExp.hasMatch(text);
  }

  // Debug method to print a sample of dictionary entries
  void debugPrintSampleEntries() {
    final sampleSize = _entries.length > 10 ? 10 : _entries.length;
    print('Sample of dictionary entries:');
    for (var i = 0; i < sampleSize; i++) {
      print('Entry $i: ${_entries[i]}');
    }
  }
}
