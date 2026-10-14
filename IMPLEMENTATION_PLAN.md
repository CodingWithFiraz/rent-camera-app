# IMPLEMENTATION_PLAN.md

Implementation plan bertahap untuk aplikasi **rent_camera_app** (penyewaan alat foto/video + portofolio jasa).

Sumber kebenaran:
- `docs/BLUEPRINT_APLIKASI.md` (spesifikasi produk & arsitektur).
- `.clinerules/01-product-and-architecture.md`, `.clinerules/02-workflow-security-quality.md` (aturan proyek).
- `docs/PROMPT_CLINE_BERTAHAP.md` (prompt per fase).

> **Status dokumen:** hasil **Prompt 0 — Audit & Rencana**. Belum ada fitur aplikasi yang diimplementasikan pada task ini. Seluruh fase pada rencana ini berstatus `Not started`.

## Cara memakai dokumen ini

- Satu task Cline = satu fase. Kerjakan hanya fase yang diminta, berhenti, lalu review sebelum menjalankan fase berikutnya.
- Label status: `Not started`, `In progress`, `Partially complete`, `Complete`, `Blocked`.
- Status hanya boleh diperbarui berdasarkan bukti nyata (command yang benar-benar dijalankan beserta hasilnya). UI/mock/hardcoded data **tidak boleh** ditandai `Complete`.
- Setelah setiap fase: `dart format` pada file yang berubah, `flutter analyze`, unit test relevan, lalu `git diff --check` + `git status --short` **bila** repository Git sudah tersedia (lihat bagian Blocker).

## Ringkasan status fase

| Fase | Judul | Status |
|---|---|---|
| 0 | Audit repository & implementation plan | Selesai (dokumen ini) |
| 1 | Fondasi aplikasi & autentikasi | Partially complete — kode & test selesai; verifikasi runtime terblokir konfigurasi Firebase |
| 2 | Model, repository, schema, security rules, data setup | Partially complete — kode & test selesai; rules/index/seed belum dideploy & belum diuji emulator |
| 3 | Katalog, carousel, search/filter, detail produk, realtime | Partially complete — kode & test selesai (`flutter test` 175 lulus); verifikasi runtime Firestore/banner/foto terblokir |
| 4 | Keranjang, validasi harga/stok, kalkulasi, WhatsApp | Not started |
| 5 | Portofolio/rate card & profil pengguna | Not started |
| 6 | Dashboard admin & CRUD produk | Not started |
| 7 | Integrasi, security hardening, accessibility, test, build validation | Not started |

## 1. Hasil audit repository

### 1.1 Environment (terverifikasi)

| Item | Nilai | Sumber |
|---|---|---|
| Flutter | stable `3.47.3` (revision `e8113bf456`) | `flutter --version` |
| Dart | `3.13.3` stable, windows_x64 | `dart --version` |
| DevTools | `2.60.0` | `flutter --version` |
| OS | Windows 11 25H2 (10.0.26200.9550), locale en-US | `flutter doctor -v` |
| Android SDK | platform terpasang: `android-34`, `android-35` (belum ada `android-36`); build-tools `34.0.0`, `35.0.0`, `35.0.1`, `36.0.0`; cmdline-tools `latest` | `flutter doctor -v` + listing SDK |
| Emulator | 1 AVD tersedia: `Pixel_8_API_31`. Tidak ada emulator/device Android yang berjalan | `flutter emulators`, `flutter devices` |
| Device aktif | Windows (desktop), Chrome (web), Edge (web) | `flutter devices` |
| Tooling Firebase | Firebase CLI `14.6.0` tersedia; `flutterfire_cli 1.2.0` terpasang sebagai global Dart package **tetapi** binary `flutterfire` belum ada di PATH | `firebase --version`, `dart pub global list`, `flutterfire --version` → not found |

Catatan `flutter doctor -v`:
- `[X] Android toolchain` — pesan *"Flutter requires Android SDK 36 and the Android BuildTools 28.0.3"*. Build Android belum siap sampai platform `android-36` dipasang.
- `[!] Visual Studio — develop Windows apps` — workload "Desktop development with C++" belum lengkap. Tidak relevan untuk target mobile.
- `[√] Chrome`, `[√] Network resources`.
- iOS: konfigurasi/build iOS hanya dapat divalidasi di macOS + Xcode, jadi **tidak dapat diverifikasi** pada mesin Windows ini.

### 1.2 Struktur repository

- **Bukan repository Git**: `git rev-parse --is-inside-work-tree` → `fatal: not a git repository`. Konsekuensi: `git status --short` dan `git diff --check` tidak dapat dijalankan sampai `git init` dilakukan (keputusan pemilik).
- Isi root: `.clinerules/`, `.dart_tool/`, `.idea/`, `android/`, `build/`, `docs/`, `ios/`, `lib/`, `linux/`, `macos/`, `test/`, `web/`, `windows/`, `.gitignore`, `.metadata`, `analysis_options.yaml`, `pubspec.yaml`, `pubspec.lock`, `README.md`, `rent_camera_app.iml`.
- Kode Dart: `lib/main.dart` (bootstrap Firebase + `ProviderScope`), `lib/app.dart`, `core/**`, dan `features/**` — struktur feature-first Fase 1 (sebelumnya hanya template `flutter create`).
- Test: `test/` berisi 8 file test Fase 1 (validator, error mapper, route guard, alias login, sesi auth, form login/register, alur bootstrap→login→katalog). `test/widget_test.dart` (smoke test counter template) sudah **diganti** karena widget `MyApp` dihapus.
- Platform tersedia (skeleton default): android, ios, web, windows, linux, macos. **Target produk: Android + iOS.**
- Belum ada folder `firebase/`, `scripts/`, `assets/`. `SETUP.md` sekarang **ada** (dibuat pada Fase 1) dan mencatat seluruh langkah setup manual.

### 1.3 pubspec.yaml & pubspec.lock

