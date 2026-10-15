#!/usr/bin/env node
/**
 * Seed data contoh: `categories`, `products` (arsip), empat `service_rates`,
 * dan `creatives`.
 *
 * Pemakaian:
 *   node scripts/seed_sample_data.mjs                    # pratinjau (default)
 *   node scripts/seed_sample_data.mjs --dry-run          # sama: hanya mencetak rencana
 *   node scripts/seed_sample_data.mjs --apply --service-account=/path/service-account.json
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/service-account.json node scripts/seed_sample_data.mjs --apply
 *   node scripts/seed_sample_data.mjs --apply --replace-sample   # tulis ulang dokumen contoh
 *
 * Sifat:
 * - Menulis ke Firebase **hanya** bila diminta eksplisit lewat `--apply`; tanpa
 *   flag itu skrip berhenti setelah mencetak rencana.
 * - Tidak pernah menimpa pekerjaan yang sudah ada: dokumen milik pemilik
 *   (tanpa penanda `isSample: true`) selalu dilewati, dan dokumen contoh yang
 *   sudah ada juga dilewati kecuali pemanggil memberi `--replace-sample`.
 *   Dengan begitu perubahan manual pemilik tidak hilang karena skrip dijalankan
 *   ulang.
 * - Idempotent: dokumen ditulis pada document ID tetap, sehingga menjalankan
 *   skrip dua kali tidak menggandakan data.
 * - Tidak mengarang data produksi: rate card memakai label
 *   "CONTOH RATE — BELUM FINAL", `startingPrice` ditulis `null`, produk contoh
 *   ditulis **arsip (`isActive: false`)** dengan harga/stok 0 bila konfigurasi
 *   tidak mengisinya dan tanpa foto, sehingga tidak pernah muncul di katalog
 *   pelanggan sebelum pemilik mengisi data aslinya dan mengaktifkannya lewat
 *   dashboard admin. URL (foto/tautan portofolio) hanya ditulis bila
 *   benar-benar diisi pemilik pada `scripts/seed_config.json` dan valid
 *   `http`/`https`.
 * - Setiap dokumen diberi penanda `isSample: true` supaya mudah dicari dan
 *   diganti sebelum dipakai sebagai data produksi.
 *
 * Prasyarat: `firebase-admin` terpasang (`npm --prefix scripts install`) dan
 * kredensial dijalankan dari lingkungan tepercaya. Skrip ini tidak dipakai oleh
 * aplikasi Flutter.
 */

import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

/** Label yang membuat halaman portofolio jujur selama rate final belum ada. */
const SAMPLE_RATE_LABEL = 'CONTOH RATE — BELUM FINAL';

/** Jumlah yang diminta blueprint §6.6 dan §6.7 (dipakai hanya untuk peringatan). */
const EXPECTED_SERVICE_RATE_COUNT = 4;
const EXPECTED_CREATIVE_COUNT = 2;

const scriptDir = path.dirname(fileURLToPath(import.meta.url));

/** Membaca argumen baris perintah; argumen tak dikenal ditolak. */
function parseArguments(argv) {
  const options = {
    writes: false,
    dryRun: false,
    replaceSample: false,
    configPath: path.join(scriptDir, 'seed_config.json'),
    serviceAccountPath: '',
  };
  for (const argument of argv) {
    if (argument === '--apply') {
      options.writes = true;
      continue;
    }
    if (argument === '--dry-run') {
      options.dryRun = true;
      continue;
    }
    if (argument === '--replace-sample') {
      options.replaceSample = true;
      continue;
    }
    if (argument.startsWith('--config=')) {
      options.configPath = path.resolve(argument.slice('--config='.length));
      continue;
    }
    if (argument.startsWith('--service-account=')) {
      options.serviceAccountPath = path.resolve(
        argument.slice('--service-account='.length),
      );
      continue;
    }
    throw new Error(`Argumen tidak dikenal: ${argument}`);
  }
  // Pratinjau adalah perilaku default: menulis ke Firebase harus diminta
  // eksplisit supaya skrip tidak pernah menulis karena salah perintah.
  if (options.writes && options.dryRun) {
    throw new Error('--apply dan --dry-run tidak dapat dipakai bersamaan.');
  }
  return options;
}

