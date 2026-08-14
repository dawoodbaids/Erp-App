# Firebase Setup

The Android app uses Firebase project `erp-app-7f98b` and Android package
`com.example.erp_mobileapp_ui`.

## Project Services

Enable these services in the Firebase console:

- Authentication: Email/password provider
- Firestore Database: default database in `me-central2`

Deploy the checked-in Firestore rules from the project root:

```text
firebase deploy --only firestore:rules --project erp-app-7f98b
```

## Firestore Collections

The app does not seed business data. Create the required records in Firestore
or provide an administrative import before using product and invoice forms.

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

`exchange_rates/{rateId}`

- `currencyId` string
- `rateToBase` number
- `effectiveDate` timestamp

`taxes/{taxId}`

- `name` string
- `rate` number
- `isActive` boolean

The first active tax document is used as the default tax rate for new
products and invoices.

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
- `price` number
- `taxRate` number
- `currencyId` string
- `isActive` boolean
- `createdAt` timestamp
- `updatedAt` timestamp

`invoices/{invoiceId}` stores the customer and currency snapshot plus an
`items` array. It contains:

- `invoiceNumber` number (sequential; displayed as `#1`, `#2`, …)
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
