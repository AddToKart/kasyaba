import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────
///  Kasyaba Design System — Luxury Ultra Fintech Theme
///  Style: Apple Card / Revolut Metal aesthetic with dark obsidian glass,
///  champagne gold & vibrant emerald glows, and smooth luxury curves.
/// ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Brand & Semantic Accents ──────────────────────────────
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981); // Positive inflows / savings
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald900 = Color(0xFF064E3B);

  // ── Semantic Colors (Strict 5% Semantic System) ────────────
  static const income = Color(0xFF10B981); // Emerald
  static const expense = Color(0xFFF43F5E); // Rose/Coral
  static const transfer = Color(0xFF06B6D4); // Cyan
  static const warning = Color(0xFFF59E0B); // Amber
  static const info = Color(0xFF06B6D4); // Cyan / Sky

  // ── Secondary Amber / Gold (Restricted to Warnings / Badges) 
  static const gold300 = Color(0xFFFDE68A);
  static const gold400 = Color(0xFFFBBF24);
  static const gold500 = Color(0xFFF59E0B);
  static const gold600 = Color(0xFFD97706);

  // ── Pure Zinc / Obsidian Monochrome Surfaces ──────────────
  static const obsidian = Color(0xFF09090B); // Zinc 950 Scaffold
  static const surface900 = Color(0xFF09090B);
  static const surface800 = Color(0xFF121215); // Zinc 900 Elevated Card
  static const surface700 = Color(0xFF18181B); // Zinc 800 Input Fill & Subtle Surface
  static const surface600 = Color(0xFF27272A); // Zinc 700 Borders / Dividers
  static const surface500 = Color(0xFF3F3F46); // Zinc 600 Subtle Element
  static const surfaceCard = Color(0xFF121215);

  // ── Light Surface (Monochrome Mirror) ──────────────────────
  static const lightBg = Color(0xFF09090B);
  static const lightCard = Color(0xFF121215);
  static const lightCard2 = Color(0xFF18181B);
  static const lightBorder = Color(0xFF27272A);
  static const lightBorder2 = Color(0xFF3F3F46);

  // ── Text Colors ────────────────────────────────────────────
  static const textDark = Color(0xFFFAFAFA); // Crisp White Zinc 50
  static const textLight = Color(0xFFFAFAFA);
  static const textMuted = Color(0xFFA1A1AA); // Zinc 400
  static const textMutedL = Color(0xFF71717A); // Zinc 500

  // ── Border Colors ──────────────────────────────────────────
  static const subtleBorder = Color(0xFF27272A); // Crisp 1px Zinc 700 border

  // ── Sleek Restrained Gradients ─────────────────────────────
  static const gradientHeroCard = LinearGradient(
    colors: [Color(0xFF121215), Color(0xFF18181B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientEmerald = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGold = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGlassCard = LinearGradient(
    colors: [Color(0xF018181B), Color(0xE0121215)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static const double cardRadius = 16.0;
  static const double buttonRadius = 10.0;
  static const double inputRadius = 10.0;
  static const double tagRadius = 9999.0;
  static const double alertRadius = 10.0;
  static const double navbarHeight = 76.0;

  ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.emerald500,
      onPrimary: Colors.black,
      primaryContainer: AppColors.emerald900,
      onPrimaryContainer: AppColors.emerald100,
      secondary: AppColors.textMuted,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.surface700,
      onSecondaryContainer: AppColors.textDark,
      tertiary: AppColors.info,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.surface700,
      onTertiaryContainer: Colors.white,
      error: AppColors.expense,
      onError: Colors.white,
      errorContainer: const Color(0xFF4C0519),
      onErrorContainer: const Color(0xFFFECDD3),
      surface: AppColors.surfaceCard,
      onSurface: AppColors.textDark,
      surfaceContainerHighest: AppColors.surface700,
      onSurfaceVariant: AppColors.textMuted,
      outline: AppColors.subtleBorder,
      outlineVariant: AppColors.surface600,
      inverseSurface: AppColors.textDark,
      onInverseSurface: AppColors.surface900,
      inversePrimary: AppColors.emerald700,
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: Colors.transparent,
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
          side: const BorderSide(color: AppColors.subtleBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface700,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.subtleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.subtleBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: Color(0xFF52525B), width: 1.5),
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
        hintStyle: const TextStyle(
          color: AppColors.textMutedL,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.textMuted,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          backgroundColor: AppColors.emerald500,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            letterSpacing: 0.2,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          side: const BorderSide(color: AppColors.subtleBorder, width: 1),
          foregroundColor: AppColors.textDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tagRadius),
          side: const BorderSide(color: AppColors.subtleBorder),
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
        indicatorColor: Colors.white.withValues(alpha: 0.08),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.emerald500, size: 23);
          }
          return const IconThemeData(color: AppColors.textMutedL, size: 21);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            );
          }
          return const TextStyle(
            color: AppColors.textMutedL,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          );
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.subtleBorder, width: 1),
        ),
        contentTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textDark,
        ),
        elevation: 0,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.emerald500,
        linearTrackColor: AppColors.surface700,
        linearMinHeight: 6,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.subtleBorder,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(color: AppColors.textMuted, size: 22),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: AppColors.textDark,
        ),
        subtitleTextStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12.5,
          color: AppColors.textMuted,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.transparent,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.emerald500,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
        elevation: 0,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
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
