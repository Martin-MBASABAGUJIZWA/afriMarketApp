import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/core/services/auth_service.dart';
import 'package:afrimarket/core/services/supabase_service.dart';
import 'package:afrimarket/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:afrimarket/features/auth/domain/entities/user_entity.dart';
import 'package:afrimarket/features/auth/domain/repositories/auth_repository.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(authServiceProvider)),
);

// Uses an async generator so the CURRENT session is yielded immediately on
// first subscription — Supabase's onAuthStateChange only fires on *changes*,
// not on subscription, which would leave StreamProvider in AsyncLoading forever.
final authStateProvider = StreamProvider<User?>((ref) async* {
  if (!SupabaseService.isInitialized) {
    yield null;
    return;
  }
  final client = SupabaseService.client;
  yield client.auth.currentUser; // emit current state immediately
  await for (final authState in client.auth.onAuthStateChange) {
    yield authState.session?.user;
  }
});

final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  // Re-fetch whenever auth session changes (login, logout, session restore).
  final sessionUser = ref.watch(authStateProvider).value;
  final notifierUser = ref.watch(authNotifierProvider).value;
  final userId = sessionUser?.id ?? notifierUser?.id;

  if (userId == null) return null;

  final repository = ref.read(authRepositoryProvider);
  try {
    return await repository.getUserProfile(userId);
  } catch (_) {
    return null;
  }
});

class AuthNotifier extends Notifier<AsyncValue<User?>> {
  late AuthRepository _repository;

  @override
  AsyncValue<User?> build() {
    _repository = ref.read(authRepositoryProvider);
    return _repository.isAuthenticated
        ? AsyncValue.data(_repository.currentUser)
        : const AsyncValue.data(null);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signIn(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _repository.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<User?>>(() {
  return AuthNotifier();
});
