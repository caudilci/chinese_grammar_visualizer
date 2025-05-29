import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import '../models/dictionary_entry.dart';
import '../services/dictionary_service.dart';
import '../services/search_isolate.dart';
import '../utils/pinyin_utils.dart';

class DictionaryProvider extends ChangeNotifier {
  final DictionaryService _dictionaryService = DictionaryService();
  
  List<DictionaryEntry> _searchResults = [];
  DictionaryEntry? _selectedEntry;
  bool _isLoading = false;
  bool _isInitialized = false;
  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.auto;
  
  // Isolate related fields
  Isolate? _searchIsolate;
  SendPort? _searchSendPort;
  final ReceivePort _receivePort = ReceivePort();
  
  // Debounce timer
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  
  // Pagination
  int _currentPage = 0;
  static const int _resultsPerPage = 20;
  bool _hasMoreResults = false;
  List<DictionaryEntry> _allResults = [];
  
  // Getters
  List<DictionaryEntry> get searchResults => _searchResults;
  DictionaryEntry? get selectedEntry => _selectedEntry;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String get searchQuery => _searchQuery;
  SearchMode get searchMode => _searchMode;
  bool get hasMoreResults => _hasMoreResults;
  
  // Initialize and load dictionary data
  Future<void> loadDictionary() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dictionaryService.loadDictionary();
      _isInitialized = true;
      
      // Print sample entries for debugging
      _dictionaryService.debugPrintSampleEntries();
      
