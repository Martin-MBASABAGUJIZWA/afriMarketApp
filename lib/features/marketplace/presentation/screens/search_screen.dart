import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
import 'package:afrimarket/core/utils/responsive.dart';
import 'package:afrimarket/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:afrimarket/core/widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final q = ref.read(searchQueryProvider);
    _controller.text = q;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final r = Responsive.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            ref.read(searchQueryProvider.notifier).state = '';
            context.pop();
          },
        ),
        titleSpacing: 0,
        title: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.isDesktop ? 720 : double.infinity),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Search products or sellers...',
              hintStyle: GoogleFonts.poppins(color: Colors.white60, fontSize: 16),
              border: InputBorder.none,
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
            ),
            onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v.trim(),
          ),
        ),
      ),
      body: query.isEmpty
          ? _EmptySearch(isDesktop: r.isDesktop)
          : results.when(
              data: (products) {
                if (products.isEmpty) {
                  return _NoResults(query: query);
                }
                if (r.isDesktop) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                      child: Padding(
                        padding: EdgeInsets.all(r.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${products.length} result${products.length == 1 ? '' : 's'} for "$query"',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: r.sectionGap / 2),
                            Expanded(
                              child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: r.productCols,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, i) {
                                  final p = products[i];
                                  return ProductCard(
                                    product: p,
                                    onTap: () => context.push('/product/${p.id}'),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                // Mobile: list layout
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return ProductCard(
                      product: p,
                      onTap: () => context.push('/product/${p.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final bool isDesktop;
  const _EmptySearch({this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: isDesktop ? 64 : 72,
            color: const Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 16),
          Text(
            'Search AfriMarket',
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 22 : 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find products and sellers near you',
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
          ),
          if (isDesktop) ...[
            const SizedBox(height: 32),
            Wrap(
              spacing: 10,
              children: ['Fresh Produce', 'Electronics', 'Clothing', 'Handmade'].map((cat) =>
                ActionChip(
                  label: Text(cat, style: GoogleFonts.poppins(fontSize: 13)),
                  backgroundColor: const Color(0xFFE8F5E9),
                  labelStyle: const TextStyle(color: AppTheme.primaryGreen),
                  onPressed: () {},
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 72, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
