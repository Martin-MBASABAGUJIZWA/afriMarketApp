import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afrimarket/features/seller/data/datasources/seller_data_source.dart';
import 'package:afrimarket/features/seller/data/repositories/seller_repository_impl.dart';
import 'package:afrimarket/features/seller/domain/entities/seller_entity.dart';
import 'package:afrimarket/features/seller/domain/repositories/seller_repository.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';

final sellerDataSourceProvider = Provider<SellerDataSource>(
  (ref) => SellerDataSource(),
);

final sellerRepositoryProvider = Provider<SellerRepository>(
  (ref) => SellerRepositoryImpl(
    ref.read(sellerDataSourceProvider),
  ),
);

final sellersProvider = FutureProvider.autoDispose<List<SellerEntity>>((ref) async {
  final repository = ref.watch(sellerRepositoryProvider);
  try {
    return await repository.getSellers();
  } catch (_) {
    return [];
  }
});

final sellerByIdProvider =
    FutureProvider.autoDispose.family<SellerEntity?, String>((ref, sellerId) {
  final repository = ref.watch(sellerRepositoryProvider);
  return repository.getSellerById(sellerId);
});

final currentUserSellerProvider = FutureProvider.autoDispose<SellerEntity?>(
  (ref) async {
    final repository = ref.watch(sellerRepositoryProvider);
    final authRepository = ref.watch(authRepositoryProvider);
    
    final userId = authRepository.currentUserId;
    if (userId == null) return null;

    return repository.getSellerByUserId(userId);
  },
);
