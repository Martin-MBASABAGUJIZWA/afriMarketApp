import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
import 'package:afrimarket/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:afrimarket/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:afrimarket/core/widgets/product_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          'My Favorites',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: favoriteIds.isEmpty
          ? _EmptyFavorites()
          : _FavoritesList(favoriteIds: favoriteIds),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border, size: 50, color: Colors.red),
          ),
          const SizedBox(height: 20),
          Text(
            'No favorites yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart on any product to save it here',
            style: GoogleFonts.poppins(
                fontSize: 14, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.storefront),
            label: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }
}

class _FavoritesList extends ConsumerWidget {
  final Set<String> favoriteIds;
  const _FavoritesList({required this.favoriteIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: favoriteIds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final productId = favoriteIds.elementAt(i);
        final productAsync = ref.watch(productDetailProvider(productId));
        return productAsync.when(
          data: (product) {
            if (product == null) return const SizedBox.shrink();
            return Stack(
              children: [
                ProductCard(
                  product: product,
                  onTap: () => context.push('/product/$productId'),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(favoritesProvider.notifier).toggle(productId),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite,
                          size: 18, color: Colors.red),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }
}
