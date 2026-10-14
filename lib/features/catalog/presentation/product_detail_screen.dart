import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/repository_error_mapper.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/product_image.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../cart/presentation/cart_providers.dart';
import '../domain/price_display.dart';
import '../domain/product.dart';
import 'catalog_providers.dart';
import 'widgets/catalog_app_bar_actions.dart';
import 'widgets/catalog_section_notice.dart';

/// Halaman detail produk (`docs/BLUEPRINT_APLIKASI.md` §4).
///
/// Menampilkan foto utama, identitas alat, harga dengan periode yang eksplisit,
/// stok, deskripsi, dan aksi "Sewa". Aksi itu menulis ke keranjang lewat
/// `CartRepository` yang sudah ada — tidak ada logika keranjang duplikat di
/// widget — dan selalu membaca ulang produk dari Firestore lebih dulu supaya
/// harga/stok yang dipakai bukan data lama di layar.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  /// Document ID produk pada collection `products`.
  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  /// Jumlah yang diminta pembeli; dibatasi stok produk di [Product].
  int _quantity = 1;

  bool _isAddingToCart = false;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authSessionNotifierProvider).user?.uid ?? '';
    final productAsync = ref.watch(productByIdProvider(widget.productId));

    return AppScaffold(
      title: 'Detail alat',
      leading: BackButton(onPressed: _backToCatalog),
      actions: const <Widget>[CatalogAppBarActions()],
      body: productAsync.when(
        loading: () => const AppLoading(label: 'Memuat detail alat…'),
        error: (Object error, StackTrace stackTrace) => AppErrorState(
          title: 'Detail alat belum dapat dimuat',
          message: repositoryErrorMessageFor(error, entityLabel: 'produk'),
          onRetry: () => ref.invalidate(productByIdProvider(widget.productId)),
        ),
        data: (Product? product) => product == null
            ? _ProductMissing(onBack: _backToCatalog)
            : _buildDetail(product, uid),
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

  Widget _buildDetail(Product product, String uid) {
    final theme = Theme.of(context);
    final price = PriceDisplay.forProduct(product);
    final categoryLabel =
        ref.watch(categoryNameProvider(product.categoryId)) ??
        product.categoryId;
    final maxQuantity = product.maxOrderableQuantity;
    final canAddToCart =
        product.isInStock && uid.isNotEmpty && !_isAddingToCart;

    return ListView(
      padding: AppSpacing.screen,
      children: <Widget>[
        ProductImage(
          imageUrl: product.primaryImageUrl,
          aspectRatio: 4 / 3,
          borderRadius: AppRadius.lgAll,
          semanticLabel: 'Foto ${product.name}',
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(product.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(product.brand, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text('Kategori: $categoryLabel', style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        _buildPriceBlock(theme, price),
        const SizedBox(height: AppSpacing.md),
        _buildStockLine(theme, product),
        if (!product.isActive) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          const CatalogSectionNotice(
            isError: true,
            message:
                'Alat ini sudah diarsipkan admin sehingga tidak dapat '
                'disewa lagi.',
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('Deskripsi', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          product.description.trim().isEmpty
              ? 'Deskripsi belum diisi admin.'
              : product.description,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (product.isInStock && maxQuantity > 1) ...<Widget>[
          _buildQuantityRow(theme, maxQuantity),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (uid.isEmpty) ...<Widget>[
          const CatalogSectionNotice(
            message:
                'Masuk terlebih dahulu agar alat dapat ditambahkan ke '
                'keranjang.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        FilledButton.icon(
          onPressed: canAddToCart ? () => _addToCart(product) : null,
          icon: _isAddingToCart
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.shopping_bag_outlined),
          label: Text(_isAddingToCart ? 'Menambahkan…' : 'Sewa'),
        ),
      ],
    );
  }

  /// Kotak harga: nominal ditambah satuan periode.
  ///
  /// Satuan hanya ditulis bila dokumen produk benar-benar menetapkan
  /// `priceUnit`; bila belum, aplikasi menjelaskan bahwa satuannya belum diatur
  /// alih-alih menebak "/hari".
  Widget _buildPriceBlock(ThemeData theme, PriceDisplay price) {
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
          Text('Harga sewa', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(price.amountText, style: theme.textTheme.titleLarge),
          if (price.hasPeriodLabel)
            Text(price.periodLabel!, style: theme.textTheme.bodySmall)
          else
            Text(
              'Satuan periode harga belum ditetapkan admin.',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  /// Keterangan stok yang tidak pernah menyesatkan.
  Widget _buildStockLine(ThemeData theme, Product product) {
    if (!product.isActive) {
      return Text(
        'Stok: produk sudah tidak tersedia',
        style: theme.textTheme.bodyMedium,
      );
    }
    if (product.stockQuantity <= 0) {
      return Text(
        'Stok habis',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }
    return Text(
      'Stok tersedia: ${product.stockQuantity}',
      style: theme.textTheme.bodyMedium,
    );
  }

  /// Pemilih jumlah, dibatasi stok yang terbaca dari Firestore.
  Widget _buildQuantityRow(ThemeData theme, int maxQuantity) {
    return Row(
      children: <Widget>[
        Text('Jumlah', style: theme.textTheme.labelMedium),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: 'Kurangi jumlah',
          onPressed: _quantity > 1
              ? () => setState(() => _quantity -= 1)
              : null,
          icon: const Icon(Icons.remove),
        ),
        Text('$_quantity', style: theme.textTheme.titleMedium),
        IconButton(
          tooltip: 'Tambah jumlah',
          onPressed: _quantity < maxQuantity
              ? () => setState(() => _quantity += 1)
              : null,
          icon: const Icon(Icons.add),
        ),
        const Spacer(),
        Text('maks. $maxQuantity', style: theme.textTheme.bodySmall),
      ],
    );
  }

  /// Menambahkan alat ke keranjang memakai API cart yang sudah ada.
  ///
  /// Produk dibaca ulang dari Firestore sebelum ditulis, dan
  /// [CartRepository.addProduct] yang memvalidasi status aktif, stok, serta
  /// batas jumlah — tidak ada perhitungan duplikat di widget ini.
  Future<void> _addToCart(Product product) async {
    final uid = ref.read(authSessionNotifierProvider).user?.uid ?? '';
    if (uid.isEmpty) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isAddingToCart = true);
    try {
      final refreshed = await ref
          .read(productRepositoryProvider)
          .fetchProductById(product.id);
      if (refreshed == null) {
        throw const AppException('Alat ini sudah tidak ada di katalog.');
      }
      await ref
          .read(cartRepositoryProvider)
          .addProduct(uid: uid, product: refreshed, quantity: _quantity);
      messenger.showSnackBar(
        SnackBar(content: Text('${refreshed.name} ditambahkan ke keranjang.')),
      );
    } on AppException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            mapRepositoryError(error, entityLabel: 'keranjang').message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }
}

/// Keadaan produk tidak ditemukan.
///
/// Ditampilkan apa adanya, tanpa produk contoh, dan menyediakan jalan kembali
/// ke katalog.
class _ProductMissing extends StatelessWidget {
  const _ProductMissing({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.search_off_outlined,
      title: 'Alat tidak ditemukan',
      message:
          'Data alat ini tidak ada di katalog. Kembali ke katalog untuk '
          'memilih alat lain.',
      action: OutlinedButton(
        onPressed: onBack,
        child: const Text('Kembali ke katalog'),
      ),
    );
  }
}
