# Firebase Seed Script

Creates the test/mock data the ERP Flutter app expects in Firebase Firestore.

Safe to run any number of times:

- Never deletes anything.
- Never overwrites an existing document — documents that already exist are skipped.

## Install

```bash
npm install
```

## Firebase credentials

1. Go to the [Firebase Console](https://console.firebase.google.com).
2. Open your project (the one the ERP app uses).
3. Go to **Project settings** (gear icon) > **Service accounts** tab.
4. Click **Generate new private key** and confirm.
5. Rename the downloaded file to `serviceAccountKey.json` and place it in this folder (`firebase_seed/`).

**IMPORTANT: never upload `serviceAccountKey.json` to GitHub or share it.**

It is already listed in the repository's `.gitignore`, so it will not be committed.
Delete it when you are done testing if you do not need it anymore.

## Run

```bash
node db.js
```

## Dry run

Shows what would be created, without touching Firebase:

```bash
node db.js --dry-run
```

## Seeding user documents (optional)

The app stores a profile document at `users/{authUid}` (fields: `email`,
`displayName`, `createdAt`, `updatedAt`) and creates it automatically the first
time each account signs in — so normally you do not need to seed it.

Passwords are **never** stored in Firestore; they only live in Firebase Auth.
Create the test accounts under **Firebase Console > Authentication > Users > Add user**:

| Email                     | Password         | Display name |
| ------------------------- | ---------------- | ------------ |
| `dawood@example.com`      | `Dawood@123`     | Dawood       |
| `dawood.test@example.com` | `DawoodTest@123` | Dawood Test  |
| `test@example.com`        | `Test@123`       | Test         |

If you want the seed script to create the Firestore user documents too, copy
each user's UID from the Auth console and pass it as an environment variable:

```bash
# Windows PowerShell
$env:UID_DAWOOD="uid-of-dawood"; $env:UID_DAWOOD_TEST="uid-of-dawood-test"; $env:UID_TEST="uid-of-test"; node db.js
```

## What gets created

| Collection       | Documents                                                                                                               |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `currencies`     | `JOD` (base currency), `USD`                                                                                            |
| `exchange_rates` | `usd_rate` (canonical `rateToBase: 0.709`), `JOD_USD` (pair `rate: 1.41044`)                                            |
| `taxes`          | `standard_tax` (Standard, 10%)                                                                                          |
| `settings`       | `invoice_counter` (next invoice number: 4)                                                                              |
| `products`       | `product_dawood_1` ... `product_dawood_5`                                                                               |
| `customers`      | `customer_dawood_1` ... `customer_dawood_5`                                                                             |
| `invoices`       | `invoice_dawood_1` (Approved, JOD, 275), `invoice_dawood_2` (Draft, USD, 275), `invoice_dawood_3` (Cancelled, JOD, 165) |
| `users`          | only when UID environment variables are set (see above)                                                                 |

Product prices are always stored in their own currency
(`price` + `currencyCode`, e.g. `100` + `JOD`) and are never converted or
rewritten. Invoices keep their own currency/amount snapshots — changing the
app's display currency never modifies existing documents.
