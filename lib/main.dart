import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/home_screen.dart';
import 'helper/clip_note_provider.dart';
import 'util/theme.dart';
import 'web_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WebBridge.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ClipNoteProvider()..load(),
      child: const CopyClipApp(),
    ),
  );
}

class CopyClipApp extends StatelessWidget {
  const CopyClipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Copy Clip',
      theme: AppTheme.build(),
      home: const HomeScreen(),
    );
  }
}
