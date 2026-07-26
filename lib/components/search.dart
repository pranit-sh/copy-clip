import 'package:flutter/material.dart';

import 'kbd_chip.dart';

class SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final VoidCallback? onClear;

  const SearchField({
    super.key,
    required this.onChanged,
    this.focusNode,
    this.controller,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller?.text.isNotEmpty ?? false;
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        cursorColor: Colors.white,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
              const BoxConstraints(minWidth: 32, minHeight: 36),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 36),
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
      ),
    );
  }
}
