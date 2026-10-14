import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/app_exception.dart';
import 'package:rent_camera_app/core/errors/storage_error_mapper.dart';

FirebaseException _storageError(String code, [String? message]) =>
    FirebaseException(plugin: 'firebase_storage', code: code, message: message);

void main() {
  test('AppException dari lapisan Storage dipakai apa adanya', () {
    expect(
      mapStorageError(
        const AppException('Format foto tidak didukung.'),
        entityLabel: 'foto profil',
      ).message,
      'Format foto tidak didukung.',
    );
  });

  test('pengguna diberi tahu bahwa Storage Rules yang menolak', () {
    final message = mapStorageError(
      _storageError('unauthorized', 'User does not have permission'),
      entityLabel: 'foto profil',
    ).message;

    expect(message, contains('Storage Rules'));
    expect(message, isNot(contains('User does not have permission')));
  });

  test('kuota penyimpanan penuh dijelaskan tanpa detail internal', () {
    final message = storageErrorMessageFor(_storageError('quota-exceeded'));

    expect(message, contains('penuh'));
    expect(message, contains('admin'));
  });

  test('masalah koneksi tidak dilaporkan sebagai kegagalan izin', () {
    final message = storageErrorMessageFor(
      _storageError('retry-limit-exceeded'),
    );

    expect(message, contains('Koneksi'));
    expect(message, isNot(contains('Storage Rules')));
  });

  test('kode yang tidak dikenal memakai pesan umum siap tampil', () {
    expect(
      storageErrorMessageFor(_storageError('kode-baru', 'stack mentah')),
      'Gagal mengunggah foto. Coba lagi.',
    );
  });

  test('error non-Firebase menyebut entitas unggahan yang gagal', () {
    expect(
      mapStorageError(StateError('boom'), entityLabel: 'foto profil').message,
      'Gagal mengunggah foto profil. Coba lagi.',
    );
  });
}
