/// Domain entity representing a collaborative canvas.
///
/// This is a pure Dart class with no framework dependencies.
/// It represents the core business object in the domain layer.
class CanvasEntity {
  /// Unique identifier for the canvas
  final String id;

  /// Human-readable name of the canvas
  final String name;

  /// Number of participants currently on the canvas
  final int participantCount;

  /// When the canvas was last updated
  final DateTime lastUpdated;

  /// Whether the canvas is currently active/live
  final bool isActive;

  /// Type of canvas state (determines visual representation)
  /// This is used for fallback when drawingData is not available.
  final CanvasState state;

  /// Creates a canvas entity.
  const CanvasEntity({
    required this.id,
    required this.name,
    required this.participantCount,
    required this.lastUpdated,
    required this.isActive,
    required this.state,
  });

  /// Creates a copy of this entity with optional field overrides
  CanvasEntity copyWith({
    String? id,
    String? name,
    int? participantCount,
    DateTime? lastUpdated,
    bool? isActive,
    CanvasState? state,
  }) {
    return CanvasEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      participantCount: participantCount ?? this.participantCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
      state: state ?? this.state,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CanvasEntity &&
        other.id == id &&
        other.name == name &&
        other.participantCount == participantCount &&
        other.lastUpdated == lastUpdated &&
        other.isActive == isActive &&
        other.state == state;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      participantCount,
      lastUpdated,
      isActive,
      state,
    );
  }

  @override
  String toString() {
    return 'CanvasEntity(id: $id, name: $name, participantCount: $participantCount, lastUpdated: $lastUpdated, isActive: $isActive, state: $state)';
  }
}

/// Enum representing different canvas states for visual variety
enum CanvasState {
  /// Canvas with colorful geometric shapes
  geometric,

  /// Canvas with sketch-like drawings
  sketch,

  /// Canvas with organic flowing shapes
  organic,

  /// Canvas with minimal content
  minimal,

  /// Empty canvas
  empty,
}
