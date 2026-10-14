import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../catalog/presentation/widgets/catalog_app_bar_actions.dart';
import '../../catalog/presentation/widgets/catalog_section_notice.dart';
import '../domain/user_profile.dart';
import 'profile_providers.dart';

/// Halaman Profil (`docs/BLUEPRINT_APLIKASI.md` §4 dan §6.3).
///
/// Menampilkan foto, nama, email (dari Firebase Auth, bukan dari dokumen
/// profil), nomor telepon, tombol Edit Profil, dan Logout. Halaman ini tidak
/// menampilkan atau mengubah role/claim: role admin hanya dibaca dari custom
/// claim pada fase dashboard.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionNotifierProvider);

    return AppScaffold(
      title: 'Profil',
      leading: BackButton(onPressed: () => _backToCatalog(context)),
      actions: const <Widget>[CatalogAppBarActions()],
      body: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? _) {
          final user = session.user;
          final uid = user?.uid.trim() ?? '';
          return uid.isEmpty
              ? const _SignedOutState()
              : _ProfileBody(uid: uid, user: user!);
        },
      ),
    );
  }

  /// Kembali ke katalog; tetap bekerja bila halaman dibuka tanpa riwayat
  /// navigasi (mis. tautan langsung) sehingga `pop` tidak mungkin.
  static void _backToCatalog(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.catalog);
  }
}

/// Keadaan saat belum ada sesi login yang dapat menampilkan profil.
class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.lock_outline,
      title: 'Masuk untuk membuka profil',
      message:
          'Profil disimpan per akun, sehingga hanya dapat dibuka setelah '
          'login. Masuk kembali untuk melihat dan mengubah profil.',
      action: OutlinedButton(
        onPressed: () => context.go(AppRoutes.login),
        child: const Text('Masuk'),
      ),
    );
  }
}

/// Isi halaman profil: state loading/error profil, lalu rinciannya.
class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.uid, required this.user});

  final String uid;
  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));

    if (profileAsync.isLoading && !profileAsync.hasValue) {
      return const AppLoading(label: 'Memuat profil…');
    }
    if (profileAsync.hasError && !profileAsync.hasValue) {
      return AppErrorState(
        title: 'Profil belum dapat dimuat',
        message: repositoryErrorMessageFor(
          profileAsync.error,
          entityLabel: 'profil',
        ),
        onRetry: () => ref.invalidate(userProfileProvider(uid)),
      );
    }

    final profile = profileAsync.value;
    return ListView(
      padding: AppSpacing.screen,
      children: <Widget>[
        if (profileAsync.hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: CatalogSectionNotice(
              isError: true,
              message: repositoryErrorMessageFor(
                profileAsync.error,
                entityLabel: 'profil',
              ),
              onRetry: () => ref.invalidate(userProfileProvider(uid)),
            ),
          ),
        if (profile == null)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            child: CatalogSectionNotice(
              message:
                  'Dokumen profil belum ada di database. Nama dari akun tetap '
                  'ditampilkan; lengkapi data lewat Edit Profil untuk '
                  'membuatnya.',
            ),
          ),
        Center(
          child: ClipOval(
            child: SizedBox(
              width: 96,
              height: 96,
              child: ProductImage(
                imageUrl: _photoUrl(profile, user),
                semanticLabel: 'Foto profil ${_displayName(profile, user)}',
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _displayName(profile, user),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          user.email ?? 'Email tidak tersedia pada akun ini.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        _ProfileDetailCard(
          phoneNumber: profile?.phoneNumber ?? '',
          hasProfileDocument: profile != null,
          updatedAt: profile?.updatedAt,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.editProfile),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit Profil'),
        ),
        const SizedBox(height: AppSpacing.md),
        _SignOutButton(),
      ],
    );
  }

  /// Foto profil: dokumen profil lebih dulu, lalu foto akun Firebase Auth.
  static String _photoUrl(UserProfile? profile, AuthUser user) {
    final fromProfile = profile?.photoUrl.trim() ?? '';
    if (fromProfile.isNotEmpty) {
      return fromProfile;
    }
    return user.photoUrl?.trim() ?? '';
  }

  /// Nama tampilan: dokumen profil, lalu nama akun, terakhir default netral.
  static String _displayName(UserProfile? profile, AuthUser user) {
    final fromProfile = profile?.displayName.trim() ?? '';
    if (fromProfile.isNotEmpty) {
      return fromProfile;
    }
    final fromAccount = user.displayName?.trim() ?? '';
    return fromAccount.isNotEmpty ? fromAccount : 'Pengguna';
  }
}

/// Ringkasan data profil yang boleh diubah pengguna.
class _ProfileDetailCard extends StatelessWidget {
  const _ProfileDetailCard({
    required this.phoneNumber,
    required this.hasProfileDocument,
    this.updatedAt,
  });

  final String phoneNumber;
  final bool hasProfileDocument;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = phoneNumber.trim();
    final updated = updatedAt;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Nomor telepon', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            phone.isEmpty ? 'Belum diisi' : phone,
            style: theme.textTheme.bodyLarge,
          ),
          if (!hasProfileDocument) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Data profil belum tersimpan di database, sehingga nama dan '
              'nomor dari akun saja yang dapat ditampilkan.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (updated != null) ...<Widget>[
            const Divider(),
            Text('Terakhir diperbarui', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(_formatDate(updated), style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  /// Tanggal lokal ringkas tanpa dependensi locale tambahan.
  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}-${two(local.month)}-${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

/// Tombol keluar dengan state pengiriman dan pesan kegagalan yang jujur.
class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(authControllerProvider).isSubmitting;
    return OutlinedButton(
      onPressed: isSubmitting ? null : () => _signOut(context, ref),
      child: Text(isSubmitting ? 'Keluar…' : 'Keluar'),
    );
  }

  /// Keluar dari akun; keberhasilan dipindahkan oleh route guard ke halaman
  /// login, sedangkan kegagalan dilaporkan lewat snack bar.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(authControllerProvider.notifier).signOut();
    final message = ref.read(authControllerProvider).errorMessage;
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
