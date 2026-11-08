import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/widgets/motion_components.dart';
import '../theme/app_motion.dart';
import '../theme/kasyaba_color_scheme.dart';

/// ─────────────────────────────────────────────────────────────
///  AppShell — Floating Navigation Dock (Figma Node 106:2024)
/// ─────────────────────────────────────────────────────────────

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({super.key, required this.child, required this.location});

  int _getSelectedIndex() {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/planning') || location.startsWith('/bills')) {
      return 2;
    }
    if (location.startsWith('/goals')) return 3;
    if (location.startsWith('/settings') || location.startsWith('/accounts')) {
      return 4;
    }
    // /dashboard, /budgets and /alerts are all children of the Home tab.
    if (location.startsWith('/dashboard') ||
        location.startsWith('/budgets') ||
        location.startsWith('/alerts') ||
        location == '/') {
      return 0;
    }
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/transactions');
      case 2:
        context.go('/planning');
      case 3:
        context.go('/goals');
      case 4:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex();

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _LuxuryFloatingDock(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _onDestinationSelected(context, i),
      ),
    );
  }
}

class _LuxuryFloatingDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _LuxuryFloatingDock({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const _destinations = [
    _NavDestination(
      svgAsset: 'assets/images/nav_home.svg',
      fallbackIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavDestination(
      svgAsset: 'assets/images/nav_activity.svg',
      fallbackIcon: Icons.swap_horiz_rounded,
      label: 'Activity',
    ),
    _NavDestination(
      svgAsset: 'assets/images/nav_forecast.svg',
      fallbackIcon: Icons.insights_rounded,
      label: 'Forecast',
    ),
    _NavDestination(
      svgAsset: 'assets/images/nav_goals.svg',
      fallbackIcon: Icons.track_changes_rounded,
      label: 'Goals',
    ),
    _NavDestination(
      svgAsset: 'assets/images/nav_profile.svg',
      fallbackIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final colors = context.kColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor =
        isDark ? colors.shadow.withValues(alpha: 0.5) : colors.shadow;

    return Center(
      heightFactor: 1.0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 362),
        margin: EdgeInsets.fromLTRB(
          14,
          0,
          14,
          bottomPadding > 0 ? bottomPadding : 16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Container(
              height: 68,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colors.dockFill,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: colors.dockBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  for (int i = 0; i < _destinations.length; i++) ...[
                    _NavItem(
                      destination: _destinations[i],
                      isSelected: selectedIndex == i,
                      onTap: () => onDestinationSelected(i),
                    ),
                    if (i < _destinations.length - 1)
                      const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  final String svgAsset;
  final IconData fallbackIcon;
  final String label;

  const _NavDestination({
    required this.svgAsset,
    required this.fallbackIcon,
    required this.label,
  });
}

class _NavItem extends StatelessWidget {
  final _NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.kColors;
    final iconColor = isSelected ? colors.onPrimaryButton : colors.icon;
    final labelColor =
        isSelected ? colors.onPrimaryButton : colors.textSecondary;

    return Expanded(
      child: SpringTouch(
        scaleDown: 0.92,
        onTap: () {
          AppHaptics.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 54,
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryButton : Colors.transparent,
            borderRadius: BorderRadius.circular(27),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  child: SvgPicture.asset(
                    destination.svgAsset,
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.dmSans(
                      color: labelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
