import 'package:flutter/foundation.dart';
import 'package:panci/domain/entities/drawing_stroke.dart';

/// Represents the complete drawing data for a canvas.
///
/// This is an immutable entity that contains all strokes on a canvas along
/// with metadata. It provides methods for managing strokes while maintaining
/// immutability through copy-on-write semantics.
///
/// Canvas ownership and access control:
/// - Each canvas has an owner (the user who created it)
/// - Owners can invite team members to collaborate
/// - Private canvases are only accessible to the owner and team members
/// - Public canvases can be viewed by anyone with the canvas ID
@immutable
class DrawingData {
  /// Creates drawing data for a canvas.
  const DrawingData({
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

  /// Creates an empty drawing data for a new canvas.
  ///
  /// Parameters:
  /// - [canvasId]: The unique identifier for the canvas
  /// - [ownerId]: The user ID of the canvas creator
  /// - [isPrivate]: Whether the canvas is private (default: true)
  factory DrawingData.empty(
    String canvasId, {
    required String ownerId,
    bool isPrivate = true,
  }) {
    return DrawingData(
      canvasId: canvasId,
      strokes: const [],
      lastUpdated: DateTime.now(),
      version: 0,
      ownerId: ownerId,
      teamMembers: const [],
      isPrivate: isPrivate,
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

  /// The user ID of the canvas creator/owner.
  ///
  /// The owner has full control over the canvas including:
  /// - Adding/removing team members
  /// - Deleting the canvas
  /// - Changing privacy settings
  final String ownerId;

  /// List of user IDs who have access to this canvas.
  ///
  /// Team members can:
  /// - View and edit the canvas
  /// - Add and remove strokes
  /// - Export the canvas
  ///
  /// They cannot:
  /// - Add/remove other team members (only owner can)
  /// - Delete the canvas (only owner can)
  /// - Change privacy settings (only owner can)
  final List<String> teamMembers;

  /// Whether this canvas is private.
  ///
  /// Private canvases (default):
  /// - Only accessible to owner and team members
  /// - Require authentication to view
  ///
  /// Public canvases:
  /// - Can be viewed by anyone with the canvas ID
  /// - Still requires authentication to edit
  final bool isPrivate;

  /// The download URL for the exported canvas image.
  ///
  /// This is the Firebase Storage URL for the latest PNG export of the canvas.
  /// Will be null if the canvas has never been exported.
  final String? imageUrl;

  /// When this canvas was last exported to PNG.
  ///
  /// Will be null if the canvas has never been exported.
  final DateTime? lastExported;

  /// The number of strokes currently on the canvas.
  int get strokeCount => strokes.length;

  /// Maximum number of strokes allowed on a canvas.
  static const int maxStrokes = 1000;

  /// Checks if a new stroke can be added to this canvas.
  ///
  /// Returns false if the canvas has reached the maximum stroke limit.
  bool get canAddStroke => strokeCount < maxStrokes;

  /// Checks if a user has access to this canvas.
  ///
  /// A user has access if they are:
  /// - The owner of the canvas, OR
  /// - A team member, OR
  /// - The canvas is public (read-only for non-members)
  bool hasAccess(String userId) {
    if (userId == ownerId) return true;
    if (teamMembers.contains(userId)) return true;
    if (!isPrivate) return true; // Public canvas - anyone can view
    return false;
  }

  /// Checks if a user can edit this canvas.
  ///
  /// A user can edit if they are:
  /// - The owner of the canvas, OR
  /// - A team member
  bool canEdit(String userId) {
    if (userId == ownerId) return true;
    if (teamMembers.contains(userId)) return true;
    return false;
  }

  /// Checks if a user is the owner of this canvas.
  bool isOwner(String userId) => userId == ownerId;

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
    String? ownerId,
    List<String>? teamMembers,
    bool? isPrivate,
    String? imageUrl,
    DateTime? lastExported,
  }) {
    return DrawingData(
      canvasId: canvasId ?? this.canvasId,
      strokes: strokes ?? this.strokes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: version ?? this.version,
      ownerId: ownerId ?? this.ownerId,
      teamMembers: teamMembers ?? this.teamMembers,
      isPrivate: isPrivate ?? this.isPrivate,
      imageUrl: imageUrl ?? this.imageUrl,
      lastExported: lastExported ?? this.lastExported,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DrawingData &&
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
    return 'DrawingData(canvasId: $canvasId, strokeCount: $strokeCount, '
        'lastUpdated: $lastUpdated, version: $version, ownerId: $ownerId, '
        'teamMembers: ${teamMembers.length}, isPrivate: $isPrivate)';
  }

  /// Helper method to compare lists of strokes.
  bool _listEquals(List<DrawingStroke> a, List<DrawingStroke> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
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
}
