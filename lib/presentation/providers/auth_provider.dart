import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panci/domain/repositories/user_repository.dart';
import 'package:panci/data/repositories/repository_provider.dart';

/// Represents the authentication status of the user.
///
/// This enum is used to track the different states of the authentication flow:
/// - loading: Initial state or checking authentication status
/// - authenticated: User is signed in (guest or registered)
/// - unauthenticated: User is not signed in (should not normally happen as we auto-sign in guests)
enum AuthStatus {
  /// Authentication status is being determined
  loading,

  /// User is successfully authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,
}

/// Represents the complete authentication state of the application.
///
/// This immutable state class holds all authentication-related data including
/// the current status, user ID, and any error messages from auth operations.
@immutable
class AuthState {
  /// Creates an authentication state.
  const AuthState({
    required this.status,
    this.userId,
    this.errorMessage,
  });

  /// Creates a loading state.
  const AuthState.loading()
      : status = AuthStatus.loading,
        userId = null,
        errorMessage = null;

  /// Creates an authenticated state.
  const AuthState.authenticated(String uid)
      : status = AuthStatus.authenticated,
        userId = uid,
        errorMessage = null;

  /// Creates an unauthenticated state.
  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        userId = null,
        errorMessage = null;

  /// The current authentication status.
  final AuthStatus status;

  /// The Firebase Auth user ID (UID) if authenticated.
  ///
  /// Null if the user is not authenticated.
  final String? userId;

  /// Error message from the last authentication operation.
  ///
  /// Null if there was no error or the error has been cleared.
  final String? errorMessage;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Whether the authentication status is being determined.
  bool get isLoading => status == AuthStatus.loading;

  /// Creates a copy of this state with the given fields replaced.
  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthState &&
        other.status == status &&
        other.userId == userId &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(status, userId, errorMessage);

  @override
  String toString() {
    return 'AuthState(status: $status, userId: $userId, errorMessage: $errorMessage)';
  }
}

/// StateNotifier that manages the authentication state.
///
/// This notifier follows clean architecture principles:
/// - Uses domain repository for user profile operations
/// - Manages presentation state (auth status, error messages)
/// - Updates state immutably using copyWith pattern
/// - Integrates with Firebase Authentication
/// - Listens to auth state changes and updates state accordingly
///
/// The notifier implements:
/// - Guest sign-in (anonymous authentication)
/// - User registration (convert guest to member or new registration)
/// - Login with email/password
/// - Logout (signs out and auto-signs in as guest)
/// - Automatic user profile creation/management
class AuthNotifier extends StateNotifier<AuthState> {
  /// Creates an authentication notifier.
  ///
  /// The notifier immediately starts listening to Firebase auth state changes
  /// and updates the state accordingly.
  AuthNotifier(this._userRepository)
      : super(const AuthState.loading()) {
    _init();
  }

  /// The repository for user profile operations.
  final UserRepository _userRepository;

  /// Subscription to Firebase auth state changes.
  StreamSubscription<firebase_auth.User?>? _authSubscription;

  /// Flag to prevent multiple simultaneous guest sign-in attempts.
  bool _isSigningInAsGuest = false;

  /// Initializes the authentication listener.
  ///
  /// Sets up a stream listener that reacts to Firebase Authentication
  /// state changes and updates the app state accordingly.
  void _init() {
    debugPrint('Initializing AuthNotifier...');

    _authSubscription = firebase_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen(
      (user) async {
        debugPrint('Auth state changed: ${user?.uid ?? 'null'}');

        if (user != null) {
          // Ensure user profile exists in Firestore BEFORE updating state
          // This handles cases where Firebase Auth has a user but Firestore profile is missing
          await _ensureUserProfileExists(user);

          // Update state AFTER ensuring profile exists
          state = AuthState.authenticated(user.uid);
          debugPrint('User authenticated: ${user.uid} (isAnonymous: ${user.isAnonymous})');
        } else {
          // User is signed out
          state = const AuthState.unauthenticated();
          debugPrint('User unauthenticated');

          // Auto-sign in as guest if not authenticated and not already signing in
          // This ensures the app always has a user
          if (!_isSigningInAsGuest) {
            signInAsGuest();
          }
        }
      },
      onError: (error) {
        debugPrint('Error in auth state stream: $error');
        state = state.copyWith(errorMessage: error.toString());
      },
    );
  }

