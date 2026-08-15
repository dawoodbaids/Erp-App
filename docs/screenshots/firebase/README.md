# Firestore Screenshots (manual step)

These screenshots must be captured from the **Firebase Console** and added to
this folder before final submission. They cannot be generated automatically.

Login at <https://console.firebase.google.com/project/erp-app-7f98b>.

## Required screenshots

1. **Firestore Database → Data** — showing the collection list on the left
   (Users, Customers, Products, Currencies, Exchange Rates, Taxes, Settings,
   Invoices). Save as `01_collections_list.png`.
2. **Firestore Database → Data → `customers`** — a few customer documents.
   Save as `02_customers.png`.
3. **Firestore Database → Data → `products`** — a few product documents.
   Save as `03_products.png`.
4. **Firestore Database → Data → `currencies`** — currency documents showing
   one with `isBaseCurrency: true`. Save as `04_currencies.png`.
5. **Firestore Database → Data → `exchange_rates`** — rate documents.
   Save as `05_exchange_rates.png`.
6. **Firestore Database → Data → `taxes`** — tax documents. Save as
   `06_taxes.png`.
7. **Firestore Database → Data → `invoices`** — one expanded invoice document
   showing the embedded `items` array. Save as `07_invoices.png`.
8. **Firestore Database → Data → `settings` → `invoice_counter`** — showing the
   `lastInvoiceNumber` counter. Save as `08_settings.png`.
9. **Firestore Database → Rules** — showing the deployed `firestore.rules`.
   Save as `09_rules.png`.
10. **Authentication → Users** — showing the configured Email/Password users.
    Save as `10_auth_users.png`.

## Alternative

If you prefer, export PNG/JPEG files of these views, name them with the
numbers above (or any clear names), and drop them here. Update the screenshot
section in the root `README.md` if you use different names.
