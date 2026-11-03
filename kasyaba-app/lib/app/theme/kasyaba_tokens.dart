import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
///  Kasyaba Design System — Single Source of Truth Tokens
///  Canonical navy palette implemented across the app (D1).
/// ─────────────────────────────────────────────────────────────
class KasyabaTokens {
  KasyabaTokens._();

  // Colors
  static const Color ebony = Color(0xFF0A1220); // Base canvas & dark text
  static const Color ebony85 = Color(0xD90A1220); // rgba(10, 18, 32, 0.85)
  static const Color bigStone = Color(0xFF16293F); // Card backgrounds
  static const Color cello = Color(0xFF1E3A56); // Elevated subtitle tone
  static const Color cello60 = Color(0x991E3A56); // Hero card fill
  static const Color periwinkleGray = Color(0xFFC9DCEA); // Primary text
  static const Color periwinkleGraySubtitle = Color(0xFFB4CDE0); // Secondary text
  static const Color poloBlue = Color(0xFF8FB2CE); // Accent stroke
  static const Color poloBlue40 = Color(0x668FB2CE); // rgba(143, 178, 206, 0.4)
  static const Color poloBlue30 = Color(0x4D8FB2CE); // rgba(143, 178, 206, 0.3)
  static const Color poloBlue25 = Color(0x408FB2CE); // rgba(143, 178, 206, 0.25)
  static const Color poloBlue22 = Color(0x388FB2CE); // rgba(143, 178, 206, 0.22)
  static const Color poloBlue20 = Color(0x338FB2CE); // rgba(143, 178, 206, 0.2)
  static const Color poloBlue16 = Color(0x298FB2CE); // rgba(143, 178, 206, 0.16)
  static const Color poloBlue14 = Color(0x248FB2CE); // rgba(143, 178, 206, 0.14)
  static const Color kashmirBlue = Color(0xFF4F7596); // Strong border & glow
  static const Color sanJuan = Color(0xFF2F5578); // Deep accent
  static const Color bermuda = Color(0xFF7FD8B5); // Success / positive
  static const Color bermuda15 = Color(0x267FD8B5); // Success fill
  static const Color apricot = Color(0xFFF2928A); // Danger / warning
  static const Color apricot15 = Color(0x26F2928A); // Danger fill

  // Forecasting tokens
  static const Color cornflowerBlue = Color(0xFF6E5BFF);
  static const Color java = Color(0xFF19C3B4);
  static const Color casablanca = Color(0xFFF5B942);
  static const Color baliHai = Color(0xFF8E97B6);
  static const Color zircon = Color(0xFFF1F4FF);

  // Loose near-tokens promoted from screen-level literals
  static const Color casablanca15 = Color(0x26F5B942);
  static const Color recessFill = Color(0xFF101E31);
  static const Color kashmirGlow35 = Color(0x594F7596);

  // Gradients
  static const RadialGradient canvasGradient = RadialGradient(
    center: Alignment(0.8, -1.0),
    radius: 1.4,
    colors: [
      Color(0xAB4F7596), // rgba(79, 117, 150, 0.67)
      Color(0x004F7596), // rgba(79, 117, 150, 0)
    ],
    stops: [0.0, 0.7],
  );

  // Sizing
  static const double radiusCard = 28.0;
  static const double radiusDialog = 24.0;
  static const double radiusChip = 22.0;
  static const double radiusSheetTop = 32.0;
  static const double radiusDock = 34.0;
  static const double screenPaddingH = 20.0;
  static const double dockClearance = 105.0;
}
