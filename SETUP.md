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
| `firebase/storage.rules` | **Ada** (dibuat Fase 5), **belum dideploy** | `firebase.json` → `firebase/storage.rules`; `profiles/{uid}/**` hanya pemilik UID, `products/**`+`banners/**`+`creatives/**` hanya admin, wajib `image/*` ≤ 5 MB |
| `firebase/firestore.rules` / `firestore.indexes.json` | `firestore.rules` **Ada** (dibuat Fase 6), **belum dideploy**; `firestore.indexes.json` belum ada | rules memuat `products/**` hanya-tulis admin (baca untuk pengguna login), `users/{uid}` hanya pemilik UID tanpa field otoritas, dan `users/{uid}/cart_items/**` hanya pemilik UID dengan `quantity` integer 1–999. Filter katalog/dashboard dikerjakan di klien sehingga composite index belum diperlukan |
| `scripts/seed_sample_data.mjs` (Fase 5, diperluas: `categories` + `products` contoh) | Ada, **belum pernah menulis ke Firebase** | pratinjau default (tanpa kredensial) memvalidasi `scripts/seed_config.json` lalu mencetak 6 kategori + 4 produk contoh (arsip) + 4 rate card + 2 kreator; penulisan hanya lewat `--apply` dan tidak menimpa dokumen yang sudah ada; `firebase-admin` belum dipasang sehingga penulisan belum dijalankan |
| `scripts/grant_admin.mjs` (Fase 6) | **Ada**, belum dijalankan pada akun nyata | aksi wajib eksplisit `--grant`/`--revoke` (tanpa aksi default): `node scripts/grant_admin.mjs --dry-run --grant --uid=abc123` mencetak rencana tanpa menyentuh Firebase; `--grant --revoke` bersamaan, `--uid` bersama `--email`, target kosong, dan email tanpa `@` semuanya ditolak. `firebase-admin` belum dipasang dan email admin pemilik belum ada |
| Kualitas kode repo (task seed/claim ini) | Bersih | 6 file dari commit UI `f816f76`/`7173a6f` belum sesuai `dart format` dan 2 pemakaian `withOpacity` baru; keduanya dirapikan pada task ini → `dart format --output=none --set-exit-if-changed lib test` = `Formatted 152 files (0 changed)`, `flutter analyze` = `No issues found!`, `flutter test` = `All tests passed!` (318 test) |
| Claim `{ admin: true }` pada akun admin nyata | **Belum ada** | tanpa claim, entri Dashboard admin tidak muncul di drawer katalog, route `/admin` dialihkan ke katalog, dan rules menolak penulisan produk (lihat §4c) |
| `--dart-define` nilai project | Belum diisi | lihat §3 |
| `--dart-define=WHATSAPP_NUMBER` | **Belum diisi** (tidak ada nilai default/contoh) | selama kosong, tombol "Checkout via WhatsApp" nonaktif dan UI menjelaskan nomor belum dikonfigurasi (Fase 4) |
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
| `WHATSAPP_NUMBER` | wajib untuk checkout | Nomor tujuan permintaan sewa. Format internasional: kode negara + nomor, **tanpa** `+`, spasi, tanda baca, dan tanpa awalan `0` (8–15 digit). Dipakai hanya oleh `AppConfig.whatsappNumber` untuk membangun tautan `https://wa.me/<nomor>` | **kosong** → tombol checkout nonaktif |

Contoh menjalankan aplikasi:

```bash
flutter run --dart-define=APP_NAME="Nama Brand" \
  --dart-define=ADMIN_EMAIL=<email-admin-yang-dikonfigurasi> \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com \
  --dart-define=WHATSAPP_NUMBER=<kode-negara><nomor-tujuan>
```

Catatan nomor WhatsApp: nomor hanya boleh berasal dari pemilik project. Aplikasi tidak
punya nomor contoh/default, memvalidasi digit (8–15 digit, awalan `0` ditolak), dan
menonaktifkan checkout selama nilai ini kosong. Checkout **bukan** booking atau
pembayaran: aplikasi hanya menyusun pesan permintaan sewa, membaca ulang harga/stok
produk dari Firestore sebelum menyusun pesan, dan tidak mengunci/mengurangi stok.

