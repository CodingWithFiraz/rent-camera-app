# Panduan Eksekusi Cline Bertahap
## Aplikasi Penyewaan Alat Foto/Video & Portofolio Jasa

Panduan ini melengkapi `BLUEPRINT_APLIKASI.md`. Tujuannya bukan sekadar meminta Cline membuat semua halaman, tetapi menuntunnya membangun aplikasi dalam potongan kecil yang dapat diuji dan ditinjau.

## Jawaban intinya: jangan jalankan semua fase sekaligus

Gunakan metode ini:

1. **Siapkan workspace** dan letakkan blueprint di folder project.
2. **Jalankan Prompt 0 — Audit & Rencana** sekali. Task ini hanya memeriksa repository dan menyusun rencana; belum membangun fitur.
3. **Jalankan Prompt Fase 1**, lalu tunggu Cline menyelesaikan fase dan membaca hasilnya.
4. Tinjau hasil (`flutter analyze`, test, diff, dan blocker). Buat commit/checkpoint Git saat fase sudah baik.
5. Baru jalankan prompt fase berikutnya. **Satu prompt = satu fase.**
6. Terakhir, jalankan Fase 7 untuk integrasi, keamanan, dan pengujian akhir.

Ini lebih terkendali daripada menempelkan prompt raksasa yang meminta semua fase dikerjakan terus-menerus. Dokumentasi Cline juga menyarankan task yang terfokus pada satu tujuan; aturan proyek persisten bisa ditempatkan di `.clinerules/`. Sumber: [Cline Rules](https://github.com/cline/cline/blob/main/docs/customization/cline-rules.mdx) dan [Cline Tasks](https://github.com/cline/cline/blob/main/docs/core-workflows/task-management.mdx).

---

## A. Siapkan struktur file proyek

Di root project Flutter, susun struktur berikut:

```text
nama-project/
├── .clinerules/
│   ├── 01-product-and-architecture.md
│   └── 02-workflow-security-quality.md
├── docs/
│   ├── BLUEPRINT_APLIKASI.md
│   └── PROMPT_CLINE_BERTAHAP.md
├── lib/
├── test/
├── pubspec.yaml
└── ...
```

File aturan `.clinerules` dan dokumen tersedia di starter bundle. Salin ke root project sesuai struktur di atas. **Gabungkan folder `docs/` bila sudah berisi file penting; jangan menimpa file milikmu tanpa memeriksa.**

### Sebelum mulai
- Buka folder root project Flutter yang benar di VS Code.
- Pastikan `flutter doctor` berjalan dan proyek bisa dibuka.
- Jika memakai Git, buat commit awal atau pastikan perubahan saat ini sudah tersimpan. Jangan memulai sebelum tahu apakah ada pekerjaan yang belum di-commit.
- Hindari auto-approve tanpa batas untuk command berisiko atau penghapusan file.
- Jika Cline baru saja membuat `.clinerules`, mulai task baru agar aturan workspace dimuat kembali.

---

## B. Prompt 0 — Audit repository dan buat implementation plan

Jalankan ini **pertama kali saja**, di root project:

```text
Baca aturan proyek dari `.clinerules/` dan baca `docs/BLUEPRINT_APLIKASI.md` sebagai sumber kebenaran spesifikasi.

TASK INI HANYA AUDIT DAN PERENCANAAN. Jangan implementasikan halaman, service, model, atau fitur aplikasi pada task ini.

Lakukan:
1. Periksa struktur repository, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, versi Flutter/Dart, platform Android/iOS yang tersedia, folder test, aturan Firebase, serta konfigurasi Firebase yang sudah ada.
2. Jalankan pemeriksaan read-only yang relevan seperti `flutter --version`, `dart --version`, `flutter doctor -v`, `git status --short`, dan daftar file. Jangan menampilkan isi secret/config sensitif.
3. Identifikasi kode yang sudah bekerja dan harus dipertahankan. Jangan menghapus atau mengganti file yang sudah ada.
4. Periksa apakah Firebase native config, `firebase_options.dart`, Google Sign-In setup, Firestore rules, Storage rules, serta tooling test/emulator tersedia. Catat statusnya; jangan membuat konfigurasi atau secret palsu.
5. Buat atau perbarui `IMPLEMENTATION_PLAN.md` dengan fase dan dependency yang jelas:
   - Fase 1: fondasi aplikasi dan autentikasi.
   - Fase 2: model, repository, schema, security rules, dan data setup.
   - Fase 3: katalog, carousel, search/filter, detail produk, realtime.
   - Fase 4: keranjang, validasi harga/stok, kalkulasi, WhatsApp.
   - Fase 5: portofolio/rate card dan profil pengguna.
   - Fase 6: dashboard admin dan CRUD produk.
   - Fase 7: integrasi, security hardening, accessibility, test, dan build validation.
6. Untuk tiap fase, catat target, file/modul yang kemungkinan disentuh, dependency, acceptance criteria, blocker eksternal, serta status awal `Not started`.
7. Catat keputusan yang belum diberikan pemilik, misalnya nomor WhatsApp, harga/periode sewa final, aset banner, rate card, URL portofolio, dan konfigurasi Firebase. Jangan mengarang nilainya.
8. Jangan menulis lebih banyak dokumentasi lain jika tidak diperlukan.

Kriteria selesai:
- Audit repo selesai.
- `IMPLEMENTATION_PLAN.md` tersedia dan akurat.
- Tidak ada fitur aplikasi yang diimplementasikan pada task ini.
- Jalankan `git diff --check` jika Git tersedia.

BERHENTI setelah Prompt 0 selesai. Jangan lanjut ke Fase 1. Dalam ringkasan akhir, sebutkan status repository, file plan, hasil command, blocker, dan prompt fase yang harus saya jalankan selanjutnya.
```

Setelah Prompt 0 selesai, baca `IMPLEMENTATION_PLAN.md`. Jika rencana masuk akal, jalankan Fase 1 pada task terpisah.

---

## C. Prompt Fase 1 — Fondasi Flutter dan autentikasi

```text
Baca `.clinerules/`, `docs/BLUEPRINT_APLIKASI.md`, dan `IMPLEMENTATION_PLAN.md`.

KERJAKAN FASE 1 SAJA: fondasi aplikasi, theme, routing, dan autentikasi. Jangan mulai katalog, cart, portfolio, atau admin CRUD.

Langkah:
1. Periksa pola dan dependency yang sudah ada sebelum mengubah `pubspec.yaml`. Pertahankan package yang masih cocok; tambahkan hanya yang dibutuhkan.
2. Siapkan struktur feature-first, bootstrap aplikasi, Material 3 theme/design tokens, shared loading/error/empty states, serta routing `go_router` sesuai kebutuhan fase ini.
3. Implementasikan auth repository/provider dan halaman Login, Register, serta Forgot Password dengan Firebase Auth email/password.
4. Implementasikan Google Sign-In native melalui package/API yang cocok dengan versi yang terpasang. Alur harus benar-benar menghasilkan credential Firebase, bukan sekadar tombol UI.
5. Buat/update `users/{uid}` saat register atau login Google pertama kali tanpa menghapus field profil yang sudah ada. Jangan mengizinkan form mengatur role admin.
6. Buat auth gate yang memonitor sesi: belum login -> Login; berhasil login -> Catalog route placeholder/route target yang jelas. Halaman katalog penuh dikerjakan pada Fase 3.
7. Siapkan logout yang benar-benar sign out Firebase dan membersihkan state terkait.
8. Tangani error/loading/disabled state; validasi email/password/konfirmasi password. Jangan menampilkan raw exception.
9. Jika file konfigurasi Firebase belum ada, jangan membuat `firebase_options.dart` palsu. Integrasikan dengan pola yang benar untuk konfigurasi yang tersedia, catat blocker, dan dokumentasikan langkah `flutterfire configure`/provider setup di `SETUP.md`. Jangan mengklaim login end-to-end telah diuji jika belum bisa.
10. Tambahkan test untuk validator atau logika auth yang bisa diuji tanpa kredensial real.

Sebelum selesai:
- Jalankan format, `flutter analyze`, dan test relevan.
- Perbaiki error yang berasal dari fase ini.
- Update status Fase 1 di `IMPLEMENTATION_PLAN.md` secara jujur.
- Tinjau `git diff --check` dan `git status --short`.

JANGAN mengerjakan fase lain. BERHENTI setelah Fase 1. Ringkas file yang berubah, apa yang benar-benar bekerja, command dan hasilnya, blocker Firebase/Google bila ada, serta acceptance criteria yang belum terpenuhi.
```

**Review sebelum lanjut:** pastikan aplikasi tidak punya route yang membiarkan user masuk tanpa autentikasi. Jika Firebase belum diset, UI login bisa dibuat, tetapi login tidak boleh diklaim berfungsi penuh.

---

## D. Prompt Fase 2 — Model, repository, schema, dan security rules

```text
Baca aturan proyek, `docs/BLUEPRINT_APLIKASI.md`, dan `IMPLEMENTATION_PLAN.md`.

KERJAKAN FASE 2 SAJA: model domain, repository/data access Firebase, provider dasar, schema dan security rules. Jangan membangun UI katalog/cart/admin pada fase ini kecuali komponen kecil diperlukan untuk compile.

Langkah:
1. Cocokkan model Dart dengan schema pada blueprint: Category, Product, UserProfile, CartItem, Banner, ServiceRate, Creative. Buat parsing dari Firestore yang tervalidasi dan tangani field lama/hilang secara eksplisit.
2. Pisahkan operasi data ke repository. UI tidak boleh melakukan query Firestore langsung.
3. Implementasikan repository awal untuk categories/products/banners/service rates/creatives/user profile/cart sesuai scope data, dengan API yang konsisten dan error yang dapat ditangani UI.
4. Gunakan stream untuk data yang wajib realtime. Terapkan `isActive` pada query katalog; pastikan Security Rules cocok dengan pola query yang digunakan.
5. Buat `firebase/firestore.rules`, `firebase/storage.rules`, dan indexes bila diperlukan. Akses default harus ditolak. Hanya admin claim yang dapat menulis katalog/kategori/banner/service_rates/creatives. Cart dan profil dibatasi UID pemilik.
6. Jangan menjadikan field `role` dari dokumen profile sebagai sumber otoritatif admin. Gunakan custom claim `{admin: true}`.
7. Buat skrip seed yang jelas berlabel SAMPLE atau instruksi seed manual yang aman untuk kategori/banner/rate card/kreator. Jangan mengisi data nyata palsu atau URL random. Nilai placeholder harus mudah diganti dan tidak disamarkan sebagai data produksi.
8. Jangan deploy rules secara otomatis ke project Firebase tanpa verifikasi target yang eksplisit. Buat instruksi deploy di `SETUP.md`.
9. Tambahkan unit test mapping Product dan aturan bisnis sederhana, termasuk kasus field tak valid.
10. Perbarui dokumentasi setup dan plan sesuai status sebenarnya.

Verifikasi:
- Format, `flutter analyze`, test relevan.
- Jika Firebase Emulator tidak tersedia, jangan klaim rules sudah lolos emulator; dokumentasikan test yang belum dapat dijalankan dan langkahnya.
- Jalankan `git diff --check`.

BERHENTI setelah Fase 2. Jangan lanjut ke UI katalog. Laporkan file berubah, hasil test, status rules, dan blocker.
```

---

## E. Prompt Fase 3 — Katalog, carousel, search/filter, detail produk

```text
Baca aturan proyek, blueprint, dan implementation plan.

KERJAKAN FASE 3 SAJA: halaman Catalog/Home, carousel tiga banner, search/filter, Product Detail, serta stream katalog realtime.

Kebutuhan:
1. App bar konsisten: hamburger, identitas aplikasi, tombol cart/badge bila relevan, dan ikon profile di kanan atas.
2. Carousel tepat tiga slot/banner aktif dengan auto-play yang wajar, indikator slide, crop konsisten, dan tap action. Minimal satu banner wajib menuju halaman Portfolio. Banner lain menggunakan target kategori/external yang sudah dikonfigurasi; jangan mengarang URL.
3. Search dapat digabungkan dengan filter kategori dan brand. Kategori dari Firestore; brand filter menyesuaikan kategori terpilih. Sediakan reset filter.
4. Tampilkan produk dalam grid/list responsif dengan foto, nama, brand, dan harga plus periode sewa jelas. Jangan memenuhi card dengan seluruh deskripsi.
5. Product Detail menampilkan foto utama, nama, deskripsi, brand, kategori, harga/periode, stok dan aksi Add to Cart/Sewa. Fase ini boleh memanggil API cart yang akan disempurnakan di Fase 4, tetapi jangan membuat logika cart duplikat pada widget.
6. Katalog mengambil data dari repository/provider dan memakai stream/listener realtime. Hanya produk aktif yang tampil.
7. Buat loading, retryable error, empty search result, empty catalogue, gambar gagal dimuat, dan feedback interaksi.
8. Kategori default dari blueprint dapat diberikan melalui seed data yang jelas, bukan hardcode tersebar di widget.
9. Buat UI editorial gear-rental yang terarah; hindari dashboard/template generik, gradient dekoratif, shadow tebal, card bertumpuk, ikon emoji, dan placeholder yang tampak seperti produk asli.
10. Uji layout layar kecil, safe area, teks panjang, dan scroll. Jangan memakai ukuran tetap yang menyebabkan overflow.

Verifikasi:
- Jalankan format, `flutter analyze`, test relevan.
- Jika Firebase belum terhubung, buat state setup/error yang jujur; jangan gantikan repository dengan hardcoded dummy list untuk mengklaim fitur selesai.
- Update plan dengan kriteria yang benar-benar lulus dan jalankan `git diff --check`.

BERHENTI setelah Fase 3. Jangan lanjut cart/WhatsApp atau fase lain. Laporkan hasil dan blocker.
```

---

## F. Prompt Fase 4 — Keranjang dan checkout WhatsApp

```text
Baca aturan proyek, blueprint, implementation plan, model Product dan repository yang telah dibuat.

KERJAKAN FASE 4 SAJA: cart persistence, validasi, kalkulasi biaya, dan WhatsApp checkout.

Aturan:
1. Simpan cart per UID di `users/{uid}/cart_items/{productId}`. Product yang sama tidak membuat baris ganda.
2. Tambah, kurangi, dan hapus quantity. Quantity integer >= 1 dan tidak lebih dari stok terkini yang diketahui. Jelaskan jika perubahan stok memerlukan refresh.
3. Gunakan integer Rupiah. Buat fungsi teruji `subtotal = unitPrice * quantity` dan total dari seluruh subtotal. Format ke lokal Indonesia, contoh `Rp150.000`.
4. Harga memiliki `priceUnit` yang eksplisit. Jangan menulis `/hari` jika dokumen/config menyatakan periode lain atau belum menetapkan periode.
5. Sebelum checkout, baca ulang seluruh product dari Firestore. Hentikan checkout jika ada produk nonaktif/tidak ditemukan, harga berubah material, atau stok tidak cukup; jelaskan apa yang harus diperbaiki. Hitung ulang dengan data terbaru.
6. Buat pure function untuk menyusun pesan WhatsApp berisi produk, brand, jumlah, harga satuan, unit periode, subtotal, total estimasi, nama pengguna jika ada, dan catatan permintaan konfirmasi ketersediaan/periode. Sertakan test karakter khusus/URL encoding.
7. Nomor WhatsApp didefinisikan hanya di `AppConfig` dan belum diisi dengan nomor palsu.
8. Buka `https://wa.me/<nomor>?text=<encoded-message>` melalui `url_launcher`. Tangani launch failure dengan alternatif menyalin pesan atau membuka link yang tersedia.
9. Jangan mengklaim pesanan sudah dikonfirmasi, tidak mengurangi stok, tidak mengunci stok, tidak menambahkan payment flow. Jangan kosongkan cart tanpa keputusan UX yang jelas.
10. Cart screen menampilkan loading/error/empty state, foto mini, nama/brand, harga/periode, quantity controls, subtotal item, total, dan CTA checkout yang disabled saat cart kosong atau validasi gagal.

Verifikasi:
- Unit test kalkulasi, format Rupiah, builder pesan, dan URL encoding.
- Format, `flutter analyze`, test relevan, `git diff --check`.
- Update plan sesuai hasil sebenarnya.

BERHENTI setelah Fase 4. Jangan mulai portfolio/profile/admin.
```

---

## G. Prompt Fase 5 — Portofolio jasa, rate card, dan profil

```text
Baca aturan proyek, blueprint, dan implementation plan.

KERJAKAN FASE 5 SAJA: Portfolio & Service Rates, dua kartu kreator, Profile/Edit Profile, dan upload foto profil.

Portofolio:
1. Tampilkan empat kelompok layanan yang spesifik:
   - Commercial / Social Media Video
   - Video Editing / Post-production
   - Event & Project Documentation
   - Commercial & Portrait Photography
2. Data rate card dibaca dari repository Firestore. Tampilkan title, deskripsi, rate label/starting price bila sudah dikonfigurasi, unit, dan deliverables. Jangan mengarang harga final.
3. Render dua kartu kreator dari koleksi `creatives`, masing-masing berisi foto, nama, spesialisasi, dan CTA `Lihat Portofolio`.
4. CTA harus membuka URL valid melalui `url_launcher`; validasi scheme yang didukung. Jika data belum diisi, tampilkan configuration/empty state yang jelas, bukan profil rekaan.

Profile:
5. Tampilkan foto, nama, email, telepon, Edit Profile, dan Logout. Email mengikuti Firebase Auth; jangan membuka field role.
6. Nama/telepon disimpan ke `users/{uid}`. Foto dipilih dengan `image_picker`, preview dulu, validasi file image dan ukuran maksimal yang masuk akal, tampilkan progress/error, upload ke Storage, lalu simpan URL.
7. Jika upload foto baru gagal, jangan menghapus foto lama. Pastikan Storage Rules mengizinkan owner mengubah foto miliknya saja.
8. Jangan membuat placeholder sukses apabila write/upload gagal.

Verifikasi:
- Format, `flutter analyze`, test yang relevan, `git diff --check`.
- Cek layout layar kecil, loading/error/empty state, dan perilaku URL.
- Update plan berdasarkan hasil sebenarnya.

BERHENTI setelah Fase 5. Jangan mulai admin CRUD.
```

---

## H. Prompt Fase 6 — Dashboard admin dan CRUD produk

```text
Baca aturan proyek, blueprint, implementation plan, repository Product dan security rules yang sudah dibuat.

KERJAKAN FASE 6 SAJA: admin dashboard, daftar produk, tambah/edit, upload gambar, archive/restore.

Keamanan:
1. Admin hanya akun Firebase Auth dengan custom claim `{admin: true}` yang dibaca dari ID token. Gagal membaca/memverifikasi claim berarti akses ditolak (fail closed).
2. Jangan hardcode password `admin/pass`. Jika alias `admin` diimplementasikan, petakan ke email admin yang dikonfigurasi; password tetap divalidasi Firebase Auth.
3. Buat atau lengkapi skrip terpisah untuk memberikan custom claim memakai Firebase Admin SDK dalam lingkungan tepercaya. Jangan simpan service account JSON atau secret di repository dan jangan jalankan Admin SDK privileged dari Flutter.
4. Route guard dan Firestore/Storage Rules harus sama-sama menolak non-admin. Hidden button bukan pengamanan.

Fitur:
5. Dashboard berisi tombol Tambah Alat, pencarian/filter seperlunya, produk aktif, dan daftar arsip. Jangan membuat angka analytics palsu.
6. Form Create/Edit mengelola nama, deskripsi, kategori, brand, harga integer Rupiah, priceUnit, stockQuantity, foto, dan status aktif. Validasi seluruh field; stok/harga tak boleh bernilai negatif.
7. Foto punya preview dan progress upload. Bila upload baru gagal, pertahankan gambar lama.
8. Save/create/update harus masuk ke Firestore; katalog pelanggan berubah lewat stream realtime tanpa reload manual.
9. Utamakan archive dengan `isActive=false`, sertakan restore. Penghapusan permanen harus punya konfirmasi serta pembersihan file yang aman jika fitur ini benar-benar disertakan.
10. Setelah save/delete/archive, tampilkan feedback berdasar hasil operasi nyata; jangan menunjukkan sukses sebelum operasi selesai.
11. Jika kategori kosong, jelaskan bahwa kategori perlu dibuat/seed; jangan menyimpan kategori random tersembunyi.

Verifikasi:
- Format, `flutter analyze`, test model/validator/repository bila tersedia, `git diff --check`.
- Jika rules belum dapat diuji dengan emulator/project, jelaskan batas verifikasi; jangan klaim aman hanya karena tombol disembunyikan.
- Update status plan secara jujur.

BERHENTI setelah Fase 6. Jangan langsung melakukan refactor besar di luar scope.
```

---

## I. Prompt Fase 7 — Integrasi, keamanan, quality gate, dan build check

```text
Baca `.clinerules/`, seluruh `docs/BLUEPRINT_APLIKASI.md`, `IMPLEMENTATION_PLAN.md`, dan review kode aplikasi yang benar-benar ada.

KERJAKAN FASE 7 SAJA: integrasi lintas fitur, security hardening, regresi, aksesibilitas, dan final quality gate. Jangan menambah fitur besar baru. Prioritaskan bug nyata dan acceptance criteria yang belum tercapai.

Checklist:
1. Jalankan `dart format .`, `flutter analyze`, `flutter test`, dan build command yang sesuai platform tersedia. Jika command tidak dapat dijalankan, tulis alasan sebenarnya.
2. Review auth gate, logout, Google Sign-In flow, role custom claim, route admin, Firestore Rules, Storage Rules. Pastikan user biasa tidak bisa menulis produk atau memodifikasi profil orang lain melalui backend.
3. Review katalog realtime, search+filter gabungan, tiga banner (satu menuju portofolio), detail produk, loading/error/empty state.
4. Review cart per UID, nilai integer Rupiah, stale price/stock handling, fungsi pesan WhatsApp, encoding URL, dan error saat `url_launcher` gagal.
5. Review service rate/kreator/profile/upload flow dan validasi URL eksternal.
6. Review admin CRUD/create/edit/archive/restore, upload gambar, dan realtime catalog.
7. Cek overflow pada layar kecil, safe area, keyboard/form, text panjang, semantics untuk ikon, tap target, kontras, dan konsistensi design tokens.
8. Tambahkan/perbaiki unit tests: currency formatting, cart calculation, WhatsApp builder/encoding, Product Firestore mapping, validation penting.
9. Tambahkan atau perbarui `SETUP.md` untuk Firebase configure, Email/Password, Google provider/SHA keys, Firestore/Storage rules, custom claim admin, nomor WhatsApp, aset, service rates/creatives, run/test/build.
10. Cari secret yang tidak seharusnya di-commit, fake-success, dummy data yang tidak ditandai, tombol inert, TODO kritis, dan dokumentasi yang menyatakan fitur selesai padahal belum terhubung.
11. Update `IMPLEMENTATION_PLAN.md` dengan status akhir per fase (`Complete`, `Blocked`, atau `Partially complete`) dan alasan berbukti. Jangan ubah blocker menjadi complete hanya agar checklist tampak hijau.
12. Jalankan `git diff --check` dan laporkan status Git.

Pada jawaban akhir cantumkan:
- Fitur yang benar-benar berjalan vs yang baru ditulis tetapi belum dapat diverifikasi.
- Daftar command yang benar-benar dijalankan beserta hasil.
- Test lulus/gagal/tidak bisa dijalankan.
- Setup manual yang masih dibutuhkan.
- Risiko tersisa atau acceptance criteria yang belum terpenuhi.

BERHENTI setelah audit dan perbaikan Fase 7. Jangan menambahkan fitur baru setelah quality gate.
```

---

## J. Prompt perbaikan bila satu fase gagal

Gunakan ini, jangan mengulang seluruh prompt awal:

```text
Perbaiki hanya kegagalan yang ditemukan pada fase terakhir. Baca laporan fase, `IMPLEMENTATION_PLAN.md`, dan output error yang ada. Reproduksi masalah jika bisa, cari penyebab dasarnya, lalu buat perubahan sekecil mungkin. Jangan refactor fitur lain atau memulai fase berikutnya. Jalankan kembali command/test yang gagal dan laporkan sebelum/sesudah secara akurat. Jika kegagalan disebabkan konfigurasi eksternal, jangan membuat fake config; jelaskan langkah manual yang dibutuhkan. Berhenti setelah masalah pada fase ini terselesaikan atau blocker teridentifikasi.
```

---

## K. Checklist setelah Cline menyelesaikan setiap fase

Jangan hanya melihat apakah layar sudah muncul. Pastikan:

- [ ] Cline mengerjakan fase yang diminta saja.
- [ ] Tidak ada file/fungsi penting yang dihapus tanpa alasan.
- [ ] `flutter analyze` sudah dijalankan dan error ditangani.
- [ ] Test relevan sudah dijalankan, atau alasan tidak bisa dijalankan dijelaskan.
- [ ] Fitur terhubung ke repository/backend yang tepat; bukan hanya data statis.
- [ ] Tidak ada tombol palsu, fake success, atau data dummy yang menyamar sebagai data riil.
- [ ] Security Rules dan akses admin tidak hanya mengandalkan tampilan UI.
- [ ] `IMPLEMENTATION_PLAN.md` sesuai kenyataan.
- [ ] Perubahan di-review; jika sudah baik, buat commit Git/checkpoint sebelum lanjut.

### Urutan praktis

`Prompt 0 → review plan → Prompt Fase 1 → review + checkpoint → Fase 2 → review + checkpoint → Fase 3 → Fase 4 → Fase 5 → Fase 6 → Fase 7`

Kalau suatu fase gagal, jalankan **Prompt Perbaikan**, jangan langsung maju ke fase berikutnya.

## Keputusan yang tetap harus kamu isi sendiri

- Nama aplikasi/brand.
- Nomor WhatsApp dalam format internasional tanpa tanda `+`.
- Unit harga sewa: per hari, per sesi, atau periode lain.
- Harga final, deskripsi dan deliverables tiap jasa.
- Foto banner/alat/profil kreator.
- Nama, spesialisasi, dan link portofolio dua kreator.
- Firebase project, provider login yang diaktifkan, konfigurasi platform, serta akun admin yang dikontrol pemilik project.
