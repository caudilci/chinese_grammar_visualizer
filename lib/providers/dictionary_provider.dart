import 'package:flutter/foundation.dart';
import '../models/dictionary_entry.dart';
import '../services/dictionary_service.dart';
import '../utils/pinyin_utils.dart';

// Define an enum for search modes
enum SearchMode {
  auto,     // Automatically detect search type
  chinese,  // Search by Chinese characters (includes pinyin)
  english   // Search by English definition
}

class DictionaryProvider extends ChangeNotifier {
  final DictionaryService _dictionaryService = DictionaryService();
  
  List<DictionaryEntry> _searchResults = [];
  DictionaryEntry? _selectedEntry;
  bool _isLoading = false;
  bool _isInitialized = false;
  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.auto;
  
  // Getters
  List<DictionaryEntry> get searchResults => _searchResults;
  DictionaryEntry? get selectedEntry => _selectedEntry;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String get searchQuery => _searchQuery;
  SearchMode get searchMode => _searchMode;
  
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
    } catch (e) {
      print('Error in loadDictionary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Search dictionary with a query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _performSearch();
    notifyListeners();
  }
  
  // Set the search mode
  void setSearchMode(SearchMode mode) {
    _searchMode = mode;
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
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final String query = _searchQuery.trim();
      
      // Perform search based on selected mode
          switch (_searchMode) {
            case SearchMode.chinese:
              // Check if the query contains Chinese characters
              if (_containsChineseCharacters(query)) {
                // Search by Chinese characters
                _searchResults = _dictionaryService.searchBySimplified(query);
                // Add traditional search results without duplicates
                final traditionalResults = _dictionaryService.searchByTraditional(query);
                for (var entry in traditionalResults) {
                  if (!_searchResults.contains(entry)) {
                    _searchResults.add(entry);
                  }
                }
              } else {
                // If not Chinese characters, treat as pinyin
                // Search for pinyin (with or without tones)
                _searchResults = _dictionaryService.searchByPinyin(query);
              }
              break;
          
        case SearchMode.english:
          // Search by English definition
          _searchResults = _dictionaryService.searchByDefinition(query);
          break;
          
        case SearchMode.auto:
        default:
          // Auto-detect search type
          if (_containsChineseCharacters(query)) {
            // Search by Chinese characters
            _searchResults = _dictionaryService.search(query);
          } else if (PinyinUtils.containsToneMarks(query) ||
                     PinyinUtils.containsToneNumbers(query) ||
                     PinyinUtils.isPotentialPinyin(query)) {
            // Search by pinyin
            _searchResults = _dictionaryService.searchByPinyin(query);
          } else {
            // Default to definition search
            _searchResults = _dictionaryService.searchByDefinition(query);
          }
          break;
      }
      
      // Limit results to prevent performance issues
      if (_searchResults.length > 100) {
        _searchResults = _searchResults.sublist(0, 100);
      }
    } catch (e) {
      print('Error in performSearch: $e');
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