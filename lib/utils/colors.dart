import 'package:flutter/material.dart';

/// Color constants for parts of speech and grammar elements
class PartOfSpeechColors {
  // Primary parts of speech
  static const Color noun = Color(0xFF5856D6);
  static const Color verb = Color(0xFF34C759);
  static const Color adverb = Color(0xFF5AC8FA);
  static const Color adjective = Color(0xFF34C759);
  static const Color conjunction = Color(0xFF9500FF);
  static const Color preposition = Color(0xFFFF3B30);
  static const Color measureWord = Color(0xFF007AFF);
  static const Color particle = Color(0xFFFF3B30);
  static const Color determiner = Color(0xFF007AFF);
  static const Color pronoun = Color(0xFFFF9500);
  static const Color postposition = Color(0xFFFF3B30);
  static const Color interjection = Color(0xFFFF9500);
  static const Color numeral = Color(0xFF007AFF);
  
  // Sentence roles
  static const Color subject = Color(0xFFFF9500);
  static const Color object = Color(0xFF5856D6);
  static const Color topic = Color(0xFFFF9500);
  static const Color predicate = Color(0xFF34C759);
  static const Color complement = Color(0xFF007AFF);
  static const Color marker = Color(0xFFFF3B30);
  static const Color time = Color(0xFF5AC8FA);
  static const Color location = Color(0xFF5856D6);
  static const Color possessive = Color(0xFFFF9500);
  
  // Additional semantic categories
  static const Color action = Color(0xFF34C759);
  static const Color result = Color(0xFF007AFF);
  static const Color aspect = Color(0xFFFF3B30);
  static const Color modal = Color(0xFF5AC8FA);
  static const Color question = Color(0xFFFF9500);
  static const Color negation = Color(0xFFFF3B30);
  static const Color comparison = Color(0xFF5AC8FA);
  static const Color direction = Color(0xFF007AFF);
  static const Color degree = Color(0xFF5AC8FA);
  static const Color quantity = Color(0xFF007AFF);
  static const Color passive = Color(0xFFFF3B30);
  static const Color emphasis = Color(0xFFFF9500);
  static const Color structure = Color(0xFF009688);
  static const Color phrase = Color(0xFF5856D6);
  static const Color destination = Color(0xFF5AC8FA);
  static const Color transportation = Color(0xFF007AFF);
  static const Color temporal = Color(0xFF5AC8FA);
  static const Color locative = Color(0xFF5856D6);
  static const Color possessor = Color(0xFFFF9500);
  static const Color classifier = Color(0xFF007AFF);
  static const Color resultative = Color(0xFF007AFF);
  static const Color directional = Color(0xFF007AFF);
  static const Color attributive = Color(0xFF34C759);
  static const Color adverbial = Color(0xFF5AC8FA);
  
  // Default fallback color
  static const Color defaultColor = Color(0xFF009688);
  
  /// Get a color for a part of speech or grammar function
  static Color getColor(String? type) {
    if (type == null || type.isEmpty) {
      return defaultColor;
    }
    
    // Convert to lowercase for case-insensitive matching
    final String lowerType = type.toLowerCase();
    
    // Map the type to a color
    switch (lowerType) {
      // Primary parts of speech
      case 'noun': return noun;
      case 'verb': return verb;
      case 'adverb': return adverb;
      case 'adjective': return adjective;
      case 'conjunction': return conjunction;
      case 'preposition': return preposition;
      case 'measure word':
      case 'measureword':
      case 'measure':
      case 'classifier': return measureWord;
      case 'particle': return particle;
      case 'determiner': return determiner;
      case 'pronoun': return pronoun;
      case 'postposition': return postposition;
      case 'interjection': return interjection;
      case 'numeral': return numeral;
      
      // Sentence roles
      case 'subject': return subject;
      case 'object': return object;
      case 'topic': return topic;
      case 'predicate': return predicate;
      case 'complement': return complement;
      case 'marker': return marker;
      case 'time': return time;
      case 'location': return location;
      case 'possessive': return possessive;
      
      // Additional semantic categories
      case 'action': return action;
      case 'result': return result;
      case 'aspect': return aspect;
      case 'modal': return modal;
      case 'question': return question;
      case 'negation': return negation;
      case 'comparison': return comparison;
      case 'direction': return direction;
      case 'degree': return degree;
      case 'quantity': return quantity;
      case 'passive': return passive;
      case 'emphasis': return emphasis;
      case 'structure': return structure;
      case 'phrase': return phrase;
      case 'destination': return destination;
      case 'transportation': return transportation;
      case 'temporal': return temporal;
      case 'locative': return locative;
      case 'possessor': return possessor;
      case 'resultative': return resultative;
      case 'directional': return directional;
      case 'attributive': return attributive;
      case 'adverbial': return adverbial;
      
      // Fallback for partial matches
      default:
        if (lowerType.contains('noun') || lowerType.contains('object')) return noun;
        if (lowerType.contains('verb') || lowerType.contains('action')) return verb;
        if (lowerType.contains('adverb') || lowerType.contains('time')) return adverb;
        if (lowerType.contains('adjective')) return adjective;
        if (lowerType.contains('marker') || lowerType.contains('particle')) return marker;
        if (lowerType.contains('complement') || lowerType.contains('result')) return complement;
        if (lowerType.contains('subject') || lowerType.contains('topic')) return subject;
        if (lowerType.contains('preposition') || lowerType.contains('location')) return preposition;
        if (lowerType.contains('measure') || lowerType.contains('classifier')) return measureWord;
        if (lowerType.contains('degree') || lowerType.contains('comparison')) return degree;
        
        // Default color if no match is found
        return defaultColor;
    }
  }
  
  /// Generate a map of color names to Color objects (for backward compatibility)
  static Map<String, Color> asMap() {
    return {
      'noun': noun,
      'verb': verb,
      'adverb': adverb,
      'adjective': adjective,
      'conjunction': conjunction,
      'preposition': preposition,
      'measureWord': measureWord,
      'particle': particle,
      'determiner': determiner,
      'pronoun': pronoun,
      'postposition': postposition,
      'interjection': interjection,
      'numeral': numeral,
      'subject': subject,
      'object': object,
      'topic': topic,
      'predicate': predicate,
      'complement': complement,
      'marker': marker,
      'time': time,
      'location': location,
      'possessive': possessive,
      'action': action,
      'result': result,
      'aspect': aspect,
      'modal': modal,
      'question': question,
      'negation': negation,
      'comparison': comparison,
      'direction': direction,
      'degree': degree,
      'quantity': quantity,
      'passive': passive,
      'emphasis': emphasis,
      'structure': structure,
      'phrase': phrase,
      'destination': destination,
      'transportation': transportation,
      'temporal': temporal,
      'locative': locative,
      'possessor': possessor,
      'classifier': classifier,
      'resultative': resultative,
      'directional': directional,
      'attributive': attributive,
      'adverbial': adverbial,
      'default': defaultColor,
    };
  }
}