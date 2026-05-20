import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
import 'package:afrimarket/core/utils/responsive.dart';
import 'package:afrimarket/features/seller/presentation/providers/seller_providers.dart';
import 'package:afrimarket/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:afrimarket/features/orders/presentation/providers/order_provider.dart';
import 'package:afrimarket/features/orders/domain/entities/order_entity.dart';
import 'package:afrimarket/features/orders/domain/entities/order_status.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root Screen
// ─────────────────────────────────────────────────────────────────────────────

class SellerDashboardScreen extends ConsumerStatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  ConsumerState<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final sellerAsync = ref.watch(currentUserSellerProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: sellerAsync.when(
        data: (seller) {
          if (seller == null) {
            return _NoSellerView(onBecomeSeller: () => context.push('/become-seller'));
          }
          return _DashboardBody(
            seller: seller,
            selectedTab: _selectedTab,
            onTabChanged: (i) => setState(() => _selectedTab = i),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Body — branches desktop vs mobile
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  final dynamic seller;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const _DashboardBody({
    required this.seller,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = Responsive.of(context);
    if (r.showSidebar) {
      return _DesktopDashboard(seller: seller);
    }
    return _MobileDashboard(seller: seller, onTabChanged: onTabChanged);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopDashboard extends ConsumerWidget {
  final dynamic seller;
  const _DesktopDashboard({required this.seller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(sellerProductsProvider(seller.id));
    final analytics = ref.watch(sellerAnalyticsProvider);
    final ordersAsync = ref.watch(sellerOrdersProvider);
    final r = Responsive.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: _DesktopAppBar(seller: seller, ref: ref),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.isWide ? 1440 : 1240),
            child: Padding(
              padding: EdgeInsets.all(r.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Left Sidebar ──────────────────────────────────────────
                  SizedBox(
                    width: r.isWide ? 300 : 260,
                    child: Column(
                      children: [
                        _ShopInfoCard(seller: seller, ref: ref),
                        const SizedBox(height: 16),
                        _SidebarActionsCard(seller: seller),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // ── Main Content ──────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _KpiGrid(analytics: analytics, seller: seller),
                        const SizedBox(height: 24),
                        _DesktopProductsCard(
                          productsAsync: productsAsync,
                          sellerId: seller.id,
                        ),
                        const SizedBox(height: 24),
                        _DesktopOrdersCard(ordersAsync: ordersAsync),
                        const SizedBox(height: 32),
                      ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Desktop AppBar
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic seller;
  final WidgetRef ref;
  const _DesktopAppBar({required this.seller, required this.ref});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        color: AppTheme.textPrimary,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Seller Dashboard',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            seller.businessName,
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
      actions: [
        // Open/Closed toggle
        GestureDetector(
          onTap: () async {
            final ds = ref.read(sellerDataSourceProvider);
            await ds.updateSeller(sellerId: seller.id, isOpen: !seller.isOpen);
            ref.invalidate(currentUserSellerProvider);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: seller.isOpen ? const Color(0xFFE8F5E9) : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: seller.isOpen ? AppTheme.primaryGreen : Colors.red.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: seller.isOpen ? AppTheme.primaryGreen : Colors.red,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  seller.isOpen ? 'Open' : 'Closed',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: seller.isOpen ? AppTheme.primaryGreen : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: AppTheme.textSecondary,
          onPressed: () => context.push('/notifications'),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/seller/add-product'),
            icon: const Icon(Icons.add, size: 16),
            label: Text('Add Product', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE9ECEF)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Left Sidebar — Shop Info Card
// ─────────────────────────────────────────────────────────────────────────────

class _ShopInfoCard extends StatelessWidget {
  final dynamic seller;
  final WidgetRef ref;
  const _ShopInfoCard({required this.seller, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    seller.businessName.isNotEmpty ? seller.businessName[0].toUpperCase() : 'S',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.businessName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      seller.category,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.location_on_outlined, text: seller.location),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.phone_outlined, text: seller.phone),
          if (seller.isVerified) ...[
            const SizedBox(height: 8),
            const _InfoRow(icon: Icons.verified_outlined, text: 'Verified Seller', iconColor: AppTheme.primaryGreen),
          ],
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _ShopStat(label: 'Rating', value: seller.ratingLabel),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE9ECEF)),
              Expanded(
                child: _ShopStat(label: 'Sales', value: '${seller.totalSales}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  const _InfoRow({required this.icon, required this.text, this.iconColor = AppTheme.textTertiary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ShopStat extends StatelessWidget {
  final String label;
  final String value;
  const _ShopStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar Quick Actions
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarActionsCard extends StatelessWidget {
  final dynamic seller;
  const _SidebarActionsCard({required this.seller});

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'QUICK ACTIONS',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _SidebarAction(
            icon: Icons.add_box_outlined,
            label: 'Add Product',
            color: AppTheme.primaryGreen,
            onTap: () => context.push('/seller/add-product'),
          ),
          _SidebarAction(
            icon: Icons.inventory_2_outlined,
            label: 'View Inventory',
            color: AppTheme.accentOrange,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _InventorySheet(sellerId: seller.id),
            ),
          ),
          _SidebarAction(
            icon: Icons.bar_chart_rounded,
            label: 'Full Analytics',
            color: const Color(0xFF1E88E5),
            onTap: () {
              final analytics = ProviderScope.containerOf(context).read(sellerAnalyticsProvider);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _AnalyticsSheet(seller: seller, analytics: analytics),
              );
            },
          ),
          _SidebarAction(
            icon: Icons.edit_outlined,
            label: 'Edit Shop Info',
            color: const Color(0xFF9C27B0),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _EditShopSheet(seller: seller),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SidebarAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  State<_SidebarAction> createState() => _SidebarActionState();
}

class _SidebarActionState extends State<_SidebarAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, size: 16, color: widget.color),
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI Grid — 4 metric cards
// ─────────────────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final dynamic seller;
  const _KpiGrid({required this.analytics, required this.seller});

  @override
  Widget build(BuildContext context) {
    final revenue = (analytics['totalRevenue'] as double?) ?? 0.0;
    final totalOrders = (analytics['totalOrders'] as int?) ?? 0;
    final pendingOrders = (analytics['pendingOrders'] as int?) ?? 0;

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Total Revenue',
            value: '${revenue.toStringAsFixed(0)} RWF',
            icon: Icons.account_balance_wallet_outlined,
            color: AppTheme.primaryGreen,
            sub: 'All time',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KpiCard(
            label: 'Total Orders',
            value: '$totalOrders',
            icon: Icons.shopping_bag_outlined,
            color: AppTheme.accentOrange,
            sub: 'All time',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KpiCard(
            label: 'Pending',
            value: '$pendingOrders',
            icon: Icons.pending_actions_outlined,
            color: const Color(0xFF1E88E5),
            sub: 'Awaiting action',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KpiCard(
            label: 'Avg. Rating',
            value: seller.ratingLabel,
            icon: Icons.star_outline_rounded,
            color: const Color(0xFFF9A825),
            sub: 'out of 5.0',
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String sub;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Text(
                sub,
                style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Products Card — table-style
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopProductsCard extends ConsumerWidget {
  final AsyncValue<List<dynamic>> productsAsync;
  final String sellerId;
  const _DesktopProductsCard({required this.productsAsync, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Products',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    productsAsync.when(
                      data: (p) => Text(
                        '${p.length} listings',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/seller/add-product'),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Add New', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFFF8F9FA),
            child: Row(
              children: [
                const SizedBox(width: 56),
                Expanded(
                  flex: 4,
                  child: Text('PRODUCT', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('PRICE', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('STOCK', style: _tableHeaderStyle),
                ),
                SizedBox(
                  width: 80,
                  child: Text('STATUS', style: _tableHeaderStyle),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Rows
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return _EmptyProductsState(onAddProduct: () => context.push('/seller/add-product'));
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, i) {
                  final product = products[i];
                  return _DesktopProductRow(
                    product: product,
                    onEdit: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _EditProductSheet(product: product, sellerId: sellerId),
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('Error loading products', style: GoogleFonts.poppins(color: AppTheme.textSecondary))),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  TextStyle get _tableHeaderStyle => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppTheme.textTertiary,
    letterSpacing: 1.0,
  );
}

class _DesktopProductRow extends StatefulWidget {
  final dynamic product;
  final VoidCallback onEdit;
  const _DesktopProductRow({required this.product, required this.onEdit});

  @override
  State<_DesktopProductRow> createState() => _DesktopProductRowState();
}

class _DesktopProductRowState extends State<_DesktopProductRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final inStock = widget.product.inStock as bool;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered ? const Color(0xFFF8F9FA) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGreen, size: 22),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.product.category != null)
                    Text(
                      widget.product.category,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
                    ),
                ],
              ),
            ),
            // Price
            Expanded(
              flex: 2,
              child: Text(
                widget.product.formattedPrice(),
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
              ),
            ),
            // Stock
            Expanded(
              flex: 2,
              child: Text(
                '${widget.product.stockQuantity} units',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: widget.product.stockQuantity < 5 ? Colors.orange : AppTheme.textSecondary,
                  fontWeight: widget.product.stockQuantity < 5 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            // Status badge
            SizedBox(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: inStock ? const Color(0xFFE8F5E9) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  inStock ? 'In Stock' : 'Out',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: inStock ? AppTheme.primaryGreen : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Edit button
            SizedBox(
              width: 48,
              child: IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: widget.onEdit,
                color: AppTheme.textSecondary,
                tooltip: 'Edit product',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Recent Orders Card
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopOrdersCard extends StatelessWidget {
  final AsyncValue<List<OrderEntity>> ordersAsync;
  const _DesktopOrdersCard({required this.ordersAsync});

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Orders',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/my-orders'),
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFFF8F9FA),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('ORDER ID', style: _headerStyle)),
                Expanded(flex: 2, child: Text('DATE', style: _headerStyle)),
                Expanded(flex: 3, child: Text('AMOUNT', style: _headerStyle)),
                Expanded(flex: 2, child: Text('STATUS', style: _headerStyle)),
              ],
            ),
          ),
          ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.textTertiary),
                        const SizedBox(height: 12),
                        Text(
                          'No orders yet',
                          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final recent = orders.take(8).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, i) => _DesktopOrderRow(order: recent[i]),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppTheme.textTertiary,
    letterSpacing: 1.0,
  );
}

class _DesktopOrderRow extends StatefulWidget {
  final OrderEntity order;
  const _DesktopOrderRow({required this.order});

  @override
  State<_DesktopOrderRow> createState() => _DesktopOrderRowState();
}

class _DesktopOrderRowState extends State<_DesktopOrderRow> {
  bool _hovered = false;

  static Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.confirmed: return const Color(0xFF1E88E5);
      case OrderStatus.completed:
      case OrderStatus.delivered: return AppTheme.primaryGreen;
      case OrderStatus.cancelled:
      case OrderStatus.refunded: return Colors.red;
      default: return AppTheme.accentOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.order.id.substring(0, 8).toUpperCase();
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateLabel = '${widget.order.createdAt.day} ${months[widget.order.createdAt.month]}';
    final statusColor = _statusColor(widget.order.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered ? const Color(0xFFF8F9FA) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '#$orderId',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                dateLabel,
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.order.formattedTotal,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.order.status.label,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Dashboard — original layout preserved
// ─────────────────────────────────────────────────────────────────────────────

class _MobileDashboard extends ConsumerWidget {
  final dynamic seller;
  final ValueChanged<int> onTabChanged;

  const _MobileDashboard({required this.seller, required this.onTabChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(sellerProductsProvider(seller.id));
    final analytics = ref.watch(sellerAnalyticsProvider);
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return CustomScrollView(
      slivers: [
        // Green Header
        SliverToBoxAdapter(
          child: Container(
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                              'Seller Dashboard',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              seller.businessName,
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final ds = ref.read(sellerDataSourceProvider);
                                await ds.updateSeller(sellerId: seller.id, isOpen: !seller.isOpen);
                                ref.invalidate(currentUserSellerProvider);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: seller.isOpen ? Colors.white : Colors.red.shade300,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: seller.isOpen ? AppTheme.primaryGreen : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      seller.isOpen ? 'Open' : 'Closed',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: seller.isOpen ? AppTheme.primaryGreen : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                              onPressed: () => context.push('/notifications'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _StatChip(label: 'Rating', value: seller.ratingLabel, icon: '⭐'),
                        const SizedBox(width: 12),
                        _StatChip(label: 'Sales', value: '${seller.totalSales}', icon: '📦'),
                        const SizedBox(width: 12),
                        if (seller.isVerified)
                          const _StatChip(label: 'Verified', value: '✓', icon: '🛡️'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Earnings Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Overview',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _EarningsCard(
                        label: 'Total Revenue',
                        value: '${((analytics['totalRevenue'] as double?) ?? 0.0).toStringAsFixed(0)} RWF',
                        icon: Icons.account_balance_wallet,
                        color: AppTheme.primaryGreen,
                        trend: 'All time',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _EarningsCard(
                        label: 'Total Orders',
                        value: '${analytics['totalOrders']}',
                        icon: Icons.shopping_bag,
                        color: AppTheme.accentOrange,
                        trend: 'All time',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _EarningsCard(
                        label: 'Pending',
                        value: '${analytics['pendingOrders']}',
                        icon: Icons.pending_actions,
                        color: const Color(0xFF1E88E5),
                        trend: 'Active',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _EarningsCard(
                        label: 'Avg. Rating',
                        value: seller.ratingLabel,
                        icon: Icons.star,
                        color: const Color(0xFFF9A825),
                        trend: 'of 5.0',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Quick Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_box,
                        label: 'Add Product',
                        color: AppTheme.primaryGreen,
                        onTap: () => context.push('/seller/add-product'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.inventory_2,
                        label: 'Inventory',
                        color: AppTheme.accentOrange,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _InventorySheet(sellerId: seller.id),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.bar_chart,
                        label: 'Analytics',
                        color: const Color(0xFF1E88E5),
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _AnalyticsSheet(seller: seller, analytics: analytics),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.edit,
                        label: 'Edit Shop',
                        color: const Color(0xFF9C27B0),
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _EditShopSheet(seller: seller),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Products Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Products',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/seller/add-product'),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Add New', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),

        productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return SliverToBoxAdapter(
                child: _EmptyProductsState(onAddProduct: () => context.push('/seller/add-product')),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _ProductListItem(
                      product: product,
                      onEdit: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _EditProductSheet(product: product, sellerId: seller.id),
                      ),
                    ),
                  );
                },
                childCount: products.length,
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            ),
          ),
          error: (e, _) => const SliverToBoxAdapter(
            child: Center(child: Text('Error loading products')),
          ),
        ),

        // Recent Orders Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Recent Orders',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ),
        ),

        ordersAsync.when(
          data: (orders) {
            final recent = orders.take(5).toList();
            if (recent.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textTertiary),
                        const SizedBox(height: 12),
                        Text('No orders yet',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Orders will appear here when buyers place them',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textTertiary),
                          textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= recent.length) return null;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _RealOrderListItem(order: recent[index]),
                  );
                },
                childCount: recent.length,
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            ),
          ),
          error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets (used by mobile layout)
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(label,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _EarningsCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(trend,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final dynamic product;
  final VoidCallback onEdit;

  const _ProductListItem({required this.product, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(product.formattedPrice(),
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                const SizedBox(height: 4),
                Text('Stock: ${product.stockQuantity}',
                  style: GoogleFonts.poppins(fontSize: 12, color: product.inStock ? AppTheme.textSecondary : Colors.red)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                color: AppTheme.primaryGreen,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: product.inStock ? const Color(0xFFE8F5E9) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.inStock ? 'In Stock' : 'Out',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: product.inStock ? AppTheme.primaryGreen : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RealOrderListItem extends StatelessWidget {
  final OrderEntity order;

  const _RealOrderListItem({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderId = order.id.substring(0, 8).toUpperCase();

    Color statusColor;
    switch (order.status) {
      case OrderStatus.confirmed: statusColor = const Color(0xFF1E88E5); break;
      case OrderStatus.completed:
      case OrderStatus.delivered: statusColor = AppTheme.primaryGreen; break;
      case OrderStatus.cancelled:
      case OrderStatus.refunded: statusColor = Colors.red; break;
      default: statusColor = AppTheme.accentOrange;
    }

    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateLabel = '${order.createdAt.day} ${months[order.createdAt.month]}';

    return Container(
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
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_outlined, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #$orderId',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text(dateLabel,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(order.formattedTotal,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.label,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  final VoidCallback onAddProduct;

  const _EmptyProductsState({required this.onAddProduct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 20),
          Text('No products yet',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Add your first product to start selling',
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddProduct,
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Shop Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditShopSheet extends ConsumerStatefulWidget {
  final dynamic seller;
  const _EditShopSheet({required this.seller});

  @override
  ConsumerState<_EditShopSheet> createState() => _EditShopSheetState();
}

class _EditShopSheetState extends ConsumerState<_EditShopSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _categoryCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.seller.businessName);
    _descCtrl = TextEditingController(text: widget.seller.description ?? '');
    _locationCtrl = TextEditingController(text: widget.seller.location);
    _phoneCtrl = TextEditingController(text: widget.seller.phone);
    _categoryCtrl = TextEditingController(text: widget.seller.category);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose();
    _locationCtrl.dispose(); _phoneCtrl.dispose(); _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final ds = ref.read(sellerDataSourceProvider);
      await ds.updateSeller(
        sellerId: widget.seller.id,
        businessName: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
      );
      ref.invalidate(currentUserSellerProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Shop updated!', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Edit Shop', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Business Name *', prefixIcon: Icon(Icons.storefront_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category *', prefixIcon: Icon(Icons.category_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location *', prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone *', prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save Changes', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Product Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditProductSheet extends ConsumerStatefulWidget {
  final dynamic product;
  final String sellerId;
  const _EditProductSheet({required this.product, required this.sellerId});

  @override
  ConsumerState<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends ConsumerState<_EditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _priceCtrl = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _stockCtrl = TextEditingController(text: '${widget.product.stockQuantity}');
    _descCtrl = TextEditingController(text: widget.product.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _stockCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final desc = _descCtrl.text.trim();
      await ref.read(marketplaceRepositoryProvider).updateProduct(
        productId: widget.product.id,
        name: _nameCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        stockQuantity: int.parse(_stockCtrl.text.trim()),
        description: desc.isEmpty ? null : desc,
      );
      ref.invalidate(sellerProductsProvider(widget.sellerId));
      ref.invalidate(featuredProductsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Product updated!', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Edit Product', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Product Name *', prefixIcon: Icon(Icons.label_outline)),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (RWF) *', prefixIcon: Icon(Icons.attach_money)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock *'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Update Product', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inventory Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _InventorySheet extends ConsumerWidget {
  final String sellerId;
  const _InventorySheet({required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(sellerProductsProvider(sellerId));
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Inventory', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              productsAsync.when(
                data: (p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text('${p.length} items', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 56, color: AppTheme.textTertiary),
                        const SizedBox(height: 12),
                        Text('No products yet', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }
                final lowStock = products.where((p) => p.stockQuantity < 5).length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lowStock > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text('$lowStock product(s) running low on stock',
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final p = products[i];
                          final stock = p.stockQuantity;
                          final isLow = stock < 5;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isLow ? Colors.orange.shade50 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isLow ? Colors.orange.shade200 : Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: isLow ? Colors.orange.shade100 : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.inventory_2_outlined,
                                    color: isLow ? Colors.orange.shade700 : AppTheme.primaryGreen, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name,
                                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('${p.price.toStringAsFixed(0)} RWF',
                                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isLow ? Colors.red.shade50 : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    stock > 0 ? 'Qty: $stock' : 'Out of Stock',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12, fontWeight: FontWeight.w700,
                                      color: stock > 0 ? (isLow ? Colors.red : AppTheme.primaryGreen) : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyticsSheet extends StatelessWidget {
  final dynamic seller;
  final Map<String, dynamic> analytics;
  const _AnalyticsSheet({required this.seller, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final revenue = (analytics['totalRevenue'] as double?) ?? 0.0;
    final totalOrders = (analytics['totalOrders'] as int?) ?? 0;
    final pendingOrders = (analytics['pendingOrders'] as int?) ?? 0;
    final completedOrders = (analytics['completedOrders'] as int?) ?? 0;
    final conversionRate = totalOrders > 0 ? (completedOrders / totalOrders * 100).toStringAsFixed(1) : '0.0';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Analytics', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          Text('All-time performance for ${seller.businessName}',
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          _AnalyticsRow(label: 'Total Revenue', value: '${revenue.toStringAsFixed(0)} RWF',
            icon: Icons.account_balance_wallet, color: AppTheme.primaryGreen),
          const SizedBox(height: 12),
          _AnalyticsRow(label: 'Total Orders', value: '$totalOrders',
            icon: Icons.shopping_bag, color: AppTheme.accentOrange),
          const SizedBox(height: 12),
          _AnalyticsRow(label: 'Pending Orders', value: '$pendingOrders',
            icon: Icons.pending_actions, color: const Color(0xFF1E88E5)),
          const SizedBox(height: 12),
          _AnalyticsRow(label: 'Completed Orders', value: '$completedOrders',
            icon: Icons.check_circle_outline, color: AppTheme.primaryGreen),
          const SizedBox(height: 12),
          _AnalyticsRow(label: 'Completion Rate', value: '$conversionRate%',
            icon: Icons.bar_chart, color: const Color(0xFF9C27B0)),
          const SizedBox(height: 12),
          _AnalyticsRow(label: 'Average Rating', value: seller.ratingLabel,
            icon: Icons.star, color: const Color(0xFFF9A825)),
          const SizedBox(height: 12),
          _AnalyticsRow(label: 'Total Sales', value: '${seller.totalSales}',
            icon: Icons.trending_up, color: const Color(0xFF1E88E5)),
        ],
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsRow({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary)),
          ),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No Seller View
// ─────────────────────────────────────────────────────────────────────────────

class _NoSellerView extends StatelessWidget {
  final VoidCallback onBecomeSeller;

  const _NoSellerView({required this.onBecomeSeller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.storefront_outlined, size: 60, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 24),
            Text('Start Selling on AfriMarket',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Join thousands of sellers and reach customers across Rwanda',
              style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onBecomeSeller,
              icon: const Icon(Icons.storefront),
              label: const Text('Become a Seller'),
            ),
          ],
        ),
      ),
    );
  }
}
