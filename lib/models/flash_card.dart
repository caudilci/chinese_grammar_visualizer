import 'dictionary_entry.dart';

/// Represents the difficulty/familiarity level of a card
enum CardLevel {
  /// New or difficult cards (reviewed frequently)
  difficult,

  /// Cards that have been answered correctly a few times (reviewed occasionally)
  learning,

  /// Cards that have been mastered (reviewed infrequently)
  mastered
}

/// Represents a single review attempt of a card
class ReviewAttempt {
  /// When the review was performed
  final DateTime reviewedAt;

  /// Whether the user got the card correct
  final bool wasCorrect;

  ReviewAttempt({
    required this.reviewedAt,
    required this.wasCorrect,
  });

  /// Create from JSON
  factory ReviewAttempt.fromJson(Map<String, dynamic> json) {
    return ReviewAttempt(
      reviewedAt: DateTime.parse(json['reviewedAt'] as String),
      wasCorrect: json['wasCorrect'] as bool,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'reviewedAt': reviewedAt.toIso8601String(),
      'wasCorrect': wasCorrect,
    };
  }
}

/// Represents a flash card with a dictionary entry and study data
class FlashCard {
  /// The dictionary entry to study
  final DictionaryEntry entry;

  /// When the card was created
  final DateTime createdAt;

  /// When the card was last reviewed
  DateTime? lastReviewedAt;

  /// Current difficulty/familiarity level
  CardLevel level;

  /// Number of consecutive correct answers
  int consecutiveCorrect;

  /// Total number of reviews
  int totalReviews;

  /// Number of correct reviews
  int correctReviews;

  /// History of review attempts
  List<ReviewAttempt> reviewHistory;

  /// Due date for next review (calculated based on level and last review)
  DateTime? dueDate;

  FlashCard({
    required this.entry,
    DateTime? createdAt,
    this.lastReviewedAt,
    this.level = CardLevel.difficult,
    this.consecutiveCorrect = 0,
    this.totalReviews = 0,
    this.correctReviews = 0,
    List<ReviewAttempt>? reviewHistory,
    this.dueDate,
  }) :
    createdAt = createdAt ?? DateTime.now(),
    reviewHistory = reviewHistory ?? [];

  /// Record a review attempt and update card statistics
  void recordReview(bool correct) {
    final now = DateTime.now();

    // Update statistics
    totalReviews++;
    if (correct) {
      correctReviews++;
      consecutiveCorrect++;
    } else {
      consecutiveCorrect = 0;
    }

    // Add to history
    reviewHistory.add(ReviewAttempt(
      reviewedAt: now,
      wasCorrect: correct,
    ));

    // Update level based on performance
    if (correct) {
      if (level == CardLevel.difficult && consecutiveCorrect >= 2) {
        level = CardLevel.learning;
      } else if (level == CardLevel.learning && consecutiveCorrect >= 4) {
        level = CardLevel.mastered;
      }
    } else {
      // If incorrect, move card back to difficult
      level = CardLevel.difficult;
    }

    // Update review date
    lastReviewedAt = now;

    // Calculate next due date based on level
    _calculateNextDueDate();
  }

  /// Calculate when this card should be reviewed next
  void _calculateNextDueDate() {
    if (lastReviewedAt == null) {
      dueDate = DateTime.now();
      return;
    }

    final now = DateTime.now();

    // Spaced repetition intervals based on difficulty level
    switch (level) {
      case CardLevel.difficult:
        // Review daily
        dueDate = now.add(const Duration(days: 1));
        break;
      case CardLevel.learning:
        // Review every 3 days
        dueDate = now.add(const Duration(days: 3));
        break;
      case CardLevel.mastered:
        // Review every 7 days
        dueDate = now.add(const Duration(days: 7));
        break;
    }
  }

  /// Get the accuracy percentage for this card
  double get accuracy {
    if (totalReviews == 0) return 0.0;
    return (correctReviews / totalReviews) * 100;
  }

