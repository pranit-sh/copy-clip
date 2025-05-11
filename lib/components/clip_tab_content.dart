import 'package:copy_clip/components/clip_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'clip_list_item.dart';
import 'package:copy_clip/models/clip.dart';

class ClipTabContent extends StatelessWidget {
  final List<Clip> items;
  final Function(String) onRemove;
  final Function(Clip) onAdd;
  final Function(String) onTogglePin;

  const ClipTabContent({
    super.key,
    required this.items,
    required this.onRemove,
    required this.onAdd,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        items.isEmpty
            ? Center(
                child: Text(
                  'No clips available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withAlpha(77),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final clip = items[index];
                  return Column(
                    children: [
                      ClipListItem(
                        clip: clip,
                        onRemove: () => onRemove(clip.id),
                        onUndo: () {
                          onAdd(clip);
                        },
                        onTogglePin: () {
                          onTogglePin(clip.id);
                        },
                      ),
                      if (index < items.length - 1)
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
                      return ClipBottomSheetContent(
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
