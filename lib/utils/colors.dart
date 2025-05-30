import 'package:flutter/material.dart';
import '../utils/catppuccin_theme.dart';

/// Color constants for parts of speech and grammar elements
class PartOfSpeechColors {
  // Static properties to cache theme mode for when BuildContext isn't available
  static bool _isDarkMode = false;
  static set isDarkMode(bool value) {
    _isDarkMode = value;
  }
  
  // Get colors based on current theme brightness
  static Color getThemeColor(BuildContext? context, Color lightColor, Color darkColor) {
    if (context == null) {
      // When context is not available, use the cached dark mode value
      return _isDarkMode ? darkColor : lightColor;
    }
    
    // When context is available, use the theme brightness
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Update cached value for future use
    _isDarkMode = isDark;
    return isDark ? darkColor : lightColor;
  }
  
  // Primary parts of speech - using Catppuccin colors
  // Latte colors for light mode, Mocha colors for dark mode
  static Color getNoun(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteBlue, CatppuccinTheme.mochaBlue);
  static Color getVerb(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteGreen, CatppuccinTheme.mochaGreen);
  static Color getAdverb(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteSky, CatppuccinTheme.mochaSky);
  static Color getAdjective(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteGreen, CatppuccinTheme.mochaGreen);
  static Color getConjunction(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteMauve, CatppuccinTheme.mochaMauve);
  static Color getPreposition(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteRed, CatppuccinTheme.mochaRed);
  static Color getMeasureWord(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteSky, CatppuccinTheme.mochaSky);
  static Color getParticle(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteMaroon, CatppuccinTheme.mochaMaroon);
  static Color getDeterminer(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteTeal, CatppuccinTheme.mochaTeal);
  static Color getPronoun(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.lattePeach, CatppuccinTheme.mochaPeach);
  static Color getPostposition(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteMaroon, CatppuccinTheme.mochaMaroon);
  static Color getInterjection(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.lattePeach, CatppuccinTheme.mochaPeach);
  static Color getNumeral(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteBlue, CatppuccinTheme.mochaBlue);
  
  // Sentence roles
  static Color getSubject(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.lattePeach, CatppuccinTheme.mochaPeach);
  static Color getObject(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteBlue, CatppuccinTheme.mochaBlue);
  static Color getTopic(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.lattePeach, CatppuccinTheme.mochaPeach);
  static Color getPredicate(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteGreen, CatppuccinTheme.mochaGreen);
  static Color getComplement(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteTeal, CatppuccinTheme.mochaTeal);
  static Color getMarker(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteMaroon, CatppuccinTheme.mochaMaroon);
  static Color getTime(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteSky, CatppuccinTheme.mochaSky);
  static Color getLocation(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteBlue, CatppuccinTheme.mochaBlue);
  static Color getPossessive(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.lattePeach, CatppuccinTheme.mochaPeach);
  
  // Additional semantic categories
  static Color getAction(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteGreen, CatppuccinTheme.mochaGreen);
  static Color getResult(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteTeal, CatppuccinTheme.mochaTeal);
  static Color getAspect(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteMaroon, CatppuccinTheme.mochaMaroon);
  static Color getModal(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteSky, CatppuccinTheme.mochaSky);
  static Color getQuestion(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.lattePeach, CatppuccinTheme.mochaPeach);
  static Color getNegation(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteMaroon, CatppuccinTheme.mochaMaroon);
  static Color getComparison(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteSky, CatppuccinTheme.mochaSky);
  static Color getDirection(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteTeal, CatppuccinTheme.mochaTeal);
  static Color getDegree(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteSky, CatppuccinTheme.mochaSky);
  static Color getQuantity(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteTeal, CatppuccinTheme.mochaTeal);
  static Color getPassive(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteMaroon, CatppuccinTheme.mochaMaroon);
  static Color getEmphasis(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.lattePeach, CatppuccinTheme.mochaPeach);
  static Color getStructure(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteLavender, CatppuccinTheme.mochaLavender);
  static Color getPhrase(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteBlue, CatppuccinTheme.mochaBlue);
  static Color getDestination(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteSky, CatppuccinTheme.mochaSky);
  static Color getTransportation(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteTeal, CatppuccinTheme.mochaTeal);
  static Color getTemporal(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteSky, CatppuccinTheme.mochaSky);
  static Color getLocative(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteBlue, CatppuccinTheme.mochaBlue);
  static Color getPossessor(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.lattePeach, CatppuccinTheme.mochaPeach);
  static Color getClassifier(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteTeal, CatppuccinTheme.mochaTeal);
  static Color getResultative(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteTeal, CatppuccinTheme.mochaTeal);
  static Color getDirectional(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteTeal, CatppuccinTheme.mochaTeal);
  static Color getAttributive(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteGreen, CatppuccinTheme.mochaGreen);
  static Color getAdverbial(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteSky, CatppuccinTheme.mochaSky);
  
