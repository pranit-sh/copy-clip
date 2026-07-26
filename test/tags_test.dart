import 'package:flutter_test/flutter_test.dart';

import 'package:copy_clip/models/clip.dart';
import 'package:copy_clip/util/tags.dart';

void main() {
  group('normalizeUserTag', () {
    test('lowercases, trims, and enforces charset', () {
      expect(normalizeUserTag('  Work '), 'work');
      expect(normalizeUserTag('Work Login'), 'work-login');
      expect(normalizeUserTag('WORK/login!'), 'worklogin');
      expect(normalizeUserTag('под'), null); // no allowed chars left
      expect(normalizeUserTag(''), null);
      expect(normalizeUserTag('   '), null);
    });

    test('rejects reserved system tags', () {
      for (final r in ['url', 'email', 'code', 'secret']) {
        expect(normalizeUserTag(r), null, reason: 'reserved: $r');
      }
    });

    test('truncates over-long tags', () {
      final t = normalizeUserTag('a' * 40);
      expect(t!.length, kMaxTagLength);
    });
  });

  group('normalizeTagList', () {
    test('dedupes, preserves order, caps count', () {
      final out = normalizeTagList([
        'Work', 'work', 'Snippets', 'code', // 'code' reserved -> dropped
        'a', 'b', 'c', 'd', // pushes past cap
      ]);
      expect(out, ['work', 'snippets', 'a', 'b', 'c']);
      expect(out.length, kMaxTagsPerClip);
    });
  });

  group('autoTagsFor', () {
    test('detects urls', () {
      expect(autoTagsFor('https://example.com'), contains('url'));
      expect(autoTagsFor('www.example.com/path'), contains('url'));
      expect(autoTagsFor('not a url'), isNot(contains('url')));
    });

    test('detects emails', () {
      expect(autoTagsFor('me@example.com'), contains('email'));
      expect(autoTagsFor('me @ example .com'), isNot(contains('email')));
    });

    test('detects code-shaped text', () {
      const snippet = '''
if (x) {
  return y;
}
''';
      expect(autoTagsFor(snippet), contains('code'));
      expect(autoTagsFor('just a sentence'), isNot(contains('code')));
    });

    test('detects secrets conservatively', () {
      expect(autoTagsFor('sk_live_abcdefghijklmnopqrstuv'), contains('secret'));
      expect(
        autoTagsFor('Bearer abcdefghijklmnopqrstuvwxyz012345'),
        contains('secret'),
      );
      expect(autoTagsFor('hello world'), isNot(contains('secret')));
    });
  });

  group('Clip', () {
    test('allTags merges user + auto without duplication', () {
      final c = Clip(
        text: 'https://example.com',
        userTags: ['stripe', 'billing'],
      );
      expect(c.userTags, ['stripe', 'billing']);
      expect(c.autoTags, contains('url'));
      expect(c.allTags, containsAllInOrder(['stripe', 'billing', 'url']));
    });

    test('hasTag matches both user and auto tags', () {
      final c = Clip(text: 'me@example.com', userTags: ['work']);
      expect(c.hasTag('work'), isTrue);
      expect(c.hasTag('email'), isTrue);
      expect(c.hasTag('nope'), isFalse);
    });

    test('json roundtrip preserves user tags but not auto tags', () {
      final c = Clip(
        text: 'https://example.com',
        userTags: ['work', 'link'],
      );
      final j = c.toJson();
      final back = Clip.fromJson(Map<String, dynamic>.from(j));
      expect(back.userTags, ['work', 'link']);
      // Auto tags are recomputed, not stored.
      expect(j['tags'], ['work', 'link']);
      expect(back.autoTags, contains('url'));
    });
  });
}