Catatan keamanan: alias `admin` **bukan** bypass autentikasi. Password tetap
divalidasi Firebase Authentication, dan role admin hanya berasal dari custom claim
`{ "admin": true }` pada ID token. Password `pass` tidak boleh ditulis di source code.

## 4. Admin dan security rules

- Skrip pemberian custom claim `scripts/grant_admin.mjs` (Firebase Admin SDK)
  **sudah ada** (Fase 6) dan hanya dijalankan dari lingkungan tepercaya, tidak pernah
  dari aplikasi Flutter. Pemakaiannya ada di §4c.
- `firebase/storage.rules` **sudah ada** (dibuat pada Fase 5) dan `firebase.json`
  menunjuk berkas itu, tetapi **belum dideploy** dan bucket Storage belum dipastikan
  aktif, sehingga unggah foto profil **dan foto produk** belum dapat diverifikasi
  runtime. Isinya: `products/{productId}/**`, `banners/**`, dan `creatives/**` hanya
  dapat ditulis admin (`request.auth.token.admin == true`); `profiles/{uid}/**` hanya
  dapat ditulis pemilik UID itu sendiri; setiap tulisan wajib `image/*` dan ≤ 5 MB;
  semua path lain ditolak. Deploy dengan `firebase deploy --only storage`.
- `firebase/firestore.rules` **sudah ada** (dibuat Fase 6) dan `firebase.json` menunjuk
  berkas itu, tetapi **belum dideploy**. Isinya: `products/**`, `categories/**`,
  `banners/**`, `service_rates/**`, dan `creatives/**` hanya dapat ditulis admin
  (`request.auth.token.admin == true`) dan dibaca pengguna yang login; `users/{uid}`
  hanya pemilik UID dan tanpa field otoritas (`role`/`admin`/`isAdmin`/`claims`);
  `users/{uid}/cart_items/**` hanya pemilik UID dengan `quantity` integer 1–999; tipe
  field produk/profil/keranjang divalidasi; seluruh path lain default-deny. Deploy dengan
  `firebase deploy --only firestore:rules`. Sampai rules dideploy, dokumen `users/{uid}`
  hasil register/login (dan penulisan produk/keranjang) dapat gagal ditulis bila project
  memakai mode produksi (default deny). Aplikasi akan menampilkan pesan peringatan yang
  jelas (bukan "sukses" palsu) pada kondisi itu.
- Alasan konkret mengapa rules wajib sebelum uji runtime keranjang: Fase 4 menyimpan
  keranjang pada `users/{uid}/cart_items/{productId}` (satu dokumen per produk).
  Rules harus (a) mengizinkan baca/tulis **hanya** untuk pemilik UID
  (`request.auth.uid == uid`), (b) menolak perubahan `role`/claim dari klien pada
  `users/{uid}`, dan (c) membuat `products` hanya-baca bagi pengguna biasa. Tanpa itu
  penulisan keranjang berhenti dengan `permission-denied` dan tidak dapat diverifikasi.
- Jangan commit service-account JSON, private key, atau file kredensial.

## 4b. Seed konten awal (`categories`, `products` contoh, rate card & kreator)

Script seed berada di `scripts/` dan memakai Firebase Admin SDK, jadi hanya dijalankan
dari lingkungan tepercaya (bukan dari aplikasi Flutter):

```bash
npm --prefix scripts install                     # memasang firebase-admin (sekali)
node scripts/seed_sample_data.mjs                # pratinjau (default, tanpa kredensial)
node scripts/seed_sample_data.mjs --dry-run      # sama: hanya mencetak rencana
node scripts/seed_sample_data.mjs --apply --service-account=<path-service-account.json>
# atau: GOOGLE_APPLICATION_CREDENTIALS=<path> node scripts/seed_sample_data.mjs --apply
node scripts/seed_sample_data.mjs --apply --replace-sample ...   # menulis ulang dokumen contoh
```

