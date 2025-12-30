import 'package:flutter/material.dart';
import 'package:panci/presentation/screens/home_screen.dart';
import 'package:panci/presentation/screens/canvas_join_screen.dart';
import 'package:panci/presentation/screens/drawing_canvas_screen.dart';

void main() {
  runApp(const PanciApp());
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
