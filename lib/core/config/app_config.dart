/// تنظیمات ثابت برنامه.
///
/// آدرس‌ها هنگام اجرا تعیین می‌شوند، نه داخل کد:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
class AppConfig {
  AppConfig._();

  /// آدرس Backend.
  /// - امولاتور اندروید:  http://10.0.2.2:8000
  /// - گوشی واقعی با adb reverse:  http://127.0.0.1:8000
  /// - سرور واقعی: حتماً https
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// سرویس مسیریابی (سازگار با OSRM) برای کشیدن مسیر روی خیابان‌ها.
  /// سرور عمومی demo فقط برای آزمایش است؛ برای استفاده‌ی واقعی OSRM
  /// اختصاصی بالا بیاورید و با --dart-define=ROUTING_URL=... آدرسش را بدهید.
  static const String routingBaseUrl = String.fromEnvironment(
    'ROUTING_URL',
    defaultValue: 'https://router.project-osrm.org',
  );

  /// حداکثر زمان انتظار برای پاسخ هر درخواست.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// حداکثر زمان انتظار برای سرویس مسیریابی (اگر نرسید، خط مستقیم می‌کشیم).
  static const Duration routingTimeout = Duration(seconds: 8);

  /// فاصله بررسی دوره‌ای وضعیت سفر وقتی اتصال زنده در دسترس نیست.
  static const Duration livePollInterval = Duration(seconds: 15);

  /// تایل نقشه‌ی OpenStreetMap. برای انتشار عمومی از یک سرویس تایل مناسب خودتان
  /// استفاده کنید (سیاست OSM برای ترافیک بالا مناسب نیست):
  ///   --dart-define=TILE_URL=https://.../{z}/{x}/{y}.png
  static const String tileUrl = String.fromEnvironment(
    'TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// آینه‌ی OSM برای وقتی که سرور اصلی تایل در دسترس نیست.
  static const String tileFallbackUrl = String.fromEnvironment(
    'TILE_FALLBACK_URL',
    defaultValue: 'https://a.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
  );

  /// مرکز پیش‌فرض نقشه (زنجان) وقتی نقطه‌ای برای نمایش نیست.
  static const double defaultLat = 36.6765;
  static const double defaultLng = 48.4963;

  /// شناسه بسته برای درخواست‌های تایل نقشه.
  static const String userAgentPackage = 'ir.hammasir.driver';
}
