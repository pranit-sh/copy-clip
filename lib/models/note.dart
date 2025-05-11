import 'package:uuid/uuid.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final String createdAt;
  bool pinned;

  Note({
    String? id,
    String? title,
    String? content,
    String? createdAt,
    bool? pinned,
  })  : id = id ?? const Uuid().v4(),
        title = title ?? '',
        content = content ?? '',
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        pinned = pinned ?? false;

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      createdAt: json['createdAt'] as String?,
      pinned: json['pinned'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'pinned': pinned,
    };
  }
}
