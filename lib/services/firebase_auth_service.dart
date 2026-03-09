// Firebase Auth Service - disabled for local-only mode.
// Re-enable when connecting to Firebase Auth.

class FirebaseAuthService {
  static bool get isAdminLoggedIn => false;
  static bool get isSuperAdmin => false;

  static Future<Map<String, dynamic>> signInAdmin(String email, String password) async {
    return {'success': false, 'error': 'Firebase Auth no configurado. Usar PIN local.'};
  }

  static Future<void> signOut() async {}
}
