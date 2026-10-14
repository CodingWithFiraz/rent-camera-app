# Blueprint Sistem Aplikasi Penyewaan Alat Foto/Video & Portofolio Jasa

Dokumen ini merupakan spesifikasi awal untuk membangun aplikasi mobile menggunakan Flutter/Dart dengan Firebase sebagai backend. Dokumen juga memuat prompt utama untuk Cline. Nama aplikasi, nomor WhatsApp, rate card final, dan link portofolio masih harus diisi dengan data milik project.

---

## 1. Ringkasan produk

Aplikasi terdiri dari dua fungsi utama:

1. **Penyewaan alat foto/video**: pengguna mencari dan memfilter alat, membuka detail produk, memasukkan alat ke keranjang, mengubah jumlah, melihat rincian biaya, lalu mengirim permintaan sewa melalui WhatsApp.
2. **Portofolio jasa kreatif**: pengguna melihat layanan dan rate card untuk video komersial/social media, editing/post-production, dokumentasi event/project, serta fotografi komersial/portrait. Pengguna juga dapat membuka link portofolio dua kreator.

Fitur pendukung: login/register, Google Sign-In, profil pengguna, serta dashboard admin untuk mengelola katalog melalui operasi CRUD.

### Keputusan produk dan asumsi MVP

- Pengguna **wajib login** sebelum membuka halaman utama. Setelah login berhasil, tujuan awalnya adalah halaman katalog.
- Login pengguna tersedia melalui email/password dan Google. Register tersedia melalui email/password; login Google dapat membuat akun Firebase pertama kali.
- Dashboard admin adalah bagian dari aplikasi yang sama, tetapi hanya dapat dibuka oleh akun dengan role admin yang ditetapkan secara aman.
- Kategori utama: Kamera, Lensa, Flash & Lighting, Audio/Microphone, Stabilizer & Support, dan Aksesori. Kategori ini merupakan contoh awal dan harus mudah ditambah atau diubah dari data.
- Brand menjadi filter turunan di dalam kategori. Contoh: kategori Kamera memiliki brand Sony, Canon, Fujifilm, Panasonic, dan lainnya sesuai data yang tersedia.
- Harga di katalog dianggap sebagai **harga sewa per satuan periode**. MVP menghitung `harga satuan × jumlah alat`; belum ada pemilihan tanggal dan durasi sewa. Label harga, misalnya “/hari” atau “/sesi”, harus dikonfigurasi dengan jelas sebelum aplikasi digunakan oleh pelanggan.
- Checkout WhatsApp adalah **permintaan/konfirmasi sewa**, bukan booking final. Keranjang tidak mengunci stok, tidak menerima pembayaran, dan tidak otomatis mengurangi stok. Ketersediaan, durasi, deposit, pengiriman, dan biaya tambahan dikonfirmasi oleh admin melalui WhatsApp.
- Banner berjumlah tiga item aktif. Salah satunya mengarah ke halaman Portofolio. Tujuan banner disimpan sebagai data agar tidak perlu mengubah widget jika target berubah.
- Halaman portofolio menampilkan empat kelompok jasa dan dua kartu profil kreator. Link portofolio eksternal dibuka melalui browser/perangkat yang sesuai.
- Dashboard pada MVP mengelola produk. Data rate card, kreator, kategori, dan banner dapat dibaca dari Firestore; pengelolaan semua konten tersebut dari dashboard boleh menjadi tahap berikutnya kecuali diminta secara eksplisit.

---

## 2. Stack teknologi

### Frontend

