import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class AuthService {
  // Sign in with email and password
  static Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  static Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  static User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // Check if user is signed in
  static bool isSignedIn() {
    return supabase.auth.currentUser != null;
  }

  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges {
    return supabase.auth.onAuthStateChange;
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }
}
