import 'package:flutter/material.dart';

abstract class ScreenSize {
  static const double sm = 600;
  static const double md = 960;
  static const double lg = 1280;
  static const double xl = 1600;
}

class Responsive {
  final double width;
  final double height;

  const Responsive._(this.width, this.height);

  factory Responsive.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Responsive._(size.width, size.height);
  }

  bool get isMobile => width < ScreenSize.sm;
  bool get isTablet => width >= ScreenSize.sm && width < ScreenSize.md;
  bool get isDesktop => width >= ScreenSize.md;
  bool get isWide => width >= ScreenSize.xl;

  // Max width for per-screen content containers (sidebar already excluded
  // from available width before these values are applied).
  double get maxContentWidth {
    if (width >= ScreenSize.xl) return 1200.0; // 1600+ viewport
    if (width >= ScreenSize.lg) return 1000.0; // 1280–1600 viewport
    if (width >= ScreenSize.md) return 840.0;  // 960–1280 viewport
    return double.infinity;
  }

  // Hard cap on the shell content column itself (right of sidebar).
  // Screens that don't use PageContainer are still bounded by this.
  double get shellContentMaxWidth {
    if (width >= ScreenSize.xl) return 1400.0;
    if (width >= ScreenSize.lg) return 1120.0;
    return double.infinity; // tablet / mobile — fill available space
  }

  // Horizontal padding for the page body
  double get h {
    if (width >= ScreenSize.lg) return 40.0;
    if (width >= ScreenSize.md) return 28.0;
    if (width >= ScreenSize.sm) return 20.0;
    return 16.0;
  }

  // Section vertical spacing
  double get sectionGap {
    if (isDesktop) return 40.0;
    if (isTablet) return 28.0;
    return 20.0;
  }

  // Product grid column count
  int get productCols {
    if (width >= ScreenSize.xl) return 5;
    if (width >= ScreenSize.lg) return 4;
    if (width >= ScreenSize.md) return 3;
    if (width >= ScreenSize.sm) return 3;
    return 2;
  }

  // Seller grid column count
  int get sellerCols {
    if (width >= ScreenSize.lg) return 3;
    if (width >= ScreenSize.md) return 2;
    if (width >= ScreenSize.sm) return 2;
    return 1;
  }

  // Whether to show the sidebar navigation
  bool get showSidebar => width >= ScreenSize.md;

  // Sidebar width
  double get sidebarWidth => width >= ScreenSize.lg ? 240.0 : 200.0;

  // Category panel width on desktop home
  double get categoryPanelWidth => width >= ScreenSize.lg ? 220.0 : 180.0;
}

// Convenience builder that provides a Responsive instance
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Responsive r) builder;
  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive.of(context));
  }
}

// Max-width centered container — use this on every page body
class PageContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const PageContainer({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final mw = maxWidth ?? r.maxContentWidth;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: mw),
        child: child,
      ),
    );
  }
}
