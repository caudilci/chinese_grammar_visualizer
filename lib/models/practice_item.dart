import '../models/grammar_pattern.dart';

class PracticeItem {
  final String id;
  final String chineseSentence;
  final String pinyinSentence;
  final String englishTranslation;
  final List<PracticeWordItem> words;
  final List<String> slots;
  final String grammarPatternId;
  final GrammarPattern grammarPattern;
  final String? note;
  
  PracticeItem({
    required this.id,
    required this.chineseSentence,
    required this.pinyinSentence,
    required this.englishTranslation,
    required this.words,
    required this.slots,
    required this.grammarPatternId,
    required this.grammarPattern,
    this.note,
  });
  
  // Create a practice item from a grammar example
  factory PracticeItem.fromGrammarExample(GrammarExample example, GrammarPattern pattern) {
    // Extract words from the example to create practice word items
    final words = example.breakdownParts.map((part) => 
      PracticeWordItem(
        text: part.text,
        pinyin: part.pinyin,
        partOfSpeech: part.partOfSpeech,
        meaning: part.meaning,
        grammarFunction: part.grammarFunction,
      )
    ).toList();
    
    // Create slots based on the number of words
    final slots = List.generate(words.length, (index) => '');
    
    return PracticeItem(
      id: example.id,
      chineseSentence: example.chineseSentence,
      pinyinSentence: example.pinyinSentence,
      englishTranslation: example.englishTranslation,
      words: words,
      slots: slots,
      grammarPatternId: pattern.id,
      grammarPattern: pattern,
      note: example.note,
    );
  }
  
  // Check if the current arrangement is correct
  bool checkAnswer(List<String> arrangement) {
    if (arrangement.length != words.length) return false;
    
    // Check if the arrangement matches the original sentence order
    for (int i = 0; i < arrangement.length; i++) {
      if (arrangement[i].isNotEmpty && arrangement[i] != words[i].text) {
        return false;
      }
    }
    
    return true;
  }
  
  // Get the correct arrangement
  List<String> getCorrectArrangement() {
    return words.map((word) => word.text).toList();
  }
  
  // Check if a specific position is correct
  bool isPositionCorrect(int position, String text) {
    if (position >= 0 && position < words.length) {
      return words[position].text == text;
    }
    return false;
  }
  
  // Get a shuffled list of words for practice
  List<PracticeWordItem> getShuffledWords() {
    final shuffled = List<PracticeWordItem>.from(words);
    shuffled.shuffle();
    return shuffled;
  }
}

class PracticeWordItem {
  final String text;
  final String pinyin;
  final String partOfSpeech;
  final String? meaning;
  final String? grammarFunction;
  bool isPlaced = false;
  
  PracticeWordItem({
    required this.text,
    required this.pinyin,
    required this.partOfSpeech,
    this.meaning,
    this.grammarFunction,
  });
  
  // Mark as placed or not placed
  void setPlaced(bool placed) {
    isPlaced = placed;
  }
  
  // Create a copy of this word item
  PracticeWordItem copy() {
    return PracticeWordItem(
      text: text,
      pinyin: pinyin,
      partOfSpeech: partOfSpeech,
      meaning: meaning,
      grammarFunction: grammarFunction,
    );
  }
}

class PracticeSession {
  final String id;
  final String grammarPatternId;
  final List<PracticeItem> items;
  int currentItemIndex = 0;
  List<bool> completedItems = [];
  
  PracticeSession({
    required this.id,
    required this.grammarPatternId,
    required this.items,
  }) {
    // Initialize completedItems list
    completedItems = List.generate(items.length, (index) => false);
  }
  
  // Get the current practice item
  PracticeItem get currentItem => items[currentItemIndex];
  
  // Move to the next item
  bool moveToNext() {
    if (currentItemIndex < items.length - 1) {
      currentItemIndex++;
      return true;
    }
    return false;
  }
  
  // Move to the previous item
  bool moveToPrevious() {
    if (currentItemIndex > 0) {
      currentItemIndex--;
      return true;
    }
    return false;
  }
  
  // Mark current item as completed
  void markCurrentAsCompleted() {
    completedItems[currentItemIndex] = true;
  }
  
  // Check if all items are completed
  bool get isCompleted => completedItems.every((completed) => completed);
  
  // Get completion percentage
  double get completionPercentage {
    if (items.isEmpty) return 0.0;
    return completedItems.where((completed) => completed).length / items.length;
  }
}