- `pubspec.yaml`: name `rent_camera_app`, `version: 1.0.0+1`, `environment.sdk: ^3.13.3`; dependencies: `flutter`, `cupertino_icons ^1.0.8`; dev_dependencies: `flutter_test`, `flutter_lints ^6.0.0`. Tidak ada `assets:`/`fonts:` aktif.
- `pubspec.lock`: **tidak ada** paket `firebase_*`, `cloud_firestore`, `google_sign_in`, `flutter_riverpod`, `go_router`, `url_launcher`, `image_picker`, `cached_network_image`, maupun `intl`. Hanya paket template/transitive (`async`, `collection`, `meta`, `matcher`, `test_api`, `leak_tracker*`, `vm_service`, dll). `sdks: dart ">=3.13.3 <4.0.0"`, `flutter ">=3.18.0-18.0.pre.54"`.
- **Diperbarui pada Fase 1**: stack sudah ditambahkan lewat `flutter pub add` dan versinya terverifikasi di `pubspec.lock`: `firebase_core 4.15.0`, `firebase_auth 6.7.0`, `cloud_firestore 6.10.0`, `google_sign_in 7.2.0`, `flutter_riverpod 3.4.3` (Riverpod 3), `go_router 18.0.2`. API paket sudah dicek langsung ke source di Pub cache: `GoogleSignIn.instance` + `initialize()` + `authenticate()` + `account.authentication.idToken`, `Notifier`/`NotifierProvider` Riverpod 3, dan `GoRouter(redirect/refreshListenable/initialLocation)`. Sisa paket blueprint (`image_picker`, `url_launcher`, `cached_network_image`, `intl`) belum ditambahkan karena belum dipakai pada Fase 1.

### 1.4 analysis_options.yaml

- `include: package:flutter_lints/flutter.yaml` (flutter_lints 6.0.0); `analyzer.exclude`: `build/**` dan seluruh folder platform. Tidak ada rule kustom tambahan.

### 1.5 Quality gate baseline (sudah dijalankan)

| Command | Hasil |
|---|---|
| `flutter analyze` | `No issues found! (ran in 50.1s)` |
| `flutter test` | `00:25 +1: All tests passed!` (1 test: smoke test counter) |

Catatan: kedua hasil di atas mengukur **template bawaan**, bukan fitur produk. Setelah Fase 1 mengganti root aplikasi, `test/widget_test.dart` (menguji `MyApp` counter) tidak lagi relevan dan harus diperbarui/diganti pada fase yang sama — bukan dihapus tanpa pengganti.

### 1.6 Kode yang sudah bekerja dan harus dipertahankan

| Item | Alasan dipertahankan |
|---|---|
| Skeleton platform `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` | Output `flutter create` yang valid; cukup ditambah konfigurasi, jangan dihapus/dibuat ulang |
| `android/app/build.gradle.kts` (Java/Kotlin 17, plugin Flutter) dan `android/settings.gradle.kts` (AGP `9.1.0`, Kotlin `2.4.0`) | Konfigurasi build yang sudah jalan; perubahan hanya penambahan bila perlu |
| `analysis_options.yaml`, `.gitignore`, `.metadata`, `README.md` | Konfigurasi proyek; `.metadata` dipakai tooling Flutter |
| `lib/main.dart` | Entry point aplikasi. Isinya masih counter demo; pada Fase 1 file ini dijadikan titik masuk `runApp` yang direfactor (bukan dihapus diam-diam) |
| `test/widget_test.dart` | Test yang saat ini hijau; pada Fase 1 diganti dengan test yang relevan |
| `docs/BLUEPRINT_APLIKASI.md`, `docs/PROMPT_CLINE_BERTAHAP.md`, `.clinerules/*` | Sumber kebenaran & aturan proyek; jangan diubah tanpa alasan |

Tidak ada file yang dihapus, dipindah, atau ditimpa pada task audit ini.

### 1.7 Status konfigurasi Firebase / Google Sign-In / rules / tooling

Semua pemeriksaan berikut bernilai **tidak ada / belum terkonfigurasi** (hasil `Test-Path` = `False` untuk seluruh path):

| Item | Path | Status |
|---|---|---|
| Firebase config Android | `android/app/google-services.json` | ✅ Ada |
| Firebase config iOS | `ios/Runner/GoogleService-Info.plist` | Belum ada |
| Firebase options Dart | `lib/firebase_options.dart` | ✅ Ada (hasil `flutterfire configure`; entri `android`, `ios`, `macos`, `web`, `windows`) |
| Firestore rules | `firebase/firestore.rules` | Belum ada |
| Storage rules | `firebase/storage.rules` | Belum ada |
| Firebase project config | `firebase.json` | ✅ Ada (project `rent-camera-app`); `.firebaserc` belum ada |
| Script admin/seed | `scripts/` (`grant_admin.mjs`, seed sample) | Belum ada |
| Dokumentasi setup | `SETUP.md` | ✅ Ada |
| Bootstrap Firebase | `lib/core/firebase/firebase_bootstrap.dart` | ✅ Ada — `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` di dalam try/catch → status + kode diagnostik, tidak pernah melempar exception |

Tabel di atas diperbarui setelah konfigurasi Firebase dibuat; status terbaru ada di `SETUP.md` §0.

