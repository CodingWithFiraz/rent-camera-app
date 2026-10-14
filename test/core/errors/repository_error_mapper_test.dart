import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/app_exception.dart';
import 'package:rent_camera_app/core/errors/firestore_data_exception.dart';
import 'package:rent_camera_app/core/errors/repository_error_mapper.dart';

void main() {
  test('AppException dipakai apa adanya', () {
    expect(
      repositoryErrorMessageFor(
        const AppException('Jumlah minimal 1.'),
        entityLabel: 'keranjang',
      ),
      'Jumlah minimal 1.',
    );
  });

  test('dokumen tidak sesuai format dijelaskan tanpa detail internal', () {
    final message = repositoryErrorMessageFor(
      const FirestoreDataException(
        documentPath: 'products/p1',
        field: 'price',
        reason: 'harus berupa bilangan bulat',
      ),
      entityLabel: 'produk',
    );

    expect(message, 'Data produk tidak sesuai format aplikasi. Hubungi admin.');
    expect(message, isNot(contains('price')));
    expect(message, isNot(contains('documentPath')));
  });

  test('Firebase yang belum siap dijelaskan sebagai keadaan aplikasi', () {
    final message = repositoryErrorMessageFor(
      StateError('Cloud Firestore belum tersedia'),
      entityLabel: 'produk',
    );

    expect(message, contains('Firebase'));
    expect(message, isNot(contains('StateError')));
    expect(message, isNot(contains('Cloud Firestore belum tersedia')));
  });

  test('error tanpa informasi menghasilkan pesan umum yang siap tampil', () {
    expect(
      repositoryErrorMessageFor(null, entityLabel: 'produk'),
      'Gagal memuat produk. Coba lagi.',
    );
  });

  test('kegagalan provider yang membungkus error dependensi tetap terbaca', () async {
    // Repository bergantung pada provider Firebase. Ketika provider itu gagal,
    // Riverpod membungkus error-nya sebelum sampai ke UI; pemetaan pesan harus
    // tetap menghasilkan kalimat yang aman, bukan tipe error internal.
    final firestore = Provider<int>((ref) => throw StateError('belum siap'));
    final stream = StreamProvider<int>(
      (ref) => Stream<int>.value(ref.watch(firestore)),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    AsyncValue<int>? latest;
    container.listen(
      stream,
      (AsyncValue<int>? previous, AsyncValue<int> next) => latest = next,
      fireImmediately: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(latest?.hasError, isTrue);
    expect(
      repositoryErrorMessageFor(latest?.error, entityLabel: 'produk'),
      contains('Firebase'),
    );
  });
}
