import '../../../core/constants/app_constants.dart';
import '../../../core/utils/firestore_document_reader.dart';

/// Model dokumen `creatives/{creativeId}` (`docs/BLUEPRINT_APLIKASI.md` §6.7).
///
/// Blueprint melarang menciptakan klaim pengalaman, foto orang, atau URL
/// portofolio palsu. Model karena itu hanya menyimpan data apa adanya dan
/// menyediakan [hasPortfolioUrl] agar UI dapat menyembunyikan tautan kosong.
class Creative {
  const Creative({
    required this.id,
    required this.name,
    this.roleTitle = '',
    this.specialties = const <String>[],
    this.photoUrl = '',
    this.portfolioUrl = '',
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String roleTitle;
  final List<String> specialties;

  /// URL foto kreator; string kosong berarti aset belum diisi pemilik.
  final String photoUrl;

  /// URL portofolio; string kosong berarti tautan belum diisi pemilik.
  final String portfolioUrl;

  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// `true` bila tautan portofolio sudah diisi dan boleh dibuka.
  bool get hasPortfolioUrl => portfolioUrl.trim().isNotEmpty;

  /// `true` bila foto kreator sudah diisi.
  bool get hasPhoto => photoUrl.trim().isNotEmpty;

  /// Membaca dokumen Firestore dengan validasi field.
  ///
  /// Field wajib: `name`. Sisanya opsional dengan fallback eksplisit.
  factory Creative.fromFirestore(String id, Map<String, dynamic> data) {
    final reader = FirestoreDocumentReader(
      documentPath: '${FirestoreCollections.creatives}/$id',
      data: data,
    );
    return Creative(
      id: id,
      name: reader.requireNonEmptyString(CreativeFields.name),
      roleTitle: reader.optionalString(CreativeFields.roleTitle),
      specialties: reader.optionalStringList(CreativeFields.specialties),
      photoUrl: reader.optionalString(CreativeFields.photoUrl),
      portfolioUrl: reader.optionalString(CreativeFields.portfolioUrl),
      sortOrder: reader.optionalNonNegativeInt(CreativeFields.sortOrder),
      isActive: reader.optionalBool(CreativeFields.isActive, fallback: true),
      createdAt: reader.optionalDateTime(CreativeFields.createdAt),
      updatedAt: reader.optionalDateTime(CreativeFields.updatedAt),
    );
  }

  @override
  String toString() => 'Creative($id, $name)';
}
