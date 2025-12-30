import '../../domain/entities/canvas_entity.dart';

/// Data model for Canvas with JSON serialization support.
///
/// This is the data layer representation that can be converted to/from
/// JSON and transformed to/from domain entities.
class CanvasModel {
  /// Unique identifier for the canvas
  final String id;

  /// Human-readable name of the canvas
  final String name;

  /// Number of participants currently on the canvas
  final int participantCount;

  /// ISO 8601 timestamp of last update
  final String lastUpdated;

  /// Whether the canvas is currently active/live
  final bool isActive;

  /// Canvas state as string
  final String state;

  /// Creates a canvas model.
  const CanvasModel({
    required this.id,
    required this.name,
    required this.participantCount,
    required this.lastUpdated,
    required this.isActive,
    required this.state,
  });

  /// Creates a model from JSON
  factory CanvasModel.fromJson(Map<String, dynamic> json) {
    return CanvasModel(
      id: json['id'] as String,
      name: json['name'] as String,
      participantCount: json['participantCount'] as int,
      lastUpdated: json['lastUpdated'] as String,
      isActive: json['isActive'] as bool,
      state: json['state'] as String,
    );
  }

  /// Converts model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'participantCount': participantCount,
      'lastUpdated': lastUpdated,
      'isActive': isActive,
      'state': state,
    };
  }

  /// Converts model to domain entity
  CanvasEntity toEntity() {
    return CanvasEntity(
      id: id,
      name: name,
      participantCount: participantCount,
      lastUpdated: DateTime.parse(lastUpdated),
      isActive: isActive,
      state: _parseCanvasState(state),
    );
  }

  /// Creates model from domain entity
  factory CanvasModel.fromEntity(CanvasEntity entity) {
    return CanvasModel(
      id: entity.id,
      name: entity.name,
      participantCount: entity.participantCount,
      lastUpdated: entity.lastUpdated.toIso8601String(),
      isActive: entity.isActive,
      state: entity.state.name,
    );
  }

  /// Parses canvas state from string
  static CanvasState _parseCanvasState(String state) {
    return CanvasState.values.firstWhere(
      (e) => e.name == state,
      orElse: () => CanvasState.empty,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CanvasModel &&
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
}

/// Sample data generator for development and testing
class SampleCanvasData {
  /// Private constructor to prevent instantiation
  SampleCanvasData._();

  /// Generates sample canvas entities for demonstration
  static List<CanvasEntity> generateSampleCanvases() {
    final now = DateTime.now();

    return [
      // Active canvas - most recent
      CanvasEntity(
        id: 'canvas_a1b2c3',
        name: 'Team Brainstorm',
        participantCount: 4,
        lastUpdated: now.subtract(const Duration(minutes: 2)),
        isActive: true,
        state: CanvasState.geometric,
      ),

      // Recent canvas - 15 minutes ago
      CanvasEntity(
        id: 'canvas_d4e5f6',
        name: 'Daily Standup Notes',
        participantCount: 2,
        lastUpdated: now.subtract(const Duration(minutes: 15)),
        isActive: false,
        state: CanvasState.sketch,
      ),

      // Canvas from 1 hour ago
      CanvasEntity(
        id: 'canvas_g7h8i9',
        name: 'Creative Ideas',
        participantCount: 1,
        lastUpdated: now.subtract(const Duration(hours: 1)),
        isActive: false,
        state: CanvasState.organic,
      ),

      // Canvas from 3 hours ago
      CanvasEntity(
        id: 'canvas_j0k1l2',
        name: 'Project Planning',
        participantCount: 5,
        lastUpdated: now.subtract(const Duration(hours: 3)),
        isActive: false,
        state: CanvasState.minimal,
      ),

      // Older canvas from yesterday
      CanvasEntity(
        id: 'canvas_m3n4o5',
        name: 'Architecture Design',
        participantCount: 3,
        lastUpdated: now.subtract(const Duration(days: 1)),
        isActive: false,
        state: CanvasState.geometric,
      ),
    ];
  }

  /// Gets the most recent canvas
  static CanvasEntity? getMostRecentCanvas() {
    final canvases = generateSampleCanvases();
    if (canvases.isEmpty) return null;
    return canvases.first;
  }

  /// Gets recent canvases (excluding the most recent one)
  static List<CanvasEntity> getRecentCanvases() {
    final canvases = generateSampleCanvases();
    if (canvases.length <= 1) return [];
    return canvases.sublist(1);
  }
}
