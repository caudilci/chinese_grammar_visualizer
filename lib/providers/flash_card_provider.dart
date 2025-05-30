import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dictionary_entry.dart';
import '../models/flash_card.dart';
import '../models/word_list.dart';
import 'word_list_provider.dart';

class FlashCardProvider extends ChangeNotifier {
  static const String _storageKey = 'flash_cards';
  static const String _sessionsKey = 'flash_card_sessions';
  
  WordListProvider _wordListProvider;
  
  // Flash card data
  Map<String, FlashCard> _cards = {};
  List<FlashCardSession> _sessions = [];
  
  // Current session
  FlashCardSession? _currentSession;
  List<FlashCard> _sessionCards = [];
  int _currentCardIndex = 0;
  bool _isCardFlipped = false;
  
  // State flags
  bool _isInitialized = false;
  bool _isLoading = false;
  
  // Constructor
  FlashCardProvider(this._wordListProvider);
  
  // Update the word list provider reference
  void update(WordListProvider wordListProvider) {
    _wordListProvider = wordListProvider;
  }
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  Map<String, FlashCard> get cards => _cards;
  List<FlashCardSession> get sessions => _sessions;
  FlashCardSession? get currentSession => _currentSession;
  FlashCard? get currentCard => _sessionCards.isNotEmpty ? _sessionCards[_currentCardIndex] : null;
  bool get isCardFlipped => _isCardFlipped;
  bool get hasMoreCards => _hasMoreCards();
  bool get isSessionActive => _currentSession != null && !(_currentSession!.isCompleted);
  int get cardsRemaining => _currentSession?.isEndless == true ? -1 : 
                           (_currentSession != null ? _currentSession!.totalCards - _getSessionProgress() : 0);
  int get sessionProgress => _currentSession?.reviewedCards.length ?? 0;
  int get sessionTotal => _currentSession?.isEndless == true ? -1 : (_currentSession?.totalCards ?? 0);
  List<FlashCard> get sessionCards => _sessionCards;
  
  // Private methods to handle calculations
  bool _hasMoreCards() {
    // No cards or no session means no more cards
    if (_sessionCards.isEmpty || _currentSession == null) return false;
    
    // Endless mode always has more cards
    if (_currentSession!.isEndless) return true;
    
    // For regular mode, check if we've completed the target number
    return !_currentSession!.isCompleted;
  }
  
  int _getSessionProgress() {
    return _currentSession?.reviewedCards.length ?? 0;
  }

  // Initialize provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _loadFlashCards();
      await _loadSessions();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing flash cards: $e');
      _cards = {};
      _sessions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load flash cards from storage
  Future<void> _loadFlashCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedCards = prefs.getString(_storageKey);
      
