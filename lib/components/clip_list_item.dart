import 'package:flutter/material.dart';
import 'package:copy_clip/models/clip.dart';
import 'package:flutter/services.dart';

class ClipListItem extends StatelessWidget {
  final Clip clip;
  final VoidCallback onRemove;
  final VoidCallback onUndo;
  final VoidCallback onTogglePin;

  const ClipListItem({
    super.key,
    required this.clip,
    required this.onRemove,
    required this.onUndo,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        onTogglePin();
      },
      onTap: () {
        Clipboard.setData(ClipboardData(text: clip.text));
        ScaffoldMessenger.of(context)
            .clearSnackBars(); // Clear existing snack bars
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Copied',
              style: TextStyle(
                  fontSize: 14, color: Colors.white), // Reduced font size
            ),
            duration: Duration(milliseconds: 500),
          ),
        );
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        tileColor: Colors.white,
        leading: Visibility(
          visible: clip.pinned,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: IconButton(
            onPressed: () {
              onTogglePin();
            },
            icon: Icon(
              Icons.push_pin_rounded,
              size: 16, // Made the icon thinner by reducing its size
            ),
          ),
        ), // Added spacing for unpinned items
        title: Center(
          child: Text(
            overflow: TextOverflow.ellipsis,
            clip.title.isEmpty ? clip.text : clip.title.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              decoration: clip.title.isEmpty ? null : TextDecoration.underline,
            ), // Reduced font size
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.close_rounded,
              size: 20), // Made the icon thinner by reducing its size
          onPressed: () {
            onRemove();
            ScaffoldMessenger.of(context)
                .clearSnackBars(); // Clear existing snack bars
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Clip Deleted'),
                action: SnackBarAction(
                  label: 'UNDO',
                  onPressed: onUndo,
                ),
                duration: Duration(milliseconds: 500),
              ),
            );
          },
        ),
      ),
    );
  }
}
