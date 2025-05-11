import 'package:copy_clip/models/note.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NoteBottomSheetContent extends StatefulWidget {
  final Function(Note) onAddItem;

  const NoteBottomSheetContent({super.key, required this.onAddItem});

  @override
  NoteBottomSheetContentState createState() => NoteBottomSheetContentState();
}

class NoteBottomSheetContentState extends State<NoteBottomSheetContent> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String hintText, String labelText) {
    return InputDecoration(
      contentPadding: const EdgeInsets.all(8),
      hintText: hintText,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: BorderSide(color: Colors.black.withAlpha(76)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: BorderSide(color: Colors.black.withAlpha(25)),
      ),
      hintStyle: TextStyle(
        color: Colors.black.withAlpha(127),
        fontSize: 14.0,
      ),
      label: Text(
        labelText,
        style: TextStyle(
          color: Colors.black.withAlpha(102),
          fontSize: 14.0,
        ),
      ),
      alignLabelWithHint: true
    );
  }

  Widget _buildTextField(String hintText, String labelText) {
    return Expanded(
      child: FocusableActionDetector(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (e) {
            if (_textController.text.isNotEmpty) {
              widget.onAddItem(
                Note(
                  title: _titleController.text,
                  content: _textController.text,
                ),
              );
              Navigator.pop(context);
            }
            return null;
          }),
        },
        child: TextField(
          controller: _textController,
          focusNode: _textFocusNode,
          decoration: _buildInputDecoration(hintText, labelText),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14.0,
          ),
          cursorColor: Colors.black.withValues(alpha: 0.5),
          maxLines: null,
          minLines: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(
            'Enter your note here...',
            'Note',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: _buildInputDecoration(
              'Give a title...',
              'Optional title',
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14.0,
            ),
            onSubmitted: (_) {
              if (_textController.text.isNotEmpty) {
                widget.onAddItem(
                  Note(
                    title: _titleController.text,
                    content: _textController.text,
                  ),
                );
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                widget.onAddItem(
                  Note(
                    title: _titleController.text,
                    content: _textController.text,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
