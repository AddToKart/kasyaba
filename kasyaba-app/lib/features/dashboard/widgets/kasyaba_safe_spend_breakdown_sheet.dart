import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/deterministic_math.dart';

/// ─────────────────────────────────────────────────────────────
///  Kasya Ba Today? Math Breakdown Navigation (Figma Image 2)
/// ─────────────────────────────────────────────────────────────
void showSafeSpendBreakdownSheet(
  BuildContext context,
  DailySafeSpendCalculation calc,
) {
  context.push('/planning/breakdown', extra: calc);
}
