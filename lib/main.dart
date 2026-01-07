import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'state/subject_provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/subject_overview_screen.dart';
import 'screens/flashcard_builder_screen.dart';
import 'screens/flashcard_review_screen.dart';
import 'pages/chat_page.dart';
// removed unused page imports (keep if you navigate to these pages elsewhere)
import 'state/theme_provider.dart' as tp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables from .env (see .env.example)
  await dotenv.load(fileName: '.env');
  // Initialize Firebase
  try {
    FirebaseOptions? options;
    try {
      options = DefaultFirebaseOptions.currentPlatform;
    } catch (e) {
      // DefaultFirebaseOptions throws for unsupported platforms (e.g., when not configured).
      options = null;
    }

    if (options != null) {
      await Firebase.initializeApp(options: options);
    } else {
      // If no generated options for this platform, attempt default initialization
      // which relies on platform-specific config files (google-services.json / plist).
      await Firebase.initializeApp();
    }
  } catch (e, st) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('$st');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SubjectProvider(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: tp.themeNotifier,
        builder: (context, mode, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: tp.AppTheme.lightThemeFinal(),
          darkTheme: tp.AppTheme.darkThemeFinal(),
          // Start app on the SplashScreen, which will navigate to Home when ready.
          // Wrap SplashScreen in the original lightweight theme so splash is not affected by the new app theme.
          home: Theme(data: tp.AppTheme.lightThemeFinal(), child: const SplashScreen()),
          routes: {
            HomeScreen.routeName: (_) => const HomeScreen(),
          },
          onGenerateRoute: (settings) {
            // Simple route parsing for subject paths
            final uri = Uri.parse(settings.name ?? '');
            if (uri.pathSegments.isEmpty) return null;
            if (uri.pathSegments[0] == 'subject' && uri.pathSegments.length >= 2) {
              final id = uri.pathSegments[1];
              if (uri.pathSegments.length == 2) {
                final args = settings.arguments as dynamic;
                final subject = args is Subject ? args : Subject(id: id, title: id);
                return MaterialPageRoute(builder: (_) => SubjectOverviewScreen(subject: subject));
              }
              if (uri.pathSegments.length >= 3 && uri.pathSegments[2] == 'new') {
                final args = settings.arguments as dynamic;
                final subject = args is Subject ? args : Subject(id: id, title: id);
                return MaterialPageRoute(builder: (_) => FlashcardBuilderScreen(subject: subject));
              }
              if (uri.pathSegments.length >= 4 && uri.pathSegments[2] == 'review') {
                  final args = settings.arguments as dynamic;
                final subject = args is Map ? args['subject'] as Subject : Subject(id: id, title: id);
                final cards = args is Map ? args['cards'] as List<Flashcard> : <Flashcard>[];
                return MaterialPageRoute(builder: (_) => FlashcardReviewScreen(subject: subject, cards: cards, startIndex: 0));
              }
            }
            if (uri.pathSegments[0] == 'chat' && uri.pathSegments.length >= 2) {
              final args = settings.arguments as dynamic;
              final title = args is Map && args['subjectName'] != null ? args['subjectName'] : 'Chat';
              return MaterialPageRoute(builder: (_) => ChatPage(title: '$title — Chat', initialMessages: []));
            }
            return null;
          },
        ),
      ),
    );
  }
}