      if (storedCards != null && storedCards.isNotEmpty) {
        final Map<String, dynamic> decodedCards = jsonDecode(storedCards) as Map<String, dynamic>;
        _cards = decodedCards.map((key, value) => 
          MapEntry(key, FlashCard.fromJson(value as Map<String, dynamic>)));
      }
    } catch (e) {
      print('Error loading flash cards: $e');
      _cards = {};
    }
  }
  
  // Load sessions from storage
  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedSessions = prefs.getString(_sessionsKey);
      
      if (storedSessions != null && storedSessions.isNotEmpty) {
        final List<dynamic> decodedSessions = jsonDecode(storedSessions) as List<dynamic>;
        _sessions = decodedSessions
            .map((e) => FlashCardSession.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error loading flash card sessions: $e');
      _sessions = [];
    }
  }
  
  // Save flash cards to storage
  Future<void> _saveFlashCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = jsonEncode(_cards.map((key, value) => 
        MapEntry(key, value.toJson())));
      await prefs.setString(_storageKey, cardsJson);
    } catch (e) {
      print('Error saving flash cards: $e');
    }
  }
  
  // Save sessions to storage
  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = jsonEncode(_sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, sessionsJson);
    } catch (e) {
      print('Error saving flash card sessions: $e');
    }
  }
  
  // Create or update flash card for a dictionary entry
  FlashCard _getOrCreateCard(DictionaryEntry entry) {
    final entryId = '${entry.simplified}:${entry.pinyin}';
    
    if (_cards.containsKey(entryId)) {
      return _cards[entryId]!;
    }
    
    final newCard = FlashCard(entry: entry);
    _cards[entryId] = newCard;
    return newCard;
  }
  
  // Get flash cards for a word list
  List<FlashCard> getCardsForWordList(WordList wordList) {
    if (wordList.entries.isEmpty) {
      print('Warning: Word list "${wordList.name}" is empty');
      return [];
    }
    return wordList.entries.map((entry) => _getOrCreateCard(entry)).toList();
  }
  
  // Get due cards for a word list
  List<FlashCard> getDueCardsForWordList(WordList wordList) {
    final cards = getCardsForWordList(wordList);
    return cards.where((card) => card.isDue()).toList();
  }
  
  // Start a new flash card session
  Future<bool> startSession({
    required List<String> wordListIds,
    required int numberOfCards,
    required bool isEndless,
  }) async {
    if (isSessionActive) {
      print('Cannot start a new session while one is active');
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get all cards from selected word lists
      final allCards = <FlashCard>[];
      bool hasEmptyWordLists = false;
      
      for (final listId in wordListIds) {
        final wordList = _wordListProvider.getWordListById(listId);
        if (wordList != null) {
          final cards = getCardsForWordList(wordList);
          if (cards.isEmpty) {
            hasEmptyWordLists = true;
            print('Warning: Word list ${wordList.name} (ID: $listId) is empty');
          }
          allCards.addAll(cards);
        } else {
          print('Warning: Could not find word list with ID: $listId');
        }
      }
      
      if (allCards.isEmpty) {
        print('Error: No cards available in the selected word lists');
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Always allow session creation even with fewer cards than requested
      if (allCards.length < numberOfCards && !isEndless) {
        print('Warning: Requested $numberOfCards cards but only ${allCards.length} available. Cards will be repeated as needed.');
      }
      
      // Sort cards with due and difficult cards first
      allCards.sort((a, b) {
        // First prioritize due cards
        if (a.isDue() && !b.isDue()) return -1;
        if (!a.isDue() && b.isDue()) return 1;
        
        // Then prioritize by difficulty level
        final levelOrder = {
          CardLevel.difficult: 0,
          CardLevel.learning: 1,
          CardLevel.mastered: 2,
        };
        
        final levelComparison = levelOrder[a.level]!.compareTo(levelOrder[b.level]!);
        if (levelComparison != 0) return levelComparison;
        
        // Then by last reviewed (oldest first)
        if (a.lastReviewedAt != null && b.lastReviewedAt != null) {
          return a.lastReviewedAt!.compareTo(b.lastReviewedAt!);
        } else if (a.lastReviewedAt == null && b.lastReviewedAt != null) {
          return -1;
        } else if (a.lastReviewedAt != null && b.lastReviewedAt == null) {
          return 1;
        }
        
        // Finally by creation date (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });
      
      // Make a deep copy of all available cards - we'll cycle through them if needed
      _sessionCards = List<FlashCard>.from(allCards);
      
      // Shuffle the cards to start with a random order
      if (_sessionCards.length > 1) {
        _sessionCards.shuffle();
        print('Shuffled ${_sessionCards.length} cards for the session');
      }
      
      // For endless mode, set a high number for display purposes only
      // For regular mode, use the requested number (will repeat cards if needed)
      final actualSessionSize = isEndless ? min(100, allCards.length) : max(1, numberOfCards);
      
      // Create a new session
      _currentSession = FlashCardSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        wordListIds: wordListIds,
        totalCards: actualSessionSize,
        isEndless: isEndless,
      );
      
      // Shuffle cards for random order at the start of the session
      _sessionCards.shuffle();
      
      _sessions.add(_currentSession!);
      await _saveSessions();
      
      // Reset session state
      _currentCardIndex = 0;
      _isCardFlipped = false;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error starting flash card session: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Flip the current card
  void flipCard() {
    _isCardFlipped = !_isCardFlipped;
    notifyListeners();
  }
  
  // Mark the current card as correct or incorrect
  Future<void> markCard(bool isCorrect) async {
    if (!isSessionActive) {
      print('Error: No active session when trying to mark card');
      return;
    }
    
    if (_sessionCards.isEmpty) {
      print('Error: Session cards list is empty');
      return;
    }
    
    if (_currentCardIndex >= _sessionCards.length) {
      print('Error: Current card index out of bounds: $_currentCardIndex >= ${_sessionCards.length}');
      _currentCardIndex = 0; // Reset to avoid crashes
    }
    
    final card = currentCard!;
    final entryId = '${card.entry.simplified}:${card.entry.pinyin}';
    
    // Record the review
    card.recordReview(isCorrect);
    await _saveFlashCards();
    
    // Update session data - always create a new review entry for progress tracking
    // Note: We now use a unique ID for each review to ensure counts increase
    final uniqueReviewId = '$entryId-${DateTime.now().millisecondsSinceEpoch}';
    _currentSession!.markCardReviewed(uniqueReviewId, isCorrect);
    await _saveSessions();
    
    // Check if we need to log progress
    final reviewCount = _currentSession!.reviewedCards.length;
    if (reviewCount % 5 == 0) {  // Log every 5 cards
      print('Progress: Reviewed $reviewCount cards so far');
    }
    
    // Check if we've reached the requested number of cards in a non-endless session
    if (_currentSession != null && !_currentSession!.isEndless) {
      int reviewed = _currentSession!.reviewedCards.length;
      int total = _currentSession!.totalCards;
      
      if (reviewed >= total) {
        print('Session completed: Reviewed $reviewed of $total cards');
        await endSession();
        notifyListeners();
        return;
      }
    }
    
    // Otherwise, move to next card
    _currentCardIndex++;
    _isCardFlipped = false;
    
    // If we've gone through all available cards but need to continue, cycle back to the beginning
    if (_currentCardIndex >= _sessionCards.length) {
      _currentCardIndex = 0;
      // Shuffle cards for more varied practice
      _sessionCards.shuffle();
      print('Cycled back to beginning of card list with ${_sessionCards.length} cards');
    }
    
    notifyListeners();
  }
  
  // End the current session
  Future<void> endSession() async {
    if (_currentSession != null && !_currentSession!.isCompleted) {
      _currentSession!.complete();
      await _saveSessions();
      
      // Clear current session cards to prevent any further operations
      _sessionCards = [];
      _currentCardIndex = 0;
      _isCardFlipped = false;
      
      notifyListeners();
      print('Session ended successfully');
    }
  }
  
  // Reset the current session
  void resetSession() {
    _currentSession = null;
    _sessionCards = [];
    _currentCardIndex = 0;
    _isCardFlipped = false;
    notifyListeners();
  }
  
  // Get statistics for a specific word list
  Map<String, dynamic> getStatsForWordList(String wordListId) {
    final wordList = _wordListProvider.getWordListById(wordListId);
    if (wordList == null) {
      return {
        'totalCards': 0,
        'dueCards': 0,
        'masterLevel': 0,
        'learningLevel': 0,
        'difficultLevel': 0,
        'averageAccuracy': 0.0,
      };
    }
    
    final cards = getCardsForWordList(wordList);
    final dueCards = cards.where((card) => card.isDue()).length;
    
    final difficultCards = cards.where((card) => card.level == CardLevel.difficult).length;
    final learningCards = cards.where((card) => card.level == CardLevel.learning).length;
    final masteredCards = cards.where((card) => card.level == CardLevel.mastered).length;
    
    double totalAccuracy = 0;
    int cardsWithReviews = 0;
    
    for (final card in cards) {
      if (card.totalReviews > 0) {
        totalAccuracy += card.accuracy;
        cardsWithReviews++;
      }
    }
    
    final averageAccuracy = cardsWithReviews > 0 ? totalAccuracy / cardsWithReviews : 0.0;
    
    return {
      'totalCards': cards.length,
      'dueCards': dueCards,
      'masterLevel': masteredCards,
      'learningLevel': learningCards,
      'difficultLevel': difficultCards,
      'averageAccuracy': averageAccuracy,
    };
  }
  
  // Get overall study statistics
  Map<String, dynamic> getOverallStats() {
    int totalReviews = 0;
    int totalCorrect = 0;
    int totalCards = _cards.length;
    int dueCards = _cards.values.where((card) => card.isDue()).length;
    
    final difficultCards = _cards.values.where((card) => card.level == CardLevel.difficult).length;
    final learningCards = _cards.values.where((card) => card.level == CardLevel.learning).length;
    final masteredCards = _cards.values.where((card) => card.level == CardLevel.mastered).length;
    
    for (final card in _cards.values) {
      totalReviews += card.totalReviews;
      totalCorrect += card.correctReviews;
    }
    
    final accuracy = totalReviews > 0 ? (totalCorrect / totalReviews) * 100 : 0.0;
    
    return {
      'totalCards': totalCards,
      'dueCards': dueCards,
      'totalReviews': totalReviews,
      'correctReviews': totalCorrect,
      'accuracy': accuracy,
      'difficultCards': difficultCards,
      'learningCards': learningCards,
      'masteredCards': masteredCards,
      'completedSessions': _sessions.where((s) => s.isCompleted).length,
    };
  }
  
  // Get recent sessions
  List<FlashCardSession> getRecentSessions({int limit = 10}) {
    final sorted = List<FlashCardSession>.from(_sessions);
    sorted.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sorted.take(limit).toList();
  }
}