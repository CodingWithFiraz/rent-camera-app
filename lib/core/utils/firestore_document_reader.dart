import 'package:cloud_firestore/cloud_firestore.dart';

import '../errors/firestore_data_exception.dart';

/// Pembaca dokumen Firestore yang memvalidasi keberadaan dan tipe field.
///
/// Dipakai model domain `fromFirestore` supaya:
/// - field wajib yang hilang/kosong/bertipe salah gagal dengan error eksplisit
///   ([FirestoreDataException]), bukan nilai default yang tampak benar;
/// - field opsional yang hilang ditangani secara sadar lewat nilai fallback
///   yang terdokumentasi (toleransi dokumen lama).
///
/// Nilai angka yang bukan integer ditolak: blueprint menyimpan harga dan stok
/// sebagai integer Rupiah/satuan, sehingga `150000.0` dianggap data tak valid,
/// bukan dibulatkan diam-diam.
class FirestoreDocumentReader {
  // Parameter bernama tidak boleh diawali `_`, sehingga initializing formal
  // `this._data` tidak mungkin dipakai untuk field privat ini.
  FirestoreDocumentReader({
    required this.documentPath,
    required Map<String, dynamic> data,
  }) : _data = data; // ignore: prefer_initializing_formals

  /// Path dokumen sumber, misalnya `products/{productId}`.
  final String documentPath;

  final Map<String, dynamic> _data;

  /// `true` bila field ada pada dokumen (walau nilainya null).
  bool has(String field) => _data.containsKey(field);

  /// Teks wajib: harus ada, bertipe `String`, dan tidak kosong.
  String requireNonEmptyString(String field) {
    final value = _data[field];
    if (value is! String) {
      throw _invalid(field, 'harus berupa teks dan tidak boleh hilang');
    }
    if (value.trim().isEmpty) {
      throw _invalid(field, 'tidak boleh kosong');
    }
    return value;
  }

  /// Teks opsional; `null` (termasuk field hilang) menjadi [fallback].
  String optionalString(String field, {String fallback = ''}) {
    final value = _data[field];
    if (value == null) {
      return fallback;
    }
    if (value is! String) {
      throw _invalid(field, 'harus berupa teks');
    }
    return value;
  }

  /// Integer wajib yang tidak boleh negatif.
  int requireNonNegativeInt(String field) {
    final value = _data[field];
    if (value is! int) {
      throw _invalid(
        field,
        'harus berupa bilangan bulat dan tidak boleh hilang',
      );
    }
    if (value < 0) {
      throw _invalid(field, 'tidak boleh bernilai negatif');
    }
    return value;
  }

  /// Integer opsional; `null`/hilang menjadi [fallback]. Nilai negatif ditolak.
  int optionalNonNegativeInt(String field, {int fallback = 0}) {
    final value = _data[field];
    if (value == null) {
      return fallback;
    }
    if (value is! int) {
      throw _invalid(field, 'harus berupa bilangan bulat');
    }
    if (value < 0) {
      throw _invalid(field, 'tidak boleh bernilai negatif');
    }
    return value;
  }

  /// Integer opsional yang boleh benar-benar tidak ada (`null`).
  ///
  /// Dipakai `startingPrice` pada `service_rates` yang memang opsional.
  int? optionalNullableNonNegativeInt(String field) {
    final value = _data[field];
    if (value == null) {
      return null;
    }
    if (value is! int) {
      throw _invalid(field, 'harus berupa bilangan bulat');
    }
    if (value < 0) {
      throw _invalid(field, 'tidak boleh bernilai negatif');
    }
    return value;
  }

  /// Boolean opsional; `null`/hilang menjadi [fallback].
  bool optionalBool(String field, {bool fallback = false}) {
    final value = _data[field];
    if (value == null) {
      return fallback;
    }
    if (value is! bool) {
      throw _invalid(field, 'harus berupa boolean');
    }
    return value;
  }

  /// Daftar teks; `null`/hilang menjadi daftar kosong.
  ///
  /// Isi daftar yang bukan teks ditolak supaya UI tidak menerima `Object` tak
  /// terduga dari dokumen lama.
  List<String> optionalStringList(String field) {
    final value = _data[field];
    if (value == null) {
      return const <String>[];
    }
    if (value is! List) {
      throw _invalid(field, 'harus berupa daftar');
    }
    final result = <String>[];
    for (final item in value) {
      if (item is! String) {
        throw _invalid(field, 'seluruh isi daftar harus berupa teks');
      }
      result.add(item);
    }
    return List<String>.unmodifiable(result);
  }

  /// Timestamp opsional; mendukung [Timestamp] maupun `DateTime` (data lama).
  DateTime? optionalDateTime(String field) {
    final value = _data[field];
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    throw _invalid(field, 'harus berupa timestamp');
  }

  FirestoreDataException _invalid(String field, String reason) =>
      FirestoreDataException(
        documentPath: documentPath,
        field: field,
        reason: reason,
      );
}
