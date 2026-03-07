# 🔔 جرس المسابقة — Quiz Buzzer v2.0
## دليل التثبيت والإطلاق الكامل

---

## 📁 هيكل المشروع الكامل

```
quiz-buzzer/
│
├── server/                          ← السيرفر (Node.js)
│   ├── server.js                    ← الملف الرئيسي
│   ├── package.json
│   ├── .env
│   └── nginx.conf                   ← للإنتاج مع HTTPS
│
└── flutter/                         ← تطبيق Flutter
    ├── pubspec.yaml                 ← الحزم والإعدادات
    ├── web/
    │   ├── index.html               ← مطلوب للويب + صوت الجرس
    │   └── manifest.json            ← إعدادات PWA
    ├── android/
    │   ├── AndroidManifest.xml      ← إذن الإنترنت
    │   ├── build.gradle
    │   ├── settings.gradle
    │   └── gradle/wrapper/
    │       └── gradle-wrapper.properties
    ├── ios/
    │   └── Runner/
    │       └── Info.plist           ← إعدادات iOS
    └── lib/
        ├── main.dart                ← نقطة الدخول
        ├── providers/
        │   └── game_provider.dart   ← إدارة الحالة
        ├── services/
        │   └── socket_service.dart  ← Socket.IO + صوت
        └── screens/
            ├── home_screen.dart     ← اختيار الدور
            ├── host_screen.dart     ← شاشة المضيف
            └── player_screen.dart   ← شاشة اللاعب
```

---

## ⬇️ الخطوة 0 — تثبيت المتطلبات

### تثبيت Flutter SDK

**macOS:**
```bash
# الطريقة الأسهل عبر Homebrew
brew install --cask flutter

# أو تحميل يدوي
# 1. حمّل من: https://docs.flutter.dev/get-started/install/macos
# 2. فك الضغط في: ~/development/flutter
# 3. أضف للـ PATH في ~/.zshrc أو ~/.bash_profile:
export PATH="$PATH:$HOME/development/flutter/bin"
```

**Windows:**
```powershell
# الطريقة الأسهل عبر winget
winget install Flutter.Flutter

# أو تحميل يدوي:
# 1. حمّل من: https://docs.flutter.dev/get-started/install/windows
# 2. فك الضغط في: C:\flutter
# 3. أضف C:\flutter\bin لمتغير PATH في System Environment Variables
```

**Linux:**
```bash
# عبر snap
sudo snap install flutter --classic

# أو يدوياً:
# 1. حمّل من: https://docs.flutter.dev/get-started/install/linux
tar xf flutter_linux_*.tar.xz -C ~/development
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

### تثبيت Node.js (للسيرفر)
```bash
# macOS
brew install node

# Windows — حمّل من:
# https://nodejs.org/en/download (اختر LTS)

# Linux
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### تحقق من التثبيت
```bash
flutter --version   # يجب أن يظهر: Flutter 3.x.x
node --version      # يجب أن يظهر: v18.x.x أو أحدث
npm --version       # يجب أن يظهر: 9.x.x أو أحدث
```

---

## 🖥️ الخطوة 1 — تشغيل السيرفر

```bash
cd quiz-buzzer/server

# تثبيت الحزم (مرة واحدة فقط)
npm install

# تشغيل السيرفر
node server.js

# ✅ ستجد:
# 🚀 السيرفر يعمل على: http://localhost:3000
```

> للتطوير مع إعادة تشغيل تلقائي عند تعديل الكود:
> ```bash
> npx nodemon server.js
> ```

---

## ⚙️ الخطوة 2 — ضبط عنوان السيرفر

افتح `flutter/lib/services/socket_service.dart` وعدّل هذا السطر:

```dart
static const String serverUrl = 'http://192.168.1.100:3000';
//                                       ↑
//  استبدلها بـ IP جهازك على الشبكة
```

**كيف أعرف IP جهازي؟**
```bash
# macOS / Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# Windows
ipconfig | findstr "IPv4"

# مثال النتيجة: 192.168.1.105
# إذن الرابط سيكون: http://192.168.1.105:3000
```

---

## 🌐 الخطوة 3أ — تشغيل على المتصفح

