import 'package:uuid/uuid.dart';

class Clip {
  final String id;
  final String text;
  bool pinned;
  final List<String> labelIDs;
  final String createdAt;
  final String title;
  final List<String> labels;

  Clip({
    required this.text,
    String? id,
    bool? pinned,
    List<String>? labelIDs,
    String? createdAt,
    String? title,
    List<String>? labels,
  })  : id = id ?? const Uuid().v4(),
        pinned = pinned ?? false,
        labelIDs = labelIDs ?? [],
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        title = title ?? '',
        labels = labels ?? [];

  factory Clip.fromJson(Map<String, dynamic> json) {
    return Clip(
      id: json['id'] as String?,
      text: json['text'] as String,
      pinned: json['pinned'] as bool?,
      labelIDs: (json['labelIDs'] as List<dynamic>?)?.cast<String>(),
      createdAt: json['createdAt'] as String?,
      title: json['title'] as String?,
      labels: (json['labels'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'pinned': pinned,
      'labelIDs': labelIDs,
      'createdAt': createdAt,
      'title': title,
      'labels': labels,
    };
  }
}
