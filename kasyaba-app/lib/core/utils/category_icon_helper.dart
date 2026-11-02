import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Clean monochrome vector icon & color helper for transaction categories
class CategoryIconHelper {
  CategoryIconHelper._();

  static IconData getIcon(String categoryName) {
    final lower = categoryName.toLowerCase().trim();
    if (lower.contains('food') ||
        lower.contains('dining') ||
        lower.contains('restaurant') ||
        lower.contains('grocery') ||
        lower.contains('ramen') ||
        lower.contains('snack')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('entertain') ||
        lower.contains('subscription') ||
        lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('streaming') ||
        lower.contains('gaming')) {
      return Icons.movie_outlined;
    }
    if (lower.contains('utilit') ||
        lower.contains('electricity') ||
        lower.contains('water') ||
        lower.contains('internet') ||
        lower.contains('wifi') ||
        lower.contains('bill')) {
      return Icons.bolt_rounded;
    }
    // Healthcare check MUST come before transport to avoid 'healthcare' matching 'car'
    if (lower.contains('health') ||
        lower.contains('medical') ||
        lower.contains('doctor') ||
        lower.contains('hospital') ||
        lower.contains('pharmacy') ||
        lower.contains('medicine') ||
        lower.contains('clinic')) {
      return Icons.medical_services_rounded;
    }
    if (lower.contains('transport') ||
        lower.contains('commute') ||
        lower.contains('gas') ||
        lower.contains('fuel') ||
        RegExp(r'\b(car|cars|auto)\b').hasMatch(lower) ||
        lower.contains('grab') ||
        lower.contains('taxi')) {
      return Icons.directions_car_rounded;
    }
    if (lower.contains('shop') ||
        lower.contains('cloth') ||
        lower.contains('retail') ||
        lower.contains('gadget') ||
        lower.contains('electronics')) {
      return Icons.shopping_bag_outlined;
    }
    if (lower.contains('house') ||
        lower.contains('rent') ||
        lower.contains('mortgage') ||
        lower.contains('home')) {
      return Icons.home_outlined;
    }
    if (lower.contains('salary') ||
        lower.contains('wage') ||
        lower.contains('payroll') ||
        lower.contains('income')) {
      return Icons.payments_outlined;
    }
    if (lower.contains('saving') ||
        lower.contains('invest') ||
        lower.contains('deposit')) {
      return Icons.savings_outlined;
    }
    if (lower.contains('educat') ||
        lower.contains('tuition') ||
        lower.contains('course') ||
        lower.contains('book')) {
      return Icons.school_outlined;
    }
    if (lower.contains('travel') ||
        lower.contains('flight') ||
        lower.contains('vacation') ||
        lower.contains('hotel')) {
      return Icons.flight_outlined;
    }
    if (lower.contains('freelance') ||
        lower.contains('client') ||
        lower.contains('contract') ||
        lower.contains('project')) {
      return Icons.laptop_mac_outlined;
    }
    if (lower.contains('allowance') ||
        lower.contains('stipend') ||
        lower.contains('pocket')) {
      return Icons.wallet_outlined;
    }
    if (lower.contains('bonus') ||
        lower.contains('reward') ||
        lower.contains('gift')) {
      return Icons.redeem_outlined;
    }
    if (lower.contains('transfer')) {
      return Icons.swap_horiz_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  static Color getColor(String categoryName, {bool isExpense = true}) {
    if (!isExpense) return AppColors.income;
    final lower = categoryName.toLowerCase().trim();
    if (lower.contains('food') || lower.contains('dining')) {
      return const Color(0xFFF97316); // Amber Orange
    }
    if (lower.contains('entertain') || lower.contains('subscription')) {
      return const Color(0xFFA855F7); // Purple
    }
    if (lower.contains('utilit') || lower.contains('bill')) {
      return const Color(0xFF38BDF8); // Sky Blue
    }
    if (lower.contains('health') || lower.contains('medical')) {
      return const Color(0xFFEF4444); // Red
    }
    if (lower.contains('transport') || RegExp(r'\b(car|cars|auto)\b').hasMatch(lower)) {
      return const Color(0xFFEAB308); // Yellow
    }
    if (lower.contains('shop')) {
      return const Color(0xFFEC4899); // Pink
    }
    if (lower.contains('transfer')) {
      return AppColors.info;
    }
    return AppColors.gold500;
  }

  static IconData iconFor(String categoryName) => getIcon(categoryName);
  static Color colorFor(String categoryName, {bool isExpense = true}) =>
      getColor(categoryName, isExpense: isExpense);
}
