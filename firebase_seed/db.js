'use strict';

const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

const DRY_RUN = process.argv.includes('--dry-run');
const KEY_FILE = path.join(__dirname, 'serviceAccountKey.json');

const USER_UIDS = {
  dawood: process.env.UID_DAWOOD || '',
  dawoodTest: process.env.UID_DAWOOD_TEST || '',
  test: process.env.UID_TEST || '',
};

const now = () => Timestamp.now();

const DOCS = [
  {
    path: 'currencies/JOD',
    data: {
      code: 'JOD',
      name: 'Jordanian Dinar',
      symbol: 'د.أ',
      isBaseCurrency: true,
      isActive: true,
    },
  },
  {
    path: 'currencies/USD',
    data: {
      code: 'USD',
      name: 'US Dollar',
      symbol: '$',
      isBaseCurrency: false,
      isActive: true,
    },
  },
  {
    path: 'exchange_rates/usd_rate',
    data: {
      currencyId: 'USD',
      rateToBase: 0.709,
      effectiveDate: now(),
    },
  },
  {
    path: 'exchange_rates/JOD_USD',
    data: {
      fromCurrency: 'JOD',
      toCurrency: 'USD',
      rate: 1.41044,
      effectiveDate: now(),
    },
  },
  {
    path: 'taxes/standard_tax',
    data: {
      name: 'Standard',
      rate: 10,
      isActive: true,
      createdAt: now(),
    },
  },
  {
    path: 'settings/invoice_counter',
    data: {
      lastInvoiceNumber: 3,
    },
  },
  {
    path: 'products/product_dawood_1',
    data: {
      name: 'Dawood Test 1',
      barcode: 'DT-1001',
      imageUrl: null,
      price: 100,
      taxRate: 10,
      currencyId: 'JOD',
      currencyCode: 'JOD',
      isActive: true,
    },
  },
  {
    path: 'products/product_dawood_2',
    data: {
      name: 'Dawood Test 2',
      barcode: 'DT-1002',
      imageUrl: null,
      price: 50,
      taxRate: 10,
      currencyId: 'JOD',
      currencyCode: 'JOD',
      isActive: true,
    },
  },
  {
    path: 'products/product_dawood_3',
    data: {
      name: 'Dawood Test 3',
      barcode: 'DT-1003',
      imageUrl: null,
      price: 25,
      taxRate: 10,
      currencyId: 'USD',
      currencyCode: 'USD',
      isActive: true,
    },
  },
  {
    path: 'products/product_dawood_4',
    data: {
      name: 'Test Product',
      barcode: 'DT-1004',
      imageUrl: null,
      price: 10,
      taxRate: 10,
      currencyId: 'JOD',
      currencyCode: 'JOD',
      isActive: true,
    },
  },
  {
    path: 'products/product_dawood_5',
    data: {
      name: 'Dawood Product',
      barcode: 'DT-1005',
      imageUrl: null,
      price: 200,
      taxRate: 10,
      currencyId: 'USD',
      currencyCode: 'USD',
      isActive: true,
    },
  },
  {
    path: 'customers/customer_dawood_1',
    data: {
      name: 'Dawood',
      nameLower: 'dawood',
      phone: '0790000001',
      email: 'dawood@example.com',
      address: 'Amman, Jordan',
      currencyId: 'JOD',
      isActive: true,
      createdAt: now(),
      updatedAt: now(),
    },
  },
  {
    path: 'customers/customer_dawood_2',
    data: {
      name: 'Dawood Test',
      nameLower: 'dawood test',
      phone: '0790000002',
      email: 'dawood.test@example.com',
      address: 'Amman, Jordan',
      currencyId: 'JOD',
      isActive: true,
      createdAt: now(),
      updatedAt: now(),
    },
  },
  {
    path: 'customers/customer_dawood_3',
    data: {
      name: 'Dawood Test 1',
      nameLower: 'dawood test 1',
      phone: '0790000003',
      email: 'dawoodtest1@example.com',
      address: 'Irbid, Jordan',
      currencyId: 'JOD',
      isActive: true,
      createdAt: now(),
      updatedAt: now(),
    },
  },
  {
    path: 'customers/customer_dawood_4',
    data: {
      name: 'Dawood Test 2',
      nameLower: 'dawood test 2',
      phone: '0790000004',
      email: 'dawoodtest2@example.com',
      address: 'Zarqa, Jordan',
      currencyId: 'USD',
      isActive: true,
      createdAt: now(),
      updatedAt: now(),
    },
  },
  {
    path: 'customers/customer_dawood_5',
    data: {
      name: 'Test Customer',
      nameLower: 'test customer',
      phone: '0790000005',
      email: 'test@example.com',
      address: 'Amman, Jordan',
      currencyId: 'JOD',
      isActive: true,
      createdAt: now(),
      updatedAt: now(),
    },
  },
  {
    path: 'invoices/invoice_dawood_1',
    data: {
      invoiceNumber: 1,
      invoiceName: 'Dawood Test Invoice 1',
      isHidden: false,
      customerId: 'customer_dawood_2',
      customerName: 'Dawood Test',
      currencyId: 'JOD',
      currencyCode: 'JOD',
      currencyName: 'Jordanian Dinar',
      currencySymbol: 'د.أ',
      baseCurrencyCode: 'JOD',
      exchangeRate: 1,
      taxRate: 10,
      taxMode: 'Exclusive',
      status: 'Approved',
      items: [
        {
          id: 'IT-1001',
          productId: 'product_dawood_1',
          productName: 'Dawood Test 1',
          barcode: 'DT-1001',
          originalUnitPrice: 100,
          originalCurrencyId: 'JOD',
          originalCurrencyCode: 'JOD',
          quantity: 2,
          unitPrice: 100,
          taxRate: 10,
          lineTotal: 220,
        },
        {
          id: 'IT-1002',
          productId: 'product_dawood_2',
          productName: 'Dawood Test 2',
          barcode: 'DT-1002',
          originalUnitPrice: 50,
          originalCurrencyId: 'JOD',
          originalCurrencyCode: 'JOD',
          quantity: 1,
          unitPrice: 50,
          taxRate: 10,
          lineTotal: 55,
        },
      ],
      subtotal: 250,
      taxAmount: 25,
      totalAmount: 275,
      createdAt: now(),
      approvedAt: now(),
      cancelledAt: null,
    },
  },
  {
    path: 'invoices/invoice_dawood_2',
    data: {
      invoiceNumber: 2,
      invoiceName: 'Dawood Test Invoice 2',
      isHidden: false,
      customerId: 'customer_dawood_5',
      customerName: 'Test Customer',
      currencyId: 'USD',
      currencyCode: 'USD',
      currencyName: 'US Dollar',
      currencySymbol: '$',
      baseCurrencyCode: 'JOD',
      exchangeRate: 0.709,
      taxRate: 10,
      taxMode: 'Inclusive',
      status: 'Draft',
      items: [
        {
          id: 'IT-2001',
          productId: 'product_dawood_3',
          productName: 'Dawood Test 3',
          barcode: 'DT-1003',
          originalUnitPrice: 25,
          originalCurrencyId: 'USD',
          originalCurrencyCode: 'USD',
          quantity: 3,
          unitPrice: 25,
          taxRate: 10,
          lineTotal: 75,
        },
        {
          id: 'IT-2002',
          productId: 'product_dawood_5',
          productName: 'Dawood Product',
          barcode: 'DT-1005',
          originalUnitPrice: 200,
          originalCurrencyId: 'USD',
          originalCurrencyCode: 'USD',
          quantity: 1,
          unitPrice: 200,
          taxRate: 10,
          lineTotal: 200,
        },
      ],
      subtotal: 250,
      taxAmount: 25,
      totalAmount: 275,
      createdAt: now(),
      approvedAt: null,
      cancelledAt: null,
    },
  },
  {
    path: 'invoices/invoice_dawood_3',
    data: {
      invoiceNumber: 3,
      invoiceName: 'Dawood Test Invoice 3',
      isHidden: false,
      customerId: 'customer_dawood_3',
      customerName: 'Dawood Test 1',
      currencyId: 'JOD',
      currencyCode: 'JOD',
      currencyName: 'Jordanian Dinar',
      currencySymbol: 'د.أ',
      baseCurrencyCode: 'JOD',
      exchangeRate: 1,
      taxRate: 10,
      taxMode: 'Exclusive',
      status: 'Cancelled',
      items: [
        {
          id: 'IT-3001',
          productId: 'product_dawood_1',
          productName: 'Dawood Test 1',
          barcode: 'DT-1001',
          originalUnitPrice: 100,
          originalCurrencyId: 'JOD',
          originalCurrencyCode: 'JOD',
          quantity: 1,
          unitPrice: 100,
          taxRate: 10,
          lineTotal: 110,
        },
        {
          id: 'IT-3002',
          productId: 'product_dawood_4',
          productName: 'Test Product',
          barcode: 'DT-1004',
          originalUnitPrice: 10,
          originalCurrencyId: 'JOD',
          originalCurrencyCode: 'JOD',
          quantity: 5,
          unitPrice: 10,
          taxRate: 10,
          lineTotal: 55,
        },
      ],
      subtotal: 150,
      taxAmount: 15,
      totalAmount: 165,
      createdAt: now(),
      approvedAt: null,
      cancelledAt: now(),
    },
  },
];

