# Firebase Firestore Database

The ERP app stores all data in Firebase Cloud Firestore (project
`erp-app-7f98b`, default database in region `me-central2`). There is **no SQL
database**. The structure below is the real schema used by the app — it is
written by `lib/services/*` and read by the models in `lib/models/*`.

Security: every collection requires an authenticated user
(`firestore.rules`). `users` documents are additionally scoped to the signed-in
user's UID.

The app does **not** seed business data. Currencies, exchange rates, taxes,
customers, products, and invoices are created from the app (Settings screens
create currencies, exchange rates, and tax rates).

---

## `users/{uid}`

One profile document per Firebase Authentication user.

| Field | Type | Notes |
| ----- | ---- | ----- |
| `email` | string | The Auth email |
| `displayName` | string | Display name (falls back to email) |
| `createdAt` | timestamp | Written on first sign-in |
| `updatedAt` | timestamp | Updated on each sign-in |

- Document ID = the Firebase Auth UID.
- Written by `AuthService._loadProfile` (`lib/services/auth_service.dart`) and
  `FirestoreInitializer` (`lib/services/firestore_initializer.dart`).
- Invoices also store `createdBy` = the signed-in user's UID.

---

## `currencies/{currencyId}`

| Field | Type | Notes |
| ----- | ---- | ---- |
| `code` | string | Uppercase currency code, e.g. `JOD`, `USD` (unique) |
| `name` | string | Currency name |
| `symbol` | string | Currency symbol, e.g. `JD`, `$` |
| `isBaseCurrency` | boolean | Exactly one currency is `true` |
| `isActive` | boolean | Inactive currencies are hidden |
| `createdAt` | timestamp | |
| `updatedAt` | timestamp | |

- Document ID is generated from `currency_<CODE>` (readable; a suffix is added
  if taken).
- The **first** currency created becomes the base currency automatically.
- The base currency cannot be deleted; deleting a non-base currency also
  deletes its `exchange_rates` documents in one batch.
- Changing the base currency re-bases all rates in a single batch write.

Service: `lib/services/currency_service.dart`.

---

## `exchange_rates/{rateId}`

| Field | Type | Notes |
| ----- | ---- | ---- |
| `currencyId` | string | The `currencies` document ID the rate belongs to |
| `rateToBase` | number | How much of the **base** currency equals 1 unit of this currency |
| `effectiveDate` | timestamp | Last time the rate was updated |

- The base currency has **no** rate document (its rate is always 1).
- A rate can also be stored under the currency **code** instead of the
  document ID (e.g. `JOD`); the app resolves either form case-insensitively.
- Conversion between two currencies: `fromRate / toRate`. A missing rate
  blocks invoice creation ("Exchange rate is not available for X → Y.") — the
  app never silently falls back to a rate of 1.
- Legacy pair documents are tolerated: `{fromCurrency, toCurrency, rate}`
  (e.g. `exchange_rates/JOD_USD` with `rate: 1.41044`). They are converted to
  the canonical `rateToBase` form when one side is the base currency.

Service: `lib/services/exchange_rate_service.dart`.

---

## `taxes/{taxId}`

| Field | Type | Notes |
| ----- | ---- | ---- |
| `name` | string | Tax name, e.g. `Sales Tax` |
| `rate` | number | Percentage, `0–100` |
| `isActive` | boolean | Only active taxes are offered |
| `createdAt` | timestamp | |
| `updatedAt` | timestamp | |

- The first active tax is the default for new products and invoices.
- Invoices store their own `taxRate` snapshot so later tax edits never change
  existing invoices.

Service: `lib/services/tax_service.dart`.

---

## `settings/{settingId}`

Configuration/counter documents.

### `settings/invoice_counter`

| Field | Type | Notes |
| ----- | ---- | ---- |
| `lastInvoiceNumber` | number | Last allocated invoice sequence |

- Allocates sequential invoice numbers **atomically** in a Firestore
  transaction: reads the counter, finds the first unused number, writes the
  new counter value and the invoice document in the same transaction
  (`lib/services/invoice_number_service.dart`).
- Created on first use.

---

## `customers/{customerId}`

| Field | Type | Notes |
| ----- | ---- | ---- |
| `name` | string | Customer name (unique) |
| `nameLower` | string | Lower-cased name for duplicate detection |
| `phone` | string \| null | |
| `email` | string | |
| `address` | string \| null | |
| `currencyId` | string | Customer's default currency (`currencies` doc ID) |
| `isActive` | boolean | |
| `createdAt` | timestamp | |
| `updatedAt` | timestamp | |

