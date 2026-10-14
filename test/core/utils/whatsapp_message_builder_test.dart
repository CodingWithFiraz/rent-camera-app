import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/core/utils/whatsapp_message_builder.dart';

void main() {
  group('WhatsAppOrderLine', () {
    test('menyusun judul, harga satuan, dan subtotal dari data baris', () {
      const line = WhatsAppOrderLine(
        name: 'Lumix G85',
        brand: 'Panasonic',
        quantity: 2,
        unitPrice: 150000,
        periodLabel: 'hari',
      );

      expect(line.title, 'Lumix G85 — Panasonic');
      expect(line.hasBrand, isTrue);
      expect(line.hasPeriodLabel, isTrue);
      expect(line.subtotal, 300000);
      expect(line.unitPriceText, 'Rp150.000 / hari');
      expect(line.subtotalText, 'Rp300.000');
    });

    test('tidak menulis periode atau pemisah brand yang belum ada', () {
      const line = WhatsAppOrderLine(
        name: 'Lensa 50mm',
        quantity: 1,
        unitPrice: 50000,
      );

      expect(line.title, 'Lensa 50mm');
      expect(line.hasBrand, isFalse);
      expect(line.hasPeriodLabel, isFalse);
      expect(line.unitPriceText, 'Rp50.000');
      expect(line.subtotalText, 'Rp50.000');
    });
  });

  group('WhatsAppOrderMessage', () {
    test('menjumlahkan subtotal dan memakai periode bersama', () {
      const message = WhatsAppOrderMessage(
        lines: <WhatsAppOrderLine>[
          WhatsAppOrderLine(
            name: 'Lumix G85',
            quantity: 2,
            unitPrice: 150000,
            periodLabel: 'hari',
          ),
          WhatsAppOrderLine(
            name: 'Lensa 50mm',
            quantity: 1,
            unitPrice: 50000,
            periodLabel: 'hari',
          ),
        ],
      );

      expect(message.total, 350000);
      expect(message.sharedPeriodLabel, 'hari');
      expect(message.totalText, 'Rp350.000 / hari');
    });

    test('tidak mengarang periode bila satuan antar baris berbeda', () {
      const message = WhatsAppOrderMessage(
        lines: <WhatsAppOrderLine>[
          WhatsAppOrderLine(
            name: 'Sewa harian',
            quantity: 1,
            unitPrice: 150000,
            periodLabel: 'hari',
          ),
          WhatsAppOrderLine(
            name: 'Sewa per sesi',
            quantity: 1,
            unitPrice: 150000,
            periodLabel: 'sesi',
          ),
        ],
      );

      expect(message.sharedPeriodLabel, isNull);
      expect(message.totalText, 'Rp300.000');
    });

    test('nama pengguna dipakai hanya bila benar-benar terisi', () {
      const lines = <WhatsAppOrderLine>[
        WhatsAppOrderLine(name: 'Lumix G85', quantity: 1, unitPrice: 150000),
      ];

      expect(const WhatsAppOrderMessage(lines: lines).hasCustomerName, isFalse);
      expect(
        const WhatsAppOrderMessage(
          lines: lines,
          customerName: '   ',
        ).hasCustomerName,
        isFalse,
      );
      expect(
        const WhatsAppOrderMessage(
          lines: lines,
          customerName: 'Nama Uji',
        ).hasCustomerName,
        isTrue,
      );
    });
  });

  group('WhatsAppMessageBuilder.build', () {
    test('menulis pesan lengkap: baris, harga, total, dan nama', () {
      final message = WhatsAppMessageBuilder.build(
        const WhatsAppOrderMessage(
          lines: <WhatsAppOrderLine>[
            WhatsAppOrderLine(
              name: 'Lumix G85',
              brand: 'Panasonic',
              quantity: 2,
              unitPrice: 150000,
              periodLabel: 'hari',
            ),
            WhatsAppOrderLine(
              name: 'Lensa 50mm',
              quantity: 1,
              unitPrice: 50000,
              periodLabel: 'hari',
            ),
          ],
          customerName: ' Nama Uji ',
        ),
      );

      expect(
        message,
        startsWith('Halo, saya ingin menanyakan penyewaan alat berikut:'),
      );
      expect(
        message,
        contains(
          '1. Lumix G85 — Panasonic\n'
          '   Jumlah: 2\n'
          '   Harga satuan: Rp150.000 / hari\n'
          '   Subtotal: Rp300.000',
        ),
      );
      expect(
        message,
        contains(
          '2. Lensa 50mm\n'
          '   Jumlah: 1\n'
          '   Harga satuan: Rp50.000 / hari\n'
          '   Subtotal: Rp50.000',
        ),
      );
      expect(message, contains('TOTAL ESTIMASI: Rp350.000 / hari'));
      expect(
        message,
        contains(
          'Mohon konfirmasi ketersediaan, periode sewa, dan ketentuan lainnya.',
        ),
      );
      // Nama ditulis sekali di akhir dan sudah dirapikan dari spasi berlebih.
      expect(message, endsWith('Nama: Nama Uji'));
      expect(message, isNot(contains('Nama:  ')));
      // Pesan tidak diakhiri baris kosong agar rapi pada kotak chat WhatsApp.
      expect(message, message.trimRight());
    });

    test('melewati baris nama bila nama pengguna belum ada', () {
      final message = WhatsAppMessageBuilder.build(
        const WhatsAppOrderMessage(
          lines: <WhatsAppOrderLine>[
            WhatsAppOrderLine(
              name: 'Lumix G85',
              quantity: 1,
              unitPrice: 150000,
            ),
          ],
        ),
      );

      expect(message, isNot(contains('Nama:')));
      expect(message, contains('TOTAL ESTIMASI: Rp150.000\n'));
    });
  });

  group('WhatsAppMessageBuilder.build menolak prasyarat yang dilanggar', () {
    test('keranjang tanpa baris tidak menghasilkan pesan', () {
      expect(
        () => WhatsAppMessageBuilder.build(
          const WhatsAppOrderMessage(lines: <WhatsAppOrderLine>[]),
        ),
        throwsArgumentError,
      );
    });

    test('jumlah kurang dari 1 ditolak', () {
      expect(
        () => WhatsAppMessageBuilder.build(
          const WhatsAppOrderMessage(
            lines: <WhatsAppOrderLine>[
              WhatsAppOrderLine(
                name: 'Lumix G85',
                quantity: 0,
                unitPrice: 1000,
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('harga 0 ditolak karena berarti harga belum diisi', () {
      expect(
        () => WhatsAppMessageBuilder.build(
          const WhatsAppOrderMessage(
            lines: <WhatsAppOrderLine>[
              WhatsAppOrderLine(name: 'Lumix G85', quantity: 1, unitPrice: 0),
            ],
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