Sifat penulisan (diperiksa lewat pratinjau, tanpa kredensial):

- **Tanpa `--apply` tidak ada dokumen yang ditulis.** Pratinjau memvalidasi
  `scripts/seed_config.json` lalu mencetak rencananya.
- **Tidak menimpa pekerjaan yang sudah ada.** Dokumen milik pemilik (tanpa penanda
  `isSample: true`) selalu dilewati, dan dokumen contoh yang sudah ada juga dilewati
  kecuali pemanggil memberi `--replace-sample`. Karena itu isian manual pemilik pada
  dokumen contoh tidak hilang kalau skrip dijalankan ulang.
- Isi yang ditulis:

  - `categories`: enam kategori contoh dari blueprint §6.1 (`kamera`, `lensa`,
    `flash_lighting`, `audio_microphone`, `stabilizer_support`, `aksesori`) dengan
    `iconKey` yang divalidasi terhadap `CategoryIconKeys` di Dart. Kategori ini perlu ada
    lebih dulu karena form produk admin tidak dapat menyimpan produk tanpa kategori.
  - `products`: empat dokumen contoh yang **selalu arsip (`isActive: false`)** dengan
    harga/stok apa adanya dari konfigurasi (default 0 = belum diisi) dan tanpa foto,
    sehingga tidak pernah muncul di katalog pelanggan. `isActive: true` pada konfigurasi
    sengaja **ditolak** oleh skrip; produk diaktifkan dari dashboard admin setelah
    datanya nyata.
  - `service_rates`: empat kelompok layanan pada `scripts/seed_config.json` dengan
    `rateLabel: "CONTOH RATE — BELUM FINAL"`, `startingPrice: null`, `priceUnit: ""`,
    `deliverables: []`, dan penanda `isSample: true` — halaman Portofolio akan menampilkan
    label tersebut apa adanya sampai pemilik mengisi rate final.
  - `creatives`: dokumen pada `scripts/seed_config.json` (`kreator_1`, `kreator_2`).
    **Nama tampilan pada berkas itu perlu diverifikasi/diganti pemilik**; `roleTitle`,
    `specialties`, `photoUrl`, dan `portfolioUrl` sengaja dikosongkan karena script tidak
    boleh mengarang pengalaman, foto, atau URL orang. URL yang diisi wajib `http`/`https`
    (divalidasi script), dan selama `portfolioUrl` kosong tombol `Lihat Portofolio` di
    aplikasi nonaktif dengan penjelasan.

Jangan commit service-account JSON; pola berkas itu sudah masuk `.gitignore`
(`scripts/service-account*.json`).

## 4c. Alur dashboard admin (Fase 6)

Tiga langkah berikut wajib dilakukan pemilik pada project Firebase nyata sebelum
dashboard admin dapat dipakai. Ketiganya butuh akun/kredensial pemilik, jadi **belum**
dijalankan dan belum dapat diverifikasi runtime dari task ini.

1. **Beri claim admin** pada akun Firebase Authentication pemilik (jangan pada akun biasa):

   ```bash
   npm --prefix scripts install        # memasang firebase-admin (sekali)
   node scripts/grant_admin.mjs --dry-run --grant --email=<email-admin>   # cek rencana, tanpa kredensial
   node scripts/grant_admin.mjs --grant --email=<email-admin> --service-account=<path-service-account.json>
   # atau: GOOGLE_APPLICATION_CREDENTIALS=<path> node scripts/grant_admin.mjs --grant --uid=<uid-akun-admin>
   # mencabut: node scripts/grant_admin.mjs --revoke --uid=<uid-akun-admin>
   ```

   Aksi wajib dipilih eksplisit (`--grant` atau `--revoke`); skrip menolak perintah tanpa
   aksi, aksi ganda, target ganda (`--uid` bersama `--email`), target kosong, dan email
   tanpa `@`.

   Skrip mempertahankan claim lain pada akun itu dan hanya mengubah field `admin`, lalu
   membaca ulang akun dari Firebase untuk memverifikasi hasilnya (bukan mengasumsikan
   berhasil). Skrip ini **tidak** memakai password apa pun; alias login `admin` di
   aplikasi hanya memetakan nama pengguna ke email admin (`ADMIN_EMAIL`, §3) dan password
   tetap divalidasi Firebase Authentication.

