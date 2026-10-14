#!/usr/bin/env node
/**
 * Seed data contoh Fase 5: empat `service_rates` dan `creatives`.
 *
 * Pemakaian:
 *   node scripts/seed_sample_data.mjs --dry-run
 *   node scripts/seed_sample_data.mjs --service-account=/path/service-account.json
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/service-account.json node scripts/seed_sample_data.mjs
 *
 * Sifat:
 * - Idempotent: dokumen ditulis dengan `set(..., { merge: true })` pada document
 *   ID tetap, sehingga menjalankan skrip dua kali tidak menggandakan data.
 * - Tidak mengarang data produksi: rate card memakai label
 *   "CONTOH RATE — BELUM FINAL", `startingPrice` ditulis `null`, dan URL
 *   (foto/tautan portofolio) hanya ditulis bila benar-benar diisi pemilik pada
 *   `scripts/seed_config.json` dan valid `http`/`https`.
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
    dryRun: false,
    configPath: path.join(scriptDir, 'seed_config.json'),
    serviceAccountPath: '',
  };
  for (const argument of argv) {
    if (argument === '--dry-run') {
      options.dryRun = true;
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

/** Menulis dokumen secara idempotent, lalu melaporkan berapa yang dibuat. */
async function writeDocuments({ collectionName, documents, db, FieldValue }) {
  let created = 0;
  let updated = 0;
  for (const document of documents) {
    const reference = db.collection(collectionName).doc(document.id);
    const snapshot = await reference.get();
    const data = {
      ...document.data,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (snapshot.exists) {
      updated += 1;
    } else {
      data.createdAt = FieldValue.serverTimestamp();
      created += 1;
    }
    await reference.set(data, { merge: true });
  }
  return { created, updated };
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
  const serviceRates = buildServiceRates(config);
  const creatives = buildCreatives(config);

  console.log(`Konfigurasi : ${options.configPath}`);
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

  if (options.dryRun) {
    console.log('\nMode --dry-run: tidak ada dokumen yang ditulis.');
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

  const rateResult = await writeDocuments({
    collectionName: 'service_rates',
    documents: serviceRates,
    db,
    FieldValue: adminFirestore.FieldValue,
  });
  const creativeResult = await writeDocuments({
    collectionName: 'creatives',
    documents: creatives,
    db,
    FieldValue: adminFirestore.FieldValue,
  });

  console.log(
    `\nservice_rates: ${rateResult.created} dibuat, ` +
      `${rateResult.updated} diperbarui.`,
  );
  console.log(
    `creatives    : ${creativeResult.created} dibuat, ` +
      `${creativeResult.updated} diperbarui.`,
  );
  console.log(
    '\nLangkah pemilik: ganti rateLabel/harga final, isi foto dan tautan ' +
      'portofolio kreator, lalu hapus dokumen ber-penanda isSample bila data ' +
      'asli sudah siap.',
  );
}

main().catch((error) => {
  console.error(`\nSeed gagal: ${error.message}`);
  process.exitCode = 1;
});

