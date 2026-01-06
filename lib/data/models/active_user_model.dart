import 'package:flutter/material.dart';
import 'package:panci/domain/entities/active_user.dart';

/// Data model for [ActiveUser] that handles JSON serialization.
///
/// This model is responsible for converting between the domain entity
/// and JSON format suitable for Firebase/Firestore persistence. It handles
/// nullable cursor positions and Flutter types (Offset, Color, DateTime).
@immutable
class ActiveUserModel {
  /// Creates an active user model.
  const ActiveUserModel({
    required this.userId,
    required this.displayName,
    required this.lastSeen,
    required this.cursorColorValue,
    this.cursorPosition,
  });

  /// Creates a model from a JSON map (from Firestore).
  ///
  /// Expects JSON structure:
  /// ```json
  /// {
  ///   "userId": "user-uuid",
  ///   "displayName": "John Doe",
  ///   "cursorPosition": {"x": 10.5, "y": 20.3},  // or null
  ///   "lastSeen": "2025-01-01T12:00:00.000Z",
  ///   "cursorColorValue": 4294198070
  /// }
  /// ```
  factory ActiveUserModel.fromJson(Map<String, dynamic> json) {
    final cursorPositionJson = json['cursorPosition'];
    Map<String, double>? cursorPosition;

    if (cursorPositionJson != null) {
      cursorPosition = {
        'x': (cursorPositionJson['x'] as num).toDouble(),
        'y': (cursorPositionJson['y'] as num).toDouble(),
      };
    }

    return ActiveUserModel(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      cursorPosition: cursorPosition,
      lastSeen: json['lastSeen'] as String,
      cursorColorValue: json['cursorColorValue'] as int,
    );
  }

  /// Creates a model from a domain entity.
  ///
  /// Converts Flutter types to JSON-compatible primitives:
  /// - Offset? → {'x': double, 'y': double}? (nullable)
  /// - Color → int (Color.value)
  /// - DateTime → ISO 8601 string
  factory ActiveUserModel.fromEntity(ActiveUser entity) {
    Map<String, double>? cursorPosition;

    if (entity.cursorPosition != null) {
      cursorPosition = {
        'x': entity.cursorPosition!.dx,
        'y': entity.cursorPosition!.dy,
      };
    }

    return ActiveUserModel(
      userId: entity.userId,
      displayName: entity.displayName,
      cursorPosition: cursorPosition,
      lastSeen: entity.lastSeen.toIso8601String(),
      cursorColorValue: entity.cursorColor.toARGB32(),
    );
  }

  /// The unique identifier for this user.
  final String userId;

  /// The display name of this user shown to other collaborators.
  final String displayName;

  /// The current cursor position of this user on the canvas.
  ///
  /// Null if the user's cursor is not currently on the canvas.
  /// Format: {'x': 10.5, 'y': 20.3}
  final Map<String, double>? cursorPosition;

  /// The last time this user was seen active, stored as ISO 8601 string.
  ///
  /// Format: "2025-01-01T12:00:00.000Z"
  final String lastSeen;

  /// The color used to represent this user's cursor, stored as int value.
  ///
  /// This is the raw ARGB color value that can be converted back to
  /// a [Color] object using Color(cursorColorValue).
  final int cursorColorValue;

  /// Converts this model to a JSON map for Firestore storage.
  ///
  /// Returns a map with all primitive types suitable for JSON serialization.
  /// Properly handles null cursor position.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'cursorPosition': cursorPosition,
      'lastSeen': lastSeen,
      'cursorColorValue': cursorColorValue,
    };
  }

  /// Converts this model to a domain entity.
  ///
  /// Transforms JSON-compatible primitives back to Flutter types:
  /// - {'x': double, 'y': double}? → Offset? (nullable)
  /// - int → Color
  /// - ISO 8601 string → DateTime
  ActiveUser toEntity() {
    Offset? cursorOffset;

    if (cursorPosition != null) {
      cursorOffset = Offset(cursorPosition!['x']!, cursorPosition!['y']!);
    }

    return ActiveUser(
      userId: userId,
      displayName: displayName,
      cursorPosition: cursorOffset,
      lastSeen: DateTime.parse(lastSeen),
      cursorColor: Color(cursorColorValue),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ActiveUserModel &&
        other.userId == userId &&
        other.displayName == displayName &&
        _mapEquals(other.cursorPosition, cursorPosition) &&
        other.lastSeen == lastSeen &&
        other.cursorColorValue == cursorColorValue;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      displayName,
      cursorPosition != null
          ? Object.hash(cursorPosition!['x'], cursorPosition!['y'])
          : null,
      lastSeen,
      cursorColorValue,
    );
  }

  @override
  String toString() {
    return 'ActiveUserModel(userId: $userId, displayName: $displayName, '
        'cursorPosition: $cursorPosition, lastSeen: $lastSeen, '
        'cursorColorValue: $cursorColorValue)';
  }

  /// Helper method to compare nullable cursor position maps.
  bool _mapEquals(
    Map<String, double>? a,
    Map<String, double>? b,
  ) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a['x'] == b['x'] && a['y'] == b['y'];
  }
}
