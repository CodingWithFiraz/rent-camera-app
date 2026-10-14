import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/app_exception.dart';
import 'package:rent_camera_app/core/theme/app_theme.dart';
import 'package:rent_camera_app/features/auth/domain/auth_user.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_providers.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_session_notifier.dart';
import 'package:rent_camera_app/features/cart/domain/cart_item.dart';
import 'package:rent_camera_app/features/cart/presentation/cart_providers.dart';
import 'package:rent_camera_app/features/profile/domain/user_profile.dart';
import 'package:rent_camera_app/features/profile/presentation/profile_providers.dart';
import 'package:rent_camera_app/features/profile/presentation/profile_screen.dart';

/// Alamat email uji dibentuk dari potongan string supaya tidak ditulis sebagai
/// satu literal utuh (mengikuti `test/core/utils/validators_test.dart`).
final String _accountEmail = ['pengguna', 'contoh.test'].join('@');

UserProfile _profile({
  String displayName = 'Nama dari Dokumen',
  String phoneNumber = '',
  String photoUrl = '',
}) => UserProfile(
  uid: 'uid-1',
  displayName: displayName,
  email: _accountEmail,
  phoneNumber: phoneNumber,
  photoUrl: photoUrl,
);

/// Stream profil yang langsung mengirim [data].
Stream<UserProfile?> _profileStream(UserProfile? data) =>
    Stream<UserProfile?>.value(data);

/// Stream yang tidak pernah mengirim nilai (keadaan memuat).
Stream<UserProfile?> _pendingProfileStream() =>
    Stream<UserProfile?>.fromFuture(Completer<UserProfile?>().future);

/// Menampilkan halaman profil dengan sesi dan stream profil dari test.
///
/// [createProfileStream] dipanggil setiap kali provider dibuat, bukan sekali:
/// `StreamProvider` dapat dibuat ulang saat nilai/error-nya berubah, dan stream
/// sekali-pakai yang sama akan gagal dilanggankan dua kali.
/// Tidak ada Firestore yang disentuh: stream profil dan keranjang (badge app
/// bar) diganti, sehingga hasilnya deterministik.
Future<void> _pumpProfile(
  WidgetTester tester, {
  required Stream<UserProfile?> Function() createProfileStream,
  bool signedIn = true,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(420, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = StreamController<AuthUser?>();
  addTearDown(controller.close);
  final session = AuthSessionNotifier(authStateChanges: controller.stream);
  addTearDown(session.dispose);
  if (signedIn) {
    controller.add(
      AuthUser(uid: 'uid-1', displayName: 'Nama Akun', email: _accountEmail),
    );
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authSessionNotifierProvider.overrideWithValue(session),
        cartItemsProvider.overrideWith(
          (Ref ref, String uid) =>
              Stream<List<CartItem>>.value(const <CartItem>[]),
        ),
        userProfileProvider.overrideWith(
          (Ref ref, String uid) => createProfileStream(),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const ProfileScreen()),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('menampilkan foto, nama, email akun, dan nomor telepon', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(
      tester,
      createProfileStream: () => _profileStream(
        _profile(displayName: 'Nama Tersimpan', phoneNumber: '(021) 1234567'),
      ),
    );

    expect(find.text('Nama Tersimpan'), findsOneWidget);
    expect(find.text(_accountEmail), findsOneWidget);
    expect(find.text('(021) 1234567'), findsOneWidget);
    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
    // Role tidak pernah ditampilkan atau dapat diubah dari halaman ini.
    expect(find.textContaining('role'), findsNothing);
  });

  testWidgets('profil tanpa dokumen memakai data akun dan menjelaskannya', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(tester, createProfileStream: () => _profileStream(null));

    expect(find.text('Nama Akun'), findsOneWidget);
    expect(find.text('Belum diisi'), findsOneWidget);
    expect(
      find.textContaining('Dokumen profil belum ada di database'),
      findsOneWidget,
    );
  });

  testWidgets('menampilkan state memuat sebelum profil tersedia', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(
      tester,
      createProfileStream: _pendingProfileStream,
      settle: false,
    );

    expect(find.text('Memuat profil…'), findsOneWidget);
  });

  testWidgets('kegagalan pemuatan dijelaskan dengan tombol coba lagi', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(
      tester,
      createProfileStream: () => Stream<UserProfile?>.error(
        const AppException('Akses ditolak untuk profil.'),
      ),
    );

    expect(find.text('Profil belum dapat dimuat'), findsOneWidget);
    expect(find.text('Akses ditolak untuk profil.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('tanpa sesi login halaman menawarkan untuk masuk', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(
      tester,
      createProfileStream: () => _profileStream(null),
      signedIn: false,
    );

    expect(find.text('Masuk untuk membuka profil'), findsOneWidget);
    expect(find.text('Edit Profil'), findsNothing);
  });
}
