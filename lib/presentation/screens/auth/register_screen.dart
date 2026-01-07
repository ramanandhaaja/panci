import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panci/presentation/providers/auth_provider.dart';

/// Registration screen for creating new user accounts.
///
/// This screen provides:
/// - Username, email, and password fields with validation
/// - Password confirmation field
/// - Register button that calls AuthProvider.register()
/// - Link to login screen for existing users
/// - Error message display
/// - Loading indicator during registration
///
/// Handles both new user registration and guest-to-member conversion.
/// Follows Material Design 3 with responsive layout.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates the username.
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }

    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (value.length > 30) {
      return 'Username must be less than 30 characters';
    }

    // Check for valid characters (alphanumeric, underscore, hyphen)
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, _ and -';
    }

    return null;
  }

  /// Validates the email format.
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates the password.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Validates the password confirmation.
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Handles the register button press.
  Future<void> _handleRegister() async {
    // Clear previous error
    ref.read(authProvider.notifier).clearError();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Registration successful, navigate back to home
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error is stored in authProvider state
      // Will be displayed in UI
      debugPrint('Registration failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Navigates to the login screen.
  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  /// Gets a user-friendly error message from Firebase error code.
  String _getFriendlyErrorMessage(String? error) {
    if (error == null) return '';

    if (error.contains('email-already-in-use')) {
      return 'This email is already registered. Please login instead.';
    } else if (error.contains('weak-password')) {
      return 'Password should be at least 6 characters';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address';
    } else if (error.contains('operation-not-allowed')) {
      return 'Registration is currently disabled. Please try again later.';
    }

    return error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final errorMessage = _getFriendlyErrorMessage(authState.errorMessage);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App logo/icon
                    Icon(
                      Icons.palette,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),

                    // Welcome message
                    Text(
                      'Create Account',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to unlock all features',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Error message banner
                    if (errorMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Username text field
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Choose a username',
                        prefixIcon: Icon(Icons.person_outline),
                        helperText: '3-30 characters, letters, numbers, _ or -',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validateUsername,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Email text field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'your@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Password text field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Create a password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        helperText: 'At least 6 characters',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.next,
                      validator: _validatePassword,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password text field
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isConfirmPasswordVisible,
                      textInputAction: TextInputAction.done,
                      validator: _validateConfirmPassword,
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _handleRegister(),
                    ),
                    const SizedBox(height: 24),

                    // Register button
                    FilledButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Text('Register'),
                    ),
                    const SizedBox(height: 24),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _navigateToLogin,
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
