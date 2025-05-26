class GrammarPattern {
  final String id;
  final String name;
  final String chineseTitle;
  final String englishTitle;
  final String description;
  final String structure;
  final List<GrammarExample> examples;
  final String category;
  final int difficultyLevel; // 1-5 where 5 is most difficult
  final Map<String, String> colorCoding; // Maps part of speech to color code

  GrammarPattern({
    required this.id,
    required this.name,
    required this.chineseTitle,
    required this.englishTitle,
    required this.description,
    required this.structure,
    required this.examples,
    required this.category,
    required this.difficultyLevel,
    required this.colorCoding,
  });

  factory GrammarPattern.fromJson(Map<String, dynamic> json) {
    return GrammarPattern(
      id: json['id'],
      name: json['name'],
      chineseTitle: json['chineseTitle'],
      englishTitle: json['englishTitle'],
      description: json['description'],
      structure: json['structure'],
      examples: (json['examples'] as List)
          .map((example) => GrammarExample.fromJson(example))
          .toList(),
      category: json['category'],
      difficultyLevel: json['difficultyLevel'],
      colorCoding: Map<String, String>.from(json['colorCoding']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chineseTitle': chineseTitle,
      'englishTitle': englishTitle,
      'description': description,
      'structure': structure,
      'examples': examples.map((example) => example.toJson()).toList(),
      'category': category,
      'difficultyLevel': difficultyLevel,
      'colorCoding': colorCoding,
    };
  }
}

class GrammarExample {
  final String id;
  final String chineseSentence;
  final String pinyinSentence;
  final String englishTranslation;
  final List<SentencePart> breakdownParts;
  final String? audioUrl;
  final String? note;

  GrammarExample({
    required this.id,
    required this.chineseSentence,
    required this.pinyinSentence,
    required this.englishTranslation,
    required this.breakdownParts,
    this.audioUrl,
    this.note,
  });

  factory GrammarExample.fromJson(Map<String, dynamic> json) {
    return GrammarExample(
      id: json['id'],
      chineseSentence: json['chineseSentence'],
      pinyinSentence: json['pinyinSentence'],
      englishTranslation: json['englishTranslation'],
      breakdownParts: (json['breakdownParts'] as List)
          .map((part) => SentencePart.fromJson(part))
          .toList(),
      audioUrl: json['audioUrl'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chineseSentence': chineseSentence,
      'pinyinSentence': pinyinSentence,
      'englishTranslation': englishTranslation,
      'breakdownParts': breakdownParts.map((part) => part.toJson()).toList(),
      'audioUrl': audioUrl,
      'note': note,
    };
  }
}

class SentencePart {
  final String text;
  final String pinyin;
  final String partOfSpeech;
  final String? meaning;
  final String? grammarFunction;

  SentencePart({
    required this.text,
    required this.pinyin,
    required this.partOfSpeech,
    this.meaning,
    this.grammarFunction,
  });

  factory SentencePart.fromJson(Map<String, dynamic> json) {
    return SentencePart(
      text: json['text'],
      pinyin: json['pinyin'],
      partOfSpeech: json['partOfSpeech'],
      meaning: json['meaning'],
      grammarFunction: json['grammarFunction'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'pinyin': pinyin,
      'partOfSpeech': partOfSpeech,
      'meaning': meaning,
      'grammarFunction': grammarFunction,
    };
  }
}