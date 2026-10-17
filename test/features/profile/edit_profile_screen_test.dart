import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_camera_app/core/theme/app_theme.dart';
import 'package:rent_camera_app/features/auth/domain/auth_user.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_providers.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_session_notifier.dart';
import 'package:rent_camera_app/features/profile/domain/user_profile.dart';
import 'package:rent_camera_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:rent_camera_app/features/profile/presentation/profile_editor.dart';
import 'package:rent_camera_app/features/profile/presentation/profile_providers.dart';

/// Alamat email uji dibentuk dari potongan string supaya tidak ditulis sebagai
/// satu literal utuh (mengikuti `test/core/utils/validators_test.dart`).
final String _accountEmail = ['pengguna', 'contoh.test'].join('@');

const String _oldPhotoUrl = 'https://contoh.test/foto-lama.jpg';

/// Pengganti [ProfileEditor]: mencatat penyimpanan tanpa Firestore/Storage.
///
/// Logika unggah dan validasi berkas diuji terpisah pada
/// `test/features/profile/profile_editor_test.dart`; test ini fokus pada
/// perilaku layar (prefill, validasi form, pesan error, dan navigasi).
class _FakeProfileEditor extends ProfileEditor {
  bool saveSucceeds = true;
  String failureMessage = 'Akses ditolak untuk profil.';
  final List<String> saves = <String>[];
  int pickCalls = 0;

  @override
  ProfileEditorState build() => const ProfileEditorState();

  @override
  Future<void> pickPhoto() async => pickCalls += 1;

  @override
  void clearPickedPhoto() {}

  @override
  Future<bool> save({
    required String uid,
    required String displayName,
    required String phoneNumber,
    String? photoUrl,
    String? previousPhotoUrl,
  }) async {
    final photo = (photoUrl != null && photoUrl.isNotEmpty)
        ? photoUrl
        : (previousPhotoUrl ?? '-');
    saves.add('$uid|$displayName|$phoneNumber|$photo');
    if (!saveSucceeds) {
      state = ProfileEditorState(errorMessage: failureMessage);
      return false;
    }
    state = const ProfileEditorState(
      noticeMessage: 'Profil berhasil disimpan.',
    );
    return true;
  }
}

/// Menampilkan layar edit profil dengan editor palsu dan router uji.
///
/// Router dipakai supaya perilaku "layar hanya ditutup saat berhasil" dapat
/// diuji: halaman tujuan `/profile` hanyalah penanda teks.
Future<_FakeProfileEditor> _pumpEditProfile(
  WidgetTester tester, {
  required UserProfile? profile,
}) async {
  tester.view.physicalSize = const Size(420, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = StreamController<AuthUser?>();
  addTearDown(controller.close);
  final session = AuthSessionNotifier(authStateChanges: controller.stream);
  addTearDown(session.dispose);
  controller.add(
    AuthUser(uid: 'uid-1', displayName: 'Nama Akun', email: _accountEmail),
  );

  final editor = _FakeProfileEditor();
  final router = GoRouter(
    initialLocation: '/profile/edit',
    routes: <RouteBase>[
      GoRoute(
        path: '/profile/edit',
        builder: (BuildContext context, GoRouterState state) =>
            const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Center(child: Text('halaman profil tujuan'))),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authSessionNotifierProvider.overrideWithValue(session),
        profileEditorProvider.overrideWith(() => editor),
        userProfileProvider.overrideWith(
          (Ref ref, String uid) => Stream<UserProfile?>.value(profile),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return editor;
}

/// Kolom teks berdasarkan label yang tampil.
Finder _fieldWithLabel(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

void main() {
  testWidgets('mengisi kolom dari dokumen dan email tidak dapat diubah', (
    WidgetTester tester,
  ) async {
    await _pumpEditProfile(
      tester,
      profile: const UserProfile(
        uid: 'uid-1',
        displayName: 'Nama Tersimpan',
        phoneNumber: '(021) 1234567',
        photoUrl: _oldPhotoUrl,
      ),
    );

    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Nama Tersimpan'), findsOneWidget);
    expect(find.text('(021) 1234567'), findsOneWidget);
    expect(find.text(_accountEmail), findsOneWidget);
    expect(find.textContaining('tidak dapat diubah di sini'), findsOneWidget);

    final emailField = tester.widget<TextFormField>(
      _fieldWithLabel('Email akun'),
    );
    expect(emailField.enabled, isFalse);
    // Tidak ada field role/claim pada form ini.
    expect(find.text('Role'), findsNothing);
  });

  testWidgets('nama yang tidak valid ditolak sebelum disimpan', (
    WidgetTester tester,
  ) async {
    final editor = await _pumpEditProfile(
      tester,
      profile: const UserProfile(uid: 'uid-1', displayName: 'Nama Tersimpan'),
    );

    await tester.enterText(_fieldWithLabel('Nama'), 'ab');
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Nama minimal 3 karakter.'), findsOneWidget);
    expect(editor.saves, isEmpty);
    expect(find.text('halaman profil tujuan'), findsNothing);
  });

  testWidgets('penyimpanan berhasil menutup layar dan membawa foto lama', (
    WidgetTester tester,
  ) async {
    final String phoneDigits = <String>['08', '12', '345', '678'].join();
    final editor = await _pumpEditProfile(
      tester,
      profile: const UserProfile(
        uid: 'uid-1',
        displayName: 'Nama Tersimpan',
        photoUrl: _oldPhotoUrl,
      ),
    );

    await tester.enterText(_fieldWithLabel('Nama'), 'Nama Baru');
    await tester.enterText(_fieldWithLabel('Nomor telepon'), phoneDigits);
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(editor.saves, <String>[
      'uid-1|Nama Baru|$phoneDigits|$_oldPhotoUrl',
    ]);
    expect(find.text('halaman profil tujuan'), findsOneWidget);
    expect(find.textContaining('Profil berhasil disimpan.'), findsOneWidget);
  });

  testWidgets('penyimpanan gagal ditampilkan dan layar tidak ditutup', (
    WidgetTester tester,
  ) async {
    final editor = await _pumpEditProfile(
      tester,
      profile: const UserProfile(uid: 'uid-1', displayName: 'Nama Tersimpan'),
    );
    editor.saveSucceeds = false;
    editor.failureMessage = 'Akses ditolak. Firestore Security Rules belum mengizinkan operasi ini.';

    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(editor.saves, hasLength(1));
    expect(find.text(editor.failureMessage), findsOneWidget);
    expect(find.text('halaman profil tujuan'), findsNothing);
    expect(find.text('Simpan perubahan'), findsOneWidget);
  });

  testWidgets('kolom URL foto profil dapat diisi dan disimpan', (
    WidgetTester tester,
  ) async {
    final editor = await _pumpEditProfile(
      tester,
      profile: const UserProfile(uid: 'uid-1', displayName: 'Nama Tersimpan'),
    );

    expect(find.text('URL Foto Profil'), findsOneWidget);
    await tester.enterText(
      _fieldWithLabel('URL Foto Profil'),
      'https://contoh.test/foto-online.jpg',
    );
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(editor.saves, <String>[
      'uid-1|Nama Tersimpan||https://contoh.test/foto-online.jpg',
    ]);
  });
}
