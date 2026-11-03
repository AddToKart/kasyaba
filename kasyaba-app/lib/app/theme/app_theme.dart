import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'kasyaba_tokens.dart';

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
  static const darkCardSurface = Color(0xFF121215);
  static const darkScaffold = Color(0xFF09090B);

  // ── Porcelain Light Mode Palette (Tactile Modern Dual-Theme) ─
  static const lightScaffold = Color(0xFFF8F9FA); // Soft Porcelain Canvas
  static const lightBg = Color(0xFFF8F9FA); // Alias for backwards-compatibility
  static const lightCardSurface = Color(0xFFFFFFFF); // Pure Crisp White Card
  static const lightInputFill = Color(0xFFEBECEF); // Soft Clay Fill
  static const lightBorderHairline = Color(0xFFE2E4E9); // Daylight 1px Soft Rim
  static const lightBorderSubtle = Color(0xFFD1D5DB); // Neutral Gray
  static const lightTextPrimary = Color(0xFF09090B); // Deep Obsidian Ink
  static const lightTextSecondary = Color(0xFF64748B); // Cool Slate Muted
  static const lightTextTertiary = Color(0xFF94A3B8); // Light Slate
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCard2 = Color(0xFFF1F2F4);
  static const lightBorder = Color(0xFFE2E4E9);
  static const lightBorder2 = Color(0xFFD1D5DB);

  // ── Text Colors ────────────────────────────────────────────
  static const textDark = Color(0xFFFAFAFA); // Crisp White Zinc 50 (Dark Mode)
  static const textLight = Color(0xFF09090B); // Deep Obsidian Zinc 950 (Light Mode)
  static const textMuted = Color(0xFFA1A1AA); // Zinc 400
  static const textMutedL = Color(0xFF71717A); // Zinc 500

  // ── Border Colors ──────────────────────────────────────────
  static const subtleBorder = Color(0x1FFFFFFF); // 12% white opacity — ultra-luxury etched glass edge, zero glaring outlines
  static const subtleBorderZinc = Color(0xFF27272A); // Zinc 700 solid fall-back

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

  // ── Adaptive Theme Color Helpers ───────────────────────────
  static Color subtleBorderAdaptive(bool isDark) =>
      isDark ? subtleBorder : lightBorderHairline;
  static Color cardBg(bool isDark) =>
      isDark ? surfaceCard : lightCardSurface;
  static Color scaffoldBg(bool isDark) =>
      isDark ? obsidian : lightScaffold;
  static Color textPrimary(bool isDark) =>
      isDark ? textDark : lightTextPrimary;
  static Color textSecondary(bool isDark) =>
      isDark ? textMuted : lightTextSecondary;
  static Color inputSurface(bool isDark) =>
      isDark ? surface700 : lightInputFill;
}

class AppTheme {
  static const double cardRadius = 28.0;
  static const double buttonRadius = 28.0;
  static const double inputRadius = 28.0;
  static const double tagRadius = 9999.0;
  static const double alertRadius = 24.0;
  static const double navbarHeight = 76.0;

  ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: KasyabaTokens.periwinkleGray,
      onPrimary: KasyabaTokens.ebony,
      primaryContainer: KasyabaTokens.cello,
      onPrimaryContainer: KasyabaTokens.periwinkleGray,
      secondary: KasyabaTokens.periwinkleGraySubtitle,
      onSecondary: KasyabaTokens.ebony,
      secondaryContainer: KasyabaTokens.bigStone,
      onSecondaryContainer: KasyabaTokens.periwinkleGray,
      tertiary: KasyabaTokens.bermuda,
      onTertiary: KasyabaTokens.ebony,
      tertiaryContainer: KasyabaTokens.bermuda15,
      onTertiaryContainer: KasyabaTokens.periwinkleGray,
      error: KasyabaTokens.apricot,
      onError: KasyabaTokens.ebony,
      errorContainer: KasyabaTokens.apricot15,
      onErrorContainer: KasyabaTokens.apricot,
      surface: KasyabaTokens.ebony,
      onSurface: KasyabaTokens.periwinkleGray,
      surfaceContainerHighest: KasyabaTokens.bigStone,
      onSurfaceVariant: KasyabaTokens.periwinkleGraySubtitle,
      outline: KasyabaTokens.poloBlue30,
      outlineVariant: KasyabaTokens.poloBlue22,
      inverseSurface: KasyabaTokens.periwinkleGray,
      onInverseSurface: KasyabaTokens.ebony,
      inversePrimary: KasyabaTokens.poloBlue,
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KasyabaTokens.ebony,
      fontFamily: GoogleFonts.dmSans().fontFamily,

