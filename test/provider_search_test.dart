import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:copy_clip/helper/clip_note_provider.dart';
import 'package:copy_clip/models/clip.dart';

void main() {
  setUp(() {
    // Fresh in-memory prefs for each test.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('tag search: tag: operator filters by user tags', () async {
    final p = ClipNoteProvider();
    await p.load();
    await p.addClip(Clip(text: 'first', userTags: ['work']));
    await p.addClip(Clip(text: 'second', userTags: ['personal']));
    await p.addClip(Clip(text: 'third', userTags: ['work', 'urgent']));

    final workOnly = p.search('tag:work');
    expect(workOnly.map((c) => c.text), containsAll(['first', 'third']));
    expect(workOnly.length, 2);

    final workAndText = p.search('tag:work third');
    expect(workAndText.map((c) => c.text), ['third']);
  });

  test('tag search: activeTag narrows results in addition to query', () async {
    final p = ClipNoteProvider();
    await p.load();
    await p.addClip(Clip(text: 'apple pie', userTags: ['food']));
    await p.addClip(Clip(text: 'apple stock', userTags: ['finance']));

    final filtered = p.search('apple', activeTag: 'food');
    expect(filtered.map((c) => c.text), ['apple pie']);
  });

  test('tag search: matches auto-tags too', () async {
    final p = ClipNoteProvider();
    await p.load();
    await p.addClip(Clip(text: 'https://example.com'));
    await p.addClip(Clip(text: 'plain text'));

    final urls = p.search('tag:url');
    expect(urls.length, 1);
    expect(urls.first.text, 'https://example.com');
  });

  test('userTagUsage ranks by frequency', () async {
    final p = ClipNoteProvider();
    await p.load();
    await p.addClip(Clip(text: 'a', userTags: ['x']));
    await p.addClip(Clip(text: 'b', userTags: ['x', 'y']));
    await p.addClip(Clip(text: 'c', userTags: ['y']));
    await p.addClip(Clip(text: 'd', userTags: ['y']));

    final usage = p.userTagUsage;
    expect(usage.first.tag, 'y'); // 3 uses
    expect(usage.first.count, 3);
    expect(usage[1].tag, 'x'); // 2 uses
  });

  test('addClip dedupes on identical text and merges tags', () async {
    final p = ClipNoteProvider();
    await p.load();
    await p.addClip(Clip(text: 'hello', userTags: ['a']));
    await p.addClip(Clip(text: 'hello', userTags: ['b']));

    expect(p.items.length, 1);
    expect(p.items.first.userTags, containsAll(['a', 'b']));
  });

  test('clearAll removes clips and persists empty state', () async {
    final p = ClipNoteProvider();
    await p.load();
    await p.addClip(Clip(text: 'hello', userTags: ['a']));
    await p.addClip(Clip(text: 'world', userTags: ['b']));

    await p.clearAll();

    expect(p.items, isEmpty);
    expect(p.userTagUsage, isEmpty);

    final reloaded = ClipNoteProvider();
    await reloaded.load();
    expect(reloaded.items, isEmpty);
  });

  test('is:pinned filter works', () async {
    final p = ClipNoteProvider();
    await p.load();
    await p.addClip(Clip(text: 'a'));
    await p.addClip(Clip(text: 'b'));
    await p.togglePin(p.items.firstWhere((c) => c.text == 'b').id);

    final pinned = p.search('is:pinned');
    expect(pinned.map((c) => c.text), ['b']);
  });

  test('debugDefaultTargetPlatformOverride does not leak', () {
    // Placeholder to keep test setUp/tearDown discipline explicit.
    expect(debugDefaultTargetPlatformOverride, isNull);
  });
}
