import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dictionary_entry.dart';
import '../models/word_list.dart';

class WordListProvider with ChangeNotifier {
  static const String _storageKey = 'word_lists';
  
  List<WordList> _wordLists = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  
  // Getters
  List<WordList> get wordLists => _wordLists;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  
  // Initialize provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _loadWordLists();
      
      // Create default uncategorized list if no lists exist
      if (_wordLists.isEmpty) {
        _wordLists.add(WordList.uncategorized());
        await _saveWordLists();
      }
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing word lists: $e');
      // Create default uncategorized list in case of error
      _wordLists = [WordList.uncategorized()];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load word lists from storage
  Future<void> _loadWordLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedLists = prefs.getStringList(_storageKey);
      
      if (storedLists != null && storedLists.isNotEmpty) {
        _wordLists = storedLists
            .map((listJson) => WordList.deserialize(listJson))
            .toList();
      } else {
        _wordLists = [WordList.uncategorized()];
      }
    } catch (e) {
      print('Error loading word lists: $e');
      _wordLists = [WordList.uncategorized()];
    }
  }
  
  // Save word lists to storage
  Future<void> _saveWordLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serializedLists = _wordLists
          .map((list) => list.serialize())
          .toList();
      await prefs.setStringList(_storageKey, serializedLists);
    } catch (e) {
      print('Error saving word lists: $e');
    }
  }
  
  // Create a new word list
  Future<WordList> createWordList(String name) async {
    // Generate a unique ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newList = WordList(id: id, name: name);
    
    _wordLists.add(newList);
    await _saveWordLists();
    notifyListeners();
    
    return newList;
  }
  
  // Delete a word list
  Future<void> deleteWordList(String id) async {
    // Don't allow deleting the uncategorized list
    if (id == 'uncategorized') return;
    
    _wordLists.removeWhere((list) => list.id == id);
    await _saveWordLists();
    notifyListeners();
  }
  
  // Rename a word list
  Future<void> renameWordList(String id, String newName) async {
    final index = _wordLists.indexWhere((list) => list.id == id);
    if (index != -1) {
      _wordLists[index].name = newName;
      _wordLists[index].updatedAt = DateTime.now();
      await _saveWordLists();
      notifyListeners();
    }
  }
  
  // Get a word list by ID
  WordList? getWordListById(String id) {
    try {
      return _wordLists.firstWhere((list) => list.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get uncategorized word list
  WordList get uncategorizedList {
    try {
      return _wordLists.firstWhere((list) => list.id == 'uncategorized');
    } catch (e) {
      // Create it if it doesn't exist
      final uncategorized = WordList.uncategorized();
      _wordLists.add(uncategorized);
      _saveWordLists();
      return uncategorized;
    }
  }
  
  // Add a dictionary entry to a word list
  Future<void> addEntryToList(String listId, DictionaryEntry entry) async {
    final index = _wordLists.indexWhere((list) => list.id == listId);
    if (index != -1) {
      _wordLists[index].addEntry(entry);
      await _saveWordLists();
      notifyListeners();
    }
  }
  
  // Remove a dictionary entry from a word list
  Future<void> removeEntryFromList(String listId, DictionaryEntry entry) async {
    final index = _wordLists.indexWhere((list) => list.id == listId);
    if (index != -1) {
      _wordLists[index].removeEntry(entry);
      await _saveWordLists();
      notifyListeners();
    }
  }
  
  // Get all word lists that contain a specific entry
  List<WordList> getListsContainingEntry(DictionaryEntry entry) {
    return _wordLists.where((list) => list.containsEntry(entry)).toList();
  }
  
  // Check if an entry is in any word list
  bool isEntryInAnyList(DictionaryEntry entry) {
    return _wordLists.any((list) => list.containsEntry(entry));
  }
}