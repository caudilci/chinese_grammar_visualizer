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
          // Check if the query contains Chinese characters
          if (_containsChineseCharacters(query)) {
            // Search by Chinese characters
            _allResults = _dictionaryService.searchBySimplified(query);
            // Add traditional search results without duplicates
            final traditionalResults = _dictionaryService.searchByTraditional(query);
            for (var entry in traditionalResults) {
              if (!_allResults.contains(entry)) {
                _allResults.add(entry);
              }
            }
          } else {
            // If not Chinese characters, treat as pinyin
            // Search for pinyin (with or without tones)
            _allResults = _dictionaryService.searchByPinyin(query);
          }
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