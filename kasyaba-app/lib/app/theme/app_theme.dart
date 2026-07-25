import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────
///  Kasyaba Design System — Sharp Luxurious Dark Theme
///  Style: Rectilinear sharp edges, obsidian black surfaces, hairline gold/emerald metallic borders
/// ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Emerald Luxury Brand ────────────────────────────────────
  static const emerald50  = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald900 = Color(0xFF064E3B);

  // ── Champagne Gold Accent ──────────────────────────────────
  static const gold300    = Color(0xFFFDE68A);
  static const gold400    = Color(0xFFFBBF24);
  static const gold500    = Color(0xFFD4AF37); // Champagne Metallic Gold
  static const gold600    = Color(0xFFB45309);

  // ── Deep Obsidian Dark Surfaces ────────────────────────────
  static const obsidian   = Color(0xFF070A0F); // Pitch Obsidian
  static const surface900 = Color(0xFF0C1017);
  static const surface800 = Color(0xFF111722);
  static const surface700 = Color(0xFF161E2E);
  static const surface600 = Color(0xFF1E293B);
  static const surface500 = Color(0xFF334155);
  static const surfaceCard= Color(0xFF0E131F); // Sharp Dark Card Base

  // ── Light Surface ──────────────────────────────────────────
  static const lightBg    = Color(0xFF070A0F); // Default to Dark Luxury
  static const lightCard  = Color(0xFF0E131F);
  static const lightCard2 = Color(0xFF161E2E);
  static const lightBorder= Color(0xFF1F293D);
  static const lightBorder2= Color(0xFF334155);

  // ── Status Colors ──────────────────────────────────────────
  static const income     = Color(0xFF10B981);
  static const expense    = Color(0xFFEF4444);
  static const warning    = Color(0xFFF59E0B);
  static const info       = Color(0xFF3B82F6);

  // ── Text ───────────────────────────────────────────────────
  static const textDark   = Color(0xFFF8FAFC);
  static const textMuted  = Color(0xFF94A3B8);
  static const textLight  = Color(0xFFF8FAFC);
  static const textMutedL = Color(0xFF64748B);

  // ── Gradients ──────────────────────────────────────────────
  static const gradientEmerald = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGold = LinearGradient(
    colors: [Color(0xFFB45309), Color(0xFFD4AF37)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientObsidian = LinearGradient(
    colors: [Color(0xFF070A0F), Color(0xFF0C1017)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientCardDark = LinearGradient(
    colors: [Color(0xFF0E131F), Color(0xFF161E2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glass overlay (dark) ───────────────────────────────────
  static Color glassDark(double opacity) =>
      Color.fromRGBO(14, 19, 31, opacity);
  static Color glassLight(double opacity) =>
      Color.fromRGBO(14, 19, 31, opacity);
}

class AppTheme {
  // ── SHARP RECTILINEAR EDGES (0px radius for razor cut geometry) ────
  static const _navbarHeight  = 74.0;

  // ───────────────────────── DARK THEME ──────────────────────
  ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary:            AppColors.emerald500,
      onPrimary:          Colors.black,
      primaryContainer:   AppColors.emerald900,
      onPrimaryContainer: AppColors.emerald100,
      secondary:          AppColors.gold500,
      onSecondary:        Colors.black,
      secondaryContainer: AppColors.surface700,
      onSecondaryContainer: AppColors.gold300,
      tertiary:           AppColors.info,
      onTertiary:         Colors.white,
      tertiaryContainer:  const Color(0xFF161E2E),
      onTertiaryContainer: Colors.white,
      error:              AppColors.expense,
      onError:            Colors.white,
      errorContainer:     const Color(0xFF7F1D1D),
      onErrorContainer:   const Color(0xFFFCA5A5),
      surface:            AppColors.surfaceCard,
      onSurface:          AppColors.textDark,
      surfaceContainerHighest: AppColors.surface700,
      onSurfaceVariant:   AppColors.textMuted,
      outline:            const Color(0xFF1F293D),
      outlineVariant:     const Color(0xFF334155),
      inverseSurface:     AppColors.textDark,
      onInverseSurface:   AppColors.surface900,
      inversePrimary:     AppColors.emerald700,
      shadow:             Colors.black,
      scrim:              Colors.black,
      surfaceTint:        AppColors.emerald500.withValues(alpha: 0.05),
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  // ───────────────────────── LIGHT THEME (Consolidated Dark Luxury) ───
  ThemeData get light => dark;

  ThemeData _buildTheme(ColorScheme cs, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,

      // ── Scaffold ───────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.obsidian,

      // ── App Bar ────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.obsidian,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.obsidian,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textDark,
          size: 22,
        ),
        actionsIconTheme: IconThemeData(
          color: AppColors.textMuted,
          size: 22,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),

      // ── Card (Sharp Rectilinear Edges) ─────────────────────
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(
            color: Color(0xFF1F293D),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black,
      ),

      // ── Input Decoration (Sharp Edges) ─────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface700,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF1F293D)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: Color(0xFF1F293D),
            width: 1,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: AppColors.gold500,
            width: 1.5,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.expense, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.expense, width: 1.5),
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

      // ── FilledButton (Sharp Razor Cut) ─────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          backgroundColor: AppColors.emerald500,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.0,
          ),
          elevation: 0,
        ),
      ),

      // ── OutlinedButton (Sharp Razor Cut) ───────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          side: const BorderSide(color: Color(0xFF1F293D), width: 1),
          foregroundColor: AppColors.textDark,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── TextButton ─────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold500,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),

      // ── Chip (Sharp Precision Tag) ─────────────────────────
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Color(0xFF1F293D)),
        ),
        backgroundColor: AppColors.surface700,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: AppColors.textDark,
          letterSpacing: 0.5,
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── NavigationBar (Sharp Obsidian Bar) ─────────────────
      navigationBarTheme: NavigationBarThemeData(
        height: _navbarHeight,
        backgroundColor: AppColors.obsidian,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.gold500.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.gold500, size: 24);
          }
          return const IconThemeData(
            color: AppColors.textMuted,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.gold500,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            );
          }
          return const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          );
        }),
      ),

      // ── SnackBar ───────────────────────────────────────────
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.gold500, width: 1),
        ),
        contentTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textDark,
        ),
        elevation: 12,
      ),

      // ── ProgressIndicator ─────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.emerald500,
        linearTrackColor: Color(0xFF161E2E),
        linearMinHeight: 6,
      ),

      // ── Divider ────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1F293D),
        thickness: 1,
        space: 1,
      ),

      // ── Icon ───────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textMuted,
        size: 22,
      ),

      // ── ListTile ───────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppColors.textDark,
        ),
        subtitleTextStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13,
          color: AppColors.textMuted,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        tileColor: Colors.transparent,
      ),

      // ── FloatingActionButton ──────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emerald500,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 6,
        extendedPadding: EdgeInsets.symmetric(horizontal: 22),
        extendedTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0.8,
        ),
      ),

      // ── Typography ─────────────────────────────────────────
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
          letterSpacing: 0,
          color: AppColors.textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
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
          letterSpacing: 0.5,
          color: AppColors.textDark,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
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
