import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/features/admin/domain/admin_access.dart';
import 'package:rent_camera_app/features/admin/presentation/admin_access_notifier.dart';

/// Test pelacak status akses admin.
///
/// Pembacaan claim disuntikkan, sehingga keputusan izin dapat diuji tanpa
/// kredensial Firebase. Semua kegagalan harus berakhir sebagai akses ditolak.
void main() {
  test(
    'tanpa sesi login statusnya denied tanpa memanggil pembaca claim',
    () async {
      var readCount = 0;
      final notifier = AdminAccessNotifier(
        readClaims: () async {
          readCount += 1;
          return <String, dynamic>{'admin': true};
        },
      );
      addTearDown(notifier.dispose);

      await notifier.onSessionChanged(isSignedIn: false);

      expect(notifier.status, AdminAccessStatus.denied);
      expect(notifier.isGranted, isFalse);
      expect(readCount, 0);
    },
  );

  test(
    'pembaca claim null (Firebase belum dikonfigurasi) menolak akses',
    () async {
      final notifier = AdminAccessNotifier(readClaims: null);
      addTearDown(notifier.dispose);

      await notifier.onSessionChanged(isSignedIn: true);

      expect(notifier.status, AdminAccessStatus.denied);
    },
  );

  test('claim admin true menghasilkan granted', () async {
    final notifier = AdminAccessNotifier(
      readClaims: () async => <String, dynamic>{'admin': true},
    );
    addTearDown(notifier.dispose);

    await notifier.onSessionChanged(isSignedIn: true);

    expect(notifier.status, AdminAccessStatus.granted);
    expect(notifier.isGranted, isTrue);
  });

  test('status menjadi unknown selama pembacaan berlangsung', () async {
    final completer = Completer<Map<String, dynamic>?>();
    final notifier = AdminAccessNotifier(readClaims: () => completer.future);
    addTearDown(notifier.dispose);

    final pending = notifier.onSessionChanged(isSignedIn: true);
    expect(notifier.status, AdminAccessStatus.unknown);

    completer.complete(<String, dynamic>{'admin': true});
    await pending;
    expect(notifier.status, AdminAccessStatus.granted);
  });

  test('kegagalan pembacaan token diperlakukan sebagai denied', () async {
    final notifier = AdminAccessNotifier(
      readClaims: () async => throw StateError('token tidak dapat dibaca'),
    );
    addTearDown(notifier.dispose);

    await notifier.onSessionChanged(isSignedIn: true);

    expect(notifier.status, AdminAccessStatus.denied);
  });

  test('hasil pembacaan lama tidak menimpa hasil terbaru', () async {
    final slow = Completer<Map<String, dynamic>?>();
    var callCount = 0;
    final notifier = AdminAccessNotifier(
      readClaims: () {
        callCount += 1;
        if (callCount == 1) {
          return slow.future;
        }
        return Future<Map<String, dynamic>?>.value(<String, dynamic>{});
      },
    );
    addTearDown(notifier.dispose);

    final first = notifier.onSessionChanged(isSignedIn: true);
    await notifier.refresh();
    expect(notifier.status, AdminAccessStatus.denied);

    // Hasil pembacaan pertama (granted) datang terlambat: harus diabaikan.
    slow.complete(<String, dynamic>{'admin': true});
    await first;

    expect(notifier.status, AdminAccessStatus.denied);
  });

  test('keluar dari akun mengubah status menjadi denied', () async {
    var isAdmin = true;
    final notifier = AdminAccessNotifier(
      readClaims: () async =>
          isAdmin ? <String, dynamic>{'admin': true} : <String, dynamic>{},
    );
    addTearDown(notifier.dispose);

    await notifier.onSessionChanged(isSignedIn: true);
    expect(notifier.status, AdminAccessStatus.granted);

    isAdmin = false;
    await notifier.refresh();
    expect(notifier.status, AdminAccessStatus.denied);
  });
}