2. **Deploy rules** — tanpa langkah ini penulisan produk, keranjang, dan foto tetap
   ditolak backend:

   ```bash
   firebase deploy --only firestore:rules,storage
   ```

3. **Login ulang di aplikasi.** Claim dibaca dengan `forceRefresh: true`, tetapi token
   lama dapat masih tersimpan sampai login ulang, sehingga entri "Dashboard admin" pada
   drawer katalog baru muncul setelah keluar-masuk akun sekali. Bila entri itu tidak
   muncul: periksa bahwa claim benar-benar tersimpan (skrip mencetak hasil verifikasi),
   rules sudah dideploy, dan akun yang dipakai memang akun yang diberi claim.

Isi dashboard (hanya CRUD produk, sesuai lingkup MVP): daftar seluruh produk termasuk
arsip dengan pencarian dan filter status yang dikerjakan di klien (tanpa composite
index), ringkasan jumlah produk nyata, form tambah/edit (nama, brand, deskripsi,
kategori dari `categories`, harga integer Rupiah + satuan periode eksplisit, stok, dan
beberapa foto), serta arsipkan/pulihkan dengan konfirmasi. Foto disimpan pada
`products/{productId}/**` dan diunggah **lebih dulu**: bila unggahan gagal, dokumen
produk tidak disentuh sama sekali sehingga foto lama tetap tampil. Arsip hanya mengubah
`isActive` — berkas foto tidak dihapus, sehingga pemulihan mengembalikan produk apa
adanya. Pengelolaan kategori, banner, rate card, dan kreator **tidak** termasuk Fase 6
(lihat `IMPLEMENTATION_PLAN.md` §5).

## 5. Verifikasi yang bisa dijalankan sekarang