  // Default fallback color
  static Color getDefaultColor(BuildContext? context) => 
      getThemeColor(context, CatppuccinTheme.latteLavender, CatppuccinTheme.mochaLavender);
      
  // Legacy static colors for backward compatibility
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
  static Color getColor(String? type, [BuildContext? context]) {
    if (type == null || type.isEmpty) {
      return context != null ? getDefaultColor(context) : defaultColor;
    }
    
    // Convert to lowercase for case-insensitive matching
    final String lowerType = type.toLowerCase();
    
    // Map the type to a color
    switch (lowerType) {
      // Primary parts of speech
      case 'noun': return context != null ? getNoun(context) : noun;
      case 'verb': return context != null ? getVerb(context) : verb;
      case 'adverb': return context != null ? getAdverb(context) : adverb;
      case 'adjective': return context != null ? getAdjective(context) : adjective;
      case 'conjunction': return context != null ? getConjunction(context) : conjunction;
      case 'preposition': return context != null ? getPreposition(context) : preposition;
      case 'measure word':
      case 'measureword':
      case 'measure':
      case 'classifier': return context != null ? getMeasureWord(context) : measureWord;
      case 'particle': return context != null ? getParticle(context) : particle;
      case 'determiner': return context != null ? getDeterminer(context) : determiner;
      case 'pronoun': return context != null ? getPronoun(context) : pronoun;
      case 'postposition': return context != null ? getPostposition(context) : postposition;
      case 'interjection': return context != null ? getInterjection(context) : interjection;
      case 'numeral': return context != null ? getNumeral(context) : numeral;
      
      // Sentence roles
      case 'subject': return context != null ? getSubject(context) : subject;
      case 'object': return context != null ? getObject(context) : object;
      case 'topic': return context != null ? getTopic(context) : topic;
      case 'predicate': return context != null ? getPredicate(context) : predicate;
      case 'complement': return context != null ? getComplement(context) : complement;
      case 'marker': return context != null ? getMarker(context) : marker;
      case 'time': return context != null ? getTime(context) : time;
      case 'location': return context != null ? getLocation(context) : location;
      case 'possessive': return context != null ? getPossessive(context) : possessive;
      
      // Additional semantic categories
      case 'action': return context != null ? getAction(context) : action;
      case 'result': return context != null ? getResult(context) : result;
      case 'aspect': return context != null ? getAspect(context) : aspect;
      case 'modal': return context != null ? getModal(context) : modal;
      case 'question': return context != null ? getQuestion(context) : question;
      case 'negation': return context != null ? getNegation(context) : negation;
      case 'comparison': return context != null ? getComparison(context) : comparison;
      case 'direction': return context != null ? getDirection(context) : direction;
      case 'degree': return context != null ? getDegree(context) : degree;
      case 'quantity': return context != null ? getQuantity(context) : quantity;
      case 'passive': return context != null ? getPassive(context) : passive;
      case 'emphasis': return context != null ? getEmphasis(context) : emphasis;
      case 'structure': return context != null ? getStructure(context) : structure;
      case 'phrase': return context != null ? getPhrase(context) : phrase;
      case 'destination': return context != null ? getDestination(context) : destination;
      case 'transportation': return context != null ? getTransportation(context) : transportation;
      case 'temporal': return context != null ? getTemporal(context) : temporal;
      case 'locative': return context != null ? getLocative(context) : locative;
      case 'possessor': return context != null ? getPossessor(context) : possessor;
      case 'resultative': return context != null ? getResultative(context) : resultative;
      case 'directional': return context != null ? getDirectional(context) : directional;
      case 'attributive': return context != null ? getAttributive(context) : attributive;
      case 'adverbial': return context != null ? getAdverbial(context) : adverbial;
      
      // Fallback for partial matches
      default:
        if (lowerType.contains('noun') || lowerType.contains('object')) 
          return context != null ? getNoun(context) : noun;
        if (lowerType.contains('verb') || lowerType.contains('action')) 
          return context != null ? getVerb(context) : verb;
        if (lowerType.contains('adverb') || lowerType.contains('time')) 
          return context != null ? getAdverb(context) : adverb;
        if (lowerType.contains('adjective')) 
          return context != null ? getAdjective(context) : adjective;
        if (lowerType.contains('marker') || lowerType.contains('particle')) 
          return context != null ? getMarker(context) : marker;
        if (lowerType.contains('complement') || lowerType.contains('result')) 
          return context != null ? getComplement(context) : complement;
        if (lowerType.contains('subject') || lowerType.contains('topic')) 
          return context != null ? getSubject(context) : subject;
        if (lowerType.contains('preposition') || lowerType.contains('location')) 
          return context != null ? getPreposition(context) : preposition;
        if (lowerType.contains('measure') || lowerType.contains('classifier')) 
          return context != null ? getMeasureWord(context) : measureWord;
        if (lowerType.contains('degree') || lowerType.contains('comparison')) 
          return context != null ? getDegree(context) : degree;
        
        // Default color if no match is found
        return context != null ? getDefaultColor(context) : defaultColor;
    }
  }
  
