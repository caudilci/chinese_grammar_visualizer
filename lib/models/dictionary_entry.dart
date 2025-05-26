class DictionaryEntry {
  final String traditional;
  final String simplified;
  final String pinyin;
  final List<String> definitions;

  DictionaryEntry({
    required this.traditional,
    required this.simplified,
    required this.pinyin,
    required this.definitions,
  });

  // Factory constructor to create a DictionaryEntry from a CC-CEDICT line
  factory DictionaryEntry.fromCEDICTLine(String line) {
    // Skip comments and empty lines
    if (line.trim().isEmpty || line.startsWith('#')) {
      return DictionaryEntry(
        traditional: '',
        simplified: '',
        pinyin: '',
        definitions: [],
      );
    }

    try {
      // The CEDICT format is:
      // Traditional Simplified [pinyin] /definition 1/definition 2/.../
      
      // Find the index positions of key delimiters
      final int pinyinStart = line.indexOf('[');
      final int pinyinEnd = line.indexOf(']');
      final int definitionsStart = line.indexOf('/', pinyinEnd);
      
      // If any delimiter is missing, the format is invalid
      if (pinyinStart == -1 || pinyinEnd == -1 || definitionsStart == -1) {
        throw FormatException('Invalid CEDICT format: missing delimiters');
      }
      
      // Extract the components based on delimiter positions
      final String charactersPart = line.substring(0, pinyinStart).trim();
      final List<String> characters = charactersPart.split(' ');
      
      if (characters.length < 2) {
        throw FormatException('Invalid CEDICT format: missing traditional or simplified');
      }
      
      final String traditional = characters[0];
      final String simplified = characters[characters.length - 1];
      final String pinyin = line.substring(pinyinStart + 1, pinyinEnd);
      
      // Extract the definitions part (everything between first '/' and the end)
      final String definitionsString = line.substring(definitionsStart + 1);
      
      // Split by '/' to get individual definitions, ignoring empty entries
      final List<String> definitions = [];
      for (String def in definitionsString.split('/')) {
        if (def.isNotEmpty) {
          definitions.add(def);
        }
      }

      return DictionaryEntry(
        traditional: traditional,
        simplified: simplified,
        pinyin: pinyin,
        definitions: definitions,
      );
    } catch (e) {
      print('Error parsing dictionary line: $e');
      print('Line: $line');
    }

    // Return empty entry if parsing fails
    return DictionaryEntry(
      traditional: '',
      simplified: '',
      pinyin: '',
      definitions: [],
    );
  }

  // Check if this entry is valid (has non-empty fields)
  bool get isValid => 
      traditional.isNotEmpty && 
      simplified.isNotEmpty && 
      pinyin.isNotEmpty && 
      definitions.isNotEmpty;

  // Check if this entry contains the specified search term in any field
  bool containsSearchTerm(String term, {bool ignoreCase = true}) {
    final searchTerm = ignoreCase ? term.toLowerCase() : term;
    
    return (ignoreCase ? simplified.toLowerCase() : simplified).contains(searchTerm) ||
           (ignoreCase ? traditional.toLowerCase() : traditional).contains(searchTerm) ||
           (ignoreCase ? pinyin.toLowerCase() : pinyin).contains(searchTerm) ||
           definitions.any((def) => 
             (ignoreCase ? def.toLowerCase() : def).contains(searchTerm)
           );
  }

  @override
  String toString() {
    return '$simplified [$pinyin] - ${definitions.join('; ')}';
  }
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is DictionaryEntry &&
    runtimeType == other.runtimeType &&
    simplified == other.simplified &&
    traditional == other.traditional &&
    pinyin == other.pinyin;

  @override
  int get hashCode => 
    simplified.hashCode ^ 
    traditional.hashCode ^ 
    pinyin.hashCode;
}