import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/repository_error_mapper.dart';
import '../../catalog/domain/product.dart';
import '../domain/product_draft.dart';

/// Kontrak akses collection `products` untuk dashboard admin.
///
/// UI dan notifier bergantung pada interface ini supaya alur admin (form,
/// arsip/pulihkan) dapat diuji tanpa kredensial Firebase. Implementasi
/// sesungguhnya ada pada [FirebaseAdminProductRepository].
abstract interface class AdminProductRepository {
  /// Document ID baru tanpa menulis apa pun.
  String reserveProductId();

  /// Seluruh produk termasuk yang diarsipkan (`isActive == false`).
  Stream<List<Product>> watchAllProducts();

  /// Versi sekali-baca dari [watchAllProducts].
  Future<List<Product>> fetchAllProducts();

  /// Membaca satu produk apa pun statusnya; `null` bila dokumen tidak ada.
  Future<Product?> fetchProduct(String productId);

  /// Membuat dokumen produk baru dengan [productId] hasil [reserveProductId].
  Future<void> createProduct({
    required String productId,
    required ProductDraft draft,
  });

  /// Memperbarui field yang dikelola form admin.
  Future<void> updateProduct({
    required String productId,
    required ProductDraft draft,
  });

  /// Mengarsipkan (`isActive: false`) atau memulihkan (`isActive: true`).
  Future<void> setActive({required String productId, required bool isActive});
}

/// Akses collection `products` untuk dashboard admin
/// (`docs/BLUEPRINT_APLIKASI.md` §6.2 dan §8).
///
/// Repository ini **tidak** memutuskan siapa yang boleh menulis: keputusan itu
/// ada pada Firestore Security Rules (`firebase/firestore.rules`, hanya claim
/// `admin: true`). Pemeriksaan claim di aplikasi hanya untuk route guard dan UI,
/// sehingga permintaan tulis dari non-admin tetap ditolak backend.
class FirebaseAdminProductRepository implements AdminProductRepository {
  FirebaseAdminProductRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _entityLabel = 'produk';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.products);

  @override
  String reserveProductId() => _collection.doc().id;

  @override
  Stream<List<Product>> watchAllProducts() {
    return guardRepositoryStream(
      _collection.snapshots().map(_mapSnapshot),
      entityLabel: _entityLabel,
    );
  }

  @override
  Future<List<Product>> fetchAllProducts() async {
    try {
      return _mapSnapshot(await _collection.get());
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  @override
  Future<Product?> fetchProduct(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) {
      return null;
    }
    try {
      final snapshot = await _collection.doc(id).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return Product.fromFirestore(snapshot.id, data);
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  @override
  Future<void> createProduct({
    required String productId,
    required ProductDraft draft,
  }) async {
    final id = _requireProductId(productId);
    final data = _documentData(draft)
      ..[ProductFields.createdAt] = FieldValue.serverTimestamp()
      ..[ProductFields.updatedAt] = FieldValue.serverTimestamp();
    try {
      await _collection.doc(id).set(data);
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  @override
  Future<void> updateProduct({
    required String productId,
    required ProductDraft draft,
  }) async {
    final id = _requireProductId(productId);
    final data = _documentData(draft)
      ..[ProductFields.updatedAt] = FieldValue.serverTimestamp();
    try {
      await _collection.doc(id).set(data, SetOptions(merge: true));
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  /// Mengarsipkan (`isActive: false`) atau memulihkan (`isActive: true`).
  ///
  /// Arsip hanya mengubah status: foto pada Storage **tidak** dihapus, sehingga
  /// restore mengembalikan produk apa adanya dan dokumen tidak perlu dibuat ulang.
  @override
  Future<void> setActive({
    required String productId,
    required bool isActive,
  }) async {
    final id = _requireProductId(productId);
    try {
      await _collection.doc(id).set(<String, dynamic>{
        ProductFields.isActive: isActive,
        ProductFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      throw mapRepositoryError(error, entityLabel: _entityLabel);
    }
  }

  /// Susunan field dokumen `products/{productId}` yang ditulis aplikasi.
  ///
  /// Validasi diulang di sini sebagai pertahanan terakhir: nilai negatif atau
  /// field wajib yang kosong tidak boleh sampai ke Firestore walaupun form
  /// dilewati.
  Map<String, dynamic> _documentData(ProductDraft draft) {
    final name = draft.name.trim();
    if (name.isEmpty) {
      throw const AppException('Nama alat wajib diisi.');
    }
    final brand = draft.brand.trim();
    if (brand.isEmpty) {
      throw const AppException('Brand wajib diisi.');
    }
    final categoryId = draft.categoryId.trim();
    if (categoryId.isEmpty) {
      throw const AppException('Kategori wajib dipilih.');
    }
    if (draft.price < 0) {
      throw const AppException('Harga tidak boleh negatif.');
    }
    if (draft.stockQuantity < 0) {
      throw const AppException('Stok tidak boleh negatif.');
    }

    return <String, dynamic>{
      ProductFields.name: name,
      ProductFields.description: draft.description.trim(),
      ProductFields.categoryId: categoryId,
      ProductFields.brand: brand,
      ProductFields.price: draft.price,
      ProductFields.priceUnit: draft.priceUnit.storageValue,
      ProductFields.stockQuantity: draft.stockQuantity,
      ProductFields.imageUrls: List<String>.unmodifiable(draft.imageUrls),
      ProductFields.isActive: draft.isActive,
    };
  }

  String _requireProductId(String productId) {
    final id = productId.trim();
    if (id.isEmpty) {
      throw const AppException(
        'ID produk tidak ditemukan, sehingga produk tidak dapat disimpan.',
      );
    }
    return id;
  }

  /// Memetakan dokumen dan mengurutkannya berdasarkan nama.
  ///
  /// Pengurutan dilakukan di klien supaya dashboard tidak memerlukan composite
  /// index untuk setiap kombinasi filter.
  List<Product> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final products = snapshot.docs
        .map((doc) => Product.fromFirestore(doc.id, doc.data()))
        .toList();
    products.sort((Product a, Product b) {
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return byName != 0 ? byName : a.id.compareTo(b.id);
    });
    return List<Product>.unmodifiable(products);
  }
}