/** Membaca dan mem-parse `seed_config.json` dengan pesan gagal yang jelas. */
function readConfig(filePath) {
  let raw;
  try {
    raw = readFileSync(filePath, 'utf8');
  } catch {
    throw new Error(`Berkas konfigurasi tidak dapat dibaca: ${filePath}`);
  }
  try {
    return JSON.parse(raw);
  } catch (error) {
    throw new Error(`JSON pada ${filePath} tidak valid: ${error.message}`);
  }
}

function requireText(value, label) {
  const text = typeof value === 'string' ? value.trim() : '';
  if (text.length === 0) {
    throw new Error(`${label} wajib diisi.`);
  }
  return text;
}

function requireNonNegativeInteger(value, label) {
  if (!Number.isInteger(value) || value < 0) {
    throw new Error(`${label} harus bilangan bulat >= 0.`);
  }
  return value;
}

function optionalTextList(value, label) {
  if (value === undefined || value === null) {
    return [];
  }
  if (!Array.isArray(value)) {
    throw new Error(`${label} harus berupa daftar teks.`);
  }
  return value.map((item, index) => requireText(item, `${label}[${index}]`));
}

/**
 * URL opsional: kosong berarti "belum diisi pemilik" dan tidak menjadi error.
 * Bila diisi, hanya `http`/`https` dengan host yang diterima — sama dengan
 * validasi `ExternalUrl` di aplikasi, sehingga seed tidak pernah memasukkan
 * skema berbahaya seperti `javascript:` atau `file:`.
 */
function optionalHttpUrl(value, label) {
  const text = typeof value === 'string' ? value.trim() : '';
  if (text.length === 0) {
    return '';
  }
  let url;
  try {
    url = new URL(text);
  } catch {
    throw new Error(`${label} bukan URL yang valid: ${text}`);
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    throw new Error(`${label} harus memakai skema http atau https: ${text}`);
  }
  if (url.hostname.length === 0) {
    throw new Error(`${label} harus memuat host: ${text}`);
  }
  return url.toString();
}

/** Daftar URL opsional; kosong berarti "belum diisi pemilik". */
function optionalHttpUrlList(value, label) {
  if (value === undefined || value === null) {
    return [];
  }
  if (!Array.isArray(value)) {
    throw new Error(`${label} harus berupa daftar URL.`);
  }
  return value.map((item, index) => optionalHttpUrl(item, `${label}[${index}]`));
}

function assertUniqueIds(documents, label) {
  const ids = documents.map((document) => document.id);
  if (new Set(ids).size !== ids.length) {
    throw new Error(`Ada id duplikat pada ${label}.`);
  }
}

/** Menyusun dokumen `service_rates` dari konfigurasi. */
function buildServiceRates(config) {
  if (!Array.isArray(config.serviceRates) || config.serviceRates.length === 0) {
    throw new Error('config.serviceRates harus berisi minimal satu layanan.');
  }
  const documents = config.serviceRates.map((entry, index) => {
    const label = `serviceRates[${index}]`;
    return {
      id: requireText(entry.id, `${label}.id`),
      data: {
        title: requireText(entry.title, `${label}.title`),
        description:
          typeof entry.description === 'string' ? entry.description.trim() : '',
        rateLabel:
          typeof entry.rateLabel === 'string' && entry.rateLabel.trim().length > 0
            ? entry.rateLabel.trim()
            : SAMPLE_RATE_LABEL,
        startingPrice:
          typeof entry.startingPrice === 'number' ? entry.startingPrice : null,
        priceUnit:
          typeof entry.priceUnit === 'string' ? entry.priceUnit.trim() : '',
        deliverables: optionalTextList(
          entry.deliverables,
          `${label}.deliverables`,
        ),
        sortOrder: requireNonNegativeInteger(
          entry.sortOrder ?? index + 1,
          `${label}.sortOrder`,
        ),
        isActive: entry.isActive !== false,
        isSample: true,
      },
    };
  });
  assertUniqueIds(documents, 'serviceRates');
  return documents;
}

