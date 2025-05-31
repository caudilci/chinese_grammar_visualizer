import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  // Font size definitions
  // These standardized sizes should be used throughout the app
  static const double fontSizeXXLarge =
      32.0; // Largest headers, main Chinese characters
  static const double fontSizeXLarge = 28.0; // Very large headers
  static const double fontSizeLarge = 24.0; // Large headers, Chinese characters
  static const double fontSizeMediumLarge =
      20.0; // Medium-large text, section headers
  static const double fontSizeMedium = 18.0; // Medium text, list items headers
  static const double fontSizeDefault = 16.0; // Default body text size
  static const double fontSizeSmall = 14.0; // Small text, secondary information
  static const double fontSizeXSmall = 12.0; // Very small text, captions, hints
  static const double fontSizeXXSmall = 10.0; // Smallest text, used sparingly
  // Primary color palette
  static const Color primaryColor = Color(0xFF4A6572);
  static const Color accentColor = Color(0xFFFF5252);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);

  // Chinese character colors
  static const Color chineseCharColor = Color(0xFF000000);
  static const Color pinyinColor = Color(0xFF4A6572);
  static const Color translationColor = Color(0xFF757575);

  // Grammar component colors (now using PartOfSpeechColors)
  // These are kept for backward compatibility
  static final Map<String, Color> grammarColors = {
    'subject': PartOfSpeechColors.subject,
    'object': PartOfSpeechColors.object,
    'verb': PartOfSpeechColors.verb,
    'marker': PartOfSpeechColors.marker,
    'adverb': PartOfSpeechColors.adverb,
    'adjective': PartOfSpeechColors.adjective,
    'noun': PartOfSpeechColors.noun,
    'preposition': PartOfSpeechColors.preposition,
    'particle': PartOfSpeechColors.particle,
    'complement': PartOfSpeechColors.complement,
  };

  // Error and success colors
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);

  // Difficulty level colors
  static const List<Color> difficultyColors = [
    Color(0xFF4CAF50), // Level 1 - Easy (Green)
    Color(0xFF8BC34A), // Level 2 - Easy-Medium (Light Green)
    Color(0xFFFFC107), // Level 3 - Medium (Amber)
    Color(0xFFFF9800), // Level 4 - Medium-Hard (Orange)
    Color(0xFFF44336), // Level 5 - Hard (Red)
  ];

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    textTheme: GoogleFonts.notoSansTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: textPrimary),
        displayMedium: TextStyle(color: textPrimary),
        displaySmall: TextStyle(color: textPrimary),
        headlineLarge: TextStyle(color: textPrimary),
        headlineMedium: TextStyle(color: textPrimary),
        headlineSmall: TextStyle(color: textPrimary),
        titleLarge: TextStyle(color: textPrimary),
        titleMedium: TextStyle(color: textPrimary),
        titleSmall: TextStyle(color: textSecondary),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: textPrimary),
        labelMedium: TextStyle(color: textSecondary),
        labelSmall: TextStyle(color: textLight),
      ),
    ),
    appBarTheme: AppBarTheme(
      color: primaryColor,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: appBarTitleStyle(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: textLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: textLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: textLight,
    ),
  );

  // Chinese text styles
  static TextStyle chineseTextStyle = GoogleFonts.notoSansSc(
    fontSize: fontSizeLarge,
    fontWeight: FontWeight.w500,
    color: chineseCharColor,
    height: 1.5,
  );

  static TextStyle pinyinTextStyle = GoogleFonts.notoSans(
    fontSize: fontSizeDefault,
    fontWeight: FontWeight.normal,
    color: pinyinColor,
    height: 1.2,
  );

  static TextStyle translationTextStyle = GoogleFonts.notoSans(
    fontSize: fontSizeDefault,
    fontWeight: FontWeight.normal,
    color: translationColor,
    fontStyle: FontStyle.italic,
    height: 1.2,
  );

  // Get color for a specific term (part of speech or grammar function)
  // Get color for a specific part of speech
  static Future<Color> getPartOfSpeechColor(String partOfSpeech) async {
    return PartOfSpeechColors.getColor(partOfSpeech);
  }

  // Synchronous version for backwards compatibility
  static Color getPartOfSpeechColorSync(String partOfSpeech) {
    return PartOfSpeechColors.getColor(partOfSpeech);
  }

  // Get color for a specific grammar function (now just an alias to getPartOfSpeechColor)
  static Future<Color> getGrammarFunctionColor(String grammarFunction) async {
    return PartOfSpeechColors.getColor(grammarFunction);
  }

  // Get a color for a difficulty level (1-5)
  static Color getDifficultyColor(int level) {
    if (level < 1) return difficultyColors[0];
    if (level > 5) return difficultyColors[4];
    return difficultyColors[level - 1];
  }

  // Text style helpers based on standardized font sizes

  // App bar title style
  static TextStyle appBarTitleStyle({
    Color? color,
    FontWeight weight = FontWeight.bold,
  }) {
    return TextStyle(
      fontSize: fontSizeMediumLarge,
      fontWeight: weight,
      color: color ?? Colors.white,
    );
  }

  // Heading styles
  static TextStyle headingXXLarge(
    BuildContext context, {
    Color? color,
    FontWeight weight = FontWeight.bold,
  }) {
    return TextStyle(
      fontSize: fontSizeXXLarge,
      fontWeight: weight,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle headingXLarge(
    BuildContext context, {
    Color? color,
    FontWeight weight = FontWeight.bold,
  }) {
    return TextStyle(
      fontSize: fontSizeXLarge,
      fontWeight: weight,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle headingLarge(
    BuildContext context, {
    Color? color,
    FontWeight weight = FontWeight.bold,
  }) {
    return TextStyle(
      fontSize: fontSizeLarge,
      fontWeight: weight,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle headingMedium(
    BuildContext context, {
    Color? color,
    FontWeight weight = FontWeight.bold,
  }) {
    return TextStyle(
      fontSize: fontSizeMediumLarge,
      fontWeight: weight,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  // Body text styles
  static TextStyle bodyLarge(
    BuildContext context, {
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: fontSizeMedium,
      fontWeight: weight,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle bodyDefault(
    BuildContext context, {
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: fontSizeDefault,
      fontWeight: weight,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle bodySmall(
    BuildContext context, {
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: fontSizeSmall,
      fontWeight: weight,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  // Caption and label styles
  static TextStyle caption(
    BuildContext context, {
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: fontSizeXSmall,
      fontWeight: weight,
      color:
          color ??
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
    );
  }

  static TextStyle labelSmall(
    BuildContext context, {
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: fontSizeXXSmall,
      fontWeight: weight,
      color:
          color ??
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
    );
  }
}