  /// Ensures that a user profile exists in Firestore.
  ///
  /// This is called when any user is detected to handle cases where
  /// Firebase Auth has a user but the Firestore profile doesn't exist
  /// (e.g., after data deletion, failed registration, etc.).
  ///
  /// For anonymous users: Creates a guest profile
  /// For registered users: Creates a profile with their email and display name
  Future<void> _ensureUserProfileExists(firebase_auth.User user) async {
    try {
      // Check if user profile exists
      final userExists = await _userRepository.getUserProfile(user.uid).then(
        (_) => true,
        onError: (_) => false,
      );

      if (!userExists) {
        if (user.isAnonymous) {
          // Create guest user profile
          debugPrint('Guest profile missing, creating: ${user.uid}');

          await _userRepository.createUser(
            userId: user.uid,
            username: 'Guest',
            email: '',
            isGuest: true,
          );

          debugPrint('Guest user profile created: ${user.uid}');
        } else {
          // Create registered user profile
          debugPrint('Registered user profile missing, creating: ${user.uid}');

          // Extract email and username from Firebase Auth user
          final email = user.email ?? '';
          final username = user.displayName ?? email.split('@').first;

          await _userRepository.createUser(
            userId: user.uid,
            username: username,
            email: email,
            isGuest: false,
          );

          debugPrint('Registered user profile created: ${user.uid} ($email)');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error ensuring user profile exists: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Signs in the user anonymously as a guest.
  ///
  /// This method:
  /// 1. Signs in to Firebase using anonymous authentication
  /// 2. Creates a guest user profile in Firestore
  ///
  /// Guest users have limited features (canvas creation limit).
  /// They can later be converted to full members via registration.
  ///
  /// Throws:
  /// - Exception if sign-in fails
  /// - Exception if user profile creation fails
  Future<void> signInAsGuest() async {
    // Prevent multiple simultaneous sign-in attempts
    if (_isSigningInAsGuest) {
      debugPrint('Guest sign-in already in progress, skipping...');
      return;
    }

    _isSigningInAsGuest = true;

    try {
      debugPrint('Signing in as guest...');

      // Sign in anonymously with Firebase
      final credential = await firebase_auth.FirebaseAuth.instance
          .signInAnonymously();

      final userId = credential.user!.uid;
      debugPrint('Guest sign-in successful: $userId');

      // Check if user profile already exists
      // This can happen if the user previously signed in as guest
      final userExists = await _userRepository.getUserProfile(userId).then(
        (_) => true,
        onError: (_) => false,
      );

      if (!userExists) {
        // Create guest user profile
        await _userRepository.createUser(
          userId: userId,
          username: 'Guest',
          email: '',
          isGuest: true,
        );
        debugPrint('Guest user profile created: $userId');
      } else {
        debugPrint('Guest user profile already exists: $userId');
      }

      // State is automatically updated by the auth state listener
    } catch (e, stackTrace) {
      debugPrint('Error signing in as guest: $e');
      debugPrint('Stack trace: $stackTrace');

      state = state.copyWith(
        errorMessage: 'Failed to sign in as guest: ${e.toString()}',
      );
      rethrow;
    } finally {
      _isSigningInAsGuest = false;
    }
  }

  /// Registers a new user with email and password.
  ///
  /// This method handles two scenarios:
  ///
  /// 1. **Guest Conversion**: If the current user is an anonymous guest,
  ///    this converts them to a registered member by linking their
  ///    anonymous account with email/password credentials. This preserves
  ///    their existing data (canvases, etc.).
  ///
  /// 2. **New Registration**: If there's no current user or the user is
  ///    already registered, this creates a brand new account.
  ///
  /// Parameters:
  /// - [username]: The user's display name
  /// - [email]: The user's email address
  /// - [password]: The user's password
  ///
  /// Throws:
  /// - Exception if registration fails (weak password, email in use, etc.)
  /// - Exception if user profile creation/update fails
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Registering user: $email (username: $username)');

      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        // Convert guest to member by linking credentials
        debugPrint('Converting guest to member: ${currentUser.uid}');

        final credential = firebase_auth.EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        await currentUser.linkWithCredential(credential);

        // Update user profile in Firestore
        await _userRepository.convertGuestToMember(
          userId: currentUser.uid,
          username: username,
          email: email,
        );

        debugPrint('Guest converted to member: ${currentUser.uid}');
      } else {
        // New registration
        debugPrint('Creating new user account');

        final credential = await firebase_auth.FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final userId = credential.user!.uid;

        // Create user profile in Firestore
        await _userRepository.createUser(
          userId: userId,
          username: username,
          email: email,
          isGuest: false,
        );

        debugPrint('New user registered: $userId');
      }

      // Clear any error messages
      state = state.copyWith(clearError: true);

      // State is automatically updated by the auth state listener
    } catch (e, stackTrace) {
      debugPrint('Error during registration: $e');
      debugPrint('Stack trace: $stackTrace');

      // Provide user-friendly error messages
      String errorMessage = 'Registration failed: ';
      if (e is firebase_auth.FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage += 'This email is already registered.';
            break;
          case 'invalid-email':
            errorMessage += 'The email address is invalid.';
            break;
          case 'weak-password':
            errorMessage += 'The password is too weak.';
            break;
          case 'operation-not-allowed':
            errorMessage += 'Email/password accounts are not enabled.';
            break;
          default:
            errorMessage += e.message ?? 'Unknown error';
        }
      } else {
        errorMessage += e.toString();
      }

      state = state.copyWith(errorMessage: errorMessage);
      rethrow;
    }
  }

