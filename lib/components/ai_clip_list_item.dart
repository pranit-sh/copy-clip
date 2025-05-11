import 'package:flutter/material.dart';
import 'package:copy_clip/models/clip.dart';

class AiClipListItem extends StatelessWidget {
  final Clip clip;
  final VoidCallback onAccept;

  const AiClipListItem({
    super.key,
    required this.clip,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      tileColor: Colors.white, // Added spacing for unpinned items
      title: Center(
        child: Text(
          overflow: TextOverflow.ellipsis,
          clip.title.isEmpty ? clip.text : clip.title,
          style: TextStyle(fontSize: 14), // Reduced font size
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.check_rounded,
            size: 20), // Made the icon thinner by reducing its size
        onPressed: () {
          onAccept();
        },
      ),
    );
  }
}
