import 'package:flutter/material.dart';

class AppTheme {
  // Purple palette
  static const Color primary = Color(0xFF7C3AED);       // Violet-600
  static const Color primaryLight = Color(0xFFA78BFA);  // Violet-400
  static const Color primaryDark = Color(0xFF5B21B6);   // Violet-800
  static const Color surface = Color(0xFF0D0D14);       // Near-black
  static const Color surfaceContainer = Color(0xFF16161F);
  static const Color surfaceVariant = Color(0xFF1E1E2E);
  static const Color onSurface = Color(0xFFF1F0FF);
  static const Color onSurfaceMuted = Color(0xFF8B8BA8);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: primaryLight,
      surface: surface,
      error: error,
    ).copyWith(
      surfaceContainerHighest: surfaceVariant,
      surfaceContainer: surfaceContainer,
      onSurface: onSurface,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Roboto',

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),

      // Navigation bar (bottom)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainer,
        indicatorColor: primary.withOpacity(0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight, size: 24);
          }
          return const IconThemeData(color: onSurfaceMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: onSurfaceMuted,
            fontSize: 12,
          );
        }),
        elevation: 0,
        height: 70,
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: onSurfaceMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // List tile
      listTileTheme: const ListTileThemeData(
        textColor: onSurface,
        iconColor: onSurfaceMuted,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A3E),
        thickness: 0.5,
        space: 0,
      ),

      // Icon button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurface,
        ),
      ),
    );
  }
}