      cardTheme: CardThemeData(
        color: KasyabaTokens.bigStone,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: KasyabaTokens.poloBlue22),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KasyabaTokens.bigStone,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: KasyabaTokens.poloBlue22),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: KasyabaTokens.poloBlue22),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(
            color: KasyabaTokens.poloBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: KasyabaTokens.apricot),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(
            color: KasyabaTokens.apricot,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(
          color: KasyabaTokens.periwinkleGraySubtitle,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: KasyabaTokens.periwinkleGraySubtitle.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        prefixIconColor: KasyabaTokens.periwinkleGraySubtitle,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          backgroundColor: KasyabaTokens.periwinkleGray,
          foregroundColor: KasyabaTokens.ebony,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            letterSpacing: 0.2,
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
          side: const BorderSide(color: KasyabaTokens.kashmirBlue),
          foregroundColor: KasyabaTokens.periwinkleGray,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KasyabaTokens.periwinkleGray,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KasyabaTokens.radiusChip),
          side: const BorderSide(color: KasyabaTokens.poloBlue22),
        ),
        backgroundColor: KasyabaTokens.bigStone,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: KasyabaTokens.periwinkleGray,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: KasyabaTokens.bigStone,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KasyabaTokens.radiusDialog),
          side: const BorderSide(color: KasyabaTokens.poloBlue22),
        ),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: KasyabaTokens.periwinkleGray,
        ),
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: KasyabaTokens.periwinkleGraySubtitle,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: KasyabaTokens.bigStone,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(KasyabaTokens.radiusSheetTop),
          ),
        ),
        dragHandleColor: KasyabaTokens.poloBlue30,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: KasyabaTokens.periwinkleGray,
        ),
        subtitleTextStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12.5,
          color: KasyabaTokens.periwinkleGraySubtitle,
        ),
        iconColor: KasyabaTokens.poloBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: Colors.transparent,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: KasyabaTokens.periwinkleGray,
        linearTrackColor: KasyabaTokens.bigStone,
        linearMinHeight: 6,
      ),

      dividerTheme: const DividerThemeData(
        color: KasyabaTokens.poloBlue16,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(
        color: KasyabaTokens.periwinkleGraySubtitle,
        size: 22,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KasyabaTokens.bigStone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KasyabaTokens.radiusDialog),
          side: const BorderSide(color: KasyabaTokens.poloBlue22),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 105),
        contentTextStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: KasyabaTokens.periwinkleGray,
        ),
        elevation: 8,
      ),

      textTheme: GoogleFonts.dmSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 57,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            color: KasyabaTokens.periwinkleGray,
          ),
          displayMedium: TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: KasyabaTokens.periwinkleGray,
          ),
          displaySmall: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: KasyabaTokens.periwinkleGray,
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: KasyabaTokens.periwinkleGray,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: KasyabaTokens.periwinkleGray,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: KasyabaTokens.periwinkleGray,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: KasyabaTokens.periwinkleGray,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: KasyabaTokens.periwinkleGray,
          ),
          titleSmall: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: KasyabaTokens.periwinkleGray,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: KasyabaTokens.periwinkleGray,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: KasyabaTokens.periwinkleGray,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: KasyabaTokens.periwinkleGraySubtitle,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: KasyabaTokens.periwinkleGray,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: KasyabaTokens.periwinkleGraySubtitle,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: KasyabaTokens.periwinkleGraySubtitle,
          ),
        ),
      ),
    );
  }

  ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.emerald600,
      onPrimary: Colors.white,
      primaryContainer: AppColors.emerald100,
      onPrimaryContainer: AppColors.emerald900,
      secondary: AppColors.lightTextSecondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.lightInputFill,
      onSecondaryContainer: AppColors.lightTextPrimary,
      tertiary: AppColors.info,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.lightInputFill,
      onTertiaryContainer: AppColors.lightTextPrimary,
      error: AppColors.expense,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFE4E6),
      onErrorContainer: const Color(0xFF9F1239),
      surface: AppColors.lightCardSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightInputFill,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: AppColors.lightBorderHairline,
      outlineVariant: AppColors.lightBorderSubtle,
      inverseSurface: AppColors.surface800,
      onInverseSurface: AppColors.textDark,
      inversePrimary: AppColors.emerald400,
      shadow: const Color(0x0A000000),
      scrim: Colors.black,
      surfaceTint: Colors.transparent,
    );

    return _buildTheme(colorScheme, isDark: false);
  }

  ThemeData _buildTheme(ColorScheme cs, {required bool isDark}) {
    final scaffoldBg = isDark ? AppColors.obsidian : AppColors.lightScaffold;
    final textPrimary = isDark ? AppColors.textDark : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.surfaceCard : AppColors.lightCardSurface;
    final cardBorder = isDark ? AppColors.subtleBorder : AppColors.lightBorderHairline;
    final inputFill = isDark ? AppColors.surface700 : AppColors.lightInputFill;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: GoogleFonts.inter().fontFamily,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: scaffoldBg,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: textMuted, size: 22),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 1,
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
        shadowColor: isDark ? Colors.transparent : const Color(0x08000000),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF52525B) : AppColors.emerald500,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.expense, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        labelStyle: TextStyle(
          color: textMuted,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.textMutedL : AppColors.lightTextTertiary,
          fontSize: 14,
        ),
        prefixIconColor: textMuted,
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
          side: BorderSide(color: cardBorder, width: 1),
          foregroundColor: textPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tagRadius),
          side: BorderSide(color: cardBorder),
        ),
        backgroundColor: inputFill,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: navbarHeight,
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.emerald500, size: 23);
          }
          return IconThemeData(
            color: isDark ? AppColors.textMutedL : AppColors.lightTextTertiary,
            size: 21,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            );
          }
          return TextStyle(
            color: isDark ? AppColors.textMutedL : AppColors.lightTextTertiary,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          );
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? KasyabaTokens.bigStone : AppColors.lightCardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? KasyabaTokens.poloBlue22 : cardBorder,
            width: 1,
          ),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 105),
        contentTextStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isDark ? KasyabaTokens.periwinkleGray : textPrimary,
        ),
        elevation: isDark ? 8 : 3,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.emerald500,
        linearTrackColor: inputFill,
        linearMinHeight: 6,
      ),

      dividerTheme: DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),

      iconTheme: IconThemeData(color: textMuted, size: 22),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12.5,
          color: textMuted,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(
            fontSize: 57,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            color: textPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: textPrimary,
          ),
          displaySmall: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: textPrimary,
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: textPrimary,
          ),
          titleSmall: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textPrimary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: textPrimary,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: textMuted,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: textMuted,
          ),
        ),
      ),
    );
  }
}
