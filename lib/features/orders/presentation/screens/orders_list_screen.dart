import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
import 'package:afrimarket/features/orders/domain/entities/order_entity.dart';
import 'package:afrimarket/features/orders/domain/entities/order_status.dart';
import 'package:afrimarket/features/orders/presentation/providers/order_provider.dart';

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(buyerOrdersProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(buyerOrdersProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                      child: const Icon(Icons.receipt_long_outlined,
                          size: 52, color: AppTheme.primaryGreen),
                    ),
                    const SizedBox(height: 24),
                    Text('No orders yet',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Text('Start shopping to place your first order',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: AppTheme.textSecondary),
                        textAlign: TextAlign.center),
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
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _OrderCard(order: orders[index]);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_outlined,
                  size: 48, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text('Could not load orders',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(buyerOrdersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(0, 8).toUpperCase()}',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(order.createdAt),
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const Divider(height: 20),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.productName} ×${item.quantity}',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                    Text(
                      '${item.subtotal.toStringAsFixed(0)} RWF',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              )),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              Text(order.formattedTotal,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.payment_outlined,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                order.paymentMethod.label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case OrderStatus.pending:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        break;
      case OrderStatus.confirmed:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        break;
      case OrderStatus.completed:
      case OrderStatus.delivered:
        bg = const Color(0xFFE8F5E9);
        fg = AppTheme.primaryGreen;
        break;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      default:
        bg = const Color(0xFFF5F5F5);
        fg = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status.label,
          style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
