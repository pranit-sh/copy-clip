import 'package:copy_clip/components/note_bottom_sheet.dart';
import 'package:copy_clip/components/note_list_item.dart';
import 'package:flutter/material.dart';
import 'package:copy_clip/models/note.dart';

class NoteTabContent extends StatelessWidget {
  final List<Note> notes;
  final Function(Note) onAdd;
  final Function(String) onRemove;
  final Function(String) onTogglePin;

  const NoteTabContent({
    super.key,
    required this.notes,
    required this.onAdd,
    required this.onRemove,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        notes.isEmpty
            ? Center(
                child: Text(
                  'No notes available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withAlpha(77),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Column(
                    children: [
                      NoteListItem(
                        note: note,
                        onRemove: () => onRemove(note.id),
                        onUndo: () {
                          onAdd(note);
                        },
                        onTogglePin: () {
                          onTogglePin(note.id);
                        },
                      ),
                      if (index < notes.length - 1)
                        Divider(
                          color: Color(0xFFf0f0f0),
                          height: 2,
                        ),
                    ],
                  );
                },
              ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: 40,
              height: 40,
              child: FloatingActionButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: Color(0xFF1e87f0),
                backgroundColor: Colors.white,
                onPressed: () {
                  showModalBottomSheet(
                    backgroundColor: Color(0xFFf8f8f8),
                    context: context,
                    builder: (BuildContext context) {
                      return NoteBottomSheetContent(
                        onAddItem: onAdd,
                      );
                    },
                  );
                },
                child: Icon(Icons.add),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
