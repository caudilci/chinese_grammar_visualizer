import 'dart:convert';
import 'dictionary_entry.dart';

class WordList {
  String id;
  String name;
  List<DictionaryEntry> entries;
  DateTime createdAt;
  DateTime updatedAt;

  WordList({
    required this.id,
    required this.name,
    List<DictionaryEntry>? entries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    entries = entries ?? [],
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Create a default "Uncategorized" word list
  factory WordList.uncategorized() {
    return WordList(
      id: 'uncategorized',
      name: 'Uncategorized',
    );
  }

  // Add an entry to the word list
  void addEntry(DictionaryEntry entry) {
    // Only add if not already present
    if (!entries.contains(entry)) {
      entries.add(entry);
      updatedAt = DateTime.now();
    }
  }

  // Remove an entry from the word list
  void removeEntry(DictionaryEntry entry) {
    entries.removeWhere((e) => e == entry);
    updatedAt = DateTime.now();
  }

  // Check if the word list contains a specific entry
  bool containsEntry(DictionaryEntry entry) {
    return entries.contains(entry);
  }

  // Factory constructor to create a WordList from JSON
  factory WordList.fromJson(Map<String, dynamic> json) {
    return WordList(
      id: json['id'] as String,
      name: json['name'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => DictionaryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'entries': entries.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Serialize to string for storage
  String serialize() {
    return jsonEncode(toJson());
  }

  // Deserialize from string
  static WordList deserialize(String data) {
    return WordList.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordList &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}