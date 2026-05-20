import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/core/services/supabase_service.dart';
import 'package:afrimarket/features/marketplace/domain/entities/category_entity.dart';

class CategoryDataSource {
  SupabaseClient? get _clientOrNull =>
      SupabaseService.isInitialized ? SupabaseService.client : null;

  Future<List<CategoryEntity>> getCategories() async {
    final client = _clientOrNull;
    if (client == null) return [];
    try {
      final response = await client
          .from('categories')
          .select()
          .order('name');
      return (response as List)
          .map((e) => CategoryEntity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CategoryEntity>> getOrSeedCategories() async {
    final client = _clientOrNull;
    if (client == null) return _defaultEntities();
    var cats = await getCategories();
    if (cats.isNotEmpty) return cats;

    try {
      await client
          .from('categories')
          .upsert(CategoryEntity.defaults, onConflict: 'slug');
      cats = await getCategories();
    } catch (_) {}

    return cats.isNotEmpty ? cats : _defaultEntities();
  }

  List<CategoryEntity> _defaultEntities() => CategoryEntity.defaults
      .map((m) => CategoryEntity.fromJson(Map<String, dynamic>.from(m)))
      .toList();
}
