# SETUP.md — Konfigurasi manual Rent Camera App

Dokumen ini mencatat langkah yang **harus dijalankan pemilik project** di luar kode.
Isinya tidak boleh dianggap sudah selesai: periksa bagian "Status saat ini" lebih dulu.

## 0. Status saat ini

| Item | Status | Bukti |
|---|---|---|
| `lib/firebase_options.dart` | **Ada** (hasil `flutterfire configure`, bukan tulisan manual) | memuat entri `android`, `ios`, `macos`, `web`, `windows` untuk project `rent-camera-app` |
| `android/app/google-services.json` | **Ada** | `Test-Path` = True |
| Plugin Gradle `com.google.gms.google-services` | **Terpasang** (`4.4.4`) | `android/settings.gradle.kts` + `android/app/build.gradle.kts` |
| `firebase.json` | **Ada** | menunjuk project `rent-camera-app` beserta file output per platform |
| `ios/Runner/GoogleService-Info.plist` | Belum ada | `Test-Path` = False (target iOS belum dikonfigurasi) |
| Provider Email/Password & Google | Email/Password bekerja pada uji manual web; Google belum diuji | `flutter run -d chrome` membentuk sesi `signedIn` (Email/Password); Google butuh `GOOGLE_SERVER_CLIENT_ID` + SHA terdaftar |
| SHA-1/SHA-256 Android | Belum diverifikasi | — |
| `firebase/firestore.rules`, `firebase/storage.rules` | Belum ada | dikerjakan pada fase model/rules |
| `--dart-define` nilai project | Belum diisi | lihat §3 |
| Login end-to-end | Sebagian | sesi Auth nyata terbentuk di web; penulisan `users/{uid}`, Google Sign-In, dan reset kata sandi belum diverifikasi |

Karena itu `lib/core/firebase/firebase_bootstrap.dart` memakai opsi eksplisit dari
`lib/firebase_options.dart` (lihat §2). Selama konfigurasi platform yang dipakai belum
lengkap, aplikasi menampilkan layar "Firebase belum dikonfigurasi" (bukan form login)
beserta kode diagnostik dan sumber konfigurasi yang dibutuhkan. Ini disengaja agar
aplikasi tidak mengklaim autentikasi berjalan padahal inisialisasi Firebase gagal.

## 1. Prasyarat tooling

| Tool | Versi terverifikasi pada mesin pengembangan |
|---|---|
| Flutter | stable `3.47.3` (revision `e8113bf456`) |
| Dart | `3.13.3` |
| Firebase CLI | `14.6.0` |
| flutterfire_cli | `1.2.0` (global Dart package, **belum** ada di PATH) |
| Android SDK | platform `android-34`, `android-35` terpasang; **`android-36` belum** |

Perintah `flutterfire` dapat dijalankan tanpa menambah PATH:

```bash
dart pub global run flutterfire_cli:flutterfire configure
```

`flutter doctor` masih melaporkan kebutuhan Android SDK 36 untuk build Android.
Pasang platform tersebut (Android Studio SDK Manager atau `sdkmanager "platforms;android-36"`)
sebelum mencoba `flutter build apk`.

## 2. Langkah Firebase

1. **Buat project Firebase** lalu daftarkan aplikasi Android (dan iOS bila diperlukan).
   - Android `applicationId` saat ini masih `com.example.rent_camera_app`
     (`android/app/build.gradle.kts`). Ganti ke ID unik atau pertahankan untuk demo kelas.
2. **Jalankan `flutterfire configure`** di root project:
   ```bash
   dart pub global run flutterfire_cli:flutterfire configure
   ```
   Perintah ini membuat `lib/firebase_options.dart`, `android/app/google-services.json`,
   `ios/Runner/GoogleService-Info.plist`, dan menambahkan plugin Gradle
   `com.google.gms.google-services`. Untuk Android langkah itu **sudah terjadi**
   (`google-services.json` ada, plugin `4.4.4` terpasang). Untuk iOS,
   `GoogleService-Info.plist` belum ada sehingga target iOS belum siap.
3. **Aktifkan provider** Email/Password dan Google di Firebase Console →
   Authentication → Sign-in method.
4. **Daftarkan SHA-1/SHA-256** build Android (wajib untuk Google Sign-In):
   ```bash
   cd android && ./gradlew signingReport
   ```
   Salin fingerprint ke Firebase Console → Project settings → Your apps.
