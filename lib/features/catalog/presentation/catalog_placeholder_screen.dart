import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_providers.dart';

/// Route tujuan setelah login pada Fase 1.
///
/// Katalog penuh (banner, pencarian, filter, daftar produk) dikerjakan pada
/// Fase 3. Layar ini sengaja hanya menandai route sehingga tidak ada route
/// terproteksi yang dibiarkan tanpa autentikasi, dan tidak berpura-pura
/// menampilkan katalog yang belum ada datanya.
class CatalogPlaceholderScreen extends ConsumerWidget {
  const CatalogPlaceholderScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) {
      return;
    }
    final message = ref.read(authControllerProvider).errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authSessionNotifierProvider);
    final isBusy = ref.watch(authControllerProvider).isSubmitting;

    return Scaffold(
      appBar: AppBar(title: Text(AppConfig.appName)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: session,
          builder: (BuildContext context, Widget? _) {
            final user = session.user;
            final email = user?.email;
            return ListView(
              padding: AppSpacing.screen,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Masuk sebagai',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            user?.preferredName ?? 'Pengguna',
                            style: theme.textTheme.titleMedium,
                          ),
                          if (email != null)
                            Text(email, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: isBusy ? null : () => _signOut(context, ref),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: AppSpacing.xxl),
                const AppEmptyState(
                  icon: Icons.photo_library_outlined,
                  title: 'Katalog belum dibangun',
                  message:
                      'Banner, pencarian, filter, dan daftar produk dikerjakan '
                      'pada fase katalog. Halaman ini hanya menandai route '
                      'setelah login sehingga tidak ada layar terproteksi yang '
                      'bisa dibuka tanpa autentikasi.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
