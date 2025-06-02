

class GrammarPattern {
  final String id;
  final String name;
  final String chineseTitle;
  final String? traditionalChineseTitle; // Traditional variant of the Chinese title
  final String englishTitle;
  final String description;
  final String structure;
  final String? traditionalStructure; // Traditional variant of the structure
  final List<StructurePart>? structureBreakdown;
  final List<GrammarExample> examples;
  final String category;
  final int difficultyLevel; // 1-5 where 5 is most difficult
  final Map<String, String>? colorCoding; // Maps part of speech to color code (legacy - will be removed)

  GrammarPattern({
    required this.id,
    required this.name,
    required this.chineseTitle,
    this.traditionalChineseTitle,
    required this.englishTitle,
    required this.description,
    required this.structure,
    this.traditionalStructure,
    this.structureBreakdown,
    required this.examples,
    required this.category,
    required this.difficultyLevel,
    this.colorCoding,
  });

  factory GrammarPattern.fromJson(Map<String, dynamic> json) {
    return GrammarPattern(
      id: json['id'],
      name: json['name'],
      chineseTitle: json['chineseTitle'],
      traditionalChineseTitle: json['traditionalChineseTitle'],
      englishTitle: json['englishTitle'],
      description: json['description'],
      structure: json['structure'],
      traditionalStructure: json['traditionalStructure'],
      structureBreakdown: json['structureBreakdown'] != null
          ? (json['structureBreakdown'] as List)
              .map((part) => StructurePart.fromJson(part))
              .toList()
          : null,
      examples: (json['examples'] as List)
          .map((example) => GrammarExample.fromJson(example))
          .toList(),
      category: json['category'],
      difficultyLevel: json['difficultyLevel'],
      colorCoding: json['colorCoding'] != null 
          ? Map<String, String>.from(json['colorCoding']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'chineseTitle': chineseTitle,
      'englishTitle': englishTitle,
      'description': description,
      'structure': structure,
      'examples': examples.map((example) => example.toJson()).toList(),
      'category': category,
      'difficultyLevel': difficultyLevel,
    };
    
    // Add traditional variants if they exist
    if (traditionalChineseTitle != null) {
      data['traditionalChineseTitle'] = traditionalChineseTitle;
    }
    
    if (traditionalStructure != null) {
      data['traditionalStructure'] = traditionalStructure;
    }
    
    // Include structureBreakdown if it exists
    if (structureBreakdown != null) {
      data['structureBreakdown'] = structureBreakdown!.map((part) => part.toJson()).toList();
    }
    
    // Only include colorCoding if it exists
    if (colorCoding != null) {
      data['colorCoding'] = colorCoding;
    }
    
    return data;
  }
}

class StructurePart {
  final String text;
  final String? traditionalText; // Traditional variant of the text
  final String partOfSpeech;
  final String? description;

  StructurePart({
    required this.text,
    this.traditionalText,
    required this.partOfSpeech,
    this.description,
  });

  factory StructurePart.fromJson(Map<String, dynamic> json) {
    return StructurePart(
      text: json['text'],
      traditionalText: json['traditionalText'],
      partOfSpeech: json['partOfSpeech'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'text': text,
      'partOfSpeech': partOfSpeech,
    };
  
    if (traditionalText != null) {
      data['traditionalText'] = traditionalText;
    }
    
    if (description != null) {
      data['description'] = description;
    }
  
    return data;
  }
}

class GrammarExample {
  final String id;
  final String chineseSentence;
  final String? traditionalChineseSentence; // Traditional variant of the Chinese sentence
  final String pinyinSentence;
  final String englishTranslation;
  final List<SentencePart> breakdownParts;
  final String? audioUrl;
  final String? note;

  GrammarExample({
    required this.id,
    required this.chineseSentence,
    this.traditionalChineseSentence,
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
      traditionalChineseSentence: json['traditionalChineseSentence'],
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
    final Map<String, dynamic> data = {
      'id': id,
      'chineseSentence': chineseSentence,
      'pinyinSentence': pinyinSentence,
      'englishTranslation': englishTranslation,
      'breakdownParts': breakdownParts.map((part) => part.toJson()).toList(),
      'audioUrl': audioUrl,
      'note': note,
    };
    
    if (traditionalChineseSentence != null) {
      data['traditionalChineseSentence'] = traditionalChineseSentence;
    }
    
    return data;
  }
}

class SentencePart {
  final String text;
  final String? traditionalText; // Traditional variant of the text
  final String pinyin;
  final String partOfSpeech;
  final String? meaning;
  final String? grammarFunction;

  SentencePart({
    required this.text,
    this.traditionalText,
    required this.pinyin,
    required this.partOfSpeech,
    this.meaning,
    this.grammarFunction,
  });

  factory SentencePart.fromJson(Map<String, dynamic> json) {
    return SentencePart(
      text: json['text'],
      traditionalText: json['traditionalText'],
      pinyin: json['pinyin'],
      partOfSpeech: json['partOfSpeech'],
      meaning: json['meaning'],
      grammarFunction: json['grammarFunction'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'text': text,
      'pinyin': pinyin,
      'partOfSpeech': partOfSpeech,
      'meaning': meaning,
      'grammarFunction': grammarFunction,
    };
    
    if (traditionalText != null) {
      data['traditionalText'] = traditionalText;
    }
    
    return data;
  }
}