import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rent_camera_app/core/errors/app_exception.dart';
import 'package:rent_camera_app/core/errors/auth_error_mapper.dart';

/// Turunan dipakai karena konstruktor `FirebaseAuthException` bersifat
/// `@protected` (hanya dapat dipakai oleh subclass).
class _StubAuthException extends FirebaseAuthException {
  _StubAuthException(String code) : super(code: code);
}

void main() {
  group('authErrorMessageForCode', () {
    test(
      'menyamakan kode credential yang salah tanpa membocorkan mana yang salah',
      () {
        const expected = 'Email atau kata sandi salah.';
        expect(authErrorMessageForCode('user-not-found'), expected);
        expect(authErrorMessageForCode('wrong-password'), expected);
        expect(authErrorMessageForCode('invalid-credential'), expected);
      },
    );

    test('memetakan kode yang sering muncul', () {
      expect(
        authErrorMessageForCode('email-already-in-use'),
        contains('sudah terdaftar'),
      );
      expect(
        authErrorMessageForCode('invalid-email'),
        'Format email tidak valid.',
      );
      expect(authErrorMessageForCode('weak-password'), contains('8 karakter'));
      expect(
        authErrorMessageForCode('operation-not-allowed'),
        contains('belum diaktifkan'),
      );
      expect(
        authErrorMessageForCode('too-many-requests'),
        contains('Coba lagi'),
      );
      expect(
        authErrorMessageForCode('network-request-failed'),
        contains('Koneksi'),
      );
    });

    test('memberi pesan generik untuk kode yang tidak dikenal', () {
      final message = authErrorMessageForCode('kode-tidak-dikenal');
      expect(message, isNotEmpty);
      expect(message, isNot(contains('kode-tidak-dikenal')));
    });
  });

  group('authErrorMessageFor', () {
    test('mengembalikan pesan AppException apa adanya', () {
      expect(
        authErrorMessageFor(
          const AppException('Alias admin belum dikonfigurasi.'),
        ),
        'Alias admin belum dikonfigurasi.',
      );
    });

    test(
      'tidak menampilkan apa pun saat pengguna membatalkan Google Sign-In',
      () {
        expect(
          authErrorMessageFor(
            const GoogleSignInException(
              code: GoogleSignInExceptionCode.canceled,
            ),
          ),
          isNull,
        );
      },
    );

    test('menjelaskan masalah konfigurasi Google Sign-In', () {
      final message = authErrorMessageFor(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      );
      expect(message, contains('Konfigurasi Google Sign-In'));
    });

    test('tidak mengembalikan detail error mentah', () {
      final message = authErrorMessageFor(
        Exception('PlatformException(detail internal)'),
      );
      expect(message, 'Terjadi kesalahan yang tidak terduga. Coba lagi.');
      expect(message, isNot(contains('PlatformException')));
    });
  });

  group('authErrorMessageForPasswordReset', () {
    test('menyembunyikan apakah email terdaftar', () {
      expect(
        authErrorMessageForPasswordReset(_StubAuthException('user-not-found')),
        isNull,
      );
    });

    test('tetap memberi pesan untuk error yang perlu diketahui pengguna', () {
      expect(
        authErrorMessageForPasswordReset(
          _StubAuthException('too-many-requests'),
        ),
        contains('Coba lagi'),
      );
      expect(
        authErrorMessageForPasswordReset(
          const AppException('Email wajib diisi.'),
        ),
        'Email wajib diisi.',
      );
    });
  });

  group('authErrorMessageFor â€” FirebaseAuthException', () {
    test('memetakan kode dari exception Firebase Auth', () {
      expect(
        authErrorMessageFor(_StubAuthException('email-already-in-use')),
        contains('sudah terdaftar'),
      );
    });
  });

  group('firestoreErrorMessageFor', () {
    test('menjelaskan penolakan Security Rules tanpa detail internal', () {
      final message = firestoreErrorMessageFor(Exception('permission-denied'));
      expect(message, contains('Gagal mengakses database'));
    });
  });
}
