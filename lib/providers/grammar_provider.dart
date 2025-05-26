import 'package:flutter/foundation.dart';
import '../models/grammar_pattern.dart';
import '../services/grammar_service.dart';
import '../utils/pinyin_utils.dart';

class GrammarProvider extends ChangeNotifier {
  final GrammarService _grammarService = GrammarService();
  
  List<GrammarPattern> _patterns = [];
  List<GrammarPattern> _filteredPatterns = [];
  GrammarPattern? _selectedPattern;
  String? _selectedCategory;
  int? _selectedDifficultyLevel;
  bool _isLoading = false;
  String _searchQuery = '';
  
  // Getters
  List<GrammarPattern> get patterns => _patterns;
  List<GrammarPattern> get filteredPatterns => _filteredPatterns;
  GrammarPattern? get selectedPattern => _selectedPattern;
  String? get selectedCategory => _selectedCategory;
  int? get selectedDifficultyLevel => _selectedDifficultyLevel;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  
  // Initialize and load data
  Future<void> loadGrammarPatterns() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _patterns = await _grammarService.loadGrammarPatterns();
      _applyFilters();
    } catch (e) {
      print('Error in loadGrammarPatterns: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Apply any active filters
  void _applyFilters() {
    _filteredPatterns = List.from(_patterns);
    
    // Apply category filter if selected
    if (_selectedCategory != null) {
      _filteredPatterns = _filteredPatterns
          .where((pattern) => pattern.category == _selectedCategory)
          .toList();
    }
    
    // Apply difficulty filter if selected
    if (_selectedDifficultyLevel != null) {
      _filteredPatterns = _filteredPatterns
          .where((pattern) => pattern.difficultyLevel == _selectedDifficultyLevel)
          .toList();
    }
    
    // Apply search filter if there's a query
    if (_searchQuery.isNotEmpty) {
      _filteredPatterns = _filteredPatterns
          .where((pattern) => 
              pattern.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              pattern.chineseTitle.contains(_searchQuery) ||
              pattern.englishTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              pattern.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              // Search examples for pinyin matches (with or without tone marks)
              pattern.examples.any((example) => 
                  PinyinUtils.matchesWithoutTones(example.pinyinSentence, _searchQuery) ||
                  example.breakdownParts.any((part) => 
                      PinyinUtils.matchesWithoutTones(part.pinyin, _searchQuery)
                  )
              )
          )
          .toList();
    }
  }
  
  // Set selected pattern
  void selectPattern(String patternId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _selectedPattern = await _grammarService.getPatternById(patternId);
    } catch (e) {
      print('Error in selectPattern: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Clear selected pattern
  void clearSelectedPattern() {
    _selectedPattern = null;
    notifyListeners();
  }
  
  // Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }
  
  // Filter by difficulty level
  void filterByDifficultyLevel(int? level) {
    _selectedDifficultyLevel = level;
    _applyFilters();
    notifyListeners();
  }
  
  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }
  
  // Clear all filters
  void clearFilters() {
    _selectedCategory = null;
    _selectedDifficultyLevel = null;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }
  
  // Get all unique categories
  Future<List<String>> getCategories() async {
    return await _grammarService.getAllCategories();
  }
  
  // Get max difficulty level
  Future<int> getMaxDifficultyLevel() async {
    return await _grammarService.getMaxDifficultyLevel();
  }
}