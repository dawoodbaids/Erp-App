import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_helpers.dart';
import '../models/dashboard.dart';
import '../models/invoice.dart';
import 'firebase_service_exception.dart';

class DashboardService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<DashboardSummary> getSummary() {
    return runFirebase(() async {
      final invoices = await _readInvoices();
      final customers = await _db.collection('customers').get();
      final products = await _db.collection('products').get();
      final currencies = await _db.collection('currencies').get();
      var baseCode = '';
      for (final doc in currencies.docs) {
        final data = doc.data();
        if (data['isBaseCurrency'] == true) {
          baseCode = firestoreString(data['code']);
          break;
        }
      }
      final visible = invoices.where((invoice) => !invoice.isHidden).toList();
      final approved = visible
          .where((invoice) => invoice.status == InvoiceStatus.approved)
          .toList();
      final now = DateTime.now();

      double sales(Iterable<Invoice> source) => source.fold(
            0,
            (total, invoice) =>
                total + invoice.totalAmount * invoice.exchangeRate,
          );

      return DashboardSummary(
        baseCurrencyCode: baseCode,
        todaySales: sales(
          approved.where(
            (invoice) => _sameDay(invoice.createdAt, now),
          ),
        ),
        thisMonthSales: sales(
          approved.where(
            (invoice) =>
                invoice.createdAt.year == now.year &&
                invoice.createdAt.month == now.month,
          ),
        ),
        totalSales: sales(approved),
        totalInvoices: visible.length,
        approvedInvoices: approved.length,
        pendingDrafts: visible
            .where((invoice) => invoice.status == InvoiceStatus.draft)
            .length,
        cancelledInvoices: visible
            .where((invoice) => invoice.status == InvoiceStatus.cancelled)
            .length,
        totalCustomers: customers.size,
        totalProducts: products.size,
      );
    }, 'Could not load the dashboard. Please try again.');
  }

  Future<List<SalesPoint>> getSalesTrend({int days = 6}) {
    return runFirebase(() async {
      final invoices = await _readInvoices();
      final now = DateTime.now();
      final points = <SalesPoint>[];
      for (var offset = days - 1; offset >= 0; offset--) {
        final day = DateTime(now.year, now.month, now.day).subtract(
          Duration(days: offset),
        );
        final matching = invoices.where(
          (invoice) =>
              !invoice.isHidden &&
              invoice.status == InvoiceStatus.approved &&
              _sameDay(invoice.createdAt, day),
        );
        points.add(
          SalesPoint(
            date: day,
            label: _weekdayLabel(day.weekday),
            total: _round(
              matching.fold(
                0,
                (total, invoice) =>
                    total + invoice.totalAmount * invoice.exchangeRate,
              ),
            ),
            invoiceCount: matching.length,
          ),
        );
      }
      return points;
    }, 'Could not load the sales trend. Please try again.');
  }

  Future<InvoiceStatusStats> getInvoiceStatus() {
    return runFirebase(() async {
      final invoices = (await _readInvoices()).where((i) => !i.isHidden);
      double total(InvoiceStatus status) => _round(
            invoices
                .where((invoice) => invoice.status == status)
                .fold(
                  0,
                  (total, invoice) =>
                      total + invoice.totalAmount * invoice.exchangeRate,
                ),
          );
      int count(InvoiceStatus status) =>
          invoices.where((invoice) => invoice.status == status).length;

      return InvoiceStatusStats(
        draftCount: count(InvoiceStatus.draft),
        draftTotal: total(InvoiceStatus.draft),
        approvedCount: count(InvoiceStatus.approved),
        approvedTotal: total(InvoiceStatus.approved),
        cancelledCount: count(InvoiceStatus.cancelled),
        cancelledTotal: total(InvoiceStatus.cancelled),
      );
    }, 'Could not load invoice statistics. Please try again.');
  }

  Future<List<Invoice>> _readInvoices() async {
    final snapshot = await _db.collection('invoices').get();
    return snapshot.docs
        .map((doc) => Invoice.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  String _weekdayLabel(int weekday) => const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ][weekday - 1];

  double _round(double value) => (value * 100).round() / 100;
}
