import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'kasyaba_color_scheme.dart';
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
      extensions: const <ThemeExtension<dynamic>>[
        KasyabaThemeExt(colors: kasyabaDarkColors),
      ],

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

      popupMenuTheme: PopupMenuThemeData(
        color: KasyabaTokens.bigStone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: KasyabaTokens.poloBlue22, width: 1),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: KasyabaTokens.periwinkleGray,
        ),
        elevation: 12,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(KasyabaTokens.bigStone),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: KasyabaTokens.poloBlue22, width: 1),
            ),
          ),
          elevation: const WidgetStatePropertyAll(12),
        ),
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

  /// Porcelain counterpart of the navy system (LT-A foundation).
  ///
  /// Fully rebuilt from [KasyabaColorsLight]; no legacy zinc/emerald/Inter
  /// surfaces remain in this pipeline.
  ThemeData get light {
    final colors = kasyabaLightColors;
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: colors.primaryButton,
      onPrimary: colors.onPrimaryButton,
      primaryContainer: colors.cardHero,
      onPrimaryContainer: colors.textPrimary,
      secondary: colors.textMuted,
      onSecondary: colors.card,
      secondaryContainer: colors.inputFill,
      onSecondaryContainer: colors.textPrimary,
      tertiary: colors.accentTeal,
      onTertiary: colors.card,
      tertiaryContainer: colors.successTint,
      onTertiaryContainer: colors.textPrimary,
      error: colors.danger,
      onError: colors.card,
      errorContainer: colors.dangerTint,
      onErrorContainer: colors.danger,
      surface: colors.canvas,
      onSurface: colors.textPrimary,
      surfaceContainerHighest: colors.inputFill,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.cardBorder,
      outlineVariant: colors.divider,
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.canvas,
      inversePrimary: colors.primaryButton,
      shadow: colors.shadow,
      scrim: colors.scrim,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.canvas,
      fontFamily: GoogleFonts.dmSans().fontFamily,
      extensions: const <ThemeExtension<dynamic>>[
        KasyabaThemeExt(colors: kasyabaLightColors),
      ],

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFFF6F8FB),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: Color(0xFF6B8299), size: 22),
        actionsIconTheme: IconThemeData(color: Color(0xFF5A6E85), size: 22),
        titleTextStyle: TextStyle(
          color: Color(0xFF0D1826),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: colors.cardBorder),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(
            color: colors.primaryButton,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(
            color: colors.danger,
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: colors.textMuted.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        prefixIconColor: colors.textMuted,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          backgroundColor: colors.primaryButton,
          foregroundColor: colors.onPrimaryButton,
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
          side: BorderSide(color: colors.secondaryBorder),
          foregroundColor: colors.primaryButton,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primaryButton,
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
          side: BorderSide(color: colors.cardBorder),
        ),
        backgroundColor: colors.inputFill,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: colors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KasyabaTokens.radiusDialog),
          side: BorderSide(color: colors.cardBorder),
        ),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: colors.textSecondary,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(KasyabaTokens.radiusSheetTop),
          ),
        ),
        dragHandleColor: colors.cardBorder,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: colors.textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12.5,
          color: colors.textSecondary,
        ),
        iconColor: colors.icon,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: Colors.transparent,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primaryButton,
        linearTrackColor: colors.inputFill,
        linearMinHeight: 6,
      ),

      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),

      iconTheme: IconThemeData(
        color: colors.icon,
        size: 22,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KasyabaTokens.radiusDialog),
          side: BorderSide(color: colors.cardBorder),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 105),
        contentTextStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: colors.textPrimary,
        ),
        elevation: 8,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.cardBorder, width: 1),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        elevation: 12,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.card),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colors.cardBorder, width: 1),
            ),
          ),
          elevation: const WidgetStatePropertyAll(12),
        ),
      ),

      textTheme: GoogleFonts.dmSansTextTheme(
        TextTheme(
          displayLarge: TextStyle(
            fontSize: 57,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            color: colors.textPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: colors.textPrimary,
          ),
          displaySmall: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: colors.textPrimary,
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: colors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: colors.textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: colors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: colors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: colors.textPrimary,
          ),
          titleSmall: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: colors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colors.textPrimary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: colors.textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: colors.textPrimary,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: colors.textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
