import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/errors/firestore_data_exception.dart';
import 'package:rent_camera_app/features/profile/domain/user_profile.dart';

const String uid = 'uid-uji-123';

/// Alamat email uji dibentuk dari potongan string supaya tidak ditulis sebagai
/// satu literal utuh (mengikuti `test/core/utils/validators_test.dart`); isinya
/// bukan milik siapa pun.
final String sampleEmail = ['pengguna', 'contoh.test'].join('@');

/// Nomor telepon contoh yang jelas bukan nomor nyata.
const String samplePhone = '0800000000';

void main() {
  group('UserProfile.fromFirestore', () {
    test('memetakan dokumen lengkap', () {
      final profile = UserProfile.fromFirestore(uid, <String, dynamic>{
        'displayName': 'Nama Pengguna',
        'email': sampleEmail,
        'phoneNumber': samplePhone,
        'photoUrl': 'https://example.com/sample/foto-profil.jpg',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 2, 1)),
        // `updatedAt` sengaja memakai `DateTime` mentah: reader menerima
        // `Timestamp` maupun `DateTime` untuk data lama.
        'updatedAt': DateTime.utc(2026, 2, 2),
      });

      expect(profile.uid, uid);
      expect(profile.displayName, 'Nama Pengguna');
      expect(profile.email, sampleEmail);
      expect(profile.phoneNumber, samplePhone);
      expect(profile.photoUrl, 'https://example.com/sample/foto-profil.jpg');
      expect(profile.hasPhoto, isTrue);
      expect(profile.hasPhoneNumber, isTrue);
      expect(profile.preferredName, 'Nama Pengguna');
      // `Timestamp.toDate()` mengembalikan waktu lokal, jadi dibandingkan dalam UTC.
      expect(profile.createdAt?.toUtc(), DateTime.utc(2026, 2, 1));
      expect(profile.updatedAt?.toUtc(), DateTime.utc(2026, 2, 2));
    });

    test('memakai string kosong untuk field opsional yang hilang', () {
      final profile = UserProfile.fromFirestore(uid, <String, dynamic>{});

      expect(profile.displayName, '');
      expect(profile.email, '');
      expect(profile.phoneNumber, '');
      expect(profile.photoUrl, '');
      expect(profile.hasPhoto, isFalse);
      expect(profile.hasPhoneNumber, isFalse);
      expect(profile.createdAt, isNull);
      expect(profile.updatedAt, isNull);
      expect(profile.preferredName, uid);
    });

    test('preferredName jatuh ke email lalu UID', () {
      final denganEmail = UserProfile.fromFirestore(uid, <String, dynamic>{
        'displayName': '   ',
        'email': sampleEmail,
      });
      final tanpaKeduanya = UserProfile.fromFirestore(uid, <String, dynamic>{
        'displayName': '',
        'email': '',
      });

      expect(denganEmail.preferredName, sampleEmail);
      expect(tanpaKeduanya.preferredName, uid);
    });

    test('menolak field bertipe salah', () {
      for (final field in <String>[
        'displayName',
        'email',
        'phoneNumber',
        'photoUrl',
      ]) {
        expect(
          () => UserProfile.fromFirestore(uid, <String, dynamic>{field: 1}),
          throwsA(
            isA<FirestoreDataException>().having(
              (error) => error.field,
              'field',
              field,
            ),
          ),
          reason: 'field $field harus ditolak saat bertipe salah',
        );
      }

      expect(
        () => UserProfile.fromFirestore(uid, <String, dynamic>{
          'createdAt': 'kemarin',
        }),
        throwsA(isA<FirestoreDataException>()),
      );
    });
  });

  group('UserProfile.containsNonAuthoritativeRoleField', () {
    test('mendeteksi field role/claim yang tidak otoritatif', () {
      expect(
        UserProfile.containsNonAuthoritativeRoleField(<String, dynamic>{
          'role': 'admin',
        }),
        isTrue,
      );
      expect(
        UserProfile.containsNonAuthoritativeRoleField(<String, dynamic>{
          'admin': true,
        }),
        isTrue,
      );
      expect(
        UserProfile.containsNonAuthoritativeRoleField(<String, dynamic>{
          'isAdmin': true,
        }),
        isTrue,
      );
      expect(
        UserProfile.containsNonAuthoritativeRoleField(<String, dynamic>{
          'claims': <String, dynamic>{'admin': true},
        }),
        isTrue,
      );
    });

    test('dokumen profil biasa tidak dianggap memuat role', () {
      expect(
        UserProfile.containsNonAuthoritativeRoleField(<String, dynamic>{
          'displayName': 'Nama',
          'email': sampleEmail,
          'phoneNumber': samplePhone,
          'photoUrl': 'https://example.com/sample/foto-profil.jpg',
        }),
        isFalse,
      );
    });
  });

  group('UserProfile.writableFields', () {
    test('hanya nama, nomor telepon, dan foto yang boleh ditulis klien', () {
      expect(UserProfile.writableFields, contains('displayName'));
      expect(UserProfile.writableFields, contains('phoneNumber'));
      expect(UserProfile.writableFields, contains('photoUrl'));
      expect(UserProfile.writableFields, isNot(contains('role')));
      expect(UserProfile.writableFields, isNot(contains('email')));
      expect(UserProfile.writableFields, isNot(contains('createdAt')));
    });
  });
}
