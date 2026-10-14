import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_form_banner.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/product_image.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/profile_image_picker.dart';
import '../domain/user_profile.dart';
import 'profile_editor.dart';
import 'profile_providers.dart';

/// Halaman Edit Profil (`docs/BLUEPRINT_APLIKASI.md` §4 dan §10).
///
/// Hanya nama, nomor telepon, dan foto yang dapat diubah. Email ditampilkan
/// tetapi tidak dapat diedit karena dikelola Firebase Auth, dan tidak ada field
/// role/claim: role hanya berasal dari custom claim pada fase dashboard.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  /// `true` setelah kolom diisi dari data profil/Akun, supaya ketikan pengguna
  /// tidak tertimpa saat stream profil memperbarui halaman.
  bool _isPrefilled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(profileEditorProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Mengisi kolom sekali dari profil (`users/{uid}`) dan akun Firebase Auth.
  static void _prefill({
    required UserProfile? profile,
    required String accountName,
    required String accountEmail,
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required TextEditingController emailController,
  }) {
    final profileName = profile?.displayName.trim() ?? '';
    nameController.text = profileName.isNotEmpty ? profileName : accountName;
    phoneController.text = profile?.phoneNumber.trim() ?? '';
    emailController.text = accountEmail;
  }

  Future<void> _pickPhoto() =>
      ref.read(profileEditorProvider.notifier).pickPhoto();

  void _clearPickedPhoto() =>
      ref.read(profileEditorProvider.notifier).clearPickedPhoto();

  /// Menyimpan perubahan; layar hanya ditutup bila penyimpanan berhasil.
  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final uid = ref.read(authSessionNotifierProvider).user?.uid ?? '';
    final previousPhotoUrl = ref.read(userProfileProvider(uid)).value?.photoUrl;

    final saved = await ref
        .read(profileEditorProvider.notifier)
        .save(
          uid: uid,
          displayName: _nameController.text,
          phoneNumber: _phoneController.text,
          previousPhotoUrl: previousPhotoUrl,
        );
    if (!mounted || !saved) {
      // Kegagalan tetap tampil pada banner form; layar tidak ditutup supaya
      // pengguna dapat memperbaiki dan mencoba lagi.
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Profil berhasil disimpan.')),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionNotifierProvider);
    final user = session.user;
    final uid = user?.uid.trim() ?? '';
    final profileAsync = uid.isEmpty
        ? const AsyncValue<UserProfile?>.data(null)
        : ref.watch(userProfileProvider(uid));
    final editorState = ref.watch(profileEditorProvider);
    final profile = profileAsync.value;

    // Pengisian awal dilakukan sekali, setelah data profil pertama kali
    // tersedia; sesudah itu ketikan pengguna tidak pernah ditimpa.
    if (!_isPrefilled && profileAsync.hasValue) {
      _isPrefilled = true;
      _prefill(
        profile: profile,
        accountName: user?.displayName?.trim() ?? '',
        accountEmail: user?.email ?? '',
        nameController: _nameController,
        phoneController: _phoneController,
        emailController: _emailController,
      );
    }

    return AppScaffold(
      title: 'Edit Profil',
      leading: BackButton(onPressed: _back),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxFormWidth,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (profileAsync.hasError)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.lg),
                      child: AppFormBanner.notice(
                        'Data profil terakhir belum dapat dibaca, sehingga '
                        'kolom di bawah mungkin kosong. Perubahan yang Anda '
                        'simpan tetap ditulis ke database.',
                      ),
                    ),
                  _PhotoField(
                    existingPhotoUrl: profile?.photoUrl.trim() ?? '',
                    pickedImage: editorState.pickedImage,
                    isBusy: editorState.isBusy,
                    onPick: _pickPhoto,
                    onClear: _clearPickedPhoto,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _nameController,
                    label: 'Nama',
                    enabled: !editorState.isSaving,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: Validators.displayName,
                  ),
                  const SizedBox(height: AppSpacing.fieldGap),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Nomor telepon',
                    enabled: !editorState.isSaving,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    helperText:
                        'Opsional. Nomor ini membantu pemilik menghubungi Anda '
                        'soal sewa.',
                    validator: Validators.phoneNumber,
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: AppSpacing.fieldGap),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email akun',
                    enabled: false,
                    helperText:
                        'Email mengikuti akun Firebase Auth dan tidak dapat '
                        'diubah di sini.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (editorState.errorMessage != null) ...<Widget>[
                    AppFormBanner.error(editorState.errorMessage!),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  AppPrimaryButton(
                    label: 'Simpan perubahan',
                    isLoading: editorState.isSaving,
                    onPressed: editorState.isBusy ? null : _save,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: editorState.isBusy ? null : _back,
                    child: const Text('Batal'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kembali tanpa menyimpan; tetap bekerja bila route tidak dapat di-pop.
  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.profile);
  }
}

/// Bagian foto pada form edit profil: pratinjau, pilih, dan batalkan.
///
/// Pratinjau memakai byte berkas yang dipilih (bukan path berkas) supaya juga
/// tampil pada web. Selama belum disimpan, pilihan lokal ini hanya pratinjau:
/// foto lama di database tidak disentuh (blueprint §10).
class _PhotoField extends StatelessWidget {
  const _PhotoField({
    required this.existingPhotoUrl,
    required this.pickedImage,
    required this.isBusy,
    required this.onPick,
    required this.onClear,
  });

  /// URL foto yang tersimpan pada `users/{uid}.photoUrl`.
  final String existingPhotoUrl;

  /// Foto baru yang sudah divalidasi tetapi belum diunggah.
  final PickedProfileImage? pickedImage;

  /// `true` selama pemilihan/penyimpanan berjalan.
  final bool isBusy;

  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = pickedImage;
    final hasExisting = existingPhotoUrl.trim().isNotEmpty;
    final note = picked != null
        ? 'Pratinjau foto baru. Simpan perubahan untuk mengunggahnya.'
        : (hasExisting
              ? 'Foto saat ini. Pilih foto baru bila ingin menggantinya.'
              : 'Foto belum diisi. Pilih foto untuk dipakai pada profil.');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipOval(
            child: SizedBox(
              width: 96,
              height: 96,
              child: picked == null
                  ? ProductImage(
                      imageUrl: existingPhotoUrl,
                      semanticLabel: 'Foto profil saat ini',
                    )
                  : Image.memory(
                      picked.bytes,
                      fit: BoxFit.cover,
                      semanticLabel: 'Pratinjau foto profil baru',
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Foto profil', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(note, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : onPick,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(picked == null ? 'Pilih foto' : 'Ganti foto'),
                    ),
                    if (picked != null)
                      TextButton(
                        onPressed: isBusy ? null : onClear,
                        child: const Text('Batalkan pilihan'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