- Flutter stable + Dart null safety.
- Material 3 dengan theme dan komponen visual custom.
- `flutter_riverpod` untuk state management dan dependency injection.
- `go_router` untuk routing dan route guards.
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`.
- `google_sign_in` untuk Google Sign-In native.
- `image_picker` untuk memilih foto produk/profil.
- `url_launcher` untuk membuka WhatsApp dan link portofolio.
- `cached_network_image` untuk gambar dari URL dengan loading/error fallback.
- `intl` untuk format Rupiah dan angka/tanggal bila diperlukan.

Gunakan versi paket yang kompatibel dengan Flutter SDK yang terpasang; jangan memaksakan versi yang belum kompatibel. Verifikasi API `google_sign_in` sesuai versi paket terpasang.

### Backend terkelola

- Firebase Authentication: identitas dan sesi.
- Cloud Firestore: data katalog, profil, keranjang, banner, jasa, kreator, dan kategori.
- Firebase Storage: file foto.
- Firestore Security Rules dan Storage Security Rules: perlindungan akses data.
- Firebase Admin SDK: hanya untuk operasi administrasi tepercaya, misalnya memberikan custom claim admin.

Flutter/Dart dipakai untuk aplikasi klien. Firebase menyediakan backend terkelola sehingga MVP tidak membutuhkan server API buatan sendiri. Jika kelak ada pembayaran, ketersediaan sewa berbasis tanggal, atau proses booking yang atomik, tambahkan backend tepercaya/Cloud Functions untuk operasi tersebut.

---

## 3. Diagram arsitektur

```text
Pengguna / Admin
       |
       v
Flutter Mobile App (Dart)
  | UI / Screens
  | Riverpod Providers / State
  | GoRouter / Route Guards
  | Feature Repositories
  |
  +---------------- Firebase Authentication
  |                    - Email/password
  |                    - Google Sign-In
  |                    - ID token + admin claim
  |
  +---------------- Cloud Firestore
  |                    - categories
  |                    - products
  |                    - banners
  |                    - service_rates
  |                    - creatives
  |                    - users/{uid}
  |                    - users/{uid}/cart_items
  |
  +---------------- Firebase Storage
  |                    - product images
  |                    - profile images
  |                    - banner images
  |                    - creative images
  |
  +---------------- url_launcher
                       - wa.me URL dengan pesan ter-encode
                       - link portofolio kreator
```

### Pembagian tanggung jawab

**Presentation/UI** hanya menampilkan data, menerima input, dan menampilkan status loading/error/empty. Widget tidak boleh menulis query Firestore sendiri.

**State/provider** menangani status login, role, katalog realtime, search/filter, cart count, subtotal, dan status proses.

**Repository/data** menjadi satu-satunya lapisan yang mengakses Firebase. Repository memetakan dokumen Firestore ke model Dart, menangani CRUD, upload foto, dan pemetaan error.

**Firebase Security Rules** menegakkan izin di backend. Menyembunyikan tombol admin di UI saja bukan keamanan yang cukup.

---

## 4. Navigasi dan daftar halaman

### Alur aplikasi

```text
App Start
  └─ Auth Gate
      ├─ belum login -> Login
      │    ├─ Register
      │    ├─ Forgot Password
      │    └─ Login Google
      └─ sudah login -> cek role
           ├─ user -> Catalog/Home
           └─ admin -> Catalog/Home + akses Dashboard Admin

Catalog/Home
  ├─ Search + Filter Kategori/Brand
  ├─ Product Detail -> Add to Cart
  ├─ Cart -> Edit Qty/Remove -> Checkout WhatsApp
  ├─ Portfolio & Service Rates
  ├─ Creative Portfolio Link
  ├─ Profile
  └─ Admin Dashboard (hanya admin)
       ├─ Product List
       ├─ Add Product
       └─ Edit Product / Archive Product
