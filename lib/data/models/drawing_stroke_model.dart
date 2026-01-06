import 'package:flutter/material.dart';
import 'package:panci/domain/entities/drawing_stroke.dart';

/// Data model for [DrawingStroke] that handles JSON serialization.
///
/// This model is responsible for converting between the domain entity
/// and JSON format suitable for Firebase/Firestore persistence. It handles
/// the transformation of Flutter types (Offset, Color, DateTime) into
/// JSON-compatible primitives.
@immutable
class DrawingStrokeModel {
  /// Creates a drawing stroke model.
  const DrawingStrokeModel({
    required this.id,
    required this.points,
    required this.colorValue,
    required this.strokeWidth,
    required this.timestamp,
    required this.userId,
  });

  /// Creates a model from a JSON map (from Firestore).
  ///
  /// Expects JSON structure:
  /// ```json
  /// {
  ///   "id": "uuid-string",
  ///   "points": [{"x": 10.5, "y": 20.3}, ...],
  ///   "colorValue": 4294198070,
  ///   "strokeWidth": 2.0,
  ///   "timestamp": "2025-01-01T12:00:00.000Z",
  ///   "userId": "user-uuid"
  /// }
  /// ```
  factory DrawingStrokeModel.fromJson(Map<String, dynamic> json) {
    return DrawingStrokeModel(
      id: json['id'] as String,
      points: (json['points'] as List<dynamic>)
          .map((point) => {
                'x': (point['x'] as num).toDouble(),
                'y': (point['y'] as num).toDouble(),
              })
          .toList(),
      colorValue: json['colorValue'] as int,
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
      userId: json['userId'] as String,
    );
  }

  /// Creates a model from a domain entity.
  ///
  /// Converts Flutter types to JSON-compatible primitives:
  /// - Offset → {'x': double, 'y': double}
  /// - Color → int (Color.value)
  /// - DateTime → ISO 8601 string
  factory DrawingStrokeModel.fromEntity(DrawingStroke entity) {
    return DrawingStrokeModel(
      id: entity.id,
      points: entity.points
          .map((offset) => {
                'x': offset.dx,
                'y': offset.dy,
              })
          .toList(),
      colorValue: entity.color.toARGB32(),
      strokeWidth: entity.strokeWidth,
      timestamp: entity.timestamp.toIso8601String(),
      userId: entity.userId,
    );
  }

  /// Unique identifier for this stroke.
  final String id;

  /// The list of points that make up this stroke's path.
  ///
  /// Each point is stored as a map with 'x' and 'y' double values.
  /// Format: [{'x': 10.5, 'y': 20.3}, {'x': 11.2, 'y': 21.0}, ...]
  final List<Map<String, double>> points;

  /// The color of this stroke as an integer value.
  ///
  /// This is the raw ARGB color value that can be converted back to
  /// a [Color] object using Color(colorValue).
  final int colorValue;

  /// The width of this stroke in logical pixels.
  final double strokeWidth;

  /// When this stroke was created, stored as ISO 8601 string.
  ///
  /// Format: "2025-01-01T12:00:00.000Z"
  final String timestamp;

  /// The ID of the user who created this stroke.
  final String userId;

  /// Converts this model to a JSON map for Firestore storage.
  ///
  /// Returns a map with all primitive types suitable for JSON serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points,
      'colorValue': colorValue,
      'strokeWidth': strokeWidth,
      'timestamp': timestamp,
      'userId': userId,
    };
  }

  /// Converts this model to a domain entity.
  ///
  /// Transforms JSON-compatible primitives back to Flutter types:
  /// - {'x': double, 'y': double} → Offset
  /// - int → Color
  /// - ISO 8601 string → DateTime
  DrawingStroke toEntity() {
    return DrawingStroke(
      id: id,
      points: points
          .map((point) => Offset(point['x']!, point['y']!))
          .toList(),
      color: Color(colorValue),
      strokeWidth: strokeWidth,
      timestamp: DateTime.parse(timestamp),
      userId: userId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DrawingStrokeModel &&
        other.id == id &&
        _listEquals(other.points, points) &&
        other.colorValue == colorValue &&
        other.strokeWidth == strokeWidth &&
        other.timestamp == timestamp &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      Object.hashAll(points),
      colorValue,
      strokeWidth,
      timestamp,
      userId,
    );
  }

  @override
  String toString() {
    return 'DrawingStrokeModel(id: $id, points: ${points.length}, '
        'colorValue: $colorValue, strokeWidth: $strokeWidth, '
        'timestamp: $timestamp, userId: $userId)';
  }

  /// Helper method to compare lists of point maps.
  bool _listEquals(List<Map<String, double>> a, List<Map<String, double>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['x'] != b[i]['x'] || a[i]['y'] != b[i]['y']) return false;
    }
    return true;
  }
}
