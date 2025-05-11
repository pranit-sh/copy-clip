import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const SearchField({
    super.key,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.0,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Lookup clips / notes...',
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
          enabled: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14.0,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 20.0,
          ),
        ),
        cursorColor: Colors.white.withValues(alpha: 0.7),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 14.0,
        ),
        textAlignVertical: TextAlignVertical.center,
      ),
    );
  }
}
