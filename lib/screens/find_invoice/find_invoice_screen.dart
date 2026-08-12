import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/invoice_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/invoice.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/invoice_card.dart';

class FindInvoiceScreen extends StatefulWidget {
  const FindInvoiceScreen({super.key});

  @override
  State<FindInvoiceScreen> createState() => _FindInvoiceScreenState();
}

class _FindInvoiceScreenState extends State<FindInvoiceScreen> {
  final _queryController = TextEditingController();
  Invoice? _result;
  String? _error;
  bool _searching = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _result = null;
        _error = 'findInvoice.enterQuery'.tr;
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _searching = true;
      _result = null;
      _error = null;
    });

    final controller = Get.find<InvoiceController>();
    Invoice? result;
    String? error;
    final normalized = query.startsWith('#') ? query.substring(1) : query;
    if (int.tryParse(normalized) != null) {
      result = await controller.loadDetails(normalized);
      if (result == null) error = 'findInvoice.notFound'.tr;
    } else {
      final lookup = await controller.findByNumber(normalized.toUpperCase());
      result = lookup.$1;
      error = lookup.$2;
    }

    if (!mounted) return;
    setState(() {
      _searching = false;
      _result = result;
      _error = result == null ? (error ?? 'findInvoice.notFound'.tr) : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(title: 'findInvoice.title'.tr),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'findInvoice.subtitle'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('find-invoice-query'),
            controller: _queryController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'findInvoice.label'.tr,
              hintText: 'findInvoice.hint'.tr,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _queryController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'search.clear'.tr,
                      onPressed: () {
                        _queryController.clear();
                        setState(() {
                          _result = null;
                          _error = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('find-invoice-submit'),
              onPressed: _searching ? null : _search,
              icon: _searching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text('findInvoice.search'.tr),
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_result != null) ...[
            Text(
              'findInvoice.result'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            InvoiceCard(invoice: _result!),
            if (_result!.isHidden) ...[
              const SizedBox(height: 10),
              Text(
                'findInvoice.hiddenNotice'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  Get.toNamed(AppRoutes.invoiceDetails, arguments: _result!.id),
              icon: const Icon(Icons.open_in_new),
              label: Text('findInvoice.openDetails'.tr),
            ),
          ],
        ],
      ),
    );
  }
}