/** Menyusun dokumen `creatives` dari konfigurasi (boleh belum diisi). */
function buildCreatives(config) {
  if (config.creatives === undefined) {
    return [];
  }
  if (!Array.isArray(config.creatives)) {
    throw new Error('config.creatives harus berupa daftar.');
  }
  const documents = config.creatives.map((entry, index) => {
    const label = `creatives[${index}]`;
    return {
      id: requireText(entry.id, `${label}.id`),
      data: {
        name: requireText(
          entry.name,
          `${label}.name (isi nama kreator sebenarnya di ` +
            'scripts/seed_config.json)',
        ),
        roleTitle:
          typeof entry.roleTitle === 'string' ? entry.roleTitle.trim() : '',
        specialties: optionalTextList(entry.specialties, `${label}.specialties`),
        photoUrl: optionalHttpUrl(entry.photoUrl, `${label}.photoUrl`),
        portfolioUrl: optionalHttpUrl(
          entry.portfolioUrl,
          `${label}.portfolioUrl`,
        ),
        sortOrder: requireNonNegativeInteger(
          entry.sortOrder ?? index + 1,
          `${label}.sortOrder`,
        ),
        isActive: entry.isActive !== false,
        isSample: true,
      },
    };
  });
  assertUniqueIds(documents, 'creatives');
  return documents;
}

/**
 * Kunci ikon yang dikenal aplikasi (`CategoryIconKeys.known` di Dart). Nilai di
 * luar daftar ini akan jatuh ke ikon default di aplikasi, jadi seed menolaknya
 * supaya tidak ada kategori yang tampil tanpa ikon yang dimaksud.
 */
const KNOWN_CATEGORY_ICON_KEYS = [
  'camera',
  'lens',
  'flash',
  'lighting',
  'drone',
  'microphone',
  'mic',
  'stabilizer',
  'tripod',
  'sd_card',
  'accessory',
  'category',
];

/** Satuan periode yang diterima `PriceUnit` di aplikasi ('' = belum ditetapkan). */
const KNOWN_PRICE_UNITS = ['per_day', 'per_session', ''];

/**
 * Menyusun dokumen `categories` dari konfigurasi.
 *
 * Kategori wajib ada: form produk admin tidak dapat menyimpan produk tanpa
 * kategori, dan aplikasi sengaja tidak membuat kategori otomatis.
 */
function buildCategories(config) {
  if (!Array.isArray(config.categories) || config.categories.length === 0) {
    throw new Error(
      'config.categories harus berisi minimal satu kategori. Form produk admin ' +
        'tidak dapat menyimpan produk tanpa kategori.',
    );
  }
  const documents = config.categories.map((entry, index) => {
    const label = `categories[${index}]`;
    const iconKey =
      typeof entry.iconKey === 'string' ? entry.iconKey.trim() : '';
    if (iconKey.length > 0 && !KNOWN_CATEGORY_ICON_KEYS.includes(iconKey)) {
      throw new Error(
        `${label}.iconKey harus salah satu dari: ` +
          `${KNOWN_CATEGORY_ICON_KEYS.join(', ')}.`,
      );
    }
    return {
      id: requireText(entry.id, `${label}.id`),
      data: {
        name: requireText(entry.name, `${label}.name`),
        slug: requireText(entry.slug, `${label}.slug`),
        description:
          typeof entry.description === 'string' ? entry.description.trim() : '',
        iconKey: iconKey.length > 0 ? iconKey : 'category',
        sortOrder: requireNonNegativeInteger(
          entry.sortOrder ?? index + 1,
          `${label}.sortOrder`,
        ),
        isActive: entry.isActive !== false,
        isSample: true,
      },
    };
  });
  assertUniqueIds(documents, 'categories');
  return documents;
}

/**
 * Menyusun dokumen `products` contoh dari konfigurasi (boleh belum diisi).
 *
 * Produk contoh **selalu** ditulis arsip (`isActive: false`) dengan harga dan
 * stok dari konfigurasi (default 0 = belum diisi): katalog hanya menampilkan
 * produk aktif, sehingga data contoh tidak pernah tampil sebagai alat nyata.
 * Karena itu `isActive: true` pada konfigurasi ditolak dengan pesan yang
 * menjelaskan, bukan diabaikan diam-diam: pemilik mengaktifkan produknya dari
 * dashboard admin setelah datanya benar.
 */
