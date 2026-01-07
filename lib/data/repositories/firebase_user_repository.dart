import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:panci/data/models/user_model.dart';
import 'package:panci/domain/entities/user.dart';
import 'package:panci/domain/repositories/user_repository.dart';

/// Firebase Firestore implementation of the [UserRepository].
///
/// This class provides persistent storage for user profile data using
/// Cloud Firestore. It implements the repository interface defined in the
/// domain layer, following clean architecture principles.
///
/// Firestore structure:
/// ```
/// users/{userId}
///   - userId: string
///   - username: string
///   - email: string
///   - canvasCount: integer
///   - isGuest: boolean
///   - createdAt: ISO timestamp string
///   - updatedAt: ISO timestamp string
/// ```
///
/// Features:
/// - Real-time user profile synchronization
/// - Atomic canvas count updates using FieldValue.increment
/// - Proper error handling with clear exception messages
/// - Debug logging for all operations
/// - Guest to member account conversion support
///
/// Error handling:
/// - Network errors are logged and propagated as exceptions
/// - Missing documents throw clear exceptions
/// - Invalid data is logged and handled gracefully
class FirebaseUserRepository implements UserRepository {
  /// Creates a Firebase user repository.
  ///
  /// By default, uses the default Firestore instance. A custom instance
  /// can be provided for testing or multi-project scenarios.
  FirebaseUserRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    // Enable offline persistence for better user experience
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// The Firestore instance used for data operations.
  final FirebaseFirestore _firestore;

  /// The collection path for user documents.
  static const String _usersCollection = 'users';

  /// Gets a reference to a user document.
  DocumentReference<Map<String, dynamic>> _getUserRef(String userId) {
    return _firestore.collection(_usersCollection).doc(userId);
  }

