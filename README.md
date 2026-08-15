# ERP Mobile App

A Flutter (Dart) mobile application that manages a small business ERP:
customers, products, multi-currency invoices with automatic currency
conversion, and tax handling. All data lives in **Firebase Cloud Firestore**
(no SQL database is used).

## Project Description

- **Authentication** — Firebase Authentication (Email/Password). Each signed-in
  user gets a profile document in `users`.
- **Customers** — add, edit, delete, and search customers; each customer can
  have a default currency.
- **Products** — add, edit, delete, and look up products by barcode. Prices are
  kept in each product's original currency and displayed in the app's display
  currency using live exchange rates.
- **Invoices** — create draft invoices with multiple line items, currency
  conversion, discounts, and taxes. Approve or cancel invoices. Sequential
  invoice numbers are assigned atomically in Firestore.
- **Currencies & Exchange Rates** — manage currencies (exactly one base
  currency) and their rates against the base currency.
- **Tax Rates** — configure the tax percentage applied to products/invoices.
- **Dashboard** — live totals: today/this month/all-time sales, invoice
  counts by status, customer and product counts.

## Technologies

| Area          | Technology                                 |
| ------------- | ------------------------------------------ |
| Framework     | Flutter (Dart)                             |
| Mobile target | Android (APK included)                     |
| Authentication| Firebase Authentication (Email/Password)   |
| Database      | Firebase Cloud Firestore                   |
| State        | GetX                                       |
| Localization  | English / Arabic                           |

## How to Run

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable).
2. Clone the repository:
   ```text
   git clone https://github.com/dawoodbaids/Erp-App.git
   cd Erp-App
   ```
3. Fetch dependencies:
   ```text
   flutter pub get
   ```
4. Run the app (Android emulator/device):
   ```text
   flutter run
   ```
5. Sign in with a Firebase Authentication user (create one in the Firebase
   console, or use the account provided by the instructor).

To build a release APK:

```text
flutter build apk --release
```

The built APK is `build/app/outputs/flutter-apk/app-release.apk`. A copy for
submission is included at [`release/app-release.apk`](release/app-release.apk).

## Database

The app uses **Firebase Cloud Firestore** (Firebase project `erp-app-7f98b`,
database region `me-central2`). There are no SQL scripts; the database schema
is enforced by the app's service layer and by `firestore.rules`.

Collections:

| Collection      | Purpose                                              |
| --------------- | ---------------------------------------------------- |
| `users`         | Signed-in user profiles (document ID = Auth UID)     |
| `customers`     | Customers and their default currency                 |
| `products`      | Products, prices, barcodes, tax rates                |
| `currencies`    | Currencies; exactly one is the base currency         |
| `exchange_rates`| Rate of each currency against the base currency      |
| `taxes`         | Tax configurations (name + percentage)               |
| `settings`      | App counters (e.g. `invoice_counter`)                |
| `invoices`      | Invoices with embedded `items` line-item array       |

Key relationships:

- `users/{uid}` — document ID is the Firebase Auth UID.
- `products/{name}` — readable document ID based on the product name;
  `currencyId` references a `currencies` document.
- `customers/{name}` — readable document ID based on the customer name;
  `currencyId` references a `currencies` document.
- `invoices/{number}` — document ID is the sequential invoice number; embeds
  snapshots of the customer, currency, and each product line item (no separate
  `invoice_items` collection).
- `exchange_rates/{id}` — `currencyId` references a `currencies` document;
  `rateToBase` is units of the base currency per 1 unit of that currency.

Full field-level documentation: [`docs/FIREBASE_DATABASE.md`](docs/FIREBASE_DATABASE.md)
and [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md).

## Firebase Configuration

| File | Purpose |
| ---- | ------- |
| `firebase.json` | Firestore rules + Flutter project mapping (`erp-app-7f98b`) |
| `.firebaserc` | Firebase project alias |
| `firestore.rules` | Firestore security rules (all collections require a signed-in user) |
| `lib/firebase_options.dart` | Runtime Firebase initialization for all platforms |
| `android/app/google-services.json` | Android Google Services configuration |
| `FIREBASE_SETUP.md` | Step-by-step Firebase setup and collection guide |

Firestore rules are deployed with:

```text
firebase deploy --only firestore:rules --project erp-app-7f98b
```

## Source Code

- **Firestore services** — `lib/services/` (`auth_service.dart`,
  `customer_service.dart`, `product_service.dart`, `currency_service.dart`,
  `exchange_rate_service.dart`, `tax_service.dart`, `invoice_service.dart`,
  `invoice_number_service.dart`, `dashboard_service.dart`).
- **Models** — `lib/models/` (`customer.dart`, `product.dart`, `currency.dart`,
  `exchange_rate.dart`, `tax_rate.dart`, `invoice.dart`, `invoice_item.dart`,
  `dashboard.dart`).
- **Controllers** — `lib/controllers/`.
- **Screens** — `lib/screens/` (login, dashboard, customers, products,
  invoices, settings).
- **Firebase initialization** — `lib/main.dart` and `lib/firebase_options.dart`.

## Firestore Screenshots

Firebase Console screenshots are required for the submission. They cannot be
generated automatically, so please add them manually:

> [`docs/screenshots/firebase/README.md`](docs/screenshots/firebase/README.md)
> lists exactly which screenshots to capture.

## Submission Checklist

- [ ] Project runs with `flutter run` (Firebase Auth + Firestore configured).
- [ ] `flutter analyze` passes with no issues.
- [ ] `flutter test` passes (unit/widget tests included in `test/`).
- [ ] Release APK built at `release/app-release.apk`.
- [ ] Firestore rules deployed (`firebase deploy --only firestore:rules`).
- [ ] Firebase Console screenshots added under `docs/screenshots/firebase/`.
