# Aturan Proyek: Workflow, Keamanan, dan Kualitas

## Workflow wajib
- Satu task Cline = satu fase atau satu sasaran yang jelas. **Jangan otomatis mengerjakan semua fase dalam satu task.**
- Sebelum mengedit, periksa file yang terkait dan `git status`. Jangan menimpa pekerjaan yang ada tanpa alasan.
- Kerjakan hanya fase yang diminta. Perbaiki bug yang ditemukan jika menghambat fase ini; catat issue di luar cakupan untuk fase yang sesuai.
- Setelah implementasi fase: jalankan `dart format` pada file yang berubah (atau `dart format .` jika aman), `flutter analyze`, dan test relevan. Jangan klaim perintah lulus jika tidak dijalankan.
- Jika test/build terhalang konfigurasi eksternal, tulis secara spesifik konfigurasi apa yang hilang, bukti/command yang dijalankan, dan langkah manual untuk menyelesaikannya.
- Perbarui `IMPLEMENTATION_PLAN.md` hanya dengan status yang benar. Jangan menandai fitur complete bila baru berupa UI/mock.
- Akhiri task setelah fase selesai. Jangan lanjut ke fase berikutnya pada task yang sama. Keluarkan ringkasan: file berubah, fitur yang benar-benar bekerja, command/test + hasil, blocker, dan nama fase selanjutnya.

## Keamanan autentikasi/admin
- Jangan hardcode password admin `pass`, kredensial, service-account JSON, private key, atau secret.
- Login admin harus memakai Firebase Auth dan role tepercaya berupa custom claim `{admin: true}`. Alias username `admin` boleh dipetakan ke email admin yang dikonfigurasi, bukan bypass autentikasi.
- Skrip Firebase Admin SDK hanya untuk lingkungan tepercaya dan tidak boleh digunakan dari aplikasi Flutter.
- Route guard UI bukan pengamanan backend. Firestore Rules dan Storage Rules wajib membatasi akses.
- Jangan pernah memakai Security Rules terbuka seperti `allow read, write: if true`.
- Profile user tidak boleh mengubah role/claim. Cart dibatasi UID pemilik. Validasi tipe field, angka, file gambar, dan ukuran upload.
- Jika Firebase belum dikonfigurasi, jangan membuat file konfigurasi palsu atau klaim bahwa autentikasi telah berjalan.

## Kejujuran implementasi
- Jangan membuat fake payment, fake booking, dummy analytics, fake success, atau tombol yang tidak melakukan aksi.
- Jangan mengarang nomor WhatsApp, harga final, portofolio, foto, pengalaman kreator, kredensial, maupun hasil test.
- Sample/seed harus ditandai sample dan mudah diganti. Jika data produksi belum ada, tampilkan empty/configuration state.
- Jangan menampilkan token, kredensial, data sensitif, atau detail error internal kepada pengguna.
- Periksa state loading/error/empty, aksesibilitas, keyboard, safe area, ukuran layar kecil, dan teks panjang.
- Sebelum task berakhir, periksa `git diff --check` dan `git status --short` bila Git tersedia.
