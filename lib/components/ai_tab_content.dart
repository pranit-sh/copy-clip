import 'package:copy_clip/components/ai_clip_list_item.dart';
import 'package:copy_clip/components/ai_note_list_item.dart';
import 'package:copy_clip/util/glowing_border_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../ai/helper.dart';
import '../helper/clip_note_provider.dart';
import '../models/clip.dart';
import '../models/note.dart';

class AiTabContent extends StatefulWidget {
  const AiTabContent({super.key});

  @override
  AiTabContentState createState() => AiTabContentState();
}

class AiTabContentState extends State<AiTabContent> {
  String? inputText;
  List<dynamic> generatedItems = []; // Can hold either Note or Clip objects
  bool isLoading = false; // Tracks if processText is running
  late final Helper helper;
  final FocusNode _focusNode =
      FocusNode(); // Added FocusNode as a member variable

  @override
  void initState() {
    super.initState();
    if (dotenv.env['GROQ_API_KEY'] != null) {
      setState(() {
        helper = Helper(dotenv.env['GROQ_API_KEY']!);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GROQ_API_KEY is missing in the .env file.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // Focus the TextField as soon as the page is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Dispose the FocusNode to avoid memory leaks
    super.dispose();
  }

  Future<void> processText(String text, bool isClip) async {
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      if (isClip) {
        final clips = await helper.generateClipsFromText(text);
        if (clips.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No clips found.'),
              duration: Duration(milliseconds: 500),
            ),
          );
        }
        setState(() {
          generatedItems = clips
              .where((clip) => clip['text'] != null && clip['text']!.isNotEmpty)
              .map((clip) => Clip(text: clip['text']!))
              .toList();
        });
      } else {
        final notes = await helper.generateNotesFromText(text);
        if (notes.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No notes found.'),
              duration: Duration(milliseconds: 500),
            ),
          );
        }
        setState(() {
          generatedItems = notes
              .where((note) => note['text'] != null && note['text']!.isNotEmpty)
              .map((note) => Note(
                    content: note['text']!,
                    title: note['title']!,
                  ))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Sorry!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // Stop loading
        });
      }
    }
  }

  Future<void> _saveClipToStorage(Clip clip) async {
    final provider = Provider.of<ClipNoteProvider>(context, listen: false);
    provider
        .addClip(clip); // Updated to use addClip instead of saveClipToStorage
    if (mounted) {
      setState(() {
        generatedItems.remove(clip);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to Clips'),
          duration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<void> _saveNoteToStorage(Note note) async {
    final provider = Provider.of<ClipNoteProvider>(context, listen: false);
    provider
        .addNote(note); // Updated to use addNote instead of saveNoteToStorage
    if (mounted) {
      setState(() {
        generatedItems.remove(note);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to Notes'),
          duration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: GlowingBorderWrapper(isLoading: isLoading, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        if (generatedItems.isEmpty) ...[
          Positioned.fill(
            child: TextField(
              focusNode: _focusNode, // Attach the FocusNode to the TextField
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              cursorColor: Colors.black.withValues(alpha: 0.5),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(8),
                hintText: 'Enter text here...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              onChanged: (value) {
                inputText = value;
              },
            ),
          ),
        ] else ...[
          Positioned.fill(
            child: ListView.builder(
              itemCount: generatedItems.length,
              itemBuilder: (context, index) {
                final item = generatedItems[index];
                return Column(
                  children: [
                    item is Clip
                        ? AiClipListItem(
                            clip: item,
                            onAccept: () async {
                              await _saveClipToStorage(item);
                            },
                          )
                        : AiNoteListItem(
                            note: item,
                            onAccept: () async {
                              await _saveNoteToStorage(item);
                            },
                          ),
                    if (index < generatedItems.length - 1)
                      const Divider(
                        color: Color(0xFFf0f0f0),
                        height: 2,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: 40,
              height: 40,
              child: generatedItems.isEmpty && !isLoading
                  ? SpeedDial(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                      icon: Icons.auto_awesome_outlined,
                      activeIcon: Icons.close,
                      activeForegroundColor: Colors.black,
                      foregroundColor: const Color(0xFF1e87f0),
                      children: [
                        SpeedDialChild(
                          label: 'Generate Clips',
                          onTap: () async {
                            FocusScope.of(context).unfocus();
                            if (inputText != null && inputText!.isNotEmpty) {
                              await processText(inputText!, true);
                            }
                          },
                        ),
                        SpeedDialChild(
                          label: 'Generate Notes',
                          onTap: () async {
                            FocusScope.of(context).unfocus();
                            if (inputText != null && inputText!.isNotEmpty) {
                              await processText(inputText!, false);
                            }
                          },
                        ),
                      ],
                    )
                  : FloatingActionButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: const Color(0xFF1e87f0),
                      backgroundColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          generatedItems = [];
                        });
                      },
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.black),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
