import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panci/domain/entities/user.dart';
import 'package:panci/domain/repositories/user_repository.dart';
import 'package:panci/data/repositories/repository_provider.dart';
import 'package:panci/presentation/providers/auth_provider.dart';

/// StateNotifier that manages the current user's profile state.
///
/// This notifier follows clean architecture principles:
/// - Uses domain entity (User) for state
/// - Calls domain repository for data operations
/// - Manages presentation state immutably
/// - Provides computed properties for UI logic
///
/// The notifier implements:
/// - Loading user profile from Firestore
/// - Incrementing/decrementing canvas count
/// - Checking canvas creation eligibility
/// - Checking if user needs registration (guest limit reached)
class UserNotifier extends StateNotifier<User?> {
  /// Creates a user notifier.
  ///
  /// The initial state is null, representing no user loaded yet.
  UserNotifier(this._repository) : super(null);

  /// The repository for user data operations.
  final UserRepository _repository;

  /// Loads the user profile from Firestore.
  ///
  /// This should be called when:
  /// - The user first authenticates
  /// - After registration/login to refresh profile
  /// - When user data may have changed
  ///
  /// Parameters:
  /// - [userId]: The Firebase Auth UID of the user to load
  ///
  /// Sets state to null if loading fails (user not found, network error, etc.)
  Future<void> loadUser(String userId) async {
    try {
      debugPrint('Loading user profile: $userId');

      final user = await _repository.getUserProfile(userId);

      // Check if still mounted before updating state
      if (mounted) {
        state = user;

        debugPrint(
          'User profile loaded: ${user.username} (canvasCount: ${user.canvasCount}, isGuest: ${user.isGuest})',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading user profile: $e');
      debugPrint('Stack trace: $stackTrace');

      // Set state to null on error, only if still mounted
      if (mounted) {
        state = null;
      }
    }
  }

  /// Increments the canvas count for the current user.
  ///
  /// This should be called when the user creates a new canvas.
  /// Updates both Firestore and local state.
  ///
  /// Does nothing if no user is loaded (state is null).
  Future<void> incrementCanvasCount() async {
    if (state == null || !mounted) {
      debugPrint('Cannot increment canvas count: no user loaded or disposed');
      return;
    }

    try {
      debugPrint('Incrementing canvas count for user: ${state!.userId}');

      // Update in Firestore
      await _repository.incrementCanvasCount(state!.userId);

      // Update local state optimistically, only if still mounted
      if (mounted) {
        state = state!.copyWith(canvasCount: state!.canvasCount + 1);
        debugPrint('Canvas count incremented: ${state!.canvasCount}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error incrementing canvas count: $e');
      debugPrint('Stack trace: $stackTrace');

      // Reload user profile to get correct count from server
      if (mounted && state != null) {
        await loadUser(state!.userId);
      }
    }
  }

  /// Decrements the canvas count for the current user.
  ///
  /// This should be called when the user deletes a canvas.
  /// Updates both Firestore and local state.
  ///
  /// Does nothing if no user is loaded (state is null).
  /// The count will not go below zero.
  Future<void> decrementCanvasCount() async {
    if (state == null || !mounted) {
      debugPrint('Cannot decrement canvas count: no user loaded or disposed');
      return;
    }

    try {
      debugPrint('Decrementing canvas count for user: ${state!.userId}');

      // Update in Firestore
      await _repository.decrementCanvasCount(state!.userId);

      // Update local state optimistically, only if still mounted
      if (mounted) {
        // Ensure count doesn't go below zero
        final newCount = state!.canvasCount > 0 ? state!.canvasCount - 1 : 0;
        state = state!.copyWith(canvasCount: newCount);
        debugPrint('Canvas count decremented: ${state!.canvasCount}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error decrementing canvas count: $e');
      debugPrint('Stack trace: $stackTrace');

      // Reload user profile to get correct count from server
      if (mounted && state != null) {
        await loadUser(state!.userId);
      }
    }
  }

  /// Checks if the current user can create a new canvas.
  ///
  /// Returns false if:
  /// - No user is loaded (state is null)
  /// - User has reached their canvas limit based on account type
  ///
  /// Guest users: Limited to [User.maxGuestCanvases] (default: 3)
  /// Registered users: Limited to [User.maxRegisteredCanvases] (default: 50)
  bool get canCreateCanvas {
    if (state == null) {
      debugPrint('Cannot create canvas: no user loaded');
      return false;
    }

    return state!.canCreateCanvas;
  }

  /// Checks if the current user needs to register.
  ///
  /// Returns true if:
  /// - User is a guest AND
  /// - User has reached or exceeded the guest canvas limit
  ///
  /// This is used to prompt guests to register when they try to
  /// create more canvases than their limit allows.
  bool get needsRegistration {
    if (state == null) {
      return false;
    }

    return state!.isGuest && state!.canvasCount >= User.maxGuestCanvases;
  }

  /// Gets the number of remaining canvases the user can create.
  ///
  /// Returns 0 if no user is loaded.
  int get remainingCanvases {
    if (state == null) {
      return 0;
    }

    return state!.remainingCanvases;
  }

  /// Checks if the current user is a guest.
  ///
  /// Returns false if no user is loaded.
  bool get isGuest {
    if (state == null) {
      return false;
    }

    return state!.isGuest;
  }

  /// Gets the current user's display name.
  ///
  /// Returns 'Guest' if no user is loaded.
  String get displayName {
    if (state == null) {
      return 'Guest';
    }

    return state!.username;
  }
}

/// Global provider for managing the current user's profile state.
///
/// This provider:
/// - Creates a UserNotifier with repository integration
/// - Automatically loads the user profile when authenticated
/// - Reacts to authentication state changes
/// - Provides the current user's profile to the entire app
///
/// The provider automatically loads the user when:
/// - The user authenticates (login, register, guest sign-in)
/// - The authentication state changes
///
/// Usage:
/// ```dart
/// // Watch the user state (rebuilds on changes)
/// final user = ref.watch(userProvider);
/// if (user != null) {
///   print('Username: ${user.username}');
/// }
///
/// // Read the notifier to call methods (doesn't rebuild)
/// ref.read(userProvider.notifier).incrementCanvasCount();
///
/// // Check if user can create canvas
/// final canCreate = ref.read(userProvider.notifier).canCreateCanvas;
/// ```
final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  final authState = ref.watch(authProvider);

  final notifier = UserNotifier(repository);

  // Auto-load user when authenticated
  if (authState.userId != null) {
    // Load user asynchronously
    // Don't await - let the notifier handle the async operation
    notifier.loadUser(authState.userId!);
  }

  return notifier;
});

/// Provider for checking if the current user can create a canvas.
///
/// This is a convenience provider that can be watched to reactively
/// update UI based on canvas creation eligibility.
///
/// Usage:
/// ```dart
/// final canCreate = ref.watch(canCreateCanvasProvider);
/// ```
final canCreateCanvasProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return false;
  return user.canCreateCanvas;
});

/// Provider for checking if the current user needs to register.
///
/// This is a convenience provider that can be watched to show
/// registration prompts when guests reach their limit.
///
/// Usage:
/// ```dart
/// final needsReg = ref.watch(needsRegistrationProvider);
/// if (needsReg) {
///   // Show registration dialog
/// }
/// ```
final needsRegistrationProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return false;
  return user.isGuest && user.canvasCount >= User.maxGuestCanvases;
});

/// Provider for getting the current user's remaining canvas count.
///
/// This is a convenience provider for displaying how many more
/// canvases the user can create.
///
/// Usage:
/// ```dart
/// final remaining = ref.watch(remainingCanvasesProvider);
/// Text('You can create $remaining more canvases');
/// ```
final remainingCanvasesProvider = Provider<int>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return 0;
  return user.remainingCanvases;
});
