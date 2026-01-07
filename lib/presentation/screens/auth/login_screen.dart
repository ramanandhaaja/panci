import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panci/presentation/providers/auth_provider.dart';

/// Login screen for user authentication.
///
/// This screen provides:
/// - Email and password text fields with validation
/// - Login button that calls AuthProvider.login()
/// - Link to registration screen
/// - Continue as Guest option
/// - Error message display
/// - Loading indicator during authentication
///
/// Follows Material Design 3 with responsive layout.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      return 'Please enter your password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Handles the login button press.
  Future<void> _handleLogin() async {
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
      await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Login successful, navigate back to home
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error is stored in authProvider state
      // Will be displayed in UI
      debugPrint('Login failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handles the continue as guest button press.
  Future<void> _handleGuestSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).signInAsGuest();

      // Guest sign-in successful, navigate back to home
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Guest sign-in failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Navigates to the registration screen.
  void _navigateToRegister() {
    Navigator.of(context).pushReplacementNamed('/register');
  }

  /// Gets a user-friendly error message from Firebase error code.
  String _getFriendlyErrorMessage(String? error) {
    if (error == null) return '';

    if (error.contains('wrong-password')) {
      return 'Invalid email or password';
    } else if (error.contains('user-not-found')) {
      return 'No account found with this email. Please register.';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address';
    } else if (error.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else if (error.contains('user-disabled')) {
      return 'This account has been disabled.';
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
        title: const Text('Login'),
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
                      'Welcome Back',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue to Panci',
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
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outlined),
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
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    FilledButton(
                      onPressed: _isLoading ? null : _handleLogin,
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
                          : const Text('Login'),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Continue as Guest button
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGuestSignIn,
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Continue as Guest'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _navigateToRegister,
                          child: const Text('Register'),
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
