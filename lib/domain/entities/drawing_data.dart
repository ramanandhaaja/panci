import 'package:flutter/foundation.dart';
import 'package:panci/domain/entities/drawing_stroke.dart';

/// Represents the complete drawing data for a canvas.
///
/// This is an immutable entity that contains all strokes on a canvas along
/// with metadata. It provides methods for managing strokes while maintaining
/// immutability through copy-on-write semantics.
@immutable
class DrawingData {
  /// Creates drawing data for a canvas.
  const DrawingData({
    required this.canvasId,
    required this.strokes,
    required this.lastUpdated,
    required this.version,
  });

  /// Creates an empty drawing data for a new canvas.
  factory DrawingData.empty(String canvasId) {
    return DrawingData(
      canvasId: canvasId,
      strokes: const [],
      lastUpdated: DateTime.now(),
      version: 0,
    );
  }

  /// The unique identifier for this canvas.
  final String canvasId;

  /// The list of all strokes on this canvas.
  ///
  /// Strokes are ordered by their timestamp (oldest first).
  final List<DrawingStroke> strokes;

  /// When this drawing was last updated.
  final DateTime lastUpdated;

  /// Version number for this drawing, incremented with each modification.
  ///
  /// Useful for conflict resolution in collaborative scenarios.
  final int version;

  /// The number of strokes currently on the canvas.
  int get strokeCount => strokes.length;

  /// Maximum number of strokes allowed on a canvas.
  static const int maxStrokes = 1000;

  /// Checks if a new stroke can be added to this canvas.
  ///
  /// Returns false if the canvas has reached the maximum stroke limit.
  bool get canAddStroke => strokeCount < maxStrokes;

  /// Adds a new stroke to the canvas.
  ///
  /// Returns a new [DrawingData] instance with the stroke added.
  /// Throws [StateError] if the maximum stroke limit has been reached.
  DrawingData addStroke(DrawingStroke stroke) {
    if (!canAddStroke) {
      throw StateError(
        'Cannot add stroke: maximum limit of $maxStrokes strokes reached',
      );
    }

    return copyWith(
      strokes: [...strokes, stroke],
      lastUpdated: DateTime.now(),
      version: version + 1,
    );
  }

  /// Removes a stroke from the canvas by its ID.
  ///
  /// Returns a new [DrawingData] instance with the stroke removed.
  /// If the stroke ID is not found, returns a copy with no changes.
  DrawingData removeStroke(String strokeId) {
    final newStrokes = strokes.where((s) => s.id != strokeId).toList();

    // If no stroke was removed, return this instance unchanged
    if (newStrokes.length == strokes.length) {
      return this;
    }

    return copyWith(
      strokes: newStrokes,
      lastUpdated: DateTime.now(),
      version: version + 1,
    );
  }

  /// Removes the last stroke from the canvas.
  ///
  /// Returns a new [DrawingData] instance with the last stroke removed,
  /// or returns this instance if there are no strokes.
  DrawingData removeLastStroke() {
    if (strokes.isEmpty) {
      return this;
    }

    return copyWith(
      strokes: strokes.sublist(0, strokes.length - 1),
      lastUpdated: DateTime.now(),
      version: version + 1,
    );
  }

  /// Clears all strokes from the canvas.
  ///
  /// Returns a new [DrawingData] instance with an empty stroke list.
  DrawingData clear() {
    if (strokes.isEmpty) {
      return this;
    }

    return copyWith(
      strokes: const [],
      lastUpdated: DateTime.now(),
      version: version + 1,
    );
  }

  /// Creates a copy of this drawing data with the given fields replaced.
  DrawingData copyWith({
    String? canvasId,
    List<DrawingStroke>? strokes,
    DateTime? lastUpdated,
    int? version,
  }) {
    return DrawingData(
      canvasId: canvasId ?? this.canvasId,
      strokes: strokes ?? this.strokes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DrawingData &&
        other.canvasId == canvasId &&
        _listEquals(other.strokes, strokes) &&
        other.lastUpdated == lastUpdated &&
        other.version == version;
  }

  @override
  int get hashCode {
    return Object.hash(
      canvasId,
      Object.hashAll(strokes),
      lastUpdated,
      version,
    );
  }

  @override
  String toString() {
    return 'DrawingData(canvasId: $canvasId, strokeCount: $strokeCount, '
        'lastUpdated: $lastUpdated, version: $version)';
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
