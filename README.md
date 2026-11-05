# هم‌مسیر راننده

اپ Flutter راننده برای سرویس ایاب‌وذهاب «هم‌مسیر» (پروژه‌ی جدا از اپ دانشجو، با همان قالب و زبان طراحی).

## قابلیت‌ها
- سفرهای امروز و فردا، شروع سوار کردن ← حرکت ← پایان سفر
- فهرست مسافران، تأیید «سوار شد» و تأیید/رد درخواست سوار شدن
- **ارسال موقعیت دقیق و کم‌مصرف** (پایین‌تر توضیح داده شده)
- **اعلام خرابی** (نوع، توضیح، «می‌توانم ادامه دهم»، موقعیت خودکار) با صف آفلاین
- فارسی/انگلیسی، تم روشن/تیره، ورود با اثر انگشت، اعلان‌ها

## ردیابی موقعیت
- با «شروع سوار کردن» ردیابی شروع و با «پایان سفر» (یا وقتی سرور سفر را غیرفعال بداند) متوقف می‌شود.
- اگر اپ بسته/دوباره باز شود و سفر هنوز فعال باشد، ردیابی خودکار ادامه پیدا می‌کند.
- روی اندروید با **سرویس پیش‌زمینه** (اعلان ثابت) اجرا می‌شود تا با خاموش شدن صفحه قطع نشود.
- فیلتر نقاط: دقت بدتر از ۵۰ متر و پرش‌های غیرممکن (بیش از ۱۵۰ km/h) دور ریخته می‌شوند.
- زمان هر نقطه، زمان واقعی گرفتن آن است؛ نقاط به‌صورت دسته‌ای (تا ۱۰۰ تایی) و با همان زمان ارسال می‌شوند.
- بدون اینترنت: نقاط روی گوشی ذخیره می‌شوند (تا ۲۰۰۰ نقطه) و با وصل شدن ارسال می‌شوند.

| شارژ | دقت GPS | حداقل جابه‌جایی | ضربان (ایستاده) | ارسال دسته‌ای |
|---|---|---|---|---|
| عادی (>۳۰٪ یا در حال شارژ) | بالا | ۱۵ متر | ۳۰ ثانیه | ۵ ثانیه |
| کم (≤۳۰٪) | بالا | ۴۰ متر | ۶۰ ثانیه | ۲۰ ثانیه |
| بحرانی (≤۱۰٪) | بالا | ۸۰ متر | ۹۰ ثانیه | ۴۵ ثانیه |

دقت GPS عمداً در همه‌ی حالت‌ها «بالا» می‌ماند؛ صرفه‌جویی از کم‌کردن تعداد نمونه‌ها و بسته‌بندی ارسال‌ها (کمتر شدن بیدار شدن رادیو) می‌آید. در شارژ کم، یک هشدار روی صفحه می‌آید.

## اجرا
```
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```
گوشی واقعی: آدرس سرور را بدهید یا `adb reverse tcp:8000 tcp:8000` و آدرس `http://127.0.0.1:8000`.
اپ به بک‌اندی نیاز دارد که `app/api/driver_self.py` را دارد (راهنما: `BACKEND_PATCH_DRIVER.md`).

## ساخت پوشه‌های android/ios
این زیپ فقط کد برنامه را دارد. یک بار:
```
flutter create --org ir.hammasir --project-name hammasir_driver --platforms=android,ios .
dart run flutter_launcher_icons
```
سپس تنظیمات زیر را اعمال کنید (برای حل مشکل Gradle: پروکسی `127.0.0.1:8580` را از `~/.gradle/gradle.properties` بردارید).

### Android — `android/app/src/main/AndroidManifest.xml`
داخل `<manifest>` (بیرون از `<application>`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```
- `MainActivity` باید از `FlutterFragmentActivity` ارث ببرد (برای اثر انگشت) و تم `Theme.AppCompat.Light.NoActionBar` باشد.
- `minSdk` حداقل ۲۱. در Android 13+ مجوز اعلان و در Android 10+ «موقعیت: همیشه/هنگام استفاده» را بدهید.
- **مهم برای دقت در پس‌زمینه:** در تنظیمات گوشی برای این اپ «Battery → Unrestricted / بدون محدودیت» را بزنید؛ بعضی برندها (شیائومی، سامسونگ، هوآوی) سرویس را می‌کُشند.

### iOS — `ios/Runner/Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key><string>برای ارسال موقعیت خودرو به دانشجویان</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key><string>برای ادامه‌ی ارسال موقعیت هنگام بسته بودن صفحه</string>
<key>NSFaceIDUsageDescription</key><string>ورود سریع با اثر انگشت/چهره</string>
<key>UIBackgroundModes</key><array><string>location</string></array>
```

## ساختار
`lib/core/tracking/` منطق ردیابی (سیاست باتری، فیلتر، صف، کنترلر) · `lib/features/trips` · `lib/features/breakdown` · `lib/data/repositories/driver_repository.dart`

## وضعیت راستی‌آزمایی
در محیط ساخت، Flutter SDK نبود: کد فقط با بررسی نحو و وجود importها و کلیدهای ترجمه چک شده و **هنوز کامپایل/اجرا نشده**. بک‌اند (`driver_self.py`) با تست یکپارچه روی SQLite آزمایش شده. بعد از `flutter pub get` حتماً `flutter analyze` و `flutter test` را اجرا کنید و خطاها را بفرستید.
