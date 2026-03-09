// Subscription Service - disabled for local-only mode.
// Re-enable when connecting to Supabase for SaaS billing.

class SubscriptionService {
  static Future<Map<String, dynamic>> checkSubscriptionStatus() async {
    return {'active': true, 'message': 'Modo local - sin suscripción requerida'};
  }
}
