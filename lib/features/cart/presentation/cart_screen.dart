import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/repository_error_mapper.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/external_launcher.dart';
import '../../../core/utils/whatsapp_checkout_link.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../catalog/presentation/widgets/catalog_section_notice.dart';
import '../domain/cart_checkout.dart';
import 'cart_providers.dart';
import 'widgets/cart_line_tile.dart';

/// Halaman keranjang dan checkout WhatsApp
/// (`docs/BLUEPRINT_APLIKASI.md` §7).
///
/// Halaman ini tidak menyimpan query Firestore sendiri: isi keranjang dibaca
/// lewat [cartCheckoutProvider] (stream keranjang + baca ulang produk) dan
/// setiap perubahan ditulis lewat [CartActions]. Harga, stok, dan status yang
/// ditampilkan serta yang dikirim ke WhatsApp selalu berasal dari dokumen
/// terbaru, bukan dari snapshot keranjang.
///
/// Checkout hanya menyusun tautan `wa.me` dan membukanya lewat
/// [ExternalLauncher]: tidak ada booking, pembayaran, atau penguncian stok yang
/// dilakukan aplikasi ini.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  /// Baris yang sedang menyimpan perubahan; `null` berarti tidak ada.
  String? _busyProductId;

  /// Kegagalan aksi tulis terakhir yang sudah dipetakan untuk pengguna.
  String? _actionError;

  /// `true` selama keranjang dibaca ulang dan tautan WhatsApp dibuka.
  bool _isCheckingOut = false;

  String get _uid =>
      ref.read(authSessionNotifierProvider).user?.uid.trim() ?? '';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionNotifierProvider);

    return AppScaffold(
      title: 'Keranjang',
      leading: BackButton(onPressed: _backToCatalog),
      body: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? child) =>
            _buildBody(session.user?.uid.trim() ?? ''),
      ),
    );
  }

  /// Kembali ke katalog; tetap bekerja bila halaman dibuka tanpa riwayat
  /// navigasi (mis. tautan langsung) sehingga `pop` tidak mungkin.
  void _backToCatalog() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.catalog);
  }

  Widget _buildBody(String uid) {
    if (uid.isEmpty) {
      return AppEmptyState(
        icon: Icons.lock_outline,
        title: 'Masuk untuk membuka keranjang',
        message:
            'Keranjang disimpan per akun, sehingga hanya dapat dibuka setelah '
            'login. Masuk kembali untuk melanjutkan sewa.',
        action: OutlinedButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text('Masuk'),
        ),
      );
    }

    return ref
        .watch(cartCheckoutProvider(uid))
        .when(
          loading: () => const AppLoading(label: 'Memuat keranjang…'),
          error: (Object error, StackTrace stackTrace) => AppErrorState(
            title: 'Keranjang belum dapat dimuat',
            message: repositoryErrorMessageFor(error, entityLabel: 'keranjang'),
            onRetry: () => ref.invalidate(cartCheckoutProvider(uid)),
          ),
          data: (CartCheckoutValidation validation) =>
              validation.isEmpty ? _buildEmptyCart() : _buildCart(validation),
        );
  }

  /// Keranjang kosong: tidak ada baris contoh dan tidak ada total karangan.
  Widget _buildEmptyCart() {
    return AppEmptyState(
      icon: Icons.shopping_bag_outlined,
      title: 'Keranjang masih kosong',
      message:
          'Belum ada alat di keranjang. Tambahkan alat dari katalog untuk '
          'menyusun permintaan sewa lewat WhatsApp.',
      action: OutlinedButton(
        onPressed: _backToCatalog,
        child: const Text('Cari alat di katalog'),
      ),
    );
  }

  Widget _buildCart(CartCheckoutValidation validation) {
    final theme = Theme.of(context);
    return ListView(
      padding: AppSpacing.screen,
      children: <Widget>[
        if (validation.hasIssues) ...<Widget>[
          CatalogSectionNotice(message: _blockedNotice(validation)),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_actionError != null) ...<Widget>[
          CatalogSectionNotice(message: _actionError!, isError: true),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final CartCheckoutLine line in validation.lines) ...<Widget>[
          _buildLine(line),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),
        _buildCheckoutSummary(validation),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Pesan ini hanya permintaan sewa: bukan booking final, bukan '
          'pembayaran, dan tidak mengunci stok. Ketersediaan, periode sewa, '
          'serta biaya akhir dikonfirmasi admin lewat chat WhatsApp.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Ringkasan baris yang tidak ikut dipesan, memakai jumlah baris apa adanya.
  String _blockedNotice(CartCheckoutValidation validation) {
    final count = validation.blockedLineCount;
    final lines = count == 1 ? 'Satu baris' : '$count baris';
    return '$lines belum dapat dipesan, sehingga tidak ikut dihitung pada '
        'total. Selesaikan masalah pada baris tersebut lebih dulu.';
  }

  Widget _buildLine(CartCheckoutLine line) {
    final isBusy = _busyProductId == line.productId;
    return CartLineTile(
      name: line.name,
      brand: line.brand,
      imageUrl: line.imageUrl,
      quantity: line.quantity,
      unitPriceText: line.unitPriceText,
      periodLabel: line.periodLabel,
      subtotalText: _subtotalText(line),
      stockNote: _stockNote(line),
      issueMessage: line.issue?.message,
      quantityNote: _quantityNote(line),
      issueActionLabel: _issueActionLabel(line),
      onIssueAction: isBusy ? null : _issueAction(line),
      onIncrease: isBusy ? null : _increase(line),
      onDecrease: isBusy ? null : _decrease(line),
      onRemove: isBusy ? null : () => _remove(line),
      isBusy: isBusy,
    );
  }

  /// Subtotal baris; harga yang belum diisi tidak ditulis sebagai `Rp0`.
  String _subtotalText(CartCheckoutLine line) => line.unitPrice > 0
      ? CurrencyFormatter.formatRupiah(line.subtotal)
      : 'Belum dapat dihitung (harga belum diisi)';

  /// Stok terverifikasi terbaru; `null` bila dokumen produk sudah tidak ada.
  String? _stockNote(CartCheckoutLine line) {
    final stock = line.availableStock;
    return stock == null ? null : 'Stok terverifikasi: $stock';
  }

  /// Batas jumlah, atau alasan jumlah belum dapat diubah.
  String _quantityNote(CartCheckoutLine line) {
    final max = line.selectableMaxQuantity;
    if (!line.canChangeQuantity || max == null) {
      return 'Jumlah belum dapat diubah sampai masalah di baris ini '
          'diselesaikan.';
    }
    return 'Jumlah maksimum: $max';
  }

  /// Label tombol perbaikan untuk masalah baris; `null` bila baris siap.
  String? _issueActionLabel(CartCheckoutLine line) {
    switch (line.issue?.kind) {
      case CartCheckoutIssueKind.priceChanged ||
          CartCheckoutIssueKind.priceUnitChanged:
        return 'Perbarui harga';
      case CartCheckoutIssueKind.insufficientStock:
        return line.recommendedQuantityForStock == null
            ? 'Hapus dari keranjang'
            : 'Sesuaikan jumlah';
      case CartCheckoutIssueKind.productMissing ||
          CartCheckoutIssueKind.productInactive ||
          CartCheckoutIssueKind.priceNotConfigured:
        return 'Hapus dari keranjang';
      case null:
        return null;
    }
  }

  /// Tindakan yang memperbaiki masalah baris, sesuai jenisnya.
  VoidCallback? _issueAction(CartCheckoutLine line) {
    switch (line.issue?.kind) {
      case CartCheckoutIssueKind.priceChanged ||
          CartCheckoutIssueKind.priceUnitChanged:
        return () => _refreshStoredPrice(line);
      case CartCheckoutIssueKind.insufficientStock:
        final recommended = line.recommendedQuantityForStock;
        return recommended == null
            ? () => _remove(line)
            : () => _setQuantity(line, recommended);
      case CartCheckoutIssueKind.productMissing ||
          CartCheckoutIssueKind.productInactive ||
          CartCheckoutIssueKind.priceNotConfigured:
        return () => _remove(line);
      case null:
        return null;
    }
  }

  /// Menambah jumlah satu langkah; `null` bila stok terverifikasi belum cukup.
  VoidCallback? _increase(CartCheckoutLine line) {
    final max = line.selectableMaxQuantity;
    if (!line.canChangeQuantity || max == null || line.quantity >= max) {
      return null;
    }
    return () => _setQuantity(line, line.quantity + 1);
  }

  /// Mengurangi jumlah satu langkah; berhenti pada 1 (hapus untuk membuang).
  VoidCallback? _decrease(CartCheckoutLine line) {
    if (!line.canChangeQuantity || line.quantity <= 1) {
      return null;
    }
    return () => _setQuantity(line, line.quantity - 1);
  }

  /// Ringkasan total dan tombol checkout WhatsApp.
  Widget _buildCheckoutSummary(CartCheckoutValidation validation) {
    final theme = Theme.of(context);
    final isConfigured = ref.watch(isCheckoutConfiguredProvider);
    final hasUsableLines = validation.usableLines.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Total estimasi',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  hasUsableLines
                      ? validation.totalText
                      : 'Belum dapat dihitung',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            validation.hasIssues
                ? 'Total hanya menjumlahkan baris yang siap dipesan.'
                : 'Total dihitung dari harga terbaru di katalog, bukan dari '
                      'harga saat alat dimasukkan ke keranjang.',
            style: theme.textTheme.bodySmall,
          ),
          if (!isConfigured) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const CatalogSectionNotice(
              message:
                  'Nomor WhatsApp tujuan belum dikonfigurasi, sehingga '
                  'permintaan sewa belum dapat dikirim dari aplikasi. '
                  'Hubungi admin untuk melengkapinya.',
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              label: 'Checkout via WhatsApp',
              icon: Icons.chat_outlined,
              isLoading: _isCheckingOut,
              onPressed: hasUsableLines && isConfigured ? _checkout : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Mengubah jumlah satu baris memakai batas stok terverifikasi terbaru.
  Future<void> _setQuantity(CartCheckoutLine line, int quantity) {
    final max = line.selectableMaxQuantity;
    if (quantity < 1 || (max != null && quantity > max)) {
      return Future<void>.value();
    }
    return _runAction(
      productId: line.productId,
      action: (String uid) => ref
          .read(cartActionsProvider)
          .setQuantity(uid: uid, productId: line.productId, quantity: quantity),
    );
  }

  /// Menghapus satu baris dari keranjang pemilik sesi.
  Future<void> _remove(CartCheckoutLine line) => _runAction(
    productId: line.productId,
    action: (String uid) => ref
        .read(cartActionsProvider)
        .removeItem(uid: uid, productId: line.productId),
  );

  /// Menyalin harga terbaru dokumen produk ke baris keranjang.
  Future<void> _refreshStoredPrice(CartCheckoutLine line) => _runAction(
    productId: line.productId,
    action: (String uid) => ref
        .read(cartActionsProvider)
        .refreshStoredPrice(uid: uid, productId: line.productId),
  );

  /// Menjalankan satu aksi tulis sambil menandai baris yang sedang menyimpan.
  ///
  /// Satu baris hanya boleh menulis pada satu waktu, supaya dua ketukan cepat
  /// tidak menghasilkan urutan tulis yang tidak pasti.
  Future<void> _runAction({
    required String productId,
    required Future<void> Function(String uid) action,
  }) async {
    if (_busyProductId != null) {
      return;
    }
    final uid = _uid;
    if (uid.isEmpty) {
      return;
    }
    setState(() {
      _busyProductId = productId;
      _actionError = null;
    });
    try {
      await action(uid);
    } catch (error) {
      if (mounted) {
        setState(
          () => _actionError = repositoryErrorMessageFor(
            error,
            entityLabel: 'keranjang',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyProductId = null);
      }
    }
  }

  /// Membaca ulang keranjang, lalu membuka WhatsApp berisi permintaan sewa.
  ///
  /// Data dibaca ulang tepat sebelum pesan disusun dan tombol hanya aktif bila
  /// tidak ada baris bermasalah, sehingga pesan tidak pernah memuat harga
  /// snapshot yang belum terverifikasi. Tidak ada booking atau pembayaran yang
  /// terjadi di sini.
  Future<void> _checkout() async {
    final uid = _uid;
    if (uid.isEmpty || _isCheckingOut) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final customerName = ref
        .read(authSessionNotifierProvider)
        .user
        ?.displayName;

    setState(() {
      _isCheckingOut = true;
      _actionError = null;
    });
    try {
      final validation = await ref
          .read(cartActionsProvider)
          .validateForCheckout(uid);
      if (validation.isEmpty || !validation.isReady) {
        ref.invalidate(cartCheckoutProvider(uid));
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              validation.isEmpty
                  ? 'Keranjang sudah kosong.'
                  : 'Ada baris keranjang yang perlu diperbaiki sebelum '
                        'checkout.',
            ),
          ),
        );
        return;
      }

      final uri = WhatsAppCheckoutLink.tryBuildUri(
        number: ref.read(checkoutWhatsAppNumberProvider),
        message: validation.buildWhatsAppMessage(customerName: customerName),
      );
      if (uri == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Nomor WhatsApp tujuan belum dikonfigurasi, sehingga permintaan '
              'sewa belum dapat dikirim.',
            ),
          ),
        );
        return;
      }

      final status = await ref
          .read(externalLauncherProvider)
          .open(uri.toString());
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(_launchMessage(status))));
    } catch (error) {
      if (mounted) {
        setState(
          () => _actionError = repositoryErrorMessageFor(
            error,
            entityLabel: 'keranjang',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  /// Kalimat hasil pembukaan tautan; kegagalan tidak dilaporkan sebagai sukses.
  String _launchMessage(ExternalLaunchStatus status) {
    switch (status) {
      case ExternalLaunchStatus.launched:
        return 'WhatsApp dibuka. Kirim pesan tersebut untuk meminta '
            'konfirmasi ketersediaan dan periode sewa.';
      case ExternalLaunchStatus.copiedToClipboard:
        return 'WhatsApp tidak dapat dibuka, sehingga tautan permintaan sudah '
            'disalin ke clipboard. Tempel di chat WhatsApp pemilik.';
      case ExternalLaunchStatus.invalidUrl:
        return 'Tautan permintaan sewa tidak valid, sehingga tidak dapat '
            'dibuka.';
      case ExternalLaunchStatus.failed:
        return 'WhatsApp tidak dapat dibuka dan tautan gagal disalin. Coba '
            'lagi.';
    }
  }
}
