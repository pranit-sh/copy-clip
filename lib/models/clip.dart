import 'package:uuid/uuid.dart';

import '../util/tags.dart';

class Clip {
  final String id;
  final String text;
  final String title;
  bool pinned;
  final DateTime createdAt;

  /// User-authored tags, already normalized (lowercased, `[a-z0-9-_]` only,
  /// deduped, capped at [kMaxTagsPerClip]). System-owned tags like `url`,
  /// `email`, `code`, `secret` are NOT stored here — they're derived from
  /// [text] via [autoTagsFor] on demand.
  final List<String> userTags;

  Clip({
    required this.text,
    String? id,
    String? title,
    bool? pinned,
    DateTime? createdAt,
    List<String>? userTags,
  })  : id = id ?? const Uuid().v4(),
        title = title ?? '',
        pinned = pinned ?? false,
        createdAt = createdAt ?? DateTime.now(),
        userTags = normalizeTagList(userTags ?? const []);

  /// Auto-computed system tags based on content.
  Set<String> get autoTags => autoTagsFor(text);

  /// All tags (user + auto), deduped, user tags first for display.
  List<String> get allTags {
    final auto = autoTags;
    return [
      ...userTags,
      ...auto.where((t) => !userTags.contains(t)),
    ];
  }

  bool hasTag(String tag) {
    final n = tag.trim().toLowerCase();
    if (n.isEmpty) return false;
    if (userTags.contains(n)) return true;
    if (kReservedTags.contains(n) && autoTags.contains(n)) return true;
    return false;
  }

  Clip copyWith({
    String? text,
    String? title,
    bool? pinned,
    List<String>? userTags,
  }) =>
      Clip(
        id: id,
        text: text ?? this.text,
        title: title ?? this.title,
        pinned: pinned ?? this.pinned,
        createdAt: createdAt,
        userTags: userTags ?? this.userTags,
      );

  factory Clip.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    List<String>? tags;
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    }
    return Clip(
      id: json['id'] as String?,
      text: json['text'] as String? ?? '',
      title: json['title'] as String?,
      pinned: json['pinned'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      userTags: tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'title': title,
        'pinned': pinned,
        'createdAt': createdAt.toIso8601String(),
        'tags': userTags,
      };
}
