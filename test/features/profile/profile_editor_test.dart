import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/app_exception.dart';
import 'package:rent_camera_app/features/profile/data/profile_image_picker.dart';
import 'package:rent_camera_app/features/profile/data/profile_photo_storage.dart';
import 'package:rent_camera_app/features/profile/data/user_profile_repository.dart';
import 'package:rent_camera_app/features/profile/domain/user_profile.dart';
import 'package:rent_camera_app/features/profile/presentation/profile_editor.dart';
import 'package:rent_camera_app/features/profile/presentation/profile_providers.dart';

const String _uid = 'uid-uji-123';
const String _oldPhotoUrl = 'https://contoh.test/foto-lama.jpg';
const String _newPhotoUrl = 'https://contoh.test/foto-baru.jpg';

PickedProfileImage _picked({
  String fileName = 'foto-profil.jpg',
  int sizeBytes = 2048,
  String? mimeType,
}) => PickedProfileImage(
  bytes: Uint8List(sizeBytes),
  fileName: fileName,
  mimeType: mimeType,
);

/// Pemilih foto palsu: tidak memanggil platform channel `image_picker`.
class _FakePicker implements ProfileImagePicker {
  PickedProfileImage? picked;
  Object? failure;
  int calls = 0;

  @override
  Future<PickedProfileImage?> pickFromGallery() async {
    calls += 1;
    final Object? error = failure;
    if (error != null) {
      throw error;
    }
    return picked;
  }
}

/// Penyimpanan palsu: mencatat unggahan tanpa menyentuh Firebase Storage.
class _FakeStorage implements ProfilePhotoStorage {
  Object? uploadFailure;

  final List<String> uploads = <String>[];
  final List<String> deletedPaths = <String>[];
  final List<String> deletedUrls = <String>[];

  @override
  Future<UploadedProfilePhoto> upload({
    required String uid,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploads.add('$uid|$contentType|${bytes.length}');
    final Object? error = uploadFailure;
    if (error != null) {
      throw error;
    }
    return UploadedProfilePhoto(
      downloadUrl: _newPhotoUrl,
      storagePath: 'profiles/$uid/photo-baru.jpg',
    );
  }

  @override
  Future<void> deletePath(String storagePath) async =>
      deletedPaths.add(storagePath);

  @override
  Future<void> deleteByUrl(String downloadUrl) async =>
      deletedUrls.add(downloadUrl);
}

/// Pengganti [UserProfileRepository] yang mencatat penulisan tanpa Firestore.
class _FakeRepository implements UserProfileRepository {
  Object? failure;
  final List<String> writes = <String>[];

