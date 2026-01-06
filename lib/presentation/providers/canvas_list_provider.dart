import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panci/domain/entities/canvas_entity.dart';

/// Provider that fetches the list of recent canvases from Firebase.
///
/// This provider queries Firestore for canvas documents, ordered by
/// lastUpdated timestamp. It converts the Firestore data into
/// CanvasEntity domain objects for display on the home screen.
///
/// The provider returns a list of canvases sorted by most recent first.
/// If there are no canvases, it returns an empty list.
///
/// Usage:
/// ```dart
/// final canvasesAsync = ref.watch(canvasListProvider);
///
/// canvasesAsync.when(
///   data: (canvases) => ListView(children: canvases.map(...)),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => ErrorWidget(),
/// );
/// ```
final canvasListProvider = StreamProvider<List<CanvasEntity>>((ref) {
  final firestore = FirebaseFirestore.instance;

  // Query canvases collection, ordered by lastUpdated descending
  return firestore
      .collection('canvases')
      .orderBy('lastUpdated', descending: true)
      .limit(10) // Limit to 10 most recent canvases
      .snapshots()
      .map((snapshot) {
    // Convert Firestore documents to CanvasEntity objects
    return snapshot.docs.map((doc) {
      final data = doc.data();

      // Extract canvas metadata from Firestore document
      final canvasId = doc.id;
      final lastUpdated = data['lastUpdated'] != null
          ? DateTime.parse(data['lastUpdated'] as String)
          : DateTime.now();
      final strokes = (data['strokes'] as List<dynamic>?) ?? [];

      // Determine canvas state based on stroke count
      final CanvasState state;
      if (strokes.isEmpty) {
        state = CanvasState.empty;
      } else if (strokes.length < 10) {
        state = CanvasState.minimal;
      } else if (strokes.length < 50) {
        state = CanvasState.sketch;
      } else if (strokes.length < 200) {
        state = CanvasState.geometric;
      } else {
        state = CanvasState.organic;
      }

      // Generate a name based on canvas ID or timestamp
      final name = _generateCanvasName(canvasId, lastUpdated);

      // Check if canvas is active (updated in last 5 minutes)
      final isActive =
          DateTime.now().difference(lastUpdated).inMinutes < 5;

      // Estimate participant count (would need active user tracking)
      final participantCount = 1; // Default to 1 for now

      return CanvasEntity(
        id: canvasId,
        name: name,
        participantCount: participantCount,
        lastUpdated: lastUpdated,
        isActive: isActive,
        state: state,
      );
    }).toList();
  });
});

/// Generates a human-readable name for a canvas.
///
/// If the canvas ID follows a specific pattern, generates a descriptive name.
/// Otherwise, creates a name based on the creation timestamp.
String _generateCanvasName(String canvasId, DateTime lastUpdated) {
  // Try to extract a meaningful name from the ID
  // For now, generate a simple name based on the date
  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));

  if (_isSameDay(lastUpdated, today)) {
    return 'Today\'s Canvas';
  } else if (_isSameDay(lastUpdated, yesterday)) {
    return 'Yesterday\'s Canvas';
  } else if (today.difference(lastUpdated).inDays < 7) {
    final daysAgo = today.difference(lastUpdated).inDays;
    return '$daysAgo days ago';
  } else {
    return 'Canvas ${lastUpdated.month}/${lastUpdated.day}';
  }
}

/// Checks if two DateTime objects represent the same day.
bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Provider that gets the most recent (active) canvas.
///
/// This provider extracts the first canvas from the canvas list,
/// representing the most recently updated canvas.
///
/// Returns null if there are no canvases.
final mostRecentCanvasProvider = Provider<CanvasEntity?>((ref) {
  final canvasesAsync = ref.watch(canvasListProvider);

  return canvasesAsync.when(
    data: (canvases) => canvases.isNotEmpty ? canvases.first : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider that gets the list of recent canvases (excluding the most recent).
///
/// This provider returns all canvases except the first one, which is
/// displayed separately as the "active" canvas.
///
/// Returns an empty list if there are 0 or 1 canvases.
final recentCanvasesProvider = Provider<List<CanvasEntity>>((ref) {
  final canvasesAsync = ref.watch(canvasListProvider);

  return canvasesAsync.when(
    data: (canvases) => canvases.length > 1 ? canvases.sublist(1) : [],
    loading: () => [],
    error: (_, __) => [],
  );
});
