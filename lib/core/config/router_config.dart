import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/core/widgets/app_shell.dart';
import 'package:afrimarket/features/auth/presentation/screens/splash_screen.dart';
import 'package:afrimarket/features/auth/presentation/screens/login_screen.dart';
import 'package:afrimarket/features/auth/presentation/screens/signup_screen.dart';
import 'package:afrimarket/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/features/marketplace/presentation/screens/home_screen.dart';
import 'package:afrimarket/features/marketplace/presentation/screens/product_detail_screen.dart';
import 'package:afrimarket/features/marketplace/presentation/screens/search_screen.dart';
import 'package:afrimarket/features/marketplace/presentation/screens/favorites_screen.dart';
import 'package:afrimarket/features/seller/presentation/screens/seller_profile_screen.dart';
import 'package:afrimarket/features/seller/presentation/screens/seller_dashboard_screen.dart';
import 'package:afrimarket/features/seller/presentation/screens/add_product_screen.dart';
import 'package:afrimarket/features/seller/presentation/screens/become_seller_screen.dart';
import 'package:afrimarket/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:afrimarket/features/orders/presentation/screens/order_summary_screen.dart';
import 'package:afrimarket/features/orders/presentation/screens/orders_list_screen.dart';
import 'package:afrimarket/features/profile/presentation/screens/profile_screen.dart';
import 'package:afrimarket/features/cart/presentation/screens/cart_screen.dart';
import 'package:afrimarket/features/notifications/presentation/screens/notifications_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(authStateProvider, (_, __) {
      notifyListeners();
    });
    _ref.listen<AsyncValue<User?>>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  bool get isLoading => _ref.read(authStateProvider).isLoading;

  bool get isAuthenticated {
    final notifierUser = _ref.read(authNotifierProvider).value;
    if (notifierUser != null) return true;
    return _ref.read(authStateProvider).value != null;
  }
}

// Routes that require a logged-in user (cart intentionally excluded — guests can browse)
const _protectedPrefixes = [
  '/favorites',
  '/order-summary',
  '/my-orders',
  '/profile',
  '/seller-dashboard',
  '/seller/add-product',
  '/become-seller',
  '/admin',
  '/notifications',
];

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      if (notifier.isLoading) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      final isAuthenticated = notifier.isAuthenticated;
      final loc = state.matchedLocation;
      final isAuthPage = loc == '/login' ||
          loc == '/signup' ||
          loc == '/forgot-password';

      if (loc == '/splash') return '/home';

      if (isAuthenticated && isAuthPage) return '/home';

      final needsAuth = _protectedPrefixes.any((p) => loc.startsWith(p));
      if (!isAuthenticated && needsAuth) return '/login';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ── Shell routes (persistent nav) ──────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // 0: Home
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          // 1: Search
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ]),
          // 2: Cart
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartScreen(),
            ),
          ]),
          // 3: Favorites
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ]),
          // 4: Profile
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // ── Full-screen routes (no persistent nav) ─────────────────────
      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/seller-dashboard',
        builder: (context, state) => const SellerDashboardScreen(),
      ),
      GoRoute(
        path: '/seller/add-product',
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/seller/:id',
        builder: (context, state) =>
            SellerProfileScreen(sellerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/become-seller',
        builder: (context, state) => const BecomeSellerScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/order-summary',
        builder: (context, state) => const OrderSummaryScreen(),
      ),
      GoRoute(
        path: '/my-orders',
        builder: (context, state) => const OrdersListScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
