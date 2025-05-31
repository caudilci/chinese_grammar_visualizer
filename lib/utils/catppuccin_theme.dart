import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Catppuccin theme implementation for the Chinese Grammar Visualizer app
/// Based on https://github.com/catppuccin/catppuccin
class CatppuccinTheme {
  // Prevent instantiation
  CatppuccinTheme._();

  // Flavor names
  static const String latte = 'Latte';
  static const String mocha = 'Mocha';

  // Available flavors
  static const List<String> flavors = [latte, mocha];

  // Latte (Light) palette
  static const Color latteRosewater = Color(0xFFDC8A78);
  static const Color latteRed = Color(0xFFD20F39);
  static const Color latteMaroon = Color(0xFFE64553);
  static const Color lattePeach = Color(0xFFFE640B);
  static const Color latteYellow = Color(0xFFDF8E1D);
  static const Color latteGreen = Color(0xFF40A02B);
  static const Color latteTeal = Color(0xFF179299);
  static const Color latteSky = Color(0xFF04A5E5);
  static const Color latteBlue = Color(0xFF1E66F5);
  static const Color latteLavender = Color(0xFF7287FD);
  static const Color latteMauve = Color(0xFF8839EF);
  static const Color lattePink = Color(0xFFEA76CB);
  static const Color latteText = Color(0xFF4C4F69);
  static const Color latteSubtext1 = Color(0xFF5C5F77);
  static const Color latteSubtext0 = Color(0xFF6C6F85);
  static const Color latteOverlay2 = Color(0xFF7C7F93);
  static const Color latteOverlay1 = Color(0xFF8C8FA1);
  static const Color latteOverlay0 = Color(0xFF9CA0B0);
  static const Color latteSurface2 = Color(0xFFACB0BE);
  static const Color latteSurface1 = Color(0xFFBCC0CC);
  static const Color latteSurface0 = Color(0xFFCCD0DA);
  static const Color latteBase = Color(0xFFEFF1F5);
  static const Color latteMantle = Color(0xFFE6E9EF);
  static const Color latteCrust = Color(0xFFDCE0E8);

  // Mocha (Darker) palette
  static const Color mochaRosewater = Color(0xFFF5E0DC);
  static const Color mochaRed = Color(0xFFF38BA8);
  static const Color mochaMaroon = Color(0xFFEBA0AC);
  static const Color mochaPeach = Color(0xFFFAB387);
  static const Color mochaYellow = Color(0xFFF9E2AF);
  static const Color mochaGreen = Color(0xFFA6E3A1);
  static const Color mochaTeal = Color(0xFF94E2D5);
  static const Color mochaSky = Color(0xFF89DCEB);
  static const Color mochaBlue = Color(0xFF89B4FA);
  static const Color mochaLavender = Color(0xFFB4BEFE);
  static const Color mochaMauve = Color(0xFFCBA6F7);
  static const Color mochaPink = Color(0xFFF5C2E7);
  static const Color mochaText = Color(0xFFCDD6F4);
  static const Color mochaSubtext1 = Color(0xFFBAC2DE);
  static const Color mochaSubtext0 = Color(0xFFA6ADC8);
  static const Color mochaOverlay2 = Color(0xFF9399B2);
  static const Color mochaOverlay1 = Color(0xFF7F849C);
  static const Color mochaOverlay0 = Color(0xFF6C7086);
  static const Color mochaSurface2 = Color(0xFF585B70);
  static const Color mochaSurface1 = Color(0xFF45475A);
  static const Color mochaSurface0 = Color(0xFF313244);
  static const Color mochaBase = Color(0xFF1E1E2E);
  static const Color mochaMantle = Color(0xFF181825);
  static const Color mochaCrust = Color(0xFF11111B);

  // Generate light theme using Latte palette
  static ThemeData getLightTheme() {
    return _getTheme(
      primary: latteBlue,
      secondary: latteMauve,
      error: latteRed,
      background: latteBase,
      surface: latteMantle,
      surfaceContainer: latteCrust,
      onPrimary: latteBase,
      onSecondary: latteBase,
      onError: latteBase,
      onBackground: latteText,
      onSurface: latteText,
      textColor: latteText,
      isDark: false,
    );
  }

