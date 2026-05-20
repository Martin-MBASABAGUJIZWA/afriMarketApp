import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afrimarket/features/marketplace/data/datasources/marketplace_data_source.dart';
import 'package:afrimarket/features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'package:afrimarket/features/marketplace/domain/entities/product_entity.dart';
import 'package:afrimarket/features/marketplace/domain/repositories/marketplace_repository.dart';

final marketplaceDataSourceProvider = Provider<MarketplaceDataSource>(
  (ref) => MarketplaceDataSource(),
);

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>(
  (ref) => MarketplaceRepositoryImpl(
    ref.read(marketplaceDataSourceProvider),
  ),
);

final featuredProductsProvider = FutureProvider<List<ProductEntity>>((ref) async {
  final repository = ref.watch(marketplaceRepositoryProvider);
  try {
    return await repository.getFeaturedProducts(limit: 4);
  } catch (_) {
    return [];
  }
});

final productsProvider = FutureProvider.family<List<ProductEntity>, String?>(
  (ref, categoryId) async {
    final repository = ref.watch(marketplaceRepositoryProvider);
    try {
      return await repository.getProducts(categoryId: categoryId);
    } catch (_) {
      return [];
    }
  },
);

final productDetailProvider = FutureProvider.family<ProductEntity?, String>(
  (ref, productId) async {
    final repository = ref.watch(marketplaceRepositoryProvider);
    try {
      return await repository.getProductById(productId);
    } catch (_) {
      return null;
    }
  },
);

// Products for a specific seller — uses seller_id, NOT category_id
final sellerProductsProvider =
    FutureProvider.autoDispose.family<List<ProductEntity>, String>(
  (ref, sellerId) async {
    final repository = ref.watch(marketplaceRepositoryProvider);
    try {
      return await repository.getProductsBySeller(sellerId);
    } catch (_) {
      return [];
    }
  },
);

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<ProductEntity>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return Future.value([]);
  
  final repository = ref.watch(marketplaceRepositoryProvider);
  return repository.searchProducts(query);
});

class ProductsNotifier extends Notifier<AsyncValue<List<ProductEntity>>> {
  late MarketplaceRepository _repository;
  String? _currentCategory;

  @override
  AsyncValue<List<ProductEntity>> build() {
    _repository = ref.read(marketplaceRepositoryProvider);
    loadProducts();
    return const AsyncValue.loading();
  }

  Future<void> loadProducts({String? categoryId}) async {
    _currentCategory = categoryId;
    state = const AsyncValue.loading();
    
    try {
      final products = await _repository.getProducts(categoryId: categoryId);
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadProducts(categoryId: _currentCategory);
  }
}

final productsNotifierProvider =
    NotifierProvider<ProductsNotifier, AsyncValue<List<ProductEntity>>>(
  () => ProductsNotifier(),
);
