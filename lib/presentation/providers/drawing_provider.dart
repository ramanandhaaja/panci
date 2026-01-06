import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:panci/domain/entities/drawing_data.dart';
import 'package:panci/domain/entities/drawing_stroke.dart';
import 'package:panci/domain/services/stroke_smoother.dart';
import 'package:panci/domain/repositories/drawing_repository.dart';
import 'package:panci/data/repositories/repository_provider.dart';

/// Represents the complete state of a drawing canvas.
///
/// This immutable state class holds all data needed for the drawing canvas,
/// including the drawing data, undo/redo stacks, and current drawing state.
@immutable
class DrawingState {
  /// Creates a drawing state.
  const DrawingState({
    required this.currentDrawing,
    this.undoStack = const [],
    this.redoStack = const [],
    this.currentStroke,
    this.isDrawing = false,
  });

  /// The current drawing data for this canvas.
  final DrawingData currentDrawing;

  /// Stack of strokes that have been undone and can be redone.
  final List<DrawingStroke> undoStack;

  /// Stack of strokes that have been removed and can be restored.
  final List<DrawingStroke> redoStack;

  /// The stroke currently being drawn (null if not actively drawing).
  final DrawingStroke? currentStroke;

  /// Flag indicating if a stroke is currently being drawn.
  final bool isDrawing;

  // Computed getters for accessing derived state

  /// Gets whether undo is available.
  bool get canUndo => currentDrawing.strokeCount > 0;

  /// Gets whether redo is available.
  bool get canRedo => redoStack.isNotEmpty;

  /// Gets the number of strokes on the canvas.
  int get strokeCount => currentDrawing.strokeCount;

  /// Gets whether more strokes can be added to the canvas.
  bool get canAddStroke => currentDrawing.canAddStroke;

  /// Gets the percentage of stroke limit used (0.0 to 1.0).
  double get strokeLimitPercentage =>
      strokeCount / DrawingData.maxStrokes;

  /// Creates a copy of this state with the given fields replaced.
  DrawingState copyWith({
    DrawingData? currentDrawing,
    List<DrawingStroke>? undoStack,
    List<DrawingStroke>? redoStack,
    DrawingStroke? currentStroke,
    bool? isDrawing,
    bool clearCurrentStroke = false,
  }) {
    return DrawingState(
      currentDrawing: currentDrawing ?? this.currentDrawing,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      currentStroke: clearCurrentStroke ? null : (currentStroke ?? this.currentStroke),
      isDrawing: isDrawing ?? this.isDrawing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DrawingState &&
        other.currentDrawing == currentDrawing &&
        _listEquals(other.undoStack, undoStack) &&
        _listEquals(other.redoStack, redoStack) &&
        other.currentStroke == currentStroke &&
        other.isDrawing == isDrawing;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentDrawing,
      Object.hashAll(undoStack),
      Object.hashAll(redoStack),
      currentStroke,
      isDrawing,
    );
  }

  @override
  String toString() {
    return 'DrawingState(strokeCount: $strokeCount, isDrawing: $isDrawing, '
        'canUndo: $canUndo, canRedo: $canRedo)';
  }