- Document ID is the exact customer name (a suffix is added if taken).
- Duplicate names are rejected via `nameLower`.

Service: `lib/services/customer_service.dart`.

---

## `products/{productId}`

| Field | Type | Notes |
| ----- | ---- | ---- |
| `name` | string | Product name |
| `barcode` | string | Unique barcode (looked up by the scanner) |
| `imageUrl` | string \| null | Optional image (Firebase Storage is optional) |
| `price` | number | Price **in the product's original currency** (never converted) |
| `taxRate` | number | Tax percentage applied to this product |
| `currencyId` | string | `currencies` document ID for the price |
| `currencyCode` | string | Code of the price currency (e.g. `JOD`); written on create/edit |
| `isActive` | boolean | |
| `createdAt` | timestamp | |
| `updatedAt` | timestamp | |

- Document ID is the exact product name (a suffix is added if taken).
- The stored `price` is never modified; the app converts it for display using
  the display-currency setting and Firebase exchange rates.

Service: `lib/services/product_service.dart`.

---

## `invoices/{invoiceId}`

Document ID is the **sequential invoice number string** (e.g. `1`, `2`, …),
allocated atomically by `InvoiceNumberService`. The invoice stores snapshots of
the customer, currency, and products plus an embedded `items` array — there is
**no** separate `invoice_items` collection.

| Field | Type | Notes |
| ----- | ---- | ---- |
| `invoiceNumber` | string | Same as the document ID; displayed as `#1`, `#2`, … |
| `invoiceName` | string | Optional name/label |
| `customerId` / `customerName` | string | Customer snapshot |
| `currencyId` / `currencyCode` / `currencyName` / `currencySymbol` | string | Invoice currency snapshot |
| `baseCurrencyCode` | string | Base currency at creation time |
| `exchangeRate` | number | Rate of the invoice currency vs. base at creation time |
| `taxRate` | number | Tax percentage applied to the invoice |
| `taxMode` | string | `Exclusive` or `Inclusive` |
| `discountAmount` | number | Discount before tax (invoice currency) |
| `subtotal` | number | Sum of line totals |
| `taxAmount` | number | Computed tax |
| `totalAmount` | number | Final total |
| `status` | string | `draft`, `approved`, or `cancelled` |
| `isHidden` | boolean | Soft-deleted invoices are hidden |
| `items` | array | Embedded line items (below) |
| `createdAt` | timestamp | |
| `updatedAt` | timestamp | |
| `approvedAt` | timestamp \| null | Set when approved |
| `cancelledAt` | timestamp \| null | Set when cancelled |
| `createdBy` | string | Auth UID of the creator |

### Invoice line item (`items[].`)

| Field | Type | Notes |
| ----- | ---- | ---- |
| `id` | string | `{productId}-{index}` |
| `productId` / `productName` | string | Product snapshot |
| `barcode` | string | Product barcode snapshot |
| `quantity` | number | |
| `originalUnitPrice` | number | Product price in its original currency |
| `originalCurrencyId` / `originalCurrencyCode` | string | Original price currency |
| `unitPrice` | number | Price converted to the invoice currency |
| `taxRate` | number | Tax percentage at invoice creation |
| `lineTotal` | number | Computed line total |

Only **draft** invoices can be edited, approved, or cancelled.

Service: `lib/services/invoice_service.dart` and
`lib/services/invoice_number_service.dart`.

---

## Document ID summary

| Collection | Document ID | Generated by |
| ---------- | ----------- | ------------ |
| `users` | Firebase Auth UID | Firebase Auth |
| `customers` | Customer name | `createWithUniqueId` |
| `products` | Product name | `createWithUniqueId` |
| `currencies` | `currency_<CODE>` | `createWithUniqueId` |
| `exchange_rates` | `exchange_rate_<CODE>` | `createWithUniqueId` |
| `taxes` | `tax_<NAME>` | `createWithUniqueId` |
| `settings` | `invoice_counter` (fixed) | App |
| `invoices` | Sequential number | `InvoiceNumberService` (atomic transaction) |

`createWithUniqueId` (`lib/core/utils/firestore_id_service.dart`) writes the
document and checks for collisions inside a transaction, appending `_2`, `_3`,
… if the readable ID is taken.
