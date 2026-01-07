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
    required this.ownerId,
    this.teamMembers = const [],
    this.isPrivate = true,
    this.imageUrl,
    this.lastExported,
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
  ///   "version": 1,
  ///   "ownerId": "user-uuid",
  ///   "teamMembers": ["user-uuid-2", "user-uuid-3"],
  ///   "isPrivate": true,
  ///   "imageUrl": "https://storage.firebase.com/...",
  ///   "lastExported": "2025-01-01T12:30:00.000Z"
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
      ownerId: json['ownerId'] as String,
      teamMembers: json['teamMembers'] != null
          ? (json['teamMembers'] as List<dynamic>)
              .map((member) => member as String)
              .toList()
          : const [],
      isPrivate: json['isPrivate'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String?,
      lastExported: json['lastExported'] as String?,
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
      ownerId: entity.ownerId,
      teamMembers: entity.teamMembers,
      isPrivate: entity.isPrivate,
      imageUrl: entity.imageUrl,
      lastExported: entity.lastExported?.toIso8601String(),
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

  /// The user ID of the canvas creator/owner.
  final String ownerId;

  /// List of user IDs who have access to this canvas.
  ///
  /// Defaults to an empty list if not provided.
  final List<String> teamMembers;

  /// Whether this canvas is private.
  ///
  /// Defaults to true if not provided.
  final bool isPrivate;

  /// The download URL for the exported canvas image.
  ///
  /// Will be null if the canvas has never been exported.
  final String? imageUrl;

  /// When this canvas was last exported to PNG, stored as ISO 8601 string.
  ///
  /// Will be null if the canvas has never been exported.
  final String? lastExported;

  /// Converts this model to a JSON map for Firestore storage.
  ///
  /// Returns a map with all primitive types suitable for JSON serialization.
  /// The strokes list is already in JSON format, so no conversion is needed.
  Map<String, dynamic> toJson() {
    final json = {
      'canvasId': canvasId,
      'strokes': strokes,
      'lastUpdated': lastUpdated,
      'version': version,
      'ownerId': ownerId,
      'teamMembers': teamMembers,
      'isPrivate': isPrivate,
    };

    if (imageUrl != null) {
      json['imageUrl'] = imageUrl!;
    }
    if (lastExported != null) {
      json['lastExported'] = lastExported!;
    }

    return json;
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
      ownerId: ownerId,
      teamMembers: teamMembers,
      isPrivate: isPrivate,
      imageUrl: imageUrl,
      lastExported: lastExported != null ? DateTime.parse(lastExported!) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DrawingDataModel &&
        other.canvasId == canvasId &&
        _listEquals(other.strokes, strokes) &&
        other.lastUpdated == lastUpdated &&
        other.version == version &&
        other.ownerId == ownerId &&
        _listEqualsString(other.teamMembers, teamMembers) &&
        other.isPrivate == isPrivate &&
        other.imageUrl == imageUrl &&
        other.lastExported == lastExported;
  }

  @override
  int get hashCode {
    return Object.hash(
      canvasId,
      Object.hashAll(strokes),
      lastUpdated,
      version,
      ownerId,
      Object.hashAll(teamMembers),
      isPrivate,
      imageUrl,
      lastExported,
    );
  }

  @override
  String toString() {
    return 'DrawingDataModel(canvasId: $canvasId, strokeCount: ${strokes.length}, '
        'lastUpdated: $lastUpdated, version: $version, ownerId: $ownerId, '
        'teamMembers: ${teamMembers.length}, isPrivate: $isPrivate)';
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

  /// Helper method to compare lists of strings.
  bool _listEqualsString(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
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
