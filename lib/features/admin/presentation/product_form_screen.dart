import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/repository_error_mapper.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_form_banner.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../catalog/domain/category.dart';
import '../../catalog/domain/price_unit.dart';
import '../../catalog/domain/product.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../domain/admin_access.dart';
import '../domain/product_draft.dart';
import 'admin_providers.dart';
import 'widgets/admin_product_image_field.dart';

/// Form tambah/edit produk (`docs/BLUEPRINT_APLIKASI.md` §8).
///
/// Hanya terbuka untuk akun dengan custom claim `admin: true`. Foto baru
/// diunggah saat produk disimpan; bila unggahan gagal, dokumen produk tidak
/// disentuh sama sekali sehingga foto lama tetap tampil.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  /// Document ID produk yang diedit; `null` berarti form tambah produk baru.
  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  /// Document ID untuk produk baru, dipesan sekali per sesi form supaya foto
  /// diunggah ke folder `products/{productId}/**` yang benar.
  late final String _newProductId;

  String? _categoryId;
  PriceUnit _priceUnit = PriceUnit.unspecified;
  bool _isActive = true;
  List<String> _existingImageUrls = const <String>[];

  /// `true` setelah kolom diisi dari dokumen produk, supaya ketikan admin tidak
  /// tertimpa saat stream produk memperbarui halaman.
  bool _isPrefilled = false;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _newProductId = ref
        .read(adminProductFormControllerProvider.notifier)
        .reserveNewProductId();
    // Catatan harga & periode ikut berubah saat admin mengetik, sehingga pesan
    // "harga belum diisi"/"satuan belum dipilih" tidak menunggu tombol simpan.
    _priceController.addListener(_handlePriceChanged);
    _imageUrlController.addListener(_handlePriceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(adminProductFormControllerProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _priceController.removeListener(_handlePriceChanged);
    _imageUrlController.removeListener(_handlePriceChanged);
    _imageUrlController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handlePriceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(adminAccessNotifierProvider);

    return AppScaffold(
      title: _isEditing ? 'Edit Produk' : 'Tambah Alat',
      leading: IconButton(
        tooltip: 'Kembali ke dashboard',
        icon: const Icon(Icons.arrow_back),
        onPressed: _goToDashboard,
      ),
      body: ListenableBuilder(
        listenable: access,
        builder: (BuildContext context, Widget? _) => switch (access.status) {
          AdminAccessStatus.unknown => const AppLoading(),
          AdminAccessStatus.denied => const AppErrorState(
            title: 'Akses admin diperlukan',
            message:
                'Akun ini tidak memiliki custom claim "admin: true", sehingga '
                'form produk tidak dapat dibuka.',
          ),
          AdminAccessStatus.granted => _buildBody(),
        },
      ),
    );
  }

  /// Isi layar: memuat dokumen produk (mode edit) atau langsung menampilkan form.
  Widget _buildBody() {
    final productId = widget.productId;
    if (productId == null) {
      return _buildForm();
    }

    final productAsync = ref.watch(productByIdProvider(productId));
    return productAsync.when(
      loading: () => const AppLoading(),
      error: (Object error, StackTrace stackTrace) => AppErrorState(
        title: 'Produk tidak dapat dimuat',
        message: repositoryErrorMessageFor(error, entityLabel: 'produk'),
        onRetry: () => ref.invalidate(productByIdProvider(productId)),
      ),
      data: (Product? product) {
        if (product == null) {
          return const AppEmptyState(
            icon: Icons.search_off_outlined,
            title: 'Produk tidak ditemukan',
            message:
                'Dokumen produk sudah tidak ada. Kembali ke dashboard untuk '
                'memilih produk lain.',
          );
        }
        _prefillFrom(product);
        return _buildForm();
      },
    );
  }

  /// Mengisi kolom form sekali dari dokumen produk yang sudah ada.
  void _prefillFrom(Product product) {
    if (_isPrefilled) {
      return;
    }
    _isPrefilled = true;
    _nameController.text = product.name;
    _brandController.text = product.brand;
    _priceController.text = product.price.toString();
    _stockController.text = product.stockQuantity.toString();
    _descriptionController.text = product.description;
    _categoryId = product.categoryId;
    _priceUnit = product.priceUnit;
    _isActive = product.isActive;
    _existingImageUrls = product.imageUrls;
    _imageUrlController.text = product.imageUrls.join(', ');
  }

  void _goToDashboard() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.admin);
  }

  /// Menyusun draft dari nilai form, lalu menyimpannya lewat controller.
  ///
  /// Layar hanya ditutup bila penyimpanan benar-benar berhasil; kegagalan
  /// ditampilkan pada banner form dan tidak pernah dilaporkan sebagai sukses.
  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final categoryId = _categoryId;
    final price = ProductDraftValidation.tryParseInteger(_priceController.text);
    final stock = ProductDraftValidation.tryParseInteger(_stockController.text);
    if (categoryId == null ||
        categoryId.isEmpty ||
        price == null ||
        stock == null) {
      // Validator form sudah menolak nilai ini; penjagaan kedua supaya tidak ada
      // nilai setengah lengkap yang sampai ke repository.
      return;
    }

    final enteredImageUrls = _imageUrlController.text
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final draft = ProductDraft(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: categoryId,
      brand: _brandController.text.trim(),
      price: price,
      priceUnit: _priceUnit,
      stockQuantity: stock,
      imageUrls: enteredImageUrls,
      isActive: _isActive,
    );

    final messenger = ScaffoldMessenger.of(context);
    final savedProductId = widget.productId ?? _newProductId;
    final saved = await ref
        .read(adminProductFormControllerProvider.notifier)
        .save(
          productId: savedProductId,
          isNew: !_isEditing,
          draft: draft,
          existingImageUrls: enteredImageUrls,
        );
    if (!saved) {
      return;
    }

    ref.invalidate(productByIdProvider(savedProductId));
    ref.invalidate(activeProductsProvider);

    final successMessage = _isActive
        ? 'Produk berhasil disimpan dan tampil di katalog utama.'
        : 'Produk berhasil disimpan sebagai arsip (tidak tampil di katalog utama).';
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    if (!mounted) {
      return;
    }
    context.go(AppRoutes.admin);
  }

  Widget _buildForm() {
    final theme = Theme.of(context);
    final formState = ref.watch(adminProductFormControllerProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final categories = categoriesAsync.value ?? const <Category>[];
    final price = ProductDraftValidation.tryParseInteger(_priceController.text);
    final isBusy = formState.isBusy;

    return Form(
      key: _formKey,
      child: ListView(
        padding: AppSpacing.screen,
        children: <Widget>[
          if (formState.errorMessage case final String message) ...<Widget>[
            AppFormBanner.error(message),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (formState.noticeMessage case final String message) ...<Widget>[
            AppFormBanner.notice(message),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('Informasi alat', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _nameController,
            label: 'Nama alat',
            enabled: !isBusy,
            textCapitalization: TextCapitalization.words,
            validator: ProductDraftValidation.name,
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          AppTextField(
            controller: _brandController,
            label: 'Brand',
            enabled: !isBusy,
            textCapitalization: TextCapitalization.words,
            validator: ProductDraftValidation.brand,
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          AppTextField(
            controller: _descriptionController,
            label: 'Deskripsi',
            enabled: !isBusy,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            validator: ProductDraftValidation.description,
            helperText: 'Opsional. Jelaskan kondisi dan kelengkapan alat.',
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          _categoryField(
            categories: categories,
            categoriesAsync: categoriesAsync,
            isBusy: isBusy,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Harga & stok', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _priceController,
            label: 'Harga (Rupiah)',
            enabled: !isBusy,
            keyboardType: TextInputType.number,
            validator: ProductDraftValidation.price,
            helperText: 'Angka saja, contoh 150000.',
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          _priceUnitField(isBusy: isBusy),
          const SizedBox(height: AppSpacing.fieldGap),
          AppTextField(
            controller: _stockController,
            label: 'Stok',
            enabled: !isBusy,
            keyboardType: TextInputType.number,
            validator: ProductDraftValidation.stockQuantity,
            helperText: 'Jumlah unit yang tersedia, contoh 2.',
          ),
          if (price != null && price == 0) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            const AppFormBanner.notice(
              'Harga 0 akan tampil di katalog sebagai "Harga belum diisi", '
              'bukan sewa gratis.',
            ),
          ],
          if (price != null &&
              price > 0 &&
              _priceUnit == PriceUnit.unspecified) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            const AppFormBanner.notice(
              'Satuan periode belum dipilih, sehingga label "/hari" atau '
              '"/sesi" tidak akan tampil di katalog. Pilih satuan yang '
              'benar-benar dipakai.',
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isActive,
            onChanged: isBusy
                ? null
                : (bool value) => setState(() => _isActive = value),
            title: Text(
              _isActive
                  ? 'Aktif (Tampil di Katalog / Halaman Utama)'
                  : 'Arsip (Tidak Tampil di Katalog)',
            ),
            subtitle: Text(
              _isActive
                  ? 'Produk langsung muncul di katalog utama dan dapat disewa oleh pelanggan.'
                  : 'Produk disimpan sebagai arsip dan TIDAK muncul di katalog utama (dapat diaktifkan nanti dari dashboard).',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AdminProductImageField(
            controller: _imageUrlController,
            isBusy: isBusy,
            existingImageUrls: _existingImageUrls,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: _isEditing ? 'Simpan perubahan' : 'Tambah produk',
            icon: Icons.save_outlined,
            isLoading: formState.isSaving,
            // Tanpa kategori tidak ada produk yang dapat disimpan; tombol
            // dinonaktifkan dan alasannya dijelaskan pada field kategori.
            onPressed: categories.isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }

  /// Field kategori: hanya kategori nyata pada `categories` yang dapat dipilih.
  Widget _categoryField({
    required List<Category> categories,
    required AsyncValue<List<Category>> categoriesAsync,
    required bool isBusy,
  }) {
    // Kategori produk yang diedit bisa saja sudah dinonaktifkan/dihapus dari
    // daftar aktif; ID-nya tetap ditampilkan apa adanya supaya admin tidak
    // dipaksa memilih kategori yang salah tanpa sadar.
    final selected = _categoryId;
    final isUnknownSelection =
        selected != null &&
        !categories.any((Category item) => item.id == selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Kategori',
            helperText: categories.isEmpty
                ? 'Belum ada kategori yang dapat dipilih.'
                : null,
          ),
          hint: Text(
            categories.isEmpty ? 'Kategori belum dibuat' : 'Pilih kategori',
          ),
          items: <DropdownMenuItem<String>>[
            for (final category in categories)
              DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name, overflow: TextOverflow.ellipsis),
              ),
            if (isUnknownSelection)
              DropdownMenuItem<String>(
                value: selected,
                child: Text(
                  '$selected (kategori tidak ditemukan)',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: isBusy || categories.isEmpty
              ? null
              : (String? value) => setState(() => _categoryId = value),
          validator: ProductDraftValidation.categoryId,
        ),
        if (!categoriesAsync.isLoading && categories.isEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          const AppFormBanner.notice(
            'Produk memerlukan kategori. Buat dokumen pada collection '
            '"categories" lebih dulu (lihat SETUP.md); aplikasi sengaja tidak '
            'membuat kategori otomatis.',
          ),
        ],
        if (categoriesAsync.hasError) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppFormBanner.error(
            repositoryErrorMessageFor(
              categoriesAsync.error,
              entityLabel: 'kategori',
            ),
          ),
        ],
      ],
    );
  }

  /// Field satuan periode harga.
  ///
  /// Pilihan "Belum ditetapkan" disediakan supaya aplikasi tidak mengarang
  /// periode: katalog hanya menampilkan label periode bila dokumen produk
  /// benar-benar menetapkannya.
  Widget _priceUnitField({required bool isBusy}) {
    return DropdownButtonFormField<PriceUnit>(
      initialValue: _priceUnit,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Satuan periode'),
      items: const <DropdownMenuItem<PriceUnit>>[
        DropdownMenuItem<PriceUnit>(
          value: PriceUnit.unspecified,
          child: Text('Belum ditetapkan'),
        ),
        DropdownMenuItem<PriceUnit>(
          value: PriceUnit.perDay,
          child: Text('Per hari'),
        ),
        DropdownMenuItem<PriceUnit>(
          value: PriceUnit.perSession,
          child: Text('Per sesi'),
        ),
      ],
      onChanged: isBusy
          ? null
          : (PriceUnit? value) =>
                setState(() => _priceUnit = value ?? PriceUnit.unspecified),
    );
  }
}