for (const [key, uid] of Object.entries(USER_UIDS)) {
  if (!uid) continue;
  const names = {
    dawood: ['Dawood', 'dawood@example.com'],
    dawoodTest: ['Dawood Test', 'dawood.test@example.com'],
    test: ['Test', 'test@example.com'],
  };
  const [displayName, email] = names[key];
  DOCS.push({
    path: `users/${uid}`,
    data: {
      email,
      displayName,
      createdAt: now(),
      updatedAt: now(),
    },
  });
}

function log(message) {
  console.log(message);
}

async function main() {
  const hasKey = fs.existsSync(KEY_FILE) && fs.statSync(KEY_FILE).size > 0;
  if (!hasKey && !DRY_RUN) {
    console.error(
      'ERROR: serviceAccountKey.json not found in ' +
        path.join(__dirname, 'serviceAccountKey.json') +
        '\nSee README.md for how to download it from Firebase Console.',
    );
    process.exit(1);
  }

  let db = null;
  if (hasKey) {
    initializeApp({ credential: cert(KEY_FILE) });
    db = getFirestore();
  } else {
    console.warn(
      'WARNING: no serviceAccountKey.json found - dry run shows the full ' +
        'plan without checking which documents already exist.',
    );
  }

  let created = 0;
  let skipped = 0;

  for (const doc of DOCS) {
    let exists = false;
    if (db) {
      const snapshot = await db.doc(doc.path).get();
      exists = snapshot.exists;
    }

    if (exists) {
      log(`- Skipped ${doc.path} (already exists)`);
      skipped += 1;
      continue;
    }

    if (DRY_RUN) {
      log(`+ Would create ${doc.path}`);
    } else {
      await db.doc(doc.path).set(doc.data);
      log(`+ Created ${doc.path}`);
      created += 1;
    }
  }

  const userUidsGiven = Object.values(USER_UIDS).filter(Boolean).length;
  if (userUidsGiven === 0) {
    log(
      'NOTE: no user documents seeded. The app creates `users/{uid}` docs ' +
        'automatically on first login, or set UID_DAWOOD/UID_DAWOOD_TEST/' +
        'UID_TEST env vars to seed them.',
    );
  }

  log('');
  log(
    DRY_RUN
      ? `Dry run complete: ${skipped} already exist (would be skipped), ${
          DOCS.length - skipped
        } would be created.`
      : `Done: ${created} created, ${skipped} skipped. No documents were deleted or overwritten.`,
  );
}

main().catch((error) => {
  console.error('Seed failed:', error.message);
  process.exit(1);
});