  /// Check if the card is due for review
  bool isDue() {
    if (dueDate == null) return true;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Create from JSON
  factory FlashCard.fromJson(Map<String, dynamic> json) {
    return FlashCard(
      entry: DictionaryEntry.fromJson(json['entry'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'] as String)
          : null,
      level: CardLevel.values.byName(json['level'] as String),
      consecutiveCorrect: json['consecutiveCorrect'] as int,
      totalReviews: json['totalReviews'] as int,
      correctReviews: json['correctReviews'] as int,
      reviewHistory: (json['reviewHistory'] as List<dynamic>)
          .map((e) => ReviewAttempt.fromJson(e as Map<String, dynamic>))
          .toList(),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'entry': entry.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'level': level.name,
      'consecutiveCorrect': consecutiveCorrect,
      'totalReviews': totalReviews,
      'correctReviews': correctReviews,
      'reviewHistory': reviewHistory.map((e) => e.toJson()).toList(),
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  /// Check if this flash card represents the same dictionary entry
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashCard &&
          runtimeType == other.runtimeType &&
          entry == other.entry;

  @override
  int get hashCode => entry.hashCode;
}

/// Represents a session of flash card review
class FlashCardSession {
  /// Unique identifier for the session
  final String id;

  /// When the session was started
  final DateTime startedAt;

  /// When the session was completed
  DateTime? completedAt;

  /// IDs of word lists included in this session
  final List<String> wordListIds;

  /// Total cards in the session
  final int totalCards;

  /// Whether the session is in endless mode
  final bool isEndless;

  /// Cards reviewed in this session (key: unique review ID, value: was correct)
  final Map<String, bool> reviewedCards;

  /// Count of unique words reviewed (for stats)
  final Set<String> uniqueWordsReviewed;

  FlashCardSession({
    required this.id,
    required this.wordListIds,
    required this.totalCards,
    required this.isEndless,
    DateTime? startedAt,
    this.completedAt,
    Map<String, bool>? reviewedCards,
    Set<String>? uniqueWordsReviewed,
  }) :
    startedAt = startedAt ?? DateTime.now(),
    reviewedCards = reviewedCards ?? {},
    uniqueWordsReviewed = uniqueWordsReviewed ?? {};

  /// Mark a card as reviewed
  void markCardReviewed(String reviewId, bool wasCorrect) {
    // Store the review result with the unique review ID
    reviewedCards[reviewId] = wasCorrect;

    // Extract the base entry ID (without timestamp) to track unique words
    if (reviewId.contains('-')) {
      String baseEntryId = reviewId.split('-').first;
      uniqueWordsReviewed.add(baseEntryId);
    } else {
      // For backwards compatibility
      uniqueWordsReviewed.add(reviewId);
    }
  }

  /// Complete the session
  void complete() {
    if (!isCompleted) {
      completedAt = DateTime.now();
    }
  }

  /// Get the number of cards reviewed
  int get cardsReviewed => reviewedCards.length;

  /// Get the number of correct answers
  int get correctAnswers => reviewedCards.values.where((v) => v).length;

  /// Get the number of incorrect answers
  int get incorrectAnswers => reviewedCards.values.where((v) => !v).length;

  /// Get the accuracy percentage
  double get accuracy {
    if (cardsReviewed == 0) return 0.0;
    return (correctAnswers / cardsReviewed) * 100;
  }

  /// Get the completion percentage (0-100)
  double get completionPercentage {
    if (isEndless || totalCards <= 0) return 0.0;
    return (cardsReviewed / totalCards) * 100;
  }

  /// Check if the session is completed
  bool get isCompleted {
    if (completedAt != null) return true;
    if (isEndless) return false;
    if (totalCards <= 0) return false;

    // Compare the number of reviewed cards to the total cards requested
    int reviewed = reviewedCards.length;
    return reviewed >= totalCards;
  }

  /// Get the duration of the session
  Duration get duration {
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  /// Create from JSON
  factory FlashCardSession.fromJson(Map<String, dynamic> json) {
    // Create a session with the basic data
    final session = FlashCardSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      wordListIds: (json['wordListIds'] as List<dynamic>).cast<String>(),
      totalCards: json['totalCards'] as int,
      isEndless: json['isEndless'] as bool,
      reviewedCards: Map<String, bool>.from(json['reviewedCards'] as Map),
    );

    // Rebuild uniqueWordsReviewed set from the review IDs
    for (String reviewId in session.reviewedCards.keys) {
      if (reviewId.contains('-')) {
        String baseEntryId = reviewId.split('-').first;
        session.uniqueWordsReviewed.add(baseEntryId);
      } else {
        session.uniqueWordsReviewed.add(reviewId);
      }
    }

    return session;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'wordListIds': wordListIds,
      'totalCards': totalCards,
      'isEndless': isEndless,
      'reviewedCards': reviewedCards,
      // We don't need to explicitly save uniqueWordsReviewed
      // as it's reconstructed from reviewedCards
    };
  }
}
