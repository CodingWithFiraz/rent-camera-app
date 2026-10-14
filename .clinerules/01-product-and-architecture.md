# Aturan Proyek: Produk dan Arsitektur

## Sumber kebenaran
- Spesifikasi produk utama berada di `docs/BLUEPRINT_APLIKASI.md`.
- Baca bagian yang relevan sebelum mengubah kode.
- Jika spesifikasi, implementasi lama, dan prompt bertentangan, jangan menebak diam-diam. Pertahankan perilaku yang benar, laporkan konflik, dan prioritaskan keamanan.
- Aplikasi adalah Flutter/Dart mobile untuk penyewaan alat fotografi/videografi dan portofolio jasa. Firebase adalah backend terkelola.

## Stack dan struktur
- Flutter stable, Dart null safety, Material 3.
- Riverpod untuk state/dependency injection; `go_router` untuk routing/guard.
- Firebase Auth, Cloud Firestore, Firebase Storage. `google_sign_in` untuk Google auth native; `image_picker`, `url_launcher`, `cached_network_image`, dan `intl` bila cocok.
- Verifikasi API paket dari versi yang benar-benar ada dalam `pubspec.lock`; jangan mengasumsikan API lama/baru.
- Gunakan feature-first structure: `core/`, `features/auth`, `catalog`, `cart`, `portfolio`, `profile`, `admin`.
- Widget tidak boleh menyimpan query Firebase tersebar di UI. Gunakan repository sebagai pintu akses Firebase, model Dart yang eksplisit, dan provider untuk state.
- Hindari overengineering dan file raksasa; pisahkan screen, widget, model, repository, provider, utilitas, dan test secukupnya.

## Perilaku inti
- Setelah autentikasi sukses, pengguna masuk ke katalog.
- Katalog berisi tiga banner; satu banner membuka portofolio. Search, filter kategori, dan filter brand dapat digabungkan.
- Produk hanya tampil di katalog jika aktif. Perubahan produk admin harus tercermin melalui stream/listener Firestore realtime.
- Keranjang milik UID, satu dokumen per productId. Quantity harus integer positif dan tidak melebihi stok terverifikasi.
- Checkout hanya menyusun permintaan sewa melalui WhatsApp; bukan booking final, bukan pembayaran, dan bukan penguncian stok. Baca ulang harga/status/stok dari Firestore sebelum menyusun pesan.
- Harga disimpan sebagai integer Rupiah dan periode harga harus eksplisit. Jangan mengarang “per hari” jika belum diatur.
- Halaman jasa menampilkan empat kategori layanan dan dua kartu kreator dari data terkonfigurasi, bukan data palsu yang tampak nyata.
- Profil dapat mengubah nama, nomor telepon, foto; role tidak dapat diedit oleh pengguna.

## Desain
- Arah visual: editorial gear-rental; fokus pada fotografi produk dan informasi yang bisa dipindai.
- Palet awal di spesifikasi adalah token awal; pusatkan warna, spacing, radius, dan typography di Theme/design tokens.
- Hindari template dashboard generik, gradient/glassmorphism/glow, shadow tebal, emoji sebagai ikon UI, card berlapis tanpa alasan, dan animasi dekoratif.
- Semua screen perlu loading, error, empty, disabled, serta submission state yang masuk akal.
- Tidak boleh ada tombol dekoratif yang tidak bekerja. Hindari gambar random; gunakan aset pemilik atau placeholder yang jelas.