  /// Generate a map of color names to Color objects
  /// If context is provided, uses theme-aware colors, otherwise falls back to cached mode or static colors
  static Map<String, Color> asMap([BuildContext? context]) {
    if (context == null && !_isDarkMode) {
      // Fallback to static colors for backward compatibility (light mode)
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
    } else if (context == null && _isDarkMode) {
      // Dark mode fallback without context
      return {
        'noun': CatppuccinTheme.mochaBlue,
        'verb': CatppuccinTheme.mochaGreen,
        'adverb': CatppuccinTheme.mochaSky,
        'adjective': CatppuccinTheme.mochaGreen,
        'conjunction': CatppuccinTheme.mochaMauve,
        'preposition': CatppuccinTheme.mochaRed,
        'measureWord': CatppuccinTheme.mochaSky,
        'particle': CatppuccinTheme.mochaMaroon,
        'determiner': CatppuccinTheme.mochaTeal,
        'pronoun': CatppuccinTheme.mochaPeach,
        'postposition': CatppuccinTheme.mochaMaroon,
        'interjection': CatppuccinTheme.mochaPeach,
        'numeral': CatppuccinTheme.mochaBlue,
        'subject': CatppuccinTheme.mochaPeach,
        'object': CatppuccinTheme.mochaBlue,
        'topic': CatppuccinTheme.mochaPeach,
        'predicate': CatppuccinTheme.mochaGreen,
        'complement': CatppuccinTheme.mochaTeal,
        'marker': CatppuccinTheme.mochaMaroon,
        'time': CatppuccinTheme.mochaSky,
        'location': CatppuccinTheme.mochaBlue,
        'possessive': CatppuccinTheme.mochaPeach,
        'action': CatppuccinTheme.mochaGreen,
        'result': CatppuccinTheme.mochaTeal,
        'aspect': CatppuccinTheme.mochaMaroon,
        'modal': CatppuccinTheme.mochaSky,
        'question': CatppuccinTheme.mochaPeach,
        'negation': CatppuccinTheme.mochaMaroon,
        'comparison': CatppuccinTheme.mochaSky,
        'direction': CatppuccinTheme.mochaTeal,
        'degree': CatppuccinTheme.mochaSky,
        'quantity': CatppuccinTheme.mochaTeal,
        'passive': CatppuccinTheme.mochaMaroon,
        'emphasis': CatppuccinTheme.mochaPeach,
        'structure': CatppuccinTheme.mochaLavender,
        'phrase': CatppuccinTheme.mochaBlue,
        'destination': CatppuccinTheme.mochaSky,
        'transportation': CatppuccinTheme.mochaTeal,
        'temporal': CatppuccinTheme.mochaSky,
        'locative': CatppuccinTheme.mochaBlue,
        'possessor': CatppuccinTheme.mochaPeach,
        'classifier': CatppuccinTheme.mochaTeal,
        'resultative': CatppuccinTheme.mochaTeal,
        'directional': CatppuccinTheme.mochaTeal,
        'attributive': CatppuccinTheme.mochaGreen,
        'adverbial': CatppuccinTheme.mochaSky,
        'default': CatppuccinTheme.mochaLavender,
      };
    }
    
    // Use theme-aware colors when context is available
    return {
      'noun': getNoun(context),
      'verb': getVerb(context),
      'adverb': getAdverb(context),
      'adjective': getAdjective(context),
      'conjunction': getConjunction(context),
      'preposition': getPreposition(context),
      'measureWord': getMeasureWord(context),
      'particle': getParticle(context),
      'determiner': getDeterminer(context),
      'pronoun': getPronoun(context),
      'postposition': getPostposition(context),
      'interjection': getInterjection(context),
      'numeral': getNumeral(context),
      'subject': getSubject(context),
      'object': getObject(context),
      'topic': getTopic(context),
      'predicate': getPredicate(context),
      'complement': getComplement(context),
      'marker': getMarker(context),
      'time': getTime(context),
      'location': getLocation(context),
      'possessive': getPossessive(context),
      'action': getAction(context),
      'result': getResult(context),
      'aspect': getAspect(context),
      'modal': getModal(context),
      'question': getQuestion(context),
      'negation': getNegation(context),
      'comparison': getComparison(context),
      'direction': getDirection(context),
      'degree': getDegree(context),
      'quantity': getQuantity(context),
      'passive': getPassive(context),
      'emphasis': getEmphasis(context),
      'structure': getStructure(context),
      'phrase': getPhrase(context),
      'destination': getDestination(context),
      'transportation': getTransportation(context),
      'temporal': getTemporal(context),
      'locative': getLocative(context),
      'possessor': getPossessor(context),
      'classifier': getClassifier(context),
      'resultative': getResultative(context),
      'directional': getDirectional(context),
      'attributive': getAttributive(context),
      'adverbial': getAdverbial(context),
      'default': getDefaultColor(context),
    };
  }
}