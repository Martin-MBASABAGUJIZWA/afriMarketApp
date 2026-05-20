import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
import 'package:afrimarket/core/utils/responsive.dart';
import 'package:afrimarket/features/auth/domain/entities/user_entity.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/features/notifications/presentation/providers/notification_provider.dart';
import 'package:afrimarket/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:afrimarket/features/orders/presentation/providers/order_provider.dart';

// ──────────────────────────────────────────────────────────
// Root screen — handles loading/error/data states
// ──────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            // Authenticated but profile row unavailable — trigger a refresh.
            // Using postFrameCallback avoids calling invalidate during build.
            if (authUser != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) ref.invalidate(currentUserProvider);
              });
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                      color: AppTheme.primaryGreen),
                  const SizedBox(height: 20),
                  Text('Setting up your profile…',
                      style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.invalidate(currentUserProvider),
                    child: Text('Retry',
                        style: GoogleFonts.poppins(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }
          return _ProfileBody(user: user);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Could not load profile',
                  style:
                      GoogleFonts.poppins(color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(currentUserProvider),
                child: Text('Retry',
                    style: GoogleFonts.poppins(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Body — branches on breakpoint
// ──────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  final UserEntity user;
  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = Responsive.of(context);
    final favoriteIds = ref.watch(favoritesProvider);
    final ordersAsync = ref.watch(buyerOrdersProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final orderCount = ordersAsync.value?.length ?? 0;
    final favoriteCount = favoriteIds.length;
    final unreadCount =
        notificationsAsync.value?.where((n) => !n.isRead).length ?? 0;

    if (r.showSidebar) {
      return _DesktopProfile(
        user: user,
        orderCount: orderCount,
        favoriteCount: favoriteCount,
        unreadCount: unreadCount,
        r: r,
      );
    }
    return _MobileProfile(
      user: user,
      orderCount: orderCount,
      favoriteCount: favoriteCount,
      unreadCount: unreadCount,
    );
  }
}

// ──────────────────────────────────────────────────────────
// Desktop/tablet layout — two-column dashboard
// ──────────────────────────────────────────────────────────

class _DesktopProfile extends ConsumerWidget {
  final UserEntity user;
  final int orderCount;
  final int favoriteCount;
  final int unreadCount;
  final Responsive r;

  const _DesktopProfile({
    required this.user,
    required this.orderCount,
    required this.favoriteCount,
    required this.unreadCount,
    required this.r,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = user.role;
    final roleData = _roleData(role);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: r.h,
        title: Text('My Account',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: r.h),
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfileDialog(context, ref, user),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text('Edit Profile',
                  style: GoogleFonts.poppins(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: r.h, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: profile card ─────────────────────────
                SizedBox(
                  width: r.isWide ? 340 : 300,
                  child: Column(
                    children: [
                      _DesktopProfileCard(
                        user: user,
                        roleData: roleData,
                        orderCount: orderCount,
                        favoriteCount: favoriteCount,
                        unreadCount: unreadCount,
                      ),
                      const SizedBox(height: 16),
                      _QuickActions(user: user, role: role),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // ── Right: section cards ───────────────────────
                Expanded(
                  child: Column(
                    children: [
                      // Account card
                      _SectionGroupCard(
                        title: 'Account',
                        children: [
                          _MenuItem(
                            icon: Icons.shopping_bag_outlined,
                            title: 'My Orders',
                            subtitle: orderCount > 0
                                ? '$orderCount orders'
                                : 'No orders yet',
                            onTap: () => context.push('/my-orders'),
                            badgeColor: AppTheme.accentOrange,
                          ),
                          _MenuItem(
                            icon: Icons.favorite_border_rounded,
                            title: 'Favorites',
                            subtitle: favoriteCount > 0
                                ? '$favoriteCount saved items'
                                : 'No favorites yet',
                            onTap: () => context.push('/favorites'),
                            badgeColor: Colors.red,
                          ),
                          _MenuItem(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            subtitle: unreadCount > 0
                                ? '$unreadCount unread'
                                : 'No new notifications',
                            onTap: () => context.push('/notifications'),
                            badgeCount: unreadCount,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Shop card
                      _SectionGroupCard(
                        title: 'Shop',
                        children: [
                          _MenuItem(
                            icon: Icons.storefront_outlined,
                            title: role == 'seller'
                                ? 'Seller Dashboard'
                                : 'Become a Seller',
                            subtitle: role == 'seller'
                                ? 'Manage your shop & products'
                                : 'Start selling on AfriMarket',
                            onTap: () =>
                                context.push('/seller-dashboard'),
                            iconColor: AppTheme.accentOrange,
                          ),
                          if (role == 'admin')
                            _MenuItem(
                              icon: Icons.admin_panel_settings_outlined,
                              title: 'Admin Panel',
                              subtitle: 'Manage the marketplace',
                              onTap: () => context.push('/admin'),
                              iconColor: const Color(0xFF9C27B0),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Settings card
                      _SectionGroupCard(
                        title: 'Settings',
                        children: [
                          _MenuItem(
                            icon: Icons.location_on_outlined,
                            title: 'Delivery Address',
                            subtitle: (user.location?.isNotEmpty ?? false)
                                ? user.location!
                                : 'Add your delivery address',
                            onTap: () =>
                                _showAddressSheet(context, ref, user),
                          ),
                          _MenuItem(
                            icon: Icons.payment_outlined,
                            title: 'Payment Methods',
                            subtitle:
                                'Mobile money, bank transfer & more',
                            onTap: () =>
                                _showPaymentSheet(context, user),
                          ),
                          _MenuItem(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            subtitle: 'FAQs and contact information',
                            onTap: () => _showHelpSheet(context),
                          ),
                          _MenuItem(
                            icon: Icons.info_outline,
                            title: 'About AfriMarket',
                            onTap: () => _showAboutDialog(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Sign out
                      _SectionGroupCard(
                        title: 'Account Actions',
                        children: [
                          _MenuItem(
                            icon: Icons.logout,
                            title: 'Sign Out',
                            subtitle: 'Log out of your account',
                            isDestructive: true,
                            onTap: () =>
                                _confirmSignOut(context, ref),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopProfileCard extends StatelessWidget {
  final UserEntity user;
  final _RoleData roleData;
  final int orderCount;
  final int favoriteCount;
  final int unreadCount;

  const _DesktopProfileCard({
    required this.user,
    required this.roleData,
    required this.orderCount,
    required this.favoriteCount,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: roleData.color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: roleData.color, width: 3),
            ),
            child: Center(
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : 'U',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: roleData.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Name
          Text(
            user.fullName,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            user.email,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (user.phone?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_outlined,
                    size: 13, color: AppTheme.textTertiary),
                const SizedBox(width: 4),
                Text(user.phone!,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ],
          if (user.location?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppTheme.textTertiary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(user.location!,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          // Role badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: roleData.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: roleData.color,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          // Stats grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(
                value: '$orderCount',
                label: 'Orders',
                onTap: () => context.push('/my-orders'),
              ),
              _VerticalDivider(),
              _StatColumn(
                value: '$favoriteCount',
                label: 'Saved',
                onTap: () => context.push('/favorites'),
              ),
              _VerticalDivider(),
              _StatColumn(
                value: unreadCount > 0 ? '$unreadCount' : '0',
                label: 'Alerts',
                highlight: unreadCount > 0,
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final UserEntity user;
  final String role;

  const _QuickActions({required this.user, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textTertiary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _QuickAction(
            icon: Icons.add_shopping_cart_outlined,
            label: 'Browse Products',
            onTap: () => context.go('/home'),
          ),
          _QuickAction(
            icon: Icons.receipt_long_outlined,
            label: 'View Orders',
            onTap: () => context.push('/my-orders'),
          ),
          if (role == 'seller') ...[
            _QuickAction(
              icon: Icons.add_box_outlined,
              label: 'Add Product',
              onTap: () => context.push('/seller/add-product'),
            ),
            _QuickAction(
              icon: Icons.dashboard_outlined,
              label: 'My Dashboard',
              onTap: () => context.push('/seller-dashboard'),
            ),
          ] else
            _QuickAction(
              icon: Icons.storefront_outlined,
              label: 'Start Selling',
              onTap: () => context.push('/become-seller'),
            ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary)),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 12, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}

// A white card that wraps a group of _MenuItem items with a section header
class _SectionGroupCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionGroupCard(
      {required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Mobile layout — scrollable single column
// ──────────────────────────────────────────────────────────

class _MobileProfile extends ConsumerWidget {
  final UserEntity user;
  final int orderCount;
  final int favoriteCount;
  final int unreadCount;

  const _MobileProfile({
    required this.user,
    required this.orderCount,
    required this.favoriteCount,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = user.role;
    final roleData = _roleData(role);

    return CustomScrollView(
      slivers: [
        // Green header
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.white),
                      tooltip: 'Edit Profile',
                      onPressed: () =>
                          _showEditProfileDialog(context, ref, user),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Floating profile card
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -70),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar + role icon
                    Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: roleData.color.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: roleData.color, width: 3),
                          ),
                          child: Center(
                            child: Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.poppins(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: roleData.color),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: roleData.color,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(roleData.icon,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(user.fullName,
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(user.email,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.textSecondary)),
                    if (user.phone?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 14, color: AppTheme.textTertiary),
                          const SizedBox(width: 4),
                          Text(user.phone!,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                    if (user.location?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppTheme.textTertiary),
                          const SizedBox(width: 4),
                          Text(user.location!,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleData.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(role.toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: roleData.color)),
                    ),
                    const SizedBox(height: 20),
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatPill(
                          label: 'Orders',
                          value: '$orderCount',
                          onTap: () => context.push('/my-orders'),
                        ),
                        Container(
                            width: 1,
                            height: 32,
                            color: const Color(0xFFE0E0E0)),
                        _StatPill(
                          label: 'Favorites',
                          value: '$favoriteCount',
                          onTap: () => context.push('/favorites'),
                        ),
                        Container(
                            width: 1,
                            height: 32,
                            color: const Color(0xFFE0E0E0)),
                        _StatPill(
                          label: 'Alerts',
                          value:
                              unreadCount > 0 ? '$unreadCount new' : '0',
                          onTap: () => context.push('/notifications'),
                          highlight: unreadCount > 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Menu items
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Account'),
                  _MenuItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Orders',
                    subtitle:
                        orderCount > 0 ? '$orderCount orders' : null,
                    onTap: () => context.push('/my-orders'),
                    badgeColor: AppTheme.accentOrange,
                  ),
                  _MenuItem(
                    icon: Icons.favorite_border_rounded,
                    title: 'Favorites',
                    subtitle: favoriteCount > 0
                        ? '$favoriteCount saved'
                        : null,
                    onTap: () => context.push('/favorites'),
                    badgeColor: Colors.red,
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () => context.push('/notifications'),
                    badgeCount: unreadCount,
                  ),

                  const SizedBox(height: 8),
                  _SectionLabel('Shop'),
                  _MenuItem(
                    icon: Icons.storefront_outlined,
                    title: role == 'seller'
                        ? 'Seller Dashboard'
                        : 'Become a Seller',
                    subtitle: role == 'seller'
                        ? 'Manage your shop'
                        : 'Start selling today',
                    onTap: () => context.push('/seller-dashboard'),
                    iconColor: AppTheme.accentOrange,
                  ),
                  if (role == 'admin')
                    _MenuItem(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin Panel',
                      subtitle: 'Manage marketplace',
                      onTap: () => context.push('/admin'),
                      iconColor: const Color(0xFF9C27B0),
                    ),

                  const SizedBox(height: 8),
                  _SectionLabel('Settings'),
                  _MenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'My Address',
                    subtitle: (user.location?.isNotEmpty ?? false)
                        ? user.location
                        : 'Add delivery address',
                    onTap: () =>
                        _showAddressSheet(context, ref, user),
                  ),
                  _MenuItem(
                    icon: Icons.payment_outlined,
                    title: 'Payment Methods',
                    subtitle: 'Mobile money & more',
                    onTap: () => _showPaymentSheet(context, user),
                  ),

                  const SizedBox(height: 8),
                  _SectionLabel('More'),
                  _MenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => _showHelpSheet(context),
                  ),
                  _MenuItem(
                    icon: Icons.info_outline,
                    title: 'About AfriMarket',
                    onTap: () => _showAboutDialog(context),
                  ),

                  const SizedBox(height: 16),
                  _MenuItem(
                    icon: Icons.logout,
                    title: 'Log Out',
                    isDestructive: true,
                    onTap: () => _confirmSignOut(context, ref),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Role data helper
// ──────────────────────────────────────────────────────────

class _RoleData {
  final Color color;
  final IconData icon;
  const _RoleData({required this.color, required this.icon});
}

_RoleData _roleData(String role) {
  switch (role) {
    case 'admin':
      return const _RoleData(color: Color(0xFF9C27B0), icon: Icons.admin_panel_settings);
    case 'seller':
      return const _RoleData(color: AppTheme.accentOrange, icon: Icons.storefront);
    default:
      return const _RoleData(color: AppTheme.primaryGreen, icon: Icons.person);
  }
}

Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Sign Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      content: Text('Are you sure you want to sign out?',
          style: GoogleFonts.poppins(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel',
              style:
                  GoogleFonts.poppins(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Sign Out',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  if (confirm == true) {
    await ref.read(authNotifierProvider.notifier).signOut();
    if (context.mounted) context.go('/login');
  }
}

// ──────────────────────────────────────────────────────────
// Shared helper widgets
// ──────────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight;
  final VoidCallback onTap;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: highlight
                    ? AppTheme.accentOrange
                    : AppTheme.textPrimary,
              )),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: const Color(0xFFE0E0E0));
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool highlight;

  const _StatPill({
    required this.label,
    required this.value,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: highlight
                    ? AppTheme.primaryGreen
                    : AppTheme.textPrimary,
              )),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final Color? iconColor;
  final Color? badgeColor;
  final int badgeCount;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
    this.iconColor,
    this.badgeColor,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        isDestructive ? Colors.red : iconColor ?? AppTheme.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: effectiveIconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDestructive
                                ? Colors.red
                                : AppTheme.textPrimary,
                          )),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$badgeCount',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                Icon(Icons.chevron_right,
                    size: 20,
                    color: isDestructive
                        ? Colors.red.shade300
                        : const Color(0xFFBDBDBD)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Edit Profile Dialog
// ──────────────────────────────────────────────────────────

Future<void> _showEditProfileDialog(
    BuildContext context, WidgetRef ref, UserEntity user) async {
  final nameController = TextEditingController(text: user.fullName);
  final phoneController =
      TextEditingController(text: user.phone ?? '');
  bool saving = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Profile',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+250 78X XXX XXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: Text('Cancel',
                style:
                    GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: saving
                ? null
                : () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    setState(() => saving = true);
                    try {
                      final phone = phoneController.text.trim();
                      await ref
                          .read(authRepositoryProvider)
                          .updateUserProfile(
                            userId: user.id,
                            fullName: name,
                            phone: phone.isEmpty ? null : phone,
                          );
                      ref.invalidate(currentUserProvider);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Profile updated'),
                          backgroundColor: AppTheme.successGreen,
                        ));
                      }
                    } catch (e) {
                      setState(() => saving = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Update failed: $e')));
                      }
                    }
                  },
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Save',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
  );

  nameController.dispose();
  phoneController.dispose();
}

// ──────────────────────────────────────────────────────────
// Address Sheet
// ──────────────────────────────────────────────────────────

Future<void> _showAddressSheet(
    BuildContext context, WidgetRef ref, UserEntity user) async {
  final controller =
      TextEditingController(text: user.location ?? '');
  bool saving = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text('My Delivery Address',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text('Used for order deliveries',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                hintText: 'e.g. Kimironko, KG 12 Ave, Kigali',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Text('Common Areas',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Kimironko',
                'Remera',
                'Kacyiru',
                'Nyamirambo',
                'Gisozi',
                'Kanombe',
                'Kicukiro',
                'Gasabo',
              ]
                  .map((area) => GestureDetector(
                        onTap: () {
                          controller.text = '$area, Kigali';
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primaryGreen
                                    .withOpacity(0.3)),
                          ),
                          child: Text(area,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryGreen)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final address = controller.text.trim();
                        setState(() => saving = true);
                        try {
                          await ref
                              .read(authRepositoryProvider)
                              .updateUserProfile(
                                userId: user.id,
                                location:
                                    address.isEmpty ? null : address,
                              );
                          ref.invalidate(currentUserProvider);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Address saved'),
                                backgroundColor: AppTheme.successGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Save Address',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  controller.dispose();
}

// ──────────────────────────────────────────────────────────
// Payment Methods Sheet
// ──────────────────────────────────────────────────────────

void _showPaymentSheet(BuildContext context, UserEntity user) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Text('Payment Methods',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text('Accepted on AfriMarket',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          _PaymentMethodTile(
            emoji: '📱',
            name: 'MTN Mobile Money',
            detail: 'Pay with *182*8*1# or MTN MoMo app',
            color: const Color(0xFFFFC400),
          ),
          const SizedBox(height: 12),
          _PaymentMethodTile(
            emoji: '💳',
            name: 'Airtel Money',
            detail: 'Pay with *185*9# or Airtel Money app',
            color: const Color(0xFFE53935),
          ),
          const SizedBox(height: 12),
          _PaymentMethodTile(
            emoji: '🏦',
            name: 'Bank Transfer',
            detail: 'Transfer to seller\'s account',
            color: const Color(0xFF1E88E5),
          ),
          const SizedBox(height: 12),
          _PaymentMethodTile(
            emoji: '💵',
            name: 'Cash on Delivery',
            detail: 'Pay cash when your order arrives',
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security,
                    color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All transactions are secured. Payment info is never stored on our servers.',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PaymentMethodTile extends StatelessWidget {
  final String emoji;
  final String name;
  final String detail;
  final Color color;

  const _PaymentMethodTile({
    required this.emoji,
    required this.name,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child:
                    Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(detail,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.check_circle,
              color: AppTheme.primaryGreen, size: 20),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Help & Support Sheet
// ──────────────────────────────────────────────────────────

void _showHelpSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text('Help & Support',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  _FaqItem(
                    question: 'How do I place an order?',
                    answer:
                        'Browse products on the home screen. Tap a product, then "Add to Cart". Go to your cart and checkout.',
                  ),
                  _FaqItem(
                    question: 'How do I become a seller?',
                    answer:
                        'Go to Profile → Seller Dashboard → tap "Become a Seller". Fill in your business details. Your shop will be live immediately.',
                  ),
                  _FaqItem(
                    question: 'How do I pay for my order?',
                    answer:
                        'We accept MTN Mobile Money, Airtel Money, bank transfer, and cash on delivery.',
                  ),
                  _FaqItem(
                    question: 'How do I track my order?',
                    answer:
                        'Go to Profile → My Orders to see all orders and their current status.',
                  ),
                  _FaqItem(
                    question: 'How do I contact a seller?',
                    answer:
                        'Open a seller\'s profile page. You\'ll find their phone number to call or WhatsApp directly.',
                  ),
                  _FaqItem(
                    question: 'Can I cancel an order?',
                    answer:
                        'You can cancel a pending order from My Orders. Once confirmed by the seller, contact them directly.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.question,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                ),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppTheme.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(widget.answer,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5)),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// About Dialog
// ──────────────────────────────────────────────────────────

void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('About AfriMarket',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('A',
                  style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          Text('AfriMarket',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen)),
          const SizedBox(height: 8),
          Text('Version 1.0.0',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          Text(
            'AfriMarket connects local buyers and sellers across Africa. '
            'Discover fresh produce, goods, and services from sellers in your area.',
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child:
              Text('Close', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