  /// Helper method to compare lists of strokes.
  bool _listEquals(List<DrawingStroke> a, List<DrawingStroke> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// StateNotifier that manages the drawing state for a canvas.
///
/// This notifier follows clean architecture principles:
/// - Uses domain entities (DrawingData, DrawingStroke)
/// - Calls domain services (StrokeSmoother)
/// - Manages presentation state (undo/redo stacks, current stroke)
/// - Updates state immutably using copyWith pattern
/// - Integrates with repository for data persistence
/// - Subscribes to real-time updates from Firestore
///
/// The notifier implements undo/redo functionality, enforces the
/// maximum stroke limit, and synchronizes with Firebase in real-time.
class DrawingNotifier extends StateNotifier<DrawingState> {
  /// Creates a drawing notifier for a specific canvas.
  DrawingNotifier(
    this._canvasId,
    this._repository, {
    String? userId,
  })  : _userId = userId ?? FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        super(DrawingState(
          currentDrawing: DrawingData.empty(_canvasId),
        ));

  /// UUID generator for creating unique stroke IDs.
  static const _uuid = Uuid();

  /// The ID of the canvas this notifier manages.
  final String _canvasId;

  /// The repository for data persistence.
  final DrawingRepository _repository;

  /// The ID of the current user drawing on this canvas.
  final String _userId;

  /// Subscription to real-time canvas updates.
  StreamSubscription<DrawingData>? _canvasSubscription;

  /// Flag to prevent infinite loops when updating from remote changes.
  bool _isUpdatingFromRemote = false;

  /// Starts a new stroke at the given point.
  ///
  /// This should be called when the user begins a pan gesture.
  ///
  /// Parameters:
  /// - [point]: The starting point in canvas coordinates
  /// - [color]: The color of the stroke
  /// - [width]: The width of the stroke
  void startStroke(Offset point, Color color, double width) {
    // Don't start a new stroke if already drawing or at limit
    if (state.isDrawing || !state.canAddStroke) {
      return;
    }

    final newStroke = DrawingStroke(
      id: _uuid.v4(),
      points: [point],
      color: color,
      strokeWidth: width,
      timestamp: DateTime.now(),
      userId: _userId,
    );

    state = state.copyWith(
      currentStroke: newStroke,
      isDrawing: true,
    );
  }

  /// Adds a point to the current stroke.
  ///
  /// This should be called during a pan gesture as the user moves their finger/cursor.
  ///
  /// Parameters:
  /// - [point]: The new point in canvas coordinates
  void addPoint(Offset point) {
    if (!state.isDrawing || state.currentStroke == null) {
      return;
    }

    // Add the point to the current stroke
    final updatedStroke = state.currentStroke!.copyWith(
      points: [...state.currentStroke!.points, point],
    );

    state = state.copyWith(
      currentStroke: updatedStroke,
    );
  }

  /// Ends the current stroke and adds it to the canvas.
  ///
  /// This should be called when the user completes a pan gesture.
  /// The stroke will be smoothed before being added to the canvas
  /// and saved to Firebase.
  Future<void> endStroke() async {
    if (!state.isDrawing || state.currentStroke == null) {
      return;
    }

    // Apply smoothing to the stroke if it has enough points
    final rawPoints = state.currentStroke!.points;
    final smoothedPoints = rawPoints.length >= 4
        ? StrokeSmoother.smoothPoints(rawPoints)
        : rawPoints;

    // Create the final stroke with smoothed points
    final finalStroke = state.currentStroke!.copyWith(
      points: smoothedPoints,
    );

    // Add the stroke to the drawing locally first (optimistic update)
    try {
      final updatedDrawing = state.currentDrawing.addStroke(finalStroke);

      state = state.copyWith(
        currentDrawing: updatedDrawing,
        currentStroke: null,
        isDrawing: false,
        redoStack: const [], // Clear the redo stack since we've made a new change
        clearCurrentStroke: true,
      );

      // Save to Firebase asynchronously
      // Don't await to keep UI responsive
      _repository.saveStroke(_canvasId, finalStroke).catchError((error) {
        debugPrint('Error saving stroke to Firebase: $error');
        // TODO: Implement retry logic or offline queue
      });
    } catch (e) {
      // If we can't add the stroke (e.g., at limit), just clear current state
      debugPrint('Failed to add stroke: $e');
      state = state.copyWith(
        currentStroke: null,
        isDrawing: false,
        clearCurrentStroke: true,
      );
    }
  }

  /// Undoes the last stroke.
  ///
  /// Removes the most recent stroke from the canvas and adds it to the
  /// redo stack so it can be restored. Also removes it from Firebase.
  Future<void> undo() async {
    if (!state.canUndo) {
      return;
    }

    // Get the last stroke before removing it
    final lastStroke = state.currentDrawing.strokes.last;

    // Remove it from the drawing locally (optimistic update)
    final updatedDrawing = state.currentDrawing.removeLastStroke();

    // Add it to the redo stack
    state = state.copyWith(
      currentDrawing: updatedDrawing,
      redoStack: [...state.redoStack, lastStroke],
    );

    // Remove from Firebase asynchronously
    _repository.removeStroke(_canvasId, lastStroke.id).catchError((error) {
      debugPrint('Error removing stroke from Firebase: $error');
      // TODO: Implement retry logic or rollback
    });
  }

  /// Redoes the last undone stroke.
  ///
  /// Restores the most recently undone stroke to the canvas and Firebase.
  Future<void> redo() async {
    if (!state.canRedo) {
      return;
    }

    // Get the stroke from the redo stack
    final strokeToRestore = state.redoStack.last;
    final newRedoStack = state.redoStack.sublist(0, state.redoStack.length - 1);

    // Add it back to the drawing locally (optimistic update)
    try {
      final updatedDrawing = state.currentDrawing.addStroke(strokeToRestore);

      state = state.copyWith(
        currentDrawing: updatedDrawing,
        redoStack: newRedoStack,
      );

      // Save to Firebase asynchronously
      _repository.saveStroke(_canvasId, strokeToRestore).catchError((error) {
        debugPrint('Error saving redone stroke to Firebase: $error');
        // TODO: Implement retry logic or rollback
      });
    } catch (e) {
      // If we can't add it back (e.g., at limit), leave state unchanged
      debugPrint('Failed to redo stroke: $e');
    }
  }

  /// Clears all strokes from the canvas.
  ///
  /// This removes all strokes and clears the undo/redo history.
  /// This action cannot be undone. Also clears from Firebase.
  Future<void> clear() async {
    final clearedDrawing = state.currentDrawing.clear();

    state = state.copyWith(
      currentDrawing: clearedDrawing,
      undoStack: const [],
      redoStack: const [],
      currentStroke: null,
      isDrawing: false,
      clearCurrentStroke: true,
    );

    // Clear from Firebase asynchronously
    _repository.clearCanvas(_canvasId).catchError((error) {
      debugPrint('Error clearing canvas in Firebase: $error');
      // TODO: Implement retry logic
    });
  }

  /// Cancels the current stroke being drawn.
  ///
  /// This is useful if the user's gesture is cancelled or interrupted.
  void cancelCurrentStroke() {
    if (state.isDrawing) {
      state = state.copyWith(
        currentStroke: null,
        isDrawing: false,
        clearCurrentStroke: true,
      );
    }
  }

  /// Loads the canvas data from the repository.
  ///
  /// This should be called when the canvas is first opened to load
  /// the existing drawing data from Firebase.
  Future<void> loadCanvas() async {
    try {
      debugPrint('Loading canvas $_canvasId...');
      final data = await _repository.loadCanvas(_canvasId);

      // Only update if we're not currently drawing
      // to avoid overwriting the user's current stroke
      if (!state.isDrawing) {
        state = state.copyWith(currentDrawing: data);
        debugPrint('Canvas $_canvasId loaded: ${data.strokeCount} strokes');
      }
    } catch (e) {
      debugPrint('Error loading canvas $_canvasId: $e');
      // Keep the current state (empty canvas) on error
    }
  }

  /// Subscribes to real-time canvas updates from Firebase.
  ///
  /// This enables collaborative drawing where changes made by other
  /// users are reflected in real-time. The subscription is automatically
  /// cancelled when the notifier is disposed.
  void subscribeToCanvas() {
    debugPrint('Subscribing to canvas $_canvasId updates...');

    _canvasSubscription = _repository.watchCanvas(_canvasId).listen(
      (data) {
        // Prevent infinite loops - don't update if we're currently
        // processing a remote update
        if (_isUpdatingFromRemote) {
          return;
        }

        _isUpdatingFromRemote = true;

        try {
          // Only update if we're not currently drawing
          // to avoid interrupting the user's current stroke
          if (!state.isDrawing) {
            // Merge remote strokes with local state
            // Keep the current stroke if it exists
            state = state.copyWith(
              currentDrawing: data,
            );

            debugPrint(
              'Canvas $_canvasId updated from remote: ${data.strokeCount} strokes',
            );
          } else {
            debugPrint(
              'Skipping remote update while drawing',
            );
          }
        } finally {
          _isUpdatingFromRemote = false;
        }
      },
      onError: (error) {
        debugPrint('Error in canvas watch stream: $error');
        // Don't update state on error, just log it
      },
    );
  }

  @override
  void dispose() {
    debugPrint('Disposing DrawingNotifier for canvas $_canvasId');
    _canvasSubscription?.cancel();
    super.dispose();
  }
}

/// Global provider for managing drawing state per canvas.
///
/// Uses the .family modifier to create a separate state instance for each
/// canvas ID. This ensures that different canvases maintain independent state.
///
/// The provider:
/// - Creates a DrawingNotifier with repository integration
/// - Loads initial canvas data from Firebase
/// - Subscribes to real-time updates
/// - Automatically disposes subscriptions when the provider is disposed
///
/// Usage:
/// ```dart
/// // Watch the state (rebuilds on changes)
/// final drawingState = ref.watch(drawingProvider(canvasId));
///
/// // Read the notifier to call methods (doesn't rebuild)
/// ref.read(drawingProvider(canvasId).notifier).startStroke(...);
/// ```
final drawingProvider = StateNotifierProvider.family<DrawingNotifier, DrawingState, String>(
  (ref, canvasId) {
    // Get the repository from the provider
    final repository = ref.watch(drawingRepositoryProvider);

    // Create the notifier with repository
    final notifier = DrawingNotifier(canvasId, repository);

    // Load initial data and subscribe to updates
    // These are called synchronously but execute asynchronously
    notifier.loadCanvas();
    notifier.subscribeToCanvas();

    return notifier;
  },
);