```bash
dart format --output=none --set-exit-if-changed lib test
                         # task seed/claim ini: `Formatted 152 files (0 changed)`
                         # (6 file dari commit UI `f816f76`/`7173a6f` dirapikan dulu)
flutter analyze          # task ini: `No issues found!` — 4 info `deprecated_member_use`
                         # (`withOpacity` pada layar auth dan katalog) sudah diganti
                         # `withValues`
flutter test             # task ini: All tests passed! (318 test)
flutter test test/features/admin test/app_auth_routing_test.dart test/features/catalog/catalog_screen_test.dart
                         # Fase 6: All tests passed! (51 test)
node scripts/seed_sample_data.mjs
                         # task ini (pratinjau default, tanpa kredensial): 6 kategori +
                         # 4 produk contoh (arsip) + 4 rate card + 2 kreator dicetak,
                         # tidak ada dokumen yang ditulis
node scripts/grant_admin.mjs --dry-run --grant --uid=abc123
                         # mencetak rencana pemberian claim tanpa menyentuh Firebase
node scripts/grant_admin.mjs --dry-run --email=<email-admin>
                         # ditolak: "Tentukan aksi secara eksplisit" (tanpa --grant/--revoke)
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
alur bootstrap → login → katalog memakai stream sesi palsu, serta (Fase 5) halaman
Portofolio & Layanan, pemetaan error Storage, validasi berkas gambar, dan alur
Edit Profil termasuk kegagalan unggah/penulisan, serta (Fase 6) keputusan akses admin
yang fail closed, validasi draft produk, pemfilteran/ringkasan daftar produk admin, dan
penyusunan provider akses admin di luar Firebase (termasuk saat `FirebaseAuth` belum siap).

Yang **belum** diverifikasi (butuh kredensial/uji manual di project Firebase):

- register email/password sungguhan dan penulisan dokumen `users/{uid}`;
- login email/password dan Google Sign-In end-to-end (termasuk ID token dari Google);
- pengiriman email reset kata sandi;
- **unggah foto profil ke Storage** (butuh Storage aktif + `firebase deploy --only storage`);
  yang baru terbukti adalah perilakunya di test: berkas > 5 MB / bukan gambar ditolak
  sebelum diunggah, dan kegagalan unggah tidak mengubah `photoUrl` lama;
- **pembukaan tautan portofolio kreator** pada perangkat (butuh `portfolioUrl` asli);
- aturan Firestore/Storage (kedua berkas rules sudah ada — `firebase/firestore.rules` Fase 6
  dan `firebase/storage.rules` Fase 5 — tetapi **belum** dideploy), termasuk blok
  `users/{uid}/cart_items` yang menentukan apakah keranjang dapat ditulis dan blok
  `products/**` yang menentukan apakah admin benar-benar dapat menyimpan produk;
- penulisan/penghapusan `users/{uid}/cart_items` beserta perilaku realtime-nya;
- checkout WhatsApp dengan nomor tujuan nyata (memerlukan `WHATSAPP_NUMBER`, §3) dan
  pembukaan tautan `wa.me` pada perangkat/emulator;
- uji manual halaman keranjang di emulator/perangkat (Katalog → Detail → Sewa → Keranjang);
- **alur admin runtime (Fase 6):** pemberian claim `{admin: true}` pada akun nyata, deploy
  rules, lalu tambah/edit/arsipkan produk dari dashboard admin beserta unggahan foto asli
  ke Storage dan pemeriksaan bahwa katalog realtime ikut berubah tanpa restart;
- penolakan penulisan produk untuk akun non-admin pada project nyata: di aplikasi baru
  terbukti lewat keputusan claim (test), sedangkan aturan backend baru terbukti setelah
  `firebase/firestore.rules` dideploy;
- tampilan dashboard admin dengan data nyata (saat ini belum ada produk/foto milik pemilik,
  sehingga yang tampil adalah keadaan kosong apa adanya).

## 6. Aset dan keputusan yang masih ditunggu pemilik

Daftar lengkap ada di `IMPLEMENTATION_PLAN.md` §3. Yang paling dekat dengan fase ini:

1. Nama/brand aplikasi final (`APP_NAME`).
2. Email admin yang dikontrol pemilik (`ADMIN_EMAIL`) beserta akun Firebase-nya. Metode pemberian claim **sudah tersedia** (`scripts/grant_admin.mjs`, lihat §4c), tetapi claim `{admin: true}` belum diberikan pada akun nyata mana pun karena email tersebut masih kosong.
3. Provider login yang diaktifkan (Email/Password, Google) di Firebase Console + SHA-1/SHA-256 Android. Project Firebase dan hasil `flutterfire configure` sudah selesai (lihat §0).
4. Keputusan `applicationId` Android (unik atau tetap `com.example.rent_camera_app`).
5. Nomor WhatsApp tujuan final (`WHATSAPP_NUMBER`) — selama kosong, checkout keranjang tetap nonaktif (Fase 4).
6. Konten Fase 5 yang belum ada: empat rate card layanan (judul, deskripsi, `rateLabel`, `startingPrice`, `priceUnit`, `deliverables`), dua kreator (nama, `roleTitle`, spesialisasi, foto, `portfolioUrl`), serta foto/aset milik pemilik. Script seed dan berkas konfigurasinya sudah tersedia (`scripts/seed_sample_data.mjs`, `scripts/seed_config.json`, lihat §4b), tetapi **belum dijalankan** karena `firebase-admin` belum dipasang; nama tampilan kreator pada berkas konfigurasi itu perlu diverifikasi pemilik. Kepastian paket billing Firebase Storage untuk upload foto profil juga masih perlu dipastikan (`IMPLEMENTATION_PLAN.md` blocker #14).

## 7. Penyelesaian blocker

| Blocker | Cara menyelesaikan |
|---|---|
| Crash/assertion *"FirebaseOptions cannot be null when creating the default app."* di web/desktop | sudah diperbaiki: bootstrap memakai `DefaultFirebaseOptions.currentPlatform` (§2). Pastikan `lib/firebase_options.dart` ada, lalu jalankan ulang (bukan hot reload) |
| Layar setup muncul terus | ikuti §2, lalu jalankan ulang aplikasi (hot restart). Kode diagnostik di layar menunjukkan penyebabnya |
| `flutter doctor` mengeluh Android SDK 36 | pasang platform `android-36` |
| `flutterfire` tidak dikenali | pakai `dart pub global run flutterfire_cli:flutterfire` atau tambahkan folder bin Pub global ke PATH |
| Google Sign-In gagal dengan pesan konfigurasi | isi `GOOGLE_SERVER_CLIENT_ID`, daftarkan SHA-1/SHA-256, aktifkan provider Google |
| Dokumen profil gagal disinkronkan | deploy Firestore Security Rules pada fase rules; aplikasi menampilkan peringatan ini apa adanya |
| Tombol "Checkout via WhatsApp" nonaktif dan menyebut nomor belum dikonfigurasi | jalankan aplikasi dengan `--dart-define=WHATSAPP_NUMBER=<kode-negara><nomor>` (§3) setelah pemilik menentukan nomor final (`IMPLEMENTATION_PLAN.md` blocker #2). Aplikasi sengaja tanpa nomor default |
| Penulisan/hapus item keranjang gagal dengan `permission-denied` | pastikan `firebase/firestore.rules` sudah dibuat dan dideploy dengan blok `users/{uid}/cart_items` untuk pemilik UID (§4) |
| Item keranjang tampak "berhasil ditambahkan" tetapi tidak muncul | periksa apakah sesi login valid pada UID yang sama (keranjang dibatasi UID) dan apakah rules mengizinkan baca untuk UID tersebut; aplikasi hanya menampilkan sukses bila penulisan Firestore benar-benar selesai |
| Entri "Dashboard admin" tidak muncul di drawer katalog | pastikan akun punya claim `{admin: true}` (`node scripts/grant_admin.mjs --grant --uid=<uid>`, §4c), rules sudah dideploy, lalu **login ulang** (claim dibaca dengan `forceRefresh: true`) |
| Route `/admin` selalu dialihkan ke katalog | sama seperti baris di atas: claim belum terbaca atau bukan `true`. Route guard hanya UI; backend tetap menolak penulisan tanpa claim |
| Penulisan produk gagal `permission-denied` atau foto produk gagal diunggah | jalankan `firebase deploy --only firestore:rules,storage`, lalu pastikan bucket Storage aktif dan berkas berupa `image/*` ≤ 5 MB |
| Dashboard admin menampilkan daftar kosong | itu keadaan nyata ketika collection `products` belum diisi; tambahkan produk lewat form admin (Fase 6). Aplikasi tidak menampilkan data contoh palsu |
| Pratinjau seed gagal: "config.categories harus berisi minimal satu kategori" | berkas `scripts/seed_config.json` yang dipakai belum memuat blok `categories`; pakai berkas dari repo terbaru (enam kategori contoh) atau tambahkan kategori yang benar-benar dipakai |
| `--apply` "tidak mengubah" dokumen contoh yang sudah ada | itu disengaja (skrip tidak menimpa pekerjaan yang ada). Hapus dokumen ber-penanda `isSample: true` di Firebase Console, atau jalankan ulang dengan `--apply --replace-sample` bila memang ingin menulis ulang data contoh |
| `--apply` gagal: "produk contoh harus diarsipkan" | `products[].isActive` diset `true` pada `scripts/seed_config.json`. Biarkan `false`; aktifkan produk dari dashboard admin setelah nama, brand, harga, stok, dan fotonya nyata |
| `grant_admin.mjs` menolak: "Tentukan aksi secara eksplisit" | tambahkan `--grant` (memberi claim) atau `--revoke` (mencabut); skrip sengaja tidak punya aksi default |
| `grant_admin.mjs` menolak: "Pilih salah satu target" | target hanya boleh satu: `--uid=<uid>` **atau** `--email=<email>` |

