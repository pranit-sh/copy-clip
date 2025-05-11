import 'package:copy_clip/models/note.dart';
import 'package:flutter/material.dart';

class AiNoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onAccept;

  const AiNoteListItem({
    super.key,
    required this.note,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
              child: Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    note.content,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            );
          },
        );
      },
      child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
          tileColor: Colors.white, // Added spacing for unpinned items
          title: Center(
            child: Text(
              overflow: TextOverflow.ellipsis,
              note.title.isEmpty ? note.content : note.title,
              style: TextStyle(fontSize: 14), // Reduced font size
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.check_rounded,
                size: 20), // Made the icon thinner by reducing its size
            onPressed: () {
              onAccept();
            },
          )),
    );
  }
}
