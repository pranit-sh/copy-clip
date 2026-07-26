// Smoke test — just makes sure the app boots.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:copy_clip/helper/clip_note_provider.dart';
import 'package:copy_clip/main.dart';

void main() {
  testWidgets('CopyClipApp boots', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ClipNoteProvider()..load(),
        child: const CopyClipApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
