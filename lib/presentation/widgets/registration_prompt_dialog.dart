import 'package:flutter/material.dart';

/// Reusable dialog widget that prompts users to register.
///
/// This dialog is shown in various places where guest users
/// try to access features that require a registered account:
/// - Creating canvases beyond the guest limit
/// - Publishing canvases
/// - Adding team members
///
/// The dialog provides:
/// - Customizable title and message
/// - "Register Now" button that navigates to registration screen
/// - "Cancel" button to dismiss
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => const RegistrationPromptDialog(
///     title: 'Registration Required',
///     message: 'You need to register to create more canvases.',
///   ),
/// );
/// ```
class RegistrationPromptDialog extends StatelessWidget {
  /// Creates a registration prompt dialog.
  const RegistrationPromptDialog({
    super.key,
    this.title = 'Registration Required',
    required this.message,
  });

  /// The dialog title.
  final String title;

  /// The dialog message explaining why registration is needed.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.lock_person,
        color: theme.colorScheme.primary,
        size: 48,
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),

        // Register Now button
        FilledButton.icon(
          onPressed: () {
            // Close the dialog
            Navigator.of(context).pop();

            // Navigate to registration screen
            Navigator.of(context).pushNamed('/register');
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Register Now'),
        ),
      ],
    );
  }
}

/// Shows a registration prompt dialog.
///
/// This is a convenience function that shows the RegistrationPromptDialog
/// with the given title and message.
///
/// Parameters:
/// - [context]: The build context
/// - [title]: The dialog title (optional, defaults to 'Registration Required')
/// - [message]: The dialog message explaining why registration is needed
///
/// Returns a Future that completes when the dialog is dismissed.
///
/// Usage:
/// ```dart
/// await showRegistrationPrompt(
///   context,
///   message: 'Register to create unlimited canvases.',
/// );
/// ```
Future<void> showRegistrationPrompt(
  BuildContext context, {
  String title = 'Registration Required',
  required String message,
}) {
  return showDialog(
    context: context,
    builder: (context) => RegistrationPromptDialog(
      title: title,
      message: message,
    ),
  );
}
