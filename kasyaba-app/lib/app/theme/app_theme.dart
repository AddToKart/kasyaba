import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────
///  Kasyaba Design System — Luxury Ultra Fintech Theme
///  Style: Apple Card / Revolut Metal aesthetic with dark obsidian glass,
///  champagne gold & vibrant emerald glows, and smooth luxury curves.
/// ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Brand Colors ───────────────────────────────────────────
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981); // Emerald Glow
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald900 = Color(0xFF064E3B);

  // ── Champagne Gold Accent ──────────────────────────────────
  static const gold300 = Color(0xFFFDE68A);
  static const gold400 = Color(0xFFFBBF24);
  static const gold500 = Color(0xFFD4AF37); // Champagne Gold
  static const gold600 = Color(0xFFB45309);

  // ── Obsidian Dark Surfaces ────────────────────────────────
  static const obsidian = Color(0xFF080B11); // Deepest Obsidian
  static const surface900 = Color(0xFF0D121D);
  static const surface800 = Color(0xFF121927); // Main Card Base
  static const surface700 = Color(0xFF182234); // Inner Container
  static const surface600 = Color(0xFF202C42);
  static const surface500 = Color(0xFF2A3A56);
  static const surfaceCard = Color(0xFF121927);

  // ── Light Surface (Fallback) ──────────────────────────────
  static const lightBg = Color(0xFF080B11);
  static const lightCard = Color(0xFF121927);
  static const lightCard2 = Color(0xFF182234);
  static const lightBorder = Color(0xFF202C42);
  static const lightBorder2 = Color(0xFF2A3A56);

  // ── Status Colors ──────────────────────────────────────────
  static const income = Color(0xFF10B981);
  static const expense = Color(0xFFF87171);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF38BDF8);

  // ── Text Colors ────────────────────────────────────────────
  static const textDark = Color(0xFFF8FAFC);
  static const textMuted = Color(0xFF94A3B8);
  static const textLight = Color(0xFFF8FAFC);
  static const textMutedL = Color(0xFF64748B);

  // ── Luxury Gradients ───────────────────────────────────────
  static const gradientHeroCard = LinearGradient(
    colors: [Color(0xFF121927), Color(0xFF1A2438), Color(0xFF0D121D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientEmerald = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGold = LinearGradient(
    colors: [Color(0xFFB45309), Color(0xFFD4AF37), Color(0xFFFCD34D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGlassCard = LinearGradient(
    colors: [Color(0xCC182234), Color(0x99121927)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static const double cardRadius = 20.0;
  static const double buttonRadius = 16.0;
  static const double inputRadius = 14.0;
  static const double navbarHeight = 76.0;

  ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.emerald500,
      onPrimary: Colors.black,
      primaryContainer: AppColors.emerald900,
      onPrimaryContainer: AppColors.emerald100,
      secondary: AppColors.gold500,
      onSecondary: Colors.black,
      secondaryContainer: AppColors.surface700,
      onSecondaryContainer: AppColors.gold300,
      tertiary: AppColors.info,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.surface700,
      onTertiaryContainer: Colors.white,
      error: AppColors.expense,
      onError: Colors.white,
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFCA5A5),
      surface: AppColors.surfaceCard,
      onSurface: AppColors.textDark,
      surfaceContainerHighest: AppColors.surface700,
      onSurfaceVariant: AppColors.textMuted,
      outline: const Color(0x40334155),
      outlineVariant: const Color(0x20334155),
      inverseSurface: AppColors.textDark,
      onInverseSurface: AppColors.surface900,
      inversePrimary: AppColors.emerald700,
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: AppColors.emerald500.withValues(alpha: 0.05),
    );

    return _buildTheme(colorScheme);
  }

  ThemeData get light => dark;

  ThemeData _buildTheme(ColorScheme cs) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.obsidian,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.obsidian,
        ),
        iconTheme: IconThemeData(color: AppColors.textDark, size: 22),
        actionsIconTheme: IconThemeData(color: AppColors.textMuted, size: 22),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: Color(0x33334155), width: 1),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.4),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface700,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: Color(0x40334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: Color(0x40334155), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.gold500, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.expense, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: AppColors.textMuted.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        prefixIconColor: AppColors.gold500,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          backgroundColor: AppColors.emerald500,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          side: const BorderSide(color: Color(0x40334155), width: 1),
          foregroundColor: AppColors.textDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold500,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x33334155)),
        ),
        backgroundColor: AppColors.surface700,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: AppColors.textDark,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: navbarHeight,
        backgroundColor: AppColors.obsidian,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.emerald500.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.emerald500, size: 24);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.emerald500,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.3,
            );
          }
          return const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          );
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gold500, width: 1),
        ),
        contentTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textDark,
        ),
        elevation: 12,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.emerald500,
        linearTrackColor: Color(0xFF182234),
        linearMinHeight: 6,
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0x33334155),
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(color: AppColors.textMuted, size: 22),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppColors.textDark,
        ),
        subtitleTextStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13,
          color: AppColors.textMuted,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: Colors.transparent,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.emerald500,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 6,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: AppColors.textDark,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: AppColors.textDark,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: AppColors.textDark,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: AppColors.textDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColors.textDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: AppColors.textDark,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: AppColors.textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textDark,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: AppColors.textDark,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          color: AppColors.textMuted,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
