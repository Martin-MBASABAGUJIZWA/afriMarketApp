import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/features/auth/domain/entities/user_entity.dart';
import 'package:afrimarket/features/auth/domain/repositories/auth_repository.dart';
import 'package:afrimarket/core/services/auth_service.dart';
import 'package:afrimarket/core/errors/exceptions.dart' as app_exceptions;

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  User? get currentUser => _authService.currentUser;

  @override
  String? get currentUserId => _authService.currentUserId;

  @override
  bool get isAuthenticated => _authService.isAuthenticated;

  @override
  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      return await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
    } catch (e) {
      throw app_exceptions.AuthException(e.toString());
    }
  }

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _authService.signIn(
        email: email,
        password: password,
      );
    } catch (e) {
      throw app_exceptions.AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      throw app_exceptions.AuthException('Failed to sign out');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      throw app_exceptions.AuthException('Failed to send reset email');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _authService.updatePassword(newPassword);
    } catch (e) {
      throw app_exceptions.AuthException('Failed to update password');
    }
  }

  @override
  Future<UserEntity?> getUserProfile(String userId) async {
    try {
      final data = await _authService.getUserProfile(userId);
      if (data == null) return _fallbackEntity(userId);
      return UserEntity.fromJson(data);
    } catch (_) {
      // DB unreachable or RLS blocked — still show the profile using
      // auth metadata so authenticated users never see "Not logged in".
      return _fallbackEntity(userId);
    }
  }

  // Constructs a minimal UserEntity from auth.currentUser metadata.
  // Used when the profiles table row is missing or inaccessible.
  UserEntity? _fallbackEntity(String userId) {
    final authUser = _authService.currentUser;
    if (authUser == null || authUser.id != userId) return null;
    final meta = authUser.userMetadata ?? {};
    final email = authUser.email ?? '';
    final now = DateTime.now().toIso8601String();
    try {
      return UserEntity.fromJson({
        'id': userId,
        'full_name': meta['full_name'] as String? ?? email.split('@').first,
        'email': email,
        'phone': meta['phone'] as String?,
        'avatar_url': null,
        'location': null,
        'role': 'buyer',
        'is_verified': false,
        'created_at': now,
        'updated_at': now,
      });
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? location,
    String? avatarUrl,
  }) async {
    try {
      await _authService.updateUserProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        location: location,
        avatarUrl: avatarUrl,
      );
    } catch (e) {
      throw app_exceptions.ServerException('Failed to update profile');
    }
  }
}
