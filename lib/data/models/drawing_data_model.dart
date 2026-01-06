import 'package:flutter/foundation.dart';
import 'package:panci/data/models/drawing_stroke_model.dart';
import 'package:panci/domain/entities/drawing_data.dart';

/// Data model for [DrawingData] that handles JSON serialization.
///
/// This model is responsible for converting between the domain entity
/// and JSON format suitable for Firebase/Firestore persistence. It stores
/// strokes as a list of JSON objects for efficient Firestore storage.
@immutable
class DrawingDataModel {
  /// Creates a drawing data model.
  const DrawingDataModel({
    required this.canvasId,
    required this.strokes,
    required this.lastUpdated,
    required this.version,
  });

  /// Creates a model from a JSON map (from Firestore).
  ///
  /// Expects JSON structure:
  /// ```json
  /// {
  ///   "canvasId": "canvas-uuid",
  ///   "strokes": [
  ///     {
  ///       "id": "stroke-uuid",
  ///       "points": [{"x": 10.5, "y": 20.3}],
  ///       "colorValue": 4294198070,
  ///       "strokeWidth": 2.0,
  ///       "timestamp": "2025-01-01T12:00:00.000Z",
  ///       "userId": "user-uuid"
  ///     }
  ///   ],
  ///   "lastUpdated": "2025-01-01T12:00:00.000Z",
  ///   "version": 1
  /// }
  /// ```
  factory DrawingDataModel.fromJson(Map<String, dynamic> json) {
    return DrawingDataModel(
      canvasId: json['canvasId'] as String,
      strokes: (json['strokes'] as List<dynamic>)
          .map((stroke) => stroke as Map<String, dynamic>)
          .toList(),
      lastUpdated: json['lastUpdated'] as String,
      version: json['version'] as int,
    );
  }

  /// Creates a model from a domain entity.
  ///
  /// Converts all strokes to JSON format using [DrawingStrokeModel].
  factory DrawingDataModel.fromEntity(DrawingData entity) {
    return DrawingDataModel(
      canvasId: entity.canvasId,
      strokes: entity.strokes
          .map((stroke) => DrawingStrokeModel.fromEntity(stroke).toJson())
          .toList(),
      lastUpdated: entity.lastUpdated.toIso8601String(),
      version: entity.version,
    );
  }

  /// The unique identifier for this canvas.
  final String canvasId;

  /// The list of all strokes on this canvas as JSON objects.
  ///
  /// Each stroke is stored as a complete JSON map, not as a model instance.
  /// This allows direct serialization to Firestore without additional conversion.
  final List<Map<String, dynamic>> strokes;

  /// When this drawing was last updated, stored as ISO 8601 string.
  ///
  /// Format: "2025-01-01T12:00:00.000Z"
  final String lastUpdated;

  /// Version number for this drawing, incremented with each modification.
  final int version;

  /// Converts this model to a JSON map for Firestore storage.
  ///
  /// Returns a map with all primitive types suitable for JSON serialization.
  /// The strokes list is already in JSON format, so no conversion is needed.
  Map<String, dynamic> toJson() {
    return {
      'canvasId': canvasId,
      'strokes': strokes,
      'lastUpdated': lastUpdated,
      'version': version,
    };
  }

  /// Converts this model to a domain entity.
  ///
  /// Deserializes all stroke JSON objects back to domain entities
  /// using [DrawingStrokeModel].
  DrawingData toEntity() {
    return DrawingData(
      canvasId: canvasId,
      strokes: strokes
          .map((strokeJson) =>
              DrawingStrokeModel.fromJson(strokeJson).toEntity())
          .toList(),
      lastUpdated: DateTime.parse(lastUpdated),
      version: version,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DrawingDataModel &&
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
    return 'DrawingDataModel(canvasId: $canvasId, strokeCount: ${strokes.length}, '
        'lastUpdated: $lastUpdated, version: $version)';
  }

  /// Helper method to compare lists of stroke JSON maps.
  bool _listEquals(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_mapEquals(a[i], b[i])) return false;
    }
    return true;
  }

  /// Helper method to deep compare JSON maps.
  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final aValue = a[key];
      final bValue = b[key];

      // Handle nested lists (points array)
      if (aValue is List && bValue is List) {
        if (aValue.length != bValue.length) return false;
        for (int i = 0; i < aValue.length; i++) {
          if (aValue[i] is Map && bValue[i] is Map) {
            if (!_mapEquals(
              aValue[i] as Map<String, dynamic>,
              bValue[i] as Map<String, dynamic>,
            )) {
              return false;
            }
          } else if (aValue[i] != bValue[i]) {
            return false;
          }
        }
      } else if (aValue != bValue) {
        return false;
      }
    }
    return true;
  }
}
