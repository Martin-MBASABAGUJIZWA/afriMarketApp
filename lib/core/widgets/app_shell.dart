import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
import 'package:afrimarket/core/utils/responsive.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/features/cart/presentation/providers/cart_provider.dart';

// ──────────────────────────────────────────────────────────
// Data
// ──────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
  });
}

// ──────────────────────────────────────────────────────────
// Root shell — picks layout based on breakpoint
// ──────────────────────────────────────────────────────────

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  List<_NavItem> _items(int cartCount, bool isLoggedIn) => [
        const _NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
        ),
        const _NavItem(
          icon: Icons.search_outlined,
          activeIcon: Icons.search_rounded,
          label: 'Search',
        ),
        _NavItem(
          icon: Icons.shopping_cart_outlined,
          activeIcon: Icons.shopping_cart_rounded,
          label: 'Cart',
          badge: cartCount,
        ),
        const _NavItem(
          icon: Icons.favorite_border_rounded,
          activeIcon: Icons.favorite_rounded,
          label: 'Wishlist',
        ),
        _NavItem(
          icon: isLoggedIn
              ? Icons.person_outline_rounded
              : Icons.login_outlined,
          activeIcon:
              isLoggedIn ? Icons.person_rounded : Icons.login_rounded,
          label: isLoggedIn ? 'Profile' : 'Login',
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = Responsive.of(context);
    final cartCount = ref.watch(cartProvider).length;
    final isLoggedIn = ref.watch(authStateProvider).value != null ||
        ref.watch(authNotifierProvider).value != null;
    final items = _items(cartCount, isLoggedIn);
    final idx = navigationShell.currentIndex;

    if (r.isDesktop) {
      return _DesktopShell(
        shell: navigationShell,
        items: items,
        currentIndex: idx,
        sidebarWidth: r.sidebarWidth,
        onTap: _go,
      );
    }
    if (r.isTablet) {
      return _TabletShell(
        shell: navigationShell,
        items: items,
        currentIndex: idx,
        onTap: _go,
      );
    }
    return _MobileShell(
      shell: navigationShell,
      items: items,
      currentIndex: idx,
      onTap: _go,
    );
  }
}

// ──────────────────────────────────────────────────────────
// Mobile: bottom nav
// ──────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MobileShell({
    required this.shell,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        items: items
            .map((item) => BottomNavigationBarItem(
                  icon: _NavBadge(
                    child: Icon(item.icon, size: 26),
                    count: item.badge,
                  ),
                  activeIcon: _NavBadge(
                    child: Icon(item.activeIcon, size: 26),
                    count: item.badge,
                  ),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Tablet: navigation rail
// ──────────────────────────────────────────────────────────

class _TabletShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TabletShell({
    required this.shell,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            labelType: NavigationRailLabelType.selected,
            backgroundColor: Colors.white,
            selectedIconTheme:
                const IconThemeData(color: AppTheme.primaryGreen, size: 26),
            unselectedIconTheme:
                IconThemeData(color: Colors.grey.shade500, size: 24),
            selectedLabelTextStyle: GoogleFonts.poppins(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            unselectedLabelTextStyle: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
            leading: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: _BrandMark(compact: true),
            ),
            destinations: items
                .map((item) => NavigationRailDestination(
                      icon: _NavBadge(
                        child: Icon(item.icon),
                        count: item.badge,
                      ),
                      selectedIcon: _NavBadge(
                        child: Icon(item.activeIcon),
                        count: item.badge,
                      ),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: shell),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Desktop: permanent sidebar
// ──────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  final List<_NavItem> items;
  final int currentIndex;
  final double sidebarWidth;
  final ValueChanged<int> onTap;

  const _DesktopShell({
    required this.shell,
    required this.items,
    required this.currentIndex,
    required this.sidebarWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: _DesktopSidebar(
              items: items,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: shell),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DesktopSidebar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _BrandMark(compact: false),
            ),
            const SizedBox(height: 28),
            ...List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return _SidebarTile(
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
                badge: item.badge,
                selected: selected,
                onTap: () => onTap(i),
              );
            }),
            const Spacer(),
            const Divider(height: 1),
            _SidebarTile(
              icon: Icons.storefront_outlined,
              activeIcon: Icons.storefront_rounded,
              label: 'Sell on AfriMarket',
              badge: 0,
              selected: false,
              onTap: () => context.push('/seller-dashboard'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected
            ? AppTheme.primaryGreen.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _NavBadge(
                  child: Icon(
                    selected ? activeIcon : icon,
                    size: 22,
                    color: selected
                        ? AppTheme.primaryGreen
                        : Colors.grey.shade600,
                  ),
                  count: badge,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppTheme.primaryGreen
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Shared helpers
// ──────────────────────────────────────────────────────────

class _NavBadge extends StatelessWidget {
  final Widget child;
  final int count;

  const _NavBadge({required this.child, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: AppTheme.accentOrange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                count > 9 ? '9+' : '$count',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  final bool compact;
  const _BrandMark({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 32 : 36,
          height: compact ? 32 : 36,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'A',
              style: GoogleFonts.poppins(
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          Text(
            'AfriMarket',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ],
    );
  }
}