Catatan tambahan:
- Android: plugin Gradle `com.google.gms.google-services` **4.4.4 sudah diterapkan** (`android/settings.gradle.kts`, `android/app/build.gradle.kts`); `applicationId` dan `namespace` masih `com.example.rent_camera_app` (masih ada TODO *"Specify your own unique Application ID"*). Belum ada SHA-1/SHA-256 terdaftar untuk Google Sign-In.
- iOS: `ios/Runner/Info.plist` masih default (`CFBundleDisplayName` = "Rent Camera App"); belum ada `CFBundleURLTypes`/`REVERSED_CLIENT_ID` untuk Google Sign-In.
- `local.properties` ada (build lokal), isinya tidak ditampilkan karena berisi path SDK lokal.
- Firebase Emulator Suite belum mungkin dijalankan karena `firebase/firestore.rules` dan `firebase/storage.rules` belum ada (walaupun `firebase.json` sudah ada). Tooling tersedia: Firebase CLI `14.6.0`; `flutterfire_cli 1.2.0` terpasang global tetapi belum ada di PATH → jalankan dengan `dart pub global run flutterfire_cli:flutterfire ...` atau tambahkan folder bin Pub global ke PATH.
- Pemetaan kode diagnostik bootstrap (`FirebaseBootstrap.diagnosticCodeFor`) diuji lewat `test/core/firebase/firebase_bootstrap_test.dart`. Subtlety: `FlutterError implements AssertionError`, jadi cabang `FlutterError` (binding belum siap → `flutter-binding-unavailable`) diperiksa lebih dulu agar error binding tidak salah dilaporkan sebagai `options-unavailable`. Di VM test, `Firebase.initializeApp` gagal dengan `PlatformException(channel-error)` → `plugin-unavailable`. Di web/Chrome, bootstrap berhasil memakai entri `web` pada `firebase_options.dart`: dibuktikan dengan `flutter run -d chrome` yang berhenti di route `#/login` (bukan `#/setup-required`) dan mengekspor global web SDK FlutterFire (`firebase_core`, `firebase_auth`, `firebase_firestore`). `flutter test --platform chrome` tidak bisa dipakai di lingkungan ini karena browser host-nya berhenti di "Flutter Test Browser Host" tanpa melaporkan hasil (CPU 0% saat dipantau).
- Tidak ada secret, service-account JSON, private key, atau password yang ditemukan di repository (tidak ada file semacam itu sama sekali).

## 2. Rencana per fase

Setiap fase hanya dikerjakan pada task terpisah. Kolom "File/modul" bersifat perkiraan berdasarkan struktur yang disarankan blueprint; boleh menyesuaikan selama pemisahan model/repository/provider/screen/widget tetap dijaga.

### Fase 1 — Fondasi aplikasi & autentikasi

- **Status:** `Partially complete` — implementasi, format, `flutter analyze`, dan test selesai (71 test hijau). Bootstrap Firebase kini memakai opsi eksplisit `DefaultFirebaseOptions.currentPlatform` di `lib/core/firebase/firebase_bootstrap.dart`, sehingga inisialisasi di web/desktop tidak lagi gagal dengan assertion "FirebaseOptions cannot be null when creating the default app." (dibuktikan `flutter run -d chrome`: masuk `#/login`, lalu sesi Auth nyata terbentuk sampai `#/catalog`). Sisa verifikasi runtime (penulisan `users/{uid}` terhadap rules, Google Sign-In, reset kata sandi) **terblokir** karena rules belum dideploy dan SHA keys / `GOOGLE_SERVER_CLIENT_ID` belum diisi.
- **Target:** bootstrap aplikasi Flutter (Riverpod + `go_router`), Material 3 theme/design tokens terpusat, shared state widget (loading/error/empty), serta autentikasi Firebase Auth email/password, register, forgot password, dan Google Sign-In native. Auth gate mengarahkan sesi: belum login → Login, sudah login → Catalog (placeholder pada fase ini).
- **Dependency:** Fase 0 selesai (dokumen ini). Tidak bergantung fase lain.
- **File/modul yang mungkin disentuh:** `pubspec.yaml` (`firebase_core`, `firebase_auth`, `google_sign_in`, `flutter_riverpod`, `go_router`, `url_launcher` bila dipakai lebih awal), `lib/main.dart`, `lib/app.dart`, `lib/core/config/app_config.dart`, `lib/core/constants/app_constants.dart`, `lib/core/errors/app_exception.dart`, `lib/core/routing/app_router.dart`, `lib/core/routing/auth_guard.dart`, `lib/core/theme/{app_theme,app_colors,app_spacing}.dart`, `lib/core/widgets/{app_loading,app_error_state,app_empty_state,app_primary_button}.dart`, `lib/features/auth/**` (repository, provider, `auth_gate.dart`, login/register/forgot-password), `test/` (test validator/auth yang dapat diuji tanpa kredensial), `SETUP.md` (langkah setup Firebase), `lib/firebase_options.dart` (hasil generate, bukan ditulis manual).
- **Acceptance criteria:**
  - Register email/password berhasil dan membuat dokumen `users/{uid}` tanpa menghapus field profil yang sudah ada.
  - Login email/password memakai Firebase Auth; forgot password benar-benar memanggil `sendPasswordResetEmail`.
  - Google Sign-In menghasilkan credential Firebase (bukan tombol UI statis); API `google_sign_in` sesuai versi yang benar-benar terpasang di `pubspec.lock`.
  - Auth gate memblokir route terproteksi saat belum login; logout benar-benar sign out dan membersihkan state.
  - Validasi form (email, password, konfirmasi) + state loading/disabled/error; tidak menampilkan exception mentah.
  - Form profil/login tidak pernah dapat mengatur role/claim admin.
  - Theme/design tokens terpusat sesuai arah visual blueprint; tidak ada warna/spacing acak di widget.
- **Blocker eksternal:** project Firebase + hasil `flutterfire configure` (`firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`), provider Email/Password dan Google diaktifkan di Firebase Console, SHA-1/SHA-256 Android terdaftar. Tanpa itu, login end-to-end **tidak boleh** diklaim berfungsi. Android build juga menunggu platform `android-36`.
- **Verifikasi:** `dart format` file berubah, `flutter analyze`, `flutter test`; uji manual di emulator `Pixel_8_API_31` bila konfigurasi Firebase tersedia; `git diff --check`/`git status --short` hanya bila repo Git sudah dibuat. Perbarui status fase di dokumen ini secara jujur.

**Log implementasi Fase 1 (task ini).**

