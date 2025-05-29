import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/dictionary_entry.dart';
import '../utils/pinyin_utils.dart';

class DictionaryService {
  static final DictionaryService _instance = DictionaryService._internal();
  factory DictionaryService() => _instance;
  DictionaryService._internal();

  List<DictionaryEntry> _entries = [];
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
      return _entries
          .where((entry) {
            // Check if all query words appear in any definition
            final allDefsText = entry.definitions.join(' ').toLowerCase();
            return queryWords.every((word) => allDefsText.contains(word));
          })
          .toList();
    } else {
      // Single word search - standard behavior
      return _entries
          .where((entry) => 
              entry.definitions.any((def) => 
                  def.toLowerCase().contains(normalizedQuery)
              )
          )
          .toList();
    }
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
  }

  // Search all fields
  List<DictionaryEntry> search(String query) {
    if (query.isEmpty) return [];
    
    final bool isChineseQuery = _containsChineseCharacters(query);
    
    if (isChineseQuery) {
      // For Chinese characters, search both simplified and traditional
      var results = <DictionaryEntry>{};  // Use a Set to avoid duplicates
      results.addAll(searchBySimplified(query));
      results.addAll(searchByTraditional(query));
      return results.toList();
    } else {
      // Attempt to detect if this is a pinyin query
      final bool isPinyinQuery = PinyinUtils.isPotentialPinyin(query);
      
      if (isPinyinQuery) {
        // Limit the number of results to prevent performance issues
        var results = searchByPinyin(query);
        print('Found ${results.length} results for pinyin query: $query');
        
        // If no results found and query is short, try first-letter search as a fallback
        if (results.isEmpty && query.length >= 2 && !query.contains(' ')) {
          // Try as initial letters search (e.g., "nh" for "ni hao")
          // No direct results, try initial letters search as fallback
          
          results = _entries.where((entry) {
            final entrySyllables = PinyinUtils.getPlainPinyin(entry.pinyin).split(' ');
            final entryFirstLetters = entrySyllables
                .map((s) => s.isNotEmpty ? s[0] : '')
                .join('');
            return entryFirstLetters.contains(query.toLowerCase());
          }).toList();
        }
        
        if (results.length > 100) {
          print('Limiting results to 100 entries');
          return results.sublist(0, 100);
        }
        return results;
      } else {
        // For English queries
        var results = searchByDefinition(query);
        print('Found ${results.length} results for definition query: $query');
        
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