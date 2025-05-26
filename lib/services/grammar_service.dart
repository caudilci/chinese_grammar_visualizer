import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/grammar_pattern.dart';

class GrammarService {
  Future<List<GrammarPattern>> loadGrammarPatterns() async {
    try {
      // Load the JSON string from the assets
      final String jsonString = await rootBundle.loadString('assets/data/grammar_patterns.json');
      
      // Decode the JSON string
      final List<dynamic> jsonList = json.decode(jsonString);
      
      // Convert each JSON object to a GrammarPattern object
      final List<GrammarPattern> grammarPatterns = jsonList
          .map((jsonItem) => GrammarPattern.fromJson(jsonItem))
          .toList();
      
      return grammarPatterns;
    } catch (e) {
      print('Error loading grammar patterns: $e');
      return [];
    }
  }

  Future<GrammarPattern?> getPatternById(String id) async {
    final patterns = await loadGrammarPatterns();
    try {
      return patterns.firstWhere((pattern) => pattern.id == id);
    } catch (e) {
      print('Pattern with ID $id not found: $e');
      return null;
    }
  }

  Future<List<GrammarPattern>> getPatternsByCategory(String category) async {
    final patterns = await loadGrammarPatterns();
    return patterns.where((pattern) => pattern.category == category).toList();
  }

  Future<List<GrammarPattern>> getPatternsByDifficulty(int level) async {
    final patterns = await loadGrammarPatterns();
    return patterns.where((pattern) => pattern.difficultyLevel == level).toList();
  }

  // Get a list of all unique categories
  Future<List<String>> getAllCategories() async {
    final patterns = await loadGrammarPatterns();
    final categories = patterns.map((pattern) => pattern.category).toSet().toList();
    return categories;
  }
  
  // Get the max difficulty level
  Future<int> getMaxDifficultyLevel() async {
    final patterns = await loadGrammarPatterns();
    if (patterns.isEmpty) return 0;
    
    return patterns
        .map((pattern) => pattern.difficultyLevel)
        .reduce((max, level) => level > max ? level : max);
  }
}