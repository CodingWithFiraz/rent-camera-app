/// Validator form yang dipakai bersama layar autentikasi.
///
/// Fungsi di sini murni (tanpa Firebase) sehingga dapat diuji tanpa kredensial.
/// Semua pesan berbahasa Indonesia dan tidak menampilkan detail internal.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Karakter yang boleh muncul pada nomor telepon profil.
  static final RegExp _phonePattern = RegExp(r'^[0-9+()\s-]+$');

  /// Panjang minimum kata sandi yang diminta aplikasi.
  static const int minPasswordLength = 8;

  /// Panjang digit nomor telepon yang diterima (tanpa spasi/tanda baca).
  static const int minPhoneDigits = 8;
  static const int maxPhoneDigits = 15;

  /// Validasi nama pengguna pada register/profil.
  static String? displayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Nama wajib diisi.';
    }
    if (text.length < 3) {
      return 'Nama minimal 3 karakter.';
    }
    return null;
  }

  /// Validasi alamat email.
  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Email wajib diisi.';
    }
    if (!_emailPattern.hasMatch(text)) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  /// Validasi field identitas pada layar login.
  ///
  /// Menerima email, atau [adminAlias] **hanya bila** alias admin sudah
  /// dikonfigurasi ([isAdminAliasConfigured]). Alias tidak melewati
  /// autentikasi: password tetap divalidasi Firebase Auth.
  static String? loginIdentifier(
    String? value, {
    String adminAlias = '',
    bool isAdminAliasConfigured = false,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Email wajib diisi.';
    }
    if (_emailPattern.hasMatch(text)) {
      return null;
    }
    if (isAdminAliasConfigured &&
        adminAlias.trim().isNotEmpty &&
        text.toLowerCase() == adminAlias.trim().toLowerCase()) {
      return null;
    }
    return 'Masukkan alamat email yang valid.';
  }

  /// Validasi kata sandi.
  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Kata sandi wajib diisi.';
    }
    if (text.length < minPasswordLength) {
      return 'Kata sandi minimal $minPasswordLength karakter.';
    }
    return null;
  }

  /// Validasi ulangi kata sandi pada register.
  static String? passwordConfirmation(String? value, String password) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi.';
    }
    if (text != password) {
      return 'Konfirmasi kata sandi tidak sama.';
    }
    return null;
  }

  /// Validasi nomor telepon pada layar edit profil.
  ///
  /// Nomor bersifat opsional (blueprint §6.3: hanya nama/telepon/foto yang boleh
  /// diubah): kosong berarti pengguna belum mengisi, bukan kesalahan. Bila
  /// diisi, jumlah digit dibatasi supaya salah ketik ketahuan sebelum disimpan.
  static String? phoneNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (!_phonePattern.hasMatch(text)) {
      return 'Nomor telepon hanya boleh berisi angka, spasi, tanda +, -, atau kurung.';
    }
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < minPhoneDigits || digits.length > maxPhoneDigits) {
      return 'Nomor telepon harus $minPhoneDigits–$maxPhoneDigits digit.';
    }
    return null;
  }
}
