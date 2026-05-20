import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/features/auth/presentation/screens/splash_screen.dart';
import 'package:afrimarket/features/auth/presentation/screens/login_screen.dart';
import 'package:afrimarket/features/auth/presentation/screens/signup_screen.dart';
import 'package:afrimarket/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/features/marketplace/presentation/screens/home_screen.dart';
import 'package:afrimarket/features/marketplace/presentation/screens/product_detail_screen.dart';
import 'package:afrimarket/features/seller/presentation/screens/seller_profile_screen.dart';
import 'package:afrimarket/features/seller/presentation/screens/seller_dashboard_screen.dart';
import 'package:afrimarket/features/seller/presentation/screens/add_product_screen.dart';
import 'package:afrimarket/features/seller/presentation/screens/become_seller_screen.dart';
import 'package:afrimarket/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:afrimarket/features/orders/presentation/screens/order_summary_screen.dart';
import 'package:afrimarket/features/profile/presentation/screens/profile_screen.dart';
import 'package:afrimarket/features/cart/presentation/screens/cart_screen.dart';
import 'package:afrimarket/features/orders/presentation/screens/orders_list_screen.dart';
import 'package:afrimarket/features/marketplace/presentation/screens/search_screen.dart';
import 'package:afrimarket/features/marketplace/presentation/screens/favorites_screen.dart';
import 'package:afrimarket/features/notifications/presentation/screens/notifications_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    // Listen to both: stream provider (session restore) and notifier (login/logout actions)
    _ref.listen<AsyncValue<User?>>(authStateProvider, (_, __) {
      notifyListeners();
    });
    _ref.listen<AsyncValue<User?>>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  bool get isLoading => _ref.read(authStateProvider).isLoading;

  bool get isAuthenticated {
    // authNotifierProvider updates immediately on signIn/signOut actions
    final notifierUser = _ref.read(authNotifierProvider).value;
    if (notifierUser != null) return true;
    // authStateProvider covers restored sessions from storage
    return _ref.read(authStateProvider).value != null;
  }
}

// Routes that require a logged-in user
const _protectedPrefixes = [
  '/cart',
  '/order-summary',
  '/my-orders',
  '/profile',
  '/seller-dashboard',
  '/seller/add-product',
  '/become-seller',
  '/admin',
  '/favorites',
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

      // Splash always goes straight to home — guests can browse freely
      if (loc == '/splash') return '/home';

      // Authenticated users don't need to see login/signup
      if (isAuthenticated && isAuthPage) return '/home';

      // Protected routes redirect guests to login
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
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailScreen(productId: productId);
        },
      ),
      // Specific /seller/* routes MUST come before the parameterised /seller/:id
      // route, otherwise GoRouter treats "add-product" as a seller ID.
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
        builder: (context, state) {
          final sellerId = state.pathParameters['id']!;
          return SellerProfileScreen(sellerId: sellerId);
        },
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
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/order-summary',
        builder: (context, state) => const OrderSummaryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/my-orders',
        builder: (context, state) => const OrdersListScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
