import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
import 'package:afrimarket/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:afrimarket/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:afrimarket/features/cart/presentation/providers/cart_provider.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/features/seller/presentation/providers/seller_providers.dart';

class SellerProfileScreen extends ConsumerWidget {
  final String sellerId;

  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(sellerByIdProvider(sellerId));
    final productsAsync = ref.watch(sellerProductsProvider(sellerId));

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: sellerAsync.when(
        data: (seller) {
          if (seller == null) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              ),
              body: const Center(child: Text('Seller not found')),
            );
          }

          final productCount = productsAsync.value?.length ?? 0;

          return RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: () async {
              ref.invalidate(sellerByIdProvider(sellerId));
              ref.invalidate(sellerProductsProvider(sellerId));
            },
            child: CustomScrollView(
              slivers: [
                // ── Hero Header ──────────────────────────────
                SliverToBoxAdapter(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Green banner
                      Container(
                        height: 200,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white, size: 26),
                                  onPressed: () => context.pop(),
                                ),
                                Row(
                                  children: [
                                    // Share button
                                    IconButton(
                                      icon: const Icon(Icons.share_outlined,
                                          color: Colors.white, size: 22),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content:
                                              Text('Share link copied!'),
                                          backgroundColor:
                                              AppTheme.primaryGreen,
                                          duration: Duration(seconds: 2),
                                        ));
                                      },
                                    ),
                                    // Open/Closed badge in header
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: seller.isOpen
                                            ? Colors.white
                                            : Colors.red.shade400,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: seller.isOpen
                                                  ? AppTheme.primaryGreen
                                                  : Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            seller.isOpen
                                                ? 'Open Now'
                                                : 'Closed',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: seller.isOpen
                                                  ? AppTheme.primaryGreen
                                                  : Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Seller logo overlapping banner
                      Positioned(
                        top: 140,
                        left: 24,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(22),
                            border:
                                Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(seller.categoryIcon,
                                style: const TextStyle(fontSize: 44)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Seller Info ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 64, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + verified
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                seller.businessName,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (seller.isVerified)
                              const Icon(Icons.verified,
                                  color: AppTheme.primaryGreen, size: 22),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Category + Location
                        Row(
                          children: [
                            const Icon(Icons.storefront_outlined,
                                size: 14, color: AppTheme.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              seller.category,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppTheme.textTertiary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                seller.location,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (seller.description != null &&
                            seller.description!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            seller.description!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (seller.isVerified)
                              _Badge(
                                label: '✓ Verified',
                                color: AppTheme.successGreen,
                                bg: const Color(0xFFE8F5E9),
                              ),
                            _Badge(
                              label: '📱 MoMo Ready',
                              color: const Color(0xFF1565C0),
                              bg: const Color(0xFFE3F2FD),
                            ),
                            _Badge(
                              label: '${seller.category}',
                              color: AppTheme.accentOrange,
                              bg: const Color(0xFFFFF3E0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.star,
                                iconColor: const Color(0xFFF9A825),
                                value: seller.ratingLabel,
                                label: 'Rating',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.shopping_bag_outlined,
                                iconColor: AppTheme.accentOrange,
                                value: '${seller.totalSales}',
                                label: 'Sales',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.inventory_2_outlined,
                                iconColor: AppTheme.primaryGreen,
                                value: '$productCount',
                                label: 'Products',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Phone Row
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: seller.phone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Phone number copied!'),
                                backgroundColor: AppTheme.primaryGreen,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFE0E0E0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.phone_outlined,
                                      color: AppTheme.primaryGreen, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Phone / WhatsApp',
                                          style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: AppTheme.textTertiary)),
                                      Text(seller.phone,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          )),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.copy_outlined,
                                    size: 18, color: AppTheme.textTertiary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Products header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Products',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (productCount > 0)
                              Text(
                                '$productCount available',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // ── Products Grid ────────────────────────────
                productsAsync.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5F5F5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 40,
                                    color: AppTheme.textTertiary),
                              ),
                              const SizedBox(height: 16),
                              Text('No products yet',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary)),
                              const SizedBox(height: 6),
                              Text('This seller hasn\'t listed products yet',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppTheme.textTertiary),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ProductCard(
                              product: products[index]),
                          childCount: products.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.wifi_off_outlined,
                                size: 48, color: AppTheme.textTertiary),
                            const SizedBox(height: 12),
                            Text('Could not load products',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => ref
                                  .invalidate(sellerProductsProvider(sellerId)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          ),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(child: Text('Error: $e')),
        ),
      ),
      // ── Bottom Action Bar ─────────────────────────────────
      bottomNavigationBar: sellerAsync.value == null
          ? null
          : _BottomBar(seller: sellerAsync.value!),
    );
  }
}

