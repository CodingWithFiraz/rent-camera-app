/// Satuan periode harga (`docs/BLUEPRINT_APLIKASI.md` §6.2, §6.4, §6.6).
///
/// Blueprint melarang mengarang label periode: jangan menulis "/hari" bila
/// pemilik belum menetapkan satuannya. Karena itu nilai yang hilang atau tidak
/// dikenal dipetakan ke [PriceUnit.unspecified], dan UI tidak boleh menampilkan
/// label periode apa pun untuk nilai tersebut.
enum PriceUnit {
  /// `per_day` — harga sewa per hari.
  perDay('per_day'),

  /// `per_session` — harga per sesi/pemakaian.
  perSession('per_session'),

  /// `per_video` — harga per video.
  perVideo('per_video'),

  /// Satuan belum ditetapkan pemilik (nilai kosong atau tidak dikenal).
  unspecified('');

  const PriceUnit(this.storageValue);

  /// Nilai yang disimpan pada field Firestore (`priceUnit`, `priceUnitSnapshot`).
  final String storageValue;

  /// Memetakan nilai Firestore ke [PriceUnit].
  ///
  /// Nilai kosong, bukan teks, atau teks yang tidak dikenal menghasilkan
  /// [unspecified] supaya dokumen lama tetap dapat dibaca tanpa menampilkan
  /// periode yang tidak pernah ditetapkan.
  static PriceUnit fromStorage(Object? value) {
    final raw = value is String ? value.trim() : '';
    for (final unit in PriceUnit.values) {
      if (unit != PriceUnit.unspecified && unit.storageValue == raw) {
        return unit;
      }
    }
    return PriceUnit.unspecified;
  }

  /// `true` bila pemilik aplikasi sudah menetapkan satuan periode.
  bool get isConfigured => this != PriceUnit.unspecified;
}