  // Generate dark theme using Mocha palette
  static ThemeData getDarkTheme() {
    return _getTheme(
      primary: mochaBlue,
      secondary: mochaMauve,
      error: mochaRed,
      background: mochaBase,
      surface: mochaMantle,
      surfaceContainer: mochaCrust,
      onPrimary: mochaText,
      onSecondary: mochaText,
      onError: mochaText,
      onBackground: mochaText,
      onSurface: mochaText,
      textColor: mochaText,
      isDark: true,
    );
  }

  // Generate theme based on flavor
  static ThemeData getThemeByFlavor(String flavor) {
    switch (flavor) {
      case latte:
        return getLightTheme();
      case mocha:
        return getDarkTheme();
      default:
        return getLightTheme();
    }
  }

  // Base theme generator
  static ThemeData _getTheme({
    required Color primary,
    required Color secondary,
    required Color error,
    required Color background,
    required Color surface,
    required Color surfaceContainer,
    required Color onPrimary,
    required Color onSecondary,
    required Color onError,
    required Color onBackground,
    required Color onSurface,
    required Color textColor,
    required bool isDark,
  }) {
    final ColorScheme colorScheme = ColorScheme(
      primary: primary,
      primaryContainer: primary.withValues(alpha: 0.8),
      secondary: secondary,
      secondaryContainer: secondary.withValues(alpha: 0.8),
      surface: surface,
      background: background,
      error: error,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      onSurface: onSurface,
      onBackground: onBackground,
      onError: onError,
      brightness: isDark ? Brightness.dark : Brightness.light,
      surfaceContainer: surfaceContainer,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: isDark ? surfaceContainer : Colors.white,
      // Cannot use cardTheme due to compatibility issues
      textTheme: GoogleFonts.notoSansTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: textColor),
          displayMedium: TextStyle(color: textColor),
          displaySmall: TextStyle(color: textColor),
          headlineLarge: TextStyle(color: textColor),
          headlineMedium: TextStyle(color: textColor),
          headlineSmall: TextStyle(color: textColor),
          titleLarge: TextStyle(color: textColor),
          titleMedium: TextStyle(color: textColor),
          titleSmall: TextStyle(color: textColor),
          bodyLarge: TextStyle(color: textColor),
          bodyMedium: TextStyle(color: textColor),
          bodySmall: TextStyle(color: textColor),
          labelLarge: TextStyle(color: textColor),
          labelMedium: TextStyle(color: textColor),
          labelSmall: TextStyle(color: textColor),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: onPrimary),
        actionsIconTheme: IconThemeData(color: onPrimary),
      ),
      // Card theme explicitly set above
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceContainer : surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.8)),
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return isDark
              ? onSurface.withValues(alpha: 0.5)
              : onSurface.withValues(alpha: 0.4);
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primary.withValues(alpha: 0.5);
          }
          return isDark
              ? onSurface.withValues(alpha: 0.2)
              : onSurface.withValues(alpha: 0.2);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(onPrimary),
        side: BorderSide(color: textColor.withValues(alpha: 0.5), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return textColor.withValues(alpha: 0.5);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? onSurface.withValues(alpha: 0.2)
            : onSurface.withValues(alpha: 0.1),
        thickness: 1,
      ),
      // Dialog settings in Material 3
      dialogBackgroundColor: isDark ? surfaceContainer : Colors.white,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textColor: textColor,
        iconColor: primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? surfaceContainer : surface,
        contentTextStyle: TextStyle(color: textColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? surfaceContainer : Colors.white,
        textStyle: TextStyle(color: textColor),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? surfaceContainer : Colors.white,
        modalBackgroundColor: isDark ? surfaceContainer : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? surface : Colors.white,
        indicatorColor: primary.withValues(alpha: 0.2),
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(color: textColor, fontSize: 12),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? surface : Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textColor.withValues(alpha: 0.6),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? surface : Colors.white,
      ),
    );
  }
}
