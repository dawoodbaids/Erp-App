# Firebase Setup

The app uses Firebase project `erp-app-7f98b` and Android package
`com.example.erp_mobileapp_ui`. Firebase is initialized on all platforms
(Android, iOS, web, macOS, Windows) from `lib/firebase_options.dart` in
`main.dart` before any controller is created.

## Project Services

Enable these services in the Firebase console:

- Authentication: Email/password provider
- Firestore Database: default database in `me-central2`

Deploy the checked-in Firestore rules from the project root:

```text
firebase deploy --only firestore:rules --project erp-app-7f98b
```

## Firestore Collections

The app does not seed business data. Currencies, exchange rates, and taxes can
be created in-app from Settings (Currencies, Exchange Rates, Tax Rates), which
writes the documents described below. The first currency created automatically
becomes the base currency.

`users/{uid}`

- `email` string
- `displayName` string
- `createdAt` timestamp
- `updatedAt` timestamp

The document ID is the Firebase Auth UID. Invoice documents also store the
authenticated user's UID in `createdBy`.

`currencies/{currencyId}`

- `code` string
- `name` string
- `symbol` string
- `isBaseCurrency` boolean
- `isActive` boolean

Exactly one currency has `isBaseCurrency: true`. The app blocks deleting the
base currency; deleting any other currency also deletes its exchange rate
documents.

`exchange_rates/{rateId}`

- `currencyId` string (may be either the `currencies` document ID or the
  currency code, e.g. `JOD` — the app resolves either form, case-insensitively)
- `rateToBase` number
- `effectiveDate` timestamp

`rateToBase` is how much of the BASE currency equals 1 unit of that currency.
The base currency has no rate document and always equals 1. Conversion between
two currencies is `fromRate / toRate`. A missing rate blocks invoice creation
with "Exchange rate is not available for X → Y." — the app never falls back to
a rate of 1 silently.

Pair-style documents are also accepted when a `rateToBase` value is absent:

`exchange_rates/{pairId}` (e.g. `JOD_USD`)

- `fromCurrency` string
- `toCurrency` string
- `rate` number (units of `toCurrency` per 1 `fromCurrency`)
- `effectiveDate` timestamp

A pair document like `{fromCurrency: "JOD", toCurrency: "USD", rate: 1.41044}`
is converted to the canonical `rateToBase` form in-app when one side is the
base currency (here: `USD → 0.709`, `JOD → 1`). Pairs between two non-base
currencies cannot be anchored and are shown read-only on the Exchange Rates
screen without being used for conversions.

`taxes/{taxId}`

- `name` string
- `rate` number
- `isActive` boolean
- `createdAt` timestamp
- `updatedAt` timestamp

The first active tax document is used as the default tax rate for new
products and invoices. Existing invoices keep their saved `taxRate`.

`settings/invoice_counter`

- `lastInvoiceNumber` number

This document is used as a counter for sequential invoice numbers. The app
creates it on first use and seeds it above the highest existing invoice
number to avoid duplicates.

`customers/{customerId}`

- `name` string
- `nameLower` string
- `phone` string or null
- `email` string
- `address` string or null
- `currencyId` string (default currency used for new invoices)
- `isActive` boolean
- `createdAt` timestamp
- `updatedAt` timestamp

Product images are optional. The app does not require Firebase Storage; an
existing `imageUrl` value can still be displayed when present.

`products/{productId}`

- `name` string
- `barcode` string
- `imageUrl` string or null
- `price` number (always kept in the product's original currency)
- `taxRate` number
- `currencyId` string
- `currencyCode` string (code of the currency `price` is stored in; written on
  create/edit. Older products without this field still work — the code is
  resolved from the currency document, and the stored `price` is never
  converted or overwritten)
- `isActive` boolean
- `createdAt` timestamp
- `updatedAt` timestamp

Prices are displayed through the app's Display Currency setting
(Settings → Display Currency, defaults to the base currency and persisted on
the device). Stored product prices are never modified; only the displayed
amount is converted using Firebase rates, so switching display currencies
round-trips to the original value with no drift. When a rate is missing the
original currency amount is shown instead of a made-up rate.

`invoices/{invoiceId}` stores the customer and currency snapshot plus an
`items` array. The document ID is the sequential invoice number string
(e.g. `1`, `2`, …), allocated atomically by `InvoiceNumberService` using the
`settings/invoice_counter` document. It contains:

- `invoiceNumber` string (same value as the document ID; displayed as `#1`,
  `#2`, …). Legacy documents holding padded numbers such as `0001` or
  `INV-2026-0003` remain readable and searchable.
- `invoiceName` string
- `customerId` and `customerName`
- `currencyId`, `currencyCode`, `currencyName`, and `currencySymbol`
- `items` array of product snapshots
- `subtotal`, `taxAmount`, and `totalAmount` numbers
- `taxRate` number (global tax applied to the invoice)
- `taxMode`, `status`, and `isHidden`
- `baseCurrencyCode` and `exchangeRate`
- `createdAt`, `updatedAt`, and `createdBy`

Each item contains `productId`, `productName`, `barcode`, `quantity`,
`originalUnitPrice`, `originalCurrencyId`, `originalCurrencyCode`, `unitPrice`,
`taxRate`, and `lineTotal`. There is no separate `invoice_items` collection.

## Android Configuration

`android/app/google-services.json` is generated for the Android app and is
consumed by the Google Services Gradle plugin. No iOS Firebase configuration
is included.
