import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../theme/app_motion.dart';

/// ─────────────────────────────────────────────────────────────
///  AppShell — Ultra Luxury Floating Navigation Dock
/// ─────────────────────────────────────────────────────────────

/// A custom [FloatingActionButtonLocation] that positions the FAB safely above
/// the floating luxury dock of [AppShell].
class FloatingDockFabLocation extends FloatingActionButtonLocation {
  final double? bottomPadding;
  final double gap;

  const FloatingDockFabLocation({
    this.bottomPadding,
    this.gap = 20.0,
  });

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double rawBottom = bottomPadding ?? scaffoldGeometry.minInsets.bottom;
    final double dockBottomMargin =
        rawBottom > 0 ? rawBottom : (bottomPadding != null ? 12.0 : 24.0);
    final double dockTotalHeight = 64.0 + dockBottomMargin;

    final double fabX = scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        16.0;
    final double fabY = scaffoldGeometry.scaffoldSize.height -
        dockTotalHeight -
        scaffoldGeometry.floatingActionButtonSize.height -
        gap;
    return Offset(fabX, fabY);
  }
}

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({super.key, required this.child, required this.location});

  int _getSelectedIndex() {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/goals')) return 2;
    if (location.startsWith('/bills')) return 3;
    if (location.startsWith('/settings')) return 4;
    if (location.startsWith('/dashboard')) return 0;
    return -1;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/transactions');
      case 2:
        context.go('/goals');
      case 3:
        context.go('/bills');
      case 4:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _LuxuryFloatingDock(
        selectedIndex: selectedIndex,
        isDark: isDark,
        onDestinationSelected: (i) => _onDestinationSelected(context, i),
      ),
    );
  }
}

class _LuxuryFloatingDock extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onDestinationSelected;

  const _LuxuryFloatingDock({
    required this.selectedIndex,
    required this.isDark,
    required this.onDestinationSelected,
  });

  static const _destinations = [
    _NavDestination(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Dashboard',
    ),
    _NavDestination(
      icon: Icons.swap_horiz_outlined,
      activeIcon: Icons.swap_horiz_rounded,
      label: 'Transactions',
    ),
    _NavDestination(
      icon: Icons.track_changes_outlined,
      activeIcon: Icons.track_changes_rounded,
      label: 'Goals',
    ),
    _NavDestination(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Bills',
    ),
    _NavDestination(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomPadding > 0 ? bottomPadding : 12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xF7121215)
            : const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.subtleBorder : AppColors.lightBorderHairline,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0x18000000),
            blurRadius: isDark ? 12 : 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (int i = 0; i < _destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: _destinations[i],
                    isSelected: selectedIndex == i,
                    isDark: isDark,
                    onTap: () => onDestinationSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavItem extends StatelessWidget {
  final _NavDestination destination;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.emerald500;
    final inactiveColor = isDark ? AppColors.textMuted : AppColors.textMutedL;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.selectionClick();
          onTap();
        },
        splashColor: activeColor.withValues(alpha: 0.1),
        highlightColor: activeColor.withValues(alpha: 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(
                        color: activeColor.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Icon(
                isSelected ? destination.activeIcon : destination.icon,
                size: 20,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 10,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
