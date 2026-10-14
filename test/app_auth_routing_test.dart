import 'dart:async';

import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_camera_app/app.dart';
import 'package:rent_camera_app/core/firebase/firebase_bootstrap.dart';
import 'package:rent_camera_app/core/firebase/firebase_providers.dart';
import 'package:rent_camera_app/features/auth/domain/auth_user.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_providers.dart';
import 'package:rent_camera_app/features/auth/presentation/auth_session_notifier.dart';
import 'package:rent_camera_app/features/catalog/domain/banner.dart';
import 'package:rent_camera_app/features/catalog/domain/banner_selection.dart';
import 'package:rent_camera_app/features/catalog/domain/category.dart';
import 'package:rent_camera_app/features/catalog/domain/product.dart';
import 'package:rent_camera_app/features/catalog/presentation/catalog_providers.dart';
import 'package:rent_camera_app/features/catalog/presentation/catalog_screen.dart';

/// Test alur aplikasi: bootstrap Firebase dan route guard autentikasi.
///
/// Test ini tidak membutuhkan kredensial: `FirebaseAuth` tidak pernah
/// diinstansiasi karena sesi disuntikkan lewat stream palsu, dan data katalog
/// diisi lewat override provider sehingga tidak ada permintaan Firestore.
void main() {
  /// Override data katalog dengan daftar kosong.
  ///
  /// Route katalog kini menampilkan halaman katalog sungguhan; tanpa override
  /// ini test akan menyentuh Firestore yang tidak tersedia pada test.
  List<Override> catalogOverrides() => <Override>[
    activeCategoriesProvider.overrideWith(
      (Ref ref) => Stream<List<Category>>.value(const <Category>[]),
    ),
    catalogBannerSelectionProvider.overrideWithValue(
      AsyncValue<BannerSelection>.data(BannerSelection.from(const <Banner>[])),
    ),
    catalogProductsProvider.overrideWithValue(
      const AsyncValue<List<Product>>.data(<Product>[]),
    ),
  ];
  testWidgets(
    'Firebase belum dikonfigurasi: layar setup ditampilkan, bukan form',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseBootstrapProvider.overrideWithValue(
              const FirebaseBootstrapStatus.notConfigured('no-app'),
            ),
          ],
          child: const RentCameraApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Firebase belum dikonfigurasi'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    },
  );

  testWidgets('belum login: pengguna diarahkan ke layar login', (
    WidgetTester tester,
  ) async {
    final controller = StreamController<AuthUser?>();
    addTearDown(controller.close);
    final session = AuthSessionNotifier(authStateChanges: controller.stream);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseBootstrapProvider.overrideWithValue(
            const FirebaseBootstrapStatus.configured(),
          ),
          authSessionNotifierProvider.overrideWithValue(session),
        ],
        child: const RentCameraApp(),
      ),
    );

    controller.add(null);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);
    expect(find.byType(CatalogScreen), findsNothing);
  });

  testWidgets('sudah login: pengguna diarahkan ke route katalog', (
    WidgetTester tester,
  ) async {
    final controller = StreamController<AuthUser?>();
    addTearDown(controller.close);
    final session = AuthSessionNotifier(authStateChanges: controller.stream);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          firebaseBootstrapProvider.overrideWithValue(
            const FirebaseBootstrapStatus.configured(),
          ),
          authSessionNotifierProvider.overrideWithValue(session),
          ...catalogOverrides(),
        ],
        child: const RentCameraApp(),
      ),
    );

    controller.add(const AuthUser(uid: 'uid-1', displayName: 'Nama Uji'));
    await tester.pumpAndSettle();

    expect(find.byType(CatalogScreen), findsOneWidget);
    expect(find.text('Katalog masih kosong'), findsOneWidget);
    expect(find.text('Katalog belum dibangun'), findsNothing);
  });
}