  @override
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String phoneNumber,
    String? photoUrl,
  }) async {
    writes.add('$uid|$displayName|$phoneNumber|${photoUrl ?? '-'}');
    final Object? error = failure;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<UserProfile?> fetchProfile(String uid) async => null;

  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      Stream<UserProfile?>.value(null);

  @override
  Future<void> ensureProfileDocument({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {}
}

class _Harness {
  _Harness({
    required this.container,
    required this.picker,
    required this.storage,
    required this.repository,
  });

  final ProviderContainer container;
  final _FakePicker picker;
  final _FakeStorage storage;
  final _FakeRepository repository;

  ProfileEditorState get state => container.read(profileEditorProvider);

  ProfileEditor get editor => container.read(profileEditorProvider.notifier);
}

/// Menyiapkan editor dengan pemilih, penyimpanan, dan repository palsu.
_Harness _createHarness() {
  final picker = _FakePicker();
  final storage = _FakeStorage();
  final repository = _FakeRepository();
  final container = ProviderContainer(
    overrides: <Override>[
      profileImagePickerProvider.overrideWithValue(picker),
      profilePhotoStorageProvider.overrideWithValue(storage),
      userProfileRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return _Harness(
    container: container,
    picker: picker,
    storage: storage,
    repository: repository,
  );
}

void main() {
  group('ProfileEditor.pickPhoto', () {
    test(
      'foto yang valid disimpan sebagai pratinjau, belum diunggah',
      () async {
        final harness = _createHarness();
        harness.picker.picked = _picked();

        await harness.editor.pickPhoto();

        expect(harness.state.pickedImage, isNotNull);
        expect(harness.state.pickedImage!.contentType, 'image/jpeg');
        expect(harness.state.errorMessage, isNull);
        expect(harness.storage.uploads, isEmpty);
      },
    );

    test('berkas yang terlalu besar ditolak sebelum diunggah', () async {
      final harness = _createHarness();
      harness.picker.picked = _picked(sizeBytes: 6 * 1024 * 1024);

      await harness.editor.pickPhoto();

      expect(harness.state.pickedImage, isNull);
      expect(harness.state.errorMessage, contains('melebihi batas'));
      expect(harness.storage.uploads, isEmpty);
    });

    test('berkas bukan gambar ditolak dengan penjelasan format', () async {
      final harness = _createHarness();
      harness.picker.picked = _picked(fileName: 'dokumen.pdf');

      await harness.editor.pickPhoto();

      expect(harness.state.pickedImage, isNull);
      expect(
        harness.state.errorMessage,
        'Format foto harus JPG, PNG, atau WEBP.',
      );
    });

    test(
      'kegagalan pemilih berkas tidak menampilkan detail internal',
      () async {
        final harness = _createHarness();
        harness.picker.failure = StateError('platform channel gagal');

        await harness.editor.pickPhoto();

        expect(harness.state.pickedImage, isNull);
        expect(
          harness.state.errorMessage,
          'Foto tidak dapat dipilih dari galeri. Coba lagi.',
        );
      },
    );

    test(
      'pembatalan mempertahankan pilihan sebelumnya tanpa pesan error',
      () async {
        final harness = _createHarness();
        harness.picker.picked = _picked();
        await harness.editor.pickPhoto();

        harness.picker.picked = null;
        await harness.editor.pickPhoto();

        expect(harness.state.pickedImage, isNotNull);
        expect(harness.state.errorMessage, isNull);
      },
    );

    test('pilihan foto dapat dibatalkan sebelum disimpan', () async {
      final harness = _createHarness();
      harness.picker.picked = _picked();
      await harness.editor.pickPhoto();

      harness.editor.clearPickedPhoto();

      expect(harness.state.pickedImage, isNull);
      expect(harness.storage.uploads, isEmpty);
    });
  });

  group('ProfileEditor.save', () {
    test('menyimpan nama dan nomor tanpa menyentuh foto lama', () async {
      final harness = _createHarness();
      // Nomor uji disusun dari potongan digit supaya tidak ada nomor nyata yang
      // tertulis harfiah di dalam test.
      final String phoneDigits = <String>['08', '12', '345', '678'].join();

      final saved = await harness.editor.save(
        uid: _uid,
        displayName: '  Nama Baru  ',
        phoneNumber: ' $phoneDigits ',
        previousPhotoUrl: _oldPhotoUrl,
      );

      expect(saved, isTrue);
      expect(harness.repository.writes, <String>[
        '$_uid|  Nama Baru  | $phoneDigits |-',
      ]);
      expect(harness.storage.uploads, isEmpty);
      expect(harness.storage.deletedUrls, isEmpty);
      expect(harness.state.noticeMessage, 'Profil berhasil disimpan.');
      expect(harness.state.errorMessage, isNull);
    });

    test('foto baru diunggah lebih dulu, lalu URL disimpan', () async {
      final harness = _createHarness();
      harness.picker.picked = _picked();
      await harness.editor.pickPhoto();

      final saved = await harness.editor.save(
        uid: _uid,
        displayName: 'Nama Baru',
        phoneNumber: '',
        previousPhotoUrl: _oldPhotoUrl,
      );

      expect(saved, isTrue);
      expect(harness.storage.uploads, <String>['$_uid|image/jpeg|2048']);
      expect(harness.repository.writes, <String>[
        '$_uid|Nama Baru||$_newPhotoUrl',
      ]);
      expect(harness.storage.deletedUrls, <String>[_oldPhotoUrl]);
    });

    test('unggahan gagal tidak menyentuh dokumen profil', () async {
      final harness = _createHarness();
      harness.picker.picked = _picked();
      await harness.editor.pickPhoto();
      harness.storage.uploadFailure = const AppException(
        'Akses unggah foto ditolak. Storage Rules belum mengizinkan akun ini '
        'menyimpan foto.',
      );

      final saved = await harness.editor.save(
        uid: _uid,
        displayName: 'Nama Baru',
        phoneNumber: '',
        previousPhotoUrl: _oldPhotoUrl,
      );

      expect(saved, isFalse);
      expect(harness.repository.writes, isEmpty);
      expect(harness.storage.deletedUrls, isEmpty);
      expect(
        harness.state.errorMessage,
        'Akses unggah foto ditolak. Storage Rules belum mengizinkan akun ini '
        'menyimpan foto.',
      );
      expect(harness.state.noticeMessage, isNull);
    });

    test(
      'penulisan profil gagal setelah unggah: berkas baru dibersihkan',
      () async {
        final harness = _createHarness();
        harness.picker.picked = _picked();
        await harness.editor.pickPhoto();
        harness.repository.failure = const AppException(
          'Akses ditolak. Firestore Security Rules belum mengizinkan operasi ini.',
        );

        final saved = await harness.editor.save(
          uid: _uid,
          displayName: 'Nama Baru',
          phoneNumber: '',
          previousPhotoUrl: _oldPhotoUrl,
        );

        expect(saved, isFalse);
        expect(harness.storage.deletedPaths, <String>[
          'profiles/$_uid/photo-baru.jpg',
        ]);
        // Foto lama di dokumen tidak pernah dihapus karena penyimpanan gagal.
        expect(harness.storage.deletedUrls, isEmpty);
        expect(
          harness.state.errorMessage,
          'Akses ditolak. Firestore Security Rules belum mengizinkan operasi ini.',
        );
        // Pilihan foto tetap ada supaya pengguna dapat mencoba menyimpan lagi.
        expect(harness.state.pickedImage, isNotNull);
      },
    );
  });
}