5. **Server client ID Google** (dipakai aplikasi lewat `--dart-define`):
   Firebase Console → Authentication → Sign-in method → Google → Web SDK configuration.
   Untuk iOS, salin juga `CLIENT_ID` dari `GoogleService-Info.plist`.

### Bagaimana aplikasi menginisialisasi Firebase

`lib/main.dart` memanggil `WidgetsFlutterBinding.ensureInitialized()`, lalu
`FirebaseBootstrap.initialize()` di `lib/core/firebase/firebase_bootstrap.dart`
menjalankan:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

Opsi eksplisit ini wajib: web dan desktop tidak punya berkas konfigurasi native,
sehingga `Firebase.initializeApp()` tanpa opsi gagal dengan assertion
"FirebaseOptions cannot be null when creating the default app." (inilah penyebab
crash saat dijalankan di web sebelum bootstrap memakai `firebase_options.dart`).

Bootstrap **tidak pernah melempar exception**. Kegagalan diterjemahkan menjadi kode
diagnostik yang aman ditampilkan (tanpa kredensial dan tanpa pesan SDK mentah):

| Kode | Arti | Tindakan |
|---|---|---|
| `no-app`, `invalid-api-key`, dsb. | kode dari SDK Firebase | periksa nilai pada `lib/firebase_options.dart` / `google-services.json` |
| `unsupported-platform` | `flutterfire configure` belum mendaftarkan platform ini | jalankan `flutterfire configure` untuk platform tersebut |
| `flutter-binding-unavailable` | binding Flutter belum siap saat bootstrap berjalan | pastikan `WidgetsFlutterBinding.ensureInitialized()` mendahului bootstrap (`lib/main.dart` sudah begitu) |
| `plugin-unavailable` | plugin native Firebase belum terdaftar | jalankan ulang aplikasi (bukan hot reload) setelah plugin/Gradle berubah |
| `options-unavailable` | opsi Firebase tidak terbaca saat app dibuat | lengkapi `lib/firebase_options.dart` lewat `flutterfire configure` |
| `initialization-failed` | penyebab lain | lihat log platform; layar setup hanya menampilkan kode ini |

Layar setup juga menampilkan **sumber konfigurasi** platform yang sedang berjalan
(`FirebaseBootstrap.describeConfigurationSource()`), mis. bagian `web` pada
`lib/firebase_options.dart` atau `android/app/google-services.json`.

## 3. Nilai konfigurasi lewat `--dart-define`

Semua nilai milik project dipasok saat build/run, bukan ditulis di source code
(lihat `lib/core/config/app_config.dart`):

| Nama | Wajib? | Kegunaan | Nilai saat ini |
|---|---|---|---|
| `APP_NAME` | disarankan | Nama/brand aplikasi pada app bar dan judul | default `Rent Camera App` |
| `ADMIN_LOGIN_ALIAS` | opsional | Alias username untuk akun admin | default `admin` |
| `ADMIN_EMAIL` | opsional | Email akun admin yang dipetakan dari alias | **kosong** → alias ditolak |
| `GOOGLE_SERVER_CLIENT_ID` | untuk Google Sign-In | Server (web) client ID | **kosong** |
| `GOOGLE_IOS_CLIENT_ID` | untuk iOS | Client ID OAuth iOS | **kosong** |

Contoh menjalankan aplikasi:

```bash
flutter run --dart-define=APP_NAME="Nama Brand" \
  --dart-define=ADMIN_EMAIL=<email-admin-yang-dikonfigurasi> \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Catatan keamanan: alias `admin` **bukan** bypass autentikasi. Password tetap
divalidasi Firebase Authentication, dan role admin hanya berasal dari custom claim
`{ "admin": true }` pada ID token. Password `pass` tidak boleh ditulis di source code.

## 4. Admin dan security rules

- Skrip pemberian custom claim (`scripts/grant_admin.mjs`, Firebase Admin SDK)
  **belum dibuat**; itu bagian dari fase dashboard admin. Skrip seperti itu hanya
  boleh dijalankan di lingkungan tepercaya dan tidak dari aplikasi Flutter.
- `firebase/firestore.rules` dan `firebase/storage.rules` **belum ada** dan belum
  dideploy. Sampai rules dibuat, dokumen `users/{uid}` hasil register/login dapat
  gagal ditulis bila project memakai mode produksi (default deny). Aplikasi akan
  menampilkan pesan peringatan yang jelas (bukan "sukses" palsu) pada kondisi itu.
- Jangan commit service-account JSON, private key, atau file kredensial.

## 5. Verifikasi yang bisa dijalankan sekarang

```bash
dart format lib test     # 46 file diperiksa, 0 diubah
flutter analyze          # No issues found! (ran in 7.4s)
flutter test             # All tests passed! (71 test)
flutter run -d chrome    # dijalankan: melewati `main()`, berhenti di #/login; uji
                         # manual di halaman yang sama berlanjut ke #/register
                         # lalu #/catalog → bootstrap web memakai bagian `web`
                         # pada firebase_options.dart dan sesi Auth nyata terbentuk