  @override
  Future<User> createUser({
    required String userId,
    required String username,
    required String email,
    required bool isGuest,
  }) async {
    try {
      debugPrint(
        'Creating user: $userId (username: $username, isGuest: $isGuest)',
      );

      // Check if user already exists
      final docRef = _getUserRef(userId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        debugPrint('User $userId already exists');
        throw Exception(
          'User profile already exists for userId: $userId. '
          'Use updateUser() to modify an existing profile.',
        );
      }

      // Create the user entity
      final now = DateTime.now();
      final user = User(
        userId: userId,
        username: username,
        email: email,
        canvasCount: 0,
        isGuest: isGuest,
        createdAt: now,
        updatedAt: now,
      );

      // Convert to model and save to Firestore
      final userModel = UserModel.fromEntity(user);
      await docRef.set(userModel.toJson());

      debugPrint('Successfully created user: $userId');

      return user;
    } catch (e, stackTrace) {
      debugPrint('Error creating user $userId: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to create user: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<User> getUserProfile(String userId) async {
    try {
      debugPrint('Getting user profile: $userId');

      final docRef = _getUserRef(userId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        debugPrint('User $userId does not exist');
        throw Exception(
          'User profile not found for userId: $userId. '
          'Please create the user profile first using createUser().',
        );
      }

      final data = docSnapshot.data();
      if (data == null) {
        debugPrint('User $userId has null data');
        throw Exception(
          'User profile data is null for userId: $userId. '
          'The document exists but contains no data.',
        );
      }

      // Convert from Firestore JSON to domain entity
      final model = UserModel.fromJson(data);
      final entity = model.toEntity();

      debugPrint(
        'Loaded user $userId: ${entity.username}, canvasCount: ${entity.canvasCount}',
      );

      return entity;
    } catch (e, stackTrace) {
      debugPrint('Error getting user profile $userId: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to get user profile: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateUser(User user) async {
    try {
      debugPrint('Updating user: ${user.userId}');

      // Check if user exists
      final docRef = _getUserRef(user.userId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        debugPrint('User ${user.userId} does not exist, cannot update');
        throw Exception(
          'User profile not found for userId: ${user.userId}. '
          'Cannot update a non-existent user. Use createUser() instead.',
        );
      }

      // Update the updatedAt timestamp
      final updatedUser = user.copyWith(updatedAt: DateTime.now());

      // Convert to model and save to Firestore
      final userModel = UserModel.fromEntity(updatedUser);
      await docRef.update(userModel.toJson());

      debugPrint(
        'Successfully updated user: ${user.userId} (username: ${user.username})',
      );
    } catch (e, stackTrace) {
      debugPrint('Error updating user ${user.userId}: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to update user: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> incrementCanvasCount(String userId) async {
    try {
      debugPrint('Incrementing canvas count for user: $userId');

      final docRef = _getUserRef(userId);

      // Use atomic increment to ensure accuracy even under concurrent operations
      await docRef.update({
        'canvasCount': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('Successfully incremented canvas count for user: $userId');
    } catch (e, stackTrace) {
      debugPrint('Error incrementing canvas count for user $userId: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        // Check if the error is due to missing document
        if (e.code == 'not-found') {
          throw Exception(
            'User profile not found for userId: $userId. '
            'Cannot increment canvas count for non-existent user.',
          );
        }
        throw Exception('Failed to increment canvas count: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> decrementCanvasCount(String userId) async {
    try {
      debugPrint('Decrementing canvas count for user: $userId');

      final docRef = _getUserRef(userId);

      // Use atomic decrement to ensure accuracy even under concurrent operations
      // Note: This can result in negative values, but we'll handle that in the UI
      // by checking user.canCreateCanvas before allowing canvas creation
      await docRef.update({
        'canvasCount': FieldValue.increment(-1),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('Successfully decremented canvas count for user: $userId');
    } catch (e, stackTrace) {
      debugPrint('Error decrementing canvas count for user $userId: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        // Check if the error is due to missing document
        if (e.code == 'not-found') {
          throw Exception(
            'User profile not found for userId: $userId. '
            'Cannot decrement canvas count for non-existent user.',
          );
        }
        throw Exception('Failed to decrement canvas count: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> convertGuestToMember({
    required String userId,
    required String username,
    required String email,
  }) async {
    try {
      debugPrint(
        'Converting guest user to member: $userId (new username: $username)',
      );

      // Get the current user profile
      final user = await getUserProfile(userId);

      // Check if the user is actually a guest
      if (!user.isGuest) {
        debugPrint('User $userId is already a registered member');
        throw Exception(
          'User $userId is already a registered member. '
          'Cannot convert a non-guest user.',
        );
      }

      // Update the user profile to a registered member
      final updatedUser = user.copyWith(
        username: username,
        email: email,
        isGuest: false,
        updatedAt: DateTime.now(),
      );

      // Save the updated profile
      final docRef = _getUserRef(userId);
      final userModel = UserModel.fromEntity(updatedUser);
      await docRef.update(userModel.toJson());

      debugPrint(
        'Successfully converted guest user to member: $userId '
        '(username: $username, canvasCount preserved: ${user.canvasCount})',
      );
    } catch (e, stackTrace) {
      debugPrint('Error converting guest user to member $userId: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to convert guest to member: ${e.message}');
      }
      rethrow;
    }
  }

  /// Deletes a user profile from Firestore.
  ///
  /// This is a utility method for user account deletion, not part of the
  /// repository interface. Use with extreme caution as this operation
  /// cannot be undone.
  ///
  /// Important: This only deletes the user profile document. It does NOT:
  /// - Delete the user's canvases (must be done separately)
  /// - Delete the user's Firebase Authentication account
  /// - Remove the user from team member lists in other canvases
  ///
  /// Parameters:
  /// - [userId]: The Firebase Auth UID of the user to delete
  Future<void> deleteUser(String userId) async {
    try {
      debugPrint('Deleting user profile: $userId');

      await _getUserRef(userId).delete();

      debugPrint('Successfully deleted user profile: $userId');
    } catch (e, stackTrace) {
      debugPrint('Error deleting user profile $userId: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is FirebaseException) {
        throw Exception('Failed to delete user profile: ${e.message}');
      }
      rethrow;
    }
  }

  /// Checks if a user profile exists in Firestore.
  ///
  /// This is a utility method for checking user existence before
  /// performing operations.
  ///
  /// Parameters:
  /// - [userId]: The Firebase Auth UID to check
  ///
  /// Returns:
  /// - true if the user profile exists, false otherwise
  Future<bool> userExists(String userId) async {
    try {
      final docSnapshot = await _getUserRef(userId).get();
      return docSnapshot.exists;
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      return false;
    }
  }
}
