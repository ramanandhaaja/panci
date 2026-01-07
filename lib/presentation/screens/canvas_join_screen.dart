import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panci/presentation/providers/auth_provider.dart';
import 'package:panci/presentation/providers/user_provider.dart';
import 'package:panci/data/repositories/repository_provider.dart';
import 'package:panci/data/repositories/firebase_drawing_repository.dart';
import 'package:panci/presentation/widgets/registration_prompt_dialog.dart';
// TODO: Uncomment when pod install completes
// import 'qr_scanner_screen.dart';

/// Screen that allows users to join an existing canvas or create a new one.
///
/// Users can:
/// - Enter a canvas ID manually in a text field
/// - Scan a QR code containing a canvas ID
/// - Create a new canvas which will generate a placeholder ID
class CanvasJoinScreen extends ConsumerStatefulWidget {
  /// Creates a canvas join/create screen.
  const CanvasJoinScreen({super.key});

  @override
  ConsumerState<CanvasJoinScreen> createState() => _CanvasJoinScreenState();
}

class _CanvasJoinScreenState extends ConsumerState<CanvasJoinScreen> {
  final TextEditingController _canvasIdController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _canvasIdController.dispose();
    super.dispose();
  }

  /// Opens the QR code scanner and handles the scanned result.
  /// TODO: Uncomment when pod install completes
  // Future<void> _openQrScanner() async {
  //   final scannedCode = await Navigator.push<String>(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const QrScannerScreen(),
  //     ),
  //   );

  //   if (scannedCode == null || !mounted) return;

  //   // Populate the text field with the scanned canvas ID
  //   setState(() {
  //     _canvasIdController.text = scannedCode;
  //     _errorMessage = null;
  //   });

  //   // Show success feedback
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Scanned canvas ID: $scannedCode'),
  //       backgroundColor: Theme.of(context).colorScheme.primary,
  //       behavior: SnackBarBehavior.floating,
  //       duration: const Duration(seconds: 2),
  //     ),
  //   );

  //   // Auto-join if the setting is enabled
  //   if (_autoJoinAfterScan) {
  //     // Give user a moment to see the scanned ID
  //     await Future.delayed(const Duration(milliseconds: 500));
  //     if (mounted) {
  //       _joinCanvas();
  //     }
  //   }
  // }

  /// Temporary placeholder for QR scanner - navigates directly to drawing screen
  void _openQrScanner() {
    // Generate a placeholder canvas ID (simulating a scanned QR code)
    final scannedCanvasId = 'canvas_${DateTime.now().millisecondsSinceEpoch}';

    // Navigate to drawing canvas screen
    Navigator.pushNamed(
      context,
      '/drawing',
      arguments: scannedCanvasId,
    );
  }

  /// Validates the canvas ID and navigates to the drawing screen if valid.
  void _joinCanvas() {
    final canvasId = _canvasIdController.text.trim();

    if (canvasId.isEmpty) {
      setState(() {
        _errorMessage = 'Canvas ID is required';
      });
      return;
    }

    // Clear error message if validation passes
    setState(() {
      _errorMessage = null;
    });

    // Navigate to drawing canvas screen with the entered canvas ID
    Navigator.pushNamed(
      context,
      '/drawing',
      arguments: canvasId,
    );
  }

  /// Creates a new canvas and navigates to the drawing screen with a placeholder ID.
  Future<void> _createNewCanvas() async {
    final user = ref.read(userProvider);
    final authState = ref.read(authProvider);

    // Check if user is loaded and authenticated
    if (user == null || authState.userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait while we set up your account'),
          ),
        );
      }
      return;
    }

    // Check if user can create canvas
    if (!user.canCreateCanvas) {
      if (mounted) {
        await showRegistrationPrompt(
          context,
          title: 'Canvas Limit Reached',
          message:
              "You've reached your canvas limit. Register to create unlimited canvases.",
        );
      }
      return;
    }

    try {
      // Generate a new canvas ID
      final newCanvasId = 'canvas_${DateTime.now().millisecondsSinceEpoch}';

      // Create canvas with ownership
      final repository = ref.read(drawingRepositoryProvider) as FirebaseDrawingRepository;
      await repository.createCanvas(
        canvasId: newCanvasId,
        ownerId: authState.userId!,
      );

      debugPrint('Canvas created: $newCanvasId for owner: ${authState.userId}');

      // Increment canvas count
      await ref.read(userProvider.notifier).incrementCanvasCount();

      // Navigate to drawing canvas screen with the new canvas ID
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/drawing',
          arguments: newCanvasId,
        );
      }
    } catch (e) {
      debugPrint('Error creating canvas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create canvas: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join or Create Canvas'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // App icon or logo placeholder
              Icon(
                Icons.palette,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Shared Canvas',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Draw together on a shared canvas',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Section title: Manual Entry
              Text(
                'Enter Canvas ID',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Canvas ID input field
              TextField(
                controller: _canvasIdController,
                decoration: InputDecoration(
                  labelText: 'Canvas ID',
                  hintText: 'Enter canvas ID to join',
                  prefixIcon: const Icon(Icons.tag),
                  errorText: _errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _joinCanvas(),
                onChanged: (_) {
                  // Clear error message when user starts typing
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Join Canvas button
              FilledButton.icon(
                onPressed: _joinCanvas,
                icon: const Icon(Icons.login),
                label: const Text('Join Canvas'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Divider with "OR" text
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // Section title: Scan QR Code
              Text(
                'Scan QR Code',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // QR Scanner button (temporary: goes to drawing screen)
              FilledButton.tonalIcon(
                onPressed: _openQrScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR Code'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Create New Canvas button
              OutlinedButton.icon(
                onPressed: _createNewCanvas,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create New Canvas'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
