import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
import 'package:afrimarket/features/seller/presentation/providers/seller_providers.dart';
import 'package:afrimarket/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:afrimarket/features/admin/presentation/providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Admin Panel',
                                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                                Text('AfriMarket Enterprise',
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Quick Stats Row — real data
                        Consumer(
                          builder: (context, ref, _) {
                            final statsAsync = ref.watch(adminStatsProvider);
                            return statsAsync.when(
                              data: (stats) {
                                final users = stats['users'] as int;
                                final sellers = stats['sellers'] as int;
                                final revenue = stats['revenue'] as double;
                                final orders = stats['orders'] as int;
                                String revenueLabel;
                                if (revenue >= 1000000) {
                                  revenueLabel = '${(revenue / 1000000).toStringAsFixed(1)}M';
                                } else if (revenue >= 1000) {
                                  revenueLabel = '${(revenue / 1000).toStringAsFixed(0)}K';
                                } else {
                                  revenueLabel = revenue.toStringAsFixed(0);
                                }
                                return Row(children: [
                                  _MiniStat(label: 'Users', value: '$users'),
                                  const SizedBox(width: 12),
                                  _MiniStat(label: 'Sellers', value: '$sellers'),
                                  const SizedBox(width: 12),
                                  _MiniStat(label: 'Revenue', value: revenueLabel),
                                  const SizedBox(width: 12),
                                  _MiniStat(label: 'Orders', value: '$orders'),
                                ]);
                              },
                              loading: () => const Row(children: [
                                Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2))),
                              ]),
                              error: (_, __) => Row(children: const [
                                _MiniStat(label: 'Users', value: '-'),
                                SizedBox(width: 12),
                                _MiniStat(label: 'Sellers', value: '-'),
                                SizedBox(width: 12),
                                _MiniStat(label: 'Revenue', value: '-'),
                                SizedBox(width: 12),
                                _MiniStat(label: 'Orders', value: '-'),
                              ]),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Sellers'),
                Tab(text: 'Products'),
                Tab(text: 'Users'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _OverviewTab(),
            _SellersTab(),
            _ProductsTab(),
            _UsersTab(),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(label,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

// ─── Overview Tab ──────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final recentOrdersAsync = ref.watch(adminRecentOrdersProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Revenue Chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Revenue Overview',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('All Time',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SimpleBarChart(),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              statsAsync.when(
                data: (stats) {
                  final revenue = (stats['revenue'] as double);
                  final orders = stats['orders'] as int;
                  String rev = revenue >= 1000000
                      ? '${(revenue / 1000000).toStringAsFixed(1)}M RWF'
                      : revenue >= 1000
                          ? '${(revenue / 1000).toStringAsFixed(0)}K RWF'
                          : '${revenue.toStringAsFixed(0)} RWF';
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LegendItem(color: AppTheme.primaryGreen, label: 'Revenue: $rev'),
                      _LegendItem(color: AppTheme.accentOrange, label: 'Orders: $orders'),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Metric Cards Grid — real counts
        statsAsync.when(
          data: (stats) => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _MetricCard(label: 'Total Users', value: '${stats['users']}', icon: Icons.people, color: const Color(0xFF1E88E5), change: 'Total'),
              _MetricCard(label: 'Total Sellers', value: '${stats['sellers']}', icon: Icons.storefront, color: AppTheme.accentOrange, change: 'Active'),
              _MetricCard(label: 'Total Orders', value: '${stats['orders']}', icon: Icons.shopping_bag, color: AppTheme.primaryGreen, change: 'All Time'),
              _MetricCard(
                label: 'Total Revenue',
                value: () {
                  final r = stats['revenue'] as double;
                  if (r >= 1000000) return '${(r / 1000000).toStringAsFixed(1)}M';
                  if (r >= 1000) return '${(r / 1000).toStringAsFixed(0)}K';
                  return r.toStringAsFixed(0);
                }(),
                icon: Icons.account_balance_wallet,
                color: const Color(0xFF9C27B0),
                change: 'RWF',
              ),
            ],
          ),
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          )),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // Recent Orders as Activity
        _AdminCard(
          title: 'Recent Orders',
          child: recentOrdersAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return Text('No orders yet',
                  style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary));
              }
              return Column(
                children: orders.map((o) {
                  final status = o['status'] as String? ?? 'pending';
                  final total = (o['total'] as num?)?.toDouble() ?? 0.0;
                  final id = (o['id'] as String? ?? '').substring(0, 8).toUpperCase();
                  final createdAt = o['created_at'] != null
                      ? DateTime.tryParse(o['created_at'] as String)
                      : null;
                  String timeLabel = '';
                  if (createdAt != null) {
                    final diff = DateTime.now().difference(createdAt);
                    if (diff.inMinutes < 60) {
                      timeLabel = '${diff.inMinutes}m ago';
                    } else if (diff.inHours < 24) {
                      timeLabel = '${diff.inHours}h ago';
                    } else {
                      timeLabel = '${diff.inDays}d ago';
                    }
                  }
                  Color statusColor;
                  switch (status) {
                    case 'completed': statusColor = AppTheme.primaryGreen; break;
                    case 'confirmed': statusColor = const Color(0xFF1E88E5); break;
                    case 'cancelled': statusColor = AppTheme.errorRed; break;
                    default: statusColor = AppTheme.accentOrange;
                  }
                  return _ActivityItem(
                    icon: Icons.receipt_outlined,
                    text: 'Order #$id · ${total.toStringAsFixed(0)} RWF',
                    time: timeLabel,
                    color: statusColor,
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = [0.4, 0.7, 0.5, 0.8, 0.6, 0.9, 0.75, 0.85, 0.65, 0.95, 0.8, 1.0];
    final labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(data.length, (i) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 18,
                height: data[i] * 100,
                decoration: BoxDecoration(
                  color: i == data.length - 1
                      ? AppTheme.primaryGreen
                      : AppTheme.primaryGreen.withValues(alpha: 0.3 + data[i] * 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(labels[i],
                style: GoogleFonts.poppins(fontSize: 9, color: AppTheme.textSecondary)),
            ],
          );
        }),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String change;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(change,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text(label,
                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String time;
  final Color color;

  const _ActivityItem({required this.icon, required this.text, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                Text(time,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sellers Tab ───────────────────────────────────────────
class _SellersTab extends ConsumerWidget {
  const _SellersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellersAsync = ref.watch(sellersProvider);

    return sellersAsync.when(
      data: (sellers) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AdminSearchBar(hint: 'Search sellers...'),
          const SizedBox(height: 16),
          ...sellers.map((seller) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SellerAdminCard(seller: seller),
          )),
          if (sellers.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No sellers found'))),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      error: (e, _) => Center(child: Text('Error loading sellers')),
    );
  }
}

class _SellerAdminCard extends StatelessWidget {
  final dynamic seller;

  const _SellerAdminCard({required this.seller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(seller.categoryIcon, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(seller.businessName,
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    if (seller.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 16, color: AppTheme.primaryGreen),
                    ],
                  ],
                ),
                Text('${seller.category} · ${seller.location}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: const Color(0xFFF9A825)),
                    const SizedBox(width: 2),
                    Text(seller.ratingLabel,
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text('${seller.totalSales} sales',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: seller.isOpen ? const Color(0xFFE8F5E9) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(seller.isOpen ? 'Open' : 'Closed',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600,
                    color: seller.isOpen ? AppTheme.primaryGreen : Colors.red)),
              ),
              const SizedBox(height: 8),
              PopupMenuButton<String>(
                onSelected: (v) {},
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'verify', child: Text('Verify Seller')),
                  PopupMenuItem(value: 'suspend', child: Text('Suspend')),
                  PopupMenuItem(value: 'view', child: Text('View Profile')),
                ],
                child: const Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Products Tab ──────────────────────────────────────────
class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider(null));

    return productsAsync.when(
      data: (products) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AdminSearchBar(hint: 'Search products...'),
          const SizedBox(height: 16),
          ...products.map((product) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ProductAdminCard(product: product),
          )),
          if (products.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No products found'))),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      error: (e, _) => Center(child: Text('Error loading products')),
    );
  }
}

class _ProductAdminCard extends StatelessWidget {
  final dynamic product;

  const _ProductAdminCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGreen, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text(product.formattedPrice(),
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
                Text('Stock: ${product.stockQuantity} · Rating: ${product.ratingDisplay}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {},
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'feature', child: Text('Feature Product')),
              PopupMenuItem(value: 'remove', child: Text('Remove')),
              PopupMenuItem(value: 'view', child: Text('View Details')),
            ],
            child: const Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Users Tab ─────────────────────────────────────────────
class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return usersAsync.when(
      data: (users) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AdminSearchBar(hint: 'Search users...'),
          const SizedBox(height: 16),
          ...users.map((user) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UserAdminCard(user: user),
          )),
          if (users.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No users found'),
            )),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      error: (e, _) => Center(child: Text('Error loading users')),
    );
  }
}

class _UserAdminCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserAdminCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final role = user['role'] as String? ?? 'buyer';
    final name = user['full_name'] as String? ?? user['email'] as String? ?? 'Unknown';
    final email = user['email'] as String? ?? '';
    final createdAt = user['created_at'] != null
        ? DateTime.tryParse(user['created_at'] as String)
        : null;
    String joinedLabel = '';
    if (createdAt != null) {
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      joinedLabel = '${months[createdAt.month]} ${createdAt.year}';
    }

    final roleColor = role == 'admin'
        ? const Color(0xFF9C27B0)
        : role == 'seller'
            ? AppTheme.accentOrange
            : AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: roleColor),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(email,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                if (joinedLabel.isNotEmpty)
                  Text('Joined $joinedLabel',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(role.toUpperCase(),
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: roleColor)),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────
class _AdminSearchBar extends StatelessWidget {
  final String hint;

  const _AdminSearchBar({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textTertiary),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _AdminCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
