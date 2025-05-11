import 'package:copy_clip/components/ai_tab_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'components/search.dart';
import 'components/clip_tab_content.dart';
import 'components/note_tab_content.dart';
import 'package:provider/provider.dart';
import 'helper/clip_note_provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    ChangeNotifierProvider(
      create: (context) => ClipNoteProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final clipNoteProvider =
        Provider.of<ClipNoteProvider>(context, listen: false);
    clipNoteProvider.loadClipsFromStorage();
    clipNoteProvider.loadNotesFromStorage();
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clipNoteProvider = Provider.of<ClipNoteProvider>(context);

    final filteredItems = clipNoteProvider.items.where((item) {
      final query = searchQuery.toLowerCase();
      return item.text.toLowerCase().contains(query) ||
          item.title.toLowerCase().contains(query) ||
          item.labels.any((label) => label.toLowerCase().contains(query));
    }).toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) {
          return a.pinned ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    final filteredNotes = clipNoteProvider.notes.where((note) {
      final query = searchQuery.toLowerCase();
      return note.content.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) {
          return a.pinned ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Color(0xFFf8f8f8),
        appBar: AppBar(
          backgroundColor: Color(0xFF1e87f0),
          title: SearchField(
            onChanged: updateSearchQuery,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report_rounded),
              tooltip: 'Report a bug',
              color: Colors.white.withAlpha(204),
              onPressed: () {
                launchUrl(
                  Uri.parse('https://github.com/your-repo/issues'),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black.withAlpha(179),
              indicatorColor: Color(0xFF1e87f0),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: 'Clips'),
                Tab(text: 'Notes'),
                Tab(text: 'Generate'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ClipTabContent(
                    items: filteredItems,
                    onRemove: (id) => clipNoteProvider.removeClipById(id),
                    onAdd: clipNoteProvider.addClip,
                    onTogglePin: (id) => clipNoteProvider.toggleClipPinById(id),
                  ),
                  NoteTabContent(
                    notes: filteredNotes,
                    onRemove: (id) => clipNoteProvider.removeNoteById(id),
                    onAdd: clipNoteProvider.addNote,
                    onTogglePin: (id) => clipNoteProvider.toggleNotePinById(id),
                  ),
                  AiTabContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
