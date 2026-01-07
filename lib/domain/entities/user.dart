import 'package:flutter/foundation.dart';

/// Represents a user profile in the application.
///
/// This is an immutable entity that contains user information including
/// their authentication details, profile data, and canvas ownership tracking.
/// It supports both guest (anonymous) and registered users.
///
/// Guest users have limited features:
/// - Can create a limited number of canvases
/// - Profile can be upgraded to full membership later
///
/// Registered users have full access:
/// - Username and email authentication
/// - Unlimited canvas creation (within reasonable limits)
/// - Team collaboration features
@immutable
class User {
  /// Creates a user profile.
  const User({
    required this.userId,
    required this.username,
    required this.email,
    required this.canvasCount,
    required this.isGuest,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a guest user profile with default values.
  ///
  /// Guest users start with zero canvases and have limited features.
  factory User.guest({
    required String userId,
  }) {
    final now = DateTime.now();
    return User(
      userId: userId,
      username: 'Guest',
      email: '',
      canvasCount: 0,
      isGuest: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates a registered user profile.
  ///
  /// Registered users have full access to all features.
  factory User.registered({
    required String userId,
    required String username,
    required String email,
  }) {
    final now = DateTime.now();
    return User(
      userId: userId,
      username: username,
      email: email,
      canvasCount: 0,
      isGuest: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// The unique identifier for this user.
  ///
  /// This is the Firebase Authentication UID and is used to associate
  /// data with the user across the application.
  final String userId;

  /// The user's display name.
  ///
  /// For guest users, this is typically 'Guest'.
  /// For registered users, this is their chosen username.
  final String username;

  /// The user's email address.
  ///
  /// Empty string for guest users.
  /// Valid email address for registered users.
  final String email;

  /// The number of canvases owned by this user.
  ///
  /// This is used to enforce canvas creation limits for guest users
  /// and to track user activity.
  final int canvasCount;

  /// Whether this is a guest (anonymous) user.
  ///
  /// Guest users have limited features and can be upgraded to
  /// registered users later.
  final bool isGuest;

  /// When this user account was created.
  final DateTime createdAt;

  /// When this user profile was last updated.
  ///
  /// This is updated whenever any user data changes, including
  /// canvas count increments.
  final DateTime updatedAt;

  /// Maximum number of canvases a guest user can create.
  static const int maxGuestCanvases = 1;

  /// Maximum number of canvases a registered user can create.
  static const int maxRegisteredCanvases = 50;

  /// Checks if this user can create a new canvas.
  ///
  /// Returns false if the user has reached their canvas limit based
  /// on their account type (guest or registered).
  bool get canCreateCanvas {
    if (isGuest) {
      return canvasCount < maxGuestCanvases;
    }
    return canvasCount < maxRegisteredCanvases;
  }

  /// Gets the remaining number of canvases this user can create.
  int get remainingCanvases {
    final maxCanvases = isGuest ? maxGuestCanvases : maxRegisteredCanvases;
    final remaining = maxCanvases - canvasCount;
    return remaining > 0 ? remaining : 0;
  }

  /// Creates a copy of this user with the given fields replaced.
  User copyWith({
    String? userId,
    String? username,
    String? email,
    int? canvasCount,
    bool? isGuest,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      canvasCount: canvasCount ?? this.canvasCount,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
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
    return 'User(userId: $userId, username: $username, email: $email, '
        'canvasCount: $canvasCount, isGuest: $isGuest, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
