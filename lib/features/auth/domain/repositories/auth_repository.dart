import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  User? get currentUser;
  String? get currentUserId;
  bool get isAuthenticated;
  Stream<AuthState> get authStateChanges;

  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  Future<User> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
  
  Future<void> resetPassword(String email);
  
  Future<void> updatePassword(String newPassword);

  Future<UserEntity?> getUserProfile(String userId);
  
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? location,
    String? avatarUrl,
  });
}