- Struktur: `lib/app.dart`, `lib/core/{config,constants,errors,firebase,routing,theme,utils,widgets}`, `lib/features/auth/{data,domain,presentation}`, `lib/features/profile/data/user_profile_repository.dart`, `lib/features/catalog/presentation/catalog_placeholder_screen.dart`. Tidak ada query Firebase di widget: akses Firebase hanya lewat repository dan provider.
- Theme/token terpusat: `app_colors`, `app_spacing`, `app_radius`, `app_typography`, `app_theme` (Material 3, `ColorScheme` eksplisit mengikuti palet blueprint, tanpa gradient/shadow dekoratif).
- State bersama: `AppLoading`, `AppErrorState`, `AppEmptyState`, `AppFormBanner`, `AppPrimaryButton`, `AppTextField`.
- Auth: `AuthRepository` (interface) + `FirebaseAuthRepository` (email/password, register, forgot password, Google Sign-In native: `GoogleSignIn.instance.authenticate()` → `GoogleAuthProvider.credential(...)` → `signInWithCredential`), `AuthSessionNotifier` (pemantau sesi untuk go_router), `AuthController` (status loading/error/notice form), layar Login/Register/Lupa Kata Sandi, dan `AuthGate`.
- `users/{uid}`: `UserProfileRepository.ensureProfileDocument` memakai `set(..., merge: true)` dan hanya menulis field profil (`displayName`, `email`, `photoUrl`, `phoneNumber`, `createdAt`, `updatedAt`). Role/claim admin **tidak pernah** ditulis dari klien. Bila penulisan gagal (mis. rules belum dideploy), aplikasi menampilkan peringatan yang jelas — bukan sukses palsu.
- Guard: `resolveAuthRedirect` bersifat default-deny, sehingga route apa pun selain `login`, `register`, `forgot-password`, `splash`, dan `setup-required` memerlukan sesi login. `/catalog` pada fase ini hanya placeholder bertanda jelas (bukan katalog palsu).
- Blocker eksternal yang belum tuntas: project Firebase, `firebase_options.dart`/`google-services.json`/`GoogleService-Info.plist`, provider Email/Password & Google, SHA-1/SHA-256 Android. Tanpa itu aplikasi menampilkan layar "Firebase belum dikonfigurasi" dan login end-to-end **tidak** diklaim berfungsi.
- Blocker lingkungan: `flutter build apk --debug` gagal dengan `JAVA_HOME is not set and no 'java' command could be found in your PATH`; platform `android-36` juga belum terpasang (tersedia hanya `android-34`, `android-35`).
- Command nyata dan hasilnya: `dart format lib test` → 44 file diproses; `flutter analyze` → `No issues found! (ran in 2.8s)`; `flutter test` → `All tests passed!` (54 test pada 8 file).
- Acceptance criteria Fase 1 yang **belum terbukti**: register email/password nyata, login email/password nyata, penulisan dokumen `users/{uid}` nyata, Google Sign-In menghasilkan credential Firebase nyata, dan pengiriman email reset. Semuanya menunggu konfigurasi Firebase.

### Fase 2 — Model, repository, schema, security rules, data setup

- **Status:** `Not started`
- **Target:** model domain + repository sebagai satu-satunya akses Firebase untuk seluruh koleksi MVP, stream realtime untuk data yang wajib realtime, serta Firestore/Storage security rules dan seed data berlabel SAMPLE.
- **Dependency:** Fase 1 (proyek Firebase & bootstrap `firebase_core` harus sudah ada).
- **File/modul yang mungkin disentuh:** `lib/features/*/domain/{category,product,user_profile,cart_item,banner,service_rate,creative}.dart`, `lib/features/*/data/*_repository.dart`, `lib/features/*/presentation/*_providers.dart` (provider dasar saja), `lib/core/errors/app_exception.dart`, `firebase/firestore.rules`, `firebase/storage.rules`, `firebase/firestore.indexes.json`, `scripts/seed_sample_data.*`, `SETUP.md`, test mapping model.
- **Acceptance criteria:**
  - Model Dart cocok dengan schema blueprint (`categories`, `products`, `users/{uid}`, `users/{uid}/cart_items/{productId}`, `banners`, `service_rates`, `creatives`) dan mem-parse Firestore secara tervalidasi (field hilang/tipe salah → error eksplisit).
  - Tidak ada query Firestore di layer UI; semua lewat repository.
  - Query katalog menerapkan `isActive == true`; rules cocok dengan pola query (rules bukan alat filter query).
  - Rules menolak akses secara default; hanya claim `admin: true` yang dapat menulis katalog/kategori/banner/service_rates/creatives; cart & profil dibatasi UID pemilik; profil tidak dapat menambah/mengubah role.
  - `role` pada dokumen profil bukan sumber otoritatif admin.
  - Seed data ditandai SAMPLE dengan placeholder yang mudah diganti; tidak ada URL/foto/nama random yang terlihat seperti data produksi.
  - Rules tidak dideploy otomatis tanpa target eksplisit; langkah deploy ada di `SETUP.md`.
- **Blocker eksternal:** project Firebase (target deploy rules), Storage aktif + persyaratan paket billing, serta Firebase Emulator Suite (belum terkonfigurasi) untuk menguji rules. Jika emulator tidak tersedia, jangan klaim rules lolos emulator.
- **Verifikasi:** `dart format`, `flutter analyze`, `flutter test` (termasuk unit test mapping + kasus field tak valid), `git diff --check` bila repo Git tersedia.

### Fase 3 — Katalog, carousel, search/filter, detail produk, realtime