```

### Detail screen

| Screen | Isi utama | Perilaku penting |
|---|---|---|
| Login | Email/username, password, tombol login, Google Sign-In, link register/forgot password | Validasi form, loading state, error yang mudah dipahami |
| Register | Nama, email, password, konfirmasi password | Membuat akun Firebase dan dokumen profil role user |
| Forgot Password | Email | Mengirim reset password via Firebase Auth |
| Catalog/Home | App bar, hamburger, profile icon, carousel tiga banner, search, filter kategori/brand, grid/list produk, cart badge | Halaman pertama setelah login; katalog mengamati perubahan Firestore realtime |
| Product Detail | Foto, nama, deskripsi, brand, kategori, harga sewa, stok/quantity tersedia, selector jumlah bila diperlukan, tombol Sewa | Tombol menambah barang ke cart; tampilkan umpan balik jelas |
| Cart | Daftar alat, foto mini, harga satuan, quantity control, subtotal tiap item, hapus item, total, Checkout WhatsApp | Total berubah saat quantity berubah; tidak mengizinkan quantity melebihi stok yang ditampilkan |
| Portfolio & Services | Pengantar singkat, empat kelompok layanan/rate card, dua kartu kreator | CTA link portofolio membuka URL yang telah dikonfigurasi |
| Profile | Foto, nama, email, nomor telepon (opsional), edit profil, logout | Email dikelola Firebase Auth; perubahan foto di-upload ke Storage |
| Admin Dashboard | Ringkasan sederhana, tombol tambah produk, daftar produk aktif/arsip | Jangan membuat grafik analitik palsu atau angka dummy yang terlihat nyata |
| Product Form | Foto, nama, deskripsi, kategori, brand, harga, stok, status aktif | Validasi; preview; upload; simpan; state submit dan error |

### Aturan navigasi global

- App bar pada seluruh halaman memiliki back button sesuai kebutuhan, judul/brand, tombol cart bila relevan, dan ikon profil di kanan atas.
- Di halaman root Catalog, tombol back menampilkan dialog konfirmasi keluar, bukan mencoba pop route yang tidak ada.
- Hamburger membuka Drawer penuh yang memuat semua kategori aktif, halaman Portofolio, Keranjang, Profil, dan Dashboard Admin jika claim admin valid.
- Pemilihan kategori dari Drawer menavigasikan ke Catalog dengan kategori tersebut sudah terpilih.
- Dashboard admin dan form edit produk memiliki tombol kembali yang konsisten.
- Gunakan satu shell/scaffold reusable agar app bar, back behavior, dan drawer tidak diimplementasikan ulang berbeda-beda di setiap screen.

---

## 5. Rancangan katalog dan filter

### Product card

Tampilkan foto rasio konsisten, nama alat, brand, harga dengan periode yang jelas, serta indikator stok yang tidak membingungkan. Hindari menampilkan seluruh deskripsi dalam card. Card dapat ditekan untuk membuka detail.

### Search dan filter

- Search berdasarkan nama produk, brand, dan kata kunci relevan. Untuk katalog kecil, filter client-side dari stream boleh digunakan; untuk katalog besar, rancang indexing/field pencarian yang sesuai.
- Kategori utama berasal dari collection `categories`, bukan list statis yang tersebar di banyak file.
- Brand filter diturunkan dari brand produk aktif dalam kategori terpilih. Brand tidak perlu menjadi subkategori tersendiri jika kebutuhan utamanya hanya filter merek.
- Filter kategori dan brand dapat dikombinasikan dengan query search.
- Sediakan tombol reset filter.
- Status loading, empty result, error, dan retry wajib ada.

### Realtime

Catalog menggunakan stream Firestore dan otomatis memperbarui UI saat admin menambah atau memperbarui produk. Hanya tampilkan produk `isActive == true`. Pastikan query dan security rules saling cocok; Security Rules bukan mekanisme untuk memfilter hasil query.

---

## 6. Model data Firestore

Gunakan document ID sebagai ID utama. Timestamp disimpan sebagai `createdAt` dan `updatedAt` menggunakan server timestamp bila memungkinkan. Nama field konsisten dalam `lowerCamelCase`.

### 6.1 `categories/{categoryId}`

```json
{
  "name": "Kamera",
  "slug": "kamera",
  "description": "Kamera untuk kebutuhan foto dan video",
  "iconKey": "camera",
  "sortOrder": 1,
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

`iconKey` dipetakan ke ikon yang dikenal aplikasi, bukan nama class yang dieksekusi dinamis.

### 6.2 `products/{productId}`

```json
{
  "name": "Lumix G85",
  "description": "Deskripsi kondisi, fungsi, dan kelengkapan alat.",
  "categoryId": "kamera",
  "brand": "Panasonic",
  "price": 150000,
  "priceUnit": "per_day",
  "stockQuantity": 2,
  "imageUrls": ["https://..."],
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

Validasi: nama tidak kosong, kategori valid, brand tidak kosong, harga integer >= 0, stok integer >= 0, dan foto sesuai kebutuhan aplikasi. `imageUrls` dapat berisi satu atau beberapa gambar; MVP boleh menampilkan foto utama pertama terlebih dahulu.

Produk yang dihapus dari katalog sebaiknya diarsipkan dengan `isActive = false` sehingga tidak terlihat oleh pelanggan dan referensi dari keranjang lama tidak langsung rusak. Daftar admin tetap dapat menampilkan arsip dan menyediakan pulihkan. Penghapusan permanen boleh disediakan terpisah dengan konfirmasi dan pembersihan file Storage.

### 6.3 `users/{uid}`

```json
{
  "displayName": "Nama Pengguna",
  "email": "user@example.com",
  "phoneNumber": "",
  "photoUrl": "",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

Jangan menerima perubahan `admin`/`role` dari form profil. Role admin dikelola melalui Firebase custom claims tepercaya, bukan field yang bebas diedit klien.

### 6.4 `users/{uid}/cart_items/{productId}`

```json
{
  "productId": "product-document-id",
  "productNameSnapshot": "Lumix G85",
  "brandSnapshot": "Panasonic",
  "imageUrlSnapshot": "https://...",
  "unitPriceSnapshot": 150000,
  "priceUnitSnapshot": "per_day",
  "quantity": 1,
  "updatedAt": "Timestamp"
}
```

Gunakan `productId` sebagai document ID sehingga satu produk hanya memiliki satu baris cart dan menambahkan produk yang sama akan menaikkan quantity, bukan membuat baris duplikat. Snapshot dipakai untuk tampilan yang stabil; saat checkout, baca ulang harga/status produk dari Firestore untuk mencegah pesan memakai harga lama.

### 6.5 `banners/{bannerId}`

```json
{
  "title": "Sewa Gear untuk Cerita yang Lebih Besar",
  "imageUrl": "https://...",
  "targetType": "portfolio",
  "targetValue": "",
  "sortOrder": 1,
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

`targetType` dibatasi ke nilai seperti `portfolio`, `category`, atau `externalUrl`. Validasi target sebelum navigasi/membuka URL. Seed tiga banner aktif; pastikan satu di antaranya menuju halaman Portofolio.

### 6.6 `service_rates/{serviceId}`

Contoh kelompok layanan:

1. Commercial / Social Media Video
2. Video Editing / Post-production
3. Event & Project Documentation
4. Commercial & Portrait Photography

Field yang disarankan: `title`, `description`, `rateLabel`, `startingPrice` (opsional), `priceUnit`, `deliverables` (array), `sortOrder`, `isActive`, `updatedAt`. Jangan mengarang rate card final; gunakan nilai placeholder yang secara visual ditandai sebagai contoh sampai rate sebenarnya dimasukkan.

### 6.7 `creatives/{creativeId}`

```json
{
  "name": "Nama Kreator",
  "roleTitle": "Videographer & Video Editor",
  "specialties": ["Commercial Video", "Editing"],
  "photoUrl": "https://...",
  "portfolioUrl": "https://...",
  "sortOrder": 1,
  "isActive": true,
  "updatedAt": "Timestamp"
}
```

Seed dua profil dengan data yang mudah diganti. Jangan menciptakan klaim pengalaman, foto orang, atau URL portofolio palsu sebagai data produksi.

### Collection MVP yang tidak dibutuhkan dulu

Belum perlu collection `orders` karena checkout hanya membuka WhatsApp dan belum mencatat booking di aplikasi. Tambahkan booking/order pada versi berikutnya jika dibutuhkan status pesanan, tanggal sewa, pembayaran, deposit, histori pemesanan, atau pengurangan stok setelah konfirmasi.

---

## 7. Logika keranjang dan checkout WhatsApp

### Aturan perhitungan

Untuk setiap item:

`subtotalItem = hargaSatuanAktual × quantity`

Total:

`total = jumlah seluruh subtotalItem`

Semua perhitungan harus memakai integer Rupiah, bukan `double` untuk nilai uang. Format tampilan menggunakan format Indonesia, contohnya `Rp150.000`.

### Alur tombol Sewa

1. Pastikan pengguna login.
2. Baca produk dan cek `isActive == true`.
3. Cek jumlah yang diminta tidak melebihi `stockQuantity`.
4. Jika produk sudah ada di cart, naikkan quantity; jika belum, buat item cart.
5. Tampilkan feedback seperti snackbar dan cart badge yang terbarui.
6. Jangan menampilkan pesan “berhasil dipesan”; statusnya baru “ditambahkan ke keranjang”.

### Alur checkout

1. Jika cart kosong, nonaktifkan checkout.
2. Baca ulang setiap produk dari Firestore.
3. Tampilkan penanganan jika produk sudah diarsipkan, harga berubah, atau stok tidak cukup; minta user memperbarui cart sebelum melanjutkan.
4. Hitung ulang semua subtotal dan total dari data aktual.
5. Buat pesan WhatsApp berisi nama pengguna bila tersedia, nama produk, brand, quantity, harga satuan, subtotal tiap item, total, dan catatan bahwa periode serta ketersediaan akan dikonfirmasi.
6. URL memakai format `https://wa.me/<nomor_internasional>?text=<pesan_ter-encode>` dan dibuka menggunakan `url_launcher`.
7. Jika WhatsApp tidak tersedia, tampilkan error yang jelas serta opsi membuka link melalui browser atau menyalin pesan.
8. Jangan mengosongkan cart sebelum user menyatakan proses pengiriman/pemesanan dilanjutkan, atau jelaskan dengan jelas kapan cart di-reset.

Contoh pesan yang dibuat aplikasi:

```text
Halo, saya ingin menanyakan penyewaan alat berikut:

1. Lumix G85 — Panasonic
   Jumlah: 1
   Harga satuan: Rp150.000 / hari
   Subtotal: Rp150.000

2. Wireless Microphone
   Jumlah: 2
   Harga satuan: Rp50.000 / hari
   Subtotal: Rp100.000

TOTAL ESTIMASI: Rp250.000 / hari

Mohon konfirmasi ketersediaan, periode sewa, dan ketentuan lainnya.
Nama: Nama Pengguna
```

Nomor WhatsApp harus berupa konfigurasi sentral dengan kode negara tanpa `+`, spasi, atau tanda baca. Jangan menyebarkan nomor ke banyak file. Nomor final belum ditentukan dan harus diberikan pemilik aplikasi.

---

## 8. Login, register, dan hak akses admin

### Pengguna biasa

- Register: email/password, lalu buat dokumen `users/{uid}`.
- Login: Firebase email/password.
- Google Sign-In: autentikasi melalui `google_sign_in`, lalu credential dikirim ke Firebase Auth.
- Login Google pertama kali membuat/memperbarui profil berdasarkan data akun Google.
- Logout memakai Firebase Auth sign out, membersihkan state in-memory, lalu kembali ke login.
- Forgot password menggunakan `sendPasswordResetEmail`.

### Admin

Keinginan memakai username `admin` bisa diwujudkan sebagai alias untuk akun Firebase Auth khusus. Namun, password `pass` **jangan ditanam di source code**, karena dapat diekstrak dari aplikasi dan bukan sistem autentikasi yang aman.

Implementasi yang disarankan:

1. Buat akun admin khusus di Firebase Authentication (contoh email admin yang dikontrol pemilik aplikasi).
2. Buat script operasional tepercaya yang memberi akun tersebut custom claim `{ "admin": true }` menggunakan Firebase Admin SDK. Jalankan satu kali di lingkungan developer/admin yang tepercaya; jangan pernah menjalankan Admin SDK dengan kredensial privileged di aplikasi Flutter.
3. Login form boleh menerima alias `admin` dan memetakannya ke email admin yang dikonfigurasi, tetapi password tetap divalidasi oleh Firebase Authentication.
4. Admin guard membaca custom claim dari ID token. Refresh token setelah claim diberikan.
5. Firestore Rules dan Storage Rules mengharuskan `request.auth.token.admin == true` untuk operasi admin.
6. User biasa tidak bisa mengubah custom claim, mengedit role sendiri, atau menulis produk hanya dengan memodifikasi UI.

Jika kredensial `admin/pass` diwajibkan hanya untuk demo kelas, buat akun sementara di Firebase Emulator atau project development terpisah, kemudian ganti sebelum rilis. Jangan menjadikannya password produksi.

### Pengamanan dasar

- Jangan commit file service-account key, password, atau file konfigurasi rahasia.
- Firebase client config bukan pengganti Security Rules.
- Jangan pernah menggunakan rules terbuka seperti `allow read, write: if true`.
- Validasi form di client untuk UX, dan validasi izin/data melalui rules untuk keamanan.
- Pertimbangkan Firebase App Check sebelum rilis.

---

## 9. Firebase Security Rules — persyaratan perilaku

Cline perlu membuat `firebase/firestore.rules` dan `firebase/storage.rules` yang bisa diaudit. Sesuaikan rules dengan nama koleksi final dan uji menggunakan Emulator Suite bila tersedia.

### Firestore

- Fungsi `signedIn()` memeriksa `request.auth != null`.
- Fungsi `isAdmin()` memeriksa user login dengan `request.auth.token.admin == true`.
- Katalog, kategori, banner, rate card, dan kreator hanya bisa dibaca sesuai kebutuhan aplikasi yang login; hanya admin yang dapat create/update/delete.
- `users/{uid}` hanya bisa dibaca pengguna yang cocok dengan UID atau admin jika dibutuhkan. Update dari pemilik dibatasi pada field profil yang diizinkan dan tidak boleh menambah atau mengubah role/claim.
- `users/{uid}/cart_items/{productId}` hanya dapat diakses pemilik cart, dan perubahan quantity harus integer positif dengan field yang tervalidasi. User tidak boleh menulis ke cart user lain.
- Tolak semua akses yang tidak secara eksplisit diizinkan.
- Tambahkan rules validasi tipe field/angka pada dokumen produk dan cart sesuai kemampuan Rules.

### Storage

- `products/**` hanya dapat ditulis admin. Validasi `contentType` gambar dan ukuran maksimal yang ditentukan project.
- `profiles/{uid}/**` hanya dapat ditulis pemilik UID dan hanya untuk image dengan ukuran wajar.
- `banners/**` dan `creatives/**` hanya dapat ditulis admin.
- Pembacaan gambar sesuai kebutuhan aplikasi dan aturan Firebase yang dipilih.

Catatan: aturan Firestore tidak otomatis melindungi file di Storage; keduanya perlu rules sendiri. Jangan menganggap filter UI sebagai kontrol keamanan.

---

## 10. Profil dan unggah gambar

- Gunakan `image_picker` untuk memilih foto.
- Tampilkan preview lokal sebelum upload.
- Batasi jenis file ke image dan beri batas ukuran yang masuk akal, misalnya maksimum 5 MB per gambar.
- Tampilkan progress/error jika upload berjalan lama atau gagal.
- Setelah upload berhasil, simpan URL hasil upload ke Firestore.
- Saat mengganti foto, pertahankan foto lama jika upload baru gagal.
- Saat produk diarsipkan, jangan menghapus foto secara otomatis karena produk mungkin dipulihkan.
- Saat penghapusan permanen, hapus file Storage yang terkait dengan aman dan tangani kemungkinan file sudah tidak ada.

---

## 11. Arah desain UI untuk menghindari AI slop

### Arah visual

Gunakan visual **editorial gear-rental**: bersih, fungsional, dan terasa dekat dengan industri foto/video. Foto alat harus menjadi fokus; elemen UI membantu pengguna membandingkan alat dengan cepat.

Palet awal yang konsisten:

- Canvas: warm off-white `#F5F4EF`
- Surface: white `#FFFFFF`
- Text utama: charcoal `#171817`
- Text sekunder: `#6F746F`
- Primary/deep green: `#172A26`
- Accent lime: `#C7F36A` (gunakan secukupnya untuk CTA/status penting)
- Border: `#DFE2DA`
- Error: `#B93838`

Ini titik awal desain, bukan kewajiban brand final. Simpan semua warna, spacing, radius, dan typography dalam design tokens/theme, bukan angka acak pada setiap widget.

### Aturan UI

- Gunakan spacing berbasis kelipatan 4/8 px; card radius konsisten, misalnya 12–16 px.
- Hierarki teks jelas: headline, title, body, caption; jangan memakai banyak ukuran font tanpa alasan.
- Hindari gradient dekoratif, glassmorphism, shadow tebal, border pelangi, glow, ikon emoji sebagai UI, dan efek animasi berlebihan.
- Jangan membungkus setiap baris teks ke dalam card. Pakai ruang kosong, divider halus, dan alignment.
- Jangan menampilkan semua informasi produk pada thumbnail. Detail lengkap ada di halaman detail.
- Semua tombol memiliki status pressed/disabled/loading yang masuk akal dan label yang jelas.
- Carousel memiliki tinggi dan crop gambar konsisten, indikator posisi, auto-play dengan interval wajar, pause saat halaman tidak aktif bila memungkinkan, dan click action yang benar.
- Gunakan aset/gambar nyata dari pemilik aplikasi. Saat belum tersedia, tampilkan placeholder netral yang menandakan gambar belum disediakan, bukan gambar acak yang seolah produk asli.
- Layout harus aman pada layar kecil; tangani keyboard, safe area, overflow, teks panjang, serta loading/error/empty state.
- Aksesibilitas: kontras memadai, ukuran tap target cukup, semantics untuk icon-only button, dan teks tidak bergantung pada warna saja.
- Animasi hanya untuk mendukung feedback/transisi; bukan untuk dekorasi yang mengganggu.
- Admin UI harus efisien untuk mengelola data, bukan meniru dashboard analytics generik.

---

## 12. Struktur direktori yang disarankan

```text
lib/
  main.dart
  app.dart
  core/
    config/
      app_config.dart
    constants/
      app_constants.dart
    errors/
      app_exception.dart
    routing/
      app_router.dart
      auth_guard.dart
    theme/
      app_theme.dart
      app_colors.dart
      app_spacing.dart
    utils/
      currency_formatter.dart
      whatsapp_message_builder.dart
      validators.dart
    widgets/
      app_scaffold.dart
      app_drawer.dart
      app_loading.dart
      app_error_state.dart
      app_empty_state.dart
      app_primary_button.dart
      product_image.dart
  features/
    auth/
      data/auth_repository.dart
      domain/auth_user.dart
      presentation/auth_gate.dart
      presentation/login_screen.dart
      presentation/register_screen.dart
      presentation/forgot_password_screen.dart
      presentation/auth_providers.dart
    catalog/
      data/product_repository.dart
      data/category_repository.dart
      domain/product.dart
      domain/category.dart
      presentation/catalog_screen.dart
      presentation/product_detail_screen.dart
      presentation/widgets/product_card.dart
      presentation/widgets/catalog_filters.dart
      presentation/catalog_providers.dart
    cart/
      data/cart_repository.dart
      domain/cart_item.dart
      presentation/cart_screen.dart
      presentation/cart_providers.dart
    portfolio/
      data/portfolio_repository.dart
      domain/service_rate.dart
      domain/creative.dart
      presentation/portfolio_screen.dart
      presentation/portfolio_providers.dart
    profile/
      data/profile_repository.dart
      domain/user_profile.dart
      presentation/profile_screen.dart
      presentation/edit_profile_screen.dart
    admin/
      data/admin_product_repository.dart
      presentation/admin_dashboard_screen.dart
      presentation/admin_product_list_screen.dart
      presentation/product_form_screen.dart
      presentation/admin_providers.dart
firebase/
  firestore.rules
  storage.rules
  firestore.indexes.json
scripts/
  grant_admin.mjs
  seed_sample_data.*
test/
  currency_formatter_test.dart
  cart_calculation_test.dart
  whatsapp_message_builder_test.dart
  product_model_test.dart
SETUP.md
```

Struktur boleh menyesuaikan project yang sudah ada, tetapi jangan membuat seluruh aplikasi dalam satu file. Pisahkan model, repository, provider, screen, dan reusable widget. Hindari abstraksi berlapis yang tidak memberi manfaat; pola repository + provider sudah cukup untuk MVP.

---

## 13. Konfigurasi yang perlu dilakukan pemilik project

1. Pastikan Flutter SDK dan Android toolchain berjalan (`flutter doctor`).
2. Buat project Firebase dan daftarkan aplikasi Android/iOS sesuai target.
3. Jalankan `flutterfire configure` agar konfigurasi Firebase dibuat sesuai platform. Jangan mengarang nilai konfigurasi atau mengklaim auth berjalan jika belum terhubung.
4. Aktifkan metode Email/Password dan Google di Firebase Authentication.
5. Untuk Android, siapkan SHA-1/SHA-256 yang dibutuhkan konfigurasi Google Sign-In sesuai panduan Firebase.
6. Buat Cloud Firestore dan deploy/test rules.
7. Siapkan Firebase Storage dan deploy/test storage rules. Periksa persyaratan paket billing yang berlaku pada project Firebase sebelum menggunakan Storage; ketentuan paket dapat berubah.
8. Buat akun admin dari lingkungan tepercaya dan berikan custom claim admin menggunakan skrip terpisah.
9. Isi nomor WhatsApp, tiga gambar banner, empat rate card, foto dan link portofolio dua kreator.
10. Jalankan `flutter analyze`, unit test, dan uji di emulator/perangkat nyata.

Referensi resmi untuk setup Firebase Flutter: https://firebase.google.com/docs/flutter/setup

---

## 14. Definition of Done / checklist penerimaan

### Autentikasi

- [ ] User bisa register dengan email/password dan masuk kembali.
- [ ] Google Sign-In benar-benar menggunakan Firebase Auth, bukan tombol UI palsu.
- [ ] Forgot password mengirim email reset melalui Firebase Auth.
- [ ] User yang logout tidak bisa membuka screen terproteksi tanpa login ulang.
- [ ] Admin claim diperiksa; user biasa tidak dapat membuka dashboard admin melalui deep link.

### Katalog

- [ ] Setelah login, pengguna mendarat di katalog.
- [ ] Tiga banner tampil dan satu mengarah ke halaman Portofolio.
- [ ] Search, filter kategori, dan filter brand bisa dikombinasikan.
- [ ] Detail menampilkan foto, judul, deskripsi, brand, kategori, harga, dan stok.
- [ ] Produk berubah di katalog setelah admin menyimpan perubahan tanpa perlu hard restart.
- [ ] Loading/error/empty state ditangani.

### Cart dan WhatsApp

- [ ] Produk yang sama tidak menghasilkan baris duplikat.
- [ ] Quantity bisa dinaikkan/diturunkan dan item bisa dihapus.
- [ ] Quantity tidak boleh kurang dari satu dan tidak boleh melebihi stok yang tersedia.
- [ ] Subtotal dan total benar.
- [ ] Checkout membaca ulang harga/status produk sebelum membuat pesan.
- [ ] WhatsApp menerima teks yang ter-encode dan seluruh harga/quantity tepat.
- [ ] Nomor WhatsApp terpusat di konfigurasi.

### Portofolio dan profil

- [ ] Empat kelompok rate card tampil dengan nilai yang dikonfigurasi pemilik aplikasi.
- [ ] Dua kartu kreator tampil dengan spesialisasi dan foto.
- [ ] Link portofolio masing-masing membuka URL yang benar.
- [ ] User dapat mengganti nama, telepon, dan foto yang diizinkan.
- [ ] Foto profile di-upload ke Storage dan URL tersimpan.

### Admin/security

- [ ] Admin dapat menambah, mengedit, dan mengarsipkan produk.
- [ ] Validasi form dan upload foto berjalan.
- [ ] User biasa gagal melakukan write produk walaupun memanggil Firebase dari luar UI.
- [ ] User tidak bisa mengubah role/claim sendiri.
- [ ] Rules tidak terbuka untuk semua orang.
- [ ] Tidak ada password atau service-account key di repository.

### Kualitas implementasi

- [ ] `flutter analyze` tanpa error; warning yang tersisa ditinjau dan diperbaiki bila wajar.
- [ ] Unit test untuk hitungan cart, format Rupiah, builder pesan WhatsApp, dan model data lulus.
- [ ] Tidak ada placeholder yang menyamar sebagai fitur sudah berjalan.
- [ ] Tidak ada dummy data yang terlihat seperti data produksi.
- [ ] Tidak ada `TODO` kritis yang disembunyikan; seluruh setup manual tercantum di `SETUP.md`.

---

---

## Catatan penggunaan

Dokumen ini adalah **spesifikasi produk dan arsitektur**, bukan perintah agar seluruh aplikasi dibuat sekaligus. Ikuti urutan pengerjaan dan prompt per fase di `docs/PROMPT_CLINE_BERTAHAP.md`. Selesaikan satu fase, periksa hasilnya, lalu jalankan prompt fase berikutnya. Jangan gunakan prompt mega lama yang meminta seluruh fase diteruskan tanpa checkpoint.
