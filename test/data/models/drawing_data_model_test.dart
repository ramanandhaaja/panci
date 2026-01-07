import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panci/data/models/drawing_data_model.dart';
import 'package:panci/domain/entities/drawing_data.dart';
import 'package:panci/domain/entities/drawing_stroke.dart';

void main() {
  group('DrawingDataModel', () {
    // Sample test data
    final testTimestamp = DateTime.parse('2025-01-01T12:00:00.000Z');
    final testUpdated = DateTime.parse('2025-01-01T12:30:00.000Z');

    final testStroke1 = DrawingStroke(
      id: 'stroke-1',
      points: const [
        Offset(10.0, 20.0),
        Offset(15.0, 25.0),
      ],
      color: Colors.blue,
      strokeWidth: 2.0,
      timestamp: testTimestamp,
      userId: 'user-1',
    );

    final testStroke2 = DrawingStroke(
      id: 'stroke-2',
      points: const [
        Offset(30.0, 40.0),
        Offset(35.0, 45.0),
        Offset(40.0, 50.0),
      ],
      color: Colors.red,
      strokeWidth: 3.0,
      timestamp: testTimestamp,
      userId: 'user-2',
    );

    final testEntity = DrawingData(
      canvasId: 'canvas-123',
      strokes: [testStroke1, testStroke2],
      lastUpdated: testUpdated,
      version: 5,
      ownerId: 'owner-user-123',
      teamMembers: const ['team-user-1', 'team-user-2'],
      isPrivate: true,
    );

    test('toJson converts DrawingDataModel to JSON map', () {
      final model = DrawingDataModel.fromEntity(testEntity);
      final json = model.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['canvasId'], 'canvas-123');
      expect(json['version'], 5);
      expect(json['lastUpdated'], '2025-01-01T12:30:00.000Z');
      expect(json['strokes'], isA<List>());
      expect(json['strokes'].length, 2);

      final strokes = json['strokes'] as List;
      expect(strokes[0], isA<Map<String, dynamic>>());
      expect(strokes[0]['id'], 'stroke-1');
      expect(strokes[0]['userId'], 'user-1');
      expect(strokes[1]['id'], 'stroke-2');
      expect(strokes[1]['userId'], 'user-2');
    });

    test('fromJson creates DrawingDataModel from JSON map', () {
      final json = {
        'canvasId': 'canvas-456',
        'strokes': [
          {
            'id': 'stroke-a',
            'points': [
              {'x': 5.0, 'y': 10.0},
            ],
            'colorValue': Colors.green.toARGB32(),
            'strokeWidth': 1.5,
            'timestamp': '2025-01-01T10:00:00.000Z',
            'userId': 'user-a',
          },
          {
            'id': 'stroke-b',
            'points': [
              {'x': 15.0, 'y': 20.0},
              {'x': 25.0, 'y': 30.0},
            ],
            'colorValue': Colors.yellow.toARGB32(),
            'strokeWidth': 2.5,
            'timestamp': '2025-01-01T11:00:00.000Z',
            'userId': 'user-b',
          },
        ],
        'lastUpdated': '2025-01-01T12:00:00.000Z',
        'version': 10,
        'ownerId': 'owner-user-456',
        'teamMembers': ['team-member-1'],
        'isPrivate': false,
      };

      final model = DrawingDataModel.fromJson(json);

      expect(model.canvasId, 'canvas-456');
      expect(model.version, 10);
      expect(model.lastUpdated, '2025-01-01T12:00:00.000Z');
      expect(model.strokes.length, 2);
      expect(model.strokes[0]['id'], 'stroke-a');
      expect(model.strokes[1]['id'], 'stroke-b');
      expect(model.ownerId, 'owner-user-456');
      expect(model.teamMembers, ['team-member-1']);
      expect(model.isPrivate, false);
    });

    test('toEntity converts model to DrawingData entity', () {
      final model = DrawingDataModel.fromEntity(testEntity);
      final entity = model.toEntity();

      expect(entity, isA<DrawingData>());
      expect(entity.canvasId, 'canvas-123');
      expect(entity.version, 5);
      expect(entity.lastUpdated, testUpdated);
      expect(entity.strokes, isA<List<DrawingStroke>>());
      expect(entity.strokes.length, 2);

      expect(entity.strokes[0].id, 'stroke-1');
      expect(entity.strokes[0].userId, 'user-1');
      expect(entity.strokes[0].points.length, 2);
      expect(entity.strokes[0].color.toARGB32(), Colors.blue.toARGB32());

      expect(entity.strokes[1].id, 'stroke-2');
      expect(entity.strokes[1].userId, 'user-2');
      expect(entity.strokes[1].points.length, 3);
      expect(entity.strokes[1].color.toARGB32(), Colors.red.toARGB32());
    });

    test('fromEntity creates model from DrawingData entity', () {
      final model = DrawingDataModel.fromEntity(testEntity);

      expect(model, isA<DrawingDataModel>());
      expect(model.canvasId, 'canvas-123');
      expect(model.version, 5);
      expect(model.lastUpdated, '2025-01-01T12:30:00.000Z');
      expect(model.strokes.length, 2);

      expect(model.strokes[0]['id'], 'stroke-1');
      expect(model.strokes[0]['userId'], 'user-1');
      expect(model.strokes[1]['id'], 'stroke-2');
      expect(model.strokes[1]['userId'], 'user-2');
    });

    test('handles empty strokes list', () {
      final emptyEntity = DrawingData(
        canvasId: 'empty-canvas',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 0,
        ownerId: 'owner-empty',
      );

      final model = DrawingDataModel.fromEntity(emptyEntity);
      expect(model.strokes, isEmpty);

      final json = model.toJson();
      expect(json['strokes'], isEmpty);

      final parsedModel = DrawingDataModel.fromJson(json);
      expect(parsedModel.strokes, isEmpty);

      final entity = parsedModel.toEntity();
      expect(entity.strokes, isEmpty);
    });

    test('handles single stroke correctly', () {
      final singleStrokeEntity = DrawingData(
        canvasId: 'single-canvas',
        strokes: [testStroke1],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-single',
      );

      final model = DrawingDataModel.fromEntity(singleStrokeEntity);
      expect(model.strokes.length, 1);

      final entity = model.toEntity();
      expect(entity.strokes.length, 1);
      expect(entity.strokes[0].id, testStroke1.id);
    });

    test('handles multiple strokes correctly', () {
      final strokes = List.generate(
        10,
        (i) => DrawingStroke(
          id: 'stroke-$i',
          points: [Offset(i.toDouble(), i.toDouble())],
          color: Colors.black,
          strokeWidth: 1.0,
          timestamp: testTimestamp,
          userId: 'user-$i',
        ),
      );

      final multiStrokeEntity = DrawingData(
        canvasId: 'multi-canvas',
        strokes: strokes,
        lastUpdated: testUpdated,
        version: 10,
        ownerId: 'owner-multi',
      );

      final model = DrawingDataModel.fromEntity(multiStrokeEntity);
      expect(model.strokes.length, 10);

      final entity = model.toEntity();
      expect(entity.strokes.length, 10);

      for (int i = 0; i < 10; i++) {
        expect(entity.strokes[i].id, 'stroke-$i');
        expect(entity.strokes[i].userId, 'user-$i');
      }
    });

    test('JSON roundtrip with multiple strokes preserves data', () {
      // Entity → Model → JSON → Model → Entity
      final model1 = DrawingDataModel.fromEntity(testEntity);
      final json = model1.toJson();
      final model2 = DrawingDataModel.fromJson(json);
      final resultEntity = model2.toEntity();

      expect(resultEntity.canvasId, testEntity.canvasId);
      expect(resultEntity.version, testEntity.version);
      expect(resultEntity.lastUpdated, testEntity.lastUpdated);
      expect(resultEntity.strokes.length, testEntity.strokes.length);

      for (int i = 0; i < resultEntity.strokes.length; i++) {
        final original = testEntity.strokes[i];
        final result = resultEntity.strokes[i];

        expect(result.id, original.id);
        expect(result.userId, original.userId);
        expect(result.color.toARGB32(), original.color.toARGB32());
        expect(result.strokeWidth, original.strokeWidth);
        expect(result.timestamp, original.timestamp);
        expect(result.points.length, original.points.length);

        for (int j = 0; j < result.points.length; j++) {
          expect(result.points[j], original.points[j]);
        }
      }
    });

    test('preserves stroke order', () {
      final strokes = [
        DrawingStroke(
          id: 'third',
          points: const [Offset(0, 0)],
          color: Colors.red,
          strokeWidth: 1.0,
          timestamp: testTimestamp.add(const Duration(seconds: 2)),
          userId: 'user-1',
        ),
        DrawingStroke(
          id: 'first',
          points: const [Offset(0, 0)],
          color: Colors.blue,
          strokeWidth: 1.0,
          timestamp: testTimestamp,
          userId: 'user-1',
        ),
        DrawingStroke(
          id: 'second',
          points: const [Offset(0, 0)],
          color: Colors.green,
          strokeWidth: 1.0,
          timestamp: testTimestamp.add(const Duration(seconds: 1)),
          userId: 'user-1',
        ),
      ];

      final entity = DrawingData(
        canvasId: 'order-canvas',
        strokes: strokes,
        lastUpdated: testUpdated,
        version: 3,
        ownerId: 'owner-order',
      );

      final model = DrawingDataModel.fromEntity(entity);
      final resultEntity = model.toEntity();

      expect(resultEntity.strokes[0].id, 'third');
      expect(resultEntity.strokes[1].id, 'first');
      expect(resultEntity.strokes[2].id, 'second');
    });

    test('handles version 0', () {
      final entity = DrawingData(
        canvasId: 'v0-canvas',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 0,
        ownerId: 'owner-v0',
      );

      final model = DrawingDataModel.fromEntity(entity);
      expect(model.version, 0);

      final resultEntity = model.toEntity();
      expect(resultEntity.version, 0);
    });

    test('handles large version numbers', () {
      final entity = DrawingData(
        canvasId: 'large-v-canvas',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 999999,
        ownerId: 'owner-large',
      );

      final model = DrawingDataModel.fromEntity(entity);
      expect(model.version, 999999);

      final resultEntity = model.toEntity();
      expect(resultEntity.version, 999999);
    });

    test('handles various timestamp formats', () {
      final timestamps = [
        DateTime.parse('2025-01-01T00:00:00.000Z'),
        DateTime.parse('2025-12-31T23:59:59.999Z'),
        DateTime.parse('2025-06-15T12:30:45.123Z'),
      ];

      for (final timestamp in timestamps) {
        final entity = DrawingData(
          canvasId: 'time-canvas',
          strokes: const [],
          lastUpdated: timestamp,
          version: 1,
          ownerId: 'owner-time',
        );

        final model = DrawingDataModel.fromEntity(entity);
        final resultEntity = model.toEntity();

        expect(resultEntity.lastUpdated, timestamp);
      }
    });

    test('equality works correctly', () {
      final model1 = DrawingDataModel.fromEntity(testEntity);
      final model2 = DrawingDataModel.fromEntity(testEntity);

      expect(model1, equals(model2));
      // Note: hashCode might differ for separate instances due to List<Map> hashing
    });

    test('inequality works correctly with different canvasId', () {
      final model1 = DrawingDataModel.fromEntity(testEntity);
      final model2 = DrawingDataModel.fromEntity(
        testEntity.copyWith(canvasId: 'different-canvas'),
      );

      expect(model1, isNot(equals(model2)));
    });

    test('inequality works correctly with different version', () {
      final model1 = DrawingDataModel.fromEntity(testEntity);
      final model2 = DrawingDataModel.fromEntity(
        testEntity.copyWith(version: 999),
      );

      expect(model1, isNot(equals(model2)));
    });

    test('inequality works correctly with different strokes', () {
      final model1 = DrawingDataModel.fromEntity(testEntity);
      final model2 = DrawingDataModel.fromEntity(
        testEntity.copyWith(strokes: [testStroke1]), // Only one stroke
      );

      expect(model1, isNot(equals(model2)));
    });

    test('toString returns meaningful representation', () {
      final model = DrawingDataModel.fromEntity(testEntity);
      final string = model.toString();

      expect(string, contains('DrawingDataModel'));
      expect(string, contains('canvas-123'));
      expect(string, contains('2')); // stroke count
      expect(string, contains('5')); // version
    });

    test('handles strokes with different point counts', () {
      final stroke1 = DrawingStroke(
        id: 'few-points',
        points: const [Offset(0, 0)],
        color: Colors.black,
        strokeWidth: 1.0,
        timestamp: testTimestamp,
        userId: 'user-1',
      );

      final stroke2 = DrawingStroke(
        id: 'many-points',
        points: List.generate(100, (i) => Offset(i.toDouble(), i.toDouble())),
        color: Colors.white,
        strokeWidth: 1.0,
        timestamp: testTimestamp,
        userId: 'user-1',
      );

      final entity = DrawingData(
        canvasId: 'points-canvas',
        strokes: [stroke1, stroke2],
        lastUpdated: testUpdated,
        version: 2,
        ownerId: 'owner-points',
      );

      final model = DrawingDataModel.fromEntity(entity);
      final resultEntity = model.toEntity();

      expect(resultEntity.strokes[0].points.length, 1);
      expect(resultEntity.strokes[1].points.length, 100);
    });

    test('handles DrawingData.empty factory', () {
      final emptyEntity = DrawingData.empty(
        'empty-canvas-id',
        ownerId: 'owner-123',
      );

      final model = DrawingDataModel.fromEntity(emptyEntity);

      expect(model.canvasId, 'empty-canvas-id');
      expect(model.strokes, isEmpty);
      expect(model.version, 0);
      expect(model.ownerId, 'owner-123');

      final resultEntity = model.toEntity();
      expect(resultEntity.canvasId, 'empty-canvas-id');
      expect(resultEntity.strokes, isEmpty);
      expect(resultEntity.version, 0);
      expect(resultEntity.ownerId, 'owner-123');
    });

    // Tests for new ownership fields

    test('toJson includes ownership fields', () {
      final entity = DrawingData(
        canvasId: 'test-canvas',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-user-id',
        teamMembers: const ['member-1', 'member-2', 'member-3'],
        isPrivate: false,
      );

      final model = DrawingDataModel.fromEntity(entity);
      final json = model.toJson();

      expect(json['ownerId'], 'owner-user-id');
      expect(json['teamMembers'], ['member-1', 'member-2', 'member-3']);
      expect(json['isPrivate'], false);
    });

    test('fromJson handles missing teamMembers with default empty list', () {
      final json = {
        'canvasId': 'canvas-id',
        'strokes': [],
        'lastUpdated': '2025-01-01T12:00:00.000Z',
        'version': 1,
        'ownerId': 'owner-id',
        // teamMembers is missing
        'isPrivate': true,
      };

      final model = DrawingDataModel.fromJson(json);

      expect(model.teamMembers, isEmpty);
      expect(model.teamMembers, const []);
    });

    test('fromJson handles missing isPrivate with default true', () {
      final json = {
        'canvasId': 'canvas-id',
        'strokes': [],
        'lastUpdated': '2025-01-01T12:00:00.000Z',
        'version': 1,
        'ownerId': 'owner-id',
        'teamMembers': [],
        // isPrivate is missing
      };

      final model = DrawingDataModel.fromJson(json);

      expect(model.isPrivate, true);
    });

    test('handles empty teamMembers list', () {
      final entity = DrawingData(
        canvasId: 'test-canvas',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-id',
        teamMembers: const [],
        isPrivate: true,
      );

      final model = DrawingDataModel.fromEntity(entity);
      expect(model.teamMembers, isEmpty);

      final json = model.toJson();
      expect(json['teamMembers'], isEmpty);

      final parsedModel = DrawingDataModel.fromJson(json);
      expect(parsedModel.teamMembers, isEmpty);

      final resultEntity = parsedModel.toEntity();
      expect(resultEntity.teamMembers, isEmpty);
    });

    test('handles single team member', () {
      final entity = DrawingData(
        canvasId: 'test-canvas',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-id',
        teamMembers: const ['member-1'],
        isPrivate: true,
      );

      final model = DrawingDataModel.fromEntity(entity);
      expect(model.teamMembers, ['member-1']);

      final json = model.toJson();
      expect(json['teamMembers'], ['member-1']);

      final parsedModel = DrawingDataModel.fromJson(json);
      expect(parsedModel.teamMembers, ['member-1']);

      final resultEntity = parsedModel.toEntity();
      expect(resultEntity.teamMembers, ['member-1']);
    });

    test('handles multiple team members', () {
      final entity = DrawingData(
        canvasId: 'test-canvas',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-id',
        teamMembers: const ['member-1', 'member-2', 'member-3', 'member-4'],
        isPrivate: true,
      );

      final model = DrawingDataModel.fromEntity(entity);
      expect(model.teamMembers.length, 4);

      final json = model.toJson();
      expect(json['teamMembers'].length, 4);

      final parsedModel = DrawingDataModel.fromJson(json);
      expect(parsedModel.teamMembers.length, 4);
      expect(parsedModel.teamMembers, [
        'member-1',
        'member-2',
        'member-3',
        'member-4',
      ]);

      final resultEntity = parsedModel.toEntity();
      expect(resultEntity.teamMembers.length, 4);
    });

    test('isPrivate true is serialized correctly', () {
      final entity = DrawingData(
        canvasId: 'test-canvas',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-id',
        isPrivate: true,
      );

      final model = DrawingDataModel.fromEntity(entity);
      expect(model.isPrivate, true);

      final json = model.toJson();
      expect(json['isPrivate'], true);

      final parsedModel = DrawingDataModel.fromJson(json);
      expect(parsedModel.isPrivate, true);
    });

    test('isPrivate false is serialized correctly', () {
      final entity = DrawingData(
        canvasId: 'test-canvas',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-id',
        isPrivate: false,
      );

      final model = DrawingDataModel.fromEntity(entity);
      expect(model.isPrivate, false);

      final json = model.toJson();
      expect(json['isPrivate'], false);

      final parsedModel = DrawingDataModel.fromJson(json);
      expect(parsedModel.isPrivate, false);
    });

    test('ownership fields roundtrip preserves data', () {
      final entity = DrawingData(
        canvasId: 'roundtrip-canvas',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-user-xyz',
        teamMembers: const ['user-a', 'user-b', 'user-c'],
        isPrivate: false,
      );

      // Entity → Model → JSON → Model → Entity
      final model1 = DrawingDataModel.fromEntity(entity);
      final json = model1.toJson();
      final model2 = DrawingDataModel.fromJson(json);
      final resultEntity = model2.toEntity();

      expect(resultEntity.ownerId, entity.ownerId);
      expect(resultEntity.teamMembers, entity.teamMembers);
      expect(resultEntity.isPrivate, entity.isPrivate);
    });

    test('equality includes ownership fields', () {
      final entity1 = DrawingData(
        canvasId: 'canvas-1',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-1',
        teamMembers: const ['member-1'],
        isPrivate: true,
      );

      final entity2 = DrawingData(
        canvasId: 'canvas-1',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-1',
        teamMembers: const ['member-1'],
        isPrivate: true,
      );

      final model1 = DrawingDataModel.fromEntity(entity1);
      final model2 = DrawingDataModel.fromEntity(entity2);

      expect(model1, equals(model2));
    });

    test('inequality with different ownerId', () {
      final entity1 = DrawingData(
        canvasId: 'canvas-1',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-1',
      );

      final entity2 = DrawingData(
        canvasId: 'canvas-1',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-2',
      );

      final model1 = DrawingDataModel.fromEntity(entity1);
      final model2 = DrawingDataModel.fromEntity(entity2);

      expect(model1, isNot(equals(model2)));
    });

    test('inequality with different teamMembers', () {
      final entity1 = DrawingData(
        canvasId: 'canvas-1',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-1',
        teamMembers: const ['member-1', 'member-2'],
      );

      final entity2 = DrawingData(
        canvasId: 'canvas-1',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-1',
        teamMembers: const ['member-1', 'member-3'],
      );

      final model1 = DrawingDataModel.fromEntity(entity1);
      final model2 = DrawingDataModel.fromEntity(entity2);

      expect(model1, isNot(equals(model2)));
    });

    test('inequality with different isPrivate', () {
      final entity1 = DrawingData(
        canvasId: 'canvas-1',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-1',
        isPrivate: true,
      );

      final entity2 = DrawingData(
        canvasId: 'canvas-1',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-1',
        isPrivate: false,
      );

      final model1 = DrawingDataModel.fromEntity(entity1);
      final model2 = DrawingDataModel.fromEntity(entity2);

      expect(model1, isNot(equals(model2)));
    });

    test('toString includes ownership fields', () {
      final entity = DrawingData(
        canvasId: 'test-canvas',
        strokes: const [],
        lastUpdated: testUpdated,
        version: 1,
        ownerId: 'owner-123',
        teamMembers: const ['member-1', 'member-2'],
        isPrivate: true,
      );

      final model = DrawingDataModel.fromEntity(entity);
      final string = model.toString();

      expect(string, contains('DrawingDataModel'));
      expect(string, contains('test-canvas'));
      expect(string, contains('owner-123'));
      expect(string, contains('2')); // team member count
      expect(string, contains('true')); // isPrivate
    });
  });
}
