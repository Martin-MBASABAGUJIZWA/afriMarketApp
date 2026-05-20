import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
import 'package:afrimarket/core/utils/responsive.dart';
import 'package:afrimarket/core/widgets/product_card.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/features/seller/presentation/providers/seller_providers.dart';
import 'package:afrimarket/features/seller/domain/entities/seller_entity.dart';
import 'package:afrimarket/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:afrimarket/features/marketplace/presentation/providers/category_provider.dart';
import 'package:afrimarket/features/marketplace/domain/entities/product_entity.dart';
import 'package:afrimarket/features/cart/presentation/providers/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategoryId;

  Future<void> _refresh() async {
    ref.invalidate(sellersProvider);
    ref.invalidate(featuredProductsProvider);
    ref.invalidate(productsProvider(_selectedCategoryId));
    ref.invalidate(categoriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);
    final productsAsync = ref.watch(productsProvider(_selectedCategoryId));
    final sellersAsync = ref.watch(sellersProvider);

    final userName = currentUser.valueOrNull?.fullName.split(' ').first;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primaryGreen,
        child: CustomScrollView(
          slivers: [
            // ── Hero header ────────────────────────────────────────────
            if (r.isMobile)
              _MobileHeroHeader(
                userName: userName,
                cartCount: ref.watch(cartProvider).length,
              )
            else
              _DesktopHeroHeader(
                userName: userName,
                cartCount: ref.watch(cartProvider).length,
                r: r,
              ),

            // ── Category pills ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: _CategoryPills(
                async: categoriesAsync,
                selectedId: _selectedCategoryId,
                onSelect: (id) => setState(() => _selectedCategoryId = id),
                r: r,
              ),
            ),

            // ── Featured products (homepage only) ──────────────────────
            if (_selectedCategoryId == null)
              featuredAsync.when(
                data: (products) => products.isEmpty
                    ? const SliverToBoxAdapter(child: SizedBox.shrink())
                    : SliverToBoxAdapter(
                        child: _FeaturedRail(products: products, r: r),
                      ),
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

            // ── All / filtered products ────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: _selectedCategoryId == null
                    ? 'All Products'
                    : 'Products',
                onSeeAll: () => context.push('/search'),
                r: r,
              ),
            ),

            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return SliverToBoxAdapter(child: _EmptyProducts(r: r));
                }
                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: r.h),
                  sliver: SliverGrid(
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: r.productCols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final p = products[i];
                        return ProductCard(
                          product: p,
                          onTap: () => context.push('/product/${p.id}'),
                          onAddToCart: () => ref
                              .read(cartProvider.notifier)
                              .addItem(p),
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ── Sellers ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Top Sellers',
                r: r,
              ),
            ),

            sellersAsync.when(
              data: (sellers) {
                if (sellers.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptySellers(r: r),
                  );
                }
                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: r.h),
                  sliver: r.sellerCols > 1
                      ? SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: r.sellerCols,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 3.2,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _SellerTile(seller: sellers[i]),
                            childCount: sellers.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SellerTile(seller: sellers[i]),
                            ),
                            childCount: sellers.length,
                          ),
                        ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: r.h, vertical: 24),
                  child: _ErrorRetry(
                    message: 'Could not load sellers',
                    onRetry: () => ref.invalidate(sellersProvider),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: r.sectionGap + 16)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Hero headers
// ──────────────────────────────────────────────────────────

class _MobileHeroHeader extends ConsumerWidget {
  final String? userName;
  final int cartCount;

