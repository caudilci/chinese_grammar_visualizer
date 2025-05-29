import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/grammar_pattern.dart';
import '../models/practice_item.dart';
import '../services/grammar_service.dart';

class PracticeProvider extends ChangeNotifier {
  final GrammarService _grammarService = GrammarService();

  // Active practice session
  PracticeSession? _activeSession;
  List<PracticeWordItem> _shuffledWords = [];
  
  // The current arrangement of words in slots
  List<PracticeWordItem?> _currentArrangement = [];
  
  // Tracking success/failure
  bool _isCorrect = false;
  bool _isSubmitted = false;
  bool _isLoading = false;
  
  // Getters
  PracticeSession? get activeSession => _activeSession;
  List<PracticeWordItem> get shuffledWords => _shuffledWords;
  List<PracticeWordItem?> get currentArrangement => _currentArrangement;
  bool get isCorrect => _isCorrect;
  bool get isSubmitted => _isSubmitted;
  bool get isLoading => _isLoading;
  bool get hasActiveSession => _activeSession != null;
  
  // Initialize a new practice session for a grammar pattern
  Future<void> startPracticeForGrammarPattern(String grammarPatternId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get the grammar pattern
      final pattern = await _grammarService.getPatternById(grammarPatternId);
      
      if (pattern == null) {
        throw Exception('Grammar pattern not found');
      }
      
      // Create practice items from the examples
      final items = pattern.examples.map((example) => 
        PracticeItem.fromGrammarExample(example, pattern)
      ).toList();
      
      // Initialize a new practice session
      _activeSession = PracticeSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        grammarPatternId: grammarPatternId,
        items: items,
      );
      
      // Reset the UI state
      _resetCurrentPracticeState();
    } catch (e) {
      print('Error starting practice: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Reset the current practice state
  void _resetCurrentPracticeState() {
    if (_activeSession == null) return;
    
    final currentItem = _activeSession!.currentItem;
    
    // Get shuffled words for the current item
    _shuffledWords = currentItem.getShuffledWords();
    
    // Reset placement status
    for (var word in _shuffledWords) {
      word.setPlaced(false);
    }
    
    // Initialize empty arrangement
    _currentArrangement = List.filled(currentItem.words.length, null);
    
    // Reset validation state
    _isCorrect = false;
    _isSubmitted = false;
    
    notifyListeners();
  }
  
  // Move to the next practice item
  void moveToNextItem() {
    if (_activeSession == null) return;
    
    if (_activeSession!.moveToNext()) {
      _resetCurrentPracticeState();
    }
  }
  
  // Move to the previous practice item
  void moveToPreviousItem() {
    if (_activeSession == null) return;
    
    if (_activeSession!.moveToPrevious()) {
      _resetCurrentPracticeState();
    }
  }
  
  // End the current practice session
  void endPracticeSession() {
    _activeSession = null;
    _shuffledWords = [];
    _currentArrangement = [];
    _isCorrect = false;
    _isSubmitted = false;
    notifyListeners();
  }
  
  // Place a word in a slot
  void placeWordInSlot(PracticeWordItem word, int slotIndex) {
    if (_activeSession == null || _isSubmitted) return;
    
    // Check if slot is already filled
    if (_currentArrangement[slotIndex] != null) return;
    
    // Find the word in the shuffled list and mark it as placed
    final index = _shuffledWords.indexWhere(
      (w) => w.text == word.text && !w.isPlaced
    );
    
    if (index != -1) {
      _shuffledWords[index].setPlaced(true);
      _currentArrangement[slotIndex] = word;
      notifyListeners();
    }
  }
  
  // Remove a word from a slot
  void removeWordFromSlot(int slotIndex) {
    if (_activeSession == null || _isSubmitted) return;
    
    final word = _currentArrangement[slotIndex];
    if (word == null) return;
    
    // Find the word in the shuffled list and mark it as not placed
    final index = _shuffledWords.indexWhere(
      (w) => w.text == word.text && w.isPlaced
    );
    
    if (index != -1) {
      _shuffledWords[index].setPlaced(false);
      _currentArrangement[slotIndex] = null;
      notifyListeners();
    }
  }
  
  // Check if all slots are filled
  bool get areAllSlotsFilled {
    return !_currentArrangement.contains(null);
  }
  
  // Submit current arrangement for validation
  void submitArrangement() {
    if (_activeSession == null || !areAllSlotsFilled) return;
    
    final currentItem = _activeSession!.currentItem;
    
    // Convert arrangement to list of texts
    final arrangement = _currentArrangement.map((word) => word!.text).toList();
    
    // Check if arrangement is correct
    _isCorrect = currentItem.checkAnswer(arrangement);
    _isSubmitted = true;
    
    if (_isCorrect) {
      _activeSession!.markCurrentAsCompleted();
    }
    
    notifyListeners();
  }
  
  // Get feedback for a specific slot
  bool isSlotCorrect(int slotIndex) {
    if (!_isSubmitted || _activeSession == null) return true;
    
    final word = _currentArrangement[slotIndex];
    if (word == null) return false;
    
    return _activeSession!.currentItem.isPositionCorrect(slotIndex, word.text);
  }
  
  // Retry current practice item
  void retryCurrentItem() {
    _resetCurrentPracticeState();
  }
  
  // Show solution for current practice item
  void showSolution() {
    if (_activeSession == null) return;
    
    final currentItem = _activeSession!.currentItem;
    final correctArrangement = currentItem.getCorrectArrangement();
    
    // Reset all words' placement status
    for (var word in _shuffledWords) {
      word.setPlaced(false);
    }
    
    // Fill in the correct arrangement
    _currentArrangement = [];
    for (int i = 0; i < correctArrangement.length; i++) {
      final text = correctArrangement[i];
      
      // Find the word in shuffled words
      final index = _shuffledWords.indexWhere((w) => w.text == text);
      if (index != -1) {
        _shuffledWords[index].setPlaced(true);
        _currentArrangement.add(_shuffledWords[index]);
      } else {
        // This shouldn't happen, but just in case
        _currentArrangement.add(null);
      }
    }
    
    _isSubmitted = true;
    _isCorrect = true;
    
    notifyListeners();
  }
}