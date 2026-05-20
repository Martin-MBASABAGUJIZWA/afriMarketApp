import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afrimarket/features/marketplace/domain/entities/product_entity.dart';
import 'package:afrimarket/core/theme/app_theme.dart';

class ProductCard extends StatefulWidget {
  final ProductEntity product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? AppTheme.primaryGreen.withOpacity(0.18)
                  : Colors.black.withOpacity(0.06),
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductImage(product: p),
                  _ProductInfo(
                    product: p,
                    onAddToCart: widget.onAddToCart,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final ProductEntity product;
  const _ProductImage({required this.product});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image or placeholder
          product.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppTheme.primaryGreen.withOpacity(0.06),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => _PlaceholderBox(),
                )
              : _PlaceholderBox(),

          // Featured badge
          if (product.isFeatured)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Featured',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Out of stock overlay
          if (!product.inStock)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Out of Stock',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryGreen.withOpacity(0.06),
      child: Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 40,
          color: AppTheme.primaryGreen.withOpacity(0.25),
        ),
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onAddToCart;

  const _ProductInfo({required this.product, this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            product.name,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (product.reviewCount > 0) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 13, color: Color(0xFFF9A825)),
                const SizedBox(width: 2),
                Text(
                  product.rating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '(${product.reviewCount})',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.formattedPrice(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    if (product.unit != 'each')
                      Text(
                        product.unit,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              if (onAddToCart != null && product.inStock)
                GestureDetector(
                  onTap: onAddToCart,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add,
                        size: 18, color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
