import 'package:copy_clip/models/note.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onRemove;
  final VoidCallback onUndo;
  final VoidCallback onTogglePin;

  const NoteListItem({
    super.key,
    required this.note,
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
        showModalBottomSheet(
          backgroundColor: Color(0xFFf8f8f8),
          isScrollControlled: true,
          context: context,
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height *
                  0.95, // Almost full screen
              padding: EdgeInsets.all(16),
              child: Stack(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        note.content,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all<Color>(
                            Color(0xFFf8f8f8)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Clipboard.setData(ClipboardData(text: note.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied'),
                            duration: Duration(milliseconds: 500),
                          ),
                        );
                      },
                      icon: Icon(Icons.copy, size: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        tileColor: Colors.white,
        leading: Visibility(
          visible: note.pinned,
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
            note.title.isEmpty ? note.content : note.title.toUpperCase(),
            style: TextStyle(
              fontSize: 14, // Reduced font size
              decoration: note.title.isEmpty ? null : TextDecoration.underline,
            ),
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