```bash
cd quiz-buzzer/flutter

# تثبيت الحزم (مرة واحدة)
flutter pub get

# تفعيل دعم الويب (مرة واحدة)
flutter config --enable-web

# تشغيل مباشرة في Chrome
flutter run -d chrome

# ─── أو بناء للنشر ───────────────────────────
flutter build web --release
# الناتج في: build/web/
# ارفع هذا المجلد على Netlify أو Firebase
```

**رفع على Netlify مجاناً (30 ثانية):**
1. افتح https://app.netlify.com/drop
2. اسحب مجلد `build/web/` وأفلته
3. احصل على رابط مثل: `https://quiz-buzzer-abc123.netlify.app` ✅

> ⚠️ على الويب في الإنتاج: السيرفر يجب أن يكون على `https://` وليس `http://`

---

## 📱 الخطوة 3ب — تشغيل على الأندرويد

```bash
# 1. تثبيت Android Studio من:
#    https://developer.android.com/studio

# 2. تحقق من الإعداد
flutter doctor
# يجب أن يظهر ✓ بجانب Android toolchain

# 3. على الجهاز الحقيقي:
#    الإعدادات ← حول الهاتف ← اضغط رقم البناء 7 مرات
#    ثم: الإعدادات ← خيارات المطور ← فعّل USB Debugging
#    وصّل الجهاز بـ USB

# 4. تشغيل
flutter devices     # تأكد يظهر جهازك
flutter run         # يثبت ويشغّل مباشرة

# 5. بناء APK للتوزيع المباشر
flutter build apk --release
# الملف في: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🍎 الخطوة 3ج — تشغيل على iOS (يحتاج Mac + Xcode)

```bash
# 1. ثبّت Xcode من App Store

# 2. ثبّت CocoaPods
sudo gem install cocoapods

# 3. ثبّت iOS dependencies
cd quiz-buzzer/flutter/ios
pod install
cd ..

# 4. افتح في Xcode لضبط التوقيع
open ios/Runner.xcworkspace
# في Xcode: Runner ← Signing & Capabilities ← اختر Team

# 5. شغّل على محاكي
flutter run -d iphone

# 6. بناء للنشر
flutter build ios --release
# ثم من Xcode: Product ← Archive ← Distribute App
```

---

## 🎮 محاكاة جلسة مسابقة كاملة

| الخطوة | الجهاز | الإجراء |
|--------|--------|---------|
| 1 | الجهاز A | اختر "أنا المضيف" ← "إنشاء جلسة جديدة" |
| 2 | الجهاز B | اختر "أنا لاعب" ← أدخل الاسم + الكود |
| 3 | الجهاز C | نفس الخطوة |
| 4 | الجهاز A | اضغط "فتح الجرس" |
| 5 | B و C | اضغطوا الجرس بأسرع ما يمكن! |
| 6 | الجميع | يظهر الترتيب الكامل بالوقت ms |

---

## 🚀 النشر في الإنتاج

### نشر السيرفر على Render (مجاني):
1. ارفع مجلد `server/` على GitHub
2. افتح https://render.com ← New Web Service
3. اربطه بالـ repo
4. Start Command: `node server.js`
5. أضف Environment Variable: `NODE_ENV=production`
6. ستحصل على رابط مثل: `https://quiz-buzzer.onrender.com`

### تحديث رابط السيرفر في Flutter:
```dart
// في socket_service.dart
static const String serverUrl = 'https://quiz-buzzer.onrender.com';
```

ثم أعد البناء:
```bash
flutter build web --release    # للويب
flutter build apk --release    # للأندرويد
```

---

## ✅ ملخص التغييرات في v2.0
- 🥇 الأول بدل الكاس في جميع الشاشات
- ترتيب جميع الضاغطين بالوقت (ms) مع ميداليات ذهب/فضة/برونز
- زر 🔊 / 🔇 تشغيل وإيقاف الصوت في كل شاشة
- صوت الجرس عبر Web Audio API (بدون ملفات خارجية)
- السيرفر يسجّل ويبث ترتيب كل الضاغطين
- جميع النصوص بصيغة المذكر
