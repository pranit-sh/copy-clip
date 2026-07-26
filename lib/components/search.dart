import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kbd_chip.dart';

/// The gradient search field that sits in the app bar. Plain text input —
/// filtering by tag is handled separately by [TagFilterBar] below the app bar.
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      cursorColor: Colors.white,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        hintText: 'Search clips…',
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: Colors.white.withValues(alpha: 0.85),
        ),
        prefixIconConstraints:
          const BoxConstraints(minWidth: 34, minHeight: 32),
        suffixIcon: hasText
            ? IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                splashRadius: 14,
                onPressed: onClear,
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              )
            : Center(
                widthFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, left: 4),
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white),
                    child: KbdChip.meta('K'),
                  ),
                ),
              ),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 30, minHeight: 32),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.7),
            width: 1.2,
          ),
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => SystemChannels.textInput.invokeMethod('TextInput.hide'),
    );
  }
}
