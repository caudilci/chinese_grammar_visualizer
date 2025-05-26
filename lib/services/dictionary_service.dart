import 'dart:async';
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

  // Load the dictionary data from the asset file
  Future<void> loadDictionary() async {
    if (_isLoaded) return;

    try {
      print('Starting to load dictionary from assets...');
      final String data = await rootBundle.loadString('assets/data/cedict_ts.u8');
      print('Dictionary file loaded, size: ${data.length} bytes');
      
      final List<String> lines = data.split('\n');
      print('Dictionary contains ${lines.length} lines');
      
      // Skip comments and process entries in batches to avoid UI freeze
      final validLines = lines.where((line) => line.trim().isNotEmpty && !line.startsWith('#')).toList();
      print('Found ${validLines.length} non-comment lines to process');
      
      const int batchSize = 1000;
      int processedCount = 0;
      int validEntryCount = 0;
      
      for (int i = 0; i < validLines.length; i += batchSize) {
        final end = (i + batchSize < validLines.length) ? i + batchSize : validLines.length;
        final batch = validLines.sublist(i, end);
        
        for (var line in batch) {
          try {
            final entry = DictionaryEntry.fromCEDICTLine(line);
            if (entry.isValid) {
              _entries.add(entry);
              validEntryCount++;
            }
          } catch (e) {
            print('Error parsing line: $e');
            print('Problematic line: $line');
          }
        }
        
        processedCount += batch.length;
        print('Processed ${processedCount}/${validLines.length} entries, valid: $validEntryCount');
        
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
    
    // Handle different pinyin formats
    bool hasToneMarks = PinyinUtils.containsToneMarks(query);
    bool hasToneNumbers = PinyinUtils.containsToneNumbers(query);
    
    // Remove all tone markers for plain search
    final String plainQuery = hasToneMarks 
        ? PinyinUtils.removeToneMarks(queryLower)
        : hasToneNumbers 
            ? PinyinUtils.removeToneNumbers(queryLower)
            : queryLower;
    
    return _entries
        .where((entry) {
          // Normalize entry pinyin for comparison
          final String entryPinyin = entry.pinyin.toLowerCase();
          final String entryPlainPinyin = PinyinUtils.removeToneNumbers(entryPinyin);
          
          // Direct match (with any tone marks/numbers)
          if (hasToneMarks || hasToneNumbers) {
            if (entryPinyin.contains(queryLower)) return true;
          }
          
          // Match without tone markers
          return entryPlainPinyin.contains(plainQuery);
        })
        .toList();
  }

  // Search for entries by English definition
  List<DictionaryEntry> searchByDefinition(String query) {
    if (query.isEmpty) return [];
    
    final String normalizedQuery = query.toLowerCase();
    
    return _entries
        .where((entry) => 
            entry.definitions.any((def) => 
                def.toLowerCase().contains(normalizedQuery)
            )
        )
        .toList();
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