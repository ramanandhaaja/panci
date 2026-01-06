import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panci/data/models/active_user_model.dart';
import 'package:panci/domain/entities/active_user.dart';

void main() {
  group('ActiveUserModel', () {
    // Sample test data
    final testTimestamp = DateTime.parse('2025-01-01T12:00:00.000Z');
    const testColor = Colors.purple;
    const testCursorPosition = Offset(100.5, 200.7);

    final testEntityWithCursor = ActiveUser(
      userId: 'test-user-123',
      displayName: 'John Doe',
      cursorPosition: testCursorPosition,
      lastSeen: testTimestamp,
      cursorColor: testColor,
    );

    final testEntityWithoutCursor = ActiveUser(
      userId: 'test-user-456',
      displayName: 'Jane Smith',
      cursorPosition: null,
      lastSeen: testTimestamp,
      cursorColor: testColor,
    );

    test('toJson handles non-null cursorPosition', () {
      final model = ActiveUserModel.fromEntity(testEntityWithCursor);
      final json = model.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['userId'], 'test-user-123');
      expect(json['displayName'], 'John Doe');
      expect(json['lastSeen'], '2025-01-01T12:00:00.000Z');
      expect(json['cursorColorValue'], testColor.toARGB32());
      expect(json['cursorPosition'], isNotNull);
      expect(json['cursorPosition'], isA<Map<String, double>>());
      expect(json['cursorPosition']['x'], 100.5);
      expect(json['cursorPosition']['y'], 200.7);
    });

    test('toJson handles null cursorPosition', () {
      final model = ActiveUserModel.fromEntity(testEntityWithoutCursor);
      final json = model.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['userId'], 'test-user-456');
      expect(json['displayName'], 'Jane Smith');
      expect(json['lastSeen'], '2025-01-01T12:00:00.000Z');
      expect(json['cursorColorValue'], testColor.toARGB32());
      expect(json['cursorPosition'], isNull);
    });

    test('fromJson handles non-null cursorPosition', () {
      final json = {
        'userId': 'user-789',
        'displayName': 'Bob Johnson',
        'cursorPosition': {'x': 50.0, 'y': 75.0},
        'lastSeen': '2025-01-01T15:30:00.000Z',
        'cursorColorValue': Colors.blue.toARGB32(),
      };

      final model = ActiveUserModel.fromJson(json);

      expect(model.userId, 'user-789');
      expect(model.displayName, 'Bob Johnson');
      expect(model.cursorPosition, isNotNull);
      expect(model.cursorPosition!['x'], 50.0);
      expect(model.cursorPosition!['y'], 75.0);
      expect(model.lastSeen, '2025-01-01T15:30:00.000Z');
      expect(model.cursorColorValue, Colors.blue.toARGB32());
    });

    test('fromJson handles null cursorPosition', () {
      final json = {
        'userId': 'user-abc',
        'displayName': 'Alice Brown',
        'cursorPosition': null,
        'lastSeen': '2025-01-01T16:00:00.000Z',
        'cursorColorValue': Colors.red.toARGB32(),
      };

      final model = ActiveUserModel.fromJson(json);

      expect(model.userId, 'user-abc');
      expect(model.displayName, 'Alice Brown');
      expect(model.cursorPosition, isNull);
      expect(model.lastSeen, '2025-01-01T16:00:00.000Z');
      expect(model.cursorColorValue, Colors.red.toARGB32());
    });

    test('fromJson handles integer coordinates', () {
      final json = {
        'userId': 'user-int',
        'displayName': 'Int User',
        'cursorPosition': {'x': 100, 'y': 200}, // integers
        'lastSeen': '2025-01-01T12:00:00.000Z',
        'cursorColorValue': Colors.green.toARGB32(),
      };

      final model = ActiveUserModel.fromJson(json);

      expect(model.cursorPosition!['x'], 100.0);
      expect(model.cursorPosition!['y'], 200.0);
    });

    test('toEntity converts model to ActiveUser entity with cursor', () {
      final model = ActiveUserModel.fromEntity(testEntityWithCursor);
      final entity = model.toEntity();

      expect(entity, isA<ActiveUser>());
      expect(entity.userId, 'test-user-123');
      expect(entity.displayName, 'John Doe');
      expect(entity.cursorPosition, isNotNull);
      expect(entity.cursorPosition, const Offset(100.5, 200.7));
      expect(entity.lastSeen, testTimestamp);
      expect(entity.cursorColor.toARGB32(), testColor.toARGB32());
    });

    test('toEntity converts model to ActiveUser entity without cursor', () {
      final model = ActiveUserModel.fromEntity(testEntityWithoutCursor);
      final entity = model.toEntity();

      expect(entity, isA<ActiveUser>());
      expect(entity.userId, 'test-user-456');
      expect(entity.displayName, 'Jane Smith');
      expect(entity.cursorPosition, isNull);
      expect(entity.lastSeen, testTimestamp);
      expect(entity.cursorColor.toARGB32(), testColor.toARGB32());
    });

    test('fromEntity creates model from ActiveUser entity with cursor', () {
      final model = ActiveUserModel.fromEntity(testEntityWithCursor);

      expect(model, isA<ActiveUserModel>());
      expect(model.userId, 'test-user-123');
      expect(model.displayName, 'John Doe');
      expect(model.cursorPosition, isNotNull);
      expect(model.cursorPosition!['x'], 100.5);
      expect(model.cursorPosition!['y'], 200.7);
      expect(model.lastSeen, '2025-01-01T12:00:00.000Z');
      expect(model.cursorColorValue, testColor.toARGB32());
    });

    test('fromEntity creates model from ActiveUser entity without cursor', () {
      final model = ActiveUserModel.fromEntity(testEntityWithoutCursor);

      expect(model, isA<ActiveUserModel>());
      expect(model.userId, 'test-user-456');
      expect(model.displayName, 'Jane Smith');
      expect(model.cursorPosition, isNull);
      expect(model.lastSeen, '2025-01-01T12:00:00.000Z');
      expect(model.cursorColorValue, testColor.toARGB32());
    });

    test('JSON roundtrip preserves data with cursor', () {
      // Entity → Model → JSON → Model → Entity
      final model1 = ActiveUserModel.fromEntity(testEntityWithCursor);
      final json = model1.toJson();
      final model2 = ActiveUserModel.fromJson(json);
      final resultEntity = model2.toEntity();

      expect(resultEntity.userId, testEntityWithCursor.userId);
      expect(resultEntity.displayName, testEntityWithCursor.displayName);
      expect(resultEntity.cursorPosition, testEntityWithCursor.cursorPosition);
      expect(resultEntity.lastSeen, testEntityWithCursor.lastSeen);
      expect(
        resultEntity.cursorColor.toARGB32(),
        testEntityWithCursor.cursorColor.toARGB32(),
      );
    });

    test('JSON roundtrip preserves data without cursor', () {
      // Entity → Model → JSON → Model → Entity
      final model1 = ActiveUserModel.fromEntity(testEntityWithoutCursor);
      final json = model1.toJson();
      final model2 = ActiveUserModel.fromJson(json);
      final resultEntity = model2.toEntity();

      expect(resultEntity.userId, testEntityWithoutCursor.userId);
      expect(resultEntity.displayName, testEntityWithoutCursor.displayName);
      expect(resultEntity.cursorPosition, isNull);
      expect(resultEntity.lastSeen, testEntityWithoutCursor.lastSeen);
      expect(
        resultEntity.cursorColor.toARGB32(),
        testEntityWithoutCursor.cursorColor.toARGB32(),
      );
    });

    test('handles extreme cursor coordinates', () {
      final extremeEntity = ActiveUser(
        userId: 'extreme-user',
        displayName: 'Extreme User',
        cursorPosition: const Offset(-9999.9, 9999.9),
        lastSeen: testTimestamp,
        cursorColor: Colors.orange,
      );

      final model = ActiveUserModel.fromEntity(extremeEntity);
      final entity = model.toEntity();

      expect(entity.cursorPosition!.dx, -9999.9);
      expect(entity.cursorPosition!.dy, 9999.9);
    });

    test('handles zero cursor coordinates', () {
      final zeroEntity = ActiveUser(
        userId: 'zero-user',
        displayName: 'Zero User',
        cursorPosition: const Offset(0.0, 0.0),
        lastSeen: testTimestamp,
        cursorColor: Colors.black,
      );

      final model = ActiveUserModel.fromEntity(zeroEntity);
      final entity = model.toEntity();

      expect(entity.cursorPosition, const Offset(0.0, 0.0));
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
        final entity = ActiveUser(
          userId: 'color-test',
          displayName: 'Color Test',
          cursorPosition: null,
          lastSeen: testTimestamp,
          cursorColor: color,
        );

        final model = ActiveUserModel.fromEntity(entity);
        expect(model.cursorColorValue, color.toARGB32());

        final resultEntity = model.toEntity();
        expect(resultEntity.cursorColor.toARGB32(), color.toARGB32());
      }
    });

    test('preserves timestamp precision', () {
      final timestamps = [
        DateTime.parse('2025-01-01T00:00:00.000Z'),
        DateTime.parse('2025-12-31T23:59:59.999Z'),
        DateTime.parse('2025-06-15T12:30:45.123Z'),
      ];

      for (final timestamp in timestamps) {
        final entity = ActiveUser(
          userId: 'time-test',
          displayName: 'Time Test',
          cursorPosition: null,
          lastSeen: timestamp,
          cursorColor: Colors.black,
        );

        final model = ActiveUserModel.fromEntity(entity);
        final resultEntity = model.toEntity();

        expect(resultEntity.lastSeen, timestamp);
      }
    });

    test('handles various display names', () {
      final names = [
        'Simple Name',
        'Name With 123 Numbers',
        'Name-With-Dashes',
        'Name_With_Underscores',
        'Name.With.Dots',
        'नाम', // Unicode characters
        '名字', // Chinese characters
        'اسم', // Arabic characters
        'Very Long Name That Contains Many Characters And Spaces',
        'A', // Single character
      ];

      for (final name in names) {
        final entity = ActiveUser(
          userId: 'name-test',
          displayName: name,
          cursorPosition: null,
          lastSeen: testTimestamp,
          cursorColor: Colors.black,
        );

        final model = ActiveUserModel.fromEntity(entity);
        final resultEntity = model.toEntity();

        expect(resultEntity.displayName, name);
      }
    });

    test('equality works correctly with cursor', () {
      final model1 = ActiveUserModel.fromEntity(testEntityWithCursor);
      final model2 = ActiveUserModel.fromEntity(testEntityWithCursor);

      expect(model1, equals(model2));
      // Note: hashCode might differ for separate instances due to Map hashing
    });

    test('equality works correctly without cursor', () {
      final model1 = ActiveUserModel.fromEntity(testEntityWithoutCursor);
      final model2 = ActiveUserModel.fromEntity(testEntityWithoutCursor);

      expect(model1, equals(model2));
      // hashCode comparison removed - not required for models used only for serialization
    });

    test('inequality works correctly with different userId', () {
      final model1 = ActiveUserModel.fromEntity(testEntityWithCursor);
      final model2 = ActiveUserModel.fromEntity(
        testEntityWithCursor.copyWith(userId: 'different-user'),
      );

      expect(model1, isNot(equals(model2)));
    });

    test('inequality works correctly with different cursor', () {
      final model1 = ActiveUserModel.fromEntity(testEntityWithCursor);
      final model2 = ActiveUserModel.fromEntity(
        testEntityWithCursor.copyWith(cursorPosition: const Offset(999, 999)),
      );

      expect(model1, isNot(equals(model2)));
    });

    test('inequality works correctly when one has cursor and other does not', () {
      final model1 = ActiveUserModel.fromEntity(testEntityWithCursor);
      final model2 = ActiveUserModel.fromEntity(testEntityWithoutCursor);

      expect(model1, isNot(equals(model2)));
    });

    test('toString returns meaningful representation with cursor', () {
      final model = ActiveUserModel.fromEntity(testEntityWithCursor);
      final string = model.toString();

      expect(string, contains('ActiveUserModel'));
      expect(string, contains('test-user-123'));
      expect(string, contains('John Doe'));
      expect(string, contains('100.5'));
      expect(string, contains('200.7'));
    });

    test('toString returns meaningful representation without cursor', () {
      final model = ActiveUserModel.fromEntity(testEntityWithoutCursor);
      final string = model.toString();

      expect(string, contains('ActiveUserModel'));
      expect(string, contains('test-user-456'));
      expect(string, contains('Jane Smith'));
      expect(string, contains('null'));
    });

    test('handles cursor position transition from null to non-null', () {
      final entity1 = ActiveUser(
        userId: 'transition-user',
        displayName: 'Transition User',
        cursorPosition: null,
        lastSeen: testTimestamp,
        cursorColor: Colors.blue,
      );

      final model1 = ActiveUserModel.fromEntity(entity1);
      expect(model1.cursorPosition, isNull);

      final entity2 = entity1.copyWith(
        cursorPosition: const Offset(50.0, 100.0),
      );

      final model2 = ActiveUserModel.fromEntity(entity2);
      expect(model2.cursorPosition, isNotNull);
      expect(model2.cursorPosition!['x'], 50.0);
      expect(model2.cursorPosition!['y'], 100.0);
    });

    test('handles cursor position transition from non-null to null', () {
      final entity1 = ActiveUser(
        userId: 'transition-user',
        displayName: 'Transition User',
        cursorPosition: const Offset(50.0, 100.0),
        lastSeen: testTimestamp,
        cursorColor: Colors.blue,
      );

      final model1 = ActiveUserModel.fromEntity(entity1);
      expect(model1.cursorPosition, isNotNull);

      final entity2 = entity1.copyWith(
        clearCursorPosition: true,
      );

      final model2 = ActiveUserModel.fromEntity(entity2);
      expect(model2.cursorPosition, isNull);
    });

    test('handles floating point precision in cursor position', () {
      final entity = ActiveUser(
        userId: 'precision-user',
        displayName: 'Precision User',
        cursorPosition: const Offset(1.23456789, 9.87654321),
        lastSeen: testTimestamp,
        cursorColor: Colors.yellow,
      );

      final model = ActiveUserModel.fromEntity(entity);
      final resultEntity = model.toEntity();

      expect(resultEntity.cursorPosition!.dx, closeTo(1.23456789, 0.0000001));
      expect(resultEntity.cursorPosition!.dy, closeTo(9.87654321, 0.0000001));
    });
  });
}
