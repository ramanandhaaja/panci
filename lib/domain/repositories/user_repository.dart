import 'package:panci/domain/entities/user.dart';

/// Repository interface for managing user profiles and authentication data.
///
/// This abstract class defines the contract for storing and retrieving
/// user profile information. Following clean architecture principles, this
/// interface is defined in the domain layer and is implemented in the data layer.
///
/// The repository pattern provides:
/// - Abstraction over data sources (Firestore, local storage, etc.)
/// - Single source of truth for user data
/// - Separation of concerns between business logic and data access
/// - Easy testability through mocking
///
/// Implementations should handle:
/// - Network errors and offline scenarios
/// - Data validation and sanitization
/// - Concurrent modifications and conflict resolution
/// - Proper error handling and logging
/// - User authentication state management
abstract class UserRepository {
  /// Creates a new user profile in Firestore.
  ///
  /// This should be called after successful Firebase Authentication to
  /// create the corresponding user profile document.
  ///
  /// Parameters:
  /// - [userId]: The Firebase Auth UID
  /// - [username]: The user's display name
  /// - [email]: The user's email address (empty for guest users)
  /// - [isGuest]: Whether this is a guest/anonymous user
  ///
  /// Returns:
  /// - [User] The newly created user profile
  ///
  /// Throws:
  /// - Exception if the user profile already exists
  /// - Exception if there's a network or permission error
  ///
  /// Example:
  /// ```dart
  /// final user = await repository.createUser(
  ///   userId: firebaseUser.uid,
  ///   username: 'john_doe',
  ///   email: 'john@example.com',
  ///   isGuest: false,
  /// );
  /// ```
  Future<User> createUser({
    required String userId,
    required String username,
    required String email,
    required bool isGuest,
  });

  /// Gets a user profile by userId.
  ///
  /// Fetches the complete user profile from Firestore including
  /// all metadata and statistics.
  ///
  /// Parameters:
  /// - [userId]: The Firebase Auth UID
  ///
  /// Returns:
  /// - [User] The user profile
  ///
  /// Throws:
  /// - Exception if the user profile doesn't exist
  /// - Exception if there's a network or permission error
  ///
  /// Example:
  /// ```dart
  /// final user = await repository.getUserProfile('user-123');
  /// print('Username: ${user.username}');
  /// print('Canvas count: ${user.canvasCount}');
  /// ```
  Future<User> getUserProfile(String userId);

  /// Updates a user profile.
  ///
  /// Updates the user profile document in Firestore with new data.
  /// This method updates the entire profile, so ensure all fields
  /// are set correctly in the [User] object.
  ///
  /// The [updatedAt] timestamp is automatically set to the current time.
  ///
  /// Parameters:
  /// - [user]: The updated user profile
  ///
  /// Returns:
  /// - Completes when the profile has been successfully updated
  ///
  /// Throws:
  /// - Exception if the user doesn't exist
  /// - Exception if there's a network or permission error
  ///
  /// Example:
  /// ```dart
  /// final updatedUser = user.copyWith(username: 'new_username');
  /// await repository.updateUser(updatedUser);
  /// ```
  Future<void> updateUser(User user);

  /// Increments the canvas count for a user.
  ///
  /// This is called when a user creates a new canvas. It atomically
  /// increments the canvasCount field in Firestore to ensure accuracy
  /// even under concurrent operations.
  ///
  /// Parameters:
  /// - [userId]: The Firebase Auth UID
  ///
  /// Returns:
  /// - Completes when the count has been successfully incremented
  ///
  /// Throws:
  /// - Exception if the user doesn't exist
  /// - Exception if there's a network or permission error
  ///
  /// Example:
  /// ```dart
  /// await repository.incrementCanvasCount('user-123');
  /// ```
  Future<void> incrementCanvasCount(String userId);

  /// Decrements the canvas count for a user.
  ///
  /// This is called when a user deletes a canvas. It atomically
  /// decrements the canvasCount field in Firestore to ensure accuracy
  /// even under concurrent operations.
  ///
  /// The count will not go below zero.
  ///
  /// Parameters:
  /// - [userId]: The Firebase Auth UID
  ///
  /// Returns:
  /// - Completes when the count has been successfully decremented
  ///
  /// Throws:
  /// - Exception if the user doesn't exist
  /// - Exception if there's a network or permission error
  ///
  /// Example:
  /// ```dart
  /// await repository.decrementCanvasCount('user-123');
  /// ```
  Future<void> decrementCanvasCount(String userId);

  /// Converts a guest user account to a registered member account.
  ///
  /// This upgrades an anonymous user to a full member by:
  /// - Updating their username and email
  /// - Setting isGuest to false
  /// - Preserving their existing canvas count and data
  ///
  /// This is typically called after a guest user signs up with
  /// email/password or social authentication.
  ///
  /// Parameters:
  /// - [userId]: The Firebase Auth UID of the guest user
  /// - [username]: The new username for the account
  /// - [email]: The new email address for the account
  ///
  /// Returns:
  /// - Completes when the account has been successfully upgraded
  ///
  /// Throws:
  /// - Exception if the user doesn't exist
  /// - Exception if the user is already a registered member
  /// - Exception if there's a network or permission error
  ///
  /// Example:
  /// ```dart
  /// await repository.convertGuestToMember(
  ///   userId: 'user-123',
  ///   username: 'john_doe',
  ///   email: 'john@example.com',
  /// );
  /// ```
  Future<void> convertGuestToMember({
    required String userId,
    required String username,
    required String email,
  });
}
