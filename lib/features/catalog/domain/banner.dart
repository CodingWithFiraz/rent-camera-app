import '../../../core/constants/app_constants.dart';
import '../../../core/utils/firestore_document_reader.dart';

/// Jenis target navigasi banner (`docs/BLUEPRINT_APLIKASI.md` §6.5).
///
/// Nilai disimpan sebagai teks pada field `targetType`.
enum BannerTargetType {
  /// Menuju halaman Portofolio; `targetValue` tidak dipakai.
  portfolio('portfolio'),

  /// Menuju katalog dengan kategori `targetValue` (document ID kategori).
  category('category'),

  /// Membuka URL pada `targetValue`.
  externalUrl('externalUrl'),

  /// `targetType` hilang atau tidak dikenal; banner tidak boleh dinavigasikan.
  unknown('');

  const BannerTargetType(this.storageValue);

  /// Nilai pada field Firestore `targetType`.
  final String storageValue;

  static BannerTargetType fromStorage(Object? value) {
    final raw = value is String ? value.trim() : '';
    for (final type in BannerTargetType.values) {
      if (type != BannerTargetType.unknown && type.storageValue == raw) {
        return type;
      }
    }
    return BannerTargetType.unknown;
  }
}

/// Model dokumen `banners/{bannerId}` (§6.5).
class Banner {
  const Banner({
    required this.id,
    required this.title,
    this.imageUrl = '',
    this.targetType = BannerTargetType.unknown,
    this.targetValue = '',
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;

  /// URL gambar banner; string kosong berarti aset belum diisi pemilik.
  final String imageUrl;

  final BannerTargetType targetType;

  /// Nilai target: document ID kategori atau URL eksternal.
  final String targetValue;

  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// `true` bila target banner sudah dikonfigurasi dan boleh dibuka.
  ///
  /// Dipakai UI supaya banner tanpa target tidak menjadi tombol mati.
  bool get hasNavigableTarget {
    switch (targetType) {
      case BannerTargetType.portfolio:
        return true;
      case BannerTargetType.category:
      case BannerTargetType.externalUrl:
        return targetValue.trim().isNotEmpty;
      case BannerTargetType.unknown:
        return false;
    }
  }

  /// Membaca dokumen Firestore dengan validasi field.
  ///
  /// Field wajib: `title`. `targetType` yang hilang/tak dikenal menjadi
  /// [BannerTargetType.unknown] sehingga UI dapat menolak navigasi.
  factory Banner.fromFirestore(String id, Map<String, dynamic> data) {
    final reader = FirestoreDocumentReader(
      documentPath: '${FirestoreCollections.banners}/$id',
      data: data,
    );
    return Banner(
      id: id,
      title: reader.requireNonEmptyString(BannerFields.title),
      imageUrl: reader.optionalString(BannerFields.imageUrl),
      targetType: BannerTargetType.fromStorage(data[BannerFields.targetType]),
      targetValue: reader.optionalString(BannerFields.targetValue),
      sortOrder: reader.optionalNonNegativeInt(BannerFields.sortOrder),
      isActive: reader.optionalBool(BannerFields.isActive, fallback: true),
      createdAt: reader.optionalDateTime(BannerFields.createdAt),
      updatedAt: reader.optionalDateTime(BannerFields.updatedAt),
    );
  }

  @override
  String toString() => 'Banner($id, $title)';
}