function buildProducts(config, categories) {
  if (config.products === undefined) {
    return [];
  }
  if (!Array.isArray(config.products)) {
    throw new Error('config.products harus berupa daftar.');
  }
  const knownCategoryIds = new Set(categories.map((document) => document.id));
  const documents = config.products.map((entry, index) => {
    const label = `products[${index}]`;
    const categoryId = requireText(entry.categoryId, `${label}.categoryId`);
    if (!knownCategoryIds.has(categoryId)) {
      throw new Error(
        `${label}.categoryId "${categoryId}" tidak ada pada config.categories.`,
      );
    }
    const priceUnit =
      typeof entry.priceUnit === 'string' ? entry.priceUnit.trim() : '';
    if (!KNOWN_PRICE_UNITS.includes(priceUnit)) {
      throw new Error(
        `${label}.priceUnit harus kosong, "per_day", atau "per_session".`,
      );
    }
    if (entry.isActive === true) {
      throw new Error(
        `${label}.isActive tidak boleh true: produk contoh harus diarsipkan ` +
          'supaya tidak muncul di katalog pelanggan. Aktifkan produknya dari ' +
          'dashboard admin setelah nama, brand, harga, stok, dan fotonya nyata.',
      );
    }
    return {
      id: requireText(entry.id, `${label}.id`),
      data: {
        name: requireText(entry.name, `${label}.name`),
        description:
          typeof entry.description === 'string' ? entry.description.trim() : '',
        categoryId,
        brand: requireText(entry.brand, `${label}.brand`),
        price: requireNonNegativeInteger(entry.price ?? 0, `${label}.price`),
        priceUnit,
        stockQuantity: requireNonNegativeInteger(
          entry.stockQuantity ?? 0,
          `${label}.stockQuantity`,
        ),
        imageUrls: optionalHttpUrlList(entry.imageUrls, `${label}.imageUrls`),
        // Selalu arsip: katalog pelanggan hanya menampilkan produk aktif.
        isActive: false,
        isSample: true,
      },
    };
  });
  assertUniqueIds(documents, 'products');
  return documents;
}

/**
 * Menulis dokumen yang **belum ada** ke Firestore dan melaporkan hasilnya.
 *
 * Skrip tidak pernah menimpa pekerjaan yang sudah ada: dokumen milik pemilik
 * selalu dilewati, dan dokumen contoh yang sudah ada juga dilewati kecuali
 * pemanggil memberi `--replace-sample` (yang tetap tidak menyentuh dokumen
 * tanpa penanda `isSample: true`). Dengan begitu perubahan manual pemilik pada
 * dokumen contoh tidak hilang hanya karena skrip dijalankan ulang.
 */