      // Initialize search isolate
      await _initializeSearchIsolate();
    } catch (e) {
      print('Error in loadDictionary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Initialize the search isolate
  Future<void> _initializeSearchIsolate() async {
    try {
      // Setup the receive port listener
      _receivePort.listen((dynamic data) {
        if (data is SendPort) {
          // Store the send port to communicate with the isolate
          _searchSendPort = data;
        } else if (data is SearchResult) {
          // Process search results from isolate
          _processSearchResults(data);
        }
      });
      
      // Create the isolate
      _searchIsolate = await Isolate.spawn(
        searchIsolateEntryPoint,
        _receivePort.sendPort,
      );
      
      print('Search isolate initialized');
    } catch (e) {
      print('Error initializing search isolate: $e');
      // Fall back to main thread search if isolate fails
    }
  }
  
  @override
  void dispose() {
    // Clean up isolate
    _searchIsolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
    
    // Clean up debounce timer
    _debounceTimer?.cancel();
    
    super.dispose();
  }
  
  // Search dictionary with a query
  void setSearchQuery(String query) {
    _searchQuery = query;
    
    // Reset pagination
    _currentPage = 0;
    _allResults = [];
    
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();
    
    // Immediately show loading state
    _isLoading = true;
    notifyListeners();
    
    // Debounce the search to prevent too many searches while typing
    _debounceTimer = Timer(_debounceDuration, () {
      if (query.isEmpty) {
        _searchResults = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      _performSearch();
    });
  }
  
  // Load the next page of results
  void loadMoreResults() {
    if (!_hasMoreResults || _isLoading) return;
    
    _currentPage++;
    _updatePaginatedResults();
    notifyListeners();
  }
  
  // Update the displayed results based on current page
  void _updatePaginatedResults() {
    final startIndex = 0;
    final endIndex = (_currentPage + 1) * _resultsPerPage;
    
    if (endIndex >= _allResults.length) {
      _searchResults = _allResults;
      _hasMoreResults = false;
    } else {
      _searchResults = _allResults.sublist(startIndex, endIndex);
      _hasMoreResults = true;
    }
  }
  
  // Set the search mode
  void setSearchMode(SearchMode mode) {
    _searchMode = mode;
    
    // Reset pagination
    _currentPage = 0;
    _allResults = [];
    
    if (_searchQuery.isNotEmpty) {
      _performSearch();
    }
    notifyListeners();
  }
  
  // Select an entry for detailed view
  void selectEntry(DictionaryEntry entry) {
    _selectedEntry = entry;
    notifyListeners();
  }
  
  // Clear selected entry
  void clearSelectedEntry() {
    _selectedEntry = null;
    notifyListeners();
  }
  
  // Get dictionary entries for a specific word (for grammar example lookups)
  // searchWithNormalization: true for general dictionary search, false for exact matching from grammar examples
  List<DictionaryEntry> getDictionaryEntriesForWord(String word, {String? pinyin, bool searchWithNormalization = true}) {
    if (word.isEmpty) return [];
    
    // Special debugging for "上" character
    if (word == '上') {
      print('>>> DEBUG: Looking up 上 with pinyin: $pinyin (normalization: $searchWithNormalization)');
    }
    
    // For grammar examples (non-normalized search), try to find exact matches first
    if (!searchWithNormalization && pinyin != null && pinyin.isNotEmpty) {
      // First get all character matches
      var characterMatches = _dictionaryService.entries.where((entry) => 
        entry.simplified == word || entry.traditional == word
      ).toList();
      
      if (characterMatches.isNotEmpty) {
        // Convert the example pinyin to numerical form for consistent comparison
        String queryNumPinyin = PinyinUtils.toNumericalPinyin(pinyin);
        
        // Find entries with exact numerical pinyin match
        var exactMatches = characterMatches.where((entry) {
          String entryNumPinyin = PinyinUtils.toNumericalPinyin(entry.pinyin);
          bool isMatch = entryNumPinyin == queryNumPinyin;
          
          if (word == '上') {
            print('>>> Comparing numerical pinyin for 上: entry=$entryNumPinyin vs query=$queryNumPinyin, match=$isMatch');
          }
          
          return isMatch;
        }).toList();
        
        // If we found exact matches, return them immediately
        if (exactMatches.isNotEmpty) {
          if (word == '上') {
            print('>>> Found ${exactMatches.length} EXACT matches for 上 with pinyin: $pinyin');
            for (var i = 0; i < exactMatches.length; i++) {
              print('>>> Exact Match $i: ${exactMatches[i].simplified} [${exactMatches[i].pinyin}] - ${exactMatches[i].definitions.join('; ')}');
            }
          }
          return exactMatches;
        }
      }
    }
    
    // Get all character matches first
    var characterMatches = _dictionaryService.entries.where((entry) => 
      entry.simplified == word || entry.traditional == word
    ).toList();
    
    // Sort by exact pinyin match if we have pinyin (for all characters, not just "上")
    if (pinyin != null && pinyin.isNotEmpty && !searchWithNormalization) {
      // Convert our test pinyin to numerical form for reliable comparison
      final String queryNumPinyin = PinyinUtils.toNumericalPinyin(pinyin);
      
      characterMatches.sort((a, b) {
        final String aNumPinyin = PinyinUtils.toNumericalPinyin(a.pinyin);
        final String bNumPinyin = PinyinUtils.toNumericalPinyin(b.pinyin);
        
        // Exact numerical pinyin match comes first
        final bool aExactMatch = aNumPinyin == queryNumPinyin;
        final bool bExactMatch = bNumPinyin == queryNumPinyin;
        
        if (aExactMatch && !bExactMatch) return -1;
        if (!aExactMatch && bExactMatch) return 1;
        
        return 0;
      });
    }
    
    // Debug info for "上" character
    if (word == '上') {
      print('>>> Found ${characterMatches.length} character matches for 上:');
      for (var i = 0; i < characterMatches.length; i++) {
        print('>>> Match $i: ${characterMatches[i].simplified} [${characterMatches[i].pinyin}] - ${characterMatches[i].definitions.join('; ')}');
      }
    }
    
    // If pinyin is provided, sort to prioritize entries with matching pinyin
    if (pinyin != null && pinyin.isNotEmpty && characterMatches.isNotEmpty) {
      // Different formats of pinyin we should check
      final pinyinVariations = searchWithNormalization 
          ? [
              pinyin,                                 // Original format
              pinyin.toLowerCase(),                   // Lowercase
              PinyinUtils.normalizePinyin(pinyin),    // Without tones
              PinyinUtils.toNumericalPinyin(pinyin),  // With numerical tones
              PinyinUtils.toDiacriticPinyin(pinyin),  // With diacritic tones
              pinyin.trim(),                          // Trimmed
              pinyin.toLowerCase().trim()             // Lowercase and trimmed
            ]
          : [
              pinyin,                                 // Original format
              pinyin.toLowerCase(),                   // Lowercase only
              pinyin.trim(),                          // Trimmed
              pinyin.toLowerCase().trim(),            // Lowercase and trimmed
              PinyinUtils.toNumericalPinyin(pinyin)   // Add numerical for 上 case
            ];
      
      // Debug for "上" character
      if (word == '上') {
        print('>>> Pinyin variations for $pinyin:');
        for (var i = 0; i < pinyinVariations.length; i++) {
          print('>>> Variation $i: "${pinyinVariations[i]}"');
        }
      }

      
      // First collect exact pinyin matches
      final exactPinyinMatches = <DictionaryEntry>[];
      final otherMatches = <DictionaryEntry>[];
      
      for (var entry in characterMatches) {
        // Check if any of our pinyin variations match the entry's pinyin or its variations
        bool isExactMatch = false;
        
        if (searchWithNormalization) {
          // For normalized search, use PinyinUtils.pinyinMatches or variation contains
          isExactMatch = pinyinVariations.contains(entry.pinyin) || 
                         pinyinVariations.contains(entry.pinyin.toLowerCase()) ||
                         PinyinUtils.pinyinMatches(entry.pinyin, pinyin);
        } else {
          // For exact match (grammar examples), require exact equality
          // Note: We shouldn't reach here for grammar examples as we check for exact matches earlier
          isExactMatch = entry.pinyin == pinyin || 
                         entry.pinyin.trim() == pinyin.trim();
        }
        
        // Debug for "上" character
        if (word == '上') {
          print('>>> Comparing entry: ${entry.simplified} [${entry.pinyin}]');
          print('>>> isExactMatch: $isExactMatch');
        }

        
        if (isExactMatch) {
          exactPinyinMatches.add(entry);
        } else {
          otherMatches.add(entry);
        }
      }
      
      // If we have exact pinyin matches, return those first
      if (exactPinyinMatches.isNotEmpty) {
        // Debug for "上" character
        if (word == '上') {
          print('>>> Found ${exactPinyinMatches.length} exact pinyin matches');
          for (var entry in exactPinyinMatches) {
            print('>>> Exact match: ${entry.simplified} [${entry.pinyin}]');
          }
        }
        return [...exactPinyinMatches, ...otherMatches];
      }
    }
    
    // If no pinyin match or no pinyin provided, return character matches
    if (characterMatches.isNotEmpty) {
      // Debug for "上" character
      if (word == '上') {
        print('>>> Returning ${characterMatches.length} character matches (no pinyin matches found)');
      }
      return characterMatches;
    }
    
    // If still no matches, try characters that contain the word
    // (for multi-character words or compounds)
    var containsMatches = _dictionaryService.entries.where((entry) => 
      entry.simplified.contains(word) || entry.traditional.contains(word)
    ).toList();
    
    // If pinyin is provided, sort to prioritize those with matching pinyin
    if (pinyin != null && pinyin.isNotEmpty && containsMatches.isNotEmpty) {
      final pinyinVariations = searchWithNormalization 
          ? [
              pinyin,
              pinyin.toLowerCase(),
              PinyinUtils.normalizePinyin(pinyin),
              PinyinUtils.toNumericalPinyin(pinyin),
              PinyinUtils.toDiacriticPinyin(pinyin)
            ]
          : [
              pinyin,
              pinyin.toLowerCase()
            ];
      
      // Debug for 上 character
      if (word.contains('上')) {
        print('>>> Partial match for 上 with pinyin variations:');
        for (var variation in pinyinVariations) {
          print('>>> Variation: "$variation"');
        }
      }

      
      containsMatches.sort((a, b) {
        // Check if entry's pinyin matches any of our variations
        bool aMatch, bMatch;
        
        if (searchWithNormalization) {
          aMatch = pinyinVariations.contains(a.pinyin) || 
                  pinyinVariations.contains(a.pinyin.toLowerCase()) ||
                  PinyinUtils.pinyinMatches(a.pinyin, pinyin);
          bMatch = pinyinVariations.contains(b.pinyin) || 
                  pinyinVariations.contains(b.pinyin.toLowerCase()) ||
                  PinyinUtils.pinyinMatches(b.pinyin, pinyin);
        } else {
          aMatch = a.pinyin == pinyin || a.pinyin.trim() == pinyin.trim();
          bMatch = b.pinyin == pinyin || b.pinyin.trim() == pinyin.trim();
        }
                       
        // Debug for 上 character
        if (word.contains('上') && (a.pinyin.contains('shang') || b.pinyin.contains('shang'))) {
          print('>>> Comparing for sort:');
          print('>>> A: ${a.simplified} [${a.pinyin}] - match: $aMatch');
          print('>>> B: ${b.simplified} [${b.pinyin}] - match: $bMatch');
        }
        
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
        
        // If both match or don't match pinyin, sort by character length (shorter first)
        return a.simplified.length.compareTo(b.simplified.length);
      });
    }
    
    return containsMatches;
  }
  
  // Internal search method that handles all search types
  void _performSearch() {
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    // Convert the local search mode to the isolate search mode
    final isolateSearchMode = _convertToIsolateSearchMode(_searchMode);
    
    // If isolate is available, use it
    if (_searchSendPort != null) {
      _performIsolateSearch(isolateSearchMode);
    } else {
      // Fall back to main thread search
      _performMainThreadSearch();
    }
  }
  
  // Convert local search mode to isolate search mode
  SearchMode _convertToIsolateSearchMode(SearchMode mode) {
    switch (mode) {
      case SearchMode.auto:
        return SearchMode.auto;
      case SearchMode.chinese:
        return SearchMode.chinese;
      case SearchMode.english:
        return SearchMode.english;
      default:
        return SearchMode.auto;
    }
  }
  
  // Perform search in an isolate
  void _performIsolateSearch(SearchMode isolateSearchMode) {
    final responsePort = ReceivePort();
    
    // Send search request to isolate
    _searchSendPort!.send(SearchMessage(
      entries: _dictionaryService.entries,
      query: _searchQuery.trim(),
      searchMode: isolateSearchMode,
      responsePort: responsePort.sendPort,
    ));
    
    // Listen for the response
    responsePort.listen((dynamic result) {
      if (result is SearchResult) {
        _processSearchResults(result);
      }
      responsePort.close();
    });
  }
  
  // Process search results from the isolate
  void _processSearchResults(SearchResult result) {
    // Make sure the result is for the current query
    if (result.query != _searchQuery.trim()) {
      return;
    }
    
    if (result.error.isNotEmpty) {
      print('Search error: ${result.error}');
      _allResults = [];
      _searchResults = [];
    } else {
      _allResults = result.results;
      _updatePaginatedResults();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Fallback method to perform search on the main thread
  void _performMainThreadSearch() {
    try {
      final String query = _searchQuery.trim();
      
      // Perform search based on selected mode
      switch (_searchMode) {
        case SearchMode.chinese:
          // For Chinese/Pinyin mode, always search both character and pinyin 
          List<DictionaryEntry> results = [];
          
          // If query contains Chinese characters, search by characters
          if (_containsChineseCharacters(query)) {
            // Search by Chinese characters
            results = _dictionaryService.searchBySimplified(query);
            // Add traditional search results without duplicates
            final traditionalResults = _dictionaryService.searchByTraditional(query);
            for (var entry in traditionalResults) {
              if (!results.contains(entry)) {
                results.add(entry);
              }
            }
          }
          
          // Also search for pinyin regardless of whether query has Chinese chars
          final pinyinResults = _dictionaryService.searchByPinyin(query);
          print('Pinyin search results: ${pinyinResults.length}');
          
          // Combine results without duplicates
          for (var entry in pinyinResults) {
            if (!results.contains(entry)) {
              results.add(entry);
            }
          }
          
          _allResults = results;
          break;
      
        case SearchMode.english:
          // Search by English definition
          _allResults = _dictionaryService.searchByDefinition(query);
          break;
          
        case SearchMode.auto:
        default:
          // Auto-detect search type
          if (_containsChineseCharacters(query)) {
            // Search by Chinese characters
            _allResults = _dictionaryService.search(query);
          } else if (PinyinUtils.containsToneMarks(query) ||
                     PinyinUtils.containsToneNumbers(query) ||
                     PinyinUtils.isPotentialPinyin(query)) {
            // Search by pinyin
            _allResults = _dictionaryService.searchByPinyin(query);
            print('Auto-detected pinyin search results: ${_allResults.length}');
          } else {
            // Default to definition search
            _allResults = _dictionaryService.searchByDefinition(query);
          }
          break;
      }
      
      _updatePaginatedResults();
    } catch (e) {
      print('Error in performMainThreadSearch: $e');
      _allResults = [];
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Helper method to check if a string contains Chinese characters
  bool _containsChineseCharacters(String text) {
    // Use the utility method from PinyinUtils
    return PinyinUtils.containsChineseCharacters(text);
  }
}