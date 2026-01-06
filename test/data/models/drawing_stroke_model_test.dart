import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panci/data/models/drawing_stroke_model.dart';
import 'package:panci/domain/entities/drawing_stroke.dart';

void main() {
  group('DrawingStrokeModel', () {
    // Sample test data
    final testTimestamp = DateTime.parse('2025-01-01T12:00:00.000Z');
    const testColor = Colors.blue;
    const testPoints = [
      Offset(10.5, 20.3),
      Offset(15.2, 25.7),
      Offset(20.0, 30.0),
    ];

    final testEntity = DrawingStroke(
      id: 'test-stroke-id-123',
      points: testPoints,
      color: testColor,
      strokeWidth: 2.5,
      timestamp: testTimestamp,
      userId: 'test-user-id-456',
    );

    final testModel = DrawingStrokeModel(
      id: 'test-stroke-id-123',
      points: [
        {'x': 10.5, 'y': 20.3},
        {'x': 15.2, 'y': 25.7},
        {'x': 20.0, 'y': 30.0},
      ],
      colorValue: testColor.toARGB32(),
      strokeWidth: 2.5,
      timestamp: '2025-01-01T12:00:00.000Z',
      userId: 'test-user-id-456',
    );

    final testJson = {
      'id': 'test-stroke-id-123',
      'points': [
        {'x': 10.5, 'y': 20.3},
        {'x': 15.2, 'y': 25.7},
        {'x': 20.0, 'y': 30.0},
      ],
      'colorValue': testColor.toARGB32(),
      'strokeWidth': 2.5,
      'timestamp': '2025-01-01T12:00:00.000Z',
      'userId': 'test-user-id-456',
    };

    test('toJson converts DrawingStrokeModel to JSON map', () {
      final json = testModel.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], 'test-stroke-id-123');
      expect(json['userId'], 'test-user-id-456');
      expect(json['colorValue'], testColor.toARGB32());
      expect(json['strokeWidth'], 2.5);
      expect(json['timestamp'], '2025-01-01T12:00:00.000Z');
      expect(json['points'], isA<List>());
      expect(json['points'].length, 3);

      final points = json['points'] as List;
      expect(points[0], isA<Map<String, double>>());
      expect(points[0]['x'], 10.5);
      expect(points[0]['y'], 20.3);
      expect(points[1]['x'], 15.2);
      expect(points[1]['y'], 25.7);
      expect(points[2]['x'], 20.0);
      expect(points[2]['y'], 30.0);
    });

    test('fromJson creates DrawingStrokeModel from JSON map', () {
      final model = DrawingStrokeModel.fromJson(testJson);

      expect(model.id, 'test-stroke-id-123');
      expect(model.userId, 'test-user-id-456');
      expect(model.colorValue, testColor.toARGB32());
      expect(model.strokeWidth, 2.5);
      expect(model.timestamp, '2025-01-01T12:00:00.000Z');
      expect(model.points.length, 3);
      expect(model.points[0]['x'], 10.5);
      expect(model.points[0]['y'], 20.3);
      expect(model.points[1]['x'], 15.2);
      expect(model.points[1]['y'], 25.7);
      expect(model.points[2]['x'], 20.0);
      expect(model.points[2]['y'], 30.0);
    });

    test('fromJson handles integer numbers correctly', () {
      final jsonWithInts = {
        'id': 'test-id',
        'points': [
          {'x': 10, 'y': 20}, // integers instead of doubles
        ],
        'colorValue': 4294198070,
        'strokeWidth': 2, // integer
        'timestamp': '2025-01-01T12:00:00.000Z',
        'userId': 'user-id',
      };

      final model = DrawingStrokeModel.fromJson(jsonWithInts);

      expect(model.points[0]['x'], 10.0);
      expect(model.points[0]['y'], 20.0);
      expect(model.strokeWidth, 2.0);
    });

    test('toEntity converts model to DrawingStroke entity', () {
      final entity = testModel.toEntity();

      expect(entity, isA<DrawingStroke>());
      expect(entity.id, 'test-stroke-id-123');
      expect(entity.userId, 'test-user-id-456');
      expect(entity.color, Color(testColor.toARGB32()));
      expect(entity.strokeWidth, 2.5);
      expect(entity.timestamp, testTimestamp);
      expect(entity.points, isA<List<Offset>>());
      expect(entity.points.length, 3);
      expect(entity.points[0], const Offset(10.5, 20.3));
      expect(entity.points[1], const Offset(15.2, 25.7));
      expect(entity.points[2], const Offset(20.0, 30.0));
    });

    test('fromEntity creates model from DrawingStroke entity', () {
      final model = DrawingStrokeModel.fromEntity(testEntity);

      expect(model, isA<DrawingStrokeModel>());
      expect(model.id, 'test-stroke-id-123');
      expect(model.userId, 'test-user-id-456');
      expect(model.colorValue, testColor.toARGB32());
      expect(model.strokeWidth, 2.5);
      expect(model.timestamp, '2025-01-01T12:00:00.000Z');
      expect(model.points.length, 3);
      expect(model.points[0]['x'], 10.5);
      expect(model.points[0]['y'], 20.3);
      expect(model.points[1]['x'], 15.2);
      expect(model.points[1]['y'], 25.7);
      expect(model.points[2]['x'], 20.0);
      expect(model.points[2]['y'], 30.0);
    });

    test('JSON roundtrip preserves data', () {
      // Entity → Model → JSON → Model → Entity
      final model1 = DrawingStrokeModel.fromEntity(testEntity);
      final json = model1.toJson();
      final model2 = DrawingStrokeModel.fromJson(json);
      final resultEntity = model2.toEntity();

      expect(resultEntity.id, testEntity.id);
      expect(resultEntity.userId, testEntity.userId);
      expect(resultEntity.color.toARGB32(), testEntity.color.toARGB32());
      expect(resultEntity.strokeWidth, testEntity.strokeWidth);
      expect(resultEntity.timestamp, testEntity.timestamp);
      expect(resultEntity.points.length, testEntity.points.length);
      for (int i = 0; i < resultEntity.points.length; i++) {
        expect(resultEntity.points[i], testEntity.points[i]);
      }
    });

    test('handles empty points list', () {
      final emptyEntity = DrawingStroke(
        id: 'empty-id',
        points: const [],
        color: Colors.red,
        strokeWidth: 1.0,
        timestamp: testTimestamp,
        userId: 'user-id',
      );

      final model = DrawingStrokeModel.fromEntity(emptyEntity);
      expect(model.points, isEmpty);

      final json = model.toJson();
      expect(json['points'], isEmpty);

      final parsedModel = DrawingStrokeModel.fromJson(json);
      expect(parsedModel.points, isEmpty);

      final entity = parsedModel.toEntity();
      expect(entity.points, isEmpty);
    });

    test('handles single point', () {
      final singlePointEntity = DrawingStroke(
        id: 'single-id',
        points: [const Offset(5.0, 10.0)],
        color: Colors.green,
        strokeWidth: 3.0,
        timestamp: testTimestamp,
        userId: 'user-id',
      );

      final model = DrawingStrokeModel.fromEntity(singlePointEntity);
      final entity = model.toEntity();

      expect(entity.points.length, 1);
      expect(entity.points[0], const Offset(5.0, 10.0));
    });

    test('handles extreme coordinate values', () {
      final extremeEntity = DrawingStroke(
        id: 'extreme-id',
        points: [
          const Offset(-1000.0, -1000.0),
          const Offset(0.0, 0.0),
          const Offset(10000.0, 10000.0),
          const Offset(0.123456789, 0.987654321),
        ],
        color: Colors.purple,
        strokeWidth: 0.5,
        timestamp: testTimestamp,
        userId: 'user-id',
      );

      final model = DrawingStrokeModel.fromEntity(extremeEntity);
      final json = model.toJson();
      final parsedModel = DrawingStrokeModel.fromJson(json);
      final entity = parsedModel.toEntity();

      expect(entity.points.length, 4);
      expect(entity.points[0], const Offset(-1000.0, -1000.0));
      expect(entity.points[1], const Offset(0.0, 0.0));
      expect(entity.points[2], const Offset(10000.0, 10000.0));
      // Note: Floating point precision may vary slightly
      expect(entity.points[3].dx, closeTo(0.123456789, 0.0000001));
      expect(entity.points[3].dy, closeTo(0.987654321, 0.0000001));
    });

    test('preserves color values correctly', () {
      final colors = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.transparent,
        const Color(0xFF123456),
        const Color(0x80ABCDEF),
      ];

      for (final color in colors) {
        final entity = DrawingStroke(
          id: 'color-test',
          points: const [Offset(0, 0)],
          color: color,
          strokeWidth: 1.0,
          timestamp: testTimestamp,
          userId: 'user-id',
        );

        final model = DrawingStrokeModel.fromEntity(entity);
        expect(model.colorValue, color.toARGB32());

        final resultEntity = model.toEntity();
        expect(resultEntity.color.toARGB32(), color.toARGB32());
      }
    });

    test('preserves timestamp precision', () {
      final timestamps = [
        DateTime.parse('2025-01-01T00:00:00.000Z'),
        DateTime.parse('2025-12-31T23:59:59.999Z'),
        DateTime.parse('2025-06-15T12:30:45.123Z'),
      ];

      for (final timestamp in timestamps) {
        final entity = DrawingStroke(
          id: 'time-test',
          points: const [Offset(0, 0)],
          color: Colors.black,
          strokeWidth: 1.0,
          timestamp: timestamp,
          userId: 'user-id',
        );

        final model = DrawingStrokeModel.fromEntity(entity);
        final resultEntity = model.toEntity();

        expect(resultEntity.timestamp, timestamp);
      }
    });

    test('equality works correctly', () {
      final model1 = DrawingStrokeModel.fromEntity(testEntity);
      final model2 = DrawingStrokeModel.fromEntity(testEntity);

      expect(model1, equals(model2));
      // Note: hashCode might differ for separate instances due to List<Map> hashing
    });

    test('inequality works correctly', () {
      final model1 = DrawingStrokeModel.fromEntity(testEntity);
      final model2 = DrawingStrokeModel.fromEntity(
        testEntity.copyWith(id: 'different-id'),
      );

      expect(model1, isNot(equals(model2)));
    });

    test('toString returns meaningful representation', () {
      final model = DrawingStrokeModel.fromEntity(testEntity);
      final string = model.toString();

      expect(string, contains('DrawingStrokeModel'));
      expect(string, contains('test-stroke-id-123'));
      expect(string, contains('3')); // number of points
      expect(string, contains('test-user-id-456'));
    });
  });
}
