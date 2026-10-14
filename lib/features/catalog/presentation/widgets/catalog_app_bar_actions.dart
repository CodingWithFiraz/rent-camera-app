import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../cart/presentation/cart_providers.dart';

/// Aksi app bar katalog: penanda keranjang dan ikon profil.
///
/// Dipakai halaman katalog maupun halaman detail produk agar susunan app bar
/// konsisten. Angka pada penanda berasal dari `cartItemCountProvider` (data
/// keranjang di Firestore); penanda disembunyikan saat keranjang kosong, jadi
/// tidak ada angka nol yang menyesatkan.
///
/// Halaman keranjang dan profil penuhnya baru ada pada fase berikutnya; route
/// yang dibuka dari sini menampilkan keterangan fase secara jujur, bukan layar
/// kosong atau data contoh.
class CatalogAppBarActions extends ConsumerWidget {
  const CatalogAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionNotifierProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (BuildContext context, Widget? _) {
        final uid = session.user?.uid ?? '';
        final itemCount = ref.watch(cartItemCountProvider(uid));
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: itemCount > 0
                  ? 'Keranjang, $itemCount item'
                  : 'Keranjang masih kosong',
              onPressed: () => context.push(AppRoutes.cart),
              icon: Badge.count(
                count: itemCount,
                isLabelVisible: itemCount > 0,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
            IconButton(
              tooltip: 'Profil',
              onPressed: () => context.push(AppRoutes.profile),
              icon: const Icon(Icons.person_outline),
            ),
          ],
        );
      },
    );
  }
}