async function writeDocuments({
  collectionName,
  documents,
  db,
  FieldValue,
  replaceSample,
}) {
  const result = { created: 0, updated: 0, keptExisting: [], keptOwner: [] };
  for (const document of documents) {
    const reference = db.collection(collectionName).doc(document.id);
    const snapshot = await reference.get();
    if (snapshot.exists) {
      if (snapshot.data().isSample !== true) {
        // Dokumen milik pemilik: seed tidak menimpa data produksi.
        result.keptOwner.push(document.id);
        continue;
      }
      if (!replaceSample) {
        result.keptExisting.push(document.id);
        continue;
      }
      result.updated += 1;
      await reference.set(
        { ...document.data, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      continue;
    }
    result.created += 1;
    await reference.set({
      ...document.data,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  return result;
}

/** Melaporkan hasil penulisan satu collection tanpa membesar-besarkan hasil. */
function reportResult(collectionName, result) {
  console.log(
    `${collectionName.padEnd(13)}: ${result.created} dibuat, ` +
      `${result.updated} diperbarui, ` +
      `${result.keptExisting.length} sudah ada (tidak diubah), ` +
      `${result.keptOwner.length} dilewati (dokumen milik pemilik).`,
  );
  if (result.keptExisting.length > 0) {
    console.log(`  sudah ada     : ${result.keptExisting.join(', ')}`);
  }
  if (result.keptOwner.length > 0) {
    console.log(`  milik pemilik : ${result.keptOwner.join(', ')}`);
  }
}

function describeDocuments(documents) {
  return documents
    .map(
      (document) =>
        `  - ${document.id}: ${document.data.title ?? document.data.name}`,
    )
    .join('\n');
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const config = readConfig(options.configPath);
  const categories = buildCategories(config);
  const products = buildProducts(config, categories);
  const serviceRates = buildServiceRates(config);
  const creatives = buildCreatives(config);

  console.log(`Konfigurasi : ${options.configPath}`);
  console.log(`Kategori    : ${categories.length} dokumen`);
  console.log(describeDocuments(categories));
  console.log(
    `Produk      : ${products.length} dokumen contoh ` +
      '(selalu arsip: isActive false)',
  );
  console.log(
    products.length === 0
      ? '  - (belum ada di konfigurasi: dashboard admin akan kosong sampai ' +
          'produk nyata ditambahkan lewat form admin)'
      : describeDocuments(products),
  );
  console.log(
    `Rate card   : ${serviceRates.length} dokumen (label "${SAMPLE_RATE_LABEL}")`,
  );
  console.log(describeDocuments(serviceRates));
  console.log(`Kreator     : ${creatives.length} dokumen`);
  console.log(
    creatives.length === 0
      ? '  - (belum ada di konfigurasi: halaman portofolio akan menampilkan ' +
          'keadaan belum dikonfigurasi)'
      : describeDocuments(creatives),
  );

  if (serviceRates.length !== EXPECTED_SERVICE_RATE_COUNT) {
    console.warn(
      `Peringatan: blueprint meminta ${EXPECTED_SERVICE_RATE_COUNT} kelompok ` +
        `layanan, konfigurasi memuat ${serviceRates.length}.`,
    );
  }
  if (creatives.length !== EXPECTED_CREATIVE_COUNT) {
    console.warn(
      `Peringatan: blueprint meminta ${EXPECTED_CREATIVE_COUNT} kartu ` +
        `kreator, konfigurasi memuat ${creatives.length}.`,
    );
  }

  if (!options.writes) {
    console.log(
      '\nMode pratinjau: tidak ada dokumen yang ditulis. Tambahkan --apply ' +
        '(beserta kredensial) untuk menulis ke Firebase.',
    );
    console.log(
      'Saat menulis, dokumen yang sudah ada tidak diubah. Tambahkan ' +
        '--replace-sample hanya bila dokumen contoh (isSample: true) memang ' +
        'ingin ditulis ulang.',
    );
    return;
  }

  let adminApp;
  let adminFirestore;
  try {
    adminApp = await import('firebase-admin/app');
    adminFirestore = await import('firebase-admin/firestore');
  } catch {
    throw new Error(
      'Paket `firebase-admin` belum terpasang. Jalankan: ' +
        'npm --prefix scripts install',
    );
  }

  const appOptions = options.serviceAccountPath
    ? { credential: adminApp.cert(options.serviceAccountPath) }
    : { credential: adminApp.applicationDefault() };
  const app =
    adminApp.getApps().length > 0
      ? adminApp.getApps()[0]
      : adminApp.initializeApp(appOptions);
  const db = adminFirestore.getFirestore(app);

  const collections = [
    { name: 'categories', documents: categories },
    { name: 'products', documents: products },
    { name: 'service_rates', documents: serviceRates },
    { name: 'creatives', documents: creatives },
  ];
  const results = [];
  for (const collection of collections) {
    results.push([
      collection.name,
      await writeDocuments({
        collectionName: collection.name,
        documents: collection.documents,
        db,
        FieldValue: adminFirestore.FieldValue,
        replaceSample: options.replaceSample,
      }),
    ]);
  }

  console.log('\nHasil:');
  for (const [collectionName, result] of results) {
    reportResult(collectionName, result);
  }
  console.log(
    '\nLangkah pemilik: buka Dashboard admin, isi nama/brand/harga/stok/foto ' +
      'yang sebenarnya pada produk contoh, lalu aktifkan produk bila sudah ' +
      'layak tampil (produk contoh ditulis arsip sehingga tidak muncul di ' +
      'katalog sebelum diaktifkan). Ganti rateLabel/harga final, isi foto dan ' +
      'tautan portofolio kreator, lalu hapus dokumen ber-penanda isSample bila ' +
      'data asli sudah siap.',
  );
  console.log(
    'Catatan: pemanggilan berikutnya tidak menulis ulang dokumen yang sudah ' +
      'ada. Hapus dokumen ber-penanda isSample atau tambahkan ' +
      '--replace-sample bila memang ingin menulis ulang data contoh.',
  );
}

main().catch((error) => {
  console.error(`\nSeed gagal: ${error.message}`);
  process.exitCode = 1;
});

