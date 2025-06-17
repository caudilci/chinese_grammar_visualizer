import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dictionary_entry.dart';
import '../models/word_list.dart';

class WordListProvider with ChangeNotifier {
  static const String _storageKey = 'word_lists';
  static const String _pathSeparator = '/';

  List<WordList> _wordLists = [];
  bool _isInitialized = false;
  bool _isLoading = false;

  // Getters
  List<WordList> get wordLists => _wordLists;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  // Get all parent categories (lists that have children)
  Set<String> get parentCategories {
    Set<String> parents = {};

    for (final list in _wordLists) {
      if (list.name.contains(_pathSeparator)) {
        final segments = list.name.split(_pathSeparator);
        for (int i = 0; i < segments.length - 1; i++) {
          parents.add(segments.sublist(0, i + 1).join(_pathSeparator));
        }
      }
    }

    return parents;
  }

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
    // Check if a word list with this name already exists
    final existingList = getWordListByName(name);
    if (existingList != null) {
      return existingList;
    }

    // Generate a unique ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newList = WordList(id: id, name: name);

    _wordLists.add(newList);
    await _saveWordLists();
    notifyListeners();

    return newList;
  }

  // Create word lists for all parent folders in a hierarchical path
  Future<List<WordList>> createWordListsForPath(String path) async {
    List<WordList> createdLists = [];
    if (!path.contains(_pathSeparator)) {
      final list = await createWordList(path);
      createdLists.add(list);
      return createdLists;
    }

    // Create parent folders as needed
    final segments = path.split(_pathSeparator);
    String currentPath = '';

    for (int i = 0; i < segments.length; i++) {
      if (i > 0) currentPath += _pathSeparator;
      currentPath += segments[i];

      final list = await createWordList(currentPath);
      createdLists.add(list);
    }

    return createdLists;
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

  // Get a word list by name
  WordList? getWordListByName(String name) {
    try {
      return _wordLists.firstWhere((list) => list.name == name);
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

  // Add multiple dictionary entries to a word list in batch
  Future<void> addEntriesToList(
    String listId,
    List<DictionaryEntry> entries,
  ) async {
    final index = _wordLists.indexWhere((list) => list.id == listId);
    if (index != -1) {
      for (final entry in entries) {
        _wordLists[index].addEntry(entry);
      }
      await _saveWordLists();
      notifyListeners();
    }
  }

  // Get all word lists that are part of a category or its subcategories
  List<WordList> getWordListsInCategory(String category) {
    if (category.isEmpty) {
      return _wordLists;
    }

    return _wordLists
        .where(
          (list) =>
              list.name == category ||
              (list.name.startsWith(category) &&
                  list.name.length > category.length &&
                  list.name[category.length] == _pathSeparator),
        )
        .toList();
  }

  // Get direct children categories of a category
  List<String> getChildCategories(String parentCategory) {
    Set<String> children = {};
    String prefix = parentCategory.isEmpty
        ? ''
        : parentCategory + _pathSeparator;

    for (final list in _wordLists) {
      if (list.name.startsWith(prefix) && list.name != parentCategory) {
        // Extract just the next segment
        String remaining = list.name.substring(prefix.length);
        int nextSeparator = remaining.indexOf(_pathSeparator);
        if (nextSeparator >= 0) {
          children.add(prefix + remaining.substring(0, nextSeparator));
        } else {
          children.add(list.name);
        }
      }
    }

    return children.toList();
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
