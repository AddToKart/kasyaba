import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────
///  Kasyaba Design System — Luxury Finance Theme
///  Palette: Deep obsidian + Emerald primary + Gold accent
/// ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Emerald Brand ──────────────────────────────────────────
  static const emerald50  = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald900 = Color(0xFF064E3B);

  // ── Gold Accent ────────────────────────────────────────────
  static const gold300    = Color(0xFFFCD34D);
  static const gold400    = Color(0xFFFBBF24);
  static const gold500    = Color(0xFFF59E0B);
  static const gold600    = Color(0xFFD97706);

  // ── Dark Surface (Obsidian) ────────────────────────────────
  static const obsidian   = Color(0xFF060B14);
  static const surface900 = Color(0xFF0A1628);
  static const surface800 = Color(0xFF0D1F3C);
  static const surface700 = Color(0xFF112240);
  static const surface600 = Color(0xFF172F52);
  static const surface500 = Color(0xFF1E3A5F);
  static const surfaceCard= Color(0xFF0F1E38);

  // ── Light Surface ──────────────────────────────────────────
  static const lightBg    = Color(0xFFF5F7FA);
  static const lightCard  = Color(0xFFFFFFFF);
  static const lightCard2 = Color(0xFFF0F4F8);
  static const lightBorder= Color(0xFFE2E8F0);
  static const lightBorder2= Color(0xFFCBD5E1);

  // ── Status Colors ──────────────────────────────────────────
  static const income     = Color(0xFF10B981);
  static const expense    = Color(0xFFEF4444);
  static const warning    = Color(0xFFF59E0B);
  static const info       = Color(0xFF3B82F6);

  // ── Text ───────────────────────────────────────────────────
  static const textDark   = Color(0xFFE2E8F0);
  static const textMuted  = Color(0xFF94A3B8);
  static const textLight  = Color(0xFF1E293B);
  static const textMutedL = Color(0xFF64748B);

  // ── Gradients ──────────────────────────────────────────────
  static const gradientEmerald = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGold = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFCD34D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientObsidian = LinearGradient(
    colors: [Color(0xFF060B14), Color(0xFF0A1628), Color(0xFF0D1F3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientCardDark = LinearGradient(
    colors: [Color(0xFF0F1E38), Color(0xFF112240)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glass overlay (dark) ───────────────────────────────────
  static Color glassDark(double opacity) =>
      Color.fromRGBO(15, 30, 56, opacity);
  static Color glassLight(double opacity) =>
      Color.fromRGBO(255, 255, 255, opacity);
}

class AppTheme {
  // ── Shared constants ────────────────────────────────────────
  static const _cardRadius    = 20.0;
  static const _buttonRadius  = 16.0;
  static const _inputRadius   = 14.0;
  static const _navbarHeight  = 76.0;

  // ───────────────────────── DARK THEME ──────────────────────
  ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary:            AppColors.emerald500,
      onPrimary:          Colors.white,
      primaryContainer:   AppColors.emerald900,
      onPrimaryContainer: AppColors.emerald100,
      secondary:          AppColors.gold400,
      onSecondary:        AppColors.surface900,
      secondaryContainer: AppColors.surface700,
      onSecondaryContainer: AppColors.gold300,
      tertiary:           AppColors.info,
      onTertiary:         Colors.white,
      tertiaryContainer:  const Color(0xFF1E3A5F),
      onTertiaryContainer: Colors.white,
      error:              AppColors.expense,
      onError:            Colors.white,
      errorContainer:     const Color(0xFF7F1D1D),
      onErrorContainer:   const Color(0xFFFCA5A5),
      surface:            AppColors.surface900,
      onSurface:          AppColors.textDark,
      surfaceContainerHighest: AppColors.surface700,
      onSurfaceVariant:   AppColors.textMuted,
      outline:            AppColors.surface600,
      outlineVariant:     AppColors.surface700,
      inverseSurface:     AppColors.textDark,
      onInverseSurface:   AppColors.surface900,
      inversePrimary:     AppColors.emerald700,
      shadow:             Colors.black,
      scrim:              Colors.black,
      surfaceTint:        AppColors.emerald500.withValues(alpha: 0.08),
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  // ───────────────────────── LIGHT THEME ─────────────────────
  ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary:            AppColors.emerald600,
      onPrimary:          Colors.white,
      primaryContainer:   AppColors.emerald100,
      onPrimaryContainer: AppColors.emerald900,
      secondary:          AppColors.gold500,
      onSecondary:        Colors.white,
      secondaryContainer: const Color(0xFFFEF3C7),
      onSecondaryContainer: AppColors.gold600,
      tertiary:           AppColors.info,
      onTertiary:         Colors.white,
      tertiaryContainer:  const Color(0xFFDBEAFE),
      onTertiaryContainer: const Color(0xFF1E40AF),
      error:              const Color(0xFFDC2626),
      onError:            Colors.white,
      errorContainer:     const Color(0xFFFEE2E2),
      onErrorContainer:   const Color(0xFF991B1B),
      surface:            AppColors.lightBg,
      onSurface:          AppColors.textLight,
      surfaceContainerHighest: AppColors.lightCard2,
      onSurfaceVariant:   AppColors.textMutedL,
      outline:            AppColors.lightBorder,
      outlineVariant:     AppColors.lightBorder2,
      inverseSurface:     AppColors.surface800,
      onInverseSurface:   AppColors.textDark,
      inversePrimary:     AppColors.emerald400,
      shadow:             Colors.black,
      scrim:              Colors.black,
      surfaceTint:        AppColors.emerald600.withValues(alpha: 0.05),
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  ThemeData _buildTheme(ColorScheme cs, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,

      // ── Scaffold ───────────────────────────────────────────
      scaffoldBackgroundColor: isDark ? AppColors.obsidian : AppColors.lightBg,

      // ── App Bar ────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: AppColors.obsidian,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: AppColors.lightBg,
              ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textDark : AppColors.textLight,
          size: 22,
        ),
        actionsIconTheme: IconThemeData(
          color: isDark ? AppColors.textMuted : AppColors.textMutedL,
          size: 22,
        ),
        titleTextStyle: TextStyle(
          color: isDark ? AppColors.textDark : AppColors.textLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),

      // ── Card ───────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.surfaceCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          side: BorderSide(
            color: isDark
                ? AppColors.surface600.withValues(alpha: 0.6)
                : AppColors.lightBorder.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),

      // ── Input Decoration ───────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.surface700.withValues(alpha: 0.5)
            : AppColors.lightCard2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(
            color: isDark ? AppColors.surface600 : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.surface600.withValues(alpha: 0.7)
                : AppColors.lightBorder,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(
            color: cs.primary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        labelStyle: TextStyle(
          color: isDark ? AppColors.textMuted : AppColors.textMutedL,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: (isDark ? AppColors.textMuted : AppColors.textMutedL)
              .withValues(alpha: 0.7),
          fontSize: 14,
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return cs.primary;
          return isDark ? AppColors.textMuted : AppColors.textMutedL;
        }),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return TextStyle(color: cs.primary, fontWeight: FontWeight.w600);
          }
          return TextStyle(
            color: isDark ? AppColors.textMuted : AppColors.textMutedL,
          );
        }),
      ),

      // ── FilledButton ──────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
          elevation: 0,
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          side: BorderSide(color: cs.outline, width: 1.5),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),

      // ── TextButton ─────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // ── Chip ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: isDark ? AppColors.surface600 : AppColors.lightBorder,
        ),
        backgroundColor: isDark ? AppColors.surface700 : AppColors.lightCard2,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── NavigationBar ──────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        height: _navbarHeight,
        backgroundColor: isDark
            ? AppColors.surface900.withValues(alpha: 0.95)
            : AppColors.lightCard.withValues(alpha: 0.97),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        elevation: 0,
        indicatorColor: cs.primary.withValues(alpha: isDark ? 0.18 : 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: 24);
          }
          return IconThemeData(
            color: isDark ? AppColors.textMuted : AppColors.textMutedL,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            );
          }
          return TextStyle(
            color: isDark ? AppColors.textMuted : AppColors.textMutedL,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          );
        }),
      ),

      // ── SnackBar ───────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        elevation: 8,
      ),

      // ── ProgressIndicator ─────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.primary.withValues(alpha: 0.12),
        linearMinHeight: 6,
      ),

      // ── Divider ────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark
            ? AppColors.surface600.withValues(alpha: 0.5)
            : AppColors.lightBorder.withValues(alpha: 0.7),
        thickness: 1,
        space: 1,
      ),

      // ── Icon ───────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: isDark ? AppColors.textMuted : AppColors.textMutedL,
        size: 22,
      ),

      // ── ListTile ───────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        subtitleTextStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13,
          color: isDark ? AppColors.textMuted : AppColors.textMutedL,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.transparent,
      ),

      // ── FloatingActionButton ──────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 4,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
      ),

      // ── Typography ─────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.textMuted : AppColors.textMutedL,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          color: isDark ? AppColors.textMuted : AppColors.textMutedL,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: isDark ? AppColors.textMuted : AppColors.textMutedL,
        ),
      ),
    );
  }
}
