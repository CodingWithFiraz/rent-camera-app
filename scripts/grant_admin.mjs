#!/usr/bin/env node
/**
 * Memberi atau mencabut custom claim admin `{ admin: true }` pada akun Firebase
 * Authentication (`docs/BLUEPRINT_APLIKASI.md` §9).
 *
 * Pemakaian (hanya dari lingkungan tepercaya milik pemilik project). Aksi wajib
 * dipilih eksplisit — `--grant` atau `--revoke` — dan tidak ada aksi default,
 * supaya claim admin tidak pernah berubah karena perintah yang tidak lengkap:
 *   node scripts/grant_admin.mjs --dry-run --grant --email=<email-admin>
 *   node scripts/grant_admin.mjs --grant --email=<email-admin> --service-account=/path/service-account.json
 *   ADMIN_EMAIL=<email-admin> node scripts/grant_admin.mjs --grant --uid=<uid>
 *   node scripts/grant_admin.mjs --revoke --email=<email-admin> --service-account=/path/service-account.json
 *
 * Alasan keberadaan skrip ini:
 * - Role admin aplikasi **hanya** berasal dari custom claim Firebase Auth, bukan
 *   dari field dokumen Firestore. Claim tidak dapat diberikan dari aplikasi
 *   Flutter, sehingga pemilik perlu alat di lingkungan tepercaya.
 * - Kredensial tidak pernah ditulis di repo: diambil dari
 *   `--service-account=<berkas>` atau `GOOGLE_APPLICATION_CREDENTIALS`.
 * - Skrip tidak memakai password apa pun. Alias login `admin` di aplikasi
 *   hanyalah nama pengguna yang dipetakan ke email admin; password tetap
 *   divalidasi Firebase Authentication. Tidak ada password `pass` atau bypass
 *   autentikasi di sini.
 * - Claim lain pada akun dipertahankan; hanya field `admin` yang diubah (dan
 *   dihapus saat `--revoke`), sehingga integrasi lain tidak ikut rusak.
 *
 * Setelah claim diberikan, aplikasi membacanya dengan `forceRefresh: true`,
 * jadi pengguna hanya perlu login ulang sebelum menu Dashboard Admin muncul.
 *
 * Prasyarat: `firebase-admin` terpasang (`npm --prefix scripts install`).
 */

import { existsSync } from 'node:fs';
import path from 'node:path';

const ADMIN_CLAIM_KEY = 'admin';

