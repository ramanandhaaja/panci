import 'package:flutter/foundation.dart';
import 'package:panci/domain/entities/user.dart';

/// Data model for [User] that handles JSON serialization.
///
/// This model is responsible for converting between the domain entity
/// and JSON format suitable for Firebase/Firestore persistence. It follows
/// the data layer pattern where models handle serialization concerns
/// separate from business logic.
///
/// JSON structure stored in Firestore:
/// ```json
/// {
///   "userId": "user-uuid",
///   "username": "john_doe",
///   "email": "john@example.com",
///   "canvasCount": 5,
///   "isGuest": false,
///   "createdAt": "2025-01-01T12:00:00.000Z",
///   "updatedAt": "2025-01-07T10:30:00.000Z"
/// }
/// ```
///
/// Key features:
/// - DateTime fields stored as ISO 8601 strings for Firestore compatibility
/// - Proper null safety with default values for missing fields
/// - Bidirectional conversion: Entity ↔ Model ↔ JSON
/// - Immutable data structure following clean architecture principles
@immutable
class UserModel {
  /// Creates a user model.
  const UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.canvasCount,
    required this.isGuest,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a model from a JSON map (from Firestore).
  ///
  /// Handles missing fields with sensible defaults:
  /// - canvasCount defaults to 0 if missing
  /// - timestamps default to current time if missing
  ///
  /// Expects JSON structure as shown in class documentation.
  ///
  /// Example:
  /// ```dart
  /// final json = {
  ///   'userId': 'user-123',
  ///   'username': 'john_doe',
  ///   'email': 'john@example.com',
  ///   'canvasCount': 5,
  ///   'isGuest': false,
  ///   'createdAt': '2025-01-01T12:00:00.000Z',
  ///   'updatedAt': '2025-01-07T10:30:00.000Z',
  /// };
  /// final model = UserModel.fromJson(json);
  /// ```
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toIso8601String();

    return UserModel(
      userId: json['userId'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      canvasCount: json['canvasCount'] as int? ?? 0,
      isGuest: json['isGuest'] as bool,
      createdAt: json['createdAt'] as String? ?? now,
      updatedAt: json['updatedAt'] as String? ?? now,
    );
  }

  /// Creates a model from a domain entity.
  ///
  /// Converts DateTime objects to ISO 8601 string format for storage.
  ///
  /// Example:
  /// ```dart
  /// final user = User.registered(
  ///   userId: 'user-123',
  ///   username: 'john_doe',
  ///   email: 'john@example.com',
  /// );
  /// final model = UserModel.fromEntity(user);
  /// ```
  factory UserModel.fromEntity(User entity) {
    return UserModel(
      userId: entity.userId,
      username: entity.username,
      email: entity.email,
      canvasCount: entity.canvasCount,
      isGuest: entity.isGuest,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  /// The unique identifier for this user.
  ///
  /// This is the Firebase Authentication UID.
  final String userId;

  /// The user's display name.
  final String username;

  /// The user's email address.
  ///
  /// Empty string for guest users.
  final String email;

  /// The number of canvases owned by this user.
  final int canvasCount;

  /// Whether this is a guest (anonymous) user.
  final bool isGuest;

  /// When this user account was created, stored as ISO 8601 string.
  ///
  /// Format: "2025-01-01T12:00:00.000Z"
  final String createdAt;

  /// When this user profile was last updated, stored as ISO 8601 string.
  ///
  /// Format: "2025-01-07T10:30:00.000Z"
  final String updatedAt;

  /// Converts this model to a JSON map for Firestore storage.
  ///
  /// Returns a map with all primitive types suitable for JSON serialization.
  /// All fields are included, even if they have default values.
  ///
  /// Example:
  /// ```dart
  /// final model = UserModel(...);
  /// final json = model.toJson();
  /// // Use json with Firestore:
  /// await firestore.collection('users').doc(userId).set(json);
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'canvasCount': canvasCount,
      'isGuest': isGuest,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Converts this model to a domain entity.
  ///
  /// Parses ISO 8601 timestamp strings back to DateTime objects.
  ///
  /// Example:
  /// ```dart
  /// final model = UserModel.fromJson(firestoreData);
  /// final user = model.toEntity();
  /// // Now use the entity in business logic
  /// if (user.canCreateCanvas) { ... }
  /// ```
  User toEntity() {
    return User(
      userId: userId,
      username: username,
      email: email,
      canvasCount: canvasCount,
      isGuest: isGuest,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.userId == userId &&
        other.username == username &&
        other.email == email &&
        other.canvasCount == canvasCount &&
        other.isGuest == isGuest &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      username,
      email,
      canvasCount,
      isGuest,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, username: $username, email: $email, '
        'canvasCount: $canvasCount, isGuest: $isGuest, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
