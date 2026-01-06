import 'package:flutter/material.dart';

/// Represents an active user on a shared canvas.
///
/// This entity is used for live presence indicators in future phases (Phase 7).
/// It tracks a user's cursor position, display name, and last activity time
/// for real-time collaboration features.
@immutable
class ActiveUser {
  /// Creates an active user.
  const ActiveUser({
    required this.userId,
    required this.displayName,
    required this.lastSeen,
    required this.cursorColor,
    this.cursorPosition,
  });

  /// The unique identifier for this user.
  final String userId;

  /// The display name of this user shown to other collaborators.
  final String displayName;

  /// The current cursor position of this user on the canvas.
  ///
  /// Null if the user's cursor is not currently on the canvas.
  /// Position is in canvas coordinate space (not screen space).
  final Offset? cursorPosition;

  /// The last time this user was seen active on the canvas.
  final DateTime lastSeen;

  /// The color used to represent this user's cursor and annotations.
  final Color cursorColor;

  /// Checks if this user is currently considered active.
  ///
  /// A user is considered active if they were seen within the last 30 seconds.
  bool get isActive {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    return difference.inSeconds < 30;
  }

  /// Creates a copy of this active user with the given fields replaced.
  ActiveUser copyWith({
    String? userId,
    String? displayName,
    Offset? cursorPosition,
    DateTime? lastSeen,
    Color? cursorColor,
    bool clearCursorPosition = false,
  }) {
    return ActiveUser(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      cursorPosition: clearCursorPosition ? null : (cursorPosition ?? this.cursorPosition),
      lastSeen: lastSeen ?? this.lastSeen,
      cursorColor: cursorColor ?? this.cursorColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ActiveUser &&
        other.userId == userId &&
        other.displayName == displayName &&
        other.cursorPosition == cursorPosition &&
        other.lastSeen == lastSeen &&
        other.cursorColor == cursorColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      displayName,
      cursorPosition,
      lastSeen,
      cursorColor,
    );
  }

  @override
  String toString() {
    return 'ActiveUser(userId: $userId, displayName: $displayName, '
        'cursorPosition: $cursorPosition, lastSeen: $lastSeen, '
        'cursorColor: $cursorColor, isActive: $isActive)';
  }
}