  /// Logs in an existing user with email and password.
  ///
  /// Parameters:
  /// - [email]: The user's email address
  /// - [password]: The user's password
  ///
  /// Throws:
  /// - Exception if login fails (wrong password, user not found, etc.)
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Logging in user: $email');

      await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Clear any error messages
      state = state.copyWith(clearError: true);

      debugPrint('User logged in successfully');

      // State is automatically updated by the auth state listener
    } catch (e, stackTrace) {
      debugPrint('Error during login: $e');
      debugPrint('Stack trace: $stackTrace');

      // Provide user-friendly error messages
      String errorMessage = 'Login failed: ';
      if (e is firebase_auth.FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage += 'No account found with this email.';
            break;
          case 'wrong-password':
            errorMessage += 'Incorrect password.';
            break;
          case 'invalid-email':
            errorMessage += 'The email address is invalid.';
            break;
          case 'user-disabled':
            errorMessage += 'This account has been disabled.';
            break;
          default:
            errorMessage += e.message ?? 'Unknown error';
        }
      } else {
        errorMessage += e.toString();
      }

      state = state.copyWith(errorMessage: errorMessage);
      rethrow;
    }
  }

  /// Logs out the current user.
  ///
  /// This method:
  /// 1. Signs out from Firebase Authentication
  /// 2. Automatically signs in as a new guest user
  ///
  /// This ensures the app always has an authenticated user, which
  /// simplifies the app logic and allows guests to immediately start
  /// using the app without explicit sign-in.
  Future<void> logout() async {
    try {
      debugPrint('Logging out user...');

      await firebase_auth.FirebaseAuth.instance.signOut();

      debugPrint('User logged out successfully');

      // The auth state listener will detect the sign-out
      // and automatically call signInAsGuest()
    } catch (e, stackTrace) {
      debugPrint('Error during logout: $e');
      debugPrint('Stack trace: $stackTrace');

      state = state.copyWith(
        errorMessage: 'Logout failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Clears the current error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    debugPrint('Disposing AuthNotifier');
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Global provider for managing authentication state.
///
/// This provider:
/// - Creates an AuthNotifier with repository integration
/// - Listens to Firebase Authentication state changes
/// - Manages the authentication state throughout the app lifecycle
/// - Automatically disposes the subscription when no longer needed
///
/// Usage:
/// ```dart
/// // Watch the state (rebuilds on changes)
/// final authState = ref.watch(authProvider);
///
/// // Read the notifier to call methods (doesn't rebuild)
/// ref.read(authProvider.notifier).login(email: email, password: password);
/// ```
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthNotifier(userRepository);
});
