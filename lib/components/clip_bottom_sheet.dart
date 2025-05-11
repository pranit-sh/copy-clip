import 'package:flutter/material.dart';
import 'package:copy_clip/models/clip.dart';
import 'package:flutter/services.dart';

class ClipBottomSheetContent extends StatefulWidget {
  final Function(Clip) onAddItem;

  const ClipBottomSheetContent({super.key, required this.onAddItem});

  @override
  ClipBottomSheetContentState createState() => ClipBottomSheetContentState();
}

class ClipBottomSheetContentState extends State<ClipBottomSheetContent> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _labelsController = TextEditingController();
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
    _labelsController.dispose();
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
    );
  }

  Widget _buildTextField({
    required String hintText,
    required String labelText,
    TextEditingController? controller,
    bool isMultiline = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: isMultiline ? null : 40.0,
      child: FocusableActionDetector(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (e) {
            if (_textController.text.isNotEmpty) {
              widget.onAddItem(
                Clip(
                  text: _textController.text,
                  title: _titleController.text,
                  labels: _labelsController.text
                      .split(' ')
                      .map((label) => label.startsWith('#') ? label.substring(1) : label)
                      .where((label) => label.isNotEmpty)
                      .toList(),
                ),
              );
              Navigator.pop(context);
            }
            return null;
          }),
        },
        child: TextField(
          controller: controller,
          focusNode: controller == _textController ? _textFocusNode : null,
          decoration: _buildInputDecoration(hintText, labelText),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14.0,
          ),
          textAlignVertical: TextAlignVertical.center,
          maxLines: isMultiline ? null : 1,
          cursorColor: Colors.black.withAlpha(127),
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
            hintText: 'Add your clip here...',
            controller: _textController,
            isMultiline: true,
            labelText: 'Clip',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            hintText: 'Give a title...',
            controller: _titleController,
            labelText: 'Optional Title',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            hintText: '#label1 #label2',
            controller: _labelsController,
            labelText: 'Optional Labels',
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
                  Clip(
                    text: _textController.text,
                    title: _titleController.text,
                    labels: _labelsController.text
                        .split(' ')
                        .map((label) => label.startsWith('#') ? label.substring(1) : label)
                        .where((label) => label.isNotEmpty)
                        .toList(),
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