// ── Bottom Action Bar ───────────────────────────────────────
class _BottomBar extends ConsumerWidget {
  final dynamic seller;
  const _BottomBar({required this.seller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authStateProvider).value != null ||
        ref.watch(authNotifierProvider).value != null;
    final cartCount = ref.watch(cartProvider.notifier).itemCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Chat / Contact button
            _ActionButton(
              icon: Icons.chat_bubble_outline,
              tooltip: 'Contact seller',
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => _ContactSheet(seller: seller),
                );
              },
            ),
            const SizedBox(width: 10),
            // View Cart button if items in cart
            if (cartCount > 0) ...[
              _ActionButton(
                icon: Icons.shopping_cart_outlined,
                tooltip: 'View cart',
                badge: cartCount,
                onTap: () => context.push('/cart'),
              ),
              const SizedBox(width: 10),
            ],
            // Main CTA
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (!isLoggedIn) {
                    context.push('/login');
                    return;
                  }
                  // Go to cart to place the order
                  context.push('/cart');
                },
                icon: const Text('📱', style: TextStyle(fontSize: 18)),
                label: Text(
                  'Order & Pay via MoMo',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badge;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                child: Icon(icon, size: 24, color: AppTheme.textPrimary),
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppTheme.accentOrange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$badge',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Contact Sheet ───────────────────────────────────────────
class _ContactSheet extends StatelessWidget {
  final dynamic seller;
  const _ContactSheet({required this.seller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Contact ${seller.businessName}',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          _ContactTile(
            icon: Icons.phone_outlined,
            color: AppTheme.primaryGreen,
            title: 'Call Seller',
            subtitle: seller.phone as String,
            onTap: () {
              Clipboard.setData(ClipboardData(text: seller.phone as String));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Phone number copied to clipboard'),
                backgroundColor: AppTheme.primaryGreen,
              ));
            },
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.chat_outlined,
            color: const Color(0xFF25D366),
            title: 'WhatsApp',
            subtitle: 'Chat on WhatsApp',
            onTap: () {
              Clipboard.setData(ClipboardData(text: seller.phone as String));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Number copied — open WhatsApp to chat'),
                backgroundColor: AppTheme.primaryGreen,
              ));
            },
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.location_on_outlined,
            color: AppTheme.accentOrange,
            title: 'Visit Shop',
            subtitle: seller.location as String,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20, color: color.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final dynamic product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref
        .watch(favoritesProvider.select((s) => s.contains(product.id as String)));

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image / emoji
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: (product.imageUrls as List).isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Image.network(
                                (product.imageUrls as List).first as String,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => Text(
                                  _emoji(product.name as String),
                                  style: const TextStyle(fontSize: 52),
                                ),
                              ),
                            )
                          : Text(
                              _emoji(product.name as String),
                              style: const TextStyle(fontSize: 52),
                            ),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(product.id as String),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 17,
                          color: isFav ? Colors.red : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  // Stock badge
                  if (!(product.inStock as bool))
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Out of stock',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name as String,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.formattedPrice(),
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryGreen),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref.read(cartProvider.notifier).addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${product.name} added to cart'),
                            backgroundColor: AppTheme.successGreen,
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'View',
                              textColor: Colors.white,
                              onPressed: () => context.push('/cart'),
                            ),
                          ));
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('avocado')) return '🥑';
    if (n.contains('tomato')) return '🍅';
    if (n.contains('maize') || n.contains('corn')) return '🌽';
    if (n.contains('cabbage')) return '🥬';
    if (n.contains('banana')) return '🍌';
    if (n.contains('carrot')) return '🥕';
    if (n.contains('potato')) return '🥔';
    if (n.contains('cloth') || n.contains('dress') || n.contains('shirt')) {
      return '👗';
    }
    if (n.contains('phone') || n.contains('electronic')) return '📱';
    if (n.contains('tool') || n.contains('hardware')) return '🔧';
    return '🛒';
  }
}
