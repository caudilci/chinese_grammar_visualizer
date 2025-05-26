import 'package:flutter/foundation.dart';
import '../models/dictionary_entry.dart';
import '../services/dictionary_service.dart';
import '../utils/pinyin_utils.dart';

class DictionaryProvider extends ChangeNotifier {
  final DictionaryService _dictionaryService = DictionaryService();
  
  List<DictionaryEntry> _searchResults = [];
  DictionaryEntry? _selectedEntry;
  bool _isLoading = false;
  bool _isInitialized = false;
  String _searchQuery = '';
  
  // Getters
  List<DictionaryEntry> get searchResults => _searchResults;
  DictionaryEntry? get selectedEntry => _selectedEntry;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String get searchQuery => _searchQuery;
  
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
      
      // Determine search type and execute appropriate search
      if (_containsChineseCharacters(query)) {
        // Search by Chinese characters
        _searchResults = _dictionaryService.search(query);
      } else if (PinyinUtils.containsToneMarks(query)) {
        // Search by pinyin with tone marks
        _searchResults = _dictionaryService.searchByPinyin(query);
      } else if (PinyinUtils.containsToneNumbers(query)) {
        // Search by pinyin with tone numbers
        _searchResults = _dictionaryService.searchByPinyin(query);
      } else if (PinyinUtils.isPotentialPinyin(query)) {
        // Search by pinyin without tone marks
        _searchResults = _dictionaryService.searchByPinyin(query);
      } else {
        // Default to definition search
        _searchResults = _dictionaryService.searchByDefinition(query);
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
    final RegExp chineseRegExp = RegExp(r'[\u4e00-\u9fff]');
    return chineseRegExp.hasMatch(text);
  }
}