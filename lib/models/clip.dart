import 'package:uuid/uuid.dart';

class Clip {
  final String id;
  final String text;
  final String title;
  bool pinned;
  final DateTime createdAt;

  Clip({
    required this.text,
    String? id,
    String? title,
    bool? pinned,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        title = title ?? '',
        pinned = pinned ?? false,
        createdAt = createdAt ?? DateTime.now();

  Clip copyWith({String? text, String? title, bool? pinned}) => Clip(
        id: id,
        text: text ?? this.text,
        title: title ?? this.title,
        pinned: pinned ?? this.pinned,
        createdAt: createdAt,
      );

  factory Clip.fromJson(Map<String, dynamic> json) => Clip(
        id: json['id'] as String?,
        text: json['text'] as String? ?? '',
        title: json['title'] as String?,
        pinned: json['pinned'] as bool?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'title': title,
        'pinned': pinned,
        'createdAt': createdAt.toIso8601String(),
      };
}