flutter run -d <emulator> # butuh konfigurasi Firebase untuk melewati layar setup
```

Catatan: `flutter test --platform chrome test/core/firebase/firebase_bootstrap_test.dart`
**tidak dipakai** pada pemeriksaan ini karena browser host-nya berhenti di
`http://localhost:<port>/static/index.html` ("Flutter Test Browser Host") tanpa
pernah melaporkan hasil (dipantau: CPU tool `0.0s` selama 20 detik, jadi bukan
sekadar kompilasi lambat). Verifikasi web dikerjakan lewat `flutter run -d chrome`:

- aplikasi melewati `main()` tanpa assertion "FirebaseOptions cannot be null when
  creating the default app." dan masuk ke `#/login`;
- uji manual di halaman yang sama berlanjut ke `#/register` lalu `#/catalog`.
  `resolveAuthRedirect` hanya mengarahkan ke `/catalog` bila
  `isFirebaseConfigured == true` **dan** sesi `signedIn`, sehingga bootstrap web
  memakai entri `web` pada `firebase_options.dart` dan Firebase Auth web benar-benar
  membuat sesi;
- halaman tersebut juga mengekspor global web SDK FlutterFire (`firebase_core`,
  `firebase_auth`, `firebase_firestore`).

Yang **tidak** dibuktikan oleh uji manual di atas: penulisan dokumen `users/{uid}`
(rules belum dideploy) dan Google Sign-In (butuh `GOOGLE_SERVER_CLIENT_ID`).

Test yang tersedia tidak memerlukan kredensial: validator form, pemetaan pesan
error, keputusan route guard, resolusi alias login, pemantauan sesi auth, form
login/register, kontrak bootstrap Firebase (kode diagnostik + sumber konfigurasi),
serta alur bootstrap → login → katalog memakai stream sesi palsu.

Yang **belum** diverifikasi (butuh kredensial/uji manual di project Firebase):

- register email/password sungguhan dan penulisan dokumen `users/{uid}`;
- login email/password dan Google Sign-In end-to-end (termasuk ID token dari Google);
- pengiriman email reset kata sandi;
- aturan Firestore/Storage (rules belum dibuat dan belum dideploy).

## 6. Aset dan keputusan yang masih ditunggu pemilik

Daftar lengkap ada di `IMPLEMENTATION_PLAN.md` §3. Yang paling dekat dengan fase ini:

1. Nama/brand aplikasi final (`APP_NAME`).
2. Email admin yang dikontrol pemilik (`ADMIN_EMAIL`) dan metode pemberian claim.
3. Provider login yang diaktifkan (Email/Password, Google) di Firebase Console + SHA-1/SHA-256 Android. Project Firebase dan hasil `flutterfire configure` sudah selesai (lihat §0).
4. Keputusan `applicationId` Android (unik atau tetap `com.example.rent_camera_app`).

## 7. Penyelesaian blocker

| Blocker | Cara menyelesaikan |
|---|---|
| Crash/assertion *"FirebaseOptions cannot be null when creating the default app."* di web/desktop | sudah diperbaiki: bootstrap memakai `DefaultFirebaseOptions.currentPlatform` (§2). Pastikan `lib/firebase_options.dart` ada, lalu jalankan ulang (bukan hot reload) |
| Layar setup muncul terus | ikuti §2, lalu jalankan ulang aplikasi (hot restart). Kode diagnostik di layar menunjukkan penyebabnya |
| `flutter doctor` mengeluh Android SDK 36 | pasang platform `android-36` |
| `flutterfire` tidak dikenali | pakai `dart pub global run flutterfire_cli:flutterfire` atau tambahkan folder bin Pub global ke PATH |
| Google Sign-In gagal dengan pesan konfigurasi | isi `GOOGLE_SERVER_CLIENT_ID`, daftarkan SHA-1/SHA-256, aktifkan provider Google |
| Dokumen profil gagal disinkronkan | deploy Firestore Security Rules pada fase rules; aplikasi menampilkan peringatan ini apa adanya |