- **Status:** `Partially complete` — seluruh kode halaman katalog, carousel, search/filter, grid produk realtime, dan halaman detail produk beserta test widget/domain sudah ada; `dart format` (`105 file, 0 changed`), `flutter analyze` (`No issues found!`), dan `flutter test` (`All tests passed!`, 175 test pada 26 file) lulus. Yang **belum**: verifikasi runtime terhadap Firestore nyata (isi katalog, realtime, tiga aset banner, foto produk) karena project Firebase belum ada dan seed belum ditulis, serta uji manual di emulator/perangkat (lihat log di bawah).
- **Target:** halaman Catalog/Home sebagai tujuan pertama setelah login, carousel tiga banner (satu menuju Portofolio), search + filter kategori/brand yang dapat digabungkan, grid/list produk realtime, dan Product Detail.
- **Dependency:** Fase 2 (repository & model katalog), Fase 1 (routing/shell).
- **File/modul yang mungkin disentuh:** `lib/core/widgets/{app_scaffold,app_drawer}.dart`, `lib/features/catalog/presentation/{catalog_screen,product_detail_screen}.dart`, `lib/features/catalog/presentation/widgets/{product_card,catalog_filters,banner_carousel}.dart`, `lib/features/catalog/presentation/catalog_providers.dart`, `lib/features/catalog/data/{product_repository,category_repository,banner_repository}.dart`, `test/` (filter/katalog logic yang dapat diuji), seed data kategori/banner bila diperlukan.
- **Acceptance criteria:**
  - App bar konsisten (hamburger/drawer, identitas aplikasi, cart badge bila relevan, ikon profil).
  - Tepat tiga banner aktif, crop & tinggi konsisten, indikator posisi, auto-play wajar, tap action sesuai `targetType`/`targetValue`; minimal satu banner menuju halaman Portofolio; tidak ada URL karangan.
  - Search dapat digabungkan dengan filter kategori dan brand; brand mengikuti kategori terpilih; ada tombol reset filter.
  - Produk tampil dengan foto, nama, brand, harga + periode yang eksplisit; deskripsi penuh hanya di detail.
  - Product Detail menampilkan foto utama, nama, deskripsi, brand, kategori, harga/periode, stok, dan aksi add-to-cart; tidak ada logika cart duplikat di widget.
  - Katalog memakai stream realtime dari repository dan hanya menampilkan produk aktif; perubahan data admin tercermin tanpa hard restart.
  - Loading, error + retry, empty katalog, empty hasil search, dan gambar gagal dimuat ditangani.
  - Layout aman pada layar kecil (tanpa overflow), safe area, teks panjang.
- **Blocker eksternal:** tiga aset banner + target banner (minimal satu ke Portofolio), data kategori/produk awal atau seed SAMPLE; kesepakatan label periode harga (lihat bagian keputusan pemilik).
- **Verifikasi:** `dart format`, `flutter analyze`, `flutter test`, uji manual di emulator; update status fase; `git diff --check` bila repo Git ada.

**Log implementasi Fase 3 (task ini).**

- Halaman katalog (`lib/features/catalog/presentation/catalog_screen.dart`) menjadi tujuan pertama setelah login (route `/catalog`; `productDetail` = `/product/:productId` di `lib/core/routing/app_router.dart`). Isi: carousel banner, kolom pencarian, keterangan keadaan kategori, baris filter, judul "Katalog alat", dan bagian daftar produk. Semua data dibaca lewat provider katalog (`catalog_providers.dart`) — tidak ada query Firestore di widget.
- Carousel: `catalogBannerSelectionProvider` + `BannerSelection` (`domain/banner_selection.dart`) memotong maksimal tiga banner aktif dan menandai slide tanpa `targetType` valid (tidak dapat ditekan, dilaporkan lewat `CatalogSectionNotice`). Slide `portfolio` membuka `/portfolio`, `category` menyetel filter kategori, `externalUrl` dibuka lewat `ExternalLauncher` yang memvalidasi URL (banner tanpa URL valid → keterangan, bukan URL karangan). Banner belum dikonfigurasi → bidang keterangan jujur, bukan gambar contoh.
- Carousel memakai satu `AspectRatio` 16/9 (`BannerCarousel.slideAspectRatio`) agar tinggi slide konsisten, dengan indikator posisi dan auto-play yang berhenti bila animasi sistem dimatikan (aksesibilitas).
- Search + filter: `CatalogFilter` (`domain/catalog_filter.dart`) menggabungkan kata kunci + kategori + brand; daftar brand diturunkan dari produk aktif kategori terpilih (`CatalogBrands`), bukan daftar hardcoded; tombol hapus filter juga mengosongkan kolom pencarian supaya teks di layar tidak menyimpang dari kriteria.
- Produk: `activeProductsProvider` memakai `ProductRepository.watchActiveProducts` (stream dengan filter `isActive == true`), sehingga perubahan admin diharapkan tercermin tanpa restart; `catalogProductsProvider` meneruskan `AsyncValue` apa adanya. Grid responsif 2/3/4 kolom (`_ProductGrid.columnCountFor`) berisi `ProductCard` (foto, nama, brand, harga + periode eksplisit), dengan keadaan memuat/error + "Coba lagi"/katalog kosong/hasil filter kosong yang dibedakan.
- Detail produk (`product_detail_screen.dart`): foto utama, nama, brand, nama kategori (ID dokumen apa adanya bila kategori belum termuat), blok harga dengan satuan periode **hanya** bila dokumen menetapkannya (jika tidak: keterangan "Satuan periode harga belum ditetapkan admin" — tidak mengarang "/hari"), stok, deskripsi, pemilih jumlah dibatasi stok, dan aksi "Sewa" yang membaca ulang produk dari Firestore lalu menulis lewat `CartRepository.addProduct` (tanpa logika keranjang duplikat di widget). Keadaan memuat, error + "Coba lagi", produk tidak ditemukan, stok habis, dan produk diarsipkan ditangani.
- App bar katalog & detail produk memakai `CatalogAppBarActions` yang sama: penanda jumlah keranjang dari `cartItemCountProvider` (disembunyikan saat 0) dan ikon profil; drawer `CatalogDrawer` membawa kategori ke filter yang sama.
- Test baru/perluasan: `test/features/catalog/{catalog_screen_test,catalog_products_section_test,product_detail_screen_test,banner_carousel_test,banner_selection_test,catalog_filter_test,product_card_test,price_display_test}.dart` — termasuk tata letak layar sempit 320×600 dengan teks panjang, grid 2/3/4 kolom, batas pemilih jumlah oleh stok, dan kegagalan memuat yang menampilkan pesan + tombol ulangi.
- Bug/test yang ditemukan dan diperbaiki saat verifikasi ini: (1) `find.byTooltip` mengembalikan `RawTooltip` sehingga cast ke `IconButton` gagal → test memakai `find.widgetWithIcon(IconButton, Icons.add)`; (2) pemeriksaan jumlah kolom pada 1200×800 tidak menemukan `GridView` karena carousel 16/9 setinggi ±657 px mendorong grid ke luar viewport → pengujian responsivitas dipindah ke `catalog_products_section_test.dart` (tiga lebar layar); (3) test error memakai `Future.error` yang sudah gagal sebelum provider berlangganan sehingga dilaporkan sebagai uncaught error oleh zone pengujian → diganti `Completer` yang gagal setelah halaman terbuka, sekaligus memeriksa keadaan memuat; (4) keterangan stok berada di bawah lipatan layar 320×600 → digulir dengan `scrollUntilVisible`.
- Blocker: `lib/firebase_options.dart`/project Firebase belum ada sehingga katalog nyata, perilaku realtime, kontrak tiga banner, dan foto produk belum dapat diverifikasi runtime; seed belum ditulis; uji manual di emulator belum dijalankan. Karena itu kriteria "tiga banner aktif dari data nyata" dan "perubahan admin tercermin tanpa restart" baru terbukti secara kode/unit test, belum runtime.
- Cakupan yang belum diuji: `ProductRepository.watchActiveProducts`/`BannerRepository` belum diuji terhadap Firestore (butuh Firestore palsu atau emulator, di luar dependensi project ini).
- Fase berikutnya setelah Fase 3: Fase 4 — Keranjang, validasi harga/stok, kalkulasi, WhatsApp.

