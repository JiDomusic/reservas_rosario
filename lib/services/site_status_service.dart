// Re-export from local implementation for backwards compatibility
export 'local_site_status_service.dart' show BannerSettings;
import 'local_site_status_service.dart';

class SiteStatusService {
  static Future<BannerSettings> fetchBannerSettings() {
    return LocalSiteStatusService.fetchBannerSettings();
  }

  static Future<BannerSettings> saveBannerSettings({
    required bool enabled,
    required DateTime? reopenDate,
    required String message,
  }) {
    return LocalSiteStatusService.saveBannerSettings(
      enabled: enabled,
      reopenDate: reopenDate,
      message: message,
    );
  }
}
