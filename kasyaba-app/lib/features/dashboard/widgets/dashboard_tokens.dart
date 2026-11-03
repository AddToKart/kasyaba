import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
///  Dashboard Design System — Figma Pixel-Perfect Tokens (Node 11:5943)
/// ─────────────────────────────────────────────────────────────
class DashboardTokens {
  DashboardTokens._();

  // Colors
  static const Color ebony = Color(0xFF0A1220); // Base canvas & dark text
  static const Color ebony85 = Color(0xD90A1220); // rgba(10, 18, 32, 0.85) (nav bar)
  static const Color bigStone = Color(0xFF16293F); // #16293F (card backgrounds)
  static const Color cello = Color(0xFF1E3A56); // #1E3A56 (subtitles on CTA)
  static const Color cello60 = Color(0x991E3A56); // rgba(30, 58, 86, 0.6) (hero card fill)
  static const Color periwinkleGray = Color(0xFFC9DCEA); // #C9DCEA (primary headings, amounts, CTA card fill, primary button)
  static const Color periwinkleGraySubtitle = Color(0xFFB4CDE0); // #B4CDE0 (subtitles, secondary labels)
  static const Color poloBlue = Color(0xFF8FB2CE); // #8FB2CE (segment 2, projected stroke)
  static const Color poloBlue40 = Color(0x668FB2CE); // rgba(143, 178, 206, 0.4)
  static const Color poloBlue30 = Color(0x4D8FB2CE); // rgba(143, 178, 206, 0.3) (hero border, nav border)
  static const Color poloBlue25 = Color(0x408FB2CE); // rgba(143, 178, 206, 0.25)
  static const Color poloBlue22 = Color(0x388FB2CE); // rgba(143, 178, 206, 0.22) (card borders, dividers)
  static const Color poloBlue20 = Color(0x338FB2CE); // rgba(143, 178, 206, 0.2) (progress track fill)
  static const Color poloBlue16 = Color(0x298FB2CE); // rgba(143, 178, 206, 0.16) (subtle dividers)
  static const Color poloBlue14 = Color(0x248FB2CE); // rgba(143, 178, 206, 0.14)
  static const Color kashmirBlue = Color(0xFF4F7596); // #4F7596 (expense border, radial gradient, segment 3)
  static const Color sanJuan = Color(0xFF2F5578); // #2F5578 (segment 4)
  static const Color bermuda = Color(0xFF7FD8B5); // #7FD8B5 (buffer text, bills covered badge)
  static const Color bermuda15 = Color(0x267FD8B5); // rgba(127, 216, 181, 0.15) (bills covered badge fill)
  static const Color apricot = Color(0xFFF2928A); // #F2928A (budget used alert, bill due dot)
  static const Color apricot15 = Color(0x26F2928A); // rgba(242, 146, 138, 0.15)

  // Forecasting (Node 85:110) Tokens
  static const Color cornflowerBlue = Color(0xFF6E5BFF); // #6E5BFF (Free allocation bar & dot)
  static const Color java = Color(0xFF19C3B4); // #19C3B4 (Goals allocation bar & dot)
  static const Color casablanca = Color(0xFFF5B942); // #F5B942 (Bills allocation bar & dot)
  static const Color baliHai = Color(0xFF8E97B6); // #8E97B6 (Legend & subtitle text)
  static const Color zircon = Color(0xFFF1F4FF); // #F1F4FF (Planned transactions heading)

  // Gradients
  static const RadialGradient canvasGradient = RadialGradient(
    center: Alignment(0.8, -1.0), // circle at 90% 0%
    radius: 1.4,
    colors: [
      Color(0xAB4F7596), // rgba(79, 117, 150, 0.67)
      Color(0x004F7596), // rgba(79, 117, 150, 0)
    ],
    stops: [0.0, 0.7],
  );
}

