import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:panci/presentation/screens/home_screen.dart';
import 'package:panci/presentation/screens/canvas_join_screen.dart';
import 'package:panci/presentation/screens/drawing_canvas_screen.dart';

/// Main entry point of the Panci application.
///
/// Initializes Firebase services and sets up the app with:
/// - Firebase Core for backend services
/// - Anonymous authentication for user identification
/// - Riverpod for state management
///
/// The initialization is asynchronous, so we use async/await
/// and WidgetsFlutterBinding.ensureInitialized() to prepare
/// the Flutter framework before Firebase initialization.
void main() async {
  // Ensure Flutter framework is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with platform-specific configuration
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Sign in anonymously to enable Firestore security rules
    // This provides each user with a unique user ID without requiring
    // explicit sign-up or login
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    debugPrint('Signed in anonymously with user ID: ${userCredential.user?.uid}');
  } catch (e, stackTrace) {
    // Log initialization errors but continue to run the app
    // The app will show error messages when trying to use Firebase features
    debugPrint('Error initializing Firebase: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  // Run the app with Riverpod provider scope
  runApp(
    const ProviderScope(
      child: PanciApp(),
    ),
  );
}

/// Root widget of the Panci shared canvas application.
///
/// Configures Material Design 3 theme, navigation routes, and app-wide settings.
class PanciApp extends StatelessWidget {
  const PanciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panci - Shared Canvas',
      debugShowCheckedModeBanner: false,

      // Material Design 3 theme configuration
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,

        // Card theme
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),

        // AppBar theme
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),

        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Dark theme configuration (optional, for future use)
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,

        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),

        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Set theme mode (can be changed to ThemeMode.system for automatic)
      themeMode: ThemeMode.light,

      // Initial route
      initialRoute: '/',

      // Named routes configuration
      routes: {
        '/': (context) => const HomeScreen(),
        '/join': (context) => const CanvasJoinScreen(),
      },

      // Handle routes that require arguments (like drawing screen)
      onGenerateRoute: (settings) {
        if (settings.name == '/drawing') {
          // Extract canvas ID from route arguments
          final canvasId = settings.arguments as String?;

          if (canvasId != null) {
            // With Riverpod family providers, we don't need to wrap with a provider here
            // The provider is accessed directly in the screen using ref
            return MaterialPageRoute(
              builder: (context) => DrawingCanvasScreen(canvasId: canvasId),
              settings: settings,
            );
          }
        }

        // Return null to fall back to onUnknownRoute
        return null;
      },

      // Handle unknown routes (404 fallback)
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        );
      },
    );
  }
}
