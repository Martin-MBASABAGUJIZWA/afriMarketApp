import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afrimarket/features/marketplace/data/datasources/category_data_source.dart';
import 'package:afrimarket/features/marketplace/domain/entities/category_entity.dart';

final categoryDataSourceProvider =
    Provider<CategoryDataSource>((ref) => CategoryDataSource());

final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final ds = ref.watch(categoryDataSourceProvider);
  return ds.getOrSeedCategories();
});
