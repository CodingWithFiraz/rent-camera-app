import '../../../core/constants/app_constants.dart';
import '../../../core/utils/firestore_document_reader.dart';

/// Model dokumen `categories/{categoryId}` (`docs/BLUEPRINT_APLIKASI.md` §6.1).
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.iconKey = CategoryIconKeys.defaultKey,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Document ID pada `categories`.
  final String id;

  final String name;

  /// Slug stabil untuk filter berbasis URL/query.
  final String slug;

  final String description;

  /// Kunci ikon yang dikenal aplikasi; lihat [CategoryIconKeys].
  final String iconKey;

  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Kunci ikon yang aman dirender: nilai tak dikenal jatuh ke default.
  String get resolvedIconKey =>
      CategoryIconKeys.isKnown(iconKey) ? iconKey : CategoryIconKeys.defaultKey;

  /// Membaca dokumen Firestore dengan validasi field.
  ///
  /// Field wajib: `name`, `slug`. Field lain opsional dengan penanganan
  /// eksplisit (dokumen lama tetap dapat dibaca).
  factory Category.fromFirestore(String id, Map<String, dynamic> data) {
    final reader = FirestoreDocumentReader(
      documentPath: '${FirestoreCollections.categories}/$id',
      data: data,
    );
    return Category(
      id: id,
      name: reader.requireNonEmptyString(CategoryFields.name),
      slug: reader.requireNonEmptyString(CategoryFields.slug),
      description: reader.optionalString(CategoryFields.description),
      iconKey: reader.optionalString(
        CategoryFields.iconKey,
        fallback: CategoryIconKeys.defaultKey,
      ),
      sortOrder: reader.optionalNonNegativeInt(CategoryFields.sortOrder),
      isActive: reader.optionalBool(CategoryFields.isActive, fallback: true),
      createdAt: reader.optionalDateTime(CategoryFields.createdAt),
      updatedAt: reader.optionalDateTime(CategoryFields.updatedAt),
    );
  }

  @override
  String toString() => 'Category($id, $name)';
}