  const _MobileHeroHeader({this.userName, required this.cartCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authStateProvider).value != null ||
        ref.watch(authNotifierProvider).value != null;

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), AppTheme.primaryGreen],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName != null
                                ? 'Hello, $userName 👋'
                                : 'AfriMarket',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.white70, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                'Kigali · Local marketplace',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (isLoggedIn)
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 24),
                            onPressed: () =>
                                context.push('/notifications'),
                          ),
                        if (!isLoggedIn)
                          TextButton(
                            onPressed: () => context.push('/login'),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(
                              'Sign in',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SearchBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopHeroHeader extends ConsumerWidget {
  final String? userName;
  final int cartCount;
  final Responsive r;

  const _DesktopHeroHeader({
    this.userName,
    required this.cartCount,
    required this.r,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authStateProvider).value != null ||
        ref.watch(authNotifierProvider).value != null;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(r.h, 24, r.h, 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName != null
                            ? 'Good day, $userName 👋'
                            : 'Welcome to AfriMarket',
                        style: GoogleFonts.poppins(
                          fontSize: r.isWide ? 28 : 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Africa\'s premier local marketplace',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (isLoggedIn) ...[
                        _HeaderIconBtn(
                          icon: Icons.notifications_outlined,
                          onTap: () => context.push('/notifications'),
                        ),
                        const SizedBox(width: 8),
                        _HeaderIconBtn(
                          icon: Icons.storefront_outlined,
                          onTap: () => context.push('/seller-dashboard'),
                        ),
                      ] else
                        OutlinedButton(
                          onPressed: () => context.push('/login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                                color: Colors.white, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Sign in',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SearchBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/search'),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFFBDBDBD), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search products, sellers...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFFBDBDBD),
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Search',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Category pills
// ──────────────────────────────────────────────────────────

class _CategoryPills extends StatelessWidget {
  final AsyncValue async;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final Responsive r;

  const _CategoryPills({
    required this.async,
    required this.selectedId,
    required this.onSelect,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: async.when(
        data: (categories) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: r.h, vertical: 10),
          itemCount: categories.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final cat = isAll ? null : categories[index - 1];
            final isSelected =
                isAll ? selectedId == null : cat!.id == selectedId;
            return GestureDetector(
              onTap: () => onSelect(isAll ? null : cat!.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : const Color(0xFFE0E0E0),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                AppTheme.primaryGreen.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAll ? '🛒' : (cat!.icon ?? '🛒'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAll ? 'All' : cat!.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Featured products horizontal rail
// ──────────────────────────────────────────────────────────

class _FeaturedRail extends StatelessWidget {
  final List<ProductEntity> products;
  final Responsive r;

  const _FeaturedRail({required this.products, required this.r});

  @override
  Widget build(BuildContext context) {
    final cardWidth = r.isDesktop ? 200.0 : 160.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Featured', onSeeAll: () => context.push('/search'), r: r),
        SizedBox(
          height: cardWidth * 1.35,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: r.h),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = products[i];
              return SizedBox(
                width: cardWidth,
                child: ProductCard(
                  product: p,
                  onTap: () => context.push('/product/${p.id}'),
                  onAddToCart: null,
                ),
              );
            },
          ),
        ),
        SizedBox(height: r.sectionGap),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Section header
// ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final Responsive r;

  const _SectionHeader({
    required this.title,
    this.onSeeAll,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(r.h, r.sectionGap, r.h, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: r.isDesktop ? 20 : 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
              ),
              child: Text(
                'See all',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Seller tile
// ──────────────────────────────────────────────────────────

class _SellerTile extends StatelessWidget {
  final SellerEntity seller;
  const _SellerTile({required this.seller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/seller/${seller.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: seller.logoUrl != null && seller.logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: seller.logoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Center(
                          child: Text(seller.categoryIcon,
                              style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(seller.categoryIcon,
                          style: const TextStyle(fontSize: 26)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          seller.businessName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (seller.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 14, color: AppTheme.primaryGreen),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFFF9A825)),
                      const SizedBox(width: 2),
                      Text(
                        seller.ratingLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${seller.category} · ${seller.location}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: seller.isOpen
                    ? const Color(0xFFE8F5E9)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                seller.isOpen ? 'Open' : 'Closed',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color:
                      seller.isOpen ? AppTheme.primaryGreen : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Empty / error states
// ──────────────────────────────────────────────────────────

class _EmptyProducts extends StatelessWidget {
  final Responsive r;
  const _EmptyProducts({required this.r});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.h, vertical: 40),
      child: Column(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No products in this category',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySellers extends StatelessWidget {
  final Responsive r;
  const _EmptySellers({required this.r});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.h, vertical: 32),
      child: Column(
        children: [
          const Text('🏪', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No sellers yet — be the first!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/become-seller'),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Become a Seller'),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.wifi_off_outlined,
            size: 40, color: AppTheme.textSecondary),
        const SizedBox(height: 12),
        Text(message,
            style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
