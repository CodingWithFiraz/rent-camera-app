import '../../../core/constants/app_constants.dart';
import '../../../core/utils/firestore_document_reader.dart';
import '../../catalog/domain/price_unit.dart';

/// Model dokumen `service_rates/{serviceId}` (`docs/BLUEPRINT_APLIKASI.md` §6.6).
///
/// Blueprint §6.6 melarang mengarang rate card final. Karena itu `rateLabel`,
/// `startingPrice`, dan `deliverables` boleh kosong, dan UI wajib menampilkan
/// keadaan "belum dikonfigurasi" alih-alih angka/nilai rekaan.
class ServiceRate {
  const ServiceRate({
    required this.id,
    required this.title,
    this.description = '',
    this.rateLabel = '',
    this.startingPrice,
    this.priceUnit = PriceUnit.unspecified,
    this.deliverables = const <String>[],
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;

  /// Label rate bebas (mis. "Mulai dari") yang ditetapkan pemilik.
  final String rateLabel;

  /// Harga awal integer Rupiah; `null` bila pemilik belum menetapkannya.
  final int? startingPrice;

  /// Satuan periode harga; [PriceUnit.unspecified] berarti belum ditetapkan.
  final PriceUnit priceUnit;

  /// Daftar keluaran/luaran pekerjaan yang dijanjikan.
  final List<String> deliverables;

  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// `true` bila pemilik sudah mengisi rate (label atau harga awal).
  bool get hasConfiguredRate =>
      rateLabel.trim().isNotEmpty ||
      (startingPrice != null && startingPrice! > 0);

  /// `true` bila label periode boleh ditampilkan.
  bool get hasConfiguredPriceUnit => priceUnit.isConfigured;

  /// Membaca dokumen Firestore dengan validasi field.
  ///
  /// Field wajib: `title`. `updatedAt`/`createdAt` opsional (dokumen lama tetap
  /// dapat dibaca). Nilai validasi hanya menolak tipe salah dan angka negatif;
  /// kekosongan rate dibiarkan sebagai keadaan "belum dikonfigurasi", bukan
  /// diisi nilai karangan.
  factory ServiceRate.fromFirestore(String id, Map<String, dynamic> data) {
    final reader = FirestoreDocumentReader(
      documentPath: '${FirestoreCollections.serviceRates}/$id',
      data: data,
    );
    return ServiceRate(
      id: id,
      title: reader.requireNonEmptyString(ServiceRateFields.title),
      description: reader.optionalString(ServiceRateFields.description),
      rateLabel: reader.optionalString(ServiceRateFields.rateLabel),
      startingPrice: reader.optionalNullableNonNegativeInt(
        ServiceRateFields.startingPrice,
      ),
      priceUnit: PriceUnit.fromStorage(data[ServiceRateFields.priceUnit]),
      deliverables: reader.optionalStringList(ServiceRateFields.deliverables),
      sortOrder: reader.optionalNonNegativeInt(ServiceRateFields.sortOrder),
      isActive: reader.optionalBool(ServiceRateFields.isActive, fallback: true),
      createdAt: reader.optionalDateTime(ServiceRateFields.createdAt),
      updatedAt: reader.optionalDateTime(ServiceRateFields.updatedAt),
    );
  }

  @override
  String toString() => 'ServiceRate($id, $title)';
}
