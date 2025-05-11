import 'package:flutter/material.dart';
import 'package:copy_clip/models/clip.dart';
import 'package:copy_clip/models/note.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ClipNoteProvider extends ChangeNotifier {
  List<Clip> _items = [];
  List<Note> _notes = [];

  List<Clip> get items => _items;
  List<Note> get notes => _notes;

  Future<void> loadClipsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedClips = prefs.getString('clips');
    if (storedClips != null) {
      final List<dynamic> decodedClips = jsonDecode(storedClips);
      _items = decodedClips.map((clip) => Clip.fromJson(clip)).toList();
      notifyListeners();
    }
  }

  Future<void> loadNotesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedNotes = prefs.getString('notes');
    if (storedNotes != null) {
      final List<dynamic> decodedNotes = jsonDecode(storedNotes);
      _notes = decodedNotes.map((note) => Note.fromJson(note)).toList();
      notifyListeners();
    }
  }

  void addClip(Clip clip) {
    _items.add(clip);
    saveAllClipsToStorage();
    notifyListeners();
  }

  void addNote(Note note) {
    _notes.add(note);
    saveAllNotesToStorage();
    notifyListeners();
  }

  void removeClipById(String id) {
    _items.removeWhere((clip) => clip.id == id);
    saveAllClipsToStorage();
    notifyListeners();
  }

  void removeNoteById(String id) {
    _notes.removeWhere((note) => note.id == id);
    saveAllNotesToStorage();
    notifyListeners();
  }

  void toggleClipPinById(String id) {
    final clip = _items.firstWhere((clip) => clip.id == id, orElse: () => throw StateError('Clip not found'));
    clip.pinned = !clip.pinned;
    saveAllClipsToStorage();
    notifyListeners();
  }

  void toggleNotePinById(String id) {
    final note = _notes.firstWhere((note) => note.id == id, orElse: () => throw StateError('Note not found'));
    note.pinned = !note.pinned;
    saveAllNotesToStorage();
    notifyListeners();
  }

  Future<void> saveAllClipsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedClips = jsonEncode(_items.map((clip) => clip.toJson()).toList());
    await prefs.setString('clips', encodedClips);
  }

  Future<void> saveAllNotesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedNotes = jsonEncode(_notes.map((note) => note.toJson()).toList());
    await prefs.setString('notes', encodedNotes);
  }
}