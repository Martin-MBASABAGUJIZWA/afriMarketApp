import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/features/auth/presentation/providers/auth_providers.dart';
import 'package:afrimarket/core/services/supabase_service.dart';

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
      final uid = next.value?.id;
      if (uid != null && uid != prev?.value?.id) {
        Future.microtask(() => _load(uid));
      } else if (uid == null) {
        state = {};
      }
    });

    final uid = ref.read(authStateProvider).value?.id;
    if (uid != null) Future.microtask(() => _load(uid));
    return {};
  }

  Future<void> _load(String userId) async {
    if (!SupabaseService.isInitialized) return;
    try {
      final rows = await SupabaseService.client
          .from('favorites')
          .select('product_id')
          .eq('user_id', userId);
      state = {for (final r in (rows as List)) r['product_id'] as String};
    } catch (_) {}
  }

  Future<void> toggle(String productId) async {
    final uid = ref.read(authStateProvider).value?.id;
    if (uid == null || !SupabaseService.isInitialized) return;

    final isFav = state.contains(productId);
    // Optimistic update
    state = Set.from(state)..toggle(productId, isFav);
    try {
      if (isFav) {
        await SupabaseService.client
            .from('favorites')
            .delete()
            .eq('user_id', uid)
            .eq('product_id', productId);
      } else {
        await SupabaseService.client.from('favorites').insert({
          'user_id': uid,
          'product_id': productId,
        });
      }
    } catch (_) {
      // Revert on failure
      state = Set.from(state)..toggle(productId, !isFav);
    }
  }

  bool isFavorite(String productId) => state.contains(productId);
}

extension _SetToggle on Set<String> {
  void toggle(String value, bool remove) {
    if (remove) {
      this.remove(value);
    } else {
      add(value);
    }
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