### Fase 4 — Keranjang, validasi harga/stok, kalkulasi, WhatsApp

- **Status:** `Not started`
- **Target:** cart per UID di Firestore, kontrol quantity dengan validasi stok, kalkulasi subtotal/total integer Rupiah, formatter mata uang, dan checkout berupa pesan WhatsApp ter-encode melalui `url_launcher`.
- **Dependency:** Fase 2 (model Product/CartItem & repository), Fase 3 (tombol add-to-cart pada detail).
- **File/modul yang mungkin disentuh:** `lib/features/cart/data/cart_repository.dart`, `lib/features/cart/domain/cart_item.dart`, `lib/features/cart/presentation/{cart_screen,cart_providers}.dart`, `lib/core/utils/{currency_formatter,whatsapp_message_builder}.dart`, `lib/core/config/app_config.dart` (nomor WhatsApp), `android/app/src/main/AndroidManifest.xml` (queries intent bila diperlukan `url_launcher`), `test/{cart_calculation_test,currency_formatter_test,whatsapp_message_builder_test}.dart`.
- **Acceptance criteria:**
  - Cart tersimpan di `users/{uid}/cart_items/{productId}`; produk yang sama tidak membuat baris duplikat (menambah = menaikkan quantity).
  - Quantity integer ≥ 1 dan tidak melebihi stok terverifikasi; penurunan/penghapusan item berfungsi; perubahan stok dijelaskan ke pengguna.
  - Perhitungan memakai integer Rupiah; `subtotalItem = hargaSatuan × quantity`; total = jumlah seluruh subtotal; format tampilan `Rp150.000`.
  - `priceUnit` eksplisit; tidak menulis "/hari" bila periode belum ditetapkan.
  - Checkout membaca ulang produk dari Firestore (harga/status/stok) dan menampilkan penanganan bila produk diarsipkan, harga berubah, atau stok tidak cukup.
  - Pesan WhatsApp berisi item, brand, quantity, harga satuan, unit periode, subtotal, total estimasi, nama pengguna, dan catatan konfirmasi ketersediaan/periode; URL `https://wa.me/<nomor>?text=<encoded>`; kegagalan launch ditangani (salin pesan / buka link).
  - Nomor WhatsApp hanya di `AppConfig` dan **belum diisi nilai palsu**.
  - Tidak ada klaim "pesanan terkonfirmasi", tidak ada pengurangan/penguncian stok, tidak ada payment flow, cart tidak dikosongkan tanpa keputusan UX yang jelas.
  - CTA checkout disabled saat cart kosong atau validasi gagal.
- **Blocker eksternal:** nomor WhatsApp final (format internasional tanpa `+`), keputusan unit periode harga, keputusan kapan cart di-reset.
- **Verifikasi:** unit test kalkulasi, formatter, builder pesan + encoding karakter khusus; `dart format`, `flutter analyze`, `flutter test`; uji manual di emulator; update status fase.

### Fase 5 — Portofolio/rate card & profil pengguna

- **Status:** `Not started`
- **Target:** halaman Portfolio & Services (empat kelompok layanan dari Firestore + dua kartu kreator dengan link portofolio), serta Profile/Edit Profile termasuk upload foto profil ke Storage.
- **Dependency:** Fase 2 (model/repository `service_rates`, `creatives`, `users`), Fase 1 (auth/shell).
- **File/modul yang mungkin disentuh:** `lib/features/portfolio/{data,domain,presentation}` (`portfolio_repository.dart`, `service_rate.dart`, `creative.dart`, `portfolio_screen.dart`, `portfolio_providers.dart`), `lib/features/profile/data/profile_repository.dart`, `lib/features/profile/presentation/{profile_screen,edit_profile_screen}.dart`, `lib/core/utils/validators.dart`, `pubspec.yaml` (`image_picker`, `cached_network_image`), `firebase/storage.rules` (bila perlu penyesuaian), `SETUP.md`.
- **Acceptance criteria:**
  - Empat kelompok layanan tampil (Commercial/Social Media Video; Video Editing/Post-production; Event & Project Documentation; Commercial & Portrait Photography) dari repository, termasuk judul, deskripsi, rate label/starting price bila sudah dikonfigurasi, unit, dan deliverables.
  - Tidak ada harga/rate card final yang dikarang; bila data belum diisi → configuration/empty state yang jelas.
  - Dua kartu kreator (foto, nama, spesialisasi) dengan CTA `Lihat Portofolio` yang membuka URL tervalidasi via `url_launcher`; bila data belum diisi → empty/configuration state, bukan profil rekaan.
  - Profil menampilkan foto, nama, email (dari Firebase Auth), telepon, Edit Profile, dan Logout; tidak ada field role.
  - Nama/telepon tersimpan ke `users/{uid}`; foto dipilih via `image_picker` dengan preview, validasi tipe image + batas ukuran (±5 MB), progress/error, upload ke Storage, lalu URL disimpan ke Firestore.
  - Upload gagal tidak menghapus foto lama; tidak ada placeholder "sukses" saat write/upload gagal.
