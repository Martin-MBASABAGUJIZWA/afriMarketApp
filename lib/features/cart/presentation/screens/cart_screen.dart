import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
import 'package:afrimarket/core/utils/responsive.dart';
import 'package:afrimarket/features/cart/presentation/providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final r = Responsive.of(context);

    if (r.isDesktop) {
      return _DesktopCart(items: items, cartNotifier: cartNotifier);
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          items.isEmpty ? 'Shopping Cart' : 'Cart (${cartNotifier.itemCount} items)',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryGreen,
        actions: items.isNotEmpty
            ? [
                TextButton(
                  onPressed: () => _confirmClear(context, ref),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ]
            : null,
      ),
      body: items.isEmpty ? const _EmptyCart() : _CartList(items: items),
      bottomNavigationBar: items.isEmpty
          ? null
          : _CartSummaryBar(total: cartNotifier.totalPrice, onCheckout: () => context.push('/order-summary')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop: side-by-side items + order summary
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopCart extends ConsumerWidget {
  final List<CartItem> items;
  final CartNotifier cartNotifier;

  const _DesktopCart({required this.items, required this.cartNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = Responsive.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppTheme.textPrimary,
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Shopping Cart',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            if (items.isNotEmpty)
              Text(
                '${cartNotifier.itemCount} items',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
              ),
          ],
        ),
        actions: items.isNotEmpty
            ? [
                TextButton.icon(
                  onPressed: () => _confirmClear(context, ref),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: Text('Clear cart', style: GoogleFonts.poppins(fontSize: 13, color: Colors.red)),
                ),
                const SizedBox(width: 8),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE9ECEF)),
        ),
      ),
      body: items.isEmpty
          ? const _EmptyCart()
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.all(r.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cart items
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Items',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _DesktopCartItem(item: item),
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Order summary panel
                        SizedBox(
                          width: r.isWide ? 380 : 340,
                          child: _DesktopOrderSummary(
                            items: items,
                            total: cartNotifier.totalPrice,
                            onCheckout: () => context.push('/order-summary'),
                          ),
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

class _DesktopCartItem extends ConsumerWidget {
  final CartItem item;
  const _DesktopCartItem({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Product icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(_getProductEmoji(item.product.name), style: const TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(width: 20),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.product.formattedPrice(),
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: ${item.totalPrice.toStringAsFixed(0)} RWF',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Quantity controls
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE9ECEF)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: () => ref.read(cartProvider.notifier).decreaseQuantity(item.product.id),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '${item.quantity}',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onTap: () => ref.read(cartProvider.notifier).increaseQuantity(item.product.id),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Remove
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.red.shade400,
            tooltip: 'Remove',
            onPressed: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: AppTheme.primaryGreen),
      ),
    );
  }
}

class _DesktopOrderSummary extends StatelessWidget {
  final List<CartItem> items;
  final double total;
  final VoidCallback onCheckout;

  const _DesktopOrderSummary({
    required this.items,
    required this.total,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = total;
    const deliveryFee = 0.0;
    final grandTotal = subtotal + deliveryFee;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Order Summary',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // Line items
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.product.name} × ${item.quantity}',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${item.totalPrice.toStringAsFixed(0)} RWF',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ],
            ),
          )),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                Text('${subtotal.toStringAsFixed(0)} RWF', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                Text(
                  deliveryFee == 0 ? 'Free' : '${deliveryFee.toStringAsFixed(0)} RWF',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: deliveryFee == 0 ? AppTheme.primaryGreen : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text(
                  '${grandTotal.toStringAsFixed(0)} RWF',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Proceed to Checkout',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          // Secure note
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'Secure checkout',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CartList extends ConsumerWidget {
  final List<CartItem> items;

  const _CartList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getProductEmoji(item.product.name),
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.product.formattedPrice(),
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
                      ),
                      Text(
                        'Subtotal: ${item.totalPrice.toStringAsFixed(0)} RWF',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 24),
                          onPressed: () => ref.read(cartProvider.notifier).decreaseQuantity(item.product.id),
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${item.quantity}',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 24),
                          onPressed: () => ref.read(cartProvider.notifier).increaseQuantity(item.product.id),
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
                      child: Text('Remove', style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  final double total;
  final VoidCallback onCheckout;

  const _CartSummaryBar({required this.total, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                Text(
                  '${total.toStringAsFixed(0)} RWF',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text('Proceed to Checkout', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.shopping_cart_outlined, size: 60, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Browse products and add them to your cart',
              style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Browse Products'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

void _confirmClear(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Clear Cart'),
      content: const Text('Remove all items from your cart?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            ref.read(cartProvider.notifier).clearAll();
            Navigator.pop(ctx);
          },
          child: const Text('Clear', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

String _getProductEmoji(String name) {
  final n = name.toLowerCase();
  if (n.contains('avocado')) return '🥑';
  if (n.contains('tomato')) return '🍅';
  if (n.contains('maize') || n.contains('corn')) return '🌽';
  if (n.contains('cabbage')) return '🥬';
  if (n.contains('banana')) return '🍌';
  if (n.contains('carrot')) return '🥕';
  if (n.contains('potato')) return '🥔';
  if (n.contains('onion')) return '🧅';
  return '🛒';
}
