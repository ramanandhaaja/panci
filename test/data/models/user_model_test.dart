import 'package:flutter_test/flutter_test.dart';
import 'package:panci/data/models/user_model.dart';
import 'package:panci/domain/entities/user.dart';

void main() {
  group('UserModel', () {
    // Sample test data
    final testCreatedAt = DateTime.parse('2025-01-01T12:00:00.000Z');
    final testUpdatedAt = DateTime.parse('2025-01-07T10:30:00.000Z');

    final testEntity = User(
      userId: 'test-user-id-123',
      username: 'john_doe',
      email: 'john@example.com',
      canvasCount: 5,
      isGuest: false,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
    );

    final testModel = UserModel(
      userId: 'test-user-id-123',
      username: 'john_doe',
      email: 'john@example.com',
      canvasCount: 5,
      isGuest: false,
      createdAt: '2025-01-01T12:00:00.000Z',
      updatedAt: '2025-01-07T10:30:00.000Z',
    );

    final testJson = {
      'userId': 'test-user-id-123',
      'username': 'john_doe',
      'email': 'john@example.com',
      'canvasCount': 5,
      'isGuest': false,
      'createdAt': '2025-01-01T12:00:00.000Z',
      'updatedAt': '2025-01-07T10:30:00.000Z',
    };

    test('toJson converts UserModel to JSON map', () {
      final json = testModel.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['userId'], 'test-user-id-123');
      expect(json['username'], 'john_doe');
      expect(json['email'], 'john@example.com');
      expect(json['canvasCount'], 5);
      expect(json['isGuest'], false);
      expect(json['createdAt'], '2025-01-01T12:00:00.000Z');
      expect(json['updatedAt'], '2025-01-07T10:30:00.000Z');
    });

    test('fromJson creates UserModel from JSON map', () {
      final model = UserModel.fromJson(testJson);

      expect(model.userId, 'test-user-id-123');
      expect(model.username, 'john_doe');
      expect(model.email, 'john@example.com');
      expect(model.canvasCount, 5);
      expect(model.isGuest, false);
      expect(model.createdAt, '2025-01-01T12:00:00.000Z');
      expect(model.updatedAt, '2025-01-07T10:30:00.000Z');
    });

    test('fromJson handles missing canvasCount with default value 0', () {
      final jsonWithoutCanvasCount = {
        'userId': 'test-user-id',
        'username': 'john',
        'email': 'john@example.com',
        'isGuest': false,
        'createdAt': '2025-01-01T12:00:00.000Z',
        'updatedAt': '2025-01-01T12:00:00.000Z',
      };

      final model = UserModel.fromJson(jsonWithoutCanvasCount);

      expect(model.canvasCount, 0);
    });

    test('fromJson handles missing createdAt with current time', () {
      final jsonWithoutTimestamps = {
        'userId': 'test-user-id',
        'username': 'john',
        'email': 'john@example.com',
        'isGuest': false,
        'canvasCount': 0,
      };

      final beforeParsing = DateTime.now();
      final model = UserModel.fromJson(jsonWithoutTimestamps);
      final afterParsing = DateTime.now();

      final parsedCreatedAt = DateTime.parse(model.createdAt);
      expect(
        parsedCreatedAt.isAfter(beforeParsing.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        parsedCreatedAt.isBefore(afterParsing.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('fromJson handles missing updatedAt with current time', () {
      final jsonWithoutTimestamps = {
        'userId': 'test-user-id',
        'username': 'john',
        'email': 'john@example.com',
        'isGuest': false,
        'canvasCount': 0,
      };

      final beforeParsing = DateTime.now();
      final model = UserModel.fromJson(jsonWithoutTimestamps);
      final afterParsing = DateTime.now();

      final parsedUpdatedAt = DateTime.parse(model.updatedAt);
      expect(
        parsedUpdatedAt.isAfter(beforeParsing.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        parsedUpdatedAt.isBefore(afterParsing.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('toEntity converts model to User entity', () {
      final entity = testModel.toEntity();

      expect(entity, isA<User>());
      expect(entity.userId, 'test-user-id-123');
      expect(entity.username, 'john_doe');
      expect(entity.email, 'john@example.com');
      expect(entity.canvasCount, 5);
      expect(entity.isGuest, false);
      expect(entity.createdAt, testCreatedAt);
      expect(entity.updatedAt, testUpdatedAt);
    });

    test('fromEntity creates model from User entity', () {
      final model = UserModel.fromEntity(testEntity);

      expect(model, isA<UserModel>());
      expect(model.userId, 'test-user-id-123');
      expect(model.username, 'john_doe');
      expect(model.email, 'john@example.com');
      expect(model.canvasCount, 5);
      expect(model.isGuest, false);
      expect(model.createdAt, '2025-01-01T12:00:00.000Z');
      expect(model.updatedAt, '2025-01-07T10:30:00.000Z');
    });

    test('JSON roundtrip preserves all data', () {
      // Entity → Model → JSON → Model → Entity
      final model1 = UserModel.fromEntity(testEntity);
      final json = model1.toJson();
      final model2 = UserModel.fromJson(json);
      final resultEntity = model2.toEntity();

      expect(resultEntity.userId, testEntity.userId);
      expect(resultEntity.username, testEntity.username);
      expect(resultEntity.email, testEntity.email);
      expect(resultEntity.canvasCount, testEntity.canvasCount);
      expect(resultEntity.isGuest, testEntity.isGuest);
      expect(resultEntity.createdAt, testEntity.createdAt);
      expect(resultEntity.updatedAt, testEntity.updatedAt);
    });

    test('handles guest user correctly', () {
      final guestEntity = User.guest(userId: 'guest-user-123');
      final model = UserModel.fromEntity(guestEntity);

      expect(model.userId, 'guest-user-123');
      expect(model.username, 'Guest');
      expect(model.email, '');
      expect(model.canvasCount, 0);
      expect(model.isGuest, true);

      final json = model.toJson();
      expect(json['username'], 'Guest');
      expect(json['email'], '');
      expect(json['isGuest'], true);

      final parsedModel = UserModel.fromJson(json);
      final entity = parsedModel.toEntity();

      expect(entity.userId, 'guest-user-123');
      expect(entity.username, 'Guest');
      expect(entity.email, '');
      expect(entity.isGuest, true);
    });

    test('handles registered user correctly', () {
      final registeredEntity = User.registered(
        userId: 'registered-user-123',
        username: 'john_smith',
        email: 'john.smith@example.com',
      );
      final model = UserModel.fromEntity(registeredEntity);

      expect(model.userId, 'registered-user-123');
      expect(model.username, 'john_smith');
      expect(model.email, 'john.smith@example.com');
      expect(model.canvasCount, 0);
      expect(model.isGuest, false);

      final json = model.toJson();
      expect(json['username'], 'john_smith');
      expect(json['email'], 'john.smith@example.com');
      expect(json['isGuest'], false);

      final parsedModel = UserModel.fromJson(json);
      final entity = parsedModel.toEntity();

      expect(entity.userId, 'registered-user-123');
      expect(entity.username, 'john_smith');
      expect(entity.email, 'john.smith@example.com');
      expect(entity.isGuest, false);
    });

    test('DateTime serialization preserves precision', () {
      final timestamps = [
        DateTime.parse('2025-01-01T00:00:00.000Z'),
        DateTime.parse('2025-12-31T23:59:59.999Z'),
        DateTime.parse('2025-06-15T12:30:45.123Z'),
      ];

      for (final timestamp in timestamps) {
        final entity = User(
          userId: 'time-test',
          username: 'test',
          email: 'test@example.com',
          canvasCount: 0,
          isGuest: false,
          createdAt: timestamp,
          updatedAt: timestamp,
        );

        final model = UserModel.fromEntity(entity);
        final resultEntity = model.toEntity();

        expect(resultEntity.createdAt, timestamp);
        expect(resultEntity.updatedAt, timestamp);
      }
    });

    test('equality works correctly for identical models', () {
      final model1 = UserModel.fromEntity(testEntity);
      final model2 = UserModel.fromEntity(testEntity);

      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('inequality works correctly for different models', () {
      final model1 = UserModel.fromEntity(testEntity);
      final model2 = UserModel.fromEntity(
        testEntity.copyWith(username: 'different_user'),
      );

      expect(model1, isNot(equals(model2)));
      expect(model1.hashCode, isNot(equals(model2.hashCode)));
    });

    test('handles empty email correctly', () {
      final entity = User(
        userId: 'test-user',
        username: 'testuser',
        email: '',
        canvasCount: 0,
        isGuest: true,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      final model = UserModel.fromEntity(entity);
      expect(model.email, '');

      final json = model.toJson();
      expect(json['email'], '');

      final parsedModel = UserModel.fromJson(json);
      expect(parsedModel.email, '');

      final resultEntity = parsedModel.toEntity();
      expect(resultEntity.email, '');
    });

    test('handles zero canvas count correctly', () {
      final entity = testEntity.copyWith(canvasCount: 0);
      final model = UserModel.fromEntity(entity);

      expect(model.canvasCount, 0);

      final json = model.toJson();
      expect(json['canvasCount'], 0);

      final parsedModel = UserModel.fromJson(json);
      expect(parsedModel.canvasCount, 0);
    });

    test('handles large canvas count correctly', () {
      final entity = testEntity.copyWith(canvasCount: 100);
      final model = UserModel.fromEntity(entity);

      expect(model.canvasCount, 100);

      final json = model.toJson();
      expect(json['canvasCount'], 100);

      final parsedModel = UserModel.fromJson(json);
      expect(parsedModel.canvasCount, 100);
    });

    test('toString returns meaningful representation', () {
      final model = UserModel.fromEntity(testEntity);
      final string = model.toString();

      expect(string, contains('UserModel'));
      expect(string, contains('test-user-id-123'));
      expect(string, contains('john_doe'));
      expect(string, contains('john@example.com'));
      expect(string, contains('5'));
      expect(string, contains('false'));
    });

    test('handles special characters in username and email', () {
      final entity = User(
        userId: 'special-user',
        username: 'user_name-123',
        email: 'test+special@example.co.uk',
        canvasCount: 1,
        isGuest: false,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      final model = UserModel.fromEntity(entity);
      final json = model.toJson();
      final parsedModel = UserModel.fromJson(json);
      final resultEntity = parsedModel.toEntity();

      expect(resultEntity.username, 'user_name-123');
      expect(resultEntity.email, 'test+special@example.co.uk');
    });
  });
}