- **Blocker eksternal:** rate card final + deliverables, data dua kreator (nama, spesialisasi, foto, URL portofolio), Storage aktif beserta Storage Rules, dan persyaratan paket billing Storage.
- **Verifikasi:** `dart format`, `flutter analyze`, `flutter test`, cek layout layar kecil + perilaku URL, update status fase, `git diff --check` bila repo Git ada.

### Fase 6 — Dashboard admin & CRUD produk

- **Status:** `Not started`
- **Target:** dashboard admin, daftar produk (aktif/arsip), form tambah/edit produk dengan upload gambar, serta arsipkan/pulihkan produk. Otorisasi berbasis custom claim `{admin: true}` (fail closed).
- **Dependency:** Fase 2 (repository produk, model, rules), Fase 3 (katalog realtime untuk memverifikasi perubahan), Fase 1 (auth claim).
- **File/modul yang mungkin disentuh:** `lib/features/admin/presentation/{admin_dashboard_screen,admin_product_list_screen,product_form_screen}.dart`, `lib/features/admin/presentation/admin_providers.dart`, `lib/features/admin/data/admin_product_repository.dart`, `lib/core/routing/app_router.dart` (+ admin guard), `scripts/grant_admin.mjs` (Admin SDK, dijalankan manual di lingkungan tepercaya), `firebase/storage.rules`, `firebase/firestore.rules`, `SETUP.md`.
- **Acceptance criteria:**
  - Akses admin hanya untuk akun dengan custom claim `admin: true` yang dibaca dari ID token; kegagalan verifikasi claim → akses ditolak.
  - Tidak ada password `admin/pass` atau kredensial hardcoded; jika alias `admin` dipakai, dipetakan ke email admin yang dikonfigurasi dan password tetap divalidasi Firebase Auth.
  - Tidak ada service-account JSON/secret di repository; Admin SDK tidak dijalankan dari aplikasi Flutter.
  - Admin dapat menambah, mengedit, dan mengarsipkan produk; validasi nama, kategori, brand, harga (integer ≥ 0), stok (integer ≥ 0), dan gambar.
  - Arsip = `isActive = false` (tidak menghapus foto Storage); daftar admin dapat menampilkan arsip dan memulihkan.
  - Perubahan tersimpan langsung terlihat di katalog realtime tanpa hard restart.
  - UI admin efisien dan tidak menampilkan grafik/angka analitik palsu.
  - User biasa gagal melakukan write produk walaupun memanggil Firebase di luar UI (dibuktikan dengan uji rules, bukan hanya tombol tersembunyi).
- **Blocker eksternal:** akun admin Firebase yang dikontrol pemilik + kredensial service account untuk menjalankan `grant_admin.mjs` (di luar repo), deploy rules ke project Firebase, Storage Rules aktif.
- **Verifikasi:** `dart format`, `flutter analyze`, `flutter test`, uji manual alur admin + verifikasi katalog realtime, update status fase, `git diff --check` bila repo Git ada.

### Fase 7 — Integrasi, security hardening, accessibility, test, build validation

- **Status:** `Not started`
- **Target:** review integrasi menyeluruh, hardening keamanan, accessibility, penambahan unit test, `SETUP.md` final, dan validasi build. Tidak menambah fitur baru.
- **Dependency:** Fase 1–6 selesai (atau dilaporkan dengan status jujur bila masih ada blocker).
- **File/modul yang mungkin disentuh:** `SETUP.md`, `IMPLEMENTATION_PLAN.md` (status akhir per fase), `test/**` (currency formatter, cart calculation, WhatsApp builder/encoding, Product Firestore mapping, validasi penting), penyesuaian kecil pada `lib/core/**` dan screen untuk overflow/accessibility, `firebase/*.rules` bila ditemukan celah.
- **Acceptance criteria:**
  - `flutter analyze` tanpa error; unit test relevan lulus.
  - Review auth gate, logout, Google Sign-In, custom claim admin, Firestore Rules, Storage Rules; user biasa tidak dapat menulis produk atau memodifikasi profil orang lain.
  - Review katalog realtime, search+filter gabungan, tiga banner (satu ke Portofolio), detail produk, dan state loading/error/empty.
  - Review cart per UID, integer Rupiah, penanganan harga/stok basi, pesan WhatsApp, encoding URL, dan kegagalan `url_launcher`.
  - Cek overflow layar kecil, safe area, keyboard/form, teks panjang, semantics ikon, tap target, kontras, dan konsistensi design tokens.
  - Tidak ada secret, fake success, dummy data tak berlabel, tombol inert, atau TODO kritis yang disembunyikan; seluruh setup manual tercantum di `SETUP.md`.
  - Status akhir tiap fase di dokumen ini diisi `Complete` / `Partially complete` / `Blocked` beserta alasan berbukti; checklist tidak "dihijaukan" tanpa bukti.
- **Blocker eksternal:** platform `android-36` untuk build Android; macOS + Xcode untuk validasi iOS; project Firebase nyata untuk verifikasi end-to-end. Bila tidak tersedia, laporkan sebagai `Blocked` dengan bukti command, bukan diklaim lulus.
- **Verifikasi:** `dart format .` (bila aman), `flutter analyze`, `flutter test`, `flutter build apk --debug` (setelah `android-36` tersedia), `git diff --check` + `git status --short` bila repo Git sudah ada.

## 3. Blocker dan keputusan pemilik yang belum tersedia