/** Membaca argumen baris perintah; argumen tak dikenal ditolak. */
function parseArguments(argv) {
  const options = {
    dryRun: false,
    grant: false,
    revoke: false,
    uid: '',
    uidProvided: false,
    email: '',
    emailProvided: false,
    serviceAccountPath: '',
  };
  for (const argument of argv) {
    if (argument === '--dry-run') {
      options.dryRun = true;
      continue;
    }
    if (argument === '--grant') {
      options.grant = true;
      continue;
    }
    if (argument === '--revoke') {
      options.revoke = true;
      continue;
    }
    if (argument.startsWith('--uid=')) {
      options.uid = argument.slice('--uid='.length).trim();
      options.uidProvided = true;
      continue;
    }
    if (argument.startsWith('--email=')) {
      options.email = argument.slice('--email='.length).trim();
      options.emailProvided = true;
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

  // Email admin dapat juga diberikan lewat variabel lingkungan supaya perintah
  // yang dijalankan berulang tidak perlu memuat alamat email di shell history.
  if (options.email.length === 0) {
    options.email = (process.env.ADMIN_EMAIL ?? '').trim();
  }
  return options;
}

/** Memvalidasi kombinasi argumen sebelum menyentuh Firebase. */
function validateOptions(options) {
  if (options.grant && options.revoke) {
    throw new Error('Pilih salah satu aksi: --grant atau --revoke.');
  }
  if (!options.grant && !options.revoke) {
    throw new Error(
      'Tentukan aksi secara eksplisit: --grant untuk memberi claim admin, ' +
        'atau --revoke untuk mencabutnya. Tidak ada aksi default supaya claim ' +
        'admin tidak berubah karena perintah yang tidak lengkap.',
    );
  }
  if (options.uidProvided && options.emailProvided) {
    throw new Error(
      'Pilih salah satu target: --uid=<uid> atau --email=<email>, bukan keduanya.',
    );
  }
  if (options.uid.length === 0 && options.email.length === 0) {
    throw new Error(
      'Tentukan akun admin: --uid=<uid> atau --email=<email> ' +
        '(atau variabel lingkungan ADMIN_EMAIL).',
    );
  }
  if (options.uid.length === 0 && !options.email.includes('@')) {
    throw new Error(
      `Email admin tidak valid: "${options.email}". Isi alamat email yang ` +
        'benar-benar ada di Firebase Authentication.',
    );
  }
  if (
    options.serviceAccountPath.length > 0 &&
    !existsSync(options.serviceAccountPath)
  ) {
    throw new Error(
      `Berkas service account tidak ditemukan: ${options.serviceAccountPath}`,
    );
  }
}

/** Memuat firebase-admin dengan pesan gagal yang jelas. */
async function loadAdminSdk() {
  try {
    const app = await import('firebase-admin/app');
    const auth = await import('firebase-admin/auth');
    return { app, auth };
  } catch {
    throw new Error(
      'Paket `firebase-admin` belum terpasang. Jalankan: ' +
        'npm --prefix scripts install',
    );
  }
}

/** Menyiapkan Admin SDK beserta kredensial dari argumen atau lingkungan. */
function initializeAdminApp(adminApp, options) {
  const appOptions = options.serviceAccountPath
    ? { credential: adminApp.cert(options.serviceAccountPath) }
    : { credential: adminApp.applicationDefault() };
  return adminApp.getApps().length > 0
    ? adminApp.getApps()[0]
    : adminApp.initializeApp(appOptions);
}

/** Claim yang akan ditulis: `admin` ditambahkan, atau dihapus saat --revoke. */
function buildNextClaims(currentClaims, revoke) {
  const claims = { ...(currentClaims ?? {}) };
  if (revoke) {
    delete claims[ADMIN_CLAIM_KEY];
    return claims;
  }
  claims[ADMIN_CLAIM_KEY] = true;
  return claims;
}

/** Mencari akun admin berdasarkan uid atau email. */
async function resolveAdminUser(authSdk, options) {
  if (options.uid.length > 0) {
    return authSdk.getUser(options.uid);
  }
  return authSdk.getUserByEmail(options.email);
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  validateOptions(options);

  const target =
    options.uid.length > 0 ? `uid=${options.uid}` : `email=${options.email}`;
  console.log(`Akun    : ${target}`);
  console.log(
    `Aksi    : ${options.revoke ? 'mencabut' : 'memberi'} claim ` +
      `{ ${ADMIN_CLAIM_KEY}: true }`,
  );
  console.log(
    'Efeknya : dokumen `products/**`, `categories/**`, `banners/**`, ' +
      '`service_rates/**`, dan `creatives/**` dapat ditulis akun ini.',
  );

  if (options.dryRun) {
    console.log('\nMode --dry-run: tidak ada perubahan pada Firebase.');
    return;
  }

  const { app: adminApp, auth: adminAuth } = await loadAdminSdk();
  const app = initializeAdminApp(adminApp, options);
  const authSdk = adminAuth.getAuth(app);

  const user = await resolveAdminUser(authSdk, options);
  const nextClaims = buildNextClaims(user.customClaims, options.revoke);
  await authSdk.setCustomUserClaims(user.uid, nextClaims);

  // Membaca ulang dari Firebase supaya laporan hanya berisi keadaan yang benar
  // tersimpan, bukan asumsi skrip.
  const verified = await authSdk.getUser(user.uid);
  const adminClaim = verified.customClaims?.[ADMIN_CLAIM_KEY] === true;
  console.log(`\nAkun terverifikasi: ${verified.uid}`);
  console.log(`Claim ${ADMIN_CLAIM_KEY} aktif: ${adminClaim}`);
  if (adminClaim === options.revoke) {
    throw new Error(
      'Claim pada Firebase tidak sesuai harapan. Periksa kredensial dan ulangi.',
    );
  }

  console.log(
    '\nLangkah berikutnya:\n' +
      '  1. Pastikan rules terdeploy: firebase deploy --only firestore:rules,storage\n' +
      '  2. Login ulang di aplikasi (claim dibaca dengan forceRefresh), lalu buka\n' +
      '     Dashboard Admin dari drawer katalog.\n' +
      '  3. Untuk akun biasa, jangan pernah menambahkan claim ini.',
  );
}

main().catch((error) => {
  console.error(`\nGagal mengubah claim admin: ${error.message}`);
  process.exitCode = 1;
});
