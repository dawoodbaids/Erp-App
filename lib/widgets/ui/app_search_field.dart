import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_text_field.dart';

/// Rounded search field with a clear button.
class AppSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final EdgeInsetsGeometry padding;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 0),
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: AppTextField(
        controller: widget.controller,
        hint: widget.hint,
        prefixIcon: Icons.search,
        textInputAction: TextInputAction.search,
        onChanged: widget.onChanged,
        suffix: ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: widget.onClear,
              tooltip: 'search.clear'.tr,
            );
          },
        ),
      ),
    );
  }
}