Nilai-nilai berikut **belum ditentukan** dan tidak boleh dikarang. Fase terkait harus memakai empty/configuration state sampai nilai asli diberikan.

| # | Keputusan / aset | Dibutuhkan pada | Status saat audit |
|---|---|---|---|
| 1 | Nama aplikasi/brand (title, app bar, label) | Fase 1, 3 | Belum ada; masih default `rent_camera_app` (iOS `CFBundleDisplayName`: "Rent Camera App") |
| 2 | Nomor WhatsApp internasional tanpa `+`, spasi, atau tanda baca | Fase 4 | Belum ada |
| 3 | Unit periode harga sewa (`per_day` / `per_session` / lainnya) + label tampilan | Fase 3, 4 | Belum ada; blueprint melarang menulis "/hari" bila belum ditetapkan |
| 4 | Harga & stok produk awal + deskripsi/kondisi alat | Fase 2 (seed), 3 | Belum ada |
| 5 | Tiga banner: gambar + `targetType`/`targetValue` (minimal satu menuju Portofolio) | Fase 2 (seed), 3 | Belum ada |
| 6 | Empat rate card: judul final, deskripsi, `rateLabel`, `startingPrice`, `priceUnit`, `deliverables` | Fase 2 (seed), 5 | Belum ada |
| 7 | Dua kreator: nama, `roleTitle`, spesialisasi, foto, `portfolioUrl` | Fase 2 (seed), 5 | Belum ada |
| 8 | Project Firebase (project id, `firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`) | Fase 1, 2 | Belum ada |
| 9 | Provider login yang diaktifkan + SHA-1/SHA-256 Android + `REVERSED_CLIENT_ID` iOS | Fase 1 | Belum ada |
| 10 | Email admin yang dikontrol pemilik (untuk alias `admin`) + metode pemberian claim | Fase 6 | Belum ada |
| 11 | Foto/aset milik pemilik (produk, banner, profil) & kebijakan placeholder netral | Fase 3, 5, 6 | Belum ada |
| 12 | Keputusan reset cart setelah checkout WhatsApp dibatalkan/diproses | Fase 4 | Belum ada |
| 13 | Repository Git: `git init` + remote + kebijakan commit per fase | Prasyarat semua fase | **Selesai**: repo sudah Git (`main`, `origin/main`), commit awal `6fb46d2 "Initial commit"` |
| 14 | Ketersediaan/persyaratan paket billing Firebase Storage | Fase 2, 5 | Belum diverifikasi |

Keputusan teknis yang juga perlu persetujuan pemilik (belum diputuskan pada task ini, tidak diimplementasikan):
- Ganti `applicationId`/`namespace` dari `com.example.rent_camera_app` menjadi ID unik, atau pertahankan untuk demo kelas.
- Menambah platform `android-36` pada Android SDK lokal agar `flutter doctor` bebas dari error toolchain Android.
- Menambahkan folder bin Pub global (`flutterfire`) ke PATH, atau selalu memanggil lewat `dart pub global run flutterfire_cli:flutterfire`.

## 4. Aturan verifikasi yang berlaku untuk setiap fase

1. Sebelum mengedit: periksa file terkait dan status Git (bila repo Git sudah ada).
2. Setelah implementasi: `dart format` pada file yang berubah (atau `dart format .` bila aman), lalu `flutter analyze`, lalu unit test relevan.
3. Jangan pernah mengklaim command lulus bila tidak benar-benar dijalankan; jangan mengklaim fitur Firebase berjalan bila konfigurasi belum ada.
4. Bila terhalang konfigurasi eksternal, tuliskan konfigurasi yang hilang, command yang dijalankan beserta output, dan langkah manual penyelesaiannya.
5. Perbarui tabel status fase di dokumen ini hanya sesuai kenyataan (`Complete` / `Partially complete` / `Blocked`).
6. Akhiri task setelah fase selesai; jangan lanjut ke fase berikutnya pada task yang sama.
7. Tutup task dengan `git diff --check` dan `git status --short` bila Git tersedia (saat ini belum tersedia).

## 5. Cakupan yang sengaja di luar MVP

Belum dikerjakan pada fase mana pun di atas, kecuali diminta eksplisit oleh pemilik:
- Collection `orders`/booking dengan tanggal sewa, deposit, dan pengurangan stok otomatis (membutuhkan backend tepercaya/Cloud Functions).
- Pembayaran, invoice, atau status pesanan; checkout tetap hanya permintaan via WhatsApp.
- Pengelolaan rate card, kreator, kategori, dan banner dari dashboard admin (MVP hanya CRUD produk).
- Analytics/dashboard statistik.
- Firebase App Check (disarankan sebelum rilis, bukan bagian fase 1–7 saat ini).

## 6. Langkah berikutnya

- Prompt yang harus dijalankan berikutnya: **Prompt Fase 4 — Keranjang, validasi harga/stok, kalkulasi, dan permintaan sewa via WhatsApp** (bagian D pada `docs/PROMPT_CLINE_BERTAHAP.md`), pada task terpisah. Fase 1–3 sudah selesai dari sisi kode (`flutter analyze` bersih, `flutter test` 175 lulus); Fase 2 & 3 berstatus `Partially complete` karena verifikasi runtime Firebase belum bisa dijalankan.
- Sebelum Fase 4 berjalan, pemilik perlu menyiapkan (lihat `SETUP.md`): project Firebase + `flutterfire configure` (`lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`), aktivasi provider Email/Password & Google, SHA keys Android, lalu penulisan seed `scripts/seed_sample_data.mjs` supaya katalog dan banner dapat diverifikasi runtime. Nomor WhatsApp internasional (blocker #2) juga wajib ada sebelum checkout WhatsApp diuji.
- Verifikasi runtime yang masih tertunda dari Fase 3: tiga banner aktif dari Firestore (satu menuju Portofolio), produk hanya tampil bila `isActive == true`, perubahan data admin tercermin tanpa restart, foto produk nyata, serta uji manual di emulator/perangkat.

