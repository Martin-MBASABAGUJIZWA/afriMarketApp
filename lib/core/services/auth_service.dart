import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/core/errors/exceptions.dart' as app_exceptions;
import 'package:afrimarket/core/services/supabase_service.dart';

class AuthService {
  SupabaseClient? get _clientOrNull =>
      SupabaseService.isInitialized ? SupabaseService.client : null;

  SupabaseClient get _client {
    if (!SupabaseService.isInitialized) {
      throw app_exceptions.AuthException('Supabase not initialized. Please configure your .env file.');
    }
    return SupabaseService.client;
  }

  User? get currentUser => _clientOrNull?.auth.currentUser;

  String? get currentUserId => currentUser?.id;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      _clientOrNull?.auth.onAuthStateChange ?? const Stream.empty();

  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (phone != null) 'phone': phone,
        },
      );

      if (response.user == null) {
        throw app_exceptions.AuthException('Sign up failed');
      }

      // Profile creation is non-critical — auth user is already created.
      // Silently skip if it fails (RLS before session confirms, duplicate, etc.)
      try {
        await _upsertUserProfile(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
          phone: phone,
        );
      } catch (_) {}

      return response.user!;
    } on AuthException catch (e) {
      throw app_exceptions.AuthException(e.message);
    } on app_exceptions.AuthException {
      rethrow;
    } catch (e) {
      throw app_exceptions.AuthException('An error occurred during sign up');
    }
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw app_exceptions.AuthException('Sign in failed');
      }

      // Ensure a profile row exists for this user (covers users who registered
      // before the profiles table existed, or whose signup profile insert failed).
      final user = response.user!;
      try {
        final existing = await _client
            .from('profiles')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();
        if (existing == null) {
          final meta = user.userMetadata ?? {};
          await _upsertUserProfile(
            userId: user.id,
            email: user.email ?? email,
            fullName: meta['full_name'] as String? ?? email.split('@').first,
            phone: meta['phone'] as String?,
          );
        }
      } catch (_) {}

      return user;
    } on AuthException catch (e) {
      throw app_exceptions.AuthException(e.message);
    } on app_exceptions.AuthException {
      rethrow;
    } catch (e) {
      throw app_exceptions.AuthException('An error occurred during sign in');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw app_exceptions.AuthException('Failed to sign out');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw app_exceptions.AuthException(e.message);
    } catch (e) {
      throw app_exceptions.AuthException('Failed to send reset email');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw app_exceptions.AuthException(e.message);
    } catch (e) {
      throw app_exceptions.AuthException('Failed to update password');
    }
  }

  // Uses upsert so duplicate-key errors on re-signup or retry are harmless.
  Future<void> _upsertUserProfile({
    required String userId,
    required String email,
    required String fullName,
    String? phone,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'email': email,
      'full_name': fullName,
      if (phone != null) 'phone': phone,
      'role': 'buyer',
    }, onConflict: 'id');
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // maybeSingle returns null instead of throwing when row missing

      if (response == null) return null;

      // Guarantee non-null timestamps so UserEntity.fromJson never crashes.
      final now = DateTime.now().toIso8601String();
      return {
        ...response,
        'created_at': response['created_at'] ?? now,
        'updated_at': response['updated_at'] ?? now,
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? location,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (location != null) updates['location'] = location;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) return;

      await _client.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw app_exceptions.ServerException('Failed to update profile');
    }
  }
}
