import 'package:flutter/material.dart';

/// Represents a single drawing stroke on the canvas.
///
/// This is an immutable entity that contains all the data for a stroke drawn
/// by a user, including the path points, visual properties, and metadata.
/// Following clean architecture, this entity has no Flutter dependencies
/// except for basic types like Offset and Color which are pure data classes.
@immutable
class DrawingStroke {
  /// Creates a drawing stroke.
  ///
  /// All parameters are required to ensure a complete stroke representation.
  const DrawingStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.timestamp,
    required this.userId,
  });

  /// Unique identifier for this stroke.
  final String id;

  /// The list of points that make up this stroke's path.
  ///
  /// Points are in canvas coordinate space (not screen space).
  final List<Offset> points;

  /// The color of this stroke.
  final Color color;

  /// The width of this stroke in logical pixels.
  final double strokeWidth;

  /// When this stroke was created.
  final DateTime timestamp;

  /// The ID of the user who created this stroke.
  final String userId;

  /// Creates a copy of this stroke with the given fields replaced with new values.
  DrawingStroke copyWith({
    String? id,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    DateTime? timestamp,
    String? userId,
  }) {
    return DrawingStroke(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DrawingStroke &&
        other.id == id &&
        _listEquals(other.points, points) &&
        other.color == color &&
        other.strokeWidth == strokeWidth &&
        other.timestamp == timestamp &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      Object.hashAll(points),
      color,
      strokeWidth,
      timestamp,
      userId,
    );
  }

  @override
  String toString() {
    return 'DrawingStroke(id: $id, points: ${points.length}, color: $color, '
        'strokeWidth: $strokeWidth, timestamp: $timestamp, userId: $userId)';
  }

  /// Helper method to compare lists of Offsets.
  bool _listEquals(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
