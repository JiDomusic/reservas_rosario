import 'supabase_service.dart';

class BannerSettings {
  final bool enabled;
  final DateTime? reopenDate;
  final String message;

  const BannerSettings({
    required this.enabled,
    required this.message,
    this.reopenDate,
  });

  BannerSettings copyWith({
    bool? enabled,
    DateTime? reopenDate,
    String? message,
  }) {
    return BannerSettings(
      enabled: enabled ?? this.enabled,
      reopenDate: reopenDate ?? this.reopenDate,
      message: message ?? this.message,
    );
  }
}

class LocalSiteStatusService {
  static const _enabledKey = 'banner_activo';
  static const _dateKey = 'banner_fecha';
  static const _textKey = 'banner_texto';

  static BannerSettings _fallback() {
    return const BannerSettings(
      enabled: false,
      reopenDate: null,
      message: 'Nos tomamos un descanso. Volvemos pronto.',
    );
  }

  static Future<BannerSettings> fetchBannerSettings() async {
    try {
      final storage = SupabaseService.instance;
      final enabled = (await storage.getConfigValue(_enabledKey)) == 'true';
      final dateStr = await storage.getConfigValue(_dateKey);
      final text = (await storage.getConfigValue(_textKey)) ?? 'Nos tomamos un descanso. Volvemos pronto.';
      final reopenDate = dateStr != null && dateStr.isNotEmpty
          ? DateTime.tryParse(dateStr)
          : null;

      return BannerSettings(
        enabled: enabled,
        reopenDate: reopenDate,
        message: text,
      );
    } catch (_) {
      return _fallback();
    }
  }

  static Future<BannerSettings> saveBannerSettings({
    required bool enabled,
    required DateTime? reopenDate,
    required String message,
  }) async {
    try {
      final storage = SupabaseService.instance;
      await storage.setConfigValue(_enabledKey, enabled.toString());
      if (reopenDate != null) {
        await storage.setConfigValue(_dateKey, reopenDate.toIso8601String().split('T')[0]);
      }
      await storage.setConfigValue(_textKey, message);
      return fetchBannerSettings();
    } catch (_) {
      return _fallback();
    }
  }
